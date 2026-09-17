import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:coinlib_flutter/coinlib_flutter.dart' as coinlib;
import 'package:isar_community/isar.dart';
import 'package:meta/meta.dart';

import '../../../db/drift/database.dart';
import '../../../electrumx_rpc/cached_electrumx_client.dart';
import '../../../electrumx_rpc/client_manager.dart';
import '../../../electrumx_rpc/electrumx_client.dart';
import '../../../models/coinlib/exp2pkh_address.dart';
import '../../../models/input.dart';
import '../../../models/isar/models/blockchain_data/v2/input_v2.dart';
import '../../../models/isar/models/blockchain_data/v2/output_v2.dart';
import '../../../models/isar/models/blockchain_data/v2/transaction_v2.dart';
import '../../../models/isar/models/isar_models.dart';
import '../../../models/keys/view_only_wallet_data.dart';
import '../../../models/paymint/fee_object_model.dart';
import '../../../utilities/amount/amount.dart';
import '../../../utilities/enums/derive_path_type_enum.dart';
import '../../../utilities/enums/fee_rate_type_enum.dart';
import '../../../utilities/extensions/extensions.dart';
import '../../../utilities/logger.dart';
import '../../../utilities/paynym_is_api.dart';
import '../../crypto_currency/coins/bitfinite.dart';
import '../../crypto_currency/coins/firo.dart';
import '../../crypto_currency/interfaces/electrumx_currency_interface.dart';
import '../../isar/models/wallet_info.dart';
import '../../models/tx_data.dart';
import '../impl/bitcoin_wallet.dart';
import '../impl/firo_wallet.dart';
import '../impl/peercoin_wallet.dart';
import '../intermediate/bip39_hd_wallet.dart';
import 'cpfp_interface.dart';
import 'mweb_interface.dart';
import 'paynym_interface.dart';
import 'rbf_interface.dart';
import 'sign_verify_interface.dart';
import 'view_only_option_interface.dart';

/// Nodes reject transactions over this size as non-standard ("tx-size",
/// reject code 64) even though consensus allows up to 1 MB. Same value in
/// BCHN and Bitcoin Core, so it holds for every coin using this interface.
const int _maxStandardTxSize = 100000;

/// Headroom: signedSize is an estimate and real signatures vary by a byte or
/// two each, which adds up across hundreds of inputs.
const int _txSizeSafetyMargin = 2000;

/// Carries its message with no "Exception: " prefix — this text is shown to
/// the user in a dialog, not to a developer in a log.
class TransactionTooLargeException implements Exception {
  TransactionTooLargeException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Thousands separators. Long digit runs like 147227 are hard to read at a
/// glance, and this text is the whole point of the check.
String _grouped(String digits) {
  final buf = StringBuffer();
  for (int i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buf.write(",");
    buf.write(digits[i]);
  }
  return buf.toString();
}

mixin ElectrumXInterface<T extends ElectrumXCurrencyInterface>
    on Bip39HDWallet<T>
    implements ViewOnlyOptionInterface<T>, SignVerifyInterface {
  late ElectrumXClient electrumXClient;
  late CachedElectrumXClient electrumXCachedClient;

  int? get maximumFeerate => null;

  double? refreshingPercent;

  static const _kServerBatchCutoffVersion = [1, 6];
  List<int>? _serverVersion;
  Future<bool> get serverCanBatch async {
    // Firo server added batching without incrementing version number...
    if (cryptoCurrency is Firo) {
      return true;
    }

    // Same story, our own server. It reports "bitfinite-electrs/1.1.3", which
    // the parse below cannot read at all, so this returned false and every
    // BitFinite wallet fetched one transaction per round trip: exactly the
    // cost the batching work was meant to remove. Verified 2026-09-02 that
    // the server answers a three call JSON-RPC batch in 0.08s.
    //
    // Bellscoin is unaffected and must stay unaffected: it talks to esplora
    // over HTTP through an adapter that reports "esplora 1.4" precisely so
    // this returns false.
    if (cryptoCurrency is Bitfinite) {
      return true;
    }

    try {
      _serverVersion ??= _parseServerVersion(
        (await electrumXClient.getServerFeatures().timeout(
              const Duration(seconds: 2),
            ))["server_version"]
            as String,
      );
    } catch (_) {
      // ignore failure as it doesn't matter
    }

    if (_serverVersion != null && _serverVersion!.length > 2) {
      if (_serverVersion![0] > _kServerBatchCutoffVersion[0]) {
        return true;
      }
      if (_serverVersion![1] > _kServerBatchCutoffVersion[1]) {
        return true;
      }
    }
    return false;
  }

  Future<List<TxRecipient>> helperRecipientsConvert(
    List<String> addrs,
    List<BigInt> satValues,
  ) async {
    final List<TxRecipient> results = [];

    for (int i = 0; i < addrs.length; i++) {
      // assume address is valid at this point so if getAddressType fails for
      // some reason default to unknown
      final type =
          cryptoCurrency.getAddressType(addrs[i]) ?? AddressType.unknown;

      results.add(
        TxRecipient(
          address: addrs[i],
          amount: Amount(
            rawValue: satValues[i],
            fractionDigits: cryptoCurrency.fractionDigits,
          ),
          isChange:
              (await mainDB.isar.addresses
                  .where()
                  .walletIdEqualTo(walletId)
                  .filter()
                  .subTypeEqualTo(AddressSubType.change)
                  .and()
                  .valueEqualTo(addrs[i])
                  .valueProperty()
                  .findFirst()) !=
              null,
          addressType: type,
        ),
      );
    }

    return results;
  }

  Future<TxData> coinSelection({
    required TxData txData,
    required bool coinControl,
    required bool isSendAll,
    required bool isSendAllCoinControlUtxos,
    int additionalOutputs = 0,
    List<BaseInput>? utxos,
    BigInt? overrideFeeAmount,
  }) async {
    Logging.instance.d("Starting coinSelection ----------");

    // TODO: multiple recipients one day
    assert(txData.recipients!.length == 1);

    if (coinControl && utxos == null) {
      throw Exception("Coin control used where utxos is null!");
    }

    Future<Address> changeAddress() async {
      if (txData.type == TxType.mweb || txData.type == TxType.mwebPegOut) {
        return (await (this as MwebInterface).getMwebChangeAddress())!;
      } else {
        return (await getCurrentChangeAddress())!;
      }
    }

    final recipientAddress = txData.recipients!.first.address;
    final satoshiAmountToSend = txData.amount!.raw;
    final int? satsPerVByte = txData.satsPerVByte;
    final selectedTxFeeRate = txData.feeRateAmount!;

    final List<BaseInput> availableOutputs;

    if (txData.type == TxType.mweb || txData.type == TxType.mwebPegOut) {
      if (utxos == null) {
        final db = Drift.get(walletId);
        final mwebUtxos = await (db.select(
          db.mwebUtxos,
        )..where((e) => e.used.equals(false))).get();

        availableOutputs = mwebUtxos.map((e) => MwebInput(e)).toList();
      } else {
        availableOutputs = utxos;
      }
    } else {
      availableOutputs =
          utxos ??
          (await mainDB.getUTXOs(walletId).findAll())
              .map((e) => StandardInput(e))
              .toList();
    }

    final currentChainHeight = await chainHeight;

    final canCPFP = this is CpfpInterface && coinControl;

    final spendableOutputs = availableOutputs.where((e) {
      if (e is StandardInput) {
        return !e.utxo.isBlocked &&
            (e.utxo.used != true) &&
            (canCPFP ||
                e.utxo.isConfirmed(
                  currentChainHeight,
                  cryptoCurrency.minConfirms,
                  cryptoCurrency.minCoinbaseConfirms,
                ));
      } else if (e is MwebInput) {
        return !e.utxo.blocked && !e.utxo.used;
      } else {
        return false;
      }
    }).toList();
    final spendableSatoshiValue = spendableOutputs.fold(
      BigInt.zero,
      (p, e) => p + e.value,
    );

    if (spendableSatoshiValue < satoshiAmountToSend) {
      throw Exception("Insufficient balance");
    } else if (spendableSatoshiValue == satoshiAmountToSend &&
        !isSendAll &&
        !isSendAllCoinControlUtxos) {
      throw Exception("Insufficient balance to pay transaction fee");
    }

    if (coinControl) {
      if (spendableOutputs.length < availableOutputs.length) {
        throw ArgumentError("Attempted to use an unavailable utxo");
      }
      // don't care about sorting if using all utxos
    } else {
      // sort spendable by age (oldest first)
      spendableOutputs.sort(
        (a, b) => (b.blockTime ?? currentChainHeight).compareTo(
          (a.blockTime ?? currentChainHeight),
        ),
      );
    }

    Logging.instance.d("spendableOutputs.length: ${spendableOutputs.length}");
    Logging.instance.d("availableOutputs.length: ${availableOutputs.length}");
    Logging.instance.d("spendableOutputs: $spendableOutputs");
    Logging.instance.d("spendableSatoshiValue: $spendableSatoshiValue");
    Logging.instance.d("satoshiAmountToSend: $satoshiAmountToSend");

    // Use coinlib CoinSelection algorithms except for
    // "coinControl", "SendAll", "MWEB", "overrideFeeAmount",
    // because they do not need a selection or
    // do not meet the requirements for the algorithms
    final bool useOptimalSelection =
        !coinControl &&
        !isSendAll &&
        !isSendAllCoinControlUtxos &&
        overrideFeeAmount == null &&
        txData.type != TxType.mweb &&
        txData.type != TxType.mwebPegOut &&
        txData.type != TxType.mwebPegIn;

    if (useOptimalSelection) {
      return await _optimalCoinSelection(
        txData: txData,
        spendableOutputs: spendableOutputs.whereType<StandardInput>().toList(),
        recipientAddress: recipientAddress,
        satoshiAmountToSend: satoshiAmountToSend,
        satsPerVByte: satsPerVByte,
        feeRatePerKB: selectedTxFeeRate,
        changeAddress: await changeAddress(),
      );
    }

    BigInt satoshisBeingUsed = BigInt.zero;
    int inputsBeingConsumed = 0;
    final List<BaseInput> utxoObjectsToUse = [];

    if (!coinControl) {
      for (
        var i = 0;
        satoshisBeingUsed < satoshiAmountToSend && i < spendableOutputs.length;
        i++
      ) {
        utxoObjectsToUse.add(spendableOutputs[i]);
        satoshisBeingUsed += spendableOutputs[i].value;
        inputsBeingConsumed += 1;
      }
      for (
        int i = 0;
        i < additionalOutputs && inputsBeingConsumed < spendableOutputs.length;
        i++
      ) {
        utxoObjectsToUse.add(spendableOutputs[inputsBeingConsumed]);
        satoshisBeingUsed += spendableOutputs[inputsBeingConsumed].value;
        inputsBeingConsumed += 1;
      }
    } else {
      satoshisBeingUsed = spendableSatoshiValue;
      utxoObjectsToUse.addAll(spendableOutputs);
      inputsBeingConsumed = spendableOutputs.length;
    }

    Logging.instance.d("satoshisBeingUsed: $satoshisBeingUsed");
    Logging.instance.d("inputsBeingConsumed: $inputsBeingConsumed");
    Logging.instance.d('utxoObjectsToUse: $utxoObjectsToUse');

    // numberOfOutputs' length must always be equal to that of recipientsArray and recipientsAmtArray
    final List<String> recipientsArray = [recipientAddress];
    final List<BigInt> recipientsAmtArray = [satoshiAmountToSend];

    // gather required signing data
    final inputsWithKeys = await addSigningKeys(utxoObjectsToUse);

    if (isSendAll || isSendAllCoinControlUtxos) {
      if ((overrideFeeAmount ?? BigInt.zero) + satoshiAmountToSend !=
          satoshisBeingUsed) {
        Logging.instance.d("txData.type: ${txData.type}");
        Logging.instance.d("isSendAll: $isSendAll");
        Logging.instance.d(
          "isSendAllCoinControlUtxos: $isSendAllCoinControlUtxos",
        );
        Logging.instance.d("overrideFeeAmount: $overrideFeeAmount");
        Logging.instance.d("satoshiAmountToSend: $satoshiAmountToSend");
        Logging.instance.d("satoshisBeingUsed: $satoshisBeingUsed");

        // hack check
        if (!(txData.type == TxType.mwebPegIn ||
            (txData.type.isMweb() && overrideFeeAmount != null))) {
          throw Exception(
            "Something happened that should never actually happen. "
            "Please report this error to the developers.",
          );
        }
      }
      return await _sendAllBuilder(
        txData: txData,
        recipientAddress: recipientAddress,
        satoshisBeingUsed: satoshisBeingUsed,
        inputsWithKeys: inputsWithKeys,
        satsPerVByte: satsPerVByte,
        feeRatePerKB: selectedTxFeeRate,
        overrideFeeAmount: overrideFeeAmount,
      );
    }

    final int vSizeForOneOutput;
    try {
      vSizeForOneOutput = (await buildTransaction(
        inputsWithKeys: inputsWithKeys,
        txData: txData.copyWith(
          recipients: await helperRecipientsConvert(
            [recipientAddress],
            [satoshisBeingUsed - BigInt.one],
          ),
        ),
      )).vSize!;
    } catch (e, s) {
      Logging.instance.e("vSizeForOneOutput: $e", error: e, stackTrace: s);
      rethrow;
    }

    final int vSizeForTwoOutPuts;

    BigInt maxBI(BigInt a, BigInt b) => a > b ? a : b;

    try {
      vSizeForTwoOutPuts = (await buildTransaction(
        inputsWithKeys: inputsWithKeys,
        txData: txData.copyWith(
          recipients: await helperRecipientsConvert(
            [recipientAddress, (await changeAddress()).value],
            [
              satoshiAmountToSend,
              maxBI(
                BigInt.zero,
                satoshisBeingUsed - (satoshiAmountToSend + BigInt.one),
              ),
            ],
          ),
        ),
      )).vSize!;
    } catch (e, s) {
      Logging.instance.e("vSizeForTwoOutPuts: $e", error: e, stackTrace: s);
      rethrow;
    }

    // Assume 1 output, only for recipient and no change
    final feeForOneOutput =
        overrideFeeAmount ??
        BigInt.from(
          satsPerVByte != null
              ? (satsPerVByte * vSizeForOneOutput)
              : estimateTxFee(
                  vSize: vSizeForOneOutput,
                  feeRatePerKB: selectedTxFeeRate,
                ),
        );
    // Assume 2 outputs, one for recipient and one for change
    final feeForTwoOutputs =
        overrideFeeAmount ??
        BigInt.from(
          satsPerVByte != null
              ? (satsPerVByte * vSizeForTwoOutPuts)
              : estimateTxFee(
                  vSize: vSizeForTwoOutPuts,
                  feeRatePerKB: selectedTxFeeRate,
                ),
        );

    Logging.instance.d("feeForTwoOutputs: $feeForTwoOutputs");
    Logging.instance.d("feeForOneOutput: $feeForOneOutput");

    final difference = satoshisBeingUsed - satoshiAmountToSend;

    Future<TxData> singleOutputTxn() async {
      Logging.instance.d('Input size: $satoshisBeingUsed');
      Logging.instance.d('Recipient output size: $satoshiAmountToSend');
      Logging.instance.d('Fee being paid: $difference sats');
      Logging.instance.d('Estimated fee: $feeForOneOutput');
      final txnData = await buildTransaction(
        inputsWithKeys: inputsWithKeys,
        txData: txData.copyWith(
          recipients: await helperRecipientsConvert(
            recipientsArray,
            recipientsAmtArray,
          ),
        ),
      );
      return txnData.copyWith(
        fee: Amount(
          rawValue: feeForOneOutput,
          fractionDigits: cryptoCurrency.fractionDigits,
        ),
        usedUTXOs: inputsWithKeys,
      );
    }

    // no change output required
    if (difference == feeForOneOutput) {
      Logging.instance.d('1 output in tx');
      return await singleOutputTxn();
    } else if (difference < feeForOneOutput) {
      Logging.instance.w(
        'Cannot pay tx fee - checking for more outputs and trying again',
      );
      // try adding more outputs
      if (spendableOutputs.length > inputsBeingConsumed) {
        return coinSelection(
          txData: txData,
          isSendAll: isSendAll,
          additionalOutputs: additionalOutputs + 1,
          utxos: utxos,
          coinControl: coinControl,
          isSendAllCoinControlUtxos: isSendAllCoinControlUtxos,
          overrideFeeAmount: overrideFeeAmount,
        );
      }
      throw Exception("Insufficient balance to pay transaction fee");
    } else {
      if (difference > (feeForOneOutput + cryptoCurrency.dustLimit.raw)) {
        final changeOutputSize = difference - feeForTwoOutputs;
        // check if possible to add the change output
        if (changeOutputSize > cryptoCurrency.dustLimit.raw &&
            difference - changeOutputSize == feeForTwoOutputs) {
          if (!(txData.type == TxType.mweb ||
              txData.type == TxType.mwebPegOut)) {
            // generate new change address if current change address has been used
            await checkChangeAddressForTransactions();
          }
          final newChangeAddress = await changeAddress();

          BigInt feeBeingPaid = difference - changeOutputSize;

          // add change output
          recipientsArray.add(newChangeAddress.value);
          recipientsAmtArray.add(changeOutputSize);

          Logging.instance.d('2 outputs in tx');
          Logging.instance.d('Input size: $satoshisBeingUsed');
          Logging.instance.d('Recipient output size: $satoshiAmountToSend');
          Logging.instance.d('Change Output Size: $changeOutputSize');
          Logging.instance.d('Difference (fee being paid): $feeBeingPaid sats');
          Logging.instance.d('Estimated fee: $feeForTwoOutputs');

          TxData txnData = await buildTransaction(
            inputsWithKeys: inputsWithKeys,
            txData: txData.copyWith(
              recipients: await helperRecipientsConvert(
                recipientsArray,
                recipientsAmtArray,
              ),
              usedUTXOs: inputsWithKeys,
            ),
          );

          // make sure minimum fee is accurate if that is being used
          if (BigInt.from(txnData.vSize!) - feeBeingPaid == BigInt.one) {
            final changeOutputSize = difference - BigInt.from(txnData.vSize!);
            feeBeingPaid = difference - changeOutputSize;
            recipientsAmtArray.removeLast();
            recipientsAmtArray.add(changeOutputSize);

            Logging.instance.d('Adjusted Input size: $satoshisBeingUsed');
            Logging.instance.d(
              'Adjusted Recipient output size: $satoshiAmountToSend',
            );
            Logging.instance.d(
              'Adjusted Change Output Size: $changeOutputSize',
            );
            Logging.instance.d(
              'Adjusted Difference (fee being paid): $feeBeingPaid sats',
            );
            Logging.instance.d('Adjusted Estimated fee: $feeForTwoOutputs');

            txnData = await buildTransaction(
              inputsWithKeys: inputsWithKeys,
              txData: txData.copyWith(
                recipients: await helperRecipientsConvert(
                  recipientsArray,
                  recipientsAmtArray,
                ),
                usedUTXOs: inputsWithKeys,
              ),
            );
          }

          return txnData.copyWith(
            fee: Amount(
              rawValue: feeBeingPaid,
              fractionDigits: cryptoCurrency.fractionDigits,
            ),
            usedUTXOs: inputsWithKeys,
          );
        } else {
          // Something went wrong here. It either overshot or undershot the estimated fee amount or the changeOutputSize
          // is smaller than or equal to cryptoCurrency.dustLimit. Revert to single output transaction.
          Logging.instance.d('Reverting to 1 output in tx');

          return await singleOutputTxn();
        }
      }
    }

    return txData;
  }

  Future<TxData> _sendAllBuilder({
    required TxData txData,
    required String recipientAddress,
    required BigInt satoshisBeingUsed,
    required List<BaseInput> inputsWithKeys,
    required int? satsPerVByte,
    required BigInt feeRatePerKB,
    BigInt? overrideFeeAmount,
  }) async {
    Logging.instance.d("Attempting to send all $cryptoCurrency");
    if (txData.recipients!.length != 1) {
      throw Exception("Send all to more than one recipient not yet supported");
    }

    BigInt feeForOneOutput;
    if (overrideFeeAmount == null) {
      final int vSizeForOneOutput = (await buildTransaction(
        inputsWithKeys: inputsWithKeys,
        txData: txData.copyWith(
          recipients: await helperRecipientsConvert(
            [recipientAddress],
            [satoshisBeingUsed - BigInt.one],
          ),
        ),
      )).vSize!;
      feeForOneOutput = BigInt.from(
        satsPerVByte != null
            ? (satsPerVByte * vSizeForOneOutput)
            : estimateTxFee(
                vSize: vSizeForOneOutput,
                feeRatePerKB: feeRatePerKB,
              ),
      );

      if (satsPerVByte == null) {
        final roughEstimate = roughFeeEstimate(
          inputsWithKeys.length,
          1,
          feeRatePerKB,
        ).raw;
        if (feeForOneOutput < roughEstimate) {
          feeForOneOutput = roughEstimate;
        }
      }
    } else {
      feeForOneOutput = overrideFeeAmount;
    }

    final satoshiAmountToSend = satoshisBeingUsed - feeForOneOutput;

    if (satoshiAmountToSend.isNegative) {
      throw Exception(
        "Estimated fee ($feeForOneOutput sats) is greater than balance!",
      );
    }

    final data = await buildTransaction(
      txData: txData.copyWith(
        recipients: await helperRecipientsConvert(
          [recipientAddress],
          [satoshiAmountToSend],
        ),
      ),
      inputsWithKeys: inputsWithKeys,
    );

    return data.copyWith(
      fee: Amount(
        rawValue: feeForOneOutput,
        fractionDigits: cryptoCurrency.fractionDigits,
      ),
      usedUTXOs: inputsWithKeys,
    );
  }

  coinlib.Input standardInputToCoinlibInput(
    StandardInput input, {
    int sequence = 0xffffffff,
  }) {
    final hash = Uint8List.fromList(
      input.utxo.txid.toUint8ListFromHex.reversed.toList(),
    );
    final prevOut = coinlib.OutPoint(hash, input.utxo.vout);

    switch (input.derivePathType) {
      case DerivePathType.bip44:
      case DerivePathType.bch44:
        return coinlib.P2PKHInput(
          prevOut: prevOut,
          publicKey: input.key!.publicKey,
          sequence: sequence,
        );

      // TODO: fix this as it is (probably) wrong!
      case DerivePathType.bip49:
        throw Exception("TODO p2sh");
      // return coinlib.P2SHMultisigInput(
      //   prevOut: prevOut,
      //   program: coinlib.MultisigProgram.decompile(
      //     input.redeemScript!,
      //   ),
      //   sequence: sequence,
      // );

      case DerivePathType.bip84:
        return coinlib.P2WPKHInput(
          prevOut: prevOut,
          publicKey: input.key!.publicKey,
          sequence: sequence,
        );

      case DerivePathType.bip86:
        return coinlib.TaprootKeyInput(prevOut: prevOut);

      default:
        throw UnsupportedError(
          "Unknown derivation path type found: ${input.derivePathType}",
        );
    }
  }

  /// Helper that will convert BaseInput into InputCandidates
  /// and use [coinlib.CoinSelection.optimal] to select the good candidates.
  Future<TxData> _optimalCoinSelection({
    required TxData txData,
    required List<StandardInput> spendableOutputs,
    required String recipientAddress,
    required BigInt satoshiAmountToSend,
    required int? satsPerVByte,
    required BigInt feeRatePerKB,
    required Address changeAddress,
  }) async {
    final List<BaseInput> candidateInputs = await addSigningKeys(
      spendableOutputs,
    );

    final BigInt feePerKb = satsPerVByte != null
        ? BigInt.from(satsPerVByte * 1000)
        : feeRatePerKB;

    // minFee should be equal or above the Vsize of the tx, which should happen
    // since coin selection algorithms will respect feeRatePerKB. So there is no
    // need to define a minFee
    final BigInt minFee = BigInt.zero;

    final List<coinlib.InputCandidate> candidates = [];
    final Map<int, BaseInput> candidateBaseInputs = {};

    for (int i = 0; i < candidateInputs.length; i++) {
      final baseInput = candidateInputs[i];

      if (baseInput is! StandardInput) {
        // This shouldn't be happening since only non MWEB inputs
        // will be given to this helper
        throw Exception('''
          Unexpected input type ${baseInput.runtimeType}
          only StandardInput are supported
          ''');
      }

      final input = standardInputToCoinlibInput(baseInput);

      candidates.add(
        coinlib.InputCandidate(input: input, value: baseInput.value),
      );
      candidateBaseInputs[i] = baseInput;
    }

    final coinlib.Address clRecipientAddress = coinlib.Address.fromString(
      normalizeAddress(recipientAddress),
      cryptoCurrency.networkParams,
    );
    final coinlib.Output recipientOutput = coinlib.Output.fromAddress(
      satoshiAmountToSend,
      clRecipientAddress,
    );

    final coinlib.Address clChangeAddress = coinlib.Address.fromString(
      normalizeAddress(changeAddress.value),
      cryptoCurrency.networkParams,
    );

    final coinlib.Program changeProgram = clChangeAddress.program;

    final coinlib.CoinSelection selection = coinlib.CoinSelection.optimal(
      candidates: candidates,
      recipients: [recipientOutput],
      changeProgram: changeProgram,
      feePerKb: feePerKb,
      minFee: minFee,
      minChange: cryptoCurrency.dustLimit.raw,
    );

    if (selection.tooLarge) {
      throw Exception("Selected transaction would be too large");
    }

    // coinlib's `tooLarge` only trips above 1 MB — the CONSENSUS limit. Nodes
    // reject anything over MAX_STANDARD_TX_SIZE (100 000 bytes) as non-standard
    // long before that, with "tx-size" / reject code 64. A wallet holding many
    // small UTXOs (mining payouts) therefore built a transaction that passed
    // every local check and then failed at broadcast, after the user had
    // already confirmed it. Catch it here, while we can still say something
    // useful.
    if (selection.signedSize > _maxStandardTxSize - _txSizeSafetyMargin) {
      final int inputsUsed = selection.selected.length;
      // Derive bytes-per-input from this selection rather than assuming a
      // script type, then work out what would actually fit.
      final int bytesPerInput = inputsUsed > 0
          ? (selection.signedSize / inputsUsed).ceil()
          : 148;
      final int maxInputs =
          ((_maxStandardTxSize - _txSizeSafetyMargin) / bytesPerInput).floor();

      final sorted = candidates.map((c) => c.value).toList()
        ..sort((a, b) => b.compareTo(a));
      BigInt fits = BigInt.zero;
      for (int i = 0; i < maxInputs && i < sorted.length; i++) {
        fits += sorted[i];
      }
      // Rough fee for a full-size transaction, so the figure we quote is
      // actually sendable rather than one the user will bounce off again.
      final BigInt roughFee =
          BigInt.from(_maxStandardTxSize - _txSizeSafetyMargin) *
          feePerKb ~/
          BigInt.from(1000);
      final BigInt sendable = fits > roughFee ? fits - roughFee : BigInt.zero;
      // Floor to whole coins. The fractional part is noise here, and quoting a
      // figure to eight decimals invites the user to type it back exactly and
      // land right on the limit again.
      final BigInt unit = BigInt.from(10).pow(cryptoCurrency.fractionDigits);
      final BigInt wholeCoins = sendable ~/ unit;
      final String sendableStr = _grouped(wholeCoins.toString());

      throw TransactionTooLargeException(
        "This amount needs $inputsUsed coins, which makes the transaction "
        "${_grouped(selection.signedSize.toString())} bytes. The network only "
        "accepts transactions up to ${_grouped(_maxStandardTxSize.toString())} "
        "bytes.\n\n"
        "Send $sendableStr ${cryptoCurrency.ticker} or less in one "
        "transaction, then repeat. Your coins are safe — nothing was sent.",
      );
    }
    if (!selection.ready) {
      throw Exception("Selection of coins was not successful");
    }

    // Going back from InputCandidates to BaseInput
    // This could be avoided since buildTransaction will do the exact opposite ?
    final List<BaseInput> selectedBaseInputs = [];
    for (final picked in selection.selected) {
      final pickedTxid = Uint8List.fromList(
        picked.input.prevOut.hash.reversed.toList(),
      ).toHex;
      final pickedVout = picked.input.prevOut.n;
      bool matched = false;
      for (final entry in candidateBaseInputs.entries) {
        final base = entry.value;
        if (base is StandardInput &&
            base.utxo.txid == pickedTxid &&
            base.utxo.vout == pickedVout) {
          selectedBaseInputs.add(base);
          matched = true;
          break;
        }
      }
      if (!matched) {
        throw Exception(
          "Selected input not found among candidates (txid=$pickedTxid"
          " vout=$pickedVout)",
        );
      }
    }

    Logging.instance.d(
      "Optimal selection: picked ${selectedBaseInputs.length} input(s),"
      " inputValue=${selection.inputValue}, fee=${selection.fee},"
      " changeValue=${selection.changeValue},"
      " signedSize=${selection.signedSize}",
    );

    /// Add the change if there is one
    final List<String> recipientsArray = [recipientAddress];
    final List<BigInt> recipientsAmtArray = [satoshiAmountToSend];
    if (!selection.changeless) {
      await checkChangeAddressForTransactions();
      final freshChange = (await getCurrentChangeAddress())!;
      recipientsArray.add(freshChange.value);
      recipientsAmtArray.add(selection.changeValue);
    }

    final TxData txBuilt = await buildTransaction(
      inputsWithKeys: selectedBaseInputs,
      txData: txData.copyWith(
        recipients: await helperRecipientsConvert(
          recipientsArray,
          recipientsAmtArray,
        ),
        usedUTXOs: selectedBaseInputs,
      ),
    );

    return txBuilt.copyWith(
      fee: Amount(
        rawValue: selection.fee,
        fractionDigits: cryptoCurrency.fractionDigits,
      ),
      usedUTXOs: selectedBaseInputs,
    );
  }

  Future<List<BaseInput>> addSigningKeys(List<BaseInput> utxosToUse) async {
    // return data
    final List<BaseInput> inputsWithKeys = [];

    try {
      // Populating the addresses to check
      for (var i = 0; i < utxosToUse.length; i++) {
        final input = utxosToUse[i];
        if (input is MwebInput) {
          inputsWithKeys.add(input);
        } else if (input is StandardInput) {
          final derivePathType = cryptoCurrency.addressType(
            address: input.address!,
          );

          inputsWithKeys.add(
            StandardInput(input.utxo, derivePathType: derivePathType),
          );
        } else {
          throw Exception("Unknown input type ${input.runtimeType}");
        }
      }

      final root = await getRootHDNode();

      for (final sd in inputsWithKeys.whereType<StandardInput>()) {
        coinlib.HDPrivateKey? keys;
        final address = await mainDB.getAddress(walletId, sd.utxo.address!);
        if (address?.derivationPath != null) {
          if (address!.subType == AddressSubType.paynymReceive) {
            if (this is PaynymInterface) {
              final code = await (this as PaynymInterface)
                  .paymentCodeStringByKey(address.otherData!);

              final bip47base = await (this as PaynymInterface)
                  .getBip47BaseNode();

              final privateKey = await (this as PaynymInterface)
                  .getPrivateKeyForPaynymReceivingAddress(
                    paymentCodeString: code!,
                    index: address.derivationIndex,
                  );

              keys = coinlib.HDPrivateKey.fromKeyAndChainCode(
                coinlib.ECPrivateKey.fromHex(privateKey.toHex),
                bip47base.chainCode,
              );
            } else {
              throw Exception(
                "$runtimeType tried to fetchBuildTxData for a paynym address"
                " in a non PaynymInterface wallet",
              );
            }
          } else {
            keys = root.derivePath(address.derivationPath!.value);
          }
        }

        if (keys == null) {
          throw Exception(
            "Failed to fetch signing data. Local db corrupt. Rescan wallet.",
          );
        }

        sd.key = keys;
      }

      return inputsWithKeys;
    } catch (e, s) {
      Logging.instance.e("fetchBuildTxData() threw", error: e, stackTrace: s);
      rethrow;
    }
  }

  /// Builds and signs a transaction
  Future<TxData> buildTransaction({
    required TxData txData,
    required List<BaseInput> inputsWithKeys,
  }) async {
    Logging.instance.d("Starting buildTransaction ----------");

    // temp tx data to show in gui while waiting for real data from server
    final List<InputV2> tempInputs = [];
    final List<OutputV2> tempOutputs = [];

    final List<coinlib.Output> prevOuts = [];

    coinlib.Transaction clTx = coinlib.Transaction(
      vExtraData: txData.vExtraData,
      version:
          txData.overrideVersion ??
          (txData.type.isMweb() ? 2 : cryptoCurrency.transactionVersion),
      inputs: [],
      outputs: [],
    );

    // TODO: [prio=high]: check this opt in rbf
    final sequence = this is RbfInterface && (this as RbfInterface).flagOptInRBF
        ? 0xffffffff - 10
        : 0xffffffff - 1;

    bool isMweb = false;
    bool hasNonWitnessInput = false;

    // Add transaction inputs
    for (var i = 0; i < inputsWithKeys.length; i++) {
      final data = inputsWithKeys[i];
      if (data is MwebInput) {
        isMweb = true;
        final address = data.address;

        final addr = await mainDB.getAddress(walletId, address);
        final index = addr!.derivationIndex;

        final input = coinlib.RawInput(
          prevOut: coinlib.OutPoint(
            Uint8List.fromList(
              data.utxo.outputId.toUint8ListFromHex.reversed.toList(),
            ),
            index,
          ),
          scriptSig: Uint8List(0),
        );

        clTx = clTx.addInput(input);

        tempInputs.add(
          InputV2.isarCantDoRequiredInDefaultConstructor(
            scriptSigHex: input.scriptSig.toHex,
            scriptSigAsm: null,
            sequence: sequence,
            outpoint: OutpointV2.isarCantDoRequiredInDefaultConstructor(
              txid: data.utxo.outputId,
              vout: index,
            ),
            addresses: [address],
            valueStringSats: inputsWithKeys[i].value.toString(),
            witness: null,
            innerRedeemScriptAsm: null,
            coinbase: null,
            walletOwns: true,
          ),
        );
      } else if (data is StandardInput) {
        final prevOutput = coinlib.Output.fromAddress(
          BigInt.from(data.utxo.value),
          coinlib.Address.fromString(
            data.utxo.address!,
            cryptoCurrency.networkParams,
          ),
        );

        prevOuts.add(prevOutput);

        final input = standardInputToCoinlibInput(data, sequence: sequence);

        if (input is! coinlib.WitnessInput) {
          hasNonWitnessInput = true;
        }

        clTx = clTx.addInput(input);

        tempInputs.add(
          InputV2.isarCantDoRequiredInDefaultConstructor(
            scriptSigHex: input.scriptSig.toHex,
            scriptSigAsm: null,
            sequence: sequence,
            outpoint: OutpointV2.isarCantDoRequiredInDefaultConstructor(
              txid: data.utxo.txid,
              vout: data.utxo.vout,
            ),
            addresses: data.utxo.address == null ? [] : [data.utxo.address!],
            valueStringSats: data.utxo.value.toString(),
            witness: null,
            innerRedeemScriptAsm: null,
            coinbase: null,
            walletOwns: true,
          ),
        );
      } else {
        throw Exception("Unknown input type: ${inputsWithKeys[i].runtimeType}");
      }
    }

    // Add transaction output
    for (var i = 0; i < txData.recipients!.length; i++) {
      late final coinlib.Address address;

      try {
        address = coinlib.Address.fromString(
          normalizeAddress(txData.recipients![i].address),
          cryptoCurrency.networkParams,
        );
      } catch (_) {
        if (this is FiroWallet) {
          address = EXP2PKHAddress.fromString(
            normalizeAddress(txData.recipients![i].address),
            (cryptoCurrency as Firo).exAddressVersion,
          );
        } else {
          rethrow;
        }
      }
      final coinlib.Output output;
      if (address is coinlib.MwebAddress) {
        isMweb = true;
        output = coinlib.Output.fromProgram(
          txData.recipients![i].amount.raw,
          address.program,
        );
      } else {
        output = coinlib.Output.fromAddress(
          txData.recipients![i].amount.raw,
          address,
        );
      }

      clTx = clTx.addOutput(output);

      tempOutputs.add(
        OutputV2.isarCantDoRequiredInDefaultConstructor(
          scriptPubKeyHex: "000000",
          valueStringSats: txData.recipients![i].amount.raw.toString(),
          addresses: [txData.recipients![i].address.toString()],
          walletOwns:
              (await mainDB.isar.addresses
                  .where()
                  .walletIdEqualTo(walletId)
                  .filter()
                  .valueEqualTo(txData.recipients![i].address)
                  .valueProperty()
                  .findFirst()) !=
              null,
        ),
      );
    }

    // Add OP_RETURN output if provided (for Rosen Bridge and other protocols)
    // Currently only supported for Firo
    if (cryptoCurrency is Firo &&
        txData.opReturnData != null &&
        txData.opReturnData!.isNotEmpty) {
      try {
        final opReturnBytes = txData.opReturnData!.toUint8ListFromHex;

        // Validate OP_RETURN size (Bitcoin/Firo limit is 80 bytes)
        if (opReturnBytes.length > 80) {
          throw Exception(
            "OP_RETURN data exceeds 80 byte limit: ${opReturnBytes.length} bytes",
          );
        }

        // Encode push data: OP_PUSHDATA1 (0x4c) for 76-80 bytes, direct length otherwise
        final pushData = opReturnBytes.length <= 75
            ? Uint8List.fromList([opReturnBytes.length, ...opReturnBytes])
            : Uint8List.fromList([
                0x4c,
                opReturnBytes.length,
                ...opReturnBytes,
              ]);

        final opReturnScript = Uint8List.fromList([
          0x6a, // OP_RETURN opcode
          ...pushData,
        ]);

        final opReturnOutput = coinlib.Output.fromScriptBytes(
          BigInt.zero, // OP_RETURN outputs have 0 value
          opReturnScript,
        );

        clTx = clTx.addOutput(opReturnOutput);

        Logging.instance.i(
          "Added OP_RETURN output with ${opReturnBytes.length} bytes of data",
        );

        tempOutputs.add(
          OutputV2.isarCantDoRequiredInDefaultConstructor(
            scriptPubKeyHex: opReturnScript.toHex,
            valueStringSats: "0",
            addresses: [],
            walletOwns: false,
          ),
        );
      } catch (e, s) {
        Logging.instance.e(
          "Failed to add OP_RETURN output",
          error: e,
          stackTrace: s,
        );
        throw Exception("Invalid OP_RETURN data: $e");
      }
    }
    if (isMweb) {
      if (hasNonWitnessInput) {
        throw Exception("Found non witness input in mweb tx");
      }
    }

    try {
      // Sign the transaction accordingly
      for (var i = 0; i < inputsWithKeys.length; i++) {
        final data = inputsWithKeys[i];

        if (data is MwebInput) {
          // do nothing
        } else if (data is StandardInput) {
          final value = BigInt.from(data.utxo.value);
          final key = data.key!.privateKey!;
          if (clTx.inputs[i] is coinlib.TaprootKeyInput) {
            final taproot = coinlib.Taproot(internalKey: data.key!.publicKey);

            clTx = clTx.signTaproot(
              inputN: i,
              key: taproot.tweakPrivateKey(key),
              prevOuts: prevOuts,
            );
          } else if (clTx.inputs[i] is coinlib.LegacyWitnessInput) {
            clTx = clTx.signLegacyWitness(inputN: i, key: key, value: value);
          } else if (clTx.inputs[i] is coinlib.LegacyInput) {
            clTx = clTx.signLegacy(inputN: i, key: key);
          } else if (clTx.inputs[i] is coinlib.TaprootSingleScriptSigInput) {
            clTx = clTx.signTaprootSingleScriptSig(
              inputN: i,
              key: key,
              prevOuts: prevOuts,
            );
          } else {
            throw Exception(
              "Unable to sign input of type ${clTx.inputs[i].runtimeType}",
            );
          }
        } else {
          throw Exception(
            "Unknown input type: ${inputsWithKeys[i].runtimeType}",
          );
        }
      }
    } catch (e, s) {
      Logging.instance.e(
        "Caught exception while signing transaction: ",
        error: e,
        stackTrace: s,
      );
      rethrow;
    }

    return txData.copyWith(
      raw: clTx.toHex(),
      // dirty shortcut for peercoin's weirdness
      vSize: this is PeercoinWallet ? clTx.size : clTx.vSize(),
      tempTx: txData.type == TxType.mwebPegIn
          ? null
          : txData.type.isMweb()
          ? TransactionV2(
              walletId: walletId,
              blockHash: null,
              hash: clTx.hashHex,
              txid: clTx.txid,
              height: null,
              timestamp: DateTime.timestamp().millisecondsSinceEpoch ~/ 1000,
              inputs: List.unmodifiable(tempInputs),
              outputs: List.unmodifiable(tempOutputs),
              version: clTx.version,
              type: TransactionType.outgoing,
              subType: TransactionSubType.mweb,
              otherData: null,
            )
          : TransactionV2(
              walletId: walletId,
              blockHash: null,
              hash: clTx.hashHex,
              txid: clTx.txid,
              height: null,
              timestamp: DateTime.timestamp().millisecondsSinceEpoch ~/ 1000,
              inputs: List.unmodifiable(tempInputs),
              outputs: List.unmodifiable(tempOutputs),
              version: clTx.version,
              type:
                  tempOutputs
                          .map((e) => e.walletOwns)
                          .fold(true, (p, e) => p &= e) &&
                      txData.paynymAccountLite == null
                  ? TransactionType.sentToSelf
                  : TransactionType.outgoing,
              subType: TransactionSubType.none,
              otherData: null,
            ),
    );
  }

  Future<int> fetchChainHeight({int retries = 1}) async {
    try {
      // Ensure server version is initialized and genesis hash is checked.
      if (_serverVersion == null) {
        await _initializeServerVersionAndCheckGenesisHash();
      }

      return await ClientManager.sharedInstance.getChainHeightFor(
        cryptoCurrency,
      );
    } catch (e, s) {
      if (retries > 0) {
        retries--;
        await electrumXClient.checkElectrumAdapter();
        return await fetchChainHeight(retries: retries);
      }
      Logging.instance.e(
        "Exception rethrown in fetchChainHeight\nError: $e\nStack trace: $s",
        error: e,
        stackTrace: s,
      );
      // completer.completeError(e, s);
      // return Future.error(e, s);
      rethrow;
    }
  }

  Future<int> fetchTxCount({required String addressScriptHash}) async {
    final transactions = await electrumXClient.getHistory(
      scripthash: addressScriptHash,
    );
    return transactions.length;
  }

  /// Should return a list of tx counts matching the list of addresses given
  Future<List<int>> fetchTxCountBatched({
    required List<String> addresses,
  }) async {
    try {
      final response = await electrumXClient.getBatchHistory(
        args: addresses
            .map((e) => [cryptoCurrency.addressToScriptHash(address: e)])
            .toList(growable: false),
      );

      final List<int> result = [];
      for (final entry in response) {
        result.add(entry.length);
      }
      return result;
    } catch (e, s) {
      Logging.instance.e(
        "Exception rethrown in _getBatchTxCount(address: $addresses: ",
        error: e,
        stackTrace: s,
      );
      rethrow;
    }
  }

  Future<ElectrumXNode> _getCurrentElectrumXNode() async {
    final node = getCurrentNode();

    return ElectrumXNode(
      address: node.host,
      port: node.port,
      name: node.name,
      useSSL: node.useSSL,
      id: node.id,
      torEnabled: node.torEnabled,
      clearnetEnabled: node.clearnetEnabled,
    );
  }

  Future<void> updateElectrumX() async {
    final newNode = await _getCurrentElectrumXNode();

    final failovers = nodeService
        .failoverNodesFor(currency: cryptoCurrency)
        // The primary is itself flagged isFailover, so without this the first
        // failover hop retries the host that just failed - paying its timeout
        // a second time before reaching a different server.
        .where((e) => e.id != newNode.id)
        .map(
          (e) => ElectrumXNode(
            address: e.host,
            port: e.port,
            name: e.name,
            id: e.id,
            useSSL: e.useSSL,
            torEnabled: e.torEnabled,
            clearnetEnabled: e.clearnetEnabled,
          ),
        )
        .toList();

    try {
      await electrumXClient.closeAdapter();
    } catch (e, s) {
      if (e.toString().contains("initialized")) {
        // Ignore.  This should happen every first time the wallet is opened.
      } else {
        Logging.instance.e(
          "Error closing electrumXClient",
          error: e,
          stackTrace: s,
        );
      }
    }
    electrumXClient = ElectrumXClient.from(
      node: newNode,
      prefs: prefs,
      failovers: failovers,
      cryptoCurrency: cryptoCurrency,
    );
    electrumXCachedClient = CachedElectrumXClient.from(
      electrumXClient: electrumXClient,
    );
  }

  //============================================================================

  Future<({List<Address> addresses, int index})> checkGapsBatched(
    int txCountBatchSize,
    coinlib.HDKey node,
    DerivePathType type,
    int chain,
  ) async {
    final List<Address> addressArray = [];
    int gapCounter = 0;
    int highestIndexWithHistory = -1;

    for (
      int index = 0;
      gapCounter < cryptoCurrency.maxUnusedAddressGap;
      index += txCountBatchSize
    ) {
      Logging.instance.d(
        "index: $index, \t GapCounter $chain ${type.name}: $gapCounter",
      );

      final List<String> txCountCallArgs = [];

      for (int j = 0; j < txCountBatchSize; j++) {
        final derivePath = cryptoCurrency.constructDerivePath(
          derivePathType: type,
          chain: chain,
          index: index + j,
        );

        final coinlib.HDKey keys;
        if (isViewOnly) {
          final idx = derivePath.lastIndexOf("'/");
          final path = derivePath.substring(idx + 2);
          keys = node.derivePath(path);
        } else {
          keys = node.derivePath(derivePath);
        }

        final addressData = cryptoCurrency.getAddressForPublicKey(
          publicKey: keys.publicKey,
          derivePathType: type,
        );

        final addressString = convertAddressString(
          addressData.address.toString(),
        );

        final address = Address(
          walletId: walletId,
          value: addressString,
          publicKey: keys.publicKey.data,
          type: addressData.addressType,
          derivationIndex: index + j,
          derivationPath: isViewOnly
              ? null
              : (DerivationPath()..value = derivePath),
          subType: chain == 0
              ? AddressSubType.receiving
              : AddressSubType.change,
        );

        addressArray.add(address);

        txCountCallArgs.add(addressString);
      }

      // get address tx counts
      final counts = await fetchTxCountBatched(addresses: txCountCallArgs);

      // check and add appropriate addresses
      for (int k = 0; k < txCountBatchSize; k++) {
        final count = counts[k];

        if (count > 0) {
          // update highest
          highestIndexWithHistory = index + k;

          // reset counter
          gapCounter = 0;
        }

        // increase counter when no tx history found
        if (count == 0) {
          gapCounter++;
        }
      }
      // // cache all the transactions while waiting for the current function to finish.
      // unawaited(getTransactionCacheEarly(addressArray));
    }
    return (index: highestIndexWithHistory, addresses: addressArray);
  }

  Future<({List<Address> addresses, int index})> checkGapsLinearly(
    coinlib.HDKey node,
    DerivePathType type,
    int chain,
  ) async {
    final List<Address> addressArray = [];
    int gapCounter = 0;
    int index = 0;
    int highestIndexWithHistory = -1;

    for (; gapCounter < cryptoCurrency.maxUnusedAddressGap; index++) {
      Logging.instance.d(
        "index: $index, \t GapCounter chain=$chain ${type.name}: $gapCounter",
      );

      final derivePath = cryptoCurrency.constructDerivePath(
        derivePathType: type,
        chain: chain,
        index: index,
      );

      final coinlib.HDKey keys;
      if (isViewOnly) {
        final idx = derivePath.lastIndexOf("'/");
        final path = derivePath.substring(idx + 2);
        keys = node.derivePath(path);
      } else {
        keys = node.derivePath(derivePath);
      }

      final addressData = cryptoCurrency.getAddressForPublicKey(
        publicKey: keys.publicKey,
        derivePathType: type,
      );

      final addressString = convertAddressString(
        addressData.address.toString(),
      );

      final address = Address(
        walletId: walletId,
        value: addressString,
        publicKey: keys.publicKey.data,
        type: addressData.addressType,
        derivationIndex: index,
        derivationPath: isViewOnly
            ? null
            : (DerivationPath()..value = derivePath),
        subType: chain == 0 ? AddressSubType.receiving : AddressSubType.change,
      );

      // get address tx count
      final count = await fetchTxCount(
        addressScriptHash: cryptoCurrency.addressToScriptHash(
          address: address.value,
        ),
      );

      addressArray.add(address);

      // check and add appropriate addresses
      if (count > 0) {
        highestIndexWithHistory = index;
        // reset counter
        gapCounter = 0;
        // add info to derivations
      } else {
        // increase counter when no tx history found
        gapCounter++;
      }
    }

    return (addresses: addressArray, index: highestIndexWithHistory);
  }

  Future<List<Map<String, dynamic>>> fetchHistory(
    Iterable<String> allAddresses,
  ) async {
    try {
      final List<Map<String, dynamic>> allTxHashes = [];
      final Set<String> seen = {};

      if (await serverCanBatch) {
        final Map<int, List<List<dynamic>>> batches = {};
        final Map<int, List<String>> batchIndexToAddressListMap = {};
        const batchSizeMax = 100;
        int batchNumber = 0;
        for (int i = 0; i < allAddresses.length; i++) {
          batches[batchNumber] ??= [];
          batchIndexToAddressListMap[batchNumber] ??= [];

          final address = allAddresses.elementAt(i);
          final scriptHash = cryptoCurrency.addressToScriptHash(
            address: address,
          );
          batches[batchNumber]!.add([scriptHash]);
          batchIndexToAddressListMap[batchNumber]!.add(address);
          if (i % batchSizeMax == batchSizeMax - 1) {
            batchNumber++;
          }
        }

        for (int i = 0; i < batches.length; i++) {
          final response = await electrumXClient.getBatchHistory(
            args: batches[i]!,
          );
          for (int j = 0; j < response.length; j++) {
            final entry = response[j];
            for (int k = 0; k < entry.length; k++) {
              entry[k]["address"] = batchIndexToAddressListMap[i]![j];
              // if (!allTxHashes.contains(entry[j])) {
              allTxHashes.add(entry[k]);
              // }
            }
          }
        }
      } else {
        for (int i = 0; i < allAddresses.length; i++) {
          final addressString = allAddresses.elementAt(i);
          final scriptHash = cryptoCurrency.addressToScriptHash(
            address: addressString,
          );

          final response = await electrumXClient.getHistory(
            scripthash: scriptHash,
          );

          for (int j = 0; j < response.length; j++) {
            response[j]["address"] = addressString;
            // Keyed on the txid, not List.contains on the whole map. contains
            // is a linear scan that deep-compares every Map already collected,
            // so this was quadratic: an address with 40,000 transactions cost
            // on the order of a billion map comparisons on the main isolate,
            // which Android ends as a not-responding kill rather than a slow
            // sync. The txid plus its height is what identity means here.
            final key =
                "${response[j]["tx_hash"]}:${response[j]["height"]}"
                ":$addressString";
            if (seen.add(key)) {
              allTxHashes.add(response[j]);
            }
          }
        }
      }

      return allTxHashes;
    } catch (e, s) {
      Logging.instance.e(
        "$runtimeType._fetchHistory: ",
        error: e,
        stackTrace: s,
      );
      rethrow;
    }
  }

  /// How many transactions one sync will walk before it stops.
  ///
  /// Measured 2026-09-02 against two real Pepecoin whale addresses, because
  /// watch-only restores of them hung at 70% forever:
  ///
  ///   CoinEx vault  31,629 txs, 8.5 inputs each, 120 ms/call  -> 10.1 hours
  ///   Litecoin pool 45,301 txs, 1.0 input each, 1002 ms/call  -> 25.2 hours
  ///
  /// Those are not slow syncs, they are syncs that never end, and any dropped
  /// connection in that window restarts them. 5,000 sits far above any real
  /// personal wallet (an active miner's payout address measured 279) and far
  /// below an exchange or pool address, so it only ever bites the cases that
  /// could not finish anyway.
  ///
  /// The cap is only half the fix. Batching (see [fetchTransactionsBulk])
  /// measured against the same two addresses on 2026-09-02:
  ///
  ///   Litecoin pool  916 ms/tx sequential -> 14 ms batched  (65x)
  ///   CoinEx vault   337 ms/tx sequential -> 40 ms batched  (8.3x)
  ///
  /// which is what brings a capped walk down to minutes, and an ordinary
  /// wallet down to seconds. The first sync pays it once; the tx cache
  /// covers every sync after that.
  ///
  /// Capping is safe for the number people actually care about: updateBalance
  /// reads UTXOs, never history, so a capped wallet still shows an exact
  /// balance. Only the visible list is short, and [WalletInfoKeys
  /// .historyTruncatedTotal] records that so the UI can say so.
  ///
  /// Set to 1000 rather than 5000 because the server gets a vote. Walking
  /// 5000 transactions on top of a large unspent set made our own Electrum
  /// server answer with JSON-RPC -101 "excessive resource usage" and close
  /// the connection, which is the server behaving correctly. 1000 is still
  /// more than three times the busiest personal wallet measured, and it is
  /// far more list than anyone scrolls.
  int get maxHistoryToWalk => 1000;

  /// Above this many unspent outputs, updateUTXOs stops fetching the
  /// transaction behind every deeply confirmed one. See updateUTXOs for what
  /// that trades away and why the balance stays exact.
  ///
  /// 2000 is deliberately far above any personal wallet, including a miner
  /// paid per block for years, so the accurate path stays the normal path and
  /// only genuinely unservable addresses take the other one.
  int get deepUtxoScanThreshold => 2000;

  /// Newest-first, truncated to [maxHistoryToWalk].
  ///
  /// Unconfirmed entries carry height 0 or -1 from the server, which would
  /// sort as the oldest things in the list, so they are pinned to the top
  /// where they belong.
  List<Map<String, dynamic>> capHistory(List<Map<String, dynamic>> history) {
    if (history.length <= maxHistoryToWalk) return history;

    final sorted = [...history];
    int rank(Map<String, dynamic> e) {
      final h = e["height"];
      final height = h is int ? h : int.tryParse("$h") ?? 0;
      return height <= 0 ? 1 << 30 : height;
    }

    sorted.sort((a, b) => rank(b).compareTo(rank(a)));
    return sorted.sublist(0, maxHistoryToWalk);
  }

  /// Fetch many transactions at once, returned as txid -> verbose tx.
  ///
  /// The per-transaction loop this replaces was the whole reason a big
  /// address could not sync: one round trip per transaction, plus one per
  /// input to price it. Batching sends them a chunk per round trip instead,
  /// which is where the order-of-magnitude comes from.
  ///
  /// Everything still goes through CachedElectrumXClient, so anything already
  /// in the tx cache costs nothing, and a server that cannot batch (or a
  /// chunk that fails) falls back to the old sequential path rather than
  /// losing the wallet's history.
  Future<Map<String, Map<String, dynamic>>> fetchTransactionsBulk(
    Iterable<String> txids,
  ) async {
    final unique = txids.toSet().toList(growable: false);
    final Map<String, Map<String, dynamic>> result = {};
    if (unique.isEmpty) return result;

    // 50 rather than 100: a pool payout transaction pays hundreds of miners
    // at once, so fifty of them in one response is already megabytes.
    const chunkSize = 50;
    final canBatch = await serverCanBatch;

    for (int i = 0; i < unique.length; i += chunkSize) {
      final end = i + chunkSize;
      final chunk = unique.sublist(i, end > unique.length ? unique.length : end);

      if (canBatch) {
        try {
          final txns = await electrumXCachedClient.getBatchTransactions(
            txHashes: chunk,
            cryptoCurrency: cryptoCurrency,
          );
          for (final tx in txns) {
            final txid = tx["txid"];
            // A batch can carry an error entry in place of a result; skipping
            // it here lets the sequential fallback below pick it up next sync
            // instead of writing a malformed transaction to the db.
            if (txid is String) {
              result[txid] = tx;
            }
          }
          if (chunk.every(result.containsKey)) {
            continue;
          }
        } catch (e, s) {
          Logging.instance.w(
            "fetchTransactionsBulk batch of ${chunk.length} failed, "
            "falling back to sequential",
            error: e,
            stackTrace: s,
          );
        }
      }

      for (final txid in chunk) {
        if (result.containsKey(txid)) continue;
        result[txid] = await electrumXCachedClient.getTransaction(
          txHash: txid,
          verbose: true,
          cryptoCurrency: cryptoCurrency,
        );
      }
    }

    return result;
  }

  Future<UTXO> parseUTXO({required Map<String, dynamic> jsonUTXO}) async {
    final txn = await electrumXCachedClient.getTransaction(
      txHash: jsonUTXO["tx_hash"] as String,
      verbose: true,
      cryptoCurrency: cryptoCurrency,
    );

    final inputs = txn["vin"] as List? ?? [];
    final isCoinbase = inputs.any((e) => (e as Map?)?["coinbase"] != null);

    final vout = jsonUTXO["tx_pos"] as int;

    final outputs = txn["vout"] as List;

    String? scriptPubKey;
    String? utxoOwnerAddress;
    // get UTXO owner address
    for (final output in outputs) {
      if (output["n"] == vout) {
        scriptPubKey = output["scriptPubKey"]?["hex"] as String?;
        utxoOwnerAddress =
            output["scriptPubKey"]?["addresses"]?[0] as String? ??
            output["scriptPubKey"]?["address"] as String?;
      }
    }

    final checkBlockResult = await checkBlockUTXO(
      jsonUTXO,
      scriptPubKey,
      txn,
      utxoOwnerAddress,
    );

    final utxo = UTXO(
      walletId: walletId,
      txid: txn["txid"] as String,
      vout: vout,
      value: jsonUTXO["value"] as int,
      name: checkBlockResult.utxoLabel ?? "",
      isBlocked: checkBlockResult.blocked,
      blockedReason: checkBlockResult.blockedReason,
      isCoinbase:
          txn["is_coinbase"] as bool? ??
          txn["is-coinbase"] as bool? ??
          txn["iscoinbase"] as bool? ??
          isCoinbase,
      blockHash: txn["blockhash"] as String?,
      blockHeight: jsonUTXO["height"] as int?,
      blockTime: txn["blocktime"] as int?,
      address: utxoOwnerAddress,
    );

    return utxo;
  }

  //============================================================================

  @override
  Future<void> updateChainHeight() async {
    final height = await fetchChainHeight();
    await info.updateCachedChainHeight(newHeight: height, isar: mainDB.isar);
  }

  @override
  Future<bool> pingCheck() async {
    try {
      final result = await electrumXClient.ping();
      return result;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> updateNode() async {
    await updateElectrumX();
  }

  FeeObject? _cachedFees;

  @override
  Future<FeeObject> get fees async {
    try {
      const int f = 1, m = 5, s = 20;

      final fast = await electrumXClient.estimateFee(blocks: f);
      final medium = await electrumXClient.estimateFee(blocks: m);
      final slow = await electrumXClient.estimateFee(blocks: s);

      final feeObject = FeeObject(
        numberOfBlocksFast: f,
        numberOfBlocksAverage: m,
        numberOfBlocksSlow: s,
        fast: Amount.fromDecimal(
          fast,
          fractionDigits: info.coin.fractionDigits,
        ).raw,
        medium: Amount.fromDecimal(
          medium,
          fractionDigits: info.coin.fractionDigits,
        ).raw,
        slow: Amount.fromDecimal(
          slow,
          fractionDigits: info.coin.fractionDigits,
        ).raw,
      );

      Logging.instance.d("fetched fees: $feeObject");
      _cachedFees = feeObject;
      return _cachedFees!;
    } catch (e, s) {
      Logging.instance.e(
        "Exception rethrown from _getFees(): $e\nStack trace: $s",
        error: e,
        stackTrace: s,
      );
      if (_cachedFees == null) {
        rethrow;
      } else {
        return _cachedFees!;
      }
    }
  }

  @override
  Future<Amount> estimateFeeFor(Amount amount, BigInt feeRate) async {
    final available = info.cachedBalance.spendable;
    final utxos = _spendableUTXOs(await mainDB.getUTXOs(walletId).findAll());

    if (available == amount) {
      return amount - (await _sweepAllEstimate(feeRate, utxos));
    } else if (amount <= Amount.zero || amount > available) {
      return roughFeeEstimate(1, 2, feeRate);
    }

    Amount runningBalance = Amount(
      rawValue: BigInt.zero,
      fractionDigits: info.coin.fractionDigits,
    );
    int inputCount = 0;
    for (final output in utxos) {
      if (!output.isBlocked) {
        runningBalance += Amount(
          rawValue: BigInt.from(output.value),
          fractionDigits: info.coin.fractionDigits,
        );
        inputCount++;
        if (runningBalance > amount) {
          break;
        }
      }
    }

    final oneOutPutFee = roughFeeEstimate(inputCount, 1, feeRate);
    final twoOutPutFee = roughFeeEstimate(inputCount, 2, feeRate);

    if (runningBalance - amount > oneOutPutFee) {
      if (runningBalance - amount > oneOutPutFee + cryptoCurrency.dustLimit) {
        final change = runningBalance - amount - twoOutPutFee;
        if (change > cryptoCurrency.dustLimit &&
            runningBalance - amount - change == twoOutPutFee) {
          return runningBalance - amount - change;
        } else {
          return runningBalance - amount;
        }
      } else {
        return runningBalance - amount;
      }
    } else if (runningBalance - amount == oneOutPutFee) {
      return oneOutPutFee;
    } else {
      return twoOutPutFee;
    }
  }

  @override
  Future<void> checkReceivingAddressForTransactions() async {
    if (isViewOnly &&
        (viewOnlyType == ViewOnlyWalletType.addressOnly ||
            viewOnlyType == ViewOnlyWalletType.spark)) {
      return;
    }

    if (info.otherData[WalletInfoKeys.reuseAddress] == true) {
      try {
        throw Exception();
      } catch (_, s) {
        Logging.instance.e(
          "checkReceivingAddressForTransactions called but reuse address flag set: $s",
          error: e,
          stackTrace: s,
        );
      }
    }

    try {
      final currentReceiving = await getCurrentReceivingAddress();

      final bool needsGenerate;
      if (currentReceiving == null) {
        // no addresses in db yet for some reason.
        // Should not happen at this point...

        needsGenerate = true;
      } else {
        final txCount = await fetchTxCount(
          addressScriptHash: cryptoCurrency.addressToScriptHash(
            address: currentReceiving.value,
          ),
        );
        needsGenerate = txCount > 0 || currentReceiving.derivationIndex < 0;
      }

      if (needsGenerate) {
        await generateNewReceivingAddress();

        // TODO: [prio=low] Make sure we scan all addresses but only show one.
        if (info.otherData[WalletInfoKeys.reuseAddress] != true) {
          // TODO: get rid of this? Could cause problems (long loading/infinite loop or something)
          // keep checking until address with no tx history is set as current
          await checkReceivingAddressForTransactions();
        }
      }
    } catch (e, s) {
      Logging.instance.e(
        "Exception rethrown from _checkReceivingAddressForTransactions"
        "($cryptoCurrency): $e\n$s",
      );
      rethrow;
    }
  }

  @override
  Future<void> checkChangeAddressForTransactions() async {
    if (isViewOnly &&
        (viewOnlyType == ViewOnlyWalletType.addressOnly ||
            viewOnlyType == ViewOnlyWalletType.spark)) {
      return;
    }

    if (info.otherData[WalletInfoKeys.reuseAddress] == true) {
      try {
        throw Exception();
      } catch (_, s) {
        Logging.instance.e(
          "checkChangeAddressForTransactions called but reuse address flag set: $s",
          error: e,
          stackTrace: s,
        );
      }
    }

    try {
      final currentChange = await getCurrentChangeAddress();

      final bool needsGenerate;
      if (currentChange == null) {
        // no addresses in db yet for some reason.
        // Should not happen at this point...

        needsGenerate = true;
      } else {
        final txCount = await fetchTxCount(
          addressScriptHash: cryptoCurrency.addressToScriptHash(
            address: currentChange.value,
          ),
        );
        needsGenerate = txCount > 0 || currentChange.derivationIndex < 0;
      }

      if (needsGenerate) {
        await generateNewChangeAddress();

        // TODO: get rid of this? Could cause problems (long loading/infinite loop or something)
        // keep checking until address with no tx history is set as current
        await checkChangeAddressForTransactions();
      }
    } catch (e, s) {
      Logging.instance.e(
        "Exception rethrown from _checkChangeAddressForTransactions"
        "($cryptoCurrency): $e\n$s",
      );
      rethrow;
    }
  }

  @override
  Future<void> recover({required bool isRescan}) async {
    if (isViewOnly) {
      await recoverViewOnly(isRescan: isRescan);
      return;
    }

    final root = await getRootHDNode();

    final List<Future<({int index, List<Address> addresses})>> receiveFutures =
        [];
    final List<Future<({int index, List<Address> addresses})>> changeFutures =
        [];

    const receiveChain = 0;
    const changeChain = 1;

    const txCountBatchSize = 12;

    try {
      await refreshMutex.protect(() async {
        if (isRescan) {
          // clear cache
          await electrumXCachedClient.clearSharedTransactionCache(
            cryptoCurrency: info.coin,
          );
          // clear blockchain info
          await mainDB.deleteWalletBlockchainData(walletId);
        }

        // receiving addresses
        Logging.instance.i("checking receiving addresses...");

        final canBatch = await serverCanBatch;

        for (final type in cryptoCurrency.supportedDerivationPathTypes) {
          receiveFutures.add(
            canBatch
                ? checkGapsBatched(txCountBatchSize, root, type, receiveChain)
                : checkGapsLinearly(root, type, receiveChain),
          );
        }

        // change addresses
        Logging.instance.d("checking change addresses...");
        for (final type in cryptoCurrency.supportedDerivationPathTypes) {
          changeFutures.add(
            canBatch
                ? checkGapsBatched(txCountBatchSize, root, type, changeChain)
                : checkGapsLinearly(root, type, changeChain),
          );
        }

        // io limitations may require running these linearly instead
        final futuresResult = await Future.wait([
          Future.wait(receiveFutures),
          Future.wait(changeFutures),
        ]);

        final List<Address> addressesToStore = processGapCheckResults([
          ...futuresResult[0],
          ...futuresResult[1],
        ]);

        await mainDB.updateOrPutAddresses(addressesToStore);

        if (this is PaynymInterface) {
          final notificationAddress = await (this as PaynymInterface)
              .getMyNotificationAddress();

          await (this as BitcoinWallet).updateTransactions(
            overrideAddresses: [notificationAddress],
          );

          // get own payment code
          // isSegwit does not matter here at all
          final myCode = await (this as PaynymInterface).getPaymentCode(
            isSegwit: false,
          );

          try {
            final Set<String> codesToCheck = {};
            final nym = await PaynymIsApi().nym(myCode.toString());
            if (nym.value != null) {
              for (final follower in nym.value!.followers) {
                codesToCheck.add(follower.code);
              }
              for (final following in nym.value!.following) {
                codesToCheck.add(following.code);
              }
            }

            // restore paynym transactions
            await (this as PaynymInterface).restoreAllHistory(
              maxUnusedAddressGap: 20,
              maxNumberOfIndexesToCheck: 10000,
              paymentCodeStrings: codesToCheck,
            );
          } catch (e, s) {
            Logging.instance.e(
              "Failed to check ${PaynymIsApi.baseURL} followers/following for history during "
              "bitcoin wallet ($walletId ${info.name}) "
              "_recoverWalletFromBIP32SeedPhrase",
              error: e,
              stackTrace: s,
            );
          }
        }
      });

      unawaited(refresh());
    } catch (e, s) {
      Logging.instance.e(
        "Exception rethrown from electrumx_mixin recover(): ",
        error: e,
        stackTrace: s,
      );

      rethrow;
    }
  }

  @override
  Future<bool> updateUTXOs() async {
    final allAddresses = await fetchAddressesForElectrumXScan();

    try {
      final fetchedUtxoList = <List<Map<String, dynamic>>>[];
      // Which address each entry in fetchedUtxoList came from. Kept in step
      // by hand because empty results are skipped, so the two lists cannot be
      // matched up by index against allAddresses afterwards.
      final utxoOwners = <String>[];

      if (await serverCanBatch) {
        final Map<int, List<List<dynamic>>> batchArgs = {};
        const batchSizeMax = 10;
        int batchNumber = 0;
        for (int i = 0; i < allAddresses.length; i++) {
          batchArgs[batchNumber] ??= [];
          final scriptHash = cryptoCurrency.addressToScriptHash(
            address: allAddresses[i].value,
          );

          batchArgs[batchNumber]!.add([scriptHash]);
          if (i % batchSizeMax == batchSizeMax - 1) {
            batchNumber++;
          }
        }

        for (int i = 0; i < batchArgs.length; i++) {
          final response = await electrumXClient.getBatchUTXOs(
            args: batchArgs[i]!,
          );
          for (int k = 0; k < response.length; k++) {
            final entry = response[k];
            if (entry.isNotEmpty) {
              fetchedUtxoList.add(entry);
              final addressIndex = i * batchSizeMax + k;
              utxoOwners.add(
                addressIndex < allAddresses.length
                    ? allAddresses[addressIndex].value
                    : "",
              );
            }
          }
        }
      } else {
        for (int i = 0; i < allAddresses.length; i++) {
          final scriptHash = cryptoCurrency.addressToScriptHash(
            address: allAddresses[i].value,
          );

          final utxos = await electrumXClient.getUTXOs(scripthash: scriptHash);
          if (utxos.isNotEmpty) {
            fetchedUtxoList.add(utxos);
            utxoOwners.add(allAddresses[i].value);
          }
        }
      }

      int utxoCount = 0;
      for (final list in fetchedUtxoList) {
        utxoCount += list.length;
      }

      // parseUTXO fetches the transaction behind every unspent output, one
      // round trip each. That is fine for a personal wallet and impossible
      // for a mining pool: a Pepecoin pool address measured 44,689 unspent
      // outputs, because it collects rewards and never consolidates. Unlike
      // history this cannot be capped, since the balance IS the sum of these
      // outputs. 44,689 fetches got us JSON-RPC -101 "excessive resource
      // usage" from our own server, so the wallet sat on "Syncing" forever
      // and showed 0.
      //
      // Past minCoinbaseConfirms an output does not need its transaction:
      //
      //   value        listunspent already gave it
      //   blockHeight  listunspent already gave it
      //   address      is the address we asked about
      //   isCoinbase   only picks which confirm threshold applies, and this
      //                deep both answers are "confirmed and spendable"
      //
      // so the balance stays exact to the satoshi, which is what the wallet
      // shows and what the truncation notice promises. What the deep path
      // gives up is checkBlockUTXO, plus the cosmetic blockHash and
      // blockTime. checkBlockUTXO's job here is flagging BIP47 notification
      // outputs, which are dust sent to the notification address, so outputs
      // near the dust limit are excluded from this path and still parsed the
      // accurate way. Recent outputs are always parsed the accurate way.
      //
      // Below deepUtxoScanThreshold nothing changes at all: an ordinary
      // wallet takes the same path it always did.
      final bool deepScan = utxoCount > deepUtxoScanThreshold;
      final int tipHeight = deepScan ? await chainHeight : 0;
      final int dustGuard = cryptoCurrency.dustLimit.raw.toInt() * 4;

      // The deep path records isCoinbase as false, so it must only be taken
      // past real coinbase maturity.
      //
      // minCoinbaseConfirms is now trustworthy: it defaults to the
      // Bitcoin-derived 100 rather than to minConfirms, which is what used to
      // make it report 1 for Pepecoin and 0 for BitFinite. The floor below is
      // kept anyway. It costs nothing, and this is the one place in the
      // wallet where being wrong means handing a miner a reward the network
      // will not let them spend, so a second guard on the same number is
      // worth its two lines.
      final int deepConfirms = cryptoCurrency.minCoinbaseConfirms > 100
          ? cryptoCurrency.minCoinbaseConfirms
          : 100;

      if (!deepScan) {
        // Warm the tx cache so the per-UTXO calls below are served locally.
        // Warming rather than passing a map down because NamecoinWallet
        // overrides parseUTXO, so adding a parameter would break it.
        final utxoTxids = <String>[];
        for (final list in fetchedUtxoList) {
          for (final utxo in list) {
            final txid = utxo["tx_hash"];
            if (txid is String) utxoTxids.add(txid);
          }
        }
        if (utxoTxids.length > 1) {
          await fetchTransactionsBulk(utxoTxids);
        }
      }

      final List<UTXO> outputArray = [];
      int deepCount = 0;

      for (int i = 0; i < fetchedUtxoList.length; i++) {
        for (int j = 0; j < fetchedUtxoList[i].length; j++) {
          final json = fetchedUtxoList[i][j];

          if (deepScan) {
            final height = json["height"];
            final txid = json["tx_hash"];
            final value = json["value"];
            if (height is int &&
                height > 0 &&
                txid is String &&
                value is int &&
                value > dustGuard &&
                tipHeight - height + 1 >= deepConfirms) {
              outputArray.add(
                UTXO(
                  walletId: walletId,
                  txid: txid,
                  vout: json["tx_pos"] as int,
                  value: value,
                  name: "",
                  isBlocked: false,
                  blockedReason: null,
                  isCoinbase: false,
                  blockHash: null,
                  blockHeight: height,
                  blockTime: null,
                  address: utxoOwners[i],
                ),
              );
              deepCount++;
              continue;
            }
          }

          outputArray.add(await parseUTXO(jsonUTXO: json));
        }
      }

      if (deepCount > 0) {
        Logging.instance.i(
          "${info.name}: $utxoCount unspent outputs, "
          "$deepCount taken from listunspent without fetching their "
          "transactions. Balance is exact.",
        );
      }

      // Nothing came back, and this wallet had coins a moment ago.
      //
      // updateUTXOs deletes the wallet's outputs and then writes the new set
      // only if it is non-empty, so an empty result here does not leave the
      // old balance alone: it zeroes it. That is correct for a wallet that has
      // just spent everything, and identical on the wire to a server that
      // answered listunspent with an empty array instead of an error.
      //
      // So confirm it with a different method before believing it.
      // get_balance is one call per address that actually held something,
      // which is a small set, and it only runs on the has-coins to has-nothing
      // transition. If the server still says there is a balance, the empty
      // listunspent was wrong and the stored outputs are left untouched.
      if (outputArray.isEmpty) {
        final stored = await mainDB.getUTXOs(walletId).findAll();
        if (stored.isNotEmpty) {
          final addresses = stored
              .map((e) => e.address)
              .whereType<String>()
              .where((e) => e.isNotEmpty)
              .toSet();

          BigInt reported = BigInt.zero;
          for (final address in addresses) {
            final balance = await electrumXClient.getBalance(
              scripthash: cryptoCurrency.addressToScriptHash(address: address),
            );
            reported +=
                BigInt.from((balance["confirmed"] as int?) ?? 0) +
                BigInt.from((balance["unconfirmed"] as int?) ?? 0);
          }

          if (reported > BigInt.zero) {
            Logging.instance.w(
              "${info.name}: listunspent returned nothing for "
              "${addresses.length} address(es) that get_balance still reports "
              "$reported sats on. Keeping the stored outputs rather than "
              "zeroing the balance on one inconsistent response.",
            );
            return false;
          }
        }
      }

      return await mainDB.updateUTXOs(walletId, outputArray);
    } catch (e, s) {
      Logging.instance.e(
        "Output fetch unsuccessful: ",
        error: e,
        stackTrace: s,
      );
      return false;
    }
  }

  @override
  Future<TxData> confirmSend({required TxData txData}) async {
    try {
      Logging.instance.d("confirmSend txData: $txData");

      final txHash = await electrumXClient.broadcastTransaction(
        rawTx: txData.raw!,
      );
      Logging.instance.d("Sent txHash: $txHash");

      txData = txData.copyWith(
        usedUTXOs: txData.usedUTXOs!.map((e) {
          if (e is StandardInput) {
            return StandardInput(
              e.utxo.copyWith(used: true),
              derivePathType: e.derivePathType,
            );
          } else if (e is MwebInput) {
            return MwebInput(e.utxo.copyWith(used: true));
          } else {
            return e;
          }
        }).toList(),

        // TODO revisit setting these both
        txHash: txHash,
        txid: txHash,
      );
      // mark utxos as used
      await mainDB.putUTXOs(
        txData.usedUTXOs!
            .whereType<StandardInput>()
            .map((e) => e.utxo)
            .toList(),
      );

      return await updateSentCachedTxData(txData: txData);
    } catch (e, s) {
      Logging.instance.e(
        "Exception rethrown from confirmSend(): ",
        error: e,
        stackTrace: s,
      );
      rethrow;
    }
  }

  @override
  Future<TxData> prepareSend({required TxData txData}) async {
    try {
      if (txData.amount == null) {
        throw Exception("No recipients in attempted transaction!");
      }

      final balance =
          txData.type == TxType.mweb || txData.type == TxType.mwebPegOut
          ? info.cachedBalanceSecondary
          : info.cachedBalance;
      final feeRateType = txData.feeRateType;
      final customSatsPerVByte = txData.satsPerVByte;
      final feeRateAmount = txData.feeRateAmount;
      final utxos = txData.utxos;

      bool isSendAll = false;

      final bool coinControl = utxos != null;

      final isSendAllCoinControlUtxos =
          coinControl &&
          txData.amount!.raw ==
              utxos.map((e) => e.value).fold(BigInt.zero, (p, e) => p + e);

      final TxData result;

      if (customSatsPerVByte != null) {
        // check for send all
        isSendAll = false;
        if (txData.ignoreCachedBalanceChecks ||
            txData.amount == balance.spendable) {
          isSendAll = true;
        }

        if (coinControl &&
            this is CpfpInterface &&
            txData.amount == (balance.spendable + balance.pendingSpendable)) {
          isSendAll = true;
        }

        result = await coinSelection(
          txData: txData.copyWith(feeRateAmount: BigInt.from(-1)),
          isSendAll: isSendAll,
          utxos: utxos?.toList(),
          coinControl: coinControl,
          isSendAllCoinControlUtxos: isSendAllCoinControlUtxos,
        );
      } else if (feeRateType is FeeRateType || feeRateAmount is BigInt) {
        late final BigInt rate;
        if (feeRateType is FeeRateType) {
          BigInt fee = BigInt.zero;
          final feeObject = await fees;
          switch (feeRateType) {
            case FeeRateType.fast:
              fee = feeObject.fast;
              break;
            case FeeRateType.average:
              fee = feeObject.medium;
              break;
            case FeeRateType.slow:
              fee = feeObject.slow;
              break;
            default:
              throw ArgumentError("Invalid use of custom fee");
          }
          rate = fee;
        } else {
          rate = feeRateAmount!;
        }

        // check for send all
        isSendAll = false;
        if (txData.amount == balance.spendable) {
          isSendAll = true;
        }

        result = await coinSelection(
          txData: txData.copyWith(feeRateAmount: rate),
          isSendAll: isSendAll,
          utxos: utxos?.toList(),
          coinControl: coinControl,
          isSendAllCoinControlUtxos: isSendAllCoinControlUtxos,
        );
      } else {
        throw ArgumentError("Invalid fee rate argument provided!");
      }

      if (result.fee!.raw.toInt() < result.vSize!) {
        throw Exception(
          "Error in fee calculation: Transaction fee (${result.fee!.raw.toInt()}) cannot "
          "be less than vSize (${result.vSize})",
        );
      }

      // mweb
      if (result.type.isMweb()) {
        final fee = await (this as MwebInterface).mwebFee(txData: result);

        TxData mwebData = await coinSelection(
          txData: result.copyWith(
            recipients: result.recipients!.where((e) => !(e.isChange)).toList(),
          ),
          utxos: utxos?.toList(),
          coinControl: coinControl,
          isSendAll: isSendAll,
          isSendAllCoinControlUtxos: isSendAllCoinControlUtxos,
          overrideFeeAmount: fee.raw,
        );

        if (mwebData.type == TxType.mwebPegIn) {
          mwebData = await buildTransaction(
            txData: mwebData,
            inputsWithKeys: mwebData.usedUTXOs!,
          );
        }
        final data = await (this as MwebInterface).processMwebTransaction(
          mwebData,
        );
        Logging.instance.d("prepare MWEB send: $data");
        return data.copyWith(fee: fee);
      }

      Logging.instance.d("prepare send: $result");

      return result;
    } catch (e, s) {
      Logging.instance.e(
        "Exception rethrown from prepareSend(): ",
        error: e,
        stackTrace: s,
      );
      rethrow;
    }
  }

  @mustCallSuper
  @override
  Future<void> init() async {
    try {
      // Server features and genesis hash check deferred.
      // See _initializeServerVersionAndCheckGenesisHash.

      await super.init();
    } catch (e, s) {
      // do nothing, still allow user into wallet
      Logging.instance.w(
        "$runtimeType init() did not complete: ",
        error: e,
        stackTrace: s,
      );
    }
  }

  Future<void> _initializeServerVersionAndCheckGenesisHash() async {
    try {
      final features = await electrumXClient.getServerFeatures().timeout(
        const Duration(seconds: 5),
      );

      Logging.instance.d("features: $features");

      _serverVersion = _parseServerVersion(
        features["server_version"] as String,
      );

      if (cryptoCurrency.genesisHash != features['genesis_hash']) {
        throw Exception("Genesis hash does not match!");
      }
    } catch (e, s) {
      Logging.instance.w(
        "$runtimeType _initializeServerVersionAndCheckGenesisHash() did not complete: ",
        error: e,
        stackTrace: s,
      );
    }
  }

  @override
  Future<String> signMessage(
    final String message, {
    required final Address address,
  }) async {
    if (isViewOnly) {
      throw Exception("Cannot sign a message in a view only wallet");
    }

    final root = await getRootHDNode();
    final keyPair = root.derivePath(address.derivationPath!.value);

    final signed = coinlib.MessageSignature.sign(
      key: keyPair.privateKey,
      message: message,
      prefix: _cleanEncodedPrefixLength(
        cryptoCurrency.networkParams.messagePrefix,
      ),
    );

    return base64Encode(signed.signature.compact);
  }

  @override
  Future<bool> verifyMessage(
    final String message, {
    required final String address,
    required final String signature,
  }) async {
    final signed = coinlib.MessageSignature.fromBase64(signature);

    coinlib.Address clAddress;
    try {
      clAddress = coinlib.Address.fromString(
        normalizeAddress(address),
        cryptoCurrency.networkParams,
      );
    } catch (e, s) {
      Logging.instance.i("$e\n$s");
      return false;
    }

    return signed.verifyAddress(
      address: clAddress,
      message: message,
      prefix: _cleanEncodedPrefixLength(
        cryptoCurrency.networkParams.messagePrefix,
      ),
    );
  }

  // ===========================================================================
  // ========== Interface functions ============================================

  int estimateTxFee({required int vSize, required BigInt feeRatePerKB});
  Amount roughFeeEstimate(int inputCount, int outputCount, BigInt feeRatePerKB);

  Future<List<Address>> fetchAddressesForElectrumXScan();

  /// Certain coins need to check if the utxo should be marked
  /// as blocked as well as give a reason.
  Future<({String? blockedReason, bool blocked, String? utxoLabel})>
  checkBlockUTXO(
    Map<String, dynamic> jsonUTXO,
    String? scriptPubKeyHex,
    Map<String, dynamic> jsonTX,
    String? utxoOwnerAddress,
  );

  // ===========================================================================
  // ========== private helpers ================================================

  String _cleanEncodedPrefixLength(String prefix) {
    final messagePrefixBytes =
        cryptoCurrency.networkParams.messagePrefix.toUint8ListFromUtf8;
    // Check if prefix already has length encoded and remove as coinlib
    // recalculates it. Really not ideal....
    // TODO: clean up cryptoCurrency.networkParams.messagePrefix once its
    // determined that every usage of messagePrefix does not expect the length
    // prefixed.
    final ignoreFirstByte =
        messagePrefixBytes.first == messagePrefixBytes.length - 1;
    return (ignoreFirstByte
            ? messagePrefixBytes.sublist(1)
            : messagePrefixBytes)
        .toUtf8String;
  }

  List<UTXO> _spendableUTXOs(List<UTXO> utxos) {
    return utxos
        .where(
          (e) =>
              !e.isBlocked &&
              e.isConfirmed(
                info.cachedChainHeight,
                cryptoCurrency.minConfirms,
                cryptoCurrency.minCoinbaseConfirms,
              ),
        )
        .toList();
  }

  Future<Amount> _sweepAllEstimate(
    BigInt feeRate,
    List<UTXO> usableUTXOs,
  ) async {
    final available = usableUTXOs
        .map((e) => BigInt.from(e.value))
        .fold(BigInt.zero, (p, e) => p + e);
    final inputCount = usableUTXOs.length;

    // transaction will only have 1 output minus the fee
    final estimatedFee = roughFeeEstimate(inputCount, 1, feeRate);

    return Amount(
          rawValue: available,
          fractionDigits: info.coin.fractionDigits,
        ) -
        estimatedFee;
  }

  // stupid + fragile
  List<int>? _parseServerVersion(String version) {
    List<int>? result;
    try {
      final list = version.split(" ");
      if (list.isNotEmpty) {
        final numberStrings = list.last.split(".");

        result = numberStrings.map((e) => int.parse(e)).toList();
      }
    } catch (_) {}

    Logging.instance.d("${info.name} _parseServerVersion($version) => $result");
    return result;
  }

  // lolcashaddrs
  String normalizeAddress(String address) {
    return address;
  }

  List<Address> processGapCheckResults(
    List<({int index, List<Address> addresses})> results,
  ) {
    final List<Address> result = [];
    for (final tuple in results) {
      if (tuple.addresses.isNotEmpty) {
        int highestIndexWithHistory = -1;
        highestIndexWithHistory = max(tuple.index, highestIndexWithHistory);

        result.addAll(
          tuple.addresses.where(
            (e) => e.derivationIndex <= highestIndexWithHistory,
          ),
        );
      }
    }
    return result;
  }
  // ============== View only ==================================================

  @override
  Future<void> recoverViewOnly({bool isRescan = false}) async {
    final data = await getViewOnlyWalletData();

    final coinlib.HDKey? root;
    if (data is AddressViewOnlyWalletData || data is SparkViewOnlyWalletData) {
      root = null;
    } else {
      if ((data as ExtendedKeysViewOnlyWalletData).xPubs.length != 1) {
        throw Exception(
          "Only single xpub view only wallets are currently supported",
        );
      }

      root = coinlib.HDPublicKey.decode(data.xPubs.first.encoded);
    }

    final List<Future<({int index, List<Address> addresses})>> receiveFutures =
        [];
    final List<Future<({int index, List<Address> addresses})>> changeFutures =
        [];

    const receiveChain = 0;
    const changeChain = 1;

    const txCountBatchSize = 12;

    try {
      await refreshMutex.protect(() async {
        if (isRescan) {
          // clear cache
          await electrumXCachedClient.clearSharedTransactionCache(
            cryptoCurrency: info.coin,
          );
          // clear blockchain info
          await mainDB.deleteWalletBlockchainData(walletId);
        }

        final List<Address> addressesToStore = [];

        if (root != null) {
          // receiving addresses
          Logging.instance.i("checking receiving addresses...");

          final canBatch = await serverCanBatch;

          for (final type in cryptoCurrency.supportedDerivationPathTypes) {
            final path = cryptoCurrency.constructDerivePath(
              derivePathType: type,
              chain: 0,
              index: 0,
            );
            if (path.startsWith(
              (data as ExtendedKeysViewOnlyWalletData).xPubs.first.path,
            )) {
              receiveFutures.add(
                canBatch
                    ? checkGapsBatched(
                        txCountBatchSize,
                        root,
                        type,
                        receiveChain,
                      )
                    : checkGapsLinearly(root, type, receiveChain),
              );
            }
          }

          // change addresses
          Logging.instance.d("checking change addresses...");
          for (final type in cryptoCurrency.supportedDerivationPathTypes) {
            final path = cryptoCurrency.constructDerivePath(
              derivePathType: type,
              chain: 0,
              index: 0,
            );
            if (path.startsWith(
              (data as ExtendedKeysViewOnlyWalletData).xPubs.first.path,
            )) {
              changeFutures.add(
                canBatch
                    ? checkGapsBatched(
                        txCountBatchSize,
                        root,
                        type,
                        changeChain,
                      )
                    : checkGapsLinearly(root, type, changeChain),
              );
            }
          }

          // io limitations may require running these linearly instead
          final futuresResult = await Future.wait([
            Future.wait(receiveFutures),
            Future.wait(changeFutures),
          ]);

          addressesToStore.addAll(
            processGapCheckResults([...futuresResult[0], ...futuresResult[1]]),
          );
        } else {
          final addressString = (data as AddressViewOnlyWalletData).address;

          // Resolve the address type via the currency's own parser rather than
          // stock coinlib. Coins with a custom cashaddr alphabet (BitFinite
          // swaps q<->f in the base32 charset) fail coinlib.Address.fromString
          // with InvalidAddress; getAddressType() routes them through the
          // correct decoder (BfxCashAddr) and still handles standard coins.
          final AddressType? addressType =
              cryptoCurrency.getAddressType(addressString);

          if (addressType == null) {
            throw Exception(
              "Unsupported or invalid view only address: $addressString",
            );
          }

          addressesToStore.add(
            Address(
              walletId: walletId,
              value: addressString,
              publicKey: [],
              derivationIndex: -1,
              derivationPath: null,
              type: addressType,
              subType: AddressSubType.receiving,
            ),
          );
        }

        await mainDB.updateOrPutAddresses(addressesToStore);
      });

      unawaited(refresh());
    } catch (e, s) {
      Logging.instance.e(
        "Exception rethrown from electrumx_mixin recoverViewOnly(): ",
        error: e,
        stackTrace: s,
      );

      rethrow;
    }
  }

  // ===========================================================================
}

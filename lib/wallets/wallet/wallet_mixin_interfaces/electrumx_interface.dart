import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:coinlib_flutter/coinlib_flutter.dart' as coinlib;
import 'package:isar/isar.dart';

import '../../../electrumx_rpc/cached_electrumx_client.dart';
import '../../../electrumx_rpc/client_manager.dart';
import '../../../electrumx_rpc/electrumx_client.dart';
import '../../../models/coinlib/exp2pkh_address.dart';
import '../../../models/isar/models/blockchain_data/v2/input_v2.dart';
import '../../../models/isar/models/blockchain_data/v2/output_v2.dart';
import '../../../models/isar/models/blockchain_data/v2/transaction_v2.dart';
import '../../../models/isar/models/isar_models.dart';
import '../../../models/paymint/fee_object_model.dart';
import '../../../models/signing_data.dart';
import '../../../utilities/amount/amount.dart';
import '../../../utilities/enums/derive_path_type_enum.dart';
import '../../../utilities/enums/fee_rate_type_enum.dart';
import '../../../utilities/extensions/extensions.dart';
import '../../../utilities/logger.dart';
import '../../../utilities/paynym_is_api.dart';
import '../../crypto_currency/coins/firo.dart';
import '../../crypto_currency/interfaces/electrumx_currency_interface.dart';
import '../../models/tx_data.dart';
import '../impl/bitcoin_wallet.dart';
import '../impl/firo_wallet.dart';
import '../impl/peercoin_wallet.dart';
import '../intermediate/bip39_hd_wallet.dart';
import 'cpfp_interface.dart';
import 'paynym_interface.dart';
import 'rbf_interface.dart';

mixin ElectrumXInterface<T extends ElectrumXCurrencyInterface>
    on Bip39HDWallet<T> {
  late ElectrumXClient electrumXClient;
  late CachedElectrumXClient electrumXCachedClient;

  int? get maximumFeerate => null;

  static const _kServerBatchCutoffVersion = [1, 6];
  List<int>? _serverVersion;
  Future<bool> get serverCanBatch async {
    // Firo server added batching without incrementing version number...
    if (cryptoCurrency is Firo) {
      return true;
    }

    try {
      _serverVersion ??= _parseServerVersion(
        (await electrumXClient
            .getServerFeatures()
            .timeout(const Duration(seconds: 2)))["server_version"] as String,
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

  Future<List<({String address, Amount amount, bool isChange})>>
      _helperRecipientsConvert(
    List<String> addrs,
    List<BigInt> satValues,
  ) async {
    final List<({String address, Amount amount, bool isChange})> results = [];

    for (int i = 0; i < addrs.length; i++) {
      results.add(
        (
          address: addrs[i],
          amount: Amount(
            rawValue: satValues[i],
            fractionDigits: cryptoCurrency.fractionDigits,
          ),
          isChange: (await mainDB.isar.addresses
                  .where()
                  .walletIdEqualTo(walletId)
                  .filter()
                  .subTypeEqualTo(AddressSubType.change)
                  .and()
                  .valueEqualTo(addrs[i])
                  .valueProperty()
                  .findFirst()) !=
              null
        ),
      );
    }

    return results;
  }

  Future<TxData> coinSelection({
    required TxData txData,
    required bool coinControl,
    required bool isSendAll,
    int additionalOutputs = 0,
    List<UTXO>? utxos,
  }) async {
    Logging.instance
        .log("Starting coinSelection ----------", level: LogLevel.Info);

    // TODO: multiple recipients one day
    assert(txData.recipients!.length == 1);

    if (coinControl && utxos == null) {
      throw Exception("Coin control used where utxos is null!");
    }

    final recipientAddress = txData.recipients!.first.address;
    final satoshiAmountToSend = txData.amount!.raw;
    final int? satsPerVByte = txData.satsPerVByte;
    final selectedTxFeeRate = txData.feeRateAmount!;

    final List<UTXO> availableOutputs =
        utxos ?? await mainDB.getUTXOs(walletId).findAll();
    final currentChainHeight = await chainHeight;

    final canCPFP = this is CpfpInterface && coinControl;

    final spendableOutputs = availableOutputs
        .where(
          (e) =>
              !e.isBlocked &&
              (e.used != true) &&
              (canCPFP ||
                  e.isConfirmed(
                      currentChainHeight, cryptoCurrency.minConfirms)),
        )
        .toList();
    final spendableSatoshiValue =
        spendableOutputs.fold(BigInt.zero, (p, e) => p + BigInt.from(e.value));

    if (spendableSatoshiValue < satoshiAmountToSend) {
      throw Exception("Insufficient balance");
    } else if (spendableSatoshiValue == satoshiAmountToSend && !isSendAll) {
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
        (a, b) => (b.blockTime ?? currentChainHeight)
            .compareTo((a.blockTime ?? currentChainHeight)),
      );
    }

    Logging.instance.log(
      "spendableOutputs.length: ${spendableOutputs.length}",
      level: LogLevel.Info,
    );
    Logging.instance.log(
      "availableOutputs.length: ${availableOutputs.length}",
      level: LogLevel.Info,
    );
    Logging.instance
        .log("spendableOutputs: $spendableOutputs", level: LogLevel.Info);
    Logging.instance.log(
      "spendableSatoshiValue: $spendableSatoshiValue",
      level: LogLevel.Info,
    );
    Logging.instance
        .log("satoshiAmountToSend: $satoshiAmountToSend", level: LogLevel.Info);

    BigInt satoshisBeingUsed = BigInt.zero;
    int inputsBeingConsumed = 0;
    final List<UTXO> utxoObjectsToUse = [];

    if (!coinControl) {
      for (var i = 0;
          satoshisBeingUsed < satoshiAmountToSend &&
              i < spendableOutputs.length;
          i++) {
        utxoObjectsToUse.add(spendableOutputs[i]);
        satoshisBeingUsed += BigInt.from(spendableOutputs[i].value);
        inputsBeingConsumed += 1;
      }
      for (int i = 0;
          i < additionalOutputs &&
              inputsBeingConsumed < spendableOutputs.length;
          i++) {
        utxoObjectsToUse.add(spendableOutputs[inputsBeingConsumed]);
        satoshisBeingUsed +=
            BigInt.from(spendableOutputs[inputsBeingConsumed].value);
        inputsBeingConsumed += 1;
      }
    } else {
      satoshisBeingUsed = spendableSatoshiValue;
      utxoObjectsToUse.addAll(spendableOutputs);
      inputsBeingConsumed = spendableOutputs.length;
    }

    Logging.instance
        .log("satoshisBeingUsed: $satoshisBeingUsed", level: LogLevel.Info);
    Logging.instance
        .log("inputsBeingConsumed: $inputsBeingConsumed", level: LogLevel.Info);
    Logging.instance
        .log('utxoObjectsToUse: $utxoObjectsToUse', level: LogLevel.Info);

    // numberOfOutputs' length must always be equal to that of recipientsArray and recipientsAmtArray
    final List<String> recipientsArray = [recipientAddress];
    final List<BigInt> recipientsAmtArray = [satoshiAmountToSend];

    // gather required signing data
    final utxoSigningData = await fetchBuildTxData(utxoObjectsToUse);

    if (isSendAll) {
      return await _sendAllBuilder(
        txData: txData,
        recipientAddress: recipientAddress,
        satoshiAmountToSend: satoshiAmountToSend,
        satoshisBeingUsed: satoshisBeingUsed,
        utxoSigningData: utxoSigningData,
        satsPerVByte: satsPerVByte,
        feeRatePerKB: selectedTxFeeRate,
      );
    }

    final int vSizeForOneOutput;
    try {
      vSizeForOneOutput = (await buildTransaction(
        utxoSigningData: utxoSigningData,
        txData: txData.copyWith(
          recipients: await _helperRecipientsConvert(
            [recipientAddress],
            [satoshisBeingUsed - BigInt.one],
          ),
        ),
      ))
          .vSize!;
    } catch (e) {
      Logging.instance.log("vSizeForOneOutput: $e", level: LogLevel.Error);
      rethrow;
    }

    final int vSizeForTwoOutPuts;

    BigInt maxBI(BigInt a, BigInt b) => a > b ? a : b;

    try {
      vSizeForTwoOutPuts = (await buildTransaction(
        utxoSigningData: utxoSigningData,
        txData: txData.copyWith(
          recipients: await _helperRecipientsConvert(
            [recipientAddress, (await getCurrentChangeAddress())!.value],
            [
              satoshiAmountToSend,
              maxBI(
                BigInt.zero,
                satoshisBeingUsed - (satoshiAmountToSend + BigInt.one),
              ),
            ],
          ),
        ),
      ))
          .vSize!;
    } catch (e) {
      Logging.instance.log("vSizeForTwoOutPuts: $e", level: LogLevel.Error);
      rethrow;
    }

    // Assume 1 output, only for recipient and no change
    final feeForOneOutput = BigInt.from(
      satsPerVByte != null
          ? (satsPerVByte * vSizeForOneOutput)
          : estimateTxFee(
              vSize: vSizeForOneOutput,
              feeRatePerKB: selectedTxFeeRate,
            ),
    );
    // Assume 2 outputs, one for recipient and one for change
    final feeForTwoOutputs = BigInt.from(
      satsPerVByte != null
          ? (satsPerVByte * vSizeForTwoOutPuts)
          : estimateTxFee(
              vSize: vSizeForTwoOutPuts,
              feeRatePerKB: selectedTxFeeRate,
            ),
    );

    Logging.instance.log(
      "feeForTwoOutputs: $feeForTwoOutputs",
      level: LogLevel.Info,
    );
    Logging.instance.log(
      "feeForOneOutput: $feeForOneOutput",
      level: LogLevel.Info,
    );

    final difference = satoshisBeingUsed - satoshiAmountToSend;

    Future<TxData> singleOutputTxn() async {
      Logging.instance.log(
        'Input size: $satoshisBeingUsed',
        level: LogLevel.Info,
      );
      Logging.instance.log(
        'Recipient output size: $satoshiAmountToSend',
        level: LogLevel.Info,
      );
      Logging.instance.log(
        'Fee being paid: $difference sats',
        level: LogLevel.Info,
      );
      Logging.instance.log(
        'Estimated fee: $feeForOneOutput',
        level: LogLevel.Info,
      );
      final txnData = await buildTransaction(
        utxoSigningData: utxoSigningData,
        txData: txData.copyWith(
          recipients: await _helperRecipientsConvert(
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
        usedUTXOs: utxoSigningData.map((e) => e.utxo).toList(),
      );
    }

    // no change output required
    if (difference == feeForOneOutput) {
      Logging.instance.log('1 output in tx', level: LogLevel.Info);
      return await singleOutputTxn();
    } else if (difference < feeForOneOutput) {
      Logging.instance.log(
        'Cannot pay tx fee - checking for more outputs and trying again',
        level: LogLevel.Warning,
      );
      // try adding more outputs
      if (spendableOutputs.length > inputsBeingConsumed) {
        return coinSelection(
          txData: txData,
          isSendAll: isSendAll,
          additionalOutputs: additionalOutputs + 1,
          utxos: utxos,
          coinControl: coinControl,
        );
      }
      throw Exception("Insufficient balance to pay transaction fee");
    } else {
      if (difference > (feeForOneOutput + cryptoCurrency.dustLimit.raw)) {
        final changeOutputSize = difference - feeForTwoOutputs;
        // check if possible to add the change output
        if (changeOutputSize > cryptoCurrency.dustLimit.raw &&
            difference - changeOutputSize == feeForTwoOutputs) {
          // generate new change address if current change address has been used
          await checkChangeAddressForTransactions();
          final String newChangeAddress =
              (await getCurrentChangeAddress())!.value;

          BigInt feeBeingPaid = difference - changeOutputSize;

          // add change output
          recipientsArray.add(newChangeAddress);
          recipientsAmtArray.add(changeOutputSize);

          Logging.instance.log('2 outputs in tx', level: LogLevel.Info);
          Logging.instance.log(
            'Input size: $satoshisBeingUsed',
            level: LogLevel.Info,
          );
          Logging.instance.log(
            'Recipient output size: $satoshiAmountToSend',
            level: LogLevel.Info,
          );
          Logging.instance.log(
            'Change Output Size: $changeOutputSize',
            level: LogLevel.Info,
          );
          Logging.instance.log(
            'Difference (fee being paid): $feeBeingPaid sats',
            level: LogLevel.Info,
          );
          Logging.instance.log(
            'Estimated fee: $feeForTwoOutputs',
            level: LogLevel.Info,
          );

          TxData txnData = await buildTransaction(
            utxoSigningData: utxoSigningData,
            txData: txData.copyWith(
              recipients: await _helperRecipientsConvert(
                recipientsArray,
                recipientsAmtArray,
              ),
            ),
          );

          // make sure minimum fee is accurate if that is being used
          if (BigInt.from(txnData.vSize!) - feeBeingPaid == BigInt.one) {
            final changeOutputSize = difference - BigInt.from(txnData.vSize!);
            feeBeingPaid = difference - changeOutputSize;
            recipientsAmtArray.removeLast();
            recipientsAmtArray.add(changeOutputSize);

            Logging.instance.log(
              'Adjusted Input size: $satoshisBeingUsed',
              level: LogLevel.Info,
            );
            Logging.instance.log(
              'Adjusted Recipient output size: $satoshiAmountToSend',
              level: LogLevel.Info,
            );
            Logging.instance.log(
              'Adjusted Change Output Size: $changeOutputSize',
              level: LogLevel.Info,
            );
            Logging.instance.log(
              'Adjusted Difference (fee being paid): $feeBeingPaid sats',
              level: LogLevel.Info,
            );
            Logging.instance.log(
              'Adjusted Estimated fee: $feeForTwoOutputs',
              level: LogLevel.Info,
            );

            txnData = await buildTransaction(
              utxoSigningData: utxoSigningData,
              txData: txData.copyWith(
                recipients: await _helperRecipientsConvert(
                  recipientsArray,
                  recipientsAmtArray,
                ),
              ),
            );
          }

          return txnData.copyWith(
            fee: Amount(
              rawValue: feeBeingPaid,
              fractionDigits: cryptoCurrency.fractionDigits,
            ),
            usedUTXOs: utxoSigningData.map((e) => e.utxo).toList(),
          );
        } else {
          // Something went wrong here. It either overshot or undershot the estimated fee amount or the changeOutputSize
          // is smaller than or equal to cryptoCurrency.dustLimit. Revert to single output transaction.
          Logging.instance.log(
            'Reverting to 1 output in tx',
            level: LogLevel.Info,
          );

          return await singleOutputTxn();
        }
      }
    }

    return txData;
  }

  Future<TxData> _sendAllBuilder({
    required TxData txData,
    required String recipientAddress,
    required BigInt satoshiAmountToSend,
    required BigInt satoshisBeingUsed,
    required List<SigningData> utxoSigningData,
    required int? satsPerVByte,
    required int feeRatePerKB,
  }) async {
    Logging.instance
        .log("Attempting to send all $cryptoCurrency", level: LogLevel.Info);
    if (txData.recipients!.length != 1) {
      throw Exception(
        "Send all to more than one recipient not yet supported",
      );
    }

    final int vSizeForOneOutput = (await buildTransaction(
      utxoSigningData: utxoSigningData,
      txData: txData.copyWith(
        recipients: await _helperRecipientsConvert(
          [recipientAddress],
          [satoshisBeingUsed - BigInt.one],
        ),
      ),
    ))
        .vSize!;
    BigInt feeForOneOutput = BigInt.from(
      satsPerVByte != null
          ? (satsPerVByte * vSizeForOneOutput)
          : estimateTxFee(
              vSize: vSizeForOneOutput,
              feeRatePerKB: feeRatePerKB,
            ),
    );

    if (satsPerVByte == null) {
      final roughEstimate = roughFeeEstimate(
        utxoSigningData.length,
        1,
        feeRatePerKB,
      ).raw;
      if (feeForOneOutput < roughEstimate) {
        feeForOneOutput = roughEstimate;
      }
    }

    final amount = satoshiAmountToSend - feeForOneOutput;

    if (amount.isNegative) {
      throw Exception(
        "Estimated fee ($feeForOneOutput sats) is greater than balance!",
      );
    }

    final data = await buildTransaction(
      txData: txData.copyWith(
        recipients: await _helperRecipientsConvert(
          [recipientAddress],
          [amount],
        ),
      ),
      utxoSigningData: utxoSigningData,
    );

    return data.copyWith(
      fee: Amount(
        rawValue: feeForOneOutput,
        fractionDigits: cryptoCurrency.fractionDigits,
      ),
      usedUTXOs: utxoSigningData.map((e) => e.utxo).toList(),
    );
  }

  Future<List<SigningData>> fetchBuildTxData(
    List<UTXO> utxosToUse,
  ) async {
    // return data
    final List<SigningData> signingData = [];

    try {
      // Populating the addresses to check
      for (var i = 0; i < utxosToUse.length; i++) {
        final derivePathType =
            cryptoCurrency.addressType(address: utxosToUse[i].address!);

        signingData.add(
          SigningData(
            derivePathType: derivePathType,
            utxo: utxosToUse[i],
          ),
        );
      }

      final root = await getRootHDNode();

      for (final sd in signingData) {
        coinlib.HDPrivateKey? keys;
        final address = await mainDB.getAddress(walletId, sd.utxo.address!);
        if (address?.derivationPath != null) {
          if (address!.subType == AddressSubType.paynymReceive) {
            if (this is PaynymInterface) {
              final code = await (this as PaynymInterface)
                  .paymentCodeStringByKey(address.otherData!);

              final bip47base =
                  await (this as PaynymInterface).getBip47BaseNode();

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

        sd.keyPair = keys;
      }

      return signingData;
    } catch (e, s) {
      Logging.instance
          .log("fetchBuildTxData() threw: $e,\n$s", level: LogLevel.Error);
      rethrow;
    }
  }

  /// Builds and signs a transaction
  Future<TxData> buildTransaction({
    required TxData txData,
    required List<SigningData> utxoSigningData,
  }) async {
    Logging.instance
        .log("Starting buildTransaction ----------", level: LogLevel.Info);

    // temp tx data to show in gui while waiting for real data from server
    final List<InputV2> tempInputs = [];
    final List<OutputV2> tempOutputs = [];

    final List<coinlib.Output> prevOuts = [];

    coinlib.Transaction clTx = coinlib.Transaction(
      version: cryptoCurrency.transactionVersion,
      inputs: [],
      outputs: [],
    );

    // TODO: [prio=high]: check this opt in rbf
    final sequence = this is RbfInterface && (this as RbfInterface).flagOptInRBF
        ? 0xffffffff - 10
        : 0xffffffff - 1;

    // Add transaction inputs
    for (var i = 0; i < utxoSigningData.length; i++) {
      final txid = utxoSigningData[i].utxo.txid;

      final hash = Uint8List.fromList(
        txid.toUint8ListFromHex.reversed.toList(),
      );

      final prevOutpoint = coinlib.OutPoint(
        hash,
        utxoSigningData[i].utxo.vout,
      );

      final prevOutput = coinlib.Output.fromAddress(
        BigInt.from(utxoSigningData[i].utxo.value),
        coinlib.Address.fromString(
          utxoSigningData[i].utxo.address!,
          cryptoCurrency.networkParams,
        ),
      );

      prevOuts.add(prevOutput);

      final coinlib.Input input;

      switch (utxoSigningData[i].derivePathType) {
        case DerivePathType.bip44:
        case DerivePathType.bch44:
          input = coinlib.P2PKHInput(
            prevOut: prevOutpoint,
            publicKey: utxoSigningData[i].keyPair!.publicKey,
            sequence: sequence,
          );

        // TODO: fix this as it is (probably) wrong!
        case DerivePathType.bip49:
          throw Exception("TODO p2sh");
        // input = coinlib.P2SHMultisigInput(
        //   prevOut: prevOutpoint,
        //   program: coinlib.MultisigProgram.decompile(
        //     utxoSigningData[i].redeemScript!,
        //   ),
        //   sequence: sequence,
        // );

        case DerivePathType.bip84:
          input = coinlib.P2WPKHInput(
            prevOut: prevOutpoint,
            publicKey: utxoSigningData[i].keyPair!.publicKey,
            sequence: sequence,
          );

        case DerivePathType.bip86:
          input = coinlib.TaprootKeyInput(prevOut: prevOutpoint);

        default:
          throw UnsupportedError(
            "Unknown derivation path type found: ${utxoSigningData[i].derivePathType}",
          );
      }

      clTx = clTx.addInput(input);

      tempInputs.add(
        InputV2.isarCantDoRequiredInDefaultConstructor(
          scriptSigHex: input.scriptSig.toHex,
          scriptSigAsm: null,
          sequence: sequence,
          outpoint: OutpointV2.isarCantDoRequiredInDefaultConstructor(
            txid: utxoSigningData[i].utxo.txid,
            vout: utxoSigningData[i].utxo.vout,
          ),
          addresses: utxoSigningData[i].utxo.address == null
              ? []
              : [utxoSigningData[i].utxo.address!],
          valueStringSats: utxoSigningData[i].utxo.value.toString(),
          witness: null,
          innerRedeemScriptAsm: null,
          coinbase: null,
          walletOwns: true,
        ),
      );
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
      final output = coinlib.Output.fromAddress(
        txData.recipients![i].amount.raw,
        address,
      );

      clTx = clTx.addOutput(output);

      tempOutputs.add(
        OutputV2.isarCantDoRequiredInDefaultConstructor(
          scriptPubKeyHex: "000000",
          valueStringSats: txData.recipients![i].amount.raw.toString(),
          addresses: [
            txData.recipients![i].address.toString(),
          ],
          walletOwns: (await mainDB.isar.addresses
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

    try {
      // Sign the transaction accordingly
      for (var i = 0; i < utxoSigningData.length; i++) {
        final value = BigInt.from(utxoSigningData[i].utxo.value);
        coinlib.ECPrivateKey key = utxoSigningData[i].keyPair!.privateKey;

        if (clTx.inputs[i] is coinlib.TaprootKeyInput) {
          final taproot = coinlib.Taproot(
            internalKey: utxoSigningData[i].keyPair!.publicKey,
          );

          key = taproot.tweakPrivateKey(key);
        }

        clTx = clTx.sign(
          inputN: i,
          value: value,
          key: key,
          prevOuts: prevOuts,
        );
      }
    } catch (e, s) {
      Logging.instance.log(
        "Caught exception while signing transaction: $e\n$s",
        level: LogLevel.Error,
      );
      rethrow;
    }

    return txData.copyWith(
      raw: clTx.toHex(),
      // dirty shortcut for peercoin's weirdness
      vSize: this is PeercoinWallet ? clTx.size : clTx.vSize(),
      tempTx: TransactionV2(
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
            tempOutputs.map((e) => e.walletOwns).fold(true, (p, e) => p &= e) &&
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
      return await ClientManager.sharedInstance.getChainHeightFor(
        cryptoCurrency,
      );
    } catch (e, s) {
      if (retries > 0) {
        retries--;
        await electrumXClient.checkElectrumAdapter();
        return await fetchChainHeight(retries: retries);
      }
      Logging.instance.log(
        "Exception rethrown in fetchChainHeight\nError: $e\nStack trace: $s",
        level: LogLevel.Error,
      );
      // completer.completeError(e, s);
      // return Future.error(e, s);
      rethrow;
    }
  }

  Future<int> fetchTxCount({required String addressScriptHash}) async {
    final transactions =
        await electrumXClient.getHistory(scripthash: addressScriptHash);
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
      Logging.instance.log(
        "Exception rethrown in _getBatchTxCount(address: $addresses: $e\n$s",
        level: LogLevel.Error,
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
    );
  }

  Future<void> updateElectrumX() async {
    final failovers = nodeService
        .failoverNodesFor(currency: cryptoCurrency)
        .map(
          (e) => ElectrumXNode(
            address: e.host,
            port: e.port,
            name: e.name,
            id: e.id,
            useSSL: e.useSSL,
          ),
        )
        .toList();

    final newNode = await _getCurrentElectrumXNode();
    try {
      await electrumXClient.closeAdapter();
    } catch (e) {
      if (e.toString().contains("initialized")) {
        // Ignore.  This should happen every first time the wallet is opened.
      } else {
        Logging.instance
            .log("Error closing electrumXClient: $e", level: LogLevel.Error);
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
    coinlib.HDPrivateKey root,
    DerivePathType type,
    int chain,
  ) async {
    final List<Address> addressArray = [];
    int gapCounter = 0;
    int highestIndexWithHistory = 0;

    for (int index = 0;
        gapCounter < cryptoCurrency.maxUnusedAddressGap;
        index += txCountBatchSize) {
      Logging.instance.log(
        "index: $index, \t GapCounter $chain ${type.name}: $gapCounter",
        level: LogLevel.Info,
      );

      final List<String> txCountCallArgs = [];

      for (int j = 0; j < txCountBatchSize; j++) {
        final derivePath = cryptoCurrency.constructDerivePath(
          derivePathType: type,
          chain: chain,
          index: index + j,
        );

        final keys = root.derivePath(derivePath);

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
          derivationPath: DerivationPath()..value = derivePath,
          subType:
              chain == 0 ? AddressSubType.receiving : AddressSubType.change,
        );

        addressArray.add(address);

        txCountCallArgs.add(
          addressString,
        );
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
    coinlib.HDPrivateKey root,
    DerivePathType type,
    int chain,
  ) async {
    final List<Address> addressArray = [];
    int gapCounter = 0;
    int index = 0;
    for (; gapCounter < cryptoCurrency.maxUnusedAddressGap; index++) {
      Logging.instance.log(
        "index: $index, \t GapCounter chain=$chain ${type.name}: $gapCounter",
        level: LogLevel.Info,
      );

      final derivePath = cryptoCurrency.constructDerivePath(
        derivePathType: type,
        chain: chain,
        index: index,
      );
      final keys = root.derivePath(derivePath);
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
        derivationPath: DerivationPath()..value = derivePath,
        subType: chain == 0 ? AddressSubType.receiving : AddressSubType.change,
      );

      // get address tx count
      final count = await fetchTxCount(
        addressScriptHash: cryptoCurrency.addressToScriptHash(
          address: address.value,
        ),
      );

      // check and add appropriate addresses
      if (count > 0) {
        // add address to array
        addressArray.add(address);
        // reset counter
        gapCounter = 0;
        // add info to derivations
      } else {
        // increase counter when no tx history found
        gapCounter++;
      }
    }

    return (addresses: addressArray, index: index);
  }

  Future<List<Map<String, dynamic>>> fetchHistory(
    Iterable<String> allAddresses,
  ) async {
    try {
      final List<Map<String, dynamic>> allTxHashes = [];

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
          final response =
              await electrumXClient.getBatchHistory(args: batches[i]!);
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
            if (!allTxHashes.contains(response[j])) {
              allTxHashes.add(response[j]);
            }
          }
        }
      }

      return allTxHashes;
    } catch (e, s) {
      Logging.instance.log(
        "$runtimeType._fetchHistory: $e\n$s",
        level: LogLevel.Error,
      );
      rethrow;
    }
  }

  /// The optional (nullable) param [checkBlock] is a callback that can be used
  /// to check if a utxo should be marked as blocked
  Future<UTXO> parseUTXO({
    required Map<String, dynamic> jsonUTXO,
  }) async {
    final txn = await electrumXCachedClient.getTransaction(
      txHash: jsonUTXO["tx_hash"] as String,
      verbose: true,
      cryptoCurrency: cryptoCurrency,
    );

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
      isCoinbase: txn["is_coinbase"] as bool? ?? false,
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
    await info.updateCachedChainHeight(
      newHeight: height,
      isar: mainDB.isar,
    );
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
        ).raw.toInt(),
        medium: Amount.fromDecimal(
          medium,
          fractionDigits: info.coin.fractionDigits,
        ).raw.toInt(),
        slow: Amount.fromDecimal(
          slow,
          fractionDigits: info.coin.fractionDigits,
        ).raw.toInt(),
      );

      Logging.instance.log("fetched fees: $feeObject", level: LogLevel.Info);
      _cachedFees = feeObject;
      return _cachedFees!;
    } catch (e, s) {
      Logging.instance.log(
        "Exception rethrown from _getFees(): $e\nStack trace: $s",
        level: LogLevel.Error,
      );
      if (_cachedFees == null) {
        rethrow;
      } else {
        return _cachedFees!;
      }
    }
  }

  @override
  Future<Amount> estimateFeeFor(Amount amount, int feeRate) async {
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

      // If the reuseAddress flag is set, don't generate a new address.
      if (prefs.reuseAddress) {
        return;
      }

      if (needsGenerate) {
        await generateNewReceivingAddress();

        // TODO: get rid of this? Could cause problems (long loading/infinite loop or something)
        // keep checking until address with no tx history is set as current
        await checkReceivingAddressForTransactions();
      }
    } catch (e, s) {
      Logging.instance.log(
        "Exception rethrown from _checkReceivingAddressForTransactions"
        "($cryptoCurrency): $e\n$s",
        level: LogLevel.Error,
      );
      rethrow;
    }
  }

  @override
  Future<void> checkChangeAddressForTransactions() async {
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
      Logging.instance.log(
        "Exception rethrown from _checkChangeAddressForTransactions"
        "($cryptoCurrency): $e\n$s",
        level: LogLevel.Error,
      );
      rethrow;
    }
  }

  @override
  Future<void> recover({required bool isRescan}) async {
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
        Logging.instance.log(
          "checking receiving addresses...",
          level: LogLevel.Info,
        );

        final canBatch = await serverCanBatch;

        for (final type in cryptoCurrency.supportedDerivationPathTypes) {
          receiveFutures.add(
            canBatch
                ? checkGapsBatched(
                    txCountBatchSize,
                    root,
                    type,
                    receiveChain,
                  )
                : checkGapsLinearly(
                    root,
                    type,
                    receiveChain,
                  ),
          );
        }

        // change addresses
        Logging.instance.log(
          "checking change addresses...",
          level: LogLevel.Info,
        );
        for (final type in cryptoCurrency.supportedDerivationPathTypes) {
          changeFutures.add(
            canBatch
                ? checkGapsBatched(
                    txCountBatchSize,
                    root,
                    type,
                    changeChain,
                  )
                : checkGapsLinearly(
                    root,
                    type,
                    changeChain,
                  ),
          );
        }

        // io limitations may require running these linearly instead
        final futuresResult = await Future.wait([
          Future.wait(receiveFutures),
          Future.wait(changeFutures),
        ]);

        final receiveResults = futuresResult[0];
        final changeResults = futuresResult[1];

        final List<Address> addressesToStore = [];

        int highestReceivingIndexWithHistory = 0;

        for (final tuple in receiveResults) {
          if (tuple.addresses.isEmpty) {
            await checkReceivingAddressForTransactions();
          } else {
            highestReceivingIndexWithHistory = max(
              tuple.index,
              highestReceivingIndexWithHistory,
            );
            addressesToStore.addAll(tuple.addresses);
          }
        }

        int highestChangeIndexWithHistory = 0;
        // If restoring a wallet that never sent any funds with change, then set changeArray
        // manually. If we didn't do this, it'd store an empty array.
        for (final tuple in changeResults) {
          if (tuple.addresses.isEmpty) {
            await checkChangeAddressForTransactions();
          } else {
            highestChangeIndexWithHistory = max(
              tuple.index,
              highestChangeIndexWithHistory,
            );
            addressesToStore.addAll(tuple.addresses);
          }
        }

        // remove extra addresses to help minimize risk of creating a large gap
        addressesToStore.removeWhere(
          (e) =>
              e.subType == AddressSubType.change &&
              e.derivationIndex > highestChangeIndexWithHistory,
        );
        addressesToStore.removeWhere(
          (e) =>
              e.subType == AddressSubType.receiving &&
              e.derivationIndex > highestReceivingIndexWithHistory,
        );

        await mainDB.updateOrPutAddresses(addressesToStore);

        if (this is PaynymInterface) {
          final notificationAddress =
              await (this as PaynymInterface).getMyNotificationAddress();

          await (this as BitcoinWallet)
              .updateTransactions(overrideAddresses: [notificationAddress]);

          // get own payment code
          // isSegwit does not matter here at all
          final myCode =
              await (this as PaynymInterface).getPaymentCode(isSegwit: false);

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
            Logging.instance.log(
              "Failed to check paynym.is followers/following for history during "
              "bitcoin wallet ($walletId ${info.name}) "
              "_recoverWalletFromBIP32SeedPhrase: $e/n$s",
              level: LogLevel.Error,
            );
          }
        }
      });

      unawaited(refresh());
    } catch (e, s) {
      Logging.instance.log(
        "Exception rethrown from electrumx_mixin recover(): $e\n$s",
        level: LogLevel.Info,
      );

      rethrow;
    }
  }

  @override
  Future<bool> updateUTXOs() async {
    final allAddresses = await fetchAddressesForElectrumXScan();

    try {
      final fetchedUtxoList = <List<Map<String, dynamic>>>[];

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
          final response =
              await electrumXClient.getBatchUTXOs(args: batchArgs[i]!);
          for (final entry in response) {
            if (entry.isNotEmpty) {
              fetchedUtxoList.add(entry);
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
          }
        }
      }

      final List<UTXO> outputArray = [];

      for (int i = 0; i < fetchedUtxoList.length; i++) {
        for (int j = 0; j < fetchedUtxoList[i].length; j++) {
          final utxo = await parseUTXO(
            jsonUTXO: fetchedUtxoList[i][j],
          );

          outputArray.add(utxo);
        }
      }

      return await mainDB.updateUTXOs(walletId, outputArray);
    } catch (e, s) {
      Logging.instance.log(
        "Output fetch unsuccessful: $e\n$s",
        level: LogLevel.Error,
      );
      return false;
    }
  }

  @override
  Future<TxData> confirmSend({required TxData txData}) async {
    try {
      Logging.instance.log("confirmSend txData: $txData", level: LogLevel.Info);

      final txHash = await electrumXClient.broadcastTransaction(
        rawTx: txData.raw!,
      );
      Logging.instance.log("Sent txHash: $txHash", level: LogLevel.Info);

      txData = txData.copyWith(
        usedUTXOs:
            txData.usedUTXOs!.map((e) => e.copyWith(used: true)).toList(),

        // TODO revisit setting these both
        txHash: txHash,
        txid: txHash,
      );
      // mark utxos as used
      await mainDB.putUTXOs(txData.usedUTXOs!);

      return await updateSentCachedTxData(txData: txData);
    } catch (e, s) {
      Logging.instance.log(
        "Exception rethrown from confirmSend(): $e\n$s",
        level: LogLevel.Error,
      );
      rethrow;
    }
  }

  @override
  Future<TxData> prepareSend({required TxData txData}) async {
    try {
      final feeRateType = txData.feeRateType;
      final customSatsPerVByte = txData.satsPerVByte;
      final feeRateAmount = txData.feeRateAmount;
      final utxos = txData.utxos;

      if (customSatsPerVByte != null) {
        // check for send all
        bool isSendAll = false;
        if (txData.ignoreCachedBalanceChecks ||
            txData.amount == info.cachedBalance.spendable) {
          isSendAll = true;
        }

        final bool coinControl = utxos != null;

        if (coinControl &&
            this is CpfpInterface &&
            txData.amount ==
                (info.cachedBalance.spendable +
                    info.cachedBalance.pendingSpendable)) {
          isSendAll = true;
        }

        final result = await coinSelection(
          txData: txData.copyWith(feeRateAmount: -1),
          isSendAll: isSendAll,
          utxos: utxos?.toList(),
          coinControl: coinControl,
        );

        Logging.instance
            .log("PREPARE SEND RESULT: $result", level: LogLevel.Info);

        if (result.fee!.raw.toInt() < result.vSize!) {
          throw Exception(
            "Error in fee calculation: Transaction fee cannot be less than vSize",
          );
        }

        return result;
      } else if (feeRateType is FeeRateType || feeRateAmount is int) {
        late final int rate;
        if (feeRateType is FeeRateType) {
          int fee = 0;
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
          rate = feeRateAmount as int;
        }

        // check for send all
        bool isSendAll = false;
        if (txData.amount == info.cachedBalance.spendable) {
          isSendAll = true;
        }

        final bool coinControl = utxos != null;

        final result = await coinSelection(
          txData: txData.copyWith(
            feeRateAmount: rate,
          ),
          isSendAll: isSendAll,
          utxos: utxos?.toList(),
          coinControl: coinControl,
        );

        Logging.instance.log("prepare send: $result", level: LogLevel.Info);
        if (result.fee!.raw.toInt() < result.vSize!) {
          throw Exception(
              "Error in fee calculation: Transaction fee (${result.fee!.raw.toInt()}) cannot "
              "be less than vSize (${result.vSize})");
        }

        return result;
      } else {
        throw ArgumentError("Invalid fee rate argument provided!");
      }
    } catch (e, s) {
      Logging.instance.log(
        "Exception rethrown from prepareSend(): $e\n$s",
        level: LogLevel.Error,
      );
      rethrow;
    }
  }

  @override
  Future<void> init() async {
    try {
      final features = await electrumXClient
          .getServerFeatures()
          .timeout(const Duration(seconds: 5));

      Logging.instance.log("features: $features", level: LogLevel.Info);

      _serverVersion =
          _parseServerVersion(features["server_version"] as String);

      if (cryptoCurrency.genesisHash != features['genesis_hash']) {
        throw Exception("genesis hash does not match!");
      }
    } catch (e, s) {
      // do nothing, still allow user into wallet
      Logging.instance.log(
        "$runtimeType init() did not complete: $e\n$s",
        level: LogLevel.Warning,
      );
    }

    await super.init();
  }

  // ===========================================================================
  // ========== Interface functions ============================================

  int estimateTxFee({required int vSize, required int feeRatePerKB});
  Amount roughFeeEstimate(int inputCount, int outputCount, int feeRatePerKB);

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

  List<UTXO> _spendableUTXOs(List<UTXO> utxos) {
    return utxos
        .where(
          (e) =>
              !e.isBlocked &&
              e.isConfirmed(
                info.cachedChainHeight,
                cryptoCurrency.minConfirms,
              ),
        )
        .toList();
  }

  Future<Amount> _sweepAllEstimate(int feeRate, List<UTXO> usableUTXOs) async {
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

    Logging.instance.log(
      "${info.name} _parseServerVersion($version) => $result",
      level: LogLevel.Info,
    );
    return result;
  }

  // lolcashaddrs
  String normalizeAddress(String address) {
    return address;
  }

  // ===========================================================================
}

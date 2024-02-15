import 'dart:async';
import 'dart:math';

import 'package:bip47/src/util.dart';
import 'package:bitcoindart/bitcoindart.dart' as bitcoindart;
import 'package:coinlib_flutter/coinlib_flutter.dart' as coinlib;
import 'package:electrum_adapter/electrum_adapter.dart' as electrum_adapter;
import 'package:electrum_adapter/electrum_adapter.dart';
import 'package:isar/isar.dart';
import 'package:mutex/mutex.dart';
import 'package:stackwallet/electrumx_rpc/cached_electrumx_client.dart';
import 'package:stackwallet/electrumx_rpc/electrumx_chain_height_service.dart';
import 'package:stackwallet/electrumx_rpc/electrumx_client.dart';
import 'package:stackwallet/electrumx_rpc/subscribable_electrumx_client.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/v2/input_v2.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/v2/output_v2.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/v2/transaction_v2.dart';
import 'package:stackwallet/models/isar/models/isar_models.dart';
import 'package:stackwallet/models/paymint/fee_object_model.dart';
import 'package:stackwallet/models/signing_data.dart';
import 'package:stackwallet/services/tor_service.dart';
import 'package:stackwallet/utilities/amount/amount.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/utilities/enums/derive_path_type_enum.dart';
import 'package:stackwallet/utilities/enums/fee_rate_type_enum.dart';
import 'package:stackwallet/utilities/logger.dart';
import 'package:stackwallet/utilities/paynym_is_api.dart';
import 'package:stackwallet/utilities/prefs.dart';
import 'package:stackwallet/wallets/crypto_currency/coins/firo.dart';
import 'package:stackwallet/wallets/crypto_currency/intermediate/bip39_hd_currency.dart';
import 'package:stackwallet/wallets/models/tx_data.dart';
import 'package:stackwallet/wallets/wallet/impl/bitcoin_wallet.dart';
import 'package:stackwallet/wallets/wallet/intermediate/bip39_hd_wallet.dart';
import 'package:stackwallet/wallets/wallet/wallet_mixin_interfaces/paynym_interface.dart';
import 'package:stream_channel/stream_channel.dart';

mixin ElectrumXInterface<T extends Bip39HDCurrency> on Bip39HDWallet<T> {
  late ElectrumXClient electrumXClient;
  late StreamChannel electrumAdapterChannel;
  late ElectrumClient electrumAdapterClient;
  late CachedElectrumXClient electrumXCachedClient;
  late SubscribableElectrumXClient subscribableElectrumXClient;

  int? get maximumFeerate => null;

  int? _latestHeight;

  static const _kServerBatchCutoffVersion = [1, 6];
  List<int>? _serverVersion;
  bool get serverCanBatch {
    // Firo server added batching without incrementing version number...
    if (cryptoCurrency is Firo) {
      return true;
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
      _helperRecipientsConvert(List<String> addrs, List<int> satValues) async {
    final List<({String address, Amount amount, bool isChange})> results = [];

    for (int i = 0; i < addrs.length; i++) {
      results.add(
        (
          address: addrs[i],
          amount: Amount(
            rawValue: BigInt.from(satValues[i]),
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

    final recipientAddress = txData.recipients!.first.address;
    final satoshiAmountToSend = txData.amount!.raw.toInt();
    final int? satsPerVByte = txData.satsPerVByte;
    final selectedTxFeeRate = txData.feeRateAmount!;

    final List<UTXO> availableOutputs =
        utxos ?? await mainDB.getUTXOs(walletId).findAll();
    final currentChainHeight = await chainHeight;
    final List<UTXO> spendableOutputs = [];
    int spendableSatoshiValue = 0;

    // Build list of spendable outputs and totaling their satoshi amount
    for (final utxo in availableOutputs) {
      if (utxo.isBlocked == false &&
          utxo.isConfirmed(currentChainHeight, cryptoCurrency.minConfirms) &&
          utxo.used != true) {
        spendableOutputs.add(utxo);
        spendableSatoshiValue += utxo.value;
      }
    }

    if (coinControl) {
      if (spendableOutputs.length < availableOutputs.length) {
        throw ArgumentError("Attempted to use an unavailable utxo");
      }
    }

    // don't care about sorting if using all utxos
    if (!coinControl) {
      // sort spendable by age (oldest first)
      spendableOutputs.sort((a, b) => (b.blockTime ?? currentChainHeight)
          .compareTo((a.blockTime ?? currentChainHeight)));
      // Null check operator changed to null assignment in order to resolve a
      // `Null check operator used on a null value` error.  currentChainHeight
      // used in order to sort these unconfirmed outputs as the youngest, but we
      // could just as well use currentChainHeight + 1.
    }

    Logging.instance.log("spendableOutputs.length: ${spendableOutputs.length}",
        level: LogLevel.Info);
    Logging.instance.log("availableOutputs.length: ${availableOutputs.length}",
        level: LogLevel.Info);
    Logging.instance
        .log("spendableOutputs: $spendableOutputs", level: LogLevel.Info);
    Logging.instance.log("spendableSatoshiValue: $spendableSatoshiValue",
        level: LogLevel.Info);
    Logging.instance
        .log("satoshiAmountToSend: $satoshiAmountToSend", level: LogLevel.Info);
    // If the amount the user is trying to send is smaller than the amount that they have spendable,
    // then return 1, which indicates that they have an insufficient balance.
    if (spendableSatoshiValue < satoshiAmountToSend) {
      // return 1;
      throw Exception("Insufficient balance");
      // If the amount the user wants to send is exactly equal to the amount they can spend, then return
      // 2, which indicates that they are not leaving enough over to pay the transaction fee
    } else if (spendableSatoshiValue == satoshiAmountToSend && !isSendAll) {
      throw Exception("Insufficient balance to pay transaction fee");
      // return 2;
    }
    // If neither of these statements pass, we assume that the user has a spendable balance greater
    // than the amount they're attempting to send. Note that this value still does not account for
    // the added transaction fee, which may require an extra input and will need to be checked for
    // later on.

    // Possible situation right here
    int satoshisBeingUsed = 0;
    int inputsBeingConsumed = 0;
    List<UTXO> utxoObjectsToUse = [];

    if (!coinControl) {
      for (var i = 0;
          satoshisBeingUsed < satoshiAmountToSend &&
              i < spendableOutputs.length;
          i++) {
        utxoObjectsToUse.add(spendableOutputs[i]);
        satoshisBeingUsed += spendableOutputs[i].value;
        inputsBeingConsumed += 1;
      }
      for (int i = 0;
          i < additionalOutputs &&
              inputsBeingConsumed < spendableOutputs.length;
          i++) {
        utxoObjectsToUse.add(spendableOutputs[inputsBeingConsumed]);
        satoshisBeingUsed += spendableOutputs[inputsBeingConsumed].value;
        inputsBeingConsumed += 1;
      }
    } else {
      satoshisBeingUsed = spendableSatoshiValue;
      utxoObjectsToUse = spendableOutputs;
      inputsBeingConsumed = spendableOutputs.length;
    }

    Logging.instance
        .log("satoshisBeingUsed: $satoshisBeingUsed", level: LogLevel.Info);
    Logging.instance
        .log("inputsBeingConsumed: $inputsBeingConsumed", level: LogLevel.Info);
    Logging.instance
        .log('utxoObjectsToUse: $utxoObjectsToUse', level: LogLevel.Info);

    // numberOfOutputs' length must always be equal to that of recipientsArray and recipientsAmtArray
    List<String> recipientsArray = [recipientAddress];
    List<int> recipientsAmtArray = [satoshiAmountToSend];

    // gather required signing data
    final utxoSigningData = await fetchBuildTxData(utxoObjectsToUse);

    if (isSendAll) {
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
            [satoshisBeingUsed - 1],
          ),
        ),
      ))
          .vSize!;
      int feeForOneOutput = satsPerVByte != null
          ? (satsPerVByte * vSizeForOneOutput)
          : estimateTxFee(
              vSize: vSizeForOneOutput,
              feeRatePerKB: selectedTxFeeRate,
            );

      if (satsPerVByte == null) {
        final int roughEstimate = roughFeeEstimate(
          spendableOutputs.length,
          1,
          selectedTxFeeRate,
        ).raw.toInt();
        if (feeForOneOutput < roughEstimate) {
          feeForOneOutput = roughEstimate;
        }
      }

      final int amount = satoshiAmountToSend - feeForOneOutput;
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
          rawValue: BigInt.from(feeForOneOutput),
          fractionDigits: cryptoCurrency.fractionDigits,
        ),
        usedUTXOs: utxoSigningData.map((e) => e.utxo).toList(),
      );
    }

    final int vSizeForOneOutput;
    try {
      vSizeForOneOutput = (await buildTransaction(
        utxoSigningData: utxoSigningData,
        txData: txData.copyWith(
          recipients: await _helperRecipientsConvert(
            [recipientAddress],
            [satoshisBeingUsed - 1],
          ),
        ),
      ))
          .vSize!;
    } catch (e) {
      Logging.instance.log("vSizeForOneOutput: $e", level: LogLevel.Error);
      rethrow;
    }

    final int vSizeForTwoOutPuts;
    try {
      vSizeForTwoOutPuts = (await buildTransaction(
        utxoSigningData: utxoSigningData,
        txData: txData.copyWith(
          recipients: await _helperRecipientsConvert(
            [recipientAddress, (await getCurrentChangeAddress())!.value],
            [
              satoshiAmountToSend,
              max(0, satoshisBeingUsed - satoshiAmountToSend - 1)
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
    final feeForOneOutput = satsPerVByte != null
        ? (satsPerVByte * vSizeForOneOutput)
        : estimateTxFee(
            vSize: vSizeForOneOutput,
            feeRatePerKB: selectedTxFeeRate,
          );
    // Assume 2 outputs, one for recipient and one for change
    final feeForTwoOutputs = satsPerVByte != null
        ? (satsPerVByte * vSizeForTwoOutPuts)
        : estimateTxFee(
            vSize: vSizeForTwoOutPuts,
            feeRatePerKB: selectedTxFeeRate,
          );

    Logging.instance
        .log("feeForTwoOutputs: $feeForTwoOutputs", level: LogLevel.Info);
    Logging.instance
        .log("feeForOneOutput: $feeForOneOutput", level: LogLevel.Info);

    if (satoshisBeingUsed - satoshiAmountToSend > feeForOneOutput) {
      if (satoshisBeingUsed - satoshiAmountToSend >
          feeForOneOutput + cryptoCurrency.dustLimit.raw.toInt()) {
        // Here, we know that theoretically, we may be able to include another output(change) but we first need to
        // factor in the value of this output in satoshis.
        int changeOutputSize =
            satoshisBeingUsed - satoshiAmountToSend - feeForTwoOutputs;
        // We check to see if the user can pay for the new transaction with 2 outputs instead of one. If they can and
        // the second output's size > cryptoCurrency.dustLimit satoshis, we perform the mechanics required to properly generate and use a new
        // change address.
        if (changeOutputSize > cryptoCurrency.dustLimit.raw.toInt() &&
            satoshisBeingUsed - satoshiAmountToSend - changeOutputSize ==
                feeForTwoOutputs) {
          // generate new change address if current change address has been used
          await checkChangeAddressForTransactions();
          final String newChangeAddress =
              (await getCurrentChangeAddress())!.value;

          int feeBeingPaid =
              satoshisBeingUsed - satoshiAmountToSend - changeOutputSize;

          recipientsArray.add(newChangeAddress);
          recipientsAmtArray.add(changeOutputSize);
          // At this point, we have the outputs we're going to use, the amounts to send along with which addresses
          // we intend to send these amounts to. We have enough to send instructions to build the transaction.
          Logging.instance.log('2 outputs in tx', level: LogLevel.Info);
          Logging.instance
              .log('Input size: $satoshisBeingUsed', level: LogLevel.Info);
          Logging.instance.log('Recipient output size: $satoshiAmountToSend',
              level: LogLevel.Info);
          Logging.instance.log('Change Output Size: $changeOutputSize',
              level: LogLevel.Info);
          Logging.instance.log(
              'Difference (fee being paid): $feeBeingPaid sats',
              level: LogLevel.Info);
          Logging.instance
              .log('Estimated fee: $feeForTwoOutputs', level: LogLevel.Info);

          var txn = await buildTransaction(
            utxoSigningData: utxoSigningData,
            txData: txData.copyWith(
              recipients: await _helperRecipientsConvert(
                recipientsArray,
                recipientsAmtArray,
              ),
            ),
          );

          // make sure minimum fee is accurate if that is being used
          if (txn.vSize! - feeBeingPaid == 1) {
            int changeOutputSize =
                satoshisBeingUsed - satoshiAmountToSend - txn.vSize!;
            feeBeingPaid =
                satoshisBeingUsed - satoshiAmountToSend - changeOutputSize;
            recipientsAmtArray.removeLast();
            recipientsAmtArray.add(changeOutputSize);
            Logging.instance.log('Adjusted Input size: $satoshisBeingUsed',
                level: LogLevel.Info);
            Logging.instance.log(
                'Adjusted Recipient output size: $satoshiAmountToSend',
                level: LogLevel.Info);
            Logging.instance.log(
                'Adjusted Change Output Size: $changeOutputSize',
                level: LogLevel.Info);
            Logging.instance.log(
                'Adjusted Difference (fee being paid): $feeBeingPaid sats',
                level: LogLevel.Info);
            Logging.instance.log('Adjusted Estimated fee: $feeForTwoOutputs',
                level: LogLevel.Info);
            txn = await buildTransaction(
              utxoSigningData: utxoSigningData,
              txData: txData.copyWith(
                recipients: await _helperRecipientsConvert(
                  recipientsArray,
                  recipientsAmtArray,
                ),
              ),
            );
          }

          return txn.copyWith(
            fee: Amount(
              rawValue: BigInt.from(feeBeingPaid),
              fractionDigits: cryptoCurrency.fractionDigits,
            ),
            usedUTXOs: utxoSigningData.map((e) => e.utxo).toList(),
          );
        } else {
          // Something went wrong here. It either overshot or undershot the estimated fee amount or the changeOutputSize
          // is smaller than or equal to cryptoCurrency.dustLimit. Revert to single output transaction.
          Logging.instance.log('1 output in tx', level: LogLevel.Info);
          Logging.instance
              .log('Input size: $satoshisBeingUsed', level: LogLevel.Info);
          Logging.instance.log('Recipient output size: $satoshiAmountToSend',
              level: LogLevel.Info);
          Logging.instance.log(
              'Difference (fee being paid): ${satoshisBeingUsed - satoshiAmountToSend} sats',
              level: LogLevel.Info);
          Logging.instance
              .log('Estimated fee: $feeForOneOutput', level: LogLevel.Info);
          final txn = await buildTransaction(
            utxoSigningData: utxoSigningData,
            txData: txData.copyWith(
              recipients: await _helperRecipientsConvert(
                recipientsArray,
                recipientsAmtArray,
              ),
            ),
          );

          return txn.copyWith(
            fee: Amount(
              rawValue: BigInt.from(satoshisBeingUsed - satoshiAmountToSend),
              fractionDigits: cryptoCurrency.fractionDigits,
            ),
            usedUTXOs: utxoSigningData.map((e) => e.utxo).toList(),
          );
        }
      } else {
        // No additional outputs needed since adding one would mean that it'd be smaller than cryptoCurrency.dustLimit sats
        // which makes it uneconomical to add to the transaction. Here, we pass data directly to instruct
        // the wallet to begin crafting the transaction that the user requested.
        Logging.instance.log('1 output in tx', level: LogLevel.Info);
        Logging.instance
            .log('Input size: $satoshisBeingUsed', level: LogLevel.Info);
        Logging.instance.log('Recipient output size: $satoshiAmountToSend',
            level: LogLevel.Info);
        Logging.instance.log(
            'Difference (fee being paid): ${satoshisBeingUsed - satoshiAmountToSend} sats',
            level: LogLevel.Info);
        Logging.instance
            .log('Estimated fee: $feeForOneOutput', level: LogLevel.Info);
        final txn = await buildTransaction(
          utxoSigningData: utxoSigningData,
          txData: txData.copyWith(
            recipients: await _helperRecipientsConvert(
              recipientsArray,
              recipientsAmtArray,
            ),
          ),
        );

        return txn.copyWith(
          fee: Amount(
            rawValue: BigInt.from(satoshisBeingUsed - satoshiAmountToSend),
            fractionDigits: cryptoCurrency.fractionDigits,
          ),
          usedUTXOs: utxoSigningData.map((e) => e.utxo).toList(),
        );
      }
    } else if (satoshisBeingUsed - satoshiAmountToSend == feeForOneOutput) {
      // In this scenario, no additional change output is needed since inputs - outputs equal exactly
      // what we need to pay for fees. Here, we pass data directly to instruct the wallet to begin
      // crafting the transaction that the user requested.
      Logging.instance.log('1 output in tx', level: LogLevel.Info);
      Logging.instance
          .log('Input size: $satoshisBeingUsed', level: LogLevel.Info);
      Logging.instance.log('Recipient output size: $satoshiAmountToSend',
          level: LogLevel.Info);
      Logging.instance.log(
          'Fee being paid: ${satoshisBeingUsed - satoshiAmountToSend} sats',
          level: LogLevel.Info);
      Logging.instance
          .log('Estimated fee: $feeForOneOutput', level: LogLevel.Info);
      final txn = await buildTransaction(
        utxoSigningData: utxoSigningData,
        txData: txData.copyWith(
          recipients: await _helperRecipientsConvert(
            recipientsArray,
            recipientsAmtArray,
          ),
        ),
      );
      return txn.copyWith(
        fee: Amount(
          rawValue: BigInt.from(feeForOneOutput),
          fractionDigits: cryptoCurrency.fractionDigits,
        ),
        usedUTXOs: utxoSigningData.map((e) => e.utxo).toList(),
      );
    } else {
      // Remember that returning 2 indicates that the user does not have a sufficient balance to
      // pay for the transaction fee. Ideally, at this stage, we should check if the user has any
      // additional outputs they're able to spend and then recalculate fees.
      Logging.instance.log(
          'Cannot pay tx fee - checking for more outputs and trying again',
          level: LogLevel.Warning);
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
      // return 2;
    }
  }

  Future<List<SigningData>> fetchBuildTxData(
    List<UTXO> utxosToUse,
  ) async {
    // return data
    List<SigningData> signingData = [];

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

      final convertedNetwork = bitcoindart.NetworkType(
        messagePrefix: cryptoCurrency.networkParams.messagePrefix,
        bech32: cryptoCurrency.networkParams.bech32Hrp,
        bip32: bitcoindart.Bip32Type(
          public: cryptoCurrency.networkParams.pubHDPrefix,
          private: cryptoCurrency.networkParams.privHDPrefix,
        ),
        pubKeyHash: cryptoCurrency.networkParams.p2pkhPrefix,
        scriptHash: cryptoCurrency.networkParams.p2shPrefix,
        wif: cryptoCurrency.networkParams.wifPrefix,
      );

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
              "Failed to fetch signing data. Local db corrupt. Rescan wallet.");
        }

        // final coinlib.Input input;

        final pubKey = keys.publicKey.data;
        final bitcoindart.PaymentData data;

        switch (sd.derivePathType) {
          case DerivePathType.bip44:
            // input = coinlib.P2PKHInput(
            //   prevOut: coinlib.OutPoint.fromHex(sd.utxo.txid, sd.utxo.vout),
            //   publicKey: keys.publicKey,
            // );

            data = bitcoindart
                .P2PKH(
                  data: bitcoindart.PaymentData(
                    pubkey: pubKey,
                  ),
                  network: convertedNetwork,
                )
                .data;
            break;

          case DerivePathType.bip49:
            final p2wpkh = bitcoindart
                .P2WPKH(
                  data: bitcoindart.PaymentData(
                    pubkey: pubKey,
                  ),
                  network: convertedNetwork,
                )
                .data;
            sd.redeemScript = p2wpkh.output;
            data = bitcoindart
                .P2SH(
                  data: bitcoindart.PaymentData(redeem: p2wpkh),
                  network: convertedNetwork,
                )
                .data;
            break;

          case DerivePathType.bip84:
            // input = coinlib.P2WPKHInput(
            //   prevOut: coinlib.OutPoint.fromHex(sd.utxo.txid, sd.utxo.vout),
            //   publicKey: keys.publicKey,
            // );
            data = bitcoindart
                .P2WPKH(
                  data: bitcoindart.PaymentData(
                    pubkey: pubKey,
                  ),
                  network: convertedNetwork,
                )
                .data;
            break;

          default:
            throw Exception("DerivePathType unsupported");
        }

        // sd.output = input.script!.compiled;
        sd.output = data.output!;
        sd.keyPair = bitcoindart.ECPair.fromPrivateKey(
          keys.privateKey.data,
          compressed: keys.privateKey.compressed,
          network: convertedNetwork,
        );
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

    // TODO: use coinlib

    final txb = bitcoindart.TransactionBuilder(
      network: bitcoindart.NetworkType(
        messagePrefix: cryptoCurrency.networkParams.messagePrefix,
        bech32: cryptoCurrency.networkParams.bech32Hrp,
        bip32: bitcoindart.Bip32Type(
          public: cryptoCurrency.networkParams.pubHDPrefix,
          private: cryptoCurrency.networkParams.privHDPrefix,
        ),
        pubKeyHash: cryptoCurrency.networkParams.p2pkhPrefix,
        scriptHash: cryptoCurrency.networkParams.p2shPrefix,
        wif: cryptoCurrency.networkParams.wifPrefix,
      ),
      maximumFeeRate: maximumFeerate,
    );
    const version = 1; // TODO possibly override this for certain coins?
    txb.setVersion(version);

    // temp tx data to show in gui while waiting for real data from server
    final List<InputV2> tempInputs = [];
    final List<OutputV2> tempOutputs = [];

    // Add transaction inputs
    for (var i = 0; i < utxoSigningData.length; i++) {
      final txid = utxoSigningData[i].utxo.txid;
      txb.addInput(
        txid,
        utxoSigningData[i].utxo.vout,
        null,
        utxoSigningData[i].output!,
        cryptoCurrency.networkParams.bech32Hrp,
      );

      tempInputs.add(
        InputV2.isarCantDoRequiredInDefaultConstructor(
          scriptSigHex: txb.inputs.first.script?.toHex,
          scriptSigAsm: null,
          sequence: 0xffffffff - 1,
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
      txb.addOutput(
        normalizeAddress(txData.recipients![i].address),
        txData.recipients![i].amount.raw.toInt(),
        cryptoCurrency.networkParams.bech32Hrp,
      );

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
        txb.sign(
          vin: i,
          keyPair: utxoSigningData[i].keyPair!,
          witnessValue: utxoSigningData[i].utxo.value,
          redeemScript: utxoSigningData[i].redeemScript,
          overridePrefix: cryptoCurrency.networkParams.bech32Hrp,
        );
      }
    } catch (e, s) {
      Logging.instance.log("Caught exception while signing transaction: $e\n$s",
          level: LogLevel.Error);
      rethrow;
    }

    final builtTx = txb.build(cryptoCurrency.networkParams.bech32Hrp);
    final vSize = builtTx.virtualSize();

    return txData.copyWith(
      raw: builtTx.toHex(),
      vSize: vSize,
      tempTx: TransactionV2(
        walletId: walletId,
        blockHash: null,
        hash: builtTx.getId(),
        txid: builtTx.getId(),
        height: null,
        timestamp: DateTime.timestamp().millisecondsSinceEpoch ~/ 1000,
        inputs: List.unmodifiable(tempInputs),
        outputs: List.unmodifiable(tempOutputs),
        version: version,
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

  Future<int> fetchChainHeight() async {
    try {
      // Don't set a stream subscription if one already exists.
      await _manageChainHeightSubscription();

      return _latestHeight ?? info.cachedChainHeight;
    } catch (e, s) {
      Logging.instance.log(
          "Exception rethrown in fetchChainHeight\nError: $e\nStack trace: $s",
          level: LogLevel.Error);
      // completer.completeError(e, s);
      // return Future.error(e, s);
      rethrow;
    }
  }

  // Mutex to control subscription management access.
  static final Mutex _subMutex = Mutex();

  Future<void> _manageChainHeightSubscription() async {
    // Set the timeout period for the chain height subscription.
    const timeout = Duration(seconds: 10);

    await _subMutex.protect(() async {
      if (ElectrumxChainHeightService.subscriptions[cryptoCurrency.coin] ==
          null) {
        await _createSubscription();
      } else if (ElectrumxChainHeightService
          .subscriptions[cryptoCurrency.coin]!.isPaused) {
        ElectrumxChainHeightService.subscriptions[cryptoCurrency.coin]!
            .resume();
      }
    });

    // Ensure _latestHeight is updated before proceeding.
    if (_latestHeight == null &&
        ElectrumxChainHeightService.completers[cryptoCurrency.coin] != null) {
      try {
        // Use a timeout to wait for the completer to avoid indefinite blocking.
        _latestHeight = await ElectrumxChainHeightService
            .completers[cryptoCurrency.coin]!.future
            .timeout(timeout);
      } catch (e) {
        Logging.instance
            .log("Timeout waiting for chain height", level: LogLevel.Error);
        // Clear this coin's subscription.
        await ElectrumxChainHeightService.subscriptions[cryptoCurrency.coin]!
            .cancel();
        ElectrumxChainHeightService.subscriptions[cryptoCurrency.coin] = null;
      }
    }
  }

  Future<void> _createSubscription() async {
    final completer = Completer<int>();
    ElectrumxChainHeightService.completers[cryptoCurrency.coin] = completer;

    // Make sure we only complete once.
    final isFirstResponse = _latestHeight == null;

    // Subscribe to block headers.
    final subscription = subscribableElectrumXClient.subscribeToBlockHeaders();

    // Set stream subscription.
    ElectrumxChainHeightService.subscriptions[cryptoCurrency.coin] =
        subscription.responseStream.asBroadcastStream().listen((event) {
      final response = event;
      if (response != null &&
          response is Map &&
          response.containsKey('height')) {
        final int chainHeight = response['height'] as int;
        // print("Current chain height: $chainHeight");

        _latestHeight = chainHeight;

        if (isFirstResponse) {
          // If the completer is not completed, complete it.
          if (!ElectrumxChainHeightService
              .completers[cryptoCurrency.coin]!.isCompleted) {
            // Complete the completer, returning the chain height.
            ElectrumxChainHeightService.completers[cryptoCurrency.coin]!
                .complete(chainHeight);
          }
        }
      } else {
        Logging.instance.log(
            "blockchain.headers.subscribe returned malformed response\n"
            "Response: $response",
            level: LogLevel.Error);
      }
    });
  }

  Future<int> fetchTxCount({required String addressScriptHash}) async {
    final transactions =
        await electrumXClient.getHistory(scripthash: addressScriptHash);
    return transactions.length;
  }

  Future<Map<int, int>> fetchTxCountBatched({
    required Map<String, String> addresses,
  }) async {
    try {
      final Map<String, List<dynamic>> args = {};
      for (final entry in addresses.entries) {
        args[entry.key] = [
          cryptoCurrency.addressToScriptHash(address: entry.value),
        ];
      }
      final response = await electrumXClient.getBatchHistory(args: args);

      final Map<int, int> result = {};
      for (final entry in response.entries) {
        result[entry.key] = entry.value.length;
      }
      return result;
    } catch (e, s) {
      Logging.instance.log(
          "Exception rethrown in _getBatchTxCount(address: $addresses: $e\n$s",
          level: LogLevel.Error);
      rethrow;
    }
  }

  Future<ElectrumXNode> getCurrentElectrumXNode() async {
    final node = getCurrentNode();

    return ElectrumXNode(
      address: node.host,
      port: node.port,
      name: node.name,
      useSSL: node.useSSL,
      id: node.id,
    );
  }

  Future<void> updateElectrumX({required ElectrumXNode newNode}) async {
    final failovers = nodeService
        .failoverNodesFor(coin: cryptoCurrency.coin)
        .map((e) => ElectrumXNode(
              address: e.host,
              port: e.port,
              name: e.name,
              id: e.id,
              useSSL: e.useSSL,
            ))
        .toList();

    final newNode = await getCurrentElectrumXNode();
    electrumXClient = ElectrumXClient.from(
      node: newNode,
      prefs: prefs,
      failovers: failovers,
      coin: cryptoCurrency.coin,
    );
    electrumAdapterChannel = await electrum_adapter.connect(
      newNode.address,
      port: newNode.port,
      acceptUnverified: true,
      useSSL: newNode.useSSL,
      proxyInfo: Prefs.instance.useTor
          ? TorService.sharedInstance.getProxyInfo()
          : null,
    );
    if (electrumXClient.coin == Coin.firo ||
        electrumXClient.coin == Coin.firoTestNet) {
      electrumAdapterClient = FiroElectrumClient(
          electrumAdapterChannel,
          newNode.address,
          newNode.port,
          newNode.useSSL,
          Prefs.instance.useTor
              ? TorService.sharedInstance.getProxyInfo()
              : null);
    } else {
      electrumAdapterClient = ElectrumClient(
          electrumAdapterChannel,
          newNode.address,
          newNode.port,
          newNode.useSSL,
          Prefs.instance.useTor
              ? TorService.sharedInstance.getProxyInfo()
              : null);
    }
    electrumXCachedClient = CachedElectrumXClient.from(
      electrumXClient: electrumXClient,
      electrumAdapterClient: electrumAdapterClient,
    );
    subscribableElectrumXClient = SubscribableElectrumXClient.from(
      node: newNode,
      prefs: prefs,
      failovers: failovers,
    );
    await subscribableElectrumXClient.connect(
        host: newNode.address, port: newNode.port);
  }

  //============================================================================

  Future<({List<Address> addresses, int index})> checkGapsBatched(
    int txCountBatchSize,
    coinlib.HDPrivateKey root,
    DerivePathType type,
    int chain,
  ) async {
    List<Address> addressArray = [];
    int gapCounter = 0;
    int highestIndexWithHistory = 0;

    for (int index = 0;
        index < cryptoCurrency.maxNumberOfIndexesToCheck &&
            gapCounter < cryptoCurrency.maxUnusedAddressGap;
        index += txCountBatchSize) {
      List<String> iterationsAddressArray = [];
      Logging.instance.log(
          "index: $index, \t GapCounter $chain ${type.name}: $gapCounter",
          level: LogLevel.Info);

      final _id = "k_$index";
      Map<String, String> txCountCallArgs = {};

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

        txCountCallArgs.addAll({
          "${_id}_$j": addressString,
        });
      }

      // get address tx counts
      final counts = await fetchTxCountBatched(addresses: txCountCallArgs);

      // check and add appropriate addresses
      for (int k = 0; k < txCountBatchSize; k++) {
        int count = (counts["${_id}_$k"] == null) ? 0 : counts["${_id}_$k"]!;

        if (count > 0) {
          iterationsAddressArray.add(txCountCallArgs["${_id}_$k"]!);

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
    List<Address> addressArray = [];
    int gapCounter = 0;
    int index = 0;
    for (;
        index < cryptoCurrency.maxNumberOfIndexesToCheck &&
            gapCounter < cryptoCurrency.maxUnusedAddressGap;
        index++) {
      Logging.instance.log(
          "index: $index, \t GapCounter chain=$chain ${type.name}: $gapCounter",
          level: LogLevel.Info);

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
      List<Map<String, dynamic>> allTxHashes = [];

      if (serverCanBatch) {
        final Map<String, Map<String, List<dynamic>>> batches = {};
        final Map<int, String> requestIdToAddressMap = {};
        const batchSizeMax = 100;
        int batchNumber = 0;
        for (int i = 0; i < allAddresses.length; i++) {
          if (batches["$batchNumber"] == null) {
            batches["$batchNumber"] = {};
          }
          final scriptHash = cryptoCurrency.addressToScriptHash(
            address: allAddresses.elementAt(i),
          );
          // final id = Logger.isTestEnv ? "$i" : const Uuid().v1();
          // TODO [prio=???]: Pass request IDs to electrum_adapter.
          requestIdToAddressMap[i] = allAddresses.elementAt(i);
          batches["$batchNumber"]!.addAll({
            "$i": [scriptHash]
          });
          if (i % batchSizeMax == batchSizeMax - 1) {
            batchNumber++;
          }
        }

        for (int i = 0; i < batches.length; i++) {
          final response =
              await electrumXClient.getBatchHistory(args: batches["$i"]!);
          for (final entry in response.entries) {
            for (int j = 0; j < entry.value.length; j++) {
              entry.value[j]["address"] = requestIdToAddressMap[entry.key];
              if (!allTxHashes.contains(entry.value[j])) {
                allTxHashes.add(entry.value[j]);
              }
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
      Logging.instance.log("_fetchHistory: $e\n$s", level: LogLevel.Error);
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
      coin: cryptoCurrency.coin,
    );

    print("txn: $txn");

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
    final node = await getCurrentElectrumXNode();
    await updateElectrumX(newNode: node);
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
          fractionDigits: info.coin.decimals,
        ).raw.toInt(),
        medium: Amount.fromDecimal(
          medium,
          fractionDigits: info.coin.decimals,
        ).raw.toInt(),
        slow: Amount.fromDecimal(
          slow,
          fractionDigits: info.coin.decimals,
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
      fractionDigits: info.coin.decimals,
    );
    int inputCount = 0;
    for (final output in utxos) {
      if (!output.isBlocked) {
        runningBalance += Amount(
          rawValue: BigInt.from(output.value),
          fractionDigits: info.coin.decimals,
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
              coin: info.coin);
          // clear blockchain info
          await mainDB.deleteWalletBlockchainData(walletId);
        }

        // receiving addresses
        Logging.instance.log(
          "checking receiving addresses...",
          level: LogLevel.Info,
        );

        for (final type in cryptoCurrency.supportedDerivationPathTypes) {
          receiveFutures.add(
            serverCanBatch
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
            serverCanBatch
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
        addressesToStore.removeWhere((e) =>
            e.subType == AddressSubType.change &&
            e.derivationIndex > highestChangeIndexWithHistory);
        addressesToStore.removeWhere((e) =>
            e.subType == AddressSubType.receiving &&
            e.derivationIndex > highestReceivingIndexWithHistory);

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
          level: LogLevel.Info);

      rethrow;
    }
  }

  @override
  Future<bool> updateUTXOs() async {
    final allAddresses = await fetchAddressesForElectrumXScan();

    try {
      final fetchedUtxoList = <List<Map<String, dynamic>>>[];

      if (serverCanBatch) {
        final Map<int, Map<String, List<dynamic>>> batches = {};
        const batchSizeMax = 10;
        int batchNumber = 0;
        for (int i = 0; i < allAddresses.length; i++) {
          if (batches[batchNumber] == null) {
            batches[batchNumber] = {};
          }
          final scriptHash = cryptoCurrency.addressToScriptHash(
            address: allAddresses[i].value,
          );

          batches[batchNumber]!.addAll({
            scriptHash: [scriptHash]
          });
          if (i % batchSizeMax == batchSizeMax - 1) {
            batchNumber++;
          }
        }

        for (int i = 0; i < batches.length; i++) {
          final response =
              await electrumXClient.getBatchUTXOs(args: batches[i]!);
          for (final entry in response.entries) {
            if (entry.value.isNotEmpty) {
              fetchedUtxoList.add(entry.value);
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
      Logging.instance.log("Exception rethrown from confirmSend(): $e\n$s",
          level: LogLevel.Error);
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
        if (txData.amount == info.cachedBalance.spendable) {
          isSendAll = true;
        }

        final bool coinControl = utxos != null;

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
              "Error in fee calculation: Transaction fee cannot be less than vSize");
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
              "Error in fee calculation: Transaction fee cannot be less than vSize");
        }

        return result;
      } else {
        throw ArgumentError("Invalid fee rate argument provided!");
      }
    } catch (e, s) {
      Logging.instance.log("Exception rethrown from prepareSend(): $e\n$s",
          level: LogLevel.Error);
      rethrow;
    }
  }

  @override
  Future<void> checkSaveInitialReceivingAddress() async {}

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
          fractionDigits: info.coin.decimals,
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

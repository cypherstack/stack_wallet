import 'dart:convert';

import 'package:isar/isar.dart';

import '../../../models/isar/models/blockchain_data/address.dart';
import '../../../models/isar/models/blockchain_data/transaction.dart';
import '../../../models/isar/models/blockchain_data/v2/input_v2.dart';
import '../../../models/isar/models/blockchain_data/v2/output_v2.dart';
import '../../../models/isar/models/blockchain_data/v2/transaction_v2.dart';
import '../../../models/isar/ordinal.dart';
import '../../../utilities/amount/amount.dart';
import '../../../utilities/logger.dart';
import '../../crypto_currency/crypto_currency.dart';
import '../../crypto_currency/interfaces/electrumx_currency_interface.dart';
import '../intermediate/bip39_hd_wallet.dart';
import '../wallet_mixin_interfaces/coin_control_interface.dart';
import '../wallet_mixin_interfaces/electrumx_interface.dart';
import '../wallet_mixin_interfaces/extended_keys_interface.dart';
import '../wallet_mixin_interfaces/ordinals_interface.dart';
import '../wallet_mixin_interfaces/rbf_interface.dart';

class LitecoinWallet<T extends ElectrumXCurrencyInterface>
    extends Bip39HDWallet<T>
    with
        ElectrumXInterface<T>,
        ExtendedKeysInterface<T>,
        CoinControlInterface<T>,
        RbfInterface<T>,
        OrdinalsInterface<T> {
  @override
  int get isarTransactionVersion => 2;

  LitecoinWallet(CryptoCurrencyNetwork network) : super(Litecoin(network) as T);

  @override
  FilterOperation? get changeAddressFilterOperation =>
      FilterGroup.and(standardChangeAddressFilters);

  @override
  FilterOperation? get receivingAddressFilterOperation =>
      FilterGroup.and(standardReceivingAddressFilters);

  // ===========================================================================

  @override
  Future<List<Address>> fetchAddressesForElectrumXScan() async {
    final allAddresses = await mainDB
        .getAddresses(walletId)
        .filter()
        .not()
        .group(
          (q) => q
              .typeEqualTo(AddressType.nonWallet)
              .or()
              .subTypeEqualTo(AddressSubType.nonWallet),
        )
        .findAll();
    return allAddresses;
  }

  // ===========================================================================

  @override
  Future<void> updateTransactions() async {
    // Get all addresses.
    final List<Address> allAddressesOld =
        await fetchAddressesForElectrumXScan();

    // Separate receiving and change addresses.
    final Set<String> receivingAddresses = allAddressesOld
        .where((e) => e.subType == AddressSubType.receiving)
        .map((e) => e.value)
        .toSet();
    final Set<String> changeAddresses = allAddressesOld
        .where((e) => e.subType == AddressSubType.change)
        .map((e) => e.value)
        .toSet();

    // Remove duplicates.
    final allAddressesSet = {...receivingAddresses, ...changeAddresses};

    final updateInscriptionsFuture = refreshInscriptions(
      overrideAddressesToCheck: allAddressesSet.toList(),
    );

    // Fetch history from ElectrumX.
    final List<Map<String, dynamic>> allTxHashes =
        await fetchHistory(allAddressesSet);

    // Only parse new txs (not in db yet).
    final List<Map<String, dynamic>> allTransactions = [];
    for (final txHash in allTxHashes) {
      // Check for duplicates by searching for tx by tx_hash in db.
      final storedTx = await mainDB.isar.transactionV2s
          .where()
          .txidWalletIdEqualTo(txHash["tx_hash"] as String, walletId)
          .findFirst();

      if (storedTx == null ||
          storedTx.height == null ||
          (storedTx.height != null && storedTx.height! <= 0)) {
        // Tx not in db yet.
        final tx = await electrumXCachedClient.getTransaction(
          txHash: txHash["tx_hash"] as String,
          verbose: true,
          cryptoCurrency: cryptoCurrency,
        );

        // Only tx to list once.
        if (allTransactions
                .indexWhere((e) => e["txid"] == tx["txid"] as String) ==
            -1) {
          tx["height"] = txHash["height"];
          allTransactions.add(tx);
        }
      }
    }

    await updateInscriptionsFuture;

    // Parse all new txs.
    final List<TransactionV2> txns = [];
    for (final txData in allTransactions) {
      bool wasSentFromThisWallet = false;
      // Set to true if any inputs were detected as owned by this wallet.

      bool wasReceivedInThisWallet = false;
      // Set to true if any outputs were detected as owned by this wallet.

      // Parse inputs.
      BigInt amountReceivedInThisWallet = BigInt.zero;
      BigInt changeAmountReceivedInThisWallet = BigInt.zero;
      final List<InputV2> inputs = [];
      for (final jsonInput in txData["vin"] as List) {
        final map = Map<String, dynamic>.from(jsonInput as Map);

        final List<String> addresses = [];
        String valueStringSats = "0";
        OutpointV2? outpoint;

        final coinbase = map["coinbase"] as String?;

        if (coinbase == null) {
          // Not a coinbase (ie a typical input).
          final txid = map["txid"] as String;
          final vout = map["vout"] as int;

          final inputTx = await electrumXCachedClient.getTransaction(
            txHash: txid,
            cryptoCurrency: cryptoCurrency,
          );

          final prevOutJson = Map<String, dynamic>.from(
            (inputTx["vout"] as List).firstWhere((e) => e["n"] == vout) as Map,
          );

          final prevOut = OutputV2.fromElectrumXJson(
            prevOutJson,
            decimalPlaces: cryptoCurrency.fractionDigits,
            isFullAmountNotSats: true,
            walletOwns: false, // Doesn't matter here as this is not saved.
          );

          outpoint = OutpointV2.isarCantDoRequiredInDefaultConstructor(
            txid: txid,
            vout: vout,
          );
          valueStringSats = prevOut.valueStringSats;
          addresses.addAll(prevOut.addresses);
        }

        InputV2 input = InputV2.isarCantDoRequiredInDefaultConstructor(
          scriptSigHex: map["scriptSig"]?["hex"] as String?,
          scriptSigAsm: map["scriptSig"]?["asm"] as String?,
          sequence: map["sequence"] as int?,
          outpoint: outpoint,
          valueStringSats: valueStringSats,
          addresses: addresses,
          witness: map["witness"] as String?,
          coinbase: coinbase,
          innerRedeemScriptAsm: map["innerRedeemscriptAsm"] as String?,
          // Need addresses before we can know if the wallet owns this input.
          walletOwns: false,
        );

        // Check if input was from this wallet.
        if (allAddressesSet.intersection(input.addresses.toSet()).isNotEmpty) {
          wasSentFromThisWallet = true;
          input = input.copyWith(walletOwns: true);
        }

        inputs.add(input);
      }

      // Parse outputs.
      final List<OutputV2> outputs = [];
      for (final outputJson in txData["vout"] as List) {
        OutputV2 output = OutputV2.fromElectrumXJson(
          Map<String, dynamic>.from(outputJson as Map),
          decimalPlaces: cryptoCurrency.fractionDigits,
          isFullAmountNotSats: true,
          // Need addresses before we can know if the wallet owns this input.
          walletOwns: false,
        );

        // If output was to my wallet, add value to amount received.
        if (receivingAddresses
            .intersection(output.addresses.toSet())
            .isNotEmpty) {
          wasReceivedInThisWallet = true;
          amountReceivedInThisWallet += output.value;
          output = output.copyWith(walletOwns: true);
        } else if (changeAddresses
            .intersection(output.addresses.toSet())
            .isNotEmpty) {
          wasReceivedInThisWallet = true;
          changeAmountReceivedInThisWallet += output.value;
          output = output.copyWith(walletOwns: true);
        }

        outputs.add(output);
      }

      final totalOut = outputs
          .map((e) => e.value)
          .fold(BigInt.zero, (value, element) => value + element);

      TransactionType type;
      TransactionSubType subType = TransactionSubType.none;

      // At least one input was owned by this wallet.
      if (wasSentFromThisWallet) {
        type = TransactionType.outgoing;

        if (wasReceivedInThisWallet) {
          if (changeAmountReceivedInThisWallet + amountReceivedInThisWallet ==
              totalOut) {
            // Definitely sent all to self.
            type = TransactionType.sentToSelf;
          } else if (amountReceivedInThisWallet == BigInt.zero) {
            // Most likely just a typical send, do nothing here yet.
          }
        }
      } else if (wasReceivedInThisWallet) {
        // Only found outputs owned by this wallet.
        type = TransactionType.incoming;

        // Check for special Litecoin outputs like ordinals.
        if (outputs.isNotEmpty) {
          // may not catch every case but it is much quicker
          final hasOrdinal = await mainDB.isar.ordinals
              .where()
              .filter()
              .walletIdEqualTo(walletId)
              .utxoTXIDEqualTo(txData["txid"] as String)
              .isNotEmpty();
          if (hasOrdinal) {
            subType = TransactionSubType.ordinal;
          }

          // making API calls for every output in every transaction is too expensive
          // and if not checked can cause refresh to fail if errors aren't handled properly

          // // Iterate through outputs to check for ordinals.
          // for (final output in outputs) {
          //   for (final String address in output.addresses) {
          //     final inscriptionData = await litescribeAPI
          //         .getInscriptionsByAddress(address)
          //         .catchError((e) {
          //       Logging.instance.log(
          //         "Failed to get inscription data for address $address",
          //         level: LogLevel.Error,
          //       );
          //     });
          //
          //     // Check if any inscription data matches this output.
          //     for (final inscription in inscriptionData) {
          //       final txid = inscription.location.split(":").first;
          //       if (inscription.address == address &&
          //           txid == txData["txid"] as String) {
          //         // Found an ordinal.
          //         subType = TransactionSubType.ordinal;
          //         break;
          //       }
          //     }
          //   }
          // }
        }
      } else {
        Logging.instance.logd(
          "Unexpected tx found (ignoring it): $txData",
          level: LogLevel.Error,
        );
        continue;
      }

      String? otherData;
      if (txData["size"] is int || txData["vsize"] is int) {
        otherData = jsonEncode({
          TxV2OdKeys.size: txData["size"] as int?,
          TxV2OdKeys.vSize: txData["vsize"] as int?,
        });
      }

      final tx = TransactionV2(
        walletId: walletId,
        blockHash: txData["blockhash"] as String?,
        hash: txData["hash"] as String,
        txid: txData["txid"] as String,
        height: txData["height"] as int?,
        version: txData["version"] as int,
        timestamp: txData["blocktime"] as int? ??
            DateTime.timestamp().millisecondsSinceEpoch ~/ 1000,
        inputs: List.unmodifiable(inputs),
        outputs: List.unmodifiable(outputs),
        type: type,
        subType: subType,
        otherData: otherData,
      );

      txns.add(tx);
    }

    await mainDB.updateOrPutTransactionV2s(txns);
  }

  @override
  Amount roughFeeEstimate(int inputCount, int outputCount, int feeRatePerKB) {
    return Amount(
      rawValue: BigInt.from(
        ((42 + (272 * inputCount) + (128 * outputCount)) / 4).ceil() *
            (feeRatePerKB / 1000).ceil(),
      ),
      fractionDigits: cryptoCurrency.fractionDigits,
    );
  }

  @override
  int estimateTxFee({required int vSize, required int feeRatePerKB}) {
    return vSize * (feeRatePerKB / 1000).ceil();
  }
//
// @override
// Future<TxData> coinSelection({required TxData txData}) async {
//   final isCoinControl = txData.utxos != null;
//   final isSendAll = txData.amount == info.cachedBalance.spendable;
//
//   final utxos =
//       txData.utxos?.toList() ?? await mainDB.getUTXOs(walletId).findAll();
//
//   final currentChainHeight = await chainHeight;
//   final List<UTXO> spendableOutputs = [];
//   int spendableSatoshiValue = 0;
//
//   // Build list of spendable outputs and totaling their satoshi amount
//   for (final utxo in utxos) {
//     if (utxo.isBlocked == false &&
//         utxo.isConfirmed(currentChainHeight, cryptoCurrency.minConfirms) &&
//         utxo.used != true) {
//       spendableOutputs.add(utxo);
//       spendableSatoshiValue += utxo.value;
//     }
//   }
//
//   if (isCoinControl && spendableOutputs.length < utxos.length) {
//     throw ArgumentError("Attempted to use an unavailable utxo");
//   }
//
//   if (spendableSatoshiValue < txData.amount!.raw.toInt()) {
//     throw Exception("Insufficient balance");
//   } else if (spendableSatoshiValue == txData.amount!.raw.toInt() &&
//       !isSendAll) {
//     throw Exception("Insufficient balance to pay transaction fee");
//   }
//
//   if (isCoinControl) {
//   } else {
//     final selection = cs.coinSelection(
//       spendableOutputs
//           .map((e) => cs.InputModel(
//                 i: e.vout,
//                 txid: e.txid,
//                 value: e.value,
//                 address: e.address,
//               ))
//           .toList(),
//       txData.recipients!
//           .map((e) => cs.OutputModel(
//                 address: e.address,
//                 value: e.amount.raw.toInt(),
//               ))
//           .toList(),
//       txData.feeRateAmount!,
//       10, // TODO: ???????????????????????????????
//     );
//
//     // .inputs and .outputs will be null if no solution was found
//     if (selection.inputs!.isEmpty || selection.outputs!.isEmpty) {
//       throw Exception("coin selection failed");
//     }
//   }
// }
}

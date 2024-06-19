import 'dart:convert';

import 'package:isar/isar.dart';

import '../../../models/isar/models/blockchain_data/v2/transaction_v2.dart';
import '../../../models/isar/models/isar_models.dart';
import '../../../utilities/amount/amount.dart';
import '../../../utilities/enums/fee_rate_type_enum.dart';
import '../../../utilities/logger.dart';
import '../../crypto_currency/interfaces/electrumx_currency_interface.dart';
import '../../models/tx_data.dart';
import 'electrumx_interface.dart';

typedef TxSize = ({int real, int virtual});

mixin RbfInterface<T extends ElectrumXCurrencyInterface>
    on ElectrumXInterface<T> {
  Future<TxSize?> getVSize(String txid) async {
    final tx = await electrumXCachedClient.getTransaction(
      txHash: txid,
      cryptoCurrency: cryptoCurrency,
    );

    try {
      return (real: tx["size"] as int, virtual: tx["vsize"] as int);
    } catch (_) {
      return null;
    }
  }

  Future<TransactionV2> updateVSize(TransactionV2 transactionV2) async {
    final size = await getVSize(transactionV2.txid);
    final otherData = jsonDecode(transactionV2.otherData ?? "{}");
    otherData[TxV2OdKeys.vSize] = size!.virtual;
    otherData[TxV2OdKeys.size] = size.real;
    final updatedTx = transactionV2.copyWith(otherData: jsonEncode(otherData));
    await mainDB.updateOrPutTransactionV2s([updatedTx]);
    return updatedTx;
  }

  Future<TxData> prepareRbfSend({
    required TransactionV2 oldTransaction,
    required int newRate,
  }) async {
    final note = await mainDB.isar.transactionNotes
        .where()
        .walletIdEqualTo(walletId)
        .filter()
        .txidEqualTo(oldTransaction.txid)
        .findFirst();

    final Set<UTXO> utxos = {};
    for (final input in oldTransaction.inputs) {
      final utxo = UTXO(
        walletId: walletId,
        txid: input.outpoint!.txid,
        vout: input.outpoint!.vout,
        value: input.value.toInt(),
        name: "rbf",
        isBlocked: false,
        blockedReason: null,
        isCoinbase: false,
        blockHash: "rbf",
        blockHeight: 1,
        blockTime: 1,
        used: false,
        address: input.addresses.first,
      );

      utxos.add(utxo);
    }

    final List<TxRecipient> recipients = [];
    for (final output in oldTransaction.outputs) {
      if (output.addresses.length != 1) {
        throw UnsupportedError(
          "Unexpected output.addresses.length: ${output.addresses.length}",
        );
      }
      final address = output.addresses.first;
      final addressModel = await mainDB.getAddress(walletId, address);
      final isChange = addressModel?.subType == AddressSubType.change;

      recipients.add(
        (
          address: address,
          amount: Amount(
              rawValue: output.value,
              fractionDigits: cryptoCurrency.fractionDigits),
          isChange: isChange,
        ),
      );
    }

    final oldFee = oldTransaction
        .getFee(fractionDigits: cryptoCurrency.fractionDigits)
        .raw;
    final inSum = utxos
        .map((e) => BigInt.from(e.value))
        .fold(BigInt.zero, (p, e) => p + e);

    final noChange =
        recipients.map((e) => e.isChange).fold(false, (p, e) => p || e) ==
            false;
    final otherAvailableUtxos = await mainDB
        .getUTXOs(walletId)
        .filter()
        .isBlockedEqualTo(false)
        .and()
        .group(
          (q) => q.usedIsNull().or().usedEqualTo(false),
        )
        .findAll();

    final height = await chainHeight;
    otherAvailableUtxos.removeWhere(
      (e) => !e.isConfirmed(
        height,
        cryptoCurrency.minConfirms,
      ),
    );

    TxData txData = TxData(
      recipients: recipients,
      feeRateType: FeeRateType.custom,
      satsPerVByte: newRate,
      utxos: utxos,
      ignoreCachedBalanceChecks: true,
      note: note?.value ?? "",
    );

    if (otherAvailableUtxos.isEmpty && noChange && recipients.length == 1) {
      // safe to assume send all?
      txData = txData.copyWith(
        recipients: [
          (
            address: recipients.first.address,
            amount: Amount(
              rawValue: inSum,
              fractionDigits: cryptoCurrency.fractionDigits,
            ),
            isChange: false,
          ),
        ],
      );
      Logging.instance.log(
        "RBF on assumed send all",
        level: LogLevel.Debug,
      );
      return await prepareSend(txData: txData);
    } else if (txData.recipients!.where((e) => e.isChange).length == 1) {
      final newFee = BigInt.from(oldTransaction.vSize! * newRate);
      final feeDifferenceRequired = newFee - oldFee;
      if (feeDifferenceRequired < BigInt.zero) {
        throw Exception("Negative new fee in RBF found");
      } else if (feeDifferenceRequired == BigInt.zero) {
        throw Exception("New fee in RBF has not changed at all");
      }

      final indexOfChangeOutput =
          txData.recipients!.indexWhere((e) => e.isChange);

      final removed = txData.recipients!.removeAt(indexOfChangeOutput);

      BigInt newChangeAmount = removed.amount.raw - feeDifferenceRequired;

      if (newChangeAmount >= BigInt.zero) {
        if (newChangeAmount >= cryptoCurrency.dustLimit.raw) {
          // yay we have enough
          // update recipients
          txData.recipients!.insert(
            indexOfChangeOutput,
            (
              address: removed.address,
              amount: Amount(
                rawValue: newChangeAmount,
                fractionDigits: cryptoCurrency.fractionDigits,
              ),
              isChange: removed.isChange,
            ),
          );
          Logging.instance.log(
            "RBF with same utxo set with increased fee and reduced change",
            level: LogLevel.Debug,
          );
        } else {
          // new change amount is less than dust limit.
          // TODO: check if worth adding another utxo?
          // depending on several factors, it may be cheaper to just add]
          // the dust to the fee...
          // we'll do that for now... aka remove the change output entirely
          // which now that I think about it, will reduce the size of the tx...
          // oh well...

          // do nothing here as we already removed the change output above
          Logging.instance.log(
            "RBF with same utxo set with increased fee and no change",
            level: LogLevel.Debug,
          );
        }
        return await buildTransaction(
          txData: txData.copyWith(
            usedUTXOs: txData.utxos!.toList(),
            fee: Amount(
              rawValue: newFee,
              fractionDigits: cryptoCurrency.fractionDigits,
            ),
          ),
          utxoSigningData: await fetchBuildTxData(txData.utxos!.toList()),
        );

        // if change amount is negative
      } else {
        // we need more utxos
        if (otherAvailableUtxos.isEmpty) {
          throw Exception("Insufficient funds to pay for increased fee");
        }

        final List<UTXO> extraUtxos = [];
        for (int i = 0; i < otherAvailableUtxos.length; i++) {
          final utxoToAdd = otherAvailableUtxos[i];
          newChangeAmount += BigInt.from(utxoToAdd.value);
          extraUtxos.add(utxoToAdd);

          if (newChangeAmount >= cryptoCurrency.dustLimit.raw) {
            break;
          }
        }

        if (newChangeAmount < cryptoCurrency.dustLimit.raw) {
          throw Exception("Insufficient funds to pay for increased fee");
        }
        txData.recipients!.insert(
          indexOfChangeOutput,
          (
            address: removed.address,
            amount: Amount(
              rawValue: newChangeAmount,
              fractionDigits: cryptoCurrency.fractionDigits,
            ),
            isChange: removed.isChange,
          ),
        );

        final newUtxoSet = {
          ...txData.utxos!,
          ...extraUtxos,
        };

        // TODO: remove assert
        assert(newUtxoSet.length == txData.utxos!.length + extraUtxos.length);

        Logging.instance.log(
          "RBF with ${extraUtxos.length} extra utxo(s)"
          " added to pay for the new fee",
          level: LogLevel.Debug,
        );

        return await buildTransaction(
          txData: txData.copyWith(
            utxos: newUtxoSet,
            usedUTXOs: newUtxoSet.toList(),
            fee: Amount(
              rawValue: newFee,
              fractionDigits: cryptoCurrency.fractionDigits,
            ),
          ),
          utxoSigningData: await fetchBuildTxData(newUtxoSet.toList()),
        );
      }
    } else {
      // TODO handle building a tx here in this case
      throw Exception(
        "Unexpected number of change outputs found:"
        " ${txData.recipients!.where((e) => e.isChange).length}",
      );
    }
  }
}

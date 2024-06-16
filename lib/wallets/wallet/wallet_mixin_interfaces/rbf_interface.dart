import 'dart:convert';

import 'package:isar/isar.dart';

import '../../../models/isar/models/blockchain_data/v2/transaction_v2.dart';
import '../../../models/isar/models/isar_models.dart';
import '../../../utilities/amount/amount.dart';
import '../../../utilities/enums/fee_rate_type_enum.dart';
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

    Amount sendAmount = oldTransaction.getAmountSentFromThisWallet(
      fractionDigits: cryptoCurrency.fractionDigits,
    );

    // TODO: fix fragile firstWhere (or at least add some error checking)
    final address = oldTransaction.outputs
        .firstWhere(
          (e) => e.value == sendAmount.raw,
        )
        .addresses
        .first;

    final inSum = utxos
        .map((e) => BigInt.from(e.value))
        .fold(BigInt.zero, (p, e) => p + e);

    if (oldTransaction
                .getFee(fractionDigits: cryptoCurrency.fractionDigits)
                .raw +
            sendAmount.raw ==
        inSum) {
      sendAmount = Amount(
        rawValue: oldTransaction
                .getFee(fractionDigits: cryptoCurrency.fractionDigits)
                .raw +
            sendAmount.raw,
        fractionDigits: cryptoCurrency.fractionDigits,
      );
    }

    final note = await mainDB.isar.transactionNotes
        .where()
        .walletIdEqualTo(walletId)
        .filter()
        .txidEqualTo(oldTransaction.txid)
        .findFirst();

    final txData = TxData(
      recipients: [
        (
          address: address,
          amount: sendAmount,
          isChange: false,
        ),
      ],
      feeRateType: FeeRateType.custom,
      satsPerVByte: newRate,
      utxos: utxos,
      ignoreCachedBalanceChecks: true,
      note: note?.value ?? "",
    );

    return await prepareSend(txData: txData);
  }
}

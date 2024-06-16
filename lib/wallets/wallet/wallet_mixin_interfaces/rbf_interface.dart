import 'dart:convert';

import '../../../models/isar/models/blockchain_data/v2/transaction_v2.dart';
import '../../crypto_currency/interfaces/electrumx_currency_interface.dart';
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

// TODO more RBF specific logic
}

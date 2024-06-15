import '../../crypto_currency/interfaces/electrumx_currency_interface.dart';
import 'electrumx_interface.dart';

typedef TxSize = ({int real, int virtual});

mixin RbfInterface<T extends ElectrumXCurrencyInterface>
    on ElectrumXInterface<T> {
  // TODO actually save the size
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

// TODO more RBF specific logic
}

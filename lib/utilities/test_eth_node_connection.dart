import '../services/tor_service.dart';
import '../wallets/wallet/impl/ethereum_wallet.dart';
import 'prefs.dart';

Future<bool> testEthNodeConnection(
  String host, {
  required Prefs prefs,
  required TorService torService,
}) async {
  final client = EthereumWallet.createWeb3Client(host, prefs, torService);
  try {
    await client.getBlockNumber();
    return true;
  } catch (_) {
    return false;
  } finally {
    await client.dispose();
  }
}

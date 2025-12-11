import '../../utilities/dynamic_object.dart';
import '../../wallets/crypto_currency/crypto_currency.dart';

export '../generated/mwebd_server_interface_impl.dart';

abstract class MwebdServerInterface {
  const MwebdServerInterface();

  Future<({DynamicObject server, int port})> createAndStartServer(
    CryptoCurrencyNetwork net, {
    required String chain,
    required String dataDir,
    required String peer,
    String proxy = "",
    required int serverPort,
  });

  Future<({String chain, String dataDir, String peer})> stopServer(
    DynamicObject server,
  );
}

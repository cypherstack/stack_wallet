//ON
import 'package:flutter_mwebd/flutter_mwebd.dart' hide Status;

//END_ON
import '../../wallets/crypto_currency/crypto_currency.dart';
import '../interfaces/mwebd_server_interface.dart';

MwebdServerInterface get mwebdServerInterface => _getInterface();

//OFF
MwebdServerInterface _getInterface() => throw Exception("MWEBD not enabled!");

//END_OFF
//ON
MwebdServerInterface _getInterface() => const _MwebdServerInterfaceImpl();

extension _OpaqueMwebdServerExt on OpaqueMwebdServer {
  MwebdServer get value => get();
}

class _MwebdServerInterfaceImpl extends MwebdServerInterface {
  const _MwebdServerInterfaceImpl();

  @override
  Future<({OpaqueMwebdServer server, int port})> createAndStartServer(
    CryptoCurrencyNetwork net, {
    required String chain,
    required String dataDir,
    required String peer,
    String proxy = "",
    required int serverPort,
  }) async {
    final newServer = MwebdServer(
      chain: chain,
      dataDir: dataDir,
      peer: peer,
      proxy: proxy,
      serverPort: serverPort,
    );
    await newServer.createServer();
    await newServer.startServer();
    return (server: OpaqueMwebdServer(newServer), port: newServer.serverPort);
  }

  @override
  Future<({String chain, String dataDir, String peer})> stopServer(
    OpaqueMwebdServer server,
  ) async {
    final actual = server.value;
    final data = (
      chain: actual.chain,
      dataDir: actual.dataDir,
      peer: actual.peer,
    );
    await actual.stopServer();
    return data;
  }

  @override
  Future<Status?> getServerStatus(OpaqueMwebdServer? server) async {
    final status = await server?.value.getStatus();
    if (status == null) return null;

    return Status(
      blockHeaderHeight: status.blockHeaderHeight,
      mwebHeaderHeight: status.mwebHeaderHeight,
      mwebUtxosHeight: status.mwebUtxosHeight,
      blockTime: status.blockTime,
    );
  }
}

//END_ON

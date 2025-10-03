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
MwebdServerInterface _getInterface() => _MwebdServerInterfaceImpl();

class _MwebdServerInterfaceImpl extends MwebdServerInterface {
  final Map<CryptoCurrencyNetwork, MwebdServer> _map = {};

  @override
  Future<int> createAndStartServer(
    CryptoCurrencyNetwork net, {
    required String chain,
    required String dataDir,
    required String peer,
    String proxy = "",
    required int serverPort,
  }) async {
    if (_map[net] != null) {
      throw Exception("Server for $net already exists");
    }

    final newServer = MwebdServer(
      chain: chain,
      dataDir: dataDir,
      peer: peer,
      proxy: proxy,
      serverPort: serverPort,
    );
    await newServer.createServer();
    await newServer.startServer();
    _map[net] = newServer;
    return newServer.serverPort;
  }

  @override
  Future<({String chain, String dataDir, String peer})> stopServer(
    CryptoCurrencyNetwork net,
  ) async {
    final server = _map.remove(net);
    await server!.stopServer();
    return (chain: server.chain, dataDir: server.dataDir, peer: server.peer);
  }

  @override
  Future<Status?> getServerStatus(CryptoCurrencyNetwork net) async {
    final status = await _map[net]?.getStatus();
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

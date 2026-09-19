import 'dart:async';
import 'dart:io';

import 'package:electrum_adapter/electrum_adapter.dart';
import 'package:event_bus/event_bus.dart';
import 'package:json_rpc_2/json_rpc_2.dart' as rpc;
import 'package:stackwallet/app_config.dart';
import 'package:stackwallet/electrumx_rpc/client_manager.dart';
import 'package:stackwallet/electrumx_rpc/electrumx_client.dart';
import 'package:stackwallet/services/event_bus/events/global/tor_connection_status_changed_event.dart';
import 'package:stackwallet/services/tor_service.dart';
import 'package:stackwallet/utilities/prefs.dart';
import 'package:stackwallet/utilities/tor_plain_net_option_enum.dart';
import 'package:stackwallet/wallets/crypto_currency/coins/firo.dart';
import 'package:stream_channel/stream_channel.dart';

typedef MockElectrumHandler = FutureOr<dynamic> Function(List<dynamic> params);
typedef MockElectrumRequest = ({String method, List<dynamic> params});

class MockElectrumServer {
  MockElectrumServer({
    Map<String, MockElectrumHandler> handlers = const {},
    BlockHeader? initialHeader,
    this.host = 'mock.electrum',
    this.port = 50002,
    this.useSSL = true,
  }) : _handlers = Map<String, MockElectrumHandler>.from(handlers),
       _latestHeader = initialHeader ?? BlockHeader('00', 1) {
    _handlers.putIfAbsent(
      'blockchain.headers.subscribe',
      () =>
          (_) => {'hex': _latestHeader.hex, 'height': _latestHeader.height},
    );
  }

  final String host;
  final int port;
  final bool useSSL;
  final Map<String, MockElectrumHandler> _handlers;
  final List<MockElectrumRequest> requests = [];
  final List<rpc.Peer> _peers = [];
  BlockHeader _latestHeader;

  Future<ElectrumClient> createElectrumClient({
    ({InternetAddress host, int port})? proxyInfo,
  }) async {
    final channel = StreamChannelController<dynamic>();
    final peer = rpc.Peer.withoutJson(
      channel.foreign,
      onUnhandledError: (_, __) {},
    );
    _registerHandlers(peer);
    unawaited(peer.listen());
    _peers.add(peer);

    return ElectrumClient(channel.local, host, port, useSSL, proxyInfo);
  }

  Future<FiroElectrumClient> createFiroElectrumClient({
    ({InternetAddress host, int port})? proxyInfo,
  }) async {
    final channel = StreamChannelController<dynamic>();
    final peer = rpc.Peer.withoutJson(
      channel.foreign,
      onUnhandledError: (_, __) {},
    );
    _registerHandlers(peer);
    unawaited(peer.listen());
    _peers.add(peer);

    return FiroElectrumClient(channel.local, host, port, useSSL, proxyInfo);
  }

  void _registerHandlers(rpc.Peer peer) {
    for (final entry in _handlers.entries) {
      peer.registerMethod(entry.key, (rpc.Parameters params) async {
        final args = _paramsAsList(params);
        requests.add((method: entry.key, params: args));
        return await entry.value(args);
      });
    }
  }

  List<dynamic> _paramsAsList(rpc.Parameters params) {
    try {
      return List<dynamic>.from(params.asList);
    } catch (_) {
      return const [];
    }
  }

  int requestCount(String method) =>
      requests.where((request) => request.method == method).length;

  Future<void> emitHeader(BlockHeader header) async {
    _latestHeader = header;
    for (final peer in _peers) {
      peer.sendNotification('blockchain.headers.subscribe', [
        {'hex': header.hex, 'height': header.height},
      ]);
    }
  }

  Future<void> close() async {
    for (final peer in _peers) {
      await peer.close();
    }
    _peers.clear();
  }
}

class ManagedElectrumXClient extends ElectrumXClient {
  ManagedElectrumXClient({
    required super.host,
    required super.port,
    required super.useSSL,
    required Prefs prefs,
    required TorService torService,
    required super.failovers,
    required super.cryptoCurrency,
    required super.netType,
    required this.clearServer,
    this.torServer,
    EventBus? globalEventBusForTesting,
  }) : _prefsForTest = prefs,
       _torServiceForTest = torService,
       super(
         prefs: prefs,
         torService: torService,
         globalEventBusForTesting: globalEventBusForTesting,
       );

  final Prefs _prefsForTest;
  final TorService _torServiceForTest;
  final MockElectrumServer clearServer;
  final MockElectrumServer? torServer;

  @override
  Future<void> checkElectrumAdapter() async {
    ({InternetAddress host, int port})? proxyInfo;

    if (AppConfig.hasFeature(AppFeature.tor)) {
      if (_prefsForTest.useTor) {
        if (_torServiceForTest.status != TorConnectionStatus.connected) {
          if (_prefsForTest.torKillSwitch) {
            throw Exception(
              'Tor preference and killswitch set but Tor is not enabled, '
              'not connecting to Electrum adapter',
            );
          }
        } else {
          proxyInfo = _torServiceForTest.getProxyInfo();
        }

        if (netType == TorPlainNetworkOption.clear) {
          await (await ClientManager.sharedInstance.remove(
            cryptoCurrency: cryptoCurrency,
          )).$1?.close();
        }
      } else if (netType == TorPlainNetworkOption.tor) {
        await (await ClientManager.sharedInstance.remove(
          cryptoCurrency: cryptoCurrency,
        )).$1?.close();
      }
    }

    final existing = getElectrumAdapter();
    if (existing != null && !existing.peer.isClosed) {
      return;
    }
    if (existing != null) {
      await (await ClientManager.sharedInstance.remove(
        cryptoCurrency: cryptoCurrency,
      )).$1?.close();
    }

    final server = proxyInfo != null ? (torServer ?? clearServer) : clearServer;
    final adapter = cryptoCurrency is Firo
        ? await server.createFiroElectrumClient(proxyInfo: proxyInfo)
        : await server.createElectrumClient(proxyInfo: proxyInfo);

    await ClientManager.sharedInstance.addClient(
      adapter,
      cryptoCurrency: cryptoCurrency,
      netType: netType,
    );
  }
}

Future<void> tearDownManagedElectrum({
  Iterable<MockElectrumServer> servers = const [],
}) async {
  await ClientManager.sharedInstance.closeAll();
  for (final server in servers) {
    await server.close();
  }
}

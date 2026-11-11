import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:event_bus/event_bus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart' show Level;
import 'package:mockito/mockito.dart';
import 'package:stackwallet/electrumx_rpc/electrumx_client.dart';
import 'package:stackwallet/models/node_model.dart';
import 'package:stackwallet/services/node_service.dart';
import 'package:stackwallet/services/tor_service.dart';
import 'package:stackwallet/utilities/flutter_secure_storage_interface.dart';
import 'package:stackwallet/utilities/logger.dart';
import 'package:stackwallet/utilities/prefs.dart';
import 'package:stackwallet/wallets/crypto_currency/crypto_currency.dart';
import 'package:stackwallet/wallets/wallet/impl/bitcoin_wallet.dart';

class _Prefs extends Mock implements Prefs {
  _Prefs({this.useTor = false});
  @override
  final bool useTor;
  @override
  bool get wifiOnly => false;
  @override
  bool get torKillSwitch => false;
}

class _Tor extends Mock implements TorService {}

class _Nodes extends NodeService {
  _Nodes(this.node) : super(secureStorageInterface: FakeSecureStorage());
  final NodeModel node;
  @override
  NodeModel? getPrimaryNodeFor({required CryptoCurrency currency}) => node;
  @override
  List<NodeModel> failoverNodesFor({required CryptoCurrency currency}) => [];
}

/// A plain JSON-RPC server. It answers setup and header requests, holds
/// `probe.held` until [release], fails `probe.fail` on [failing] servers and
/// never answers `probe.silent`.
class _Server {
  _Server(this.listener, {required this.failing});
  final ServerSocket listener;
  final bool failing;
  final sockets = <Socket>[];
  final methods = <String>[];
  final _held = <void Function()>[];
  int accepted = 0;
  int height = 100;
  int get port => listener.port;

  static Future<_Server> start({bool failing = false}) async {
    final server = _Server(
      await ServerSocket.bind(InternetAddress.loopbackIPv4, 0),
      failing: failing,
    );
    server.listener.listen((socket) {
      server.accepted++;
      server.sockets.add(socket);
      socket.done.ignore();
      socket
          .cast<List<int>>()
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen((line) {
            final request = jsonDecode(line) as Map<String, dynamic>;
            final method = request['method'] as String;
            server.methods.add(method);
            void reply(Object? result) {
              final response = {
                'jsonrpc': '2.0',
                'id': request['id'],
                'result': result,
              };
              socket.write('${jsonEncode(response)}\n');
            }

            switch (method) {
              case 'server.version':
                reply(['test', '1.4']);
              case 'blockchain.headers.subscribe':
                reply({'height': server.height, 'hex': '00' * 80});
              case 'probe.held':
                server._held.add(() => reply({'held': 'done'}));
              case 'probe.fail':
                reply(
                  server.failing
                      ? {'error': 'try the fallback'}
                      : {'via': 'fallback'},
                );
              case 'probe.silent':
                break;
              default:
                reply({});
            }
          }, onError: (Object _) {});
    });
    return server;
  }

  bool get holding => _held.isNotEmpty;

  void release() {
    for (final reply in _held) {
      reply();
    }
    _held.clear();
  }

  Future<void> close() async {
    for (final socket in sockets) {
      socket.destroy();
    }
    await listener.close();
  }
}

Future<void> _until(bool Function() ready) async {
  final watch = Stopwatch()..start();
  while (!ready()) {
    if (watch.elapsed > const Duration(seconds: 3)) {
      throw TimeoutException('Waiting for isolation test server');
    }
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
}

void main() {
  late Directory logs;
  late EventBus bus;
  final clients = <ElectrumXClient>[];
  final coin = Bitcoin(CryptoCurrencyNetwork.main);

  setUpAll(() async {
    logs = await Directory.systemTemp.createTemp('electrum_isolation');
    await Logging.instance.initialize(logs.path, level: Level.off);
  });
  tearDownAll(() => logs.delete(recursive: true));
  setUp(() => bus = EventBus());
  tearDown(() async {
    for (final client in clients) {
      await client.closeAdapter();
    }
    clients.clear();
    bus.destroy();
  });

  Future<_Server> start({bool failing = false}) async {
    final server = await _Server.start(failing: failing);
    addTearDown(server.close);
    return server;
  }

  ElectrumXNode node(_Server server) => ElectrumXNode(
    address: '127.0.0.1',
    port: server.port,
    name: '${server.port}',
    id: '${server.port}',
    useSSL: false,
    torEnabled: true,
    clearnetEnabled: true,
  );

  ElectrumXClient client(_Server primary, {_Server? fallback}) {
    final client = ElectrumXClient.from(
      node: node(primary),
      prefs: _Prefs(),
      torService: _Tor(),
      failovers: [if (fallback != null) node(fallback)],
      cryptoCurrency: coin,
      globalEventBusForTesting: bus,
    );
    clients.add(client);
    return client;
  }

  test(
    'two clients of the same coin and node have distinct connections',
    () async {
      final server = await start();
      final first = client(server);
      final second = client(server);

      await first.checkElectrumAdapter();
      await second.checkElectrumAdapter();

      expect(first.getElectrumAdapter(), isNotNull);
      expect(second.getElectrumAdapter(), isNotNull);
      expect(
        first.getElectrumAdapter(),
        isNot(same(second.getElectrumAdapter())),
      );
      expect(server.accepted, 2);
    },
  );

  for (final action in ['failover', 'timeout', 'closeAdapter']) {
    test("another client's $action never fails this client's in-flight "
        'request', () async {
      final primary = await start(failing: true);
      final fallback = await start();
      final actor = client(primary, fallback: fallback);
      final bystander = client(primary, fallback: fallback);
      await actor.checkElectrumAdapter();
      final actorConnection = actor.getElectrumAdapter()!;

      final inFlight = bystander
          .request(command: 'probe.held')
          .then<Object?>((value) => value, onError: (Object e) => e);
      await _until(() => primary.holding);
      final bystanderConnection = bystander.getElectrumAdapter()!;
      expect(bystanderConnection, isNot(same(actorConnection)));

      switch (action) {
        case 'failover':
          expect(await actor.request(command: 'probe.fail'), {
            'via': 'fallback',
          });
          expect(actor.getElectrumAdapter()!.port, fallback.port);
        case 'timeout':
          await expectLater(
            actor.request(
              command: 'probe.silent',
              requestTimeout: const Duration(milliseconds: 150),
            ),
            throwsA(isA<TimeoutException>()),
          );
        case 'closeAdapter':
          await actor.closeAdapter();
      }
      // The action really ended the actor's connection.
      await _until(() => actorConnection.peer.isClosed);

      expect(bystanderConnection.peer.isClosed, false);
      expect(bystander.getElectrumAdapter(), same(bystanderConnection));
      primary.release();
      expect(await inFlight.timeout(const Duration(seconds: 2)), {
        'held': 'done',
      });
      expect(bystander.currentFailoverIndex, -1);
    });
  }

  group('wallet chain height', () {
    NodeModel nodeModel(
      _Server server, {
      bool torEnabled = true,
      bool clearnetEnabled = true,
    }) => NodeModel(
      host: '127.0.0.1',
      port: server.port,
      name: 'node',
      id: 'node',
      useSSL: false,
      enabled: true,
      coinName: coin.identifier,
      isFailover: false,
      isDown: false,
      trusted: false,
      torEnabled: torEnabled,
      clearnetEnabled: clearnetEnabled,
      isPrimary: true,
    );

    Future<BitcoinWallet<Bitcoin>> wallet(NodeModel node, Prefs prefs) async {
      final wallet = BitcoinWallet<Bitcoin>(CryptoCurrencyNetwork.main)
        ..prefs = prefs
        ..nodeService = _Nodes(node);
      // Wallet.load() calls this before the wallet has any client to close.
      await wallet.updateNode();
      clients.add(wallet.electrumXClient);
      return wallet;
    }

    test('each wallet reads the current tip on its own connection', () async {
      final server = await start();
      final first = await wallet(nodeModel(server), _Prefs());
      final second = await wallet(nodeModel(server), _Prefs());

      expect(await first.fetchChainHeight(), 100);
      expect(await second.fetchChainHeight(), 100);
      expect(server.accepted, 2);

      // Nothing is cached between calls: a new block is seen at once.
      server.height = 101;
      expect(await first.fetchChainHeight(), 101);
      expect(
        server.methods.where((m) => m == 'blockchain.headers.subscribe'),
        hasLength(3),
      );
      expect(server.accepted, 2);
    });

    test('a clearnet-only node still fails chain height under Tor', () async {
      final server = await start();
      final clearOnly = await wallet(
        nodeModel(server, torEnabled: false),
        _Prefs(useTor: true),
      );

      await expectLater(
        clearOnly.fetchChainHeight(),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Non-TOR only client'),
          ),
        ),
      );
      expect(server.methods, isNot(contains('blockchain.headers.subscribe')));
    });
  });
}

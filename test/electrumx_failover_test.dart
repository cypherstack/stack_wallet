import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:event_bus/event_bus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart' show Level;
import 'package:mockito/mockito.dart';
import 'package:stackwallet/electrumx_rpc/client_manager.dart';
import 'package:stackwallet/electrumx_rpc/electrumx_client.dart';
import 'package:stackwallet/services/tor_service.dart';
import 'package:stackwallet/utilities/logger.dart';
import 'package:stackwallet/utilities/prefs.dart';
import 'package:stackwallet/wallets/crypto_currency/crypto_currency.dart';

import 'utilities/tls_test_server.dart';

class _Prefs extends Mock implements Prefs {
  @override
  bool get useTor => false;
  @override
  bool get wifiOnly => false;
  @override
  bool get torKillSwitch => false;
}

class _Tor extends Mock implements TorService {}

class _RpcServer {
  _RpcServer(this.server);
  final ServerSocket server;
  final sockets = <Socket>[];
  final ready = Completer<void>();
  int pending = 0;
  int requests = 0;
  void Function()? fail;
  int get port => server.port;

  static Future<_RpcServer> start({
    required bool batch,
    bool holdRequests = true,
  }) async {
    final primary = _RpcServer(
      await ServerSocket.bind(InternetAddress.loopbackIPv4, 0),
    );
    primary.server.listen((socket) {
      primary.sockets.add(socket);
      socket.done.ignore();
      socket
          .cast<List<int>>()
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen((line) {
            final decoded = jsonDecode(line);
            for (final request in decoded is List ? decoded : [decoded]) {
              primary.requests++;
              if (holdRequests &&
                  (request['method'] == 'probe.a' ||
                      request['method'] == 'probe.b')) {
                primary.pending++;
                if (request['method'] == 'probe.a') {
                  primary.fail = () {
                    final reply = batch
                        ? {
                            'jsonrpc': '2.0',
                            'id': request['id'],
                            'error': {
                              'code': -32000,
                              'message': 'temporary failure',
                            },
                          }
                        : {
                            'jsonrpc': '2.0',
                            'id': request['id'],
                            'result': {'error': 'temporary failure'},
                          };
                    socket.write('${jsonEncode(batch ? [reply] : reply)}\n');
                  };
                }
                if (primary.pending == 2) primary.ready.complete();
              } else {
                final Object result = switch (request['method']) {
                  'server.version' => ['test', '1.4'],
                  'blockchain.headers.subscribe' => {
                    'height': 100,
                    'hex': '00' * 80,
                  },
                  _ => {},
                };
                final reply = {
                  'jsonrpc': '2.0',
                  'id': request['id'],
                  'result': result,
                };
                socket.write(
                  '${jsonEncode(decoded is List ? [reply] : reply)}\n',
                );
              }
            }
          }, onError: (Object _) {});
    });
    return primary;
  }

  Future<void> close() async {
    for (final socket in sockets) {
      socket.destroy();
    }
    await server.close();
  }
}

class _Rpc {
  _Rpc(this.socket, this.message);
  final Socket socket;
  final Map<String, dynamic> message;
  String get method => message['method'] as String;
  void reply(Object? value) => socket.write(
    '${jsonEncode({'jsonrpc': '2.0', 'id': message['id'], 'result': value})}\n',
  );
}

/// A plain JSON-RPC server for the publication-selection regression. It
/// answers header subscriptions, optionally auto-answers server.version, and
/// hands every request to [onRequest] so a test can error or hold it.
class _PubServer {
  _PubServer(this.listener, this.autoVersion);
  final ServerSocket listener;
  final bool autoVersion;
  final sockets = <Socket>[];
  final requests = <_Rpc>[];
  void Function(_Rpc)? onRequest;
  int get port => listener.port;
  List<_Rpc> get versions =>
      requests.where((e) => e.method == 'server.version').toList();

  static Future<_PubServer> start({bool autoVersion = false}) async {
    final server = _PubServer(
      await ServerSocket.bind(InternetAddress.loopbackIPv4, 0),
      autoVersion,
    );
    server.listener.listen((socket) {
      server.sockets.add(socket);
      socket.done.ignore();
      socket
          .cast<List<int>>()
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen((line) {
            final decoded = jsonDecode(line);
            for (final message in decoded is List ? decoded : [decoded]) {
              final rpc = _Rpc(socket, message as Map<String, dynamic>);
              server.requests.add(rpc);
              if (rpc.method == 'blockchain.headers.subscribe') {
                rpc.reply({'height': 100, 'hex': '00' * 80});
              } else if (rpc.method == 'server.version' && autoVersion) {
                rpc.reply(['test', '1.4']);
              }
              server.onRequest?.call(rpc);
            }
          }, onError: (Object _) {});
    });
    return server;
  }

  Future<void> close() async {
    for (final socket in sockets) {
      socket.destroy();
    }
    await listener.close();
  }
}

Future<void> _until(bool Function() ready) async {
  final deadline = DateTime.now().add(const Duration(seconds: 3));
  while (!ready()) {
    if (DateTime.now().isAfter(deadline)) {
      throw TimeoutException('probe synchronization');
    }
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
}

void main() {
  late Directory logDirectory;
  setUpAll(() async {
    logDirectory = await Directory.systemTemp.createTemp('electrumx_failover');
    await Logging.instance.initialize(logDirectory.path, level: Level.off);
  });
  tearDownAll(() => logDirectory.delete(recursive: true));
  final coin = Bitcoin(CryptoCurrencyNetwork.main);
  final servers = <TlsElectrumServer>[];
  late EventBus bus;

  setUp(() => bus = EventBus());
  tearDown(() async {
    await ClientManager.sharedInstance.closeAll();
    bus.destroy();
    for (final server in servers) {
      await server.close();
    }
    servers.clear();
  });

  Future<TlsElectrumServer> startPlain() async {
    final server = await TlsElectrumServer.start(certificateName: null);
    servers.add(server);
    return server;
  }

  /// A port nothing listens on.
  Future<int> deadPort() async {
    final socket = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    final port = socket.port;
    await socket.close();
    return port;
  }

  ElectrumXNode node(int port, String id) => ElectrumXNode(
    address: '127.0.0.1',
    port: port,
    name: id,
    id: id,
    useSSL: false,
    torEnabled: true,
    clearnetEnabled: true,
  );

  ElectrumXClient client(
    ElectrumXNode primary, {
    List<ElectrumXNode> failovers = const [],
  }) => ElectrumXClient.from(
    node: primary,
    prefs: _Prefs(),
    torService: _Tor(),
    failovers: failovers,
    cryptoCurrency: coin,
    globalEventBusForTesting: bus,
  );

  test(
    'requests after a successful failover request stay on the failover',
    () async {
      final failover = await startPlain();
      final connection = client(
        node(await deadPort(), 'primary'),
        failovers: [node(failover.port, 'failover')],
      );
      connection.currentFailoverIndex = 0;
      // A successful request resets the failover index to the primary.
      expect(await connection.ping(), true);
      expect(connection.currentFailoverIndex, -1);
      final result = await connection.getTransaction(txHash: 'a' * 64);
      expect(result['confirmations'], 3);
      expect(connection.getElectrumAdapter()!.port, failover.port);
      // server.version, headers.subscribe, ping, transaction.get: one session.
      expect(failover.requests, 4);
      expect(failover.disconnections, 0);
    },
  );

  for (final primaryShadows in [false, true]) {
    test(
      'duplicate endpoint approvals do not hide a successful ${primaryShadows ? 'primary' : 'failover'} fallback',
      () async {
        final server = await TlsElectrumServer.start(certificateName: 'node_b');
        servers.add(server);
        final a = TlsElectrumServer.certificate('node_a');
        final b = TlsElectrumServer.certificate('node_b');
        ElectrumXNode approved(String id, String pem) => ElectrumXNode(
          address: '127.0.0.1',
          port: server.port,
          name: id,
          id: id,
          useSSL: true,
          torEnabled: true,
          clearnetEnabled: true,
          trustedCertificatePem: pem,
        );
        final connection = client(
          primaryShadows
              ? approved('primary', a)
              : node(await deadPort(), 'primary'),
          failovers: [
            if (!primaryShadows) approved('old approval', a),
            approved('selected', b),
          ],
        );
        addTearDown(connection.closeAdapter);
        connection.currentFailoverIndex = primaryShadows ? 0 : 1;
        expect(await connection.ping(), true);
        final selected = connection.getElectrumAdapter();
        expect(connection.currentFailoverIndex, -1);
        expect(
          (await connection.getTransaction(txHash: 'a' * 64))['confirmations'],
          3,
        );
        expect(connection.getElectrumAdapter(), same(selected));
        expect(server.accepted, 1);
        expect(server.disconnections, 0);
      },
    );
  }

  test('another client for the coin shares the failover connection', () async {
    final failover = await startPlain();
    final dead = await deadPort();
    final first = client(
      node(dead, 'primary'),
      failovers: [node(failover.port, 'failover')],
    );
    first.currentFailoverIndex = 0;
    expect(await first.ping(), true);
    final second = client(
      node(dead, 'primary'),
      failovers: [node(failover.port, 'failover')],
    );
    final result = await second.getTransaction(txHash: 'b' * 64);
    expect(result['confirmations'], 3);
    expect(failover.disconnections, 0);
  });

  test("a failover retry reuses another owner's healthy selected connection", () async {
    // A shared failover endpoint that answers setup and holds one request.
    final listener = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    final sockets = <Socket>[];
    var accepted = 0;
    void Function()? release;
    final held = Completer<void>();
    listener.listen((socket) {
      accepted++;
      sockets.add(socket);
      socket.done.ignore();
      socket
          .cast<List<int>>()
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen((line) {
            final request = jsonDecode(line) as Map<String, dynamic>;
            void reply(Object? result) => socket.write(
              '${jsonEncode({'jsonrpc': '2.0', 'id': request['id'], 'result': result})}\n',
            );
            switch (request['method']) {
              case 'blockchain.transaction.get':
                release = () => reply({'confirmations': 7});
                if (!held.isCompleted) held.complete();
              case 'blockchain.headers.subscribe':
                reply({'height': 100, 'hex': '00' * 80});
              default:
                reply(['test', '1.4']);
            }
          }, onError: (Object _) {});
    });
    addTearDown(() async {
      for (final socket in sockets) {
        socket.destroy();
      }
      await listener.close();
    });
    final dead = await deadPort();
    final failoverNode = node(listener.port, 'failover');
    final w1 = client(node(dead, 'primary'), failovers: [failoverNode]);
    final w2 = client(node(dead, 'primary'), failovers: [failoverNode]);
    addTearDown(w1.closeAdapter);
    addTearDown(w2.closeAdapter);

    // W1 has already failed over to the shared node and is healthy on it.
    w1.currentFailoverIndex = 0;
    expect(await w1.ping(), true);
    expect(w1.currentFailoverIndex, -1);
    final shared = w1.getElectrumAdapter()!;

    // W1 keeps a request in flight on the shared connection.
    final inflight = w1.getTransaction(txHash: 'a' * 64);
    await held.future.timeout(const Duration(seconds: 2));

    // W2's primary is also dead; its failover retry selects the same node.
    w2.currentFailoverIndex = 0;
    await w2.checkElectrumAdapter();
    expect(
      w2.getElectrumAdapter(),
      same(shared),
      reason: 'the healthy selected failover is reused, not reopened',
    );
    expect(
      shared.peer.isClosed,
      false,
      reason: "another owner's connection must not be closed",
    );
    expect(accepted, 1, reason: 'no spare session is opened');

    release!();
    expect(
      (await inflight.timeout(const Duration(seconds: 2)))['confirmations'],
      7,
      reason: 'the in-flight RPC on the shared connection is not cut off',
    );
  });

  test(
    'a concurrent primary publication cannot replace the selected fallback',
    () async {
      final primary = await _PubServer.start(autoVersion: true);
      final fallback = await _PubServer.start();
      addTearDown(primary.close);
      addTearDown(fallback.close);
      primary.onRequest = (rpc) {
        if (rpc.method == 'probe') rpc.reply({'error': 'primary unavailable'});
      };
      fallback.onRequest = (rpc) {
        if (rpc.method == 'probe') rpc.reply({'via': 'fallback'});
      };
      final first = client(
        node(primary.port, 'primary'),
        failovers: [node(fallback.port, 'fallback')],
      );
      final second = client(
        node(primary.port, 'primary'),
        failovers: [node(fallback.port, 'fallback')],
      );
      addTearDown(first.closeAdapter);
      addTearDown(second.closeAdapter);
      final pending = first
          .request(command: 'probe')
          .then<Object?>((value) => value, onError: (Object e) => e);
      await _until(() => fallback.versions.isNotEmpty);
      // The second owner publishes a fresh primary while the fallback waits.
      await second.checkElectrumAdapter();
      expect(second.getElectrumAdapter()!.port, primary.port);
      // Let the primary's header subscription finish before it is replaced.
      await ClientManager.sharedInstance.getChainHeightFor(coin);
      fallback.versions.single.reply(['test', '1.4']);
      final result = await pending.timeout(const Duration(seconds: 4));
      expect(result, {
        'via': 'fallback',
      }, reason: 'the selected fallback must serve the retry, not the primary');
      expect(first.getElectrumAdapter()!.port, fallback.port);
      expect(
        fallback.requests.where((r) => r.method == 'probe').length,
        1,
        reason: 'the probe reaches the healthy fallback',
      );
    },
  );
  for (final batch in [false, true]) {
    test(
      'failover survives another outstanding RPC closing (batch=$batch)',
      () async {
        final primary = await _RpcServer.start(batch: batch);
        final failover = await _RpcServer.start(
          batch: batch,
          holdRequests: false,
        );
        addTearDown(failover.close);
        final connection = client(
          node(primary.port, 'primary'),
          failovers: [node(failover.port, 'failover')],
        );
        final first =
            (batch
                    ? connection.batchRequest(
                        command: 'probe.a',
                        args: [
                          ['address'],
                        ],
                      )
                    : connection.request(command: 'probe.a'))
                .then<Object?>(
                  (value) => value,
                  onError: (Object error) => error,
                );
        final other = connection
            .request(command: 'probe.b')
            .then<Object?>((value) => value, onError: (Object error) => error);
        try {
          await primary.ready.future.timeout(const Duration(seconds: 2));
          primary.fail!();
          final result = await first.timeout(const Duration(seconds: 3));
          expect(
            result,
            batch ? isA<List<dynamic>>() : isA<Map<dynamic, dynamic>>(),
          );
          expect(failover.requests, greaterThanOrEqualTo(2));
        } finally {
          await primary.close();
          await other.timeout(const Duration(seconds: 3));
          await connection.closeAdapter();
        }
      },
    );
  }
}

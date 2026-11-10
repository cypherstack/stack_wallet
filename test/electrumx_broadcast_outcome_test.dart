import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:bitcoindart/bitcoindart.dart' as bitcoin;
import 'package:event_bus/event_bus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:json_rpc_2/json_rpc_2.dart' show RpcException;
import 'package:logger/logger.dart' show Level;
import 'package:mockito/mockito.dart';
import 'package:stackwallet/electrumx_rpc/client_manager.dart';
import 'package:stackwallet/electrumx_rpc/electrum_request_timeouts.dart';
import 'package:stackwallet/electrumx_rpc/electrumx_client.dart';
import 'package:stackwallet/exceptions/electrumx/broadcast_outcome_unknown.dart';
import 'package:stackwallet/services/tor_service.dart';
import 'package:stackwallet/utilities/logger.dart';
import 'package:stackwallet/utilities/prefs.dart';
import 'package:stackwallet/utilities/tor_plain_net_option_enum.dart';
import 'package:stackwallet/wallets/crypto_currency/crypto_currency.dart';

import 'utilities/tls_test_server.dart';

// Serialized standard 1-input/1-output transaction from bitcoindart's
// test/fixtures/transaction.json. Its txid is checked below using the parser.
const _rawTx =
    '0100000001f1fefefefefefefefefefefefefefefefefefefefefefefefefefefefefefefe'
    '000000006b4830450221008732a460737d956fd94d49a31890b2908'
    'f7ed7025a9c1d0f25e43290f1841716'
    '022004fa7d608a291d44ebbbebbadaac18f943031e7de39ef3bf9920998c43e60c0401'
    '210279be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798'
    'ffffffff01a0860100000000001976a914c42e7ef92fdb603af844d064'
    'faad95db9bcdfd3d88ac00000000';
const _txid =
    'a0ff943d3f644d8832b1fa74be4d0ad2577615dc28a7ef74ff8c271b603a082a';
const _broadcast = 'blockchain.transaction.broadcast';
const _lookup = 'blockchain.transaction.get';

class _Prefs extends Mock implements Prefs {
  @override
  bool get useTor => false;
  @override
  bool get wifiOnly => false;
  @override
  bool get torKillSwitch => true;
}

class _Tor extends Mock implements TorService {}

class _BroadcastServer {
  _BroadcastServer(
    this.listener, {
    required this.broadcastError,
    required this.broadcastErrorCode,
    required this.broadcastResult,
    required this.lookupResult,
    required this.stallVersion,
    required this.stallLookup,
  });

  final ServerSocket listener;
  final String? broadcastError;
  final int broadcastErrorCode;
  final Object? broadcastResult;
  final Object? lookupResult;
  final bool stallVersion;
  final bool stallLookup;
  final sockets = <Socket>[];
  final requests = <Map<String, dynamic>>[];
  late final StreamSubscription<Socket> subscription;
  int accepted = 0;
  int get port => listener.port;
  List<Map<String, dynamic>> get broadcasts =>
      requests.where((request) => request['method'] == _broadcast).toList();
  List<Map<String, dynamic>> get lookups =>
      requests.where((request) => request['method'] == _lookup).toList();

  static Future<_BroadcastServer> start({
    String? certificateName,
    String? broadcastError,
    int broadcastErrorCode = -32000,
    Object? broadcastResult,
    Object? lookupResult,
    bool stallVersion = false,
    bool stallLookup = false,
  }) async {
    final server = _BroadcastServer(
      await ServerSocket.bind(InternetAddress.loopbackIPv4, 0),
      broadcastError: broadcastError,
      broadcastErrorCode: broadcastErrorCode,
      broadcastResult: broadcastResult,
      lookupResult: lookupResult,
      stallVersion: stallVersion,
      stallLookup: stallLookup,
    );
    final context = certificateName == null
        ? null
        : (SecurityContext()
            ..useCertificateChainBytes(
              utf8.encode(TlsElectrumServer.certificate(certificateName)),
            )
            ..usePrivateKeyBytes(
              File('test/fixtures/tls/$certificateName.key.pem')
                  .readAsBytesSync(),
            ));
    server.subscription = server.listener.listen((raw) async {
      server.accepted++;
      server.sockets.add(raw);
      raw.done.ignore();
      try {
        final socket = context == null
            ? raw
            : await SecureSocket.secureServer(raw, context);
        if (!identical(raw, socket)) {
          server.sockets.add(socket);
          socket.done.ignore();
        }
        socket
            .cast<List<int>>()
            .transform(utf8.decoder)
            .transform(const LineSplitter())
            .listen((line) {
              final request = jsonDecode(line) as Map<String, dynamic>;
              server.requests.add(request);
              void reply(Object? result) {
                final response = {
                  'jsonrpc': '2.0',
                  'id': request['id'],
                  'result': result,
                };
                socket.write('${jsonEncode(response)}\n');
              }

              void reject(String message, {int code = -32000}) => socket.write(
                '${jsonEncode({
                  'jsonrpc': '2.0',
                  'id': request['id'],
                  'error': {'code': code, 'message': message},
                })}\n',
              );
              switch (request['method']) {
                case 'server.version':
                  if (!server.stallVersion) reply(['test', '1.4']);
                case 'blockchain.headers.subscribe':
                  reply({'height': 100, 'hex': '00' * 80});
                case _broadcast:
                  if (server.broadcastError != null) {
                    reject(
                      server.broadcastError!,
                      code: server.broadcastErrorCode,
                    );
                  } else if (server.broadcastResult != null) {
                    reply(server.broadcastResult);
                  }
                // Otherwise accept the bytes but lose the broadcast reply.
                case _lookup:
                  if (!server.stallLookup) {
                    if (server.lookupResult == null) {
                      reject('No such mempool or blockchain transaction');
                    } else {
                      reply(server.lookupResult);
                    }
                  }
                default:
                  reply({});
              }
            }, onError: (Object _) {});
      } catch (_) {
        raw.destroy();
      }
    });
    return server;
  }

  Future<void> close() async {
    for (final socket in sockets) {
      socket.destroy();
    }
    await subscription.cancel();
    await listener.close();
  }
}

Future<void> _until(bool Function() ready) async {
  final watch = Stopwatch()..start();
  while (!ready()) {
    if (watch.elapsed > const Duration(seconds: 3)) {
      throw TimeoutException('Waiting for broadcast test server');
    }
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
}

void main() {
  late Directory logDirectory;
  late EventBus bus;
  setUpAll(() async {
    expect(bitcoin.Transaction.fromHex(_rawTx).getId(), _txid);
    logDirectory = await Directory.systemTemp.createTemp('broadcast_outcomes');
    await Logging.instance.initialize(logDirectory.path, level: Level.off);
  });
  tearDownAll(() => logDirectory.delete(recursive: true));
  setUp(() => bus = EventBus());
  tearDown(() async {
    await ClientManager.sharedInstance.closeAll();
    bus.destroy();
  });

  Future<_BroadcastServer> start({
    String? certificateName,
    String? broadcastError,
    int broadcastErrorCode = -32000,
    Object? broadcastResult,
    Object? lookupResult,
    bool stallVersion = false,
    bool stallLookup = false,
  }) async {
    final server = await _BroadcastServer.start(
      certificateName: certificateName,
      broadcastError: broadcastError,
      broadcastErrorCode: broadcastErrorCode,
      broadcastResult: broadcastResult,
      lookupResult: lookupResult,
      stallVersion: stallVersion,
      stallLookup: stallLookup,
    );
    addTearDown(server.close);
    return server;
  }

  ElectrumXClient clientFor(
    _BroadcastServer primary, [
    List<_BroadcastServer> failovers = const [],
  ]) {
    final client = ElectrumXClient(
      host: '127.0.0.1',
      port: primary.port,
      useSSL: false,
      prefs: _Prefs(),
      torService: _Tor(),
      netType: TorPlainNetworkOption.both,
      cryptoCurrency: Bitcoin(CryptoCurrencyNetwork.main),
      globalEventBusForTesting: bus,
      requestTimeouts: const ElectrumRequestTimeouts(
        standard: Duration(milliseconds: 150),
      ),
      connectionTimeoutForSpecialCaseJsonRPCClients: const Duration(
        milliseconds: 150,
      ),
      failovers: [
        for (final server in failovers)
          ElectrumXNode(
            address: '127.0.0.1',
            port: server.port,
            name: 'broadcast fallback',
            id: '${server.port}',
            useSSL: false,
            torEnabled: true,
            clearnetEnabled: true,
          ),
      ],
    );
    addTearDown(client.closeAdapter);
    return client;
  }

  Future<String> broadcast(ElectrumXClient client) => client
      .broadcastTransaction(rawTx: _rawTx, expectedTxId: _txid)
      .timeout(const Duration(seconds: 3));

  TypeMatcher<BroadcastOutcomeUnknown> unknownWithTxid() =>
      isA<BroadcastOutcomeUnknown>().having(
        (error) => error.txid,
        'transaction ID',
        _txid,
      );

  test(
    'lost broadcast reply resolves through exact raw transaction lookup',
    () async {
      final primary = await start(lookupResult: _rawTx.toUpperCase());
      final client = clientFor(primary);

      expect(await broadcast(client), _txid);

      expect(primary.broadcasts, hasLength(1));
      expect(primary.broadcasts.single['params'], [_rawTx]);
      expect(primary.lookups, hasLength(1));
      expect(primary.lookups.single['params'], [_txid, false]);
    },
  );

  test(
    'fallback can confirm a lost reply without any broadcast replay',
    () async {
      final primary = await start();
      final fallback = await start(lookupResult: _rawTx);
      final client = clientFor(primary, [fallback]);

      expect(await broadcast(client), _txid);

      expect(primary.broadcasts, hasLength(1));
      expect(fallback.broadcasts, isEmpty);
      expect(primary.lookups, hasLength(1));
      expect(fallback.lookups, hasLength(1));
      expect(fallback.lookups.single['params'], [_txid, false]);
    },
  );

  test('TLS reconciliation keeps approvals bound to their endpoints', () async {
    final primary = await start(certificateName: 'node_a');
    final unapproved = await start(
      certificateName: 'node_a',
      lookupResult: _rawTx,
    );
    final approved = await start(
      certificateName: 'node_b',
      lookupResult: _rawTx,
    );
    final client = ElectrumXClient(
      host: '127.0.0.1',
      port: primary.port,
      useSSL: true,
      trustedCertificatePem: TlsElectrumServer.certificate('node_a'),
      prefs: _Prefs(),
      torService: _Tor(),
      netType: TorPlainNetworkOption.both,
      cryptoCurrency: Bitcoin(CryptoCurrencyNetwork.main),
      globalEventBusForTesting: bus,
      requestTimeouts: const ElectrumRequestTimeouts(
        standard: Duration(milliseconds: 150),
      ),
      connectionTimeoutForSpecialCaseJsonRPCClients: const Duration(seconds: 2),
      failovers: [
        for (final server in [unapproved, approved])
          ElectrumXNode(
            address: '127.0.0.1',
            port: server.port,
            name: 'TLS reconciliation',
            id: '${server.port}',
            useSSL: true,
            torEnabled: true,
            clearnetEnabled: true,
            trustedCertificatePem: identical(server, approved)
                ? TlsElectrumServer.certificate('node_b')
                : null,
          ),
      ],
    );
    addTearDown(client.closeAdapter);

    expect(await broadcast(client), _txid);

    expect(primary.broadcasts, hasLength(1));
    expect(unapproved.accepted, 1);
    expect(unapproved.requests, isEmpty);
    expect(approved.broadcasts, isEmpty);
    expect(approved.lookups, hasLength(1));
    expect(approved.lookups.single['params'], [_txid, false]);
  });

  test(
    'unresolved broadcast is typed unknown with its locally known txid',
    () async {
      final primary = await start(stallLookup: true);
      final fallback = await start();
      final client = clientFor(primary, [fallback]);

      await expectLater(
        broadcast(client),
        throwsA(
          unknownWithTxid().having(
            (error) => error.cause,
            'original cause',
            isA<TimeoutException>(),
          ),
        ),
      );

      expect(primary.broadcasts, hasLength(1));
      expect(fallback.broadcasts, isEmpty);
      expect(primary.lookups, isNotEmpty);
      expect(fallback.lookups, hasLength(1));
    },
  );

  for (final found in [true, false]) {
    final outcome = found ? 'confirmed by raw lookup' : 'still unknown';
    test('already-known response is $outcome', () async {
      final primary = await start(
        broadcastError: 'txn-already-known',
        lookupResult: found ? _rawTx : null,
      );
      final fallback = await start();
      final client = clientFor(primary, [fallback]);

      if (found) {
        expect(await broadcast(client), _txid);
      } else {
        await expectLater(
          broadcast(client),
          throwsA(
            unknownWithTxid().having(
              (error) => error.cause,
              'original cause',
              isA<RpcException>(),
            ),
          ),
        );
      }

      expect(primary.broadcasts, hasLength(1));
      expect(primary.lookups, hasLength(1));
      expect(fallback.broadcasts, isEmpty);
    });
  }

  test(
    'definitive RPC rejection propagates without retry or reconciliation',
    () async {
      final primary = await start(
        broadcastError: 'mandatory-script-verify-flag-failed',
      );
      final fallback = await start(
        lookupResult: _rawTx,
        broadcastResult: _txid,
      );
      final client = clientFor(primary, [fallback]);

      await expectLater(
        broadcast(client),
        throwsA(
          isA<RpcException>().having(
            (error) => error.message,
            'reason',
            'mandatory-script-verify-flag-failed',
          ),
        ),
      );

      expect(primary.broadcasts, hasLength(1));
      expect(primary.lookups, isEmpty);
      expect(fallback.requests, isEmpty);
    },
  );

  test(
    'internal RPC errors leave a submitted broadcast indeterminate',
    () async {
      final primary = await start(
        broadcastError: 'Internal error',
        broadcastErrorCode: -32603,
      );
      final fallback = await start();
      final client = clientFor(primary, [fallback]);

      await expectLater(
        broadcast(client),
        throwsA(
          unknownWithTxid().having(
            (error) => error.cause,
            'original internal error',
            isA<RpcException>().having((error) => error.code, 'code', -32603),
          ),
        ),
      );

      expect(primary.broadcasts, hasLength(1));
      expect(primary.lookups, hasLength(1));
      expect(fallback.broadcasts, isEmpty);
      expect(fallback.lookups, hasLength(1));
    },
  );

  test(
    'a different raw transaction cannot confirm the submitted transaction',
    () async {
      final primary = await start(
        lookupResult: '${_rawTx.substring(0, _rawTx.length - 8)}01000000',
      );
      final client = clientFor(primary);

      await expectLater(broadcast(client), throwsA(unknownWithTxid()));

      expect(primary.broadcasts, hasLength(1));
      expect(primary.lookups, isNotEmpty);
    },
  );

  test('setup failure before sending stays a setup error', () async {
    final primary = await start(stallVersion: true);
    final fallback = await start(stallVersion: true);
    final client = clientFor(primary, [fallback]);

    await expectLater(broadcast(client), throwsA(isA<TimeoutException>()));

    expect(primary.broadcasts, isEmpty);
    expect(fallback.broadcasts, isEmpty);
    expect(primary.lookups, isEmpty);
    expect(fallback.lookups, isEmpty);
  });

  test(
    'raw request broadcast also avoids automatic replay after timeout',
    () async {
      final primary = await start(lookupResult: _rawTx);
      final fallback = await start(broadcastResult: _txid);
      final client = clientFor(primary, [fallback]);

      await expectLater(
        client
            .request(command: _broadcast, args: [_rawTx])
            .timeout(const Duration(seconds: 3)),
        throwsA(
          isA<BroadcastOutcomeUnknown>().having(
            (error) => error.txid,
            'unknown local ID',
            isNull,
          ),
        ),
      );

      expect(primary.broadcasts, hasLength(1));
      expect(fallback.requests, isEmpty);
    },
  );

  test('batch broadcast is rejected before opening a connection', () async {
    final primary = await start();
    final client = clientFor(primary);

    await expectLater(
      client.batchRequest(
        command: _broadcast,
        args: [
          [_rawTx],
        ],
      ),
      throwsArgumentError,
    );

    expect(primary.requests, isEmpty);
  });

  test(
    'closing an unresolved broadcast prevents fallback reconciliation',
    () async {
      final primary = await start();
      final fallback = await start(lookupResult: _rawTx);
      final client = clientFor(primary, [fallback]);
      final result = broadcast(client)
          .then<Object?>((value) => value, onError: (Object error) => error);
      await _until(() => primary.broadcasts.isNotEmpty);

      await client.closeAdapter();

      expect(await result, unknownWithTxid());
      expect(primary.broadcasts, hasLength(1));
      expect(primary.lookups, isEmpty);
      expect(fallback.requests, isEmpty);
    },
  );
}

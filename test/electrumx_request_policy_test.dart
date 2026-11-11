import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:event_bus/event_bus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart' show Level;
import 'package:mockito/mockito.dart';
import 'package:stackwallet/electrumx_rpc/client_manager.dart';
import 'package:stackwallet/electrumx_rpc/electrum_request_timeouts.dart';
import 'package:stackwallet/electrumx_rpc/electrumx_client.dart';
import 'package:stackwallet/services/event_bus/events/global/tor_connection_status_changed_event.dart';
import 'package:stackwallet/services/tor_service.dart';
import 'package:stackwallet/utilities/logger.dart';
import 'package:stackwallet/utilities/prefs.dart';
import 'package:stackwallet/utilities/tor_plain_net_option_enum.dart';
import 'package:stackwallet/wallets/crypto_currency/crypto_currency.dart';

const _historyMethod = 'blockchain.scripthash.get_history';
const _broadcastMethod = 'blockchain.transaction.broadcast';
const _short = Duration(milliseconds: 100);
const _long = Duration(seconds: 1);

class _Prefs extends Mock implements Prefs {
  @override
  bool get useTor => false;
  @override
  bool get wifiOnly => false;
}

class _Tor extends Mock implements TorService {
  @override
  TorConnectionStatus get status => TorConnectionStatus.disconnected;
}

class _ObservedTimeouts extends ElectrumRequestTimeouts {
  final resolved = <({String method, Duration timeout})>[];

  @override
  Duration forMethod(String method) {
    final timeout = super.forMethod(method);
    resolved.add((method: method, timeout: timeout));
    return timeout;
  }
}

/// Setup and headers reply immediately; application responses take 250ms.
class _PolicyServer {
  _PolicyServer(this.listener) {
    listener.listen((socket) {
      accepted++;
      sockets.add(socket);
      socket
          .cast<List<int>>()
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen(
            (line) {
              final message = jsonDecode(line);
              final requests = message is List ? message : [message];
              final responses = <Map<String, dynamic>>[];
              var delayed = false;
              for (final dynamic request in requests) {
                received.add(Map<String, dynamic>.from(request as Map));
                final method = request['method'] as String;
                methods.add(method);
                final Object result;
                switch (method) {
                  case 'server.version':
                    result = ['policy-test', '1.4'];
                  case 'blockchain.headers.subscribe':
                    result = {'height': 800000, 'hex': '00'};
                  case 'probe.ready':
                    result = <String, dynamic>{};
                  case _historyMethod:
                    delayed = true;
                    result = [
                      {'height': 1, 'tx_hash': request['params'][0]},
                    ];
                  case 'blockchain.transaction.get':
                    delayed = true;
                    result = request['params'][1] == true
                        ? {'txid': request['params'][0]}
                        : 'raw-transaction';
                  case _broadcastMethod:
                    delayed = true;
                    result = 'broadcast-txid';
                  case 'spark.getsparklatestcoinid':
                  case 'lelantus.getlatestcoinid':
                    delayed = true;
                    result = 42;
                  case 'blockchain.getfeerate':
                    delayed = true;
                    result = {'rate': 1000};
                  case 'lelantus.getmintmetadata':
                    delayed = true;
                    result = [
                      {'height': 10, 'groupId': 1},
                    ];
                  case 'lelantus.getanonymityset':
                  case 'spark.getsparkanonymityset':
                    delayed = true;
                    result = {
                      'blockHash': '00',
                      'setHash': '00',
                      'coins': <dynamic>[],
                    };
                  default:
                    delayed = true;
                    result = {'ok': true};
                }
                responses.add({
                  'jsonrpc': '2.0',
                  'id': request['id'],
                  'result': result,
                });
              }
              void reply() {
                if (sockets.contains(socket)) {
                  final payload = message is List
                      ? responses
                      : responses.single;
                  socket.write('${jsonEncode(payload)}\n');
                }
              }

              if (delayed) {
                timers.add(Timer(const Duration(milliseconds: 250), reply));
              } else {
                reply();
              }
            },
            onError: (Object _) {},
            onDone: () => sockets.remove(socket),
          );
    });
  }

  final ServerSocket listener;
  final sockets = <Socket>[];
  final timers = <Timer>[];
  final methods = <String>[];
  final received = <Map<String, dynamic>>[];
  int accepted = 0;
  int get port => listener.port;

  static Future<_PolicyServer> start() async =>
      _PolicyServer(await ServerSocket.bind(InternetAddress.loopbackIPv4, 0));

  Future<void> close() async {
    for (final timer in timers) {
      timer.cancel();
    }
    for (final socket in sockets.toList()) {
      socket.destroy();
    }
    sockets.clear();
    await listener.close();
  }
}

Matcher _deadline(Duration duration) => throwsA(
  isA<TimeoutException>().having(
    (error) => error.duration,
    'deadline',
    duration,
  ),
);

void main() {
  late Directory logs;
  late EventBus bus;
  setUpAll(() async {
    logs = await Directory.systemTemp.createTemp('electrum_request_policy');
    await Logging.instance.initialize(logs.path, level: Level.off);
  });
  tearDownAll(() => logs.delete(recursive: true));
  setUp(() => bus = EventBus());
  tearDown(() async {
    await ClientManager.sharedInstance.closeAll();
    bus.destroy();
  });

  Future<_PolicyServer> start() async {
    final server = await _PolicyServer.start();
    addTearDown(server.close);
    return server;
  }

  ElectrumXClient clientFor(
    _PolicyServer server, {
    ElectrumRequestTimeouts policy = const ElectrumRequestTimeouts(),
    CryptoCurrency? coin,
  }) {
    final client = ElectrumXClient(
      host: '127.0.0.1',
      port: server.port,
      useSSL: false,
      prefs: _Prefs(),
      torService: _Tor(),
      netType: TorPlainNetworkOption.both,
      failovers: [],
      cryptoCurrency: coin ?? Bitcoin(CryptoCurrencyNetwork.main),
      globalEventBusForTesting: bus,
      requestTimeouts: policy,
    );
    addTearDown(client.closeAdapter);
    return client;
  }

  test(
    'default history limit is shared by individual and batch helpers',
    () async {
      final server = await start();
      final policy = _ObservedTimeouts();
      final client = clientFor(server, policy: policy);
      expect(policy.standard, const Duration(seconds: 60));
      expect(policy.history, const Duration(minutes: 5));
      expect(policy.firoSet, const Duration(minutes: 2));

      expect(await client.getHistory(scripthash: 'single'), [
        {'height': 1, 'tx_hash': 'single'},
      ]);
      expect(
        await client.getBatchHistory(
          args: [
            ['batch'],
          ],
        ),
        [
          [
            {'height': 1, 'tx_hash': 'batch'},
          ],
        ],
      );
      expect(policy.resolved, [
        (method: _historyMethod, timeout: const Duration(minutes: 5)),
        (method: _historyMethod, timeout: const Duration(minutes: 5)),
      ]);
    },
  );

  test('broadcast has its own five-minute default policy', () {
    const policy = ElectrumRequestTimeouts();
    expect(policy.broadcast, const Duration(minutes: 5));
    expect(policy.forMethod(_broadcastMethod), policy.broadcast);
    expect(policy.standard, const Duration(seconds: 60));
    expect(policy.history, const Duration(minutes: 5));
    expect(policy.firoSet, const Duration(minutes: 2));
  });

  for (final generic in [false, true]) {
    final mode = generic ? 'generic request' : 'broadcast helper';
    for (final timeout in [_short, _long]) {
      test('$mode uses the broadcast policy $timeout', () async {
        final server = await start();
        final client = clientFor(
          server,
          policy: ElectrumRequestTimeouts(
            standard: timeout == _short ? _long : _short,
            broadcast: timeout,
          ),
        );
        final result = generic
            ? client.request(command: _broadcastMethod, args: ['signed-tx'])
            : client.broadcastTransaction(rawTx: 'signed-tx');
        if (timeout == _short) {
          await expectLater(result, _deadline(_short));
        } else {
          expect(await result, 'broadcast-txid');
        }
        expect(server.accepted, 1);
        final sent = server.received
            .where((request) => request['method'] == _broadcastMethod)
            .single;
        expect(sent['params'], ['signed-tx']);
      });
    }
  }

  for (final override in [_short, _long]) {
    test(
      'explicit broadcast request timeout overrides policy: $override',
      () async {
        final server = await start();
        final client = clientFor(
          server,
          policy: ElectrumRequestTimeouts(
            standard: _long,
            broadcast: override == _short ? _long : _short,
          ),
        );
        final result = client.request(
          command: _broadcastMethod,
          args: ['signed-tx'],
          requestTimeout: override,
        );
        if (override == _short) {
          await expectLater(result, _deadline(_short));
        } else {
          expect(await result, 'broadcast-txid');
        }
      },
    );
  }

  test('broadcast policy must be positive', () async {
    final server = await start();
    for (final invalid in [Duration.zero, const Duration(milliseconds: -1)]) {
      expect(
        () => clientFor(
          server,
          policy: ElectrumRequestTimeouts(broadcast: invalid),
        ),
        throwsArgumentError,
      );
    }
    expect(server.accepted, 0);
  });

  test('history helpers share a longer limit than standard requests', () async {
    final server = await start();
    final client = clientFor(
      server,
      policy: const ElectrumRequestTimeouts(standard: _short, history: _long),
    );
    await client.request(command: 'probe.ready');

    final results = await Future.wait([
      client.getHistory(scripthash: 'single'),
      client.getBatchHistory(
        args: [
          ['batch'],
        ],
      ),
    ]);
    expect(results, [
      [
        {'height': 1, 'tx_hash': 'single'},
      ],
      [
        [
          {'height': 1, 'tx_hash': 'batch'},
        ],
      ],
    ]);
    await expectLater(client.request(command: 'probe.slow'), _deadline(_short));
  });

  for (final batch in [false, true]) {
    final mode = batch ? 'batch' : 'individual';
    test('$mode history observes a shorter configured history limit', () async {
      final server = await start();
      final client = clientFor(
        server,
        policy: const ElectrumRequestTimeouts(standard: _long, history: _short),
      );
      await client.request(command: 'probe.ready');
      await expectLater(
        batch
            ? client.getBatchHistory(
                args: [
                  ['history'],
                ],
              )
            : client.getHistory(scripthash: 'history'),
        _deadline(_short),
      );
      expect(
        server.methods.where((method) => method == _historyMethod),
        hasLength(1),
      );
    });

    test(
      '$mode explicit timeout overrides the method policy in either direction',
      () async {
        final server = await start();
        final client = clientFor(
          server,
          policy: const ElectrumRequestTimeouts(
            standard: _long,
            history: _short,
          ),
        );
        Future<dynamic> history(Duration timeout) => batch
            ? client.batchRequest(
                command: _historyMethod,
                args: [
                  ['history'],
                ],
                requestTimeout: timeout,
              )
            : client.request(
                command: _historyMethod,
                args: ['history'],
                requestTimeout: timeout,
              );

        final result = await history(_long);
        expect(
          result,
          batch
              ? [
                  [
                    {'height': 1, 'tx_hash': 'history'},
                  ],
                ]
              : [
                  {'height': 1, 'tx_hash': 'history'},
                ],
        );
        const shorter = Duration(milliseconds: 50);
        await expectLater(history(shorter), _deadline(shorter));
      },
    );
  }

  test(
    'an empty history batch opens no connection or response timer',
    () async {
      final server = await start();
      final client = clientFor(server);
      expect(await client.getBatchHistory(args: []), isEmpty);
      expect(server.accepted, 0);
      expect(server.methods, isEmpty);
    },
  );

  for (final verbose in [false, true]) {
    for (final callerTimeout in [_short, _long]) {
      test('shared getTransaction uses caller timeout $callerTimeout '
          '(verbose: $verbose)', () async {
        final server = await start();
        final coin = Bitcoin(CryptoCurrencyNetwork.main);
        final owner = clientFor(
          server,
          coin: coin,
          policy: ElectrumRequestTimeouts(
            standard: callerTimeout == _short ? _long : _short,
          ),
        );
        final caller = clientFor(
          server,
          coin: coin,
          policy: ElectrumRequestTimeouts(standard: callerTimeout),
        );
        await owner.checkElectrumAdapter();
        await ClientManager.sharedInstance.getChainHeightFor(coin);
        await caller.checkElectrumAdapter();
        expect(caller.getElectrumAdapter(), same(owner.getElectrumAdapter()));

        final result = caller.getTransaction(txHash: 'tx', verbose: verbose);
        if (callerTimeout == _short) {
          await expectLater(result, _deadline(_short));
        } else {
          expect(
            await result,
            verbose ? {'txid': 'tx'} : {'rawtx': 'raw-transaction'},
          );
        }
        expect(server.accepted, 1);
        expect(
          server.methods.where(
            (method) => method == 'blockchain.transaction.get',
          ),
          hasLength(1),
        );
      });
    }
  }

  for (final (method, expected) in [
    ('spark.getsparklatestcoinid', 42),
    ('blockchain.getfeerate', {'rate': 1000}),
    ('lelantus.getlatestcoinid', 42),
    (
      'lelantus.getmintmetadata',
      [
        {'height': 10, 'groupId': 1},
      ],
    ),
  ]) {
    for (final callerTimeout in [_short, _long]) {
      test('shared $method uses caller timeout $callerTimeout', () async {
        final server = await start();
        final coin = method == 'blockchain.getfeerate'
            ? Bitcoin(CryptoCurrencyNetwork.main)
            : Firo(CryptoCurrencyNetwork.main);
        final owner = clientFor(
          server,
          coin: coin,
          policy: ElectrumRequestTimeouts(
            standard: callerTimeout == _short ? _long : _short,
          ),
        );
        final caller = clientFor(
          server,
          coin: coin,
          policy: ElectrumRequestTimeouts(standard: callerTimeout),
        );
        await owner.checkElectrumAdapter();
        await ClientManager.sharedInstance.getChainHeightFor(coin);
        await caller.checkElectrumAdapter();
        expect(caller.getElectrumAdapter(), same(owner.getElectrumAdapter()));

        final result = switch (method) {
          'spark.getsparklatestcoinid' => caller.getSparkLatestCoinId(),
          'blockchain.getfeerate' => caller.getFeeRate(),
          'lelantus.getlatestcoinid' => caller.getLelantusLatestCoinId(),
          'lelantus.getmintmetadata' => caller.getLelantusMintData(
            mints: ['mint'],
          ),
          _ => throw StateError('Unexpected test method: $method'),
        };
        if (callerTimeout == _short) {
          await expectLater(result, _deadline(_short));
        } else {
          expect(await result, expected);
        }
        expect(server.accepted, 1);
        final sent = server.received
            .where((request) => request['method'] == method)
            .single;
        expect(
          sent['params'],
          method == 'lelantus.getmintmetadata'
              ? [
                  ['mint'],
                ]
              : null,
        );
      });
    }
  }

  test('Firo set methods share their configurable policy', () {
    const policy = ElectrumRequestTimeouts(
      standard: _short,
      history: _long,
      firoSet: Duration(seconds: 2),
    );
    for (final method in [
      'lelantus.getanonymityset',
      'lelantus.getusedcoinserials',
      'spark.getusedcoinstags',
      'spark.getusedcoinstagstxhashes',
      'spark.getsparkanonymityset',
      'spark.getsparkanonymitysetsector',
    ]) {
      expect(policy.forMethod(method), policy.firoSet, reason: method);
    }
    expect(policy.forMethod('lelantus.getlatestcoinid'), _short);
    expect(policy.forMethod('probe.unknown'), _short);
  });

  test(
    'Firo anonymity helpers pass the longer set policy to the adapter',
    () async {
      final server = await start();
      final client = clientFor(
        server,
        coin: Firo(CryptoCurrencyNetwork.main),
        policy: const ElectrumRequestTimeouts(standard: _short, firoSet: _long),
      );
      expect((await client.getLelantusAnonymitySet())['coins'], isEmpty);
      expect((await client.getSparkAnonymitySet())['coins'], isEmpty);
      await expectLater(
        client.request(command: 'probe.slow'),
        _deadline(_short),
      );
    },
  );
}

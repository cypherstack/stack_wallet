import 'dart:io';

import 'package:decimal/decimal.dart';
import 'package:event_bus/event_bus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart' show Level;
import 'package:mockito/mockito.dart';
import 'package:stackwallet/electrumx_rpc/electrumx_client.dart';
import 'package:stackwallet/services/event_bus/events/global/tor_connection_status_changed_event.dart';
import 'package:stackwallet/services/tor_service.dart';
import 'package:stackwallet/utilities/logger.dart';
import 'package:stackwallet/utilities/prefs.dart';
import 'package:stackwallet/utilities/tor_plain_net_option_enum.dart';
import 'package:stackwallet/wallets/crypto_currency/coins/bitcoin.dart';
import 'package:stackwallet/wallets/crypto_currency/coins/firo.dart';
import 'package:stackwallet/wallets/crypto_currency/crypto_currency.dart';

import 'sample_data/get_anonymity_set_sample_data.dart';
import 'sample_data/get_used_serials_sample_data.dart';
import 'sample_data/gethistory_samples.dart';
import 'sample_data/transaction_data_samples.dart';
import 'utilities/mock_electrum_server.dart';

class MockPrefs extends Mock implements Prefs {
  @override
  bool get wifiOnly =>
      super.noSuchMethod(
            Invocation.getter(#wifiOnly),
            returnValue: false,
            returnValueForMissingStub: false,
          )
          as bool;

  @override
  bool get useTor =>
      super.noSuchMethod(
            Invocation.getter(#useTor),
            returnValue: false,
            returnValueForMissingStub: false,
          )
          as bool;

  @override
  bool get torKillSwitch =>
      super.noSuchMethod(
            Invocation.getter(#torKillSwitch),
            returnValue: false,
            returnValueForMissingStub: false,
          )
          as bool;
}

class FakeTorService implements TorService {
  FakeTorService({
    this.currentStatus = TorConnectionStatus.disconnected,
    ({InternetAddress host, int port})? proxyInfo,
  }) : _proxyInfo =
           proxyInfo ?? (host: InternetAddress.loopbackIPv4, port: 9050);

  TorConnectionStatus currentStatus;
  ({InternetAddress host, int port}) _proxyInfo;
  int statusReads = 0;
  int proxyInfoReads = 0;

  @override
  TorConnectionStatus get status {
    statusReads++;
    return currentStatus;
  }

  void setProxyInfo(({InternetAddress host, int port}) proxyInfo) {
    _proxyInfo = proxyInfo;
  }

  @override
  ({InternetAddress host, int port}) getProxyInfo() {
    proxyInfoReads++;
    return _proxyInfo;
  }

  @override
  Future<void> disable() async {}

  @override
  void init({required String torDataDirPath}) {}

  @override
  Future<void> start() async {}
}

void main() {
  late Directory logDir;
  late MockPrefs prefs;
  late FakeTorService torService;
  late EventBus eventBus;
  final servers = <MockElectrumServer>[];

  setUpAll(() async {
    logDir = await Directory.systemTemp.createTemp('electrumx_test_logs');
    await Logging.instance.initialize(logDir.path, level: Level.off);
  });

  Bitcoin bitcoin() => Bitcoin(CryptoCurrencyNetwork.main);
  Firo firo() => Firo(CryptoCurrencyNetwork.main);

  MockElectrumServer registerServer({
    Map<String, MockElectrumHandler> handlers = const {},
  }) {
    final server = MockElectrumServer(handlers: handlers);
    servers.add(server);
    return server;
  }

  ManagedElectrumXClient buildClient({
    required MockElectrumServer clearServer,
    MockElectrumServer? torServer,
    required CryptoCurrency coin,
    TorPlainNetworkOption netType = TorPlainNetworkOption.both,
  }) {
    return ManagedElectrumXClient(
      host: 'mock.stackwallet.dev',
      port: 50002,
      useSSL: true,
      prefs: prefs,
      torService: torService,
      failovers: [],
      cryptoCurrency: coin,
      netType: netType,
      clearServer: clearServer,
      torServer: torServer,
      globalEventBusForTesting: eventBus,
    );
  }

  Matcher throwsCurrentCastError() => throwsA(
    isA<Object>().having(
      (error) => error.toString(),
      'message',
      contains('is not a subtype'),
    ),
  );

  setUp(() {
    prefs = MockPrefs();
    torService = FakeTorService();
    eventBus = EventBus();
    servers.clear();

    when(prefs.wifiOnly).thenReturn(false);
    when(prefs.useTor).thenReturn(false);
    when(prefs.torKillSwitch).thenReturn(false);
  });

  tearDown(() async {
    await tearDownManagedElectrum(servers: servers);
  });

  group('factory constructors and getters', () {
    test('electrumxnode .from factory copies current fields', () {
      final nodeA = ElectrumXNode(
        address: 'some address',
        port: 50002,
        name: 'some name',
        id: 'some ID',
        useSSL: true,
        torEnabled: true,
        clearnetEnabled: false,
      );

      final nodeB = ElectrumXNode.from(nodeA);

      expect(nodeB.toString(), nodeA.toString());
      expect(nodeA == nodeB, false);
      expect(nodeB.torEnabled, isTrue);
      expect(nodeB.clearnetEnabled, isFalse);
    });

    test('electrumx .from factory uses current constructor inputs', () {
      final node = ElectrumXNode(
        address: 'some address',
        port: 60001,
        name: 'some name',
        id: 'some ID',
        useSSL: false,
        torEnabled: false,
        clearnetEnabled: true,
      );

      final client = ElectrumXClient.from(
        node: node,
        failovers: [],
        prefs: prefs,
        torService: torService,
        globalEventBusForTesting: eventBus,
        cryptoCurrency: bitcoin(),
      );

      expect(client.useSSL, isFalse);
      expect(client.host, node.address);
      expect(client.port, node.port);
      expect(client.netType, TorPlainNetworkOption.clear);
      expect(client.getElectrumAdapter(), isNull);
      verifyNever(prefs.useTor);
      expect(torService.statusReads, 0);
    });
  });

  group('generic request wrappers', () {
    test('ping success uses the live adapter client', () async {
      final server = registerServer(handlers: {'server.ping': (_) => null});
      final client = buildClient(clearServer: server, coin: bitcoin());

      final result = await client.ping(requestID: 'ping-1');

      expect(result, isTrue);
      expect(server.requestCount('blockchain.headers.subscribe'), 1);
      expect(server.requestCount('server.ping'), 1);
    });

    test('server.features success returns a parsed map', () async {
      final expected = {
        'genesis_hash': 'genesis',
        'hosts': {
          '0.0.0.0': {'tcp_port': 51001, 'ssl_port': 51002},
        },
        'protocol_max': '1.4',
        'protocol_min': '1.0',
        'server_version': 'ElectrumX 1.0.17',
        'hash_function': 'sha256',
      };
      final server = registerServer(
        handlers: {'server.features': (_) => expected},
      );
      final client = buildClient(clearServer: server, coin: bitcoin());

      final result = await client.getServerFeatures(requestID: 'features-1');

      expect(result, expected);
      expect(server.requestCount('server.features'), 1);
    });

    test('getTransaction supports verbose and raw responses', () async {
      final server = registerServer(
        handlers: {
          'blockchain.transaction.get': (params) {
            if (params.last == false) {
              return 'raw-transaction-hex';
            }
            return SampleGetTransactionData.txData0;
          },
        },
      );
      final client = buildClient(clearServer: server, coin: firo());

      final verbose = await client.getTransaction(
        txHash: SampleGetTransactionData.txHash0,
        verbose: true,
        requestID: 'tx-verbose',
      );
      final raw = await client.getTransaction(
        txHash: SampleGetTransactionData.txHash0,
        verbose: false,
        requestID: 'tx-raw',
      );

      expect(verbose, SampleGetTransactionData.txData0);
      expect(raw, {'rawtx': 'raw-transaction-hex'});
    });

    test('request surfaces server errors for malformed inputs', () async {
      final server = registerServer(
        handlers: {
          'blockchain.transaction.get': (_) => {
            'error': {
              'code': 1,
              'message': 'None should be a transaction hash',
            },
          },
        },
      );
      final client = buildClient(clearServer: server, coin: bitcoin());

      await expectLater(
        () => client.request(
          command: 'blockchain.transaction.get',
          args: const ['', true],
          requestID: 'bad-tx',
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('getHistory uses the current list payload', () async {
      final server = registerServer(
        handlers: {
          'blockchain.scripthash.get_history': (_) =>
              SampleGetHistoryData.data1,
        },
      );
      final client = buildClient(clearServer: server, coin: firo());

      final history = await client.getHistory(
        scripthash: SampleGetHistoryData.scripthash1,
        requestID: 'history-1',
      );

      expect(history, SampleGetHistoryData.data1);
      expect(server.requestCount('blockchain.scripthash.get_history'), 1);
    });

    test('getHistory throws after retrying malformed payloads', () async {
      final server = registerServer(
        handlers: {
          'blockchain.scripthash.get_history': (_) => {'unexpected': true},
        },
      );
      final client = buildClient(clearServer: server, coin: firo());

      await expectLater(
        () => client.getHistory(
          scripthash: SampleGetHistoryData.scripthash1,
          requestID: 'history-bad',
        ),
        throwsCurrentCastError(),
      );
      expect(server.requestCount('blockchain.scripthash.get_history'), 3);
    });

    test('fee wrappers use the current adapter command names', () async {
      final server = registerServer(
        handlers: {
          'blockchain.getfeerate': (_) => {'rate': 1000},
          'blockchain.estimatefee': (params) {
            expect(params, [5]);
            return '0.00001000';
          },
          'blockchain.relayfee': (_) => '0.00002000',
        },
      );
      final client = buildClient(clearServer: server, coin: firo());

      final feeRate = await client.getFeeRate(requestID: 'fee-rate');
      final estimate = await client.estimateFee(
        requestID: 'estimate-1',
        blocks: 5,
      );
      final relay = await client.relayFee(requestID: 'relay-1');

      expect(feeRate, {'rate': 1000});
      expect(estimate, Decimal.parse('0.00001000'));
      expect(relay, Decimal.parse('0.00002000'));
      expect(server.requestCount('blockchain.getfeerate'), 1);
      expect(server.requestCount('blockchain.estimatefee'), 1);
      expect(server.requestCount('blockchain.relayfee'), 1);
    });

    test('bad server exceptions bubble from current public wrappers', () async {
      final server = registerServer(
        handlers: {
          'server.features': (_) => throw Exception('mock bad server'),
        },
      );
      final client = buildClient(clearServer: server, coin: bitcoin());

      await expectLater(
        () => client.getServerFeatures(requestID: 'features-bad'),
        throwsA(
          isA<Exception>().having(
            (error) => error.toString(),
            'message',
            contains('mock bad server'),
          ),
        ),
      );
    });
  });

  group('Firo-specific wrappers', () {
    test(
      'Lelantus wrappers use the current payloads and request shapes',
      () async {
        const requestedMints = ['mint-a', 'mint-b'];
        final mintMetadata = {
          'mint-a': {'groupId': 1, 'height': 455866},
          'mint-b': {'groupId': 2, 'height': 455876},
        };
        final server = registerServer(
          handlers: {
            'lelantus.getanonymityset': (params) {
              expect(params, ['1', '']);
              return GetAnonymitySetSampleData.data;
            },
            'lelantus.getmintmetadata': (params) {
              expect(params, [requestedMints]);
              return mintMetadata;
            },
            'lelantus.getusedcoinserials': (params) {
              expect(params, ['0']);
              return GetUsedSerialsSampleData.serials;
            },
            'lelantus.getlatestcoinid': (_) => 42,
          },
        );
        final client = buildClient(clearServer: server, coin: firo());

        final anonymitySet = await client.getLelantusAnonymitySet(
          groupId: '1',
          blockhash: '',
          requestID: 'set-1',
        );
        final mintData = await client.getLelantusMintData(
          mints: requestedMints,
          requestID: 'mint-1',
        );
        final serials = await client.getLelantusUsedCoinSerials(
          requestID: 'serials-1',
          startNumber: 0,
        );
        final latest = await client.getLelantusLatestCoinId(requestID: 'id-1');

        expect(anonymitySet, GetAnonymitySetSampleData.data);
        expect(mintData, mintMetadata);
        expect(serials, GetUsedSerialsSampleData.serials);
        expect(latest, 42);
        expect(server.requestCount('lelantus.getanonymityset'), 1);
        expect(server.requestCount('lelantus.getmintmetadata'), 1);
        expect(server.requestCount('lelantus.getusedcoinserials'), 3);
        expect(server.requestCount('lelantus.getlatestcoinid'), 1);
      },
    );

    test('Lelantus wrappers surface current failure modes', () async {
      final server = registerServer(
        handlers: {
          'lelantus.getmintmetadata': (_) =>
              throw Exception('mint metadata unavailable'),
          'lelantus.getusedcoinserials': (_) => ['not-a-map'],
          'lelantus.getlatestcoinid': (_) => 'forty-two',
        },
      );
      final client = buildClient(clearServer: server, coin: firo());

      await expectLater(
        () => client.getLelantusMintData(
          mints: const ['mint-a'],
          requestID: 'mint-bad',
        ),
        throwsA(
          isA<Exception>().having(
            (error) => error.toString(),
            'message',
            contains('mint metadata unavailable'),
          ),
        ),
      );
      await expectLater(
        () => client.getLelantusUsedCoinSerials(
          requestID: 'serials-bad',
          startNumber: 0,
        ),
        throwsCurrentCastError(),
      );
      await expectLater(
        () => client.getLelantusLatestCoinId(requestID: 'id-bad'),
        throwsCurrentCastError(),
      );
      expect(server.requestCount('lelantus.getusedcoinserials'), 1);
    });
  });

  group('Tor tests', () {
    test('Tor not in use', () async {
      when(prefs.useTor).thenReturn(false);
      when(prefs.torKillSwitch).thenReturn(false);

      final clearServer = registerServer(
        handlers: {
          'blockchain.transaction.get': (_) => SampleGetTransactionData.txData0,
        },
      );
      final torServer = registerServer(
        handlers: {
          'blockchain.transaction.get': (_) => {'unexpected': true},
        },
      );

      final client = buildClient(
        clearServer: clearServer,
        torServer: torServer,
        coin: firo(),
      );

      final result = await client.getTransaction(
        txHash: SampleGetTransactionData.txHash0,
        verbose: true,
        requestID: 'tor-off',
      );

      expect(result, SampleGetTransactionData.txData0);
      expect(clearServer.requestCount('blockchain.transaction.get'), 1);
      expect(torServer.requestCount('blockchain.transaction.get'), 0);
      verify(prefs.useTor).called(greaterThanOrEqualTo(1));
      expect(torService.statusReads, 0);
      expect(torService.proxyInfoReads, 0);
    });

    test(
      'Tor in use but unavailable and killswitch off uses clearnet',
      () async {
        when(prefs.useTor).thenReturn(true);
        when(prefs.torKillSwitch).thenReturn(false);
        torService.currentStatus = TorConnectionStatus.disconnected;

        final clearServer = registerServer(
          handlers: {
            'blockchain.transaction.get': (_) =>
                SampleGetTransactionData.txData0,
          },
        );
        final torServer = registerServer(
          handlers: {
            'blockchain.transaction.get': (_) => {'unexpected': true},
          },
        );

        final client = buildClient(
          clearServer: clearServer,
          torServer: torServer,
          coin: firo(),
        );

        final result = await client.getTransaction(
          txHash: SampleGetTransactionData.txHash0,
          verbose: true,
          requestID: 'tor-fallback',
        );

        expect(result, SampleGetTransactionData.txData0);
        expect(clearServer.requestCount('blockchain.transaction.get'), 1);
        expect(torServer.requestCount('blockchain.transaction.get'), 0);
        expect(torService.statusReads, greaterThanOrEqualTo(1));
        expect(torService.proxyInfoReads, 0);
      },
    );

    test('Tor in use and available uses the tor-backed adapter', () async {
      when(prefs.useTor).thenReturn(true);
      torService.currentStatus = TorConnectionStatus.connected;
      torService.setProxyInfo((host: InternetAddress.loopbackIPv4, port: 9050));

      final clearServer = registerServer(
        handlers: {
          'blockchain.transaction.get': (_) => {'unexpected': true},
        },
      );
      final torServer = registerServer(
        handlers: {
          'blockchain.transaction.get': (_) => SampleGetTransactionData.txData0,
        },
      );

      final client = buildClient(
        clearServer: clearServer,
        torServer: torServer,
        coin: firo(),
      );

      final result = await client.getTransaction(
        txHash: SampleGetTransactionData.txHash0,
        verbose: true,
        requestID: 'tor-on',
      );

      expect(result, SampleGetTransactionData.txData0);
      expect(clearServer.requestCount('blockchain.transaction.get'), 0);
      expect(torServer.requestCount('blockchain.transaction.get'), 1);
      expect(torService.statusReads, greaterThanOrEqualTo(1));
      expect(torService.proxyInfoReads, greaterThanOrEqualTo(1));
    });

    test('killswitch enabled throws before any adapter request', () async {
      when(prefs.useTor).thenReturn(true);
      when(prefs.torKillSwitch).thenReturn(true);
      torService.currentStatus = TorConnectionStatus.disconnected;

      final clearServer = registerServer(
        handlers: {
          'blockchain.transaction.get': (_) => SampleGetTransactionData.txData0,
        },
      );

      final client = buildClient(clearServer: clearServer, coin: firo());

      await expectLater(
        () => client.getTransaction(
          txHash: SampleGetTransactionData.txHash0,
          verbose: true,
          requestID: 'tor-killswitch',
        ),
        throwsA(
          isA<Exception>().having(
            (error) => error.toString(),
            'message',
            contains(
              'Tor preference and killswitch set but Tor is not enabled',
            ),
          ),
        ),
      );
      expect(clearServer.requestCount('blockchain.transaction.get'), 0);
    });
  });
}

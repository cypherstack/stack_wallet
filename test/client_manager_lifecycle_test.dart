import 'dart:async';
import 'dart:io';

import 'package:electrum_adapter/electrum_adapter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart' show Level;
import 'package:stackwallet/electrumx_rpc/client_manager.dart';
import 'package:stackwallet/utilities/logger.dart';
import 'package:stackwallet/utilities/tor_plain_net_option_enum.dart';
import 'package:stackwallet/wallets/crypto_currency/crypto_currency.dart';
import 'package:stream_channel/stream_channel.dart';

class _RpcFixture {
  _RpcFixture({Duration? requestTimeout}) {
    final channel = StreamChannelController<dynamic>();
    server = channel.foreign;
    serverSubscription = server.stream.listen((dynamic request) {
      subscribed.complete();
      unawaited(
        firstHeader.future.then<void>((response) {
          if (!closed) {
            server.sink.add({
              'jsonrpc': '2.0',
              'id': request['id'],
              ...response,
            });
          }
        }),
      );
    });
    client = ElectrumClient(
      channel.local,
      'test.electrum',
      50001,
      false,
      null,
      requestTimeout: requestTimeout,
    );
  }

  late final StreamChannel<dynamic> server;
  late final StreamSubscription<dynamic> serverSubscription;
  late final ElectrumClient client;
  bool closed = false;
  final subscribed = Completer<void>();
  final firstHeader = Completer<Map<String, dynamic>>();

  void reply(int height) => firstHeader.complete({
    'result': {'height': height, 'hex': '00'},
  });

  void reject() => firstHeader.complete({
    'error': {'code': -32000, 'message': 'header subscription rejected'},
  });

  void notify(Object height) => server.sink.add({
    'jsonrpc': '2.0',
    'method': 'blockchain.headers.subscribe',
    'params': [
      {'height': height, 'hex': '00'},
    ],
  });

  Future<void> close() async {
    closed = true;
    await client.close();
    await serverSubscription.cancel();
    await server.sink.close();
  }
}

/// Allows a clean stream end before the first header, and delayed cancellation.
class _ControlledHeadersClient extends ElectrumClient {
  _ControlledHeadersClient({Future<void> Function()? onCancel})
    : headers = StreamController<dynamic>(onCancel: onCancel),
      super(
        StreamChannelController<dynamic>().local,
        'test.headers',
        50001,
        false,
        null,
      );

  final StreamController<dynamic> headers;

  @override
  Stream<T> subscribeNonBatch<T>(
    String methodPrefix, [
    List<dynamic> params = const [],
  ]) => headers.stream.cast<T>();
}

Future<void> _until(bool Function() ready) async {
  final watch = Stopwatch()..start();
  while (!ready()) {
    if (watch.elapsed > const Duration(seconds: 2)) {
      throw TimeoutException('Waiting for client lifecycle');
    }
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
}

void main() {
  final coin = Bitcoin(CryptoCurrencyNetwork.main);
  final manager = ClientManager.sharedInstance;
  final fixtures = <_RpcFixture>[];
  late Directory logs;

  setUpAll(() async {
    logs = await Directory.systemTemp.createTemp('client_manager_lifecycle');
    await Logging.instance.initialize(logs.path, level: Level.off);
  });
  tearDownAll(() => logs.delete(recursive: true));
  tearDown(() async {
    await manager.closeAll();
    for (final fixture in fixtures) {
      await fixture.close();
    }
    fixtures.clear();
  });

  Future<_RpcFixture> add({Duration? requestTimeout}) async {
    final fixture = _RpcFixture(requestTimeout: requestTimeout);
    fixtures.add(fixture);
    await manager.addClient(
      fixture.client,
      cryptoCurrency: coin,
      netType: TorPlainNetworkOption.both,
    );
    await fixture.subscribed.future;
    return fixture;
  }

  Future<void> expectHealthyReplacement() async {
    final healthy = await add();
    healthy.reply(123);
    expect(await manager.getChainHeightFor(coin), 123);
    expect(
      manager.getClient(
        cryptoCurrency: coin,
        netType: TorPlainNetworkOption.both,
      ),
      same(healthy.client),
    );
  }

  for (final retirement in ['remove', 'replace', 'closeAll']) {
    test('$retirement releases every pending first-height waiter', () async {
      final original = await add();
      final waits = [
        expectLater(manager.getChainHeightFor(coin), throwsStateError),
        expectLater(manager.getChainHeightFor(coin), throwsStateError),
      ];

      switch (retirement) {
        case 'remove':
          final removed = await manager.remove(cryptoCurrency: coin);
          expect(removed.$1, same(original.client));
          await removed.$1!.close();
          await expectHealthyReplacement();
        case 'replace':
          await expectHealthyReplacement();
        case 'closeAll':
          await manager.closeAll();
          await expectHealthyReplacement();
      }

      await Future.wait(waits).timeout(const Duration(seconds: 2));
      expect(original.client.peer.isClosed, true);
    });
  }

  test('subscription RPC rejection retires an otherwise live client', () async {
    final original = await add();
    final waiting = expectLater(
      manager.getChainHeightFor(coin),
      throwsA(
        predicate<Object>(
          (error) => error.toString().contains('header subscription rejected'),
        ),
      ),
    );
    expect(original.client.peer.isClosed, false);
    original.reject();

    await waiting.timeout(const Duration(seconds: 2));
    await _until(() => original.client.peer.isClosed);
    expect(
      manager.getClient(
        cryptoCurrency: coin,
        netType: TorPlainNetworkOption.both,
      ),
      isNull,
    );
    await expectHealthyReplacement();
  });

  test('subscription timeout releases its first-height waiter', () async {
    final original = await add(
      requestTimeout: const Duration(milliseconds: 100),
    );
    await expectLater(
      manager.getChainHeightFor(coin).timeout(const Duration(seconds: 2)),
      throwsA(
        isA<TimeoutException>().having(
          (error) => error.duration,
          'adapter deadline',
          const Duration(milliseconds: 100),
        ),
      ),
    );
    await _until(() => original.client.peer.isClosed);
    await expectHealthyReplacement();
  });

  test('failure before any height consumer does not escape the zone', () async {
    final original = await add();
    original.reject();
    await _until(() => original.client.peer.isClosed);
    // The test runner also fails if the unobserved completer emits an error.
    await expectLater(manager.getChainHeightFor(coin), throwsException);
    await expectHealthyReplacement();
  });

  test('a clean header stream end fails pending height waits', () async {
    final client = _ControlledHeadersClient();
    addTearDown(client.close);
    await manager.addClient(
      client,
      cryptoCurrency: coin,
      netType: TorPlainNetworkOption.both,
    );
    final waiting = expectLater(
      manager.getChainHeightFor(coin),
      throwsStateError,
    );
    await client.headers.close();
    await waiting.timeout(const Duration(seconds: 2));
    await _until(() => client.peer.isClosed);
    await expectHealthyReplacement();
  });

  test(
    'a failed established subscription cannot return its stale height',
    () async {
      final original = await add();
      original.reply(10);
      expect(await manager.getChainHeightFor(coin), 10);
      original.notify('invalid');
      await _until(() => original.client.peer.isClosed);
      await expectLater(manager.getChainHeightFor(coin), throwsException);
      await expectHealthyReplacement();
    },
  );

  test('retiring an old client cannot remove its healthy successor', () async {
    final original = await add();
    final oldWait = expectLater(
      manager.getChainHeightFor(coin),
      throwsStateError,
    );
    await expectHealthyReplacement();
    await oldWait;
    final removed = await manager.remove(
      cryptoCurrency: coin,
      expectedClient: original.client,
    );
    expect(removed, (null, null));
    expect(await manager.getChainHeightFor(coin), 123);
  });

  test(
    'shutdown finishing after replacement leaves the new client intact',
    () async {
      final cancellation = Completer<void>();
      final oldClient = _ControlledHeadersClient(
        onCancel: () => cancellation.future,
      );
      addTearDown(() async {
        if (!cancellation.isCompleted) cancellation.complete();
        await oldClient.close();
        await oldClient.headers.close();
      });
      await manager.addClient(
        oldClient,
        cryptoCurrency: coin,
        netType: TorPlainNetworkOption.both,
      );
      final oldWait = expectLater(
        manager.getChainHeightFor(coin),
        throwsStateError,
      );
      final closing = manager.closeAll();
      await oldWait.timeout(const Duration(seconds: 2));
      await expectHealthyReplacement();
      cancellation.complete();
      await closing;
      expect(await manager.getChainHeightFor(coin), 123);
    },
  );
}

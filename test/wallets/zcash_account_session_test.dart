import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/models/node_model.dart';
import 'package:stackwallet/wallets/crypto_currency/crypto_currency.dart';
import 'package:stackwallet/wallets/wallet/intermediate/zcash_account_session.dart';
import 'package:zcash_flutter/zcash_flutter.dart' as zcash;

class FakeLightwalletdClient implements ZcashLightwalletdClient {
  FakeLightwalletdClient({
    required this.chainName,
    required this.tipHeight,
    this.infoError,
    this.neverInfo = false,
    this.neverTip = false,
    this.infoCompleter,
  });

  final String chainName;
  final int tipHeight;
  final Object? infoError;
  bool neverInfo;
  bool neverTip;
  final Completer<zcash.LightdInfo>? infoCompleter;
  int infoCalls = 0;
  int tipCalls = 0;
  int closeCalls = 0;

  @override
  Future<zcash.LightdInfo> getInfo() async {
    infoCalls++;
    if (infoError case final error?) throw error;
    if (infoCompleter case final completer?) return completer.future;
    if (neverInfo) return Completer<zcash.LightdInfo>().future;
    return zcash.LightdInfo(chainName: chainName);
  }

  @override
  Future<int> getTipHeight() async {
    tipCalls++;
    if (neverTip) return Completer<int>().future;
    return tipHeight;
  }

  @override
  Future<void> close() async {
    closeCalls++;
  }
}

class SubmittingLightwalletdClient extends FakeLightwalletdClient
    implements ZcashLightwalletdSendClient {
  SubmittingLightwalletdClient({
    this.errorCode = 0,
    this.errorMessage = '',
    this.neverSubmit = false,
  }) : super(chainName: 'main', tipHeight: 42);

  final int errorCode;
  final String errorMessage;
  final bool neverSubmit;
  final List<Uint8List> submitted = [];

  @override
  Future<ZcashSubmissionAcknowledgement> submitTransaction(
    Uint8List transaction,
  ) async {
    submitted.add(Uint8List.fromList(transaction));
    if (neverSubmit) {
      return Completer<ZcashSubmissionAcknowledgement>().future;
    }
    return ZcashSubmissionAcknowledgement(
      errorCode: errorCode,
      errorMessage: errorMessage,
    );
  }
}

NodeModel node({
  String host = 'https://lightwalletd.example',
  int port = 443,
  bool useSSL = true,
}) => NodeModel(
  host: host,
  port: port,
  name: 'fixture',
  id: 'fixture-node',
  useSSL: useSSL,
  enabled: true,
  coinName: 'zcash',
  isFailover: false,
  isDown: false,
  torEnabled: false,
  clearnetEnabled: true,
  isPrimary: true,
);

void main() {
  test(
    'submits exact prepared bytes and returns an explicit acknowledgement',
    () async {
      final client = SubmittingLightwalletdClient();
      final session = ZcashAccountSession(
        network: CryptoCurrencyNetwork.main,
        clientFactory: (_) => client,
      );
      await session.replaceNode(node());

      final acknowledgement = await session.submitTransactionHex('00ff10');

      expect(client.submitted, [
        Uint8List.fromList([0, 255, 16]),
      ]);
      expect(acknowledgement.accepted, isTrue);
      expect(acknowledgement.errorCode, 0);
      await session.close();
    },
  );

  test('surfaces lightwalletd rejection explicitly', () async {
    final client = SubmittingLightwalletdClient(
      errorCode: -26,
      errorMessage: 'bad-tx',
    );
    final session = ZcashAccountSession(
      network: CryptoCurrencyNetwork.main,
      clientFactory: (_) => client,
    );
    await session.replaceNode(node());

    await expectLater(
      session.submitTransactionHex('00'),
      throwsA(
        isA<ZcashBroadcastRejectedException>()
            .having((e) => e.errorCode, 'errorCode', -26)
            .having((e) => e.message, 'message', 'bad-tx'),
      ),
    );
    await session.close();
  });

  test('bounds an indeterminate lightwalletd submission', () async {
    final client = SubmittingLightwalletdClient(neverSubmit: true);
    final session = ZcashAccountSession(
      network: CryptoCurrencyNetwork.main,
      clientFactory: (_) => client,
      requestTimeout: const Duration(milliseconds: 10),
    );
    await session.replaceNode(node());

    await expectLater(
      session.submitTransactionHex('00'),
      throwsA(
        isA<ZcashReadinessTimeoutException>().having(
          (e) => e.phase,
          'phase',
          'sendTransaction',
        ),
      ),
    );
    await session.close();
  });

  test('opens a bounded ready session from a Stack node', () async {
    final client = FakeLightwalletdClient(chainName: 'main', tipHeight: 42);
    ZcashEndpoint? openedEndpoint;
    final session = ZcashAccountSession(
      network: CryptoCurrencyNetwork.main,
      clientFactory: (endpoint) {
        openedEndpoint = endpoint;
        return client;
      },
      requestTimeout: const Duration(milliseconds: 100),
    );

    final readiness = await session.replaceNode(node());

    expect(
      openedEndpoint,
      const ZcashEndpoint(
        host: 'lightwalletd.example',
        port: 443,
        useTls: true,
        network: CryptoCurrencyNetwork.main,
      ),
    );
    expect(readiness.tipHeight, 42);
    expect(client.infoCalls, 1);
    expect(client.tipCalls, 1);
    expect(client.closeCalls, 0);

    await session.close();
    expect(client.closeCalls, 1);
  });

  test(
    'a rejected replacement closes its client and retains the old one',
    () async {
      final oldClient = FakeLightwalletdClient(
        chainName: 'main',
        tipHeight: 42,
      );
      final rejectedClient = FakeLightwalletdClient(
        chainName: 'main',
        tipHeight: 43,
        infoError: StateError('not ready'),
      );
      final clients = [oldClient, rejectedClient];
      final session = ZcashAccountSession(
        network: CryptoCurrencyNetwork.main,
        clientFactory: (_) => clients.removeAt(0),
        requestTimeout: const Duration(milliseconds: 100),
      );
      await session.replaceNode(node());

      await expectLater(
        session.replaceNode(node(host: 'replacement.example')),
        throwsStateError,
      );

      expect(rejectedClient.closeCalls, 1);
      expect(oldClient.closeCalls, 0);
      expect(await session.ping(), isTrue);
      expect(oldClient.infoCalls, 2);
      expect(oldClient.tipCalls, 2);
    },
  );

  test('rejects and closes an endpoint on the wrong Zcash network', () async {
    final client = FakeLightwalletdClient(chainName: 'test', tipHeight: 42);
    final session = ZcashAccountSession(
      network: CryptoCurrencyNetwork.main,
      clientFactory: (_) => client,
      requestTimeout: const Duration(milliseconds: 100),
    );

    await expectLater(
      session.replaceNode(node()),
      throwsA(isA<ZcashNetworkMismatchException>()),
    );
    expect(client.infoCalls, 1);
    expect(client.tipCalls, 0);
    expect(client.closeCalls, 1);
    expect(await session.ping(), isFalse);
  });

  test('accepts lightwalletd test chain identity for regtest', () async {
    final client = FakeLightwalletdClient(chainName: 'test', tipHeight: 42);
    final session = ZcashAccountSession(
      network: CryptoCurrencyNetwork.regtest,
      clientFactory: (_) => client,
      requestTimeout: const Duration(milliseconds: 100),
    );

    final readiness = await session.replaceNode(node());

    expect(readiness.info.chainName, 'test');
    expect(readiness.tipHeight, 42);
    expect(client.closeCalls, 0);
  });

  test('a chain-name mismatch leaves the active client usable', () async {
    final oldClient = FakeLightwalletdClient(chainName: 'main', tipHeight: 42);
    final wrongNetwork = FakeLightwalletdClient(
      chainName: 'test',
      tipHeight: 43,
    );
    final clients = [oldClient, wrongNetwork];
    final session = ZcashAccountSession(
      network: CryptoCurrencyNetwork.main,
      clientFactory: (_) => clients.removeAt(0),
      requestTimeout: const Duration(milliseconds: 100),
    );
    await session.replaceNode(node());

    await expectLater(
      session.replaceNode(node(host: 'testnet.example')),
      throwsA(isA<ZcashNetworkMismatchException>()),
    );

    expect(session.generation, 1);
    expect(wrongNetwork.closeCalls, 1);
    expect(oldClient.closeCalls, 0);
    expect(await session.ping(), isTrue);
  });

  test('bounds getLightdInfo and closes the timed-out candidate', () async {
    final client = FakeLightwalletdClient(
      chainName: 'main',
      tipHeight: 42,
      neverInfo: true,
    );
    final session = ZcashAccountSession(
      network: CryptoCurrencyNetwork.main,
      clientFactory: (_) => client,
      requestTimeout: const Duration(milliseconds: 10),
    );

    await expectLater(
      session.replaceNode(node()),
      throwsA(
        isA<ZcashReadinessTimeoutException>().having(
          (error) => error.phase,
          'phase',
          'getLightdInfo',
        ),
      ),
    );
    expect(client.closeCalls, 1);
  });

  test('bounds getTipHeight and closes the timed-out candidate', () async {
    final client = FakeLightwalletdClient(
      chainName: 'main',
      tipHeight: 42,
      neverTip: true,
    );
    final session = ZcashAccountSession(
      network: CryptoCurrencyNetwork.main,
      clientFactory: (_) => client,
      requestTimeout: const Duration(milliseconds: 10),
    );

    await expectLater(
      session.replaceNode(node()),
      throwsA(
        isA<ZcashReadinessTimeoutException>().having(
          (error) => error.phase,
          'phase',
          'getTipHeight',
        ),
      ),
    );
    expect(client.closeCalls, 1);
  });

  test('bounds readiness when pinging the active client', () async {
    final client = FakeLightwalletdClient(chainName: 'main', tipHeight: 42);
    final session = ZcashAccountSession(
      network: CryptoCurrencyNetwork.main,
      clientFactory: (_) => client,
      requestTimeout: const Duration(milliseconds: 10),
    );
    await session.replaceNode(node());
    client.neverTip = true;

    expect(await session.ping(), isFalse);
    expect(client.closeCalls, 0);
  });

  test('rejects ambiguous or contradictory Stack node endpoints', () {
    final invalid = [
      node(host: ''),
      node(host: 'https://lightwalletd.example', useSSL: false),
      node(host: 'http://lightwalletd.example', useSSL: true),
      node(host: 'https://user@lightwalletd.example'),
      node(host: 'https://lightwalletd.example/rpc'),
      node(host: 'https://lightwalletd.example?network=main'),
      node(host: 'https://lightwalletd.example:9067', port: 443),
      node(port: 0),
      node(port: 65536),
    ];

    for (final value in invalid) {
      expect(
        () => ZcashEndpoint.fromNode(value, CryptoCurrencyNetwork.main),
        throwsArgumentError,
        reason: value.toString(),
      );
    }
  });

  test(
    'successful replacement advances generation and closes exactly once',
    () async {
      final first = FakeLightwalletdClient(chainName: 'main', tipHeight: 42);
      final second = FakeLightwalletdClient(chainName: 'main', tipHeight: 43);
      final clients = [first, second];
      final session = ZcashAccountSession(
        network: CryptoCurrencyNetwork.main,
        clientFactory: (_) => clients.removeAt(0),
        requestTimeout: const Duration(milliseconds: 100),
      );

      expect(session.generation, 0);
      await session.replaceNode(node());
      expect(session.generation, 1);
      await session.replaceNode(node(host: 'replacement.example'));
      expect(session.generation, 2);
      expect(first.closeCalls, 1);
      expect(second.closeCalls, 0);

      await session.close();
      expect(session.generation, 3);
      await session.close();
      expect(session.generation, 3);
      expect(first.closeCalls, 1);
      expect(second.closeCalls, 1);
    },
  );

  test('close prevents an in-flight replacement from installing', () async {
    final active = FakeLightwalletdClient(chainName: 'main', tipHeight: 42);
    final delayedInfo = Completer<zcash.LightdInfo>();
    final candidate = FakeLightwalletdClient(
      chainName: 'main',
      tipHeight: 43,
      infoCompleter: delayedInfo,
    );
    final clients = [active, candidate];
    final session = ZcashAccountSession(
      network: CryptoCurrencyNetwork.main,
      clientFactory: (_) => clients.removeAt(0),
      requestTimeout: const Duration(milliseconds: 100),
    );
    await session.replaceNode(node());

    final replacement = session.replaceNode(node(host: 'delayed.example'));
    await Future<void>.delayed(Duration.zero);
    expect(candidate.infoCalls, 1);

    await session.close();
    delayedInfo.complete(zcash.LightdInfo(chainName: 'main'));

    await expectLater(replacement, throwsStateError);
    expect(session.generation, 2);
    expect(active.closeCalls, 1);
    expect(candidate.closeCalls, 1);
    expect(await session.ping(), isFalse);
    await session.close();
    expect(active.closeCalls, 1);
    expect(candidate.closeCalls, 1);
  });
}

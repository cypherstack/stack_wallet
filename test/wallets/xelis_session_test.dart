import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/models/node_model.dart';
import 'package:stackwallet/wallets/crypto_currency/crypto_currency.dart';
import 'package:stackwallet/wallets/wallet/impl/xelis_wallet.dart';
import 'package:stackwallet/wl_gen/interfaces/lib_xelis_interface.dart';

import 'support/xelis_test_fakes.dart';

class SessionNative extends Fake implements LibXelisInterface {
  @override
  String get xelisAsset => 'xel';
  final runtime = <StreamController<Event>>[];
  final business = <StreamController<Event>>[];
  final order = <String>[];
  bool failRuntimeCancel = false;
  bool failRuntimeSubscribe = false;
  bool failBusinessSubscribe = false;
  Completer<void>? onlineStarted;
  Completer<void>? onlineRelease;
  @override
  Future<XelisEventSubscription> subscribeRuntimeEvents(
    OpaqueXelisWallet wallet,
  ) async {
    if (failRuntimeSubscribe) throw StateError('runtime subscription failed');
    final controller = StreamController<Event>();
    runtime.add(controller);
    return XelisEventSubscription(
      events: controller.stream,
      cancel: () async {
        order.add('cancel-runtime');
        await controller.close();
        if (failRuntimeCancel) throw StateError('test cancellation failure');
      },
    );
  }

  @override
  Future<XelisEventSubscription> subscribeBusinessEvents(
    OpaqueXelisWallet wallet,
  ) async {
    if (failBusinessSubscribe) throw StateError('business subscription failed');
    final controller = StreamController<Event>();
    business.add(controller);
    return XelisEventSubscription(
      events: controller.stream,
      cancel: () async {
        order.add('cancel-business');
        await controller.close();
      },
    );
  }

  @override
  Future<void> onlineMode(
    OpaqueXelisWallet wallet, {
    required String daemonAddress,
  }) async {
    order.add(daemonAddress);
    if (!(onlineStarted?.isCompleted ?? true)) onlineStarted!.complete();
    await onlineRelease?.future;
  }

  @override
  Future<void> offlineMode(OpaqueXelisWallet wallet) async =>
      order.add('offline');
  @override
  Future<void> closeWallet(OpaqueXelisWallet wallet) async =>
      order.add('close');
}

class SessionWallet extends XelisWallet {
  SessionWallet(SessionNative native)
    : super(CryptoCurrencyNetwork.test, native: native) {
    wallet = const OpaqueXelisWallet(Object());
    prefs = SessionPrefs();
  }
  final handled = <Event>[];
  int reconnectRequests = 0;
  @override
  void scheduleReconnect() {
    reconnectRequests++;
    super.scheduleReconnect();
  }

  @override
  String get walletId => 'isolated-session-test';
  @override
  NodeModel getCurrentNode() => cryptoCurrency.defaultNode(isPrimary: true);
  @override
  Future<void> refresh({int? topoheight}) async {}
  @override
  Future<void> handleEvent(
    Event event, {
    required bool Function() isCurrent,
  }) async {
    await Future<void>.delayed(Duration.zero);
    if (isCurrent()) handled.add(event);
  }
}

void main() {
  testWidgets(
    'business event bursts coalesce and shutdown drops pending work',
    (tester) async {
      final native = SessionNative();
      final wallet = SessionWallet(native);
      await wallet.connect();
      for (var i = 0; i < 20; i++) {
        native.runtime.single.add(NewTopoheight(BigInt.from(i)));
        native.business.single.add(BalanceChanged('xel', BigInt.from(i)));
      }
      await tester.pump();
      expect(wallet.handled, isEmpty);
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump();
      await tester.pump();
      expect(wallet.handled.whereType<NewTopoheight>(), hasLength(1));
      expect(wallet.handled.whereType<BalanceChanged>(), hasLength(1));
      expect(
        wallet.handled.whereType<NewTopoheight>().single.height,
        BigInt.from(19),
      );
      native.business.single.add(NewTopoheight(BigInt.from(21)));
      await tester.pump();
      await wallet.exit();
      await tester.pump(const Duration(seconds: 1));
      expect(wallet.handled, hasLength(2));
    },
  );

  testWidgets('automatic retry backs off, caps at 32s and resets on success', (
    tester,
  ) async {
    final native = SessionNative()..failRuntimeSubscribe = true;
    final wallet = SessionWallet(native);
    await expectLater(wallet.connect(), throwsStateError);
    int attempts() => native.order.where((entry) => entry == 'offline').length;
    var expectedAttempts = 1;
    for (final seconds in [1, 2, 4, 8, 16, 32, 32]) {
      await tester.pump(Duration(milliseconds: seconds * 1000 - 1));
      expect(attempts(), expectedAttempts);
      await tester.pump(const Duration(milliseconds: 1));
      expect(attempts(), ++expectedAttempts);
    }
    native.failRuntimeSubscribe = false;
    await tester.pump(const Duration(seconds: 32));
    expect(attempts(), ++expectedAttempts);
    expect(native.runtime, hasLength(1));
    native.runtime.single.addError(StateError('synthetic channel failure'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 999));
    expect(attempts(), expectedAttempts);
    await tester.pump(const Duration(milliseconds: 1));
    expect(attempts(), ++expectedAttempts);
    expect(native.runtime, hasLength(2));
    await wallet.exit();
  });

  testWidgets('shutdown cancels a scheduled automatic retry', (tester) async {
    final native = SessionNative()..failBusinessSubscribe = true;
    final wallet = SessionWallet(native);
    await expectLater(wallet.connect(), throwsStateError);
    await wallet.exit();
    final orderAfterExit = List<String>.of(native.order);
    await tester.pump(const Duration(minutes: 2));
    expect(native.order, orderAfterExit);
    expect(native.order.last, 'close');
    expect(wallet.wallet, isNull);
  });

  testWidgets('simultaneous channel failures share one automatic retry', (
    tester,
  ) async {
    final native = SessionNative();
    final wallet = SessionWallet(native);
    await wallet.connect();
    native.runtime.single.addError(StateError('synthetic runtime failure'));
    native.business.single.addError(StateError('synthetic business failure'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(native.runtime, hasLength(2));
    expect(native.business, hasLength(2));
    await tester.pump(const Duration(seconds: 40));
    expect(native.runtime, hasLength(2));
    expect(native.business, hasLength(2));
    await wallet.exit();
  });

  for (final isRuntime in [false, true]) {
    test(
      'failed ${isRuntime ? 'runtime' : 'business'} subscription can retry',
      () async {
        final native = SessionNative()
          ..failRuntimeSubscribe = isRuntime
          ..failBusinessSubscribe = !isRuntime;
        final wallet = SessionWallet(native);
        addTearDown(wallet.exit);
        await expectLater(wallet.connect(), throwsStateError);
        expect(wallet.reconnectRequests, 1);
        native
          ..failRuntimeSubscribe = false
          ..failBusinessSubscribe = false;
        await wallet.connect();
        expect(native.runtime, hasLength(1));
        expect(native.business, hasLength(1));
      },
    );

    test(
      'closed ${isRuntime ? 'runtime' : 'business'} channel is replaced',
      () async {
        final native = SessionNative();
        final wallet = SessionWallet(native);
        addTearDown(wallet.exit);
        await wallet.connect();
        await (isRuntime ? native.runtime.single : native.business.single)
            .close();
        expect(wallet.reconnectRequests, 1);
        await wallet.connect();
        expect(native.runtime, hasLength(2));
        expect(native.business, hasLength(isRuntime ? 1 : 2));
        native.business.last.add(const Online());
        await Future<void>.delayed(Duration.zero);
        await Future<void>.delayed(Duration.zero);
        expect(wallet.handled, hasLength(1));
      },
    );
  }

  test(
    'rapid connection requests skip superseded queued connections',
    () async {
      final native = SessionNative()
        ..onlineStarted = Completer<void>()
        ..onlineRelease = Completer<void>();
      final wallet = SessionWallet(native);
      addTearDown(wallet.exit);
      final first = wallet.connect();
      await native.onlineStarted!.future;
      final second = wallet.connect();
      final third = wallet.connect();
      native.onlineRelease!.complete();
      await Future.wait([first, second, third]);
      expect(native.runtime, hasLength(2));
      expect(native.business, hasLength(1));
      expect(
        native.order.where((entry) => entry.startsWith('https://')),
        hasLength(2),
      );
    },
  );

  test(
    'node rotation replaces runtime but preserves the business channel',
    () async {
      final native = SessionNative();
      final wallet = SessionWallet(native);
      await wallet.connect();
      native.runtime.single.add(const Online());
      await wallet.connect();
      expect(wallet.handled, isEmpty);
      expect(native.runtime, hasLength(2));
      expect(native.business, hasLength(1));
      expect(
        native.order.where((entry) => entry.startsWith('https://')),
        hasLength(2),
      );
      await wallet.exit();
      expect(native.order.last, 'close');
      expect(wallet.wallet, isNull);
    },
  );

  test('shutdown still cancels business and closes native storage '
      'after a cancellation error', () async {
    final native = SessionNative();
    final wallet = SessionWallet(native);
    await wallet.connect();
    native.failRuntimeCancel = true;
    await expectLater(wallet.exit(), throwsStateError);
    expect(
      native.order,
      containsAllInOrder(['cancel-runtime', 'cancel-business', 'close']),
    );
    expect(wallet.exitInProgress, isFalse);
    expect(wallet.wallet, isNull);
  });
}

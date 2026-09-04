import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/wallets/wallet/intermediate/cryptonote_wallet_lifecycle.dart';

void main() {
  test("Tor transition gate waits for a status change", () async {
    final gate = CryptonoteTorTransitionGate()..block();
    var blocked = true;
    var completed = false;

    final wait = gate
        .wait(isBlocked: () => blocked, isCurrent: () => true)
        .then((value) {
          completed = true;
          return value;
        });
    await Future<void>.delayed(Duration.zero);
    expect(completed, isFalse);

    blocked = false;
    gate.release();
    expect(await wait, isTrue);
  });

  test("Tor transition gate aborts a superseded operation", () async {
    final gate = CryptonoteTorTransitionGate()..block();
    var current = true;

    final wait = gate.wait(isBlocked: () => true, isCurrent: () => current);
    current = false;
    gate.release();

    expect(await wait, isFalse);
  });

  test("Tor transition gate aborts an already superseded operation", () async {
    final gate = CryptonoteTorTransitionGate()..block();

    // exit() detached this wallet's Tor listeners before the update reached the
    // gate, so nothing will ever release it on this wallet's behalf.
    final wait = gate
        .wait(isBlocked: () => true, isCurrent: () => false)
        .timeout(const Duration(seconds: 5));

    expect(await wait, isFalse);
  });

  test("subscription cleanup continues after one cancellation fails", () async {
    var secondCancellation = 0;
    final first = StreamController<void>(
      onCancel: () async => throw Exception("cancel failed"),
    );
    final second = StreamController<void>(
      onCancel: () async => secondCancellation++,
    );
    final subscriptions = [
      first.stream.listen((_) {}),
      second.stream.listen((_) {}),
    ];

    await expectLater(
      cancelCryptonoteWalletSubscriptions(subscriptions),
      throwsA(isA<Exception>()),
    );
    expect(secondCancellation, 1);
    await first.close();
    await second.close();
  });

  test("close stops sources before waiting for an active update", () async {
    final lifecycle = CryptonoteWalletLifecycle();
    final updateStarted = Completer<void>();
    final releaseUpdate = Completer<void>();
    final calls = <String>[];

    final update = lifecycle.updateNode((_) async {
      calls.add("update start");
      updateStarted.complete();
      await releaseUpdate.future;
      calls.add("update end");
    });
    await updateStarted.future;

    final close = lifecycle.close(
      stopEventSources: () async => calls.add("stop sources"),
      closeNative: () async => calls.add("close native"),
    );
    await Future<void>.delayed(Duration.zero);

    expect(calls, ["update start", "stop sources"]);
    releaseUpdate.complete();
    await Future.wait([update, close]);
    expect(calls, [
      "update start",
      "stop sources",
      "update end",
      "stop sources",
      "close native",
    ]);
  });

  test("queued node update is rejected after close begins", () async {
    final lifecycle = CryptonoteWalletLifecycle();
    final openStarted = Completer<void>();
    final releaseOpen = Completer<void>();
    var updates = 0;

    final open = lifecycle.open((_) async {
      openStarted.complete();
      await releaseOpen.future;
    });
    await openStarted.future;
    final queuedUpdate = lifecycle.updateNode((_) async => updates++);
    final close = lifecycle.close(
      stopEventSources: () async {},
      closeNative: () async {},
    );

    releaseOpen.complete();
    await Future.wait([open, queuedUpdate, close]);
    expect(updates, 0);
  });

  test("close requested after a queued open still ends closed", () async {
    final lifecycle = CryptonoteWalletLifecycle();
    final releaseUpdate = Completer<void>();

    // Something already holds the mutex, so the open queues behind it.
    final update = lifecycle.updateNode((_) => releaseUpdate.future);
    final open = lifecycle.open((_) async {});
    final close = lifecycle.close(
      stopEventSources: () async {},
      closeNative: () async {},
    );
    releaseUpdate.complete();
    await Future.wait([update, open, close]);

    expect(lifecycle.allowsNodeUpdates, isFalse);
    var updates = 0;
    await lifecycle.updateNode((_) async => updates++);
    expect(updates, 0);
  });

  test("close in the same tick as open wins", () async {
    final lifecycle = CryptonoteWalletLifecycle();

    final open = lifecycle.open((_) async {});
    final close = lifecycle.close(
      stopEventSources: () async {},
      closeNative: () async {},
    );
    await Future.wait([open, close]);

    expect(lifecycle.allowsNodeUpdates, isFalse);
  });

  test("failed open rejects updates until a successful reopen", () async {
    final lifecycle = CryptonoteWalletLifecycle();

    await expectLater(
      lifecycle.open((_) async => throw Exception("open failed")),
      throwsException,
    );
    await lifecycle.updateNode((_) async => fail("update must be rejected"));

    await lifecycle.open((_) async {});
    var updates = 0;
    await lifecycle.updateNode((_) async => updates++);
    expect(updates, 1);
  });

  test("close catches event sources attached by an active open", () async {
    final lifecycle = CryptonoteWalletLifecycle();
    final openStarted = Completer<void>();
    final releaseOpen = Completer<void>();
    var sourceAttached = false;
    var stops = 0;

    final open = lifecycle.open((isCurrent) async {
      openStarted.complete();
      await releaseOpen.future;
      sourceAttached = true;
      expect(isCurrent(), isFalse);
    });
    await openStarted.future;
    final close = lifecycle.close(
      stopEventSources: () async {
        if (sourceAttached) {
          sourceAttached = false;
          stops++;
        }
      },
      closeNative: () async {},
    );

    releaseOpen.complete();
    await Future.wait([open, close]);
    expect(sourceAttached, isFalse);
    expect(stops, 1);
  });

  test("queued native work is rejected after close begins", () async {
    final lifecycle = CryptonoteWalletLifecycle();
    final stopStarted = Completer<void>();
    final releaseStop = Completer<void>();

    final close = lifecycle.close(
      stopEventSources: () async {
        if (!stopStarted.isCompleted) {
          stopStarted.complete();
          await releaseStop.future;
        }
      },
      closeNative: () async {},
    );
    await stopStarted.future;
    final nativeWork = lifecycle.replaceNative(() async {});

    releaseStop.complete();
    await close;
    await expectLater(nativeWork, throwsStateError);
  });

  test("source cancellation failure does not skip native close", () async {
    final lifecycle = CryptonoteWalletLifecycle();
    var closeCalls = 0;

    await expectLater(
      lifecycle.close(
        stopEventSources: () async => throw Exception("cancel failed"),
        closeNative: () async => closeCalls++,
      ),
      throwsA(isA<Exception>()),
    );
    expect(closeCalls, 1);
  });
}

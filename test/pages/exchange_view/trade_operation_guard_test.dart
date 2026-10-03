import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/pages/exchange_view/trade_operation_guard.dart';

void main() {
  test("waits for an in-flight refresh before deleting", () async {
    final refresh = Completer<void>();
    final guard = TradeOperationGuard()..trackStatusRefresh(refresh.future);
    var deleted = false;

    final result = guard.deleteAfterRefresh(() async => deleted = true);

    expect(guard.deletionRequested, isTrue);
    expect(deleted, isFalse);

    refresh.complete();
    expect(await result, isTrue);
    expect(deleted, isTrue);
  });

  testWidgets("bounds the wait so a stalled refresh cannot block deletion", (
    tester,
  ) async {
    final guard = TradeOperationGuard()
      ..trackStatusRefresh(Completer<void>().future);
    var deleted = false;
    bool? outcome;

    unawaited(
      guard
          .deleteAfterRefresh(() async => deleted = true)
          .then((value) => outcome = value),
    );

    await tester.pump();
    expect(deleted, isFalse);

    await tester.pump(
      TradeOperationGuard.refreshWaitTimeout + const Duration(seconds: 1),
    );
    await tester.pump();

    expect(deleted, isTrue);
    expect(outcome, isTrue);
  });

  test("allows retry after a failed delete", () async {
    final guard = TradeOperationGuard();

    await expectLater(
      guard.deleteAfterRefresh(() async => throw Exception("database error")),
      throwsException,
    );
    expect(guard.deletionRequested, isFalse);
    expect(await guard.deleteAfterRefresh(() async {}), isTrue);
  });

  test("ignores duplicate delete requests", () async {
    final refresh = Completer<void>();
    final lateRefresh = Completer<void>();
    final guard = TradeOperationGuard()..trackStatusRefresh(refresh.future);

    final first = guard.deleteAfterRefresh(() async {});
    guard.trackStatusRefresh(lateRefresh.future);
    expect(await guard.deleteAfterRefresh(() async {}), isFalse);

    refresh.complete();
    expect(await first, isTrue);
  });
}

import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Bounded real-app pumping. Never print finders containing recovery words.
class TestUI {
  TestUI(this.tester);

  final WidgetTester tester;
  final errors = <Object>[];
  File? errorLog;
  String _stage = 'startup';
  String get stage => _stage;
  set stage(String value) {
    _stage = value;
    report('STAGE $value');
  }

  void report(String message) =>
      debugPrintSynchronously('WALLET_CREATION_$message');

  Future<void> pump() async {
    await tester
        .pump(const Duration(milliseconds: 100))
        .timeout(
          const Duration(seconds: 20),
          onTimeout: () =>
              fail('$stage: no frame received from the native app'),
        );
    final Object? exception = tester.takeException();
    if (exception != null) errors.add(exception);
    if (errors.isNotEmpty) {
      // Only the disposable test root gets full diagnostics. The runner deletes
      // this with the native logs; public output cannot expose recovery data.
      await errorLog?.writeAsString(errors.first.toString(), flush: true);
      fail(
        '$stage: app raised ${errors.first.runtimeType} '
        '(exception text omitted to protect recovery data)',
      );
    }
    if (find.text('Create Wallet Error').evaluate().isNotEmpty) {
      fail('$stage: app displayed a wallet creation error');
    }
  }

  Future<void> until(
    FutureOr<bool> Function() condition,
    String description, {
    Duration timeout = const Duration(minutes: 2),
  }) async {
    final deadline = DateTime.now().add(timeout);
    while (true) {
      await pump();
      if (await condition()) return;
      if (DateTime.now().isAfter(deadline)) {
        fail('$stage: timed out waiting for $description');
      }
    }
  }

  Future<void> waitFor(
    Finder finder, {
    String description = 'screen',
    Duration timeout = const Duration(minutes: 2),
  }) =>
      until(() => finder.evaluate().isNotEmpty, description, timeout: timeout);

  Future<void> reveal(Finder finder) async {
    await waitFor(finder, description: 'control');
    expect(finder.evaluate().length, 1, reason: '$stage: ambiguous control');
    if (finder.hitTestable().evaluate().isNotEmpty) return;
    await tester.ensureVisible(finder);
    await tester
        .pump(const Duration(milliseconds: 350))
        .timeout(
          const Duration(seconds: 20),
          onTimeout: () => fail('$stage: native app stopped producing frames'),
        );
  }

  Future<void> tap(Finder finder) async {
    await reveal(finder);
    await until(
      () => finder.hitTestable().evaluate().length == 1,
      'tappable control',
    );
    await tester.tap(finder.hitTestable());
    await pump();
  }

  Future<void> tapText(String text, {Finder? within}) => tap(
    within == null
        ? find.text(text, findRichText: true)
        : find.descendant(
            of: within,
            matching: find.text(text, findRichText: true),
          ),
  );

  Future<void> enter(Finder finder, String value) async {
    await reveal(finder);
    await tester.enterText(finder, value);
    await pump();
  }

  /// Scroll a lazy wallet list until its requested row is built.
  Future<void> revealListRow(Finder finder, Finder list) async {
    await waitFor(list);
    if (finder.evaluate().isEmpty) {
      final scrollable = find
          .descendant(of: list, matching: find.byType(Scrollable))
          .first;
      await waitFor(scrollable.hitTestable(), description: 'wallet list');
      // Coin sorting can put a new row above the previously opened wallet.
      // Reset the viewport before searching the lazily built list downward.
      final position = tester.state<ScrollableState>(scrollable).position;
      position.jumpTo(position.minScrollExtent);
      await pump();
      await tester.scrollUntilVisible(
        finder,
        250,
        scrollable: scrollable,
        maxScrolls: 50,
      );
    }
    await reveal(finder);
  }
}

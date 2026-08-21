import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/widgets/async_pop_scope.dart';

import 'helpers/navigation_test_helpers.dart';

void main() {
  final navigatorKey = GlobalKey<NavigatorState>();

  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigatorKey,
        home: const Scaffold(body: Text('home')),
      ),
    );
  }

  Future<T?> pushGuardedRoute<T>({
    required Future<bool> Function() onPopAttempt,
  }) {
    final result = navigatorKey.currentState!.push<T>(
      MaterialPageRoute<T>(
        builder: (_) => AsyncPopScope<T>(
          onPopAttempt: onPopAttempt,
          child: const Scaffold(body: Text('guarded')),
        ),
      ),
    );
    return result;
  }

  testWidgets('system back waits for approval before popping', (tester) async {
    await pumpApp(tester);
    final approval = Completer<bool>();
    var attempts = 0;
    final routeResult = pushGuardedRoute<void>(
      onPopAttempt: () {
        attempts++;
        return approval.future;
      },
    );
    await tester.pumpAndSettle();

    await simulateSystemBack();
    await tester.pump();

    expect(attempts, 1);
    expect(find.text('guarded'), findsOneWidget);

    approval.complete(true);
    await tester.pumpAndSettle();

    expect(find.text('guarded'), findsNothing);
    await expectLater(routeResult, completion(isNull));
  });

  testWidgets('rapid back attempts run one callback', (tester) async {
    await pumpApp(tester);
    final approval = Completer<bool>();
    var attempts = 0;
    unawaited(
      pushGuardedRoute<void>(
        onPopAttempt: () {
          attempts++;
          return approval.future;
        },
      ),
    );
    await tester.pumpAndSettle();

    await Future.wait(<Future<void>>[
      simulateSystemBack(),
      simulateSystemBack(),
      simulateSystemBack(),
    ]);
    await tester.pump();

    expect(attempts, 1);

    approval.complete(false);
    await tester.pump();
    await simulateSystemBack();
    await tester.pump();

    expect(attempts, 2);
    expect(find.text('guarded'), findsOneWidget);
  });

  testWidgets('approved maybePop preserves its result', (tester) async {
    await pumpApp(tester);
    final routeResult = pushGuardedRoute<int>(onPopAttempt: () async => true);
    await tester.pumpAndSettle();

    await navigatorKey.currentState!.maybePop<int>(42);
    await tester.pumpAndSettle();

    await expectLater(routeResult, completion(42));
    expect(find.text('home'), findsOneWidget);
  });

  testWidgets('direct Navigator.pop bypasses approval', (tester) async {
    await pumpApp(tester);
    var attempts = 0;
    final routeResult = pushGuardedRoute<int>(
      onPopAttempt: () async {
        attempts++;
        return false;
      },
    );
    await tester.pumpAndSettle();

    navigatorKey.currentState!.pop<int>(7);
    await tester.pumpAndSettle();

    expect(attempts, 0);
    await expectLater(routeResult, completion(7));
  });

  testWidgets('callback navigation is not followed by another pop', (
    tester,
  ) async {
    await pumpApp(tester);
    unawaited(
      pushGuardedRoute<void>(
        onPopAttempt: () async {
          unawaited(
            navigatorKey.currentState!.push<void>(
              MaterialPageRoute<void>(
                builder: (_) => const Scaffold(body: Text('replacement')),
              ),
            ),
          );
          return true;
        },
      ),
    );
    await tester.pumpAndSettle();

    await simulateSystemBack();
    await tester.pumpAndSettle();

    expect(find.text('replacement'), findsOneWidget);
    navigatorKey.currentState!.pop();
    await tester.pumpAndSettle();
    expect(find.text('guarded'), findsOneWidget);
  });

  for (final approval in <bool>[false, true]) {
    testWidgets('matches legacy async pop when approval is $approval', (
      tester,
    ) async {
      final outcomes = <(bool, int)>[];

      for (final legacy in <bool>[true, false]) {
        await pumpApp(tester);
        var attempts = 0;
        unawaited(
          navigatorKey.currentState!.push<void>(
            MaterialPageRoute<void>(
              builder: (_) {
                Future<bool> onPopAttempt() async {
                  attempts++;
                  return approval;
                }

                const child = Scaffold(body: Text('compared'));
                if (legacy) {
                  // ignore: deprecated_member_use
                  return WillPopScope(onWillPop: onPopAttempt, child: child);
                }
                return AsyncPopScope<void>(
                  onPopAttempt: onPopAttempt,
                  child: child,
                );
              },
            ),
          ),
        );
        await tester.pumpAndSettle();

        await simulateSystemBack();
        await tester.pumpAndSettle();

        outcomes.add((find.text('compared').evaluate().isNotEmpty, attempts));
      }

      expect(outcomes[1], outcomes[0]);
    });
  }

  testWidgets('approval finishes before route completion', (tester) async {
    await pumpApp(tester);
    final events = <String>[];
    final routeResult = pushGuardedRoute<void>(
      onPopAttempt: () async {
        events.add('approval started');
        await Future<void>.delayed(Duration.zero);
        events.add('approval finished');
        return true;
      },
    );
    unawaited(routeResult.then((_) => events.add('route completed')));
    await tester.pumpAndSettle();

    await simulateSystemBack();
    await tester.pumpAndSettle();
    await routeResult;

    expect(events, <String>[
      'approval started',
      'approval finished',
      'route completed',
    ]);
  });

  group('first route', () {
    late List<String> platformCalls;

    setUp(() {
      platformCalls = <String>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (call) async {
            platformCalls.add(call.method);
            return null;
          });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null);
    });

    for (final legacy in <bool>[true, false]) {
      final label = legacy ? 'legacy' : 'async pop scope';

      for (final approval in <bool>[true, false]) {
        testWidgets('$label back with approval $approval', (tester) async {
          Future<bool> onPopAttempt() async => approval;
          const child = Scaffold(body: Text('root'));

          await tester.pumpWidget(
            MaterialApp(
              home: legacy
                  // ignore: deprecated_member_use
                  ? WillPopScope(onWillPop: onPopAttempt, child: child)
                  : AsyncPopScope<void>(
                      onPopAttempt: onPopAttempt,
                      child: child,
                    ),
            ),
          );
          await tester.pumpAndSettle();

          await simulateSystemBack();
          await tester.pumpAndSettle();

          expect(
            platformCalls.contains('SystemNavigator.pop'),
            approval,
            reason:
                'an approved back on the only route must reach the '
                'platform instead of emptying the navigator',
          );
          expect(find.text('root'), findsOneWidget);
        });
      }

      testWidgets('$label tap back again to exit', (tester) async {
        await tester.pumpWidget(MaterialApp(home: _ExitPrompt(legacy: legacy)));
        await tester.pumpAndSettle();

        unawaited(simulateSystemBack());
        await tester.pumpAndSettle();
        expect(find.text('tap back again to exit'), findsOneWidget);

        unawaited(simulateSystemBack());
        await tester.pumpAndSettle();

        expect(platformCalls, contains('SystemNavigator.pop'));
        expect(find.text('home'), findsOneWidget);
      });
    }

    testWidgets('a pushed route still pops without exiting', (tester) async {
      await pumpApp(tester);
      unawaited(pushGuardedRoute<void>(onPopAttempt: () async => true));
      await tester.pumpAndSettle();

      await simulateSystemBack();
      await tester.pumpAndSettle();

      expect(find.text('guarded'), findsNothing);
      expect(find.text('home'), findsOneWidget);
      expect(platformCalls, isNot(contains('SystemNavigator.pop')));
    });
  });
}

/// Mirrors `HomeView`'s double back to exit prompt, the first route flow the
/// migration has to preserve.
class _ExitPrompt extends StatefulWidget {
  const _ExitPrompt({required this.legacy});

  final bool legacy;

  @override
  State<_ExitPrompt> createState() => _ExitPromptState();
}

class _ExitPromptState extends State<_ExitPrompt> {
  bool _exitEnabled = false;
  DateTime? _cachedTime;

  Future<bool> _onWillPop() async {
    if (_exitEnabled) {
      return true;
    }

    final now = DateTime.now();
    const timeout = Duration(milliseconds: 1500);
    if (_cachedTime == null || now.difference(_cachedTime!) > timeout) {
      _cachedTime = now;
      var timedOut = false;
      await showDialog<dynamic>(
        context: context,
        barrierDismissible: false,
        builder: (_) {
          const dialog = Material(child: Text('tap back again to exit'));
          if (widget.legacy) {
            // ignore: deprecated_member_use
            return WillPopScope(
              onWillPop: () async {
                _exitEnabled = !timedOut;
                return true;
              },
              child: dialog,
            );
          }
          return PopScope(
            onPopInvokedWithResult: (didPop, result) {
              if (didPop && !timedOut) {
                _exitEnabled = true;
              }
            },
            child: dialog,
          );
        },
      ).timeout(
        timeout,
        onTimeout: () {
          timedOut = true;
          _exitEnabled = false;
          if (mounted) {
            Navigator.of(context).pop();
          }
        },
      );
    }

    return _exitEnabled;
  }

  @override
  Widget build(BuildContext context) {
    const child = Scaffold(body: Text('home'));
    if (widget.legacy) {
      // ignore: deprecated_member_use
      return WillPopScope(onWillPop: _onWillPop, child: child);
    }
    return AsyncPopScope<void>(onPopAttempt: _onWillPop, child: child);
  }
}

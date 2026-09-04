import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

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

  testWidgets(
    'dynamic canPop controls system back and reports the result',
    (tester) async {
      await pumpApp(tester);
      var canPop = false;
      late StateSetter setPageState;
      late BuildContext pageContext;
      final callbacks = <(bool, int?)>[];
      final result = navigatorKey.currentState!.push<int>(
        MaterialPageRoute<int>(
          builder: (_) => StatefulBuilder(
            builder: (context, setState) {
              setPageState = setState;
              pageContext = context;
              return PopScope<int>(
                canPop: canPop,
                onPopInvokedWithResult: (didPop, result) {
                  callbacks.add((didPop, result));
                },
                child: const Scaffold(body: Text('page')),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        ModalRoute.of(pageContext)!.popDisposition,
        RoutePopDisposition.doNotPop,
      );
      await simulateSystemBack();
      await tester.pumpAndSettle();

      expect(callbacks, <(bool, int?)>[(false, null)]);
      expect(find.text('page'), findsOneWidget);

      setPageState(() => canPop = true);
      await tester.pump();
      expect(
        ModalRoute.of(pageContext)!.popDisposition,
        RoutePopDisposition.pop,
      );

      await navigatorKey.currentState!.maybePop<int>(19);
      await tester.pumpAndSettle();

      expect(callbacks.last, (true, 19));
      await expectLater(result, completion(19));
    },
    variant: TargetPlatformVariant.all(),
  );

  testWidgets('direct pop reports didPop without replaying side effects', (
    tester,
  ) async {
    await pumpApp(tester);
    var successfulPopSideEffects = 0;
    final callbacks = <(bool, String?)>[];
    final result = navigatorKey.currentState!.push<String>(
      MaterialPageRoute<String>(
        builder: (_) => PopScope<String>(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) {
            callbacks.add((didPop, result));
            if (didPop) {
              successfulPopSideEffects++;
            }
          },
          child: const Scaffold(body: Text('page')),
        ),
      ),
    );
    await tester.pumpAndSettle();

    navigatorKey.currentState!.pop<String>('done');
    await tester.pumpAndSettle();

    expect(callbacks, <(bool, String?)>[(true, 'done')]);
    expect(successfulPopSideEffects, 1);
    await expectLater(result, completion('done'));
  });

  testWidgets('a blocking nested scope blocks the whole route', (tester) async {
    await pumpApp(tester);
    var innerCanPop = false;
    late StateSetter setPageState;
    final outerCallbacks = <bool>[];
    final innerCallbacks = <bool>[];
    unawaited(
      navigatorKey.currentState!.push<void>(
        MaterialPageRoute<void>(
          builder: (_) => StatefulBuilder(
            builder: (context, setState) {
              setPageState = setState;
              return PopScope<void>(
                canPop: true,
                onPopInvokedWithResult: (didPop, _) {
                  outerCallbacks.add(didPop);
                },
                child: PopScope<void>(
                  canPop: innerCanPop,
                  onPopInvokedWithResult: (didPop, _) {
                    innerCallbacks.add(didPop);
                  },
                  child: const Scaffold(body: Text('nested')),
                ),
              );
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await simulateSystemBack();
    await tester.pumpAndSettle();
    expect(find.text('nested'), findsOneWidget);
    expect(outerCallbacks, <bool>[false]);
    expect(innerCallbacks, <bool>[false]);

    setPageState(() => innerCanPop = true);
    await tester.pump();
    await simulateSystemBack();
    await tester.pumpAndSettle();
    expect(find.text('home'), findsOneWidget);
    expect(outerCallbacks.last, isTrue);
    expect(innerCallbacks.last, isTrue);
  });

  for (final popPrevious in <bool>[false, true]) {
    testWidgets('token-style back pops ${popPrevious ? 2 : 1} route(s)', (
      tester,
    ) async {
      await pumpApp(tester);
      unawaited(
        navigatorKey.currentState!.push<void>(
          MaterialPageRoute<void>(
            builder: (_) => const Scaffold(body: Text('previous')),
          ),
        ),
      );
      await tester.pumpAndSettle();
      unawaited(
        navigatorKey.currentState!.push<void>(
          MaterialPageRoute<void>(
            builder: (context) => PopScope<void>(
              canPop: false,
              onPopInvokedWithResult: (didPop, _) {
                if (didPop) {
                  return;
                }
                final navigator = Navigator.of(context);
                if (popPrevious) {
                  navigator.pop();
                }
                navigator.pop();
              },
              child: const Scaffold(body: Text('token')),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await simulateSystemBack();
      await tester.pumpAndSettle();

      expect(find.text('token'), findsNothing);
      expect(
        find.text('previous'),
        popPrevious ? findsNothing : findsOneWidget,
      );
      expect(find.text('home'), popPrevious ? findsOneWidget : findsNothing);
    });
  }

  testWidgets('recovery-style back stops at its named route', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigatorKey,
        initialRoute: '/',
        routes: <String, WidgetBuilder>{
          '/': (_) => const Scaffold(body: Text('home')),
          '/recovery': (_) => const Scaffold(body: Text('recovery')),
          '/middle': (_) => const Scaffold(body: Text('middle')),
          '/verify': (context) => PopScope<void>(
            canPop: false,
            onPopInvokedWithResult: (didPop, _) {
              if (!didPop) {
                Navigator.of(
                  context,
                ).popUntil(ModalRoute.withName('/recovery'));
              }
            },
            child: const Scaffold(body: Text('verify')),
          ),
        },
      ),
    );
    unawaited(navigatorKey.currentState!.pushNamed('/recovery'));
    unawaited(navigatorKey.currentState!.pushNamed('/middle'));
    unawaited(navigatorKey.currentState!.pushNamed('/verify'));
    await tester.pumpAndSettle();

    await simulateSystemBack();
    await tester.pumpAndSettle();

    expect(find.text('recovery'), findsOneWidget);
    expect(find.text('middle'), findsNothing);
    expect(find.text('verify'), findsNothing);
  });

  testWidgets(
    'Android predictive back cancel keeps the route and commit pops it',
    (tester) async {
      await pumpApp(tester);
      final callbacks = <bool>[];
      unawaited(
        navigatorKey.currentState!.push<void>(
          MaterialPageRoute<void>(
            builder: (_) => PopScope<void>(
              onPopInvokedWithResult: (didPop, _) {
                callbacks.add(didPop);
              },
              child: const Scaffold(body: Text('predictive')),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await startPredictiveBackGesture();
      await updatePredictiveBackGesture(0.5);
      await cancelPredictiveBackGesture();
      await tester.pumpAndSettle();

      expect(find.text('predictive'), findsOneWidget);
      expect(callbacks, isEmpty);

      await startPredictiveBackGesture();
      await updatePredictiveBackGesture(0.5);
      await commitPredictiveBackGesture();
      await tester.pumpAndSettle();

      expect(find.text('predictive'), findsNothing);
      expect(callbacks, <bool>[true]);
    },
    variant: const TargetPlatformVariant(<TargetPlatform>{
      TargetPlatform.android,
    }),
  );

  testWidgets(
    'blocked Android predictive gesture stays blocked',
    (tester) async {
      await pumpApp(tester);
      final callbacks = <bool>[];
      unawaited(
        navigatorKey.currentState!.push<void>(
          MaterialPageRoute<void>(
            builder: (_) => PopScope<void>(
              canPop: false,
              onPopInvokedWithResult: (didPop, _) {
                callbacks.add(didPop);
              },
              child: const Scaffold(body: Text('blocked')),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await startPredictiveBackGesture();
      await updatePredictiveBackGesture(0.5);
      await commitPredictiveBackGesture();
      await tester.pumpAndSettle();

      expect(find.text('blocked'), findsOneWidget);
      expect(callbacks, <bool>[false]);

      await simulateSystemBack();
      await tester.pumpAndSettle();
      expect(callbacks, <bool>[false, false]);
    },
    variant: const TargetPlatformVariant(<TargetPlatform>{
      TargetPlatform.android,
    }),
  );

  testWidgets(
    'iOS edge gesture is not detected when canPop is false',
    (tester) async {
      await pumpApp(tester);
      final callbacks = <bool>[];
      unawaited(
        navigatorKey.currentState!.push<void>(
          CupertinoPageRoute<void>(
            builder: (_) => PopScope<void>(
              canPop: false,
              onPopInvokedWithResult: (didPop, _) {
                callbacks.add(didPop);
              },
              child: const CupertinoPageScaffold(
                child: Center(child: Text('cupertino')),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.dragFrom(const Offset(5, 300), const Offset(500, 0));
      await tester.pumpAndSettle();

      expect(find.text('cupertino'), findsOneWidget);
      expect(callbacks, isEmpty);
    },
    variant: const TargetPlatformVariant(<TargetPlatform>{TargetPlatform.iOS}),
  );
}

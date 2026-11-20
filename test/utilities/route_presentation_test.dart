import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/utilities/route_presentation.dart';

void main() {
  testWidgets('route presentation completes when the route is dismissed', (
    tester,
  ) async {
    late BuildContext context;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (builderContext) {
            context = builderContext;
            return const SizedBox();
          },
        ),
      ),
    );

    final route = DialogRoute<void>(
      context: context,
      builder: (_) => const Text('Progress'),
    );
    final navigator = Navigator.of(context);
    unawaited(navigator.push(route));
    await tester.pump();

    final presented = waitForRoutePresentation(route);
    navigator.removeRoute(route);
    await tester.pumpAndSettle();

    await expectLater(presented.timeout(const Duration(seconds: 1)), completes);
  });

  testWidgets('current-aware dismissal waits below a newer lock route', (
    tester,
  ) async {
    late BuildContext context;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (builderContext) {
            context = builderContext;
            return const Text('Home');
          },
        ),
      ),
    );

    final navigator = Navigator.of(context);
    final progress = CurrentAwareDialogRoute<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Text('Cancelling'),
    );
    unawaited(navigator.push(progress));
    await tester.pumpAndSettle();
    unawaited(
      navigator.push(
        MaterialPageRoute<void>(builder: (_) => const Text('Locked')),
      ),
    );
    await tester.pumpAndSettle();

    var completed = false;
    final dismissal =
        dismissCurrentAwareDialogRoute(
          navigator: navigator,
          route: progress,
        ).then((value) {
          completed = true;
          return value;
        });
    await tester.pump();

    expect(completed, isFalse);
    expect(find.text('Locked'), findsOneWidget);

    navigator.pop();
    await tester.pumpAndSettle();

    expect(await dismissal, isTrue);
    expect(find.text('Cancelling'), findsNothing);
    expect(find.text('Home'), findsOneWidget);
  });
}

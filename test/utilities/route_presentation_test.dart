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
}

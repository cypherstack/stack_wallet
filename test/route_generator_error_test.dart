import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/pages/exchange_view/trade_details_view.dart';
import 'package:stackwallet/route_generator.dart';

class _PrivateArguments {
  @override
  String toString() => throw StateError('Route arguments were serialized');
}

void main() {
  const unknown = '/unknown/private-wallet-id';
  for (final (name, diagnostic, message) in [
    (
      TradeDetailsView.routeName,
      TradeDetailsView.routeName,
      'Couldn’t open trade details.',
    ),
    (unknown, '<unknown>', 'Couldn’t open this screen.'),
  ]) {
    testWidgets('safe navigation error for $diagnostic', (tester) async {
      final logs = <String>[];
      final navigator = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navigator,
          onGenerateRoute: RouteGenerator.generateRoute,
          home: const SizedBox(),
        ),
      );
      runZoned(
        () {
          navigator.currentState!.pushNamed(
            name,
            arguments: _PrivateArguments(),
          );
        },
        zoneSpecification: ZoneSpecification(
          print: (_, _, _, line) => logs.add(line),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Navigation error'), findsOneWidget);
      expect(find.text(message), findsOneWidget);
      expect(find.textContaining('private-wallet-id'), findsNothing);
      expect(find.textContaining('_PrivateArguments'), findsNothing);
      expect(
        logs.join('\n'),
        contains('$diagnostic (argument type: _PrivateArguments)'),
      );
      expect(logs.join('\n'), isNot(contains('private-wallet-id')));
    });
  }
}

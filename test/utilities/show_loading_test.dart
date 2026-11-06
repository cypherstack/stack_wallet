import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:stackwallet/models/isar/stack_theme.dart';
import 'package:stackwallet/themes/stack_colors.dart';
import 'package:stackwallet/themes/theme_service.dart';
import 'package:stackwallet/utilities/show_loading.dart';

import '../sample_data/theme_json.dart';

class _MockThemeService extends Mock implements ThemeService {}

void main() {
  late GlobalKey<NavigatorState> rootNavigatorKey;
  late GlobalKey<NavigatorState> nestedNavigatorKey;
  late BuildContext nestedContext;

  setUp(() {
    rootNavigatorKey = GlobalKey<NavigatorState>();
    nestedNavigatorKey = GlobalKey<NavigatorState>();
  });

  Future<void> pumpHarness(WidgetTester tester) {
    final stackTheme = StackTheme.fromJson(json: lightThemeJsonMap);
    final themeService = _MockThemeService();
    when(themeService.getTheme(themeId: "light")).thenAnswer((_) => stackTheme);

    return tester.pumpWidget(
      ProviderScope(
        overrides: [pThemeService.overrideWithValue(themeService)],
        child: MaterialApp(
          navigatorKey: rootNavigatorKey,
          theme: ThemeData(
            extensions: [StackColors.fromStackColorTheme(stackTheme)],
          ),
          home: Navigator(
            key: nestedNavigatorKey,
            onGenerateRoute: (_) => MaterialPageRoute<void>(
              builder: (context) {
                nestedContext = context;
                return const Scaffold(body: Text("nested page"));
              },
            ),
          ),
        ),
      ),
    );
  }

  Future<void> pushNestedPage(WidgetTester tester) async {
    unawaited(
      nestedNavigatorKey.currentState!.push(
        MaterialPageRoute<void>(
          builder: (context) {
            nestedContext = context;
            return const Scaffold(body: Text("second nested page"));
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  for (final rootNavigator in [false, true]) {
    testWidgets("shows on the root navigator and leaves nested routes alone "
        "(rootNavigator: $rootNavigator)", (tester) async {
      await pumpHarness(tester);
      await pushNestedPage(tester);
      final work = Completer<String>();

      final loading = showLoading(
        whileFuture: work.future,
        context: nestedContext,
        message: "Working",
        rootNavigator: rootNavigator,
      );
      await tester.pump();

      expect(find.text("Working"), findsOneWidget);
      expect(rootNavigatorKey.currentState!.canPop(), isTrue);

      work.complete("done");
      await tester.pumpAndSettle();

      expect(await loading, "done");
      expect(find.text("Working"), findsNothing);
      expect(find.text("second nested page"), findsOneWidget);
      expect(rootNavigatorKey.currentState!.canPop(), isFalse);
      expect(nestedNavigatorKey.currentState!.canPop(), isTrue);
    });
  }

  testWidgets("an already-completed operation keeps the caller route", (
    tester,
  ) async {
    await pumpHarness(tester);

    final loading = showLoading(
      whileFuture: Future.value("done"),
      context: nestedContext,
      message: "Finishing immediately",
    );
    await tester.pumpAndSettle();

    expect(await loading, "done");
    expect(find.text("nested page"), findsOneWidget);
    expect(rootNavigatorKey.currentState!.canPop(), isFalse);
    expect(nestedNavigatorKey.currentState!.canPop(), isFalse);
  });

  testWidgets("removes only its own route when another route is above it", (
    tester,
  ) async {
    await pumpHarness(tester);
    final work = Completer<String>();

    final loading = showLoading(
      whileFuture: work.future,
      context: nestedContext,
      message: "Working",
    );
    await tester.pump();

    unawaited(
      rootNavigatorKey.currentState!.push(
        MaterialPageRoute<void>(
          builder: (_) => const Scaffold(body: Text("newer route")),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text("newer route"), findsOneWidget);

    work.complete("done");
    await tester.pumpAndSettle();

    expect(await loading, "done");
    expect(find.text("newer route"), findsOneWidget);
    expect(find.text("Working"), findsNothing);

    rootNavigatorKey.currentState!.pop();
    await tester.pumpAndSettle();
    expect(find.text("nested page"), findsOneWidget);
    expect(rootNavigatorKey.currentState!.canPop(), isFalse);
  });

  testWidgets("reports exceptions after dismissing the overlay", (
    tester,
  ) async {
    await pumpHarness(tester);
    Exception? caught;

    final loading = showLoading<String>(
      whileFutureAlt: () async => throw Exception("boom"),
      context: nestedContext,
      message: "Failing",
      onException: (e) => caught = e,
    );
    await tester.pumpAndSettle();

    expect(await loading, isNull);
    expect(caught.toString(), "Exception: boom");
    expect(rootNavigatorKey.currentState!.canPop(), isFalse);
  });
}

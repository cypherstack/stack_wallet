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
              settings: const RouteSettings(name: "nested home"),
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

  testWidgets("uses and dismisses the nested navigator", (tester) async {
    await pumpHarness(tester);
    final work = Completer<String>();

    final loading = showLoading(
      whileFuture: work.future,
      context: nestedContext,
      message: "Working locally",
    );
    await tester.pump();

    expect(find.text("Working locally"), findsOneWidget);
    expect(rootNavigatorKey.currentState!.canPop(), isFalse);
    expect(nestedNavigatorKey.currentState!.canPop(), isTrue);

    work.complete("done");
    await tester.pumpAndSettle();

    expect(await loading, "done");
    expect(find.text("nested page"), findsOneWidget);
    expect(nestedNavigatorKey.currentState!.canPop(), isFalse);
  });

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

  testWidgets("uses and dismisses the root navigator", (tester) async {
    await pumpHarness(tester);
    final work = Completer<String>();

    final loading = showLoading(
      whileFuture: work.future,
      context: nestedContext,
      message: "Working globally",
      rootNavigator: true,
    );
    await tester.pump();

    expect(find.text("Working globally"), findsOneWidget);
    expect(rootNavigatorKey.currentState!.canPop(), isTrue);
    expect(nestedNavigatorKey.currentState!.canPop(), isFalse);

    work.complete("done");
    await tester.pumpAndSettle();

    expect(await loading, "done");
    expect(find.text("nested page"), findsOneWidget);
    expect(rootNavigatorKey.currentState!.canPop(), isFalse);
  });

  testWidgets("removes only its own route when another route is above it", (
    tester,
  ) async {
    await pumpHarness(tester);
    final work = Completer<String>();

    final loading = showLoading(
      whileFuture: work.future,
      context: nestedContext,
      message: "Working locally",
    );
    await tester.pump();

    unawaited(
      nestedNavigatorKey.currentState!.push(
        MaterialPageRoute<void>(
          builder: (_) => const Scaffold(body: Text("newer route")),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text("newer route"), findsOneWidget);

    work.complete("done");
    await tester.pumpAndSettle();

    expect(await loading, "done");
    expect(find.text("newer route"), findsOneWidget);
    expect(nestedNavigatorKey.currentState!.canPop(), isTrue);
  });
}

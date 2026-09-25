import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/models/isar/stack_theme.dart';
import 'package:stackwallet/pages/settings_views/global_settings_view/stack_backup_views/create_backup_view.dart';
import 'package:stackwallet/themes/stack_colors.dart';

import '../../sample_data/theme_json.dart';

void main() {
  late GlobalKey<NavigatorState> rootNavigatorKey;
  late GlobalKey<NavigatorState> nestedNavigatorKey;
  late BuildContext nestedContext;

  setUp(() {
    rootNavigatorKey = GlobalKey<NavigatorState>();
    nestedNavigatorKey = GlobalKey<NavigatorState>();
  });

  Future<void> pumpHarness(WidgetTester tester) => tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        navigatorKey: rootNavigatorKey,
        theme: ThemeData(
          extensions: [
            StackColors.fromStackColorTheme(
              StackTheme.fromJson(json: lightThemeJsonMap),
            ),
          ],
        ),
        home: Navigator(
          key: nestedNavigatorKey,
          onGenerateRoute: (_) => MaterialPageRoute<void>(
            builder: (context) {
              nestedContext = context;
              return const Scaffold(body: Text("create backup page"));
            },
          ),
        ),
      ),
    ),
  );

  testWidgets("desktop success dismisses only its dialog", (tester) async {
    await pumpHarness(tester);

    final dialog = showStackWalletBackupResult(
      context: nestedContext,
      savedPath: "/tmp/backup.swb",
      error: null,
      isDesktop: true,
    );
    await tester.pumpAndSettle();

    expect(find.text("/tmp/backup.swb"), findsOneWidget);
    expect(rootNavigatorKey.currentState!.canPop(), isTrue);
    expect(nestedNavigatorKey.currentState!.canPop(), isFalse);

    await tester.tap(find.text("Ok"));
    await tester.pumpAndSettle();
    await dialog;

    expect(find.text("create backup page"), findsOneWidget);
    expect(rootNavigatorKey.currentState!.canPop(), isFalse);
  });

  testWidgets("desktop failure dismisses only its dialog", (tester) async {
    await pumpHarness(tester);

    final dialog = showStackWalletBackupResult(
      context: nestedContext,
      savedPath: null,
      error: Exception("disk full"),
      isDesktop: true,
    );
    await tester.pumpAndSettle();

    expect(find.text("Backup creation failed"), findsOneWidget);
    expect(find.text("Exception: disk full"), findsOneWidget);
    expect(rootNavigatorKey.currentState!.canPop(), isTrue);

    await tester.tap(find.text("OK"));
    await tester.pumpAndSettle();
    await dialog;

    expect(find.text("create backup page"), findsOneWidget);
    expect(rootNavigatorKey.currentState!.canPop(), isFalse);
  });
}

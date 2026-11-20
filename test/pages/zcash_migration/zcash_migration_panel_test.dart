import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/models/isar/stack_theme.dart';
import 'package:stackwallet/pages/zcash_migration/zcash_migration_view.dart';
import 'package:stackwallet/themes/stack_colors.dart';
import 'package:stackwallet/wallets/wallet/intermediate/zcash_migration.dart';

import '../../sample_data/theme_json.dart';

void main() {
  testWidgets('shows the conservative Zcash migration action matrix', (
    tester,
  ) async {
    final theme = StackTheme.fromJson(json: lightThemeJsonMap);
    const overview = ZcashMigrationOverview(
      chainHeight: 42,
      transparentSpendableZatoshis: 100000,
      saplingSpendableZatoshis: 200000,
      orchardMigratableZatoshis: 300000,
      ironwoodSpendableZatoshis: 400000,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(extensions: [StackColors.fromStackColorTheme(theme)]),
        home: Scaffold(
          body: ZcashMigrationPanel(
            overview: overview,
            formatZatoshis: (value) => '$value zats',
            onRoutePressed: (_) {},
          ),
        ),
      ),
    );

    expect(find.text('Transparent → Ironwood'), findsOneWidget);
    expect(find.text('Sapling → Ironwood'), findsOneWidget);
    expect(find.text('Ironwood → Transparent'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Orchard migration is scheduled only'),
      300,
    );
    expect(find.text('Orchard migration is scheduled only'), findsOneWidget);
    expect(find.byKey(const Key('zcash_migrate_orchard')), findsNothing);
  });
}

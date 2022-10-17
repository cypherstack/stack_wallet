import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:stackwallet/pages_desktop_specific/home/my_stack_view/coin_wallets_table.dart';
import 'package:stackwallet/services/wallets.dart';
import 'package:stackwallet/utilities/theme/light_colors.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';
import 'package:stackwallet/widgets/table_view/table_view_cell.dart';
import 'package:stackwallet/widgets/table_view/table_view_row.dart';

import 'table_view_row_test.mocks.dart';

@GenerateMocks([Wallets])
void main() {
  testWidgets('Blah blah', (widgetTester) async {
    final mockWallets = MockWallets();

    // final walletIds = mock
    await widgetTester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          extensions: [
            StackColors.fromStackColorTheme(LightColors()),
          ],
        ),
        home: Material(
          child: TableViewRow(cells: [
            for (int j = 1; j <= 5; j++)
              TableViewCell(flex: 16, child: Text("Some Text ${j}"))
          ], expandingChild: CoinWalletsTable(walletIds: nu)),
        ),
      ),
    );

    expect(find.text("Some Text 1"), findsOneWidget);
    expect(find.byType(TableViewRow), findsWidgets);
    expect(find.byType(TableViewCell), findsWidgets);
  });
}

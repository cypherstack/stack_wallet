import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/models/isar/stack_theme.dart';
import 'package:stackwallet/themes/stack_colors.dart';
import 'package:stackwallet/widgets/table_view/table_view.dart';
import 'package:stackwallet/widgets/table_view/table_view_cell.dart';
import 'package:stackwallet/widgets/table_view/table_view_row.dart';

import '../../sample_data/theme_json.dart';

void main() {
  testWidgets("Test create table row widget ", (widgetTester) async {
    await widgetTester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          extensions: [
            StackColors.fromStackColorTheme(
              StackTheme.fromJson(
                json: lightThemeJsonMap,
              ),
            ),
          ],
        ),
        home: Material(
          child: TableView(
            rows: [
              for (int i = 0; i < 10; i++)
                TableViewRow(cells: [
                  for (int j = 1; j <= 5; j++)
                    const TableViewCell(flex: 16, child: Text("Some Text"))
                ], expandingChild: null)
            ],
          ),
        ),
      ),
    );

    expect(find.byType(TableView), findsOneWidget);
    expect(find.byType(TableViewRow), findsWidgets);
    expect(find.byType(TableViewCell), findsWidgets);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:epicmobile/utilities/theme/light_colors.dart';
import 'package:epicmobile/utilities/theme/stack_colors.dart';
import 'package:epicmobile/widgets/table_view/table_view.dart';
import 'package:epicmobile/widgets/table_view/table_view_cell.dart';
import 'package:epicmobile/widgets/table_view/table_view_row.dart';

void main() {
  testWidgets("Test create table row widget ", (widgetTester) async {
    await widgetTester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          extensions: [
            StackColors.fromStackColorTheme(LightColors()),
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

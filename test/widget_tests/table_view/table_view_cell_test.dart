import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/models/isar/stack_theme.dart';
import 'package:stackwallet/themes/stack_colors.dart';
import 'package:stackwallet/widgets/table_view/table_view_cell.dart';

import '../../sample_data/theme_json.dart';

void main() {
  testWidgets("Widget build correctly", (widgetTester) async {
    const tableViewCell = TableViewCell(flex: 16, child: Text("data"));
    await widgetTester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          extensions: [
            StackColors.fromStackColorTheme(
              StackTheme.fromJson(
                json: lightThemeJsonMap,
                applicationThemesDirectoryPath: "test",
              ),
            ),
          ],
        ),
        home: const Material(
          child: tableViewCell,
        ),
      ),
    );

    expect(find.text("data"), findsOneWidget);
    expect(find.byWidget(tableViewCell), findsOneWidget);
  });
}

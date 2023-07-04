import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/models/isar/stack_theme.dart';
import 'package:stackwallet/themes/stack_colors.dart';
import 'package:stackwallet/widgets/icon_widgets/addressbook_icon.dart';

import '../../sample_data/theme_json.dart';

void main() {
  testWidgets("test address book icon widget", (widgetTester) async {
    final key = UniqueKey();
    final addressBookIcon = AddressBookIcon(
      key: key,
    );

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
          child: addressBookIcon,
        ),
      ),
    );

    expect(find.byWidget(addressBookIcon), findsOneWidget);
    expect(find.byType(SvgPicture), findsOneWidget);
  });
}

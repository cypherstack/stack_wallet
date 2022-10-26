import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/utilities/theme/light_colors.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';
import 'package:stackwallet/widgets/icon_widgets/addressbook_icon.dart';

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
            StackColors.fromStackColorTheme(LightColors()),
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

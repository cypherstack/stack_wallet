import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/pages/address_book_view/subviews/add_address_book_entry_view.dart';
import 'package:stackwallet/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:stackwallet/widgets/custom_buttons/gradient_button.dart';
import 'package:stackwallet/widgets/custom_buttons/simple_button.dart';

class AddAddressBookEntryViewBot {
  final WidgetTester tester;

  const AddAddressBookEntryViewBot(this.tester);

  Future<void> ensureVisible() async {
    await tester.ensureVisible(find.byType(AddAddressBookEntryView));
  }

  Future<void> tapBack() async {
    await tester.tap(find.byType(AppBarIconButton));
    await tester.pumpAndSettle();
  }

  Future<void> enterAddress(String text) async {
    await tester.enterText(
        find.byKey(Key("addAddressBookEntryViewAddressField")), text);
    await tester.pumpAndSettle();
  }

  Future<void> enterName(String text) async {
    await tester.enterText(
        find.byKey(Key("addAddressBookEntryViewNameField")), text);
    await tester.pumpAndSettle();
  }

  Future<void> tapCancel() async {
    await tester.tap(find.byType(SimpleButton));
    await tester.pumpAndSettle();
  }

  Future<void> tapSave() async {
    await tester.tap(find.byType(GradientButton));
    await tester.pumpAndSettle();
  }
}

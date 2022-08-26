import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/pages/address_book_view/subviews/edit_address_book_entry_view.dart';
import 'package:stackwallet/widgets/custom_buttons/gradient_button.dart';
import 'package:stackwallet/widgets/custom_buttons/simple_button.dart';

class EditAddressBookEntryViewBot {
  final WidgetTester tester;

  const EditAddressBookEntryViewBot(this.tester);

  Future<void> ensureVisible() async {
    await tester.ensureVisible(find.byType(EditAddressBookEntryView));
  }

  Future<void> tapBack() async {
    await tester.tap(find.byKey(Key("editAddressBookEntryBackButtonKey")));
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

  Future<void> enterAddress(String text) async {
    await tester.enterText(
        find.byKey(Key("editAddressBookEntryAddressFieldKey")), text);
  }

  Future<void> enterName(String text) async {
    await tester.enterText(
        find.byKey(Key("editAddressBookEntryNameFieldKey")), text);
  }
}

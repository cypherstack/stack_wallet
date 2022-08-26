import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/pages/address_book_view/subviews/address_book_entry_details_view.dart';
import 'package:stackwallet/widgets/custom_buttons/gradient_button.dart';

class AddressBookEntryDetailsViewBot {
  final WidgetTester tester;

  const AddressBookEntryDetailsViewBot(this.tester);

  Future<void> ensureVisible() async {
    await tester.ensureVisible(find.byType(AddressBookEntryDetailsView));
  }

  Future<void> tapBack() async {
    await tester.tap(find.byKey(Key("addressBookDetailsBackButtonKey")));
    await tester.pumpAndSettle();
  }

  Future<void> tapMore() async {
    await tester.tap(find.byKey(Key("addressBookDetailsDeleteButtonKey")));
    await tester.pumpAndSettle();
  }

  Future<void> tapDelete() async {
    await tester
        .tap(find.byKey(Key("addressBookDetailsContextMenuDeleteButtonKey")));
    await tester.pumpAndSettle();
  }

  Future<void> tapConfirmDelete() async {
    await tester
        .tap(find.byKey(Key("deleteContactConfirmationDialogDeleteButtonKey")));
    await tester.pumpAndSettle();
  }

  Future<void> tapCancelDelete() async {
    await tester
        .tap(find.byKey(Key("deleteContactConfirmationDialogCancelButtonKey")));
    await tester.pumpAndSettle();
  }

  Future<void> tapCopyAddress() async {
    await tester
        .tap(find.byKey(Key("addressBookEntryDetailsCopyAddressButtonKey")));
    await tester.pumpAndSettle();
  }

  Future<void> tapEdit() async {
    await tester
        .tap(find.byKey(Key("addressBookEntryDetailsEditEntryButtonKey")));
    await tester.pumpAndSettle();
  }

  Future<void> tapSend() async {
    await tester.tap(find.byType(GradientButton));
    await tester.pumpAndSettle();
  }
}

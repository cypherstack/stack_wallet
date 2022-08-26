import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/pages/address_book_view/address_book_view.dart';

class AddressBookViewBot {
  final WidgetTester tester;

  const AddressBookViewBot(this.tester);

  Future<void> ensureVisible() async {
    await tester.ensureVisible(find.byType(AddressBookView));
  }

  Future<void> tapBack() async {
    await tester.tap(find.byKey(Key("addressBookBackButton")));
    await tester.pumpAndSettle();
  }

  Future<void> tapAdd() async {
    await tester.tap(find.byKey(Key("addressBookAddButton")));
    await tester.pumpAndSettle();
  }

  Future<void> enterQuery(String query) async {
    await tester.enterText(find.byType(TextField), query);
    await tester.pumpAndSettle();
  }
}

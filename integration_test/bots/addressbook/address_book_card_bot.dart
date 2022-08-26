import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/widgets/address_book_card.dart';

class AddressBookCardBot {
  final WidgetTester tester;

  const AddressBookCardBot(this.tester);

  Future<void> ensureVisible() async {
    await tester.ensureVisible(find.byType(AddressBookCard));
  }

  Future<void> toggleExpandCard() async {
    await tester.tap(find.byType(AddressBookCard));
    await tester.pumpAndSettle();
  }

  Future<void> tapDetails() async {
    await tester.tap(find.byWidgetPredicate(
        (widget) => widget is SubButton && widget.label == "DETAILS"));
    await tester.pumpAndSettle();
  }

  Future<void> tapCopy() async {
    await tester.tap(find.byWidgetPredicate(
        (widget) => widget is SubButton && widget.label == "COPY"));
    await tester.pumpAndSettle();
  }

  Future<void> tapSend() async {
    await tester.tap(find.byWidgetPredicate(
        (widget) => widget is SubButton && widget.label == "SEND FIRO"));
    await tester.pumpAndSettle();
  }
}

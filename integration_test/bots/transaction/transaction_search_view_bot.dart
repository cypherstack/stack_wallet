import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/pages/transaction_subviews/transaction_search_view.dart';
import 'package:stackwallet/widgets/custom_buttons/simple_button.dart';

class TransactionSearchViewBot {
  final WidgetTester tester;

  const TransactionSearchViewBot(this.tester);

  Future<void> ensureVisible() async {
    await tester.ensureVisible(find.byType(TransactionSearchView));
  }

  Future<void> tapX() async {
    await tester.tap(find.byKey(Key("cancelTransactionSearchAppBarButton")));
    await tester.pumpAndSettle();
  }

  Future<void> tapCancel() async {
    await tester.tap(find.byType(SimpleButton));
    await tester.pumpAndSettle();
  }
}

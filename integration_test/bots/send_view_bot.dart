import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/pages/wallet_view/send_view.dart';

class SendViewBot {
  final WidgetTester tester;

  const SendViewBot(this.tester);

  Future<void> ensureVisible() async {
    await tester.ensureVisible(find.byType(SendView));
  }
  //
  // Future<void> tapX() async {
  //   await tester.tap(find.byKey(Key("cancelTransactionSearchAppBarButton")));
  //   await tester.pumpAndSettle();
  // }
  //
  // Future<void> tapCancel() async {
  //   await tester.tap(find.byType(SimpleButton));
  //   await tester.pumpAndSettle();
  // }
}

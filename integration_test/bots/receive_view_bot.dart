import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/pages/wallet_view/receive_view.dart';

class ReceiveViewBot {
  final WidgetTester tester;

  const ReceiveViewBot(this.tester);

  Future<void> ensureVisible() async {
    await tester.ensureVisible(find.byType(ReceiveView));
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

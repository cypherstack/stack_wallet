import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/pages/main_view.dart';

class MainViewBot {
  final WidgetTester tester;

  const MainViewBot(this.tester);

  Future<void> ensureVisible() async {
    await tester.ensureVisible(find.byType(MainView));
  }

  Future<void> tapRefresh() async {
    await tester.tap(find.byKey(Key("mainViewRefreshButton")));
    await tester.pumpAndSettle();
  }

  Future<void> tapSettings() async {
    await tester.tap(find.byKey(Key("mainViewSettingsButton")));
    await tester.pumpAndSettle();
  }

  Future<void> tapSend() async {
    await tester.tap(find.byKey(Key("mainViewNavBarSendItemKey")));
    await tester.pumpAndSettle();
  }

  Future<void> tapWallet() async {
    await tester.tap(find.byKey(Key("mainViewNavBarWalletItemKey")));
    await tester.pumpAndSettle();
  }

  Future<void> tapReceive() async {
    await tester.tap(find.byKey(Key("mainViewNavBarReceiveItemKey")));
    await tester.pumpAndSettle();
  }
}

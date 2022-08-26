import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/pages/wallet_view/wallet_view.dart';
import 'package:stackwallet/widgets/custom_buttons/draggable_switch_button.dart';

class WalletViewBot {
  final WidgetTester tester;

  const WalletViewBot(this.tester);

  Future<void> ensureVisible() async {
    await tester.ensureVisible(find.byType(WalletView));
  }

  Future<void> tapAvailableFullSwitch() async {
    await tester.tap(find.byType(DraggableSwitchButton));
    await tester.pumpAndSettle();
  }

  Future<void> dragAvailableFullSwitchRight() async {
    await tester.fling(
        find.byKey(Key("draggableSwitchButtonSwitch")), Offset(200, 0), 500);
    await tester.pumpAndSettle();
  }

  Future<void> dragAvailableFullSwitchLeft() async {
    await tester.fling(
        find.byKey(Key("draggableSwitchButtonSwitch")), Offset(-200, 0), 500);
    await tester.pumpAndSettle();
  }

  Future<void> tapTransactionSearch() async {
    await tester.tap(find.byKey(Key("walletViewTransactionSearchButton")));
    await tester.pumpAndSettle();
  }

  Future<void> checkAvailableFullSwitchIsEnabled() async {
    final state = tester.state(find.byType(DraggableSwitchButton))
        as DraggableSwitchButtonState;
    expect(state.enabled, true);
  }

  Future<void> checkAvailableFullSwitchIsDisabled() async {
    final state = tester.state(find.byType(DraggableSwitchButton))
        as DraggableSwitchButtonState;
    expect(state.enabled, false);
  }
}

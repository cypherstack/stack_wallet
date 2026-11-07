import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/pages/wallets_view/sub_widgets/empty_wallets.dart';
import 'package:stackwallet/pages_desktop_specific/desktop_home_view.dart';
import 'package:stackwallet/pages_desktop_specific/my_stack_view/wallet_summary_table.dart';
import 'package:stackwallet/pages_desktop_specific/my_stack_view/wallet_view/desktop_wallet_view.dart';
import 'package:stackwallet/pages_desktop_specific/my_stack_view/wallet_view/sub_widgets/desktop_receive.dart';
import 'package:stackwallet/pages_desktop_specific/password/create_password_view.dart';
import 'package:stackwallet/pages_desktop_specific/password/desktop_login_view.dart';
import 'package:stackwallet/wallets/wallet/wallet.dart';
import 'package:stackwallet/widgets/slatepack_method_toggle.dart';
import 'package:stackwallet/widgets/toggle.dart';
import 'package:stackwallet/widgets/wallet_card.dart';

import 'platform_driver.dart';

const testPassword = 'wallet-creation-integration-only-4862!';

class DesktopDriver extends PlatformDriver {
  DesktopDriver(super.ui);

  @override
  Finder get home => find.byType(DesktopHomeView);
  @override
  Finder get walletScreen => find.byType(DesktopWalletView);
  @override
  String get verificationButton => 'Verify';

  @override
  Future<void> createCredentials() async {
    await ui.waitFor(find.byType(CreatePasswordView));
    await ui.enter(
      find.byKey(const Key('createBackupPasswordFieldKey1')),
      testPassword,
    );
    await ui.enter(
      find.byKey(const Key('createDesktopPasswordFieldKey2')),
      testPassword,
    );
    await ui.tapText('Next');
    await ui.waitFor(home);
  }

  @override
  Future<void> unlock() async {
    await ui.waitFor(find.byType(DesktopLoginView));
    await ui.enter(
      find.byKey(const Key('desktopLoginPasswordFieldKey')),
      testPassword,
    );
    await ui.tapText('Continue');
    await ui.waitFor(home);
  }

  @override
  Future<void> addWallet() async {
    await ui.waitFor(home);
    final empty = find.byType(AddWalletButton);
    if (empty.evaluate().isNotEmpty) {
      await ui.tap(empty);
    } else {
      await ui.tapText('Add new wallet');
    }
  }

  @override
  Future<void> openWallet(Wallet wallet) async {
    final row = find.byKey(
      Key('DesktopWalletSummaryRow_key_${wallet.cryptoCurrency.identifier}'),
    );
    await ui.revealListRow(row, find.byType(WalletSummaryTable));
    await ui.tap(row);
    if (wallet.cryptoCurrency.hasTokenSupport) {
      final card = find.byWidgetPredicate(
        (widget) =>
            widget is SimpleWalletCard &&
            widget.walletId == wallet.walletId &&
            widget.contractAddress == null,
      );
      await ui.tapText('Open wallet', within: card);
    }
    await ui.waitFor(walletScreen);
  }

  @override
  Future<void> verifyReceiveAddress(Wallet wallet, String address) async {
    await ui.tap(
      find.descendant(
        of: walletScreen,
        matching: find.byKey(const ValueKey('customTab_Receive')),
      ),
    );
    final receive = find.byType(DesktopReceive);
    await ui.waitFor(receive);
    final slatepackMode = find.descendant(
      of: receive,
      matching: find.byType(SlatepackMethodToggle),
    );
    if (slatepackMode.evaluate().isNotEmpty) {
      final toggle = ui.tester.widget<Toggle>(
        find.descendant(of: slatepackMode, matching: find.byType(Toggle)),
      );
      // MWC defaults to Slatepack, which does not display the MQS address.
      // Epic Cash defaults to epicbox, so this is a no-op there.
      if (!toggle.isOn) await ui.tap(slatepackMode);
    }
    await selectPrimaryAddress(wallet, receive);
    final displayed = find.descendant(
      of: receive,
      matching: find.text(address),
    );
    await ui.waitFor(displayed, description: 'receiving address in desktop UI');
    await ui.reveal(displayed);
  }

  @override
  Future<void> backToHome() async {
    await ui.tap(find.byKey(const Key('desktopWalletBackButton')));
    await ui.waitFor(home);
  }
}

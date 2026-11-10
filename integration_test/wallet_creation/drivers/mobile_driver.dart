import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/pages/home_view/home_view.dart';
import 'package:stackwallet/pages/pinpad_views/create_pin_view.dart';
import 'package:stackwallet/pages/pinpad_views/lock_screen_view.dart';
import 'package:stackwallet/pages/receive_view/receive_view.dart';
import 'package:stackwallet/pages/wallet_view/wallet_view.dart';
import 'package:stackwallet/pages/wallets_view/sub_widgets/all_wallets.dart';
import 'package:stackwallet/pages/wallets_view/sub_widgets/empty_wallets.dart';
import 'package:stackwallet/wallets/crypto_currency/crypto_currency.dart';
import 'package:stackwallet/wallets/wallet/wallet.dart';
import 'package:stackwallet/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:stackwallet/widgets/custom_pin_put/pin_keyboard.dart';
import 'package:stackwallet/widgets/master_wallet_card.dart';

import 'platform_driver.dart';

class MobileDriver extends PlatformDriver {
  MobileDriver(super.ui);

  @override
  Finder get home => find.byType(HomeView);
  @override
  Finder get walletScreen => find.byType(WalletView);
  @override
  String get verificationButton => 'Continue';

  Future<void> _enterPin() async {
    // Use the actual custom keypad. It may be randomized and there can be
    // offscreen keypads in the PIN PageView, so select only hit-testable keys.
    for (final digit in '486251'.split('')) {
      await ui.tap(
        find
            .byWidgetPredicate(
              (widget) => widget is NumberKey && widget.number == digit,
            )
            .hitTestable(),
      );
    }
    await ui.tap(find.byType(SubmitKey).hitTestable());
  }

  @override
  Future<void> createCredentials() async {
    await ui.waitFor(find.byType(CreatePinView));
    await ui.waitFor(find.text('Create a PIN').hitTestable());
    await _enterPin();
    await ui.waitFor(find.text('Confirm PIN').hitTestable());
    await ui.until(() {
      final pages = ui.tester.widget<PageView>(
        find.descendant(
          of: find.byType(CreatePinView),
          matching: find.byType(PageView),
        ),
      );
      final controller = pages.controller!;
      return controller.hasClients &&
          (controller.page! - 1).abs() < 0.001 &&
          !controller.position.isScrollingNotifier.value;
    }, 'confirmation PIN page to settle');
    await _enterPin();
    // IS_INTEGRATION_TEST uses the app's existing biometric opt-out; PIN
    // creation and the platform secure-storage plugin are still real.
    await ui.waitFor(home);
  }

  @override
  Future<void> unlock() async {
    await ui.waitFor(find.byType(LockscreenView));
    await _enterPin();
    await ui.waitFor(home);
  }

  @override
  Future<void> addWallet() async {
    await ui.waitFor(home);
    final empty = find.byType(AddWalletButton);
    if (empty.evaluate().isNotEmpty) {
      await ui.tap(empty);
    } else {
      await ui.tapText('Add new');
    }
  }

  @override
  Future<void> openWallet(Wallet wallet) async {
    final row = find.byKey(
      Key('walletListItemButtonKey_${wallet.cryptoCurrency.identifier}'),
    );
    await ui.revealListRow(row, find.byType(AllWallets));
    await ui.tap(row);
    // A single ETH wallet opens an overview even without tokens. A base SOL
    // wallet with no tokens opens directly (WalletListItem's production flow).
    if (wallet.cryptoCurrency is Ethereum) {
      // The mobile overview starts with its master card collapsed.
      final master = find.byWidgetPredicate(
        (widget) =>
            widget is MasterWalletCard && widget.walletId == wallet.walletId,
      );
      await ui.tap(
        find
            .descendant(of: master, matching: find.byType(MaterialButton))
            .hitTestable(),
      );
      await ui.tap(
        find.byKey(Key('walletsSheetItemButtonKey_${wallet.walletId}')),
      );
    }
    await ui.waitFor(walletScreen);
  }

  @override
  Future<void> verifyReceiveAddress(Wallet wallet, String address) async {
    await ui.tapText('Receive', within: walletScreen);
    final receive = find.byType(ReceiveView);
    await ui.waitFor(receive);
    await selectPrimaryAddress(wallet, receive);
    final displayed = find.descendant(
      of: receive,
      matching: find.text(address),
    );
    await ui.waitFor(displayed, description: 'receiving address in mobile UI');
    await ui.reveal(displayed);
    await ui.tap(
      find.descendant(of: receive, matching: find.byType(AppBarBackButton)),
    );
    await ui.waitFor(walletScreen);
  }

  @override
  Future<void> backToHome() async {
    await ui.tap(
      find.descendant(
        of: walletScreen,
        matching: find.byType(AppBarBackButton),
      ),
    );
    await ui.until(
      () => walletScreen.evaluate().isEmpty,
      'wallet screen to close',
    );
    if (home.evaluate().isEmpty) {
      await ui.tap(find.byType(AppBarBackButton).hitTestable());
    }
    await ui.waitFor(home);
  }
}

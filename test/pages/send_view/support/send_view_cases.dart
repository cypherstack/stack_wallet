import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/models/balance.dart';
import 'package:stackwallet/pages/send_view/frost_ms/recipient.dart';
import 'package:stackwallet/pages/send_view/send_view.dart';
import 'package:stackwallet/pages/send_view/sol_token_send_view.dart';
import 'package:stackwallet/pages/send_view/token_send_view.dart';
import 'package:stackwallet/pages_desktop_specific/my_stack_view/wallet_view/sub_widgets/desktop_send.dart';
import 'package:stackwallet/pages_desktop_specific/my_stack_view/wallet_view/sub_widgets/desktop_token_send.dart';
import 'package:stackwallet/wallets/wallet/wallet.dart';
import 'package:stackwallet/widgets/fee_slider.dart';

import 'fake_wallets.dart';
import 'send_view_harness.dart';

class SendViewCase {
  const SendViewCase({
    required this.name,
    required this.desktop,
    required this.view,
    required this.addressField,
    required this.cryptoAmountField,
    required this.defaultWallet,
    required this.feeEstimator,
    this.tokenOverrides,
  });

  final String name;
  final bool desktop;
  final Widget Function(Wallet wallet) view;
  final Key addressField;
  final Key cryptoAmountField;

  final List<Override> Function(Wallet wallet)? tokenOverrides;

  final Wallet Function() defaultWallet;

  final FakeWallet Function(Wallet wallet) feeEstimator;

  String get previewLabel => desktop ? "Preview send" : "Preview";

  Future<void> pump(
    WidgetTester tester, {
    Wallet? wallet,
    List<Override> overrides = const [],
    Balance? balance,
    HarnessPrefs? prefs,
    RouteFactory? onGenerateRoute,
  }) async {
    final w = wallet ?? defaultWallet();
    await pumpSendView(
      tester,
      wallet: w,
      desktop: desktop,
      view: view(w),
      balance: balance,
      prefs: prefs,
      onGenerateRoute: onGenerateRoute,
      overrides: [...?tokenOverrides?.call(w), ...overrides],
    );
  }

  Future<void> preview(WidgetTester tester) async {
    await tester.tap(find.text(previewLabel));
    // The views keep the building dialog up for at least 2.5 s.
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
  }

  Future<void> openFeeChoice(WidgetTester tester, String fee) async {
    await tester.tap(
      desktop
          ? find.text("Edit", findRichText: true)
          : find.textContaining(fee).last,
    );
    await tester.pumpAndSettle();
  }

  @override
  String toString() => name;
}

const _cryptoAmountField = Key("amountInputFieldCryptoTextFieldKey");

final mobileCoin = SendViewCase(
  name: "mobile",
  desktop: false,
  view: (wallet) =>
      SendView(walletId: wallet.walletId, coin: wallet.cryptoCurrency),
  addressField: const Key("sendViewAddressFieldKey"),
  cryptoAmountField: _cryptoAmountField,
  defaultWallet: FakeBitcoinWallet.new,
  feeEstimator: (wallet) => wallet as FakeWallet,
);

final desktopCoin = SendViewCase(
  name: "desktop",
  desktop: true,
  view: (wallet) => DesktopSend(walletId: wallet.walletId),
  addressField: const Key("sendViewAddressFieldKey"),
  cryptoAmountField: _cryptoAmountField,
  defaultWallet: FakeBitcoinWallet.new,
  feeEstimator: (wallet) => wallet as FakeWallet,
);

final coinCases = [mobileCoin, desktopCoin];

List<Override> _ethToken(Wallet wallet) =>
    ethTokenOverrides((wallet as FakeEthereumWallet).tokenWallet);

List<Override> _solToken(Wallet wallet) =>
    solTokenOverrides((wallet as FakeSolanaWallet).tokenWallet);

FakeWallet _ethTokenFees(Wallet wallet) =>
    (wallet as FakeEthereumWallet).tokenWallet;

// Solana token fees are the parent wallet's.
FakeWallet _solTokenFees(Wallet wallet) => wallet as FakeSolanaWallet;

final mobileEthToken = SendViewCase(
  name: "mobile Ethereum token",
  desktop: false,
  view: (wallet) => TokenSendView(
    walletId: wallet.walletId,
    coin: wallet.cryptoCurrency,
    tokenContract: testEthContract,
  ),
  addressField: const Key("tokenSendViewAddressFieldKey"),
  cryptoAmountField: _cryptoAmountField,
  tokenOverrides: _ethToken,
  defaultWallet: FakeEthereumWallet.new,
  feeEstimator: _ethTokenFees,
);

final desktopEthToken = SendViewCase(
  name: "desktop Ethereum token",
  desktop: true,
  view: (wallet) => DesktopTokenSend(walletId: wallet.walletId),
  addressField: const Key("sendViewAddressFieldKey"),
  cryptoAmountField: _cryptoAmountField,
  tokenOverrides: _ethToken,
  defaultWallet: FakeEthereumWallet.new,
  feeEstimator: _ethTokenFees,
);

final mobileSolToken = SendViewCase(
  name: "mobile Solana token",
  desktop: false,
  view: (wallet) => SolTokenSendView(
    walletId: wallet.walletId,
    tokenMint: testSolContract.address,
  ),
  addressField: const Key("solTokenSendViewAddressFieldKey"),
  cryptoAmountField: const Key("solAmountInputFieldCryptoTextFieldKey"),
  tokenOverrides: _solToken,
  defaultWallet: FakeSolanaWallet.new,
  feeEstimator: _solTokenFees,
);

/// Recipient forms reuse the view's keys.
Finder _inView(Key key) => find.byElementPredicate(
  (element) =>
      element.widget.key == key &&
      element.findAncestorWidgetOfExactType<Recipient>() == null,
);

Future<void> enterField(WidgetTester tester, Key key, String text) async {
  await tester.enterText(_inView(key), text);
  await tester.pumpAndSettle();
}

Future<void> sendFrom(WidgetTester tester, String balance) async {
  await tester.tap(
    find.textContaining(RegExp(r"^(Public|Private) balance$")).last,
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text(balance).last);
  await tester.pumpAndSettle();
}

Future<void> pick(WidgetTester tester, String feeRate) async {
  await tester.tap(find.textContaining(feeRate).last);
  await tester.pumpAndSettle();
}

int sliderRate(WidgetTester tester) => int.parse(
  tester
      .widget<Text>(
        find.descendant(
          of: find.byType(FeeSlider),
          matching: find.textContaining(RegExp(r"^[0-9]+$")),
        ),
      )
      .data!,
);

Future<int> setCustomRate(WidgetTester tester) async {
  await tester.tap(find.text("Custom").last);
  await tester.pumpAndSettle();
  await tester.drag(find.byType(Slider), const Offset(2000, 0));
  await tester.pumpAndSettle();
  return sliderRate(tester);
}

import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/wallets/crypto_currency/crypto_currency.dart';
import 'package:stackwallet/wallets/wallet/wallet.dart';

import '../ui.dart';

abstract class PlatformDriver {
  PlatformDriver(this.ui);

  final TestUI ui;
  Finder get home;
  Finder get walletScreen;
  String get verificationButton;
  Future<void> createCredentials();
  Future<void> unlock();
  Future<void> addWallet();
  Future<void> openWallet(Wallet wallet);
  Future<void> verifyReceiveAddress(Wallet wallet, String address);
  Future<void> backToHome();

  Future<void> selectPrimaryAddress(Wallet wallet, Finder receive) async {
    final selector = find.descendant(
      of: receive,
      matching: find.byType(DropdownButton2<int>),
    );
    if (selector.evaluate().isEmpty) return;
    // Firo initially shows Spark. Select the address type checked by the wallet
    // API; the same rule covers Litecoin if MWEB is enabled by default later.
    final label = wallet.cryptoCurrency is Firo
        ? 'Transparent address'
        : '${wallet.info.mainAddressType.readableName} address';
    final dropdown = ui.tester.widget<DropdownButton2<int>>(selector);
    final item = dropdown.items!.singleWhere(
      (item) => item.child is Text && (item.child as Text).data == label,
    );
    if (dropdown.value == item.value) return;
    await ui.tap(selector);
    await ui.tap(find.text(label).hitTestable());
  }
}

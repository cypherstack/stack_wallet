import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/utilities/stack_file_system.dart';
import 'package:stackwallet/wallets/crypto_currency/crypto_currency.dart';
import 'package:stackwallet/wallets/wallet/wallet.dart';
import 'package:stackwallet/widgets/custom_buttons/blue_text_button.dart';

import '../../support/isar_test_utils.dart';
import 'support/fake_wallets.dart';
import 'support/send_view_cases.dart';
import 'support/send_view_harness.dart';

class _FakeZcashWallet extends FakeWallet<Zcash> implements Wallet<Zcash> {
  _FakeZcashWallet() : super(Zcash(CryptoCurrencyNetwork.main), testFees);
}

void main() {
  setUpAll(() async {
    final dir = await Directory.systemTemp.createTemp('zcash_send_capability_');
    StackFileSystem.setDesktopOverrideDir(dir.path);
    addTearDown(() => dir.delete(recursive: true));
    await initializeTestIsar();
    await loadButtonFont();
  });

  for (final view in coinCases) {
    testWithoutAnimation(
      'does not offer unsupported Zcash multi-recipient send ($view)',
      (tester) async {
        await view.pump(tester, wallet: _FakeZcashWallet());

        expect(
          find.byWidgetPredicate(
            (widget) =>
                widget is CustomTextButton && widget.text == 'Add recipient',
          ),
          findsNothing,
        );
      },
    );
  }
}

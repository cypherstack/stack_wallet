import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/pages_desktop_specific/my_stack_view/wallet_view/sub_widgets/desktop_send_fee_form.dart';
import 'package:stackwallet/providers/wallet/public_private_balance_state_provider.dart';
import 'package:stackwallet/utilities/amount/amount.dart';
import 'package:stackwallet/utilities/enums/fee_rate_type_enum.dart';
import 'package:stackwallet/widgets/fee_slider.dart';

import '../../pages/send_view/support/fake_wallets.dart';
import '../../pages/send_view/support/send_view_cases.dart';
import '../../pages/send_view/support/send_view_harness.dart';

Amount _amount(String amount) =>
    Amount.tryParseCanonicalAmount(amount, fractionDigits: 8)!;

Future<void> _pickCustomFee(WidgetTester tester) async {
  await desktopCoin.openFeeChoice(tester, "");
  await pick(tester, FeeRateType.custom.prettyName);
}

void main() {
  setUpAll(loadButtonFont);

  Future<StateController<BalanceType>> pumpPublicFiroForm(
    WidgetTester tester,
  ) async {
    final wallet = FakeFiroWallet();
    await pumpSendView(
      tester,
      wallet: wallet,
      desktop: true,
      view: DesktopSendFeeForm(
        walletId: wallet.walletId,
        isToken: false,
        amount: SendFeeAmount()..sync(_amount("1")),
        onCustomFeeSliderChanged: (_) {},
      ),
    );
    final balance = ProviderScope.containerOf(
      tester.element(find.byType(DesktopSendFeeForm)),
    ).read(publicPrivateBalanceStateProvider.state);
    balance.state = BalanceType.public;
    await tester.pumpAndSettle();
    return balance;
  }

  group("the fee shown", () {
    testWithoutAnimation("is the estimated Spark fee after Custom (Firo)", (
      tester,
    ) async {
      final balance = await pumpPublicFiroForm(tester);
      await _pickCustomFee(tester);

      balance.state = BalanceType.private;
      await tester.pumpAndSettle();

      expect(find.text("Transaction fee (estimated)"), findsOneWidget);
      expect(find.textContaining("0.00002000"), findsOneWidget);
      expect(find.byType(FeeSlider), findsNothing);
    });
  });

  group("the fee sent", () {
    testWithoutAnimation(
      "starts at the Average level in a form opened over another",
      (tester) async {
        final wallet = FakeBitcoinWallet();
        final form = DesktopSendFeeForm(
          walletId: wallet.walletId,
          isToken: false,
          amount: SendFeeAmount(),
          onCustomFeeSliderChanged: (_) {},
        );
        var forms = [form];
        late StateSetter rebuild;
        await pumpSendView(
          tester,
          wallet: wallet,
          desktop: true,
          view: StatefulBuilder(
            builder: (_, setState) {
              rebuild = setState;
              return Column(children: forms);
            },
          ),
        );
        await _pickCustomFee(tester);

        rebuild(() => forms = [form, form]);
        await tester.pumpAndSettle();

        expect(find.text("Average (~0.00002000 BTC)"), findsNWidgets(2));
      },
    );
  });
}

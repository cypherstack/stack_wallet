import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/themes/stack_colors.dart';
import 'package:stackwallet/widgets/custom_buttons/blue_text_button.dart';

import '../../pages/send_view/support/fake_wallets.dart';
import '../../pages/send_view/support/send_view_harness.dart';

void main() {
  testWithoutAnimation("a button takes the disabled color once disabled", (
    tester,
  ) async {
    var enabled = true;
    late StateSetter rebuild;
    await pumpSendView(
      tester,
      wallet: FakeBitcoinWallet(),
      desktop: true,
      view: StatefulBuilder(
        builder: (_, setState) {
          rebuild = setState;
          return CustomTextButton(text: "Edit", enabled: enabled);
        },
      ),
    );

    rebuild(() => enabled = false);
    await tester.pump();

    expect(
      tester.widget<RichText>(find.byType(RichText)).text.style!.color,
      Theme.of(tester.element(find.byType(CustomTextButton)))
          .extension<StackColors>()!
          .customTextButtonDisabledText,
    );
  });

  testWithoutAnimation("a button takes the color of a new theme", (
    tester,
  ) async {
    var color = const Color(0xFF112233);
    late StateSetter rebuild;
    await pumpSendView(
      tester,
      wallet: FakeBitcoinWallet(),
      desktop: true,
      view: StatefulBuilder(
        builder: (context, setState) {
          rebuild = setState;
          final theme = Theme.of(context);
          return Theme(
            data: theme.copyWith(
              extensions: [
                theme.extension<StackColors>()!.copyWith(
                  customTextButtonEnabledText: color,
                ),
              ],
            ),
            child: const CustomTextButton(text: "Edit"),
          );
        },
      ),
    );

    rebuild(() => color = const Color(0xFF445566));
    await tester.pump();

    expect(
      tester.widget<RichText>(find.byType(RichText)).text.style!.color,
      const Color(0xFF445566),
    );
  });
}

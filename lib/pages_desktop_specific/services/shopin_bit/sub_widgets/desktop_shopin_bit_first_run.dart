import 'package:flutter/material.dart';

import '../../../../pages/shopinbit/shopinbit_step_2.dart';
import '../../../../utilities/text_styles.dart';
import '../../../../widgets/desktop/primary_button.dart';
import '../../../../widgets/dialogs/s_dialog.dart';

class DesktopShopinBitFirstRun extends StatelessWidget {
  const DesktopShopinBitFirstRun({super.key});

  static const routeName = "/desktopShopinBitFirstRun";

  @override
  Widget build(BuildContext context) {
    return SDialog(
      child: SizedBox(
        width: 500,
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("ShopinBit", style: STextStyles.desktopH2(context)),
              const SizedBox(height: 24),
              RichText(
                text: TextSpan(
                  style: STextStyles.desktopTextSmall(context),
                  children: const [
                    TextSpan(
                      text:
                          "Please note the following before proceeding:"
                          "\n\n  \u2022 Minimum order amount: 1,000 EUR"
                          "\n  \u2022 Service fee: 10% of the order total",
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 48),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Spacer(),
                  Expanded(
                    child: PrimaryButton(
                      buttonHeight: ButtonHeight.l,
                      label: "Continue",
                      onPressed: () => Navigator.of(
                        context,
                      ).pushReplacementNamed(ShopInBitStep2.routeName),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

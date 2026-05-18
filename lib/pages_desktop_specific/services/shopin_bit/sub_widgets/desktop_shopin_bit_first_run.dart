import 'package:flutter/material.dart';

import '../../../../models/shopinbit/shopinbit_order_model.dart';
import '../../../../pages/shopinbit/shopinbit_step_1.dart';
import '../../../../utilities/text_styles.dart';
import '../../../../widgets/desktop/primary_button.dart';
import '../../../../widgets/desktop/secondary_button.dart';
import '../../../../widgets/dialogs/s_dialog.dart';

class DesktopShopinBitFirstRun extends StatelessWidget {
  const DesktopShopinBitFirstRun({super.key, required this.model});

  static const routeName = "/desktopShopinBitFirstRun";

  final ShopInBitOrderModel model;

  @override
  Widget build(BuildContext context) {
    return SDialog(
      child: SizedBox(
        width: 580,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("ShopinBit", style: STextStyles.desktopH2(context)),
            const SizedBox(height: 16),
            RichText(
              text: TextSpan(
                style: STextStyles.desktopTextSmall(context),
                children: const [
                  TextSpan(
                    text:
                        "Please note the following before proceeding:"
                        "\n\n\u2022 Minimum order amount: 1,000 EUR"
                        "\n\u2022 Service fee: 10% of the order total",
                  ),
                ],
              ),
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SecondaryButton(
                  width: 220,
                  buttonHeight: ButtonHeight.l,
                  label: "Cancel",
                  onPressed: Navigator.of(context).pop,
                ),
                PrimaryButton(
                  width: 220,
                  buttonHeight: ButtonHeight.l,
                  label: "Continue",
                  onPressed: () => Navigator.of(
                    context,
                  ).pushNamed(ShopInBitStep1.routeName, arguments: model),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

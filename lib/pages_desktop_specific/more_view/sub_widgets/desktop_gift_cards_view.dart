import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import '../../../pages/cakepay/cakepay_orders_view.dart';
import '../../../pages/cakepay/cakepay_vendors_view.dart';
import '../../../utilities/assets.dart';
import '../../../utilities/text_styles.dart';
import '../../../widgets/desktop/primary_button.dart';
import '../../../widgets/desktop/secondary_button.dart';
import '../../../widgets/rounded_white_container.dart';

class DesktopGiftCardsView extends StatelessWidget {
  const DesktopGiftCardsView({super.key});

  static const String routeName = "/desktopGiftCardsView";

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 30),
          child: RoundedWhiteContainer(
            radiusMultiplier: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: SvgPicture.asset(
                    Assets.svg.creditCard,
                    width: 48,
                    height: 48,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: RichText(
                    textAlign: TextAlign.start,
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: "CakePay",
                          style: STextStyles.desktopTextSmall(context),
                        ),
                        TextSpan(
                          text: "\n\nPurchase gift cards with cryptocurrency.",
                          style: STextStyles.desktopTextExtraExtraSmall(
                            context,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: PrimaryButton(
                          buttonHeight: ButtonHeight.m,
                          label: "Browse Gift Cards",
                          onPressed: () {
                            showDialog<void>(
                              context: context,
                              builder: (_) => const CakePayVendorsView(),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: SecondaryButton(
                          buttonHeight: ButtonHeight.m,
                          label: "My Orders",
                          onPressed: () {
                            showDialog<void>(
                              context: context,
                              builder: (_) => const CakePayOrdersView(),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

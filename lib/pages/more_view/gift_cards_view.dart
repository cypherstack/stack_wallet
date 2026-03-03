import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import '../../themes/stack_colors.dart';
import '../../utilities/assets.dart';
import '../../utilities/text_styles.dart';
import '../../widgets/background.dart';
import '../../widgets/custom_buttons/app_bar_icon_button.dart';
import '../../widgets/desktop/primary_button.dart';
import '../../widgets/desktop/secondary_button.dart';
import '../../widgets/rounded_white_container.dart';
import '../cakepay/cakepay_orders_view.dart';
import '../cakepay/cakepay_vendors_view.dart';

class GiftCardsView extends StatelessWidget {
  const GiftCardsView({super.key});

  static const String routeName = "/giftCardsView";

  @override
  Widget build(BuildContext context) {
    return Background(
      child: Scaffold(
        backgroundColor: Theme.of(context).extension<StackColors>()!.background,
        appBar: AppBar(
          leading: AppBarBackButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          title: Text("Gift cards", style: STextStyles.navBarTitle(context)),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                RoundedWhiteContainer(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          SvgPicture.asset(
                            Assets.svg.creditCard,
                            width: 32,
                            height: 32,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  "CakePay",
                                  style: STextStyles.titleBold12(context),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  "Purchase gift cards with cryptocurrency",
                                  style: STextStyles.itemSubtitle12(context)
                                      .copyWith(
                                        color: Theme.of(context)
                                            .extension<StackColors>()!
                                            .textSubtitle1,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: PrimaryButton(
                              label: "Browse",
                              onPressed: () {
                                Navigator.of(
                                  context,
                                ).pushNamed(CakePayVendorsView.routeName);
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: SecondaryButton(
                              label: "My Orders",
                              onPressed: () {
                                Navigator.of(
                                  context,
                                ).pushNamed(CakePayOrdersView.routeName);
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

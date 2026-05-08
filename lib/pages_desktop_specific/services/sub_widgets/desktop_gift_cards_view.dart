import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';

import '../../../app_config.dart';
import '../../../pages/cakepay/cakepay_orders_view.dart';
import '../../../pages/cakepay/cakepay_vendors_view.dart';
import '../../../services/event_bus/events/global/tor_connection_status_changed_event.dart';
import '../../../services/tor_service.dart';
import '../../../themes/stack_colors.dart';
import '../../../utilities/assets.dart';
import '../../../utilities/text_styles.dart';
import '../../../widgets/desktop/primary_button.dart';
import '../../../widgets/desktop/secondary_button.dart';
import '../../../widgets/rounded_white_container.dart';
import '../../../widgets/tor_subscription.dart';

class DesktopGiftCardsView extends ConsumerStatefulWidget {
  const DesktopGiftCardsView({super.key});

  static const String routeName = "/desktopGiftCardsView";

  @override
  ConsumerState<DesktopGiftCardsView> createState() =>
      _DesktopGiftCardsViewState();
}

class _DesktopGiftCardsViewState extends ConsumerState<DesktopGiftCardsView> {
  late bool _torEnabled;

  @override
  void initState() {
    _torEnabled = AppConfig.hasFeature(AppFeature.tor)
        ? ref.read(pTorService).status != TorConnectionStatus.disconnected
        : false;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return TorSubscription(
      onTorStatusChanged: (status) {
        setState(() {
          _torEnabled = status != TorConnectionStatus.disconnected;
        });
      },
      child: Column(
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
                      colorFilter: ColorFilter.mode(
                        Theme.of(context).extension<StackColors>()!.textDark,
                        BlendMode.srcIn,
                      ),
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
                            text:
                                "\n\nPurchase gift cards with cryptocurrency.",
                            style: STextStyles.desktopTextExtraExtraSmall(
                              context,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_torEnabled)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text(
                        "CakePay is not available while Tor is enabled",
                        style: STextStyles.desktopTextExtraExtraSmall(context)
                            .copyWith(
                              color: Theme.of(
                                context,
                              ).extension<StackColors>()!.textSubtitle1,
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
                            enabled: !_torEnabled,
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
      ),
    );
  }
}

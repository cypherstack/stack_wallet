import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app_config.dart';
import '../../services/event_bus/events/global/tor_connection_status_changed_event.dart';
import '../../services/tor_service.dart';
import '../../themes/stack_colors.dart';
import '../../utilities/text_styles.dart';
import '../../widgets/background.dart';
import '../../widgets/custom_buttons/app_bar_icon_button.dart';
import '../../widgets/desktop/primary_button.dart';
import '../../widgets/desktop/secondary_button.dart';
import '../../widgets/icon_widgets/credit_card_icon.dart';
import '../../widgets/rounded_white_container.dart';
import '../../widgets/tor_subscription.dart';
import '../cakepay/cakepay_orders_view.dart';
import '../cakepay/cakepay_vendors_view.dart';

class GiftCardsView extends ConsumerStatefulWidget {
  const GiftCardsView({super.key});

  static const String routeName = "/giftCardsView";

  @override
  ConsumerState<GiftCardsView> createState() => _GiftCardsViewState();
}

class _GiftCardsViewState extends ConsumerState<GiftCardsView> {
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
      child: Background(
        child: Scaffold(
          backgroundColor: Theme.of(
            context,
          ).extension<StackColors>()!.background,
          appBar: AppBar(
            leading: const AppBarBackButton(),
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
                            const CreditCardIcon(width: 32, height: 32),
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
                        if (_torEnabled)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Text(
                              "CakePay is not available while Tor is enabled",
                              style: STextStyles.itemSubtitle12(context)
                                  .copyWith(
                                    color: Theme.of(
                                      context,
                                    ).extension<StackColors>()!.textSubtitle1,
                                  ),
                            ),
                          ),
                        Row(
                          children: [
                            Expanded(
                              child: SecondaryButton(
                                label: "My Orders",
                                enabled: !_torEnabled,
                                onPressed: () {
                                  Navigator.of(
                                    context,
                                  ).pushNamed(CakePayOrdersView.routeName);
                                },
                              ),
                            ),

                            const SizedBox(width: 16),
                            Expanded(
                              child: PrimaryButton(
                                label: "Browse",
                                enabled: !_torEnabled,
                                onPressed: () {
                                  Navigator.of(
                                    context,
                                  ).pushNamed(CakePayVendorsView.routeName);
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
      ),
    );
  }
}

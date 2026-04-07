import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../db/isar/main_db.dart';
import '../../models/shopinbit/shopinbit_order_model.dart';
import '../../themes/stack_colors.dart';
import '../../utilities/assets.dart';
import '../../utilities/text_styles.dart';
import '../../widgets/background.dart';
import '../../widgets/custom_buttons/app_bar_icon_button.dart';
import '../../widgets/desktop/primary_button.dart';
import '../../widgets/desktop/secondary_button.dart';
import '../../widgets/rounded_white_container.dart';
import '../../widgets/stack_dialog.dart';
import '../shopinbit/shopinbit_settings_view.dart';
import '../shopinbit/shopinbit_step_1.dart';
import '../shopinbit/shopinbit_tickets_view.dart';

class ServicesView extends StatefulWidget {
  const ServicesView({super.key});

  static const String routeName = "/servicesView";

  @override
  State<ServicesView> createState() => _ServicesViewState();
}

class _ServicesViewState extends State<ServicesView> {
  Future<bool> _showOpenBrowserWarning(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    final shouldContinue = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => StackDialog(
        title: "Attention",
        message:
            "You are about to open "
            "${uri.scheme}://${uri.host} "
            "in your browser.",
        leftButton: TextButton(
          onPressed: () {
            Navigator.of(context).pop(false);
          },
          child: Text(
            "Cancel",
            style: STextStyles.button(context).copyWith(
              color: Theme.of(
                context,
              ).extension<StackColors>()!.accentColorDark,
            ),
          ),
        ),
        rightButton: TextButton(
          style: Theme.of(
            context,
          ).extension<StackColors>()!.getPrimaryEnabledButtonStyle(context),
          onPressed: () {
            Navigator.of(context).pop(true);
          },
          child: Text("Continue", style: STextStyles.button(context)),
        ),
      ),
    );
    return shouldContinue ?? false;
  }

  void _showShopDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => StackDialogBase(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("ShopInBit", style: STextStyles.pageTitleH2(dialogContext)),
            const SizedBox(height: 8),
            RichText(
              text: TextSpan(
                style: STextStyles.smallMed14(dialogContext),
                children: [
                  const TextSpan(
                    text:
                        "Please note the following before proceeding:"
                        "\n\n\u2022 Minimum order amount: 1,000 EUR"
                        "\n\u2022 Service fee: 10% of the order total"
                        "\n\nBy continuing, you agree to the ShopInBit ",
                  ),
                  TextSpan(
                    text: "Privacy Policy",
                    style: STextStyles.richLink(
                      dialogContext,
                    ).copyWith(fontSize: 16),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () async {
                        const url =
                            "https://api.shopinbit.com/static/policy/privacy.html";
                        final shouldOpen = await _showOpenBrowserWarning(
                          dialogContext,
                          url,
                        );
                        if (shouldOpen) {
                          await launchUrl(
                            Uri.parse(url),
                            mode: LaunchMode.externalApplication,
                          );
                        }
                      },
                  ),
                  const TextSpan(text: "."),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () {
                      Navigator.of(dialogContext).pop();
                    },
                    child: Text(
                      "Cancel",
                      style: STextStyles.button(dialogContext).copyWith(
                        color: Theme.of(
                          dialogContext,
                        ).extension<StackColors>()!.accentColorDark,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextButton(
                    style: Theme.of(dialogContext)
                        .extension<StackColors>()!
                        .getPrimaryEnabledButtonStyle(dialogContext),
                    onPressed: () async {
                      Navigator.of(dialogContext).pop();
                      await Navigator.of(context).pushNamed(
                        ShopInBitStep1.routeName,
                        arguments: ShopInBitOrderModel(),
                      );
                      if (mounted) setState(() {});
                    },
                    child: Text(
                      "Continue",
                      style: STextStyles.button(dialogContext),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

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
          title: Text("Services", style: STextStyles.navBarTitle(context)),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: RoundedWhiteContainer(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        SvgPicture.asset(
                          Assets.svg.circleSliders,
                          width: 32,
                          height: 32,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            "ShopInBit",
                            style: STextStyles.titleBold12(context),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.of(
                              context,
                            ).pushNamed(ShopInBitSettingsView.routeName);
                          },
                          child: SvgPicture.asset(
                            Assets.svg.gear,
                            width: 20,
                            height: 20,
                            color: Theme.of(
                              context,
                            ).extension<StackColors>()!.textDark3,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    RichText(
                      text: TextSpan(
                        style: STextStyles.itemSubtitle12(context).copyWith(
                          color: Theme.of(
                            context,
                          ).extension<StackColors>()!.textSubtitle1,
                        ),
                        children: [
                          const TextSpan(
                            text:
                                "Concierge shopping service. Purchase "
                                "products and services using cryptocurrency.\n\n"
                                "Minimum order value of 1,000 EUR. "
                                "A 10% service fee applies to all orders.\n\n"
                                "By using ShopInBit, you agree to their ",
                          ),
                          TextSpan(
                            text: "Terms & Conditions",
                            style: STextStyles.richLink(
                              context,
                            ).copyWith(fontSize: 14),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () async {
                                const url =
                                    "https://api.shopinbit.com/static/policy/terms.html";
                                final shouldOpen =
                                    await _showOpenBrowserWarning(context, url);
                                if (shouldOpen) {
                                  await launchUrl(
                                    Uri.parse(url),
                                    mode: LaunchMode.externalApplication,
                                  );
                                }
                              },
                          ),
                          const TextSpan(text: " and "),
                          TextSpan(
                            text: "Privacy Policy",
                            style: STextStyles.richLink(
                              context,
                            ).copyWith(fontSize: 14),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () async {
                                const url =
                                    "https://api.shopinbit.com/static/policy/privacy.html";
                                final shouldOpen =
                                    await _showOpenBrowserWarning(context, url);
                                if (shouldOpen) {
                                  await launchUrl(
                                    Uri.parse(url),
                                    mode: LaunchMode.externalApplication,
                                  );
                                }
                              },
                          ),
                          const TextSpan(text: "."),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    PrimaryButton(
                      label: "Shop with ShopInBit",
                      enabled: true,
                      onPressed: () => _showShopDialog(context),
                    ),
                    const SizedBox(height: 12),
                    Builder(
                      builder: (context) {
                        final count = MainDB.instance
                            .getShopInBitTickets()
                            .length;
                        return SecondaryButton(
                          label: count > 0
                              ? "My tickets ($count)"
                              : "My tickets",
                          onPressed: () async {
                            await Navigator.of(
                              context,
                            ).pushNamed(ShopInBitTicketsView.routeName);
                            if (mounted) setState(() {});
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

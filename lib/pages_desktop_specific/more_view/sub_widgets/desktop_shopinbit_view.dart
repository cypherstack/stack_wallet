import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app_config.dart';
import '../../../db/isar/main_db.dart';
import '../../../models/shopinbit/shopinbit_order_model.dart';
import '../../../pages/shopinbit/shopinbit_step_1.dart';
import '../../../pages/shopinbit/shopinbit_tickets_view.dart';
import '../../../providers/desktop/current_desktop_menu_item.dart';
import '../../../utilities/assets.dart';
import '../../../utilities/text_styles.dart';
import '../../../widgets/desktop/desktop_dialog.dart';
import '../../../widgets/desktop/primary_button.dart';
import '../../../widgets/desktop/secondary_button.dart';
import '../../../widgets/rounded_white_container.dart';
import '../../desktop_menu.dart';
import '../../settings/settings_menu.dart';

class DesktopShopInBitView extends ConsumerStatefulWidget {
  const DesktopShopInBitView({super.key});

  static const String routeName = "/desktopShopInBitView";

  @override
  ConsumerState<DesktopShopInBitView> createState() =>
      _DesktopServicesViewState();
}

class _DesktopServicesViewState extends ConsumerState<DesktopShopInBitView> {
  Future<bool> _showOpenBrowserWarning(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    final shouldContinue = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => DesktopDialog(
        maxWidth: 550,
        maxHeight: 250,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
          child: Column(
            children: [
              Text("Attention", style: STextStyles.desktopH2(context)),
              const SizedBox(height: 16),
              Text(
                "You are about to open "
                "${uri.scheme}://${uri.host} "
                "in your browser.",
                style: STextStyles.desktopTextSmall(context),
              ),
              const SizedBox(height: 35),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SecondaryButton(
                    width: 200,
                    buttonHeight: ButtonHeight.l,
                    label: "Cancel",
                    onPressed: () {
                      Navigator.of(context, rootNavigator: true).pop(false);
                    },
                  ),
                  const SizedBox(width: 20),
                  PrimaryButton(
                    width: 200,
                    buttonHeight: ButtonHeight.l,
                    label: "Continue",
                    onPressed: () {
                      Navigator.of(context, rootNavigator: true).pop(true);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    return shouldContinue ?? false;
  }

  void _showShopDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => DesktopDialog(
        maxWidth: 550,
        maxHeight: 300,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("ShopInBit", style: STextStyles.desktopH2(dialogContext)),
              const SizedBox(height: 16),
              RichText(
                text: TextSpan(
                  style: STextStyles.desktopTextSmall(dialogContext),
                  children: [
                    const TextSpan(
                      text:
                          "Please note the following before proceeding:"
                          "\n\n\u2022 Minimum order amount: 1,000 EUR"
                          "\n\u2022 Service fee: 10% of the order total",
                      // "\n\nBy continuing, you agree to the ShopInBit ",
                    ),
                    // TextSpan(
                    //   text: "Privacy Policy",
                    //   style: STextStyles.richLink(dialogContext).copyWith(
                    //     fontSize: 18,
                    //   ),
                    //   recognizer: TapGestureRecognizer()
                    //     ..onTap = () async {
                    //       const url =
                    //           "https://api.shopinbit.com/static/policy/privacy.html";
                    //       final shouldOpen =
                    //           await _showOpenBrowserWarning(dialogContext, url);
                    //       if (shouldOpen) {
                    //         await launchUrl(
                    //           Uri.parse(url),
                    //           mode: LaunchMode.externalApplication,
                    //         );
                    //       }
                    //     },
                    // ),
                    // const TextSpan(text: "."),
                  ],
                ),
              ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SecondaryButton(
                    width: 200,
                    buttonHeight: ButtonHeight.l,
                    label: "Cancel",
                    onPressed: () {
                      Navigator.of(dialogContext, rootNavigator: true).pop();
                    },
                  ),
                  const SizedBox(width: 20),
                  PrimaryButton(
                    width: 200,
                    buttonHeight: ButtonHeight.l,
                    label: "Continue",
                    onPressed: () async {
                      Navigator.of(dialogContext, rootNavigator: true).pop();
                      await showDialog<void>(
                        context: context,
                        builder: (_) =>
                            ShopInBitStep1(model: ShopInBitOrderModel()),
                      );
                      if (mounted) setState(() {});
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

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
                    Assets.svg.circleSliders,
                    width: 48,
                    height: 48,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: RichText(
                    textAlign: TextAlign.start,
                    text: TextSpan(
                      style: STextStyles.desktopTextExtraExtraSmall(context),
                      children: [
                        TextSpan(
                          text: "ShopInBit",
                          style: STextStyles.desktopTextSmall(context),
                        ),
                        const TextSpan(
                          text:
                              "\n\nConcierge shopping service. Purchase "
                              "products and services using cryptocurrency.\n\n"
                              "Minimum order value of 1,000 EUR. "
                              "A 10% service fee applies to all orders.\n\n"
                              "By using ShopInBit, you agree to their ",
                        ),
                        TextSpan(
                          text: "Terms & Conditions",
                          style: STextStyles.richLink(context),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () async {
                              const url =
                                  "https://api.shopinbit.com/static/policy/terms.html";
                              final shouldOpen = await _showOpenBrowserWarning(
                                context,
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
                        const TextSpan(text: " and "),
                        TextSpan(
                          text: "Privacy Policy",
                          style: STextStyles.richLink(context),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () async {
                              const url =
                                  "https://api.shopinbit.com/static/policy/privacy.html";
                              final shouldOpen = await _showOpenBrowserWarning(
                                context,
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
                ),
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Row(
                    children: [
                      PrimaryButton(
                        width: 250,
                        buttonHeight: ButtonHeight.m,
                        enabled: true,
                        label: "Shop with ShopInBit",
                        onPressed: () => _showShopDialog(context),
                      ),
                      const SizedBox(width: 16),
                      Builder(
                        builder: (context) {
                          final count = MainDB.instance
                              .getShopInBitTickets()
                              .length;
                          return SecondaryButton(
                            width: 200,
                            buttonHeight: ButtonHeight.m,
                            label: count > 0
                                ? "My tickets ($count)"
                                : "My tickets",
                            onPressed: () async {
                              await showDialog<void>(
                                context: context,
                                builder: (_) => const ShopInBitTicketsView(),
                              );
                              if (mounted) setState(() {});
                            },
                          );
                        },
                      ),
                      const SizedBox(width: 16),
                      SecondaryButton(
                        width: 140,
                        buttonHeight: ButtonHeight.m,
                        label: "Settings",
                        onPressed: () {
                          // ShopInBit is the last settings menu item.
                          var idx = 8;
                          if (AppConfig.hasFeature(AppFeature.themeSelection)) {
                            idx++;
                          }
                          ref
                                  .read(
                                    selectedSettingsMenuItemStateProvider.state,
                                  )
                                  .state =
                              idx;
                          ref.read(currentDesktopMenuItemProvider.state).state =
                              DesktopMenuItemId.settings;
                        },
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

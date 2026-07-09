import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';

import '../../db/drift/shared_db/shared_database.dart';
import '../../providers/providers.dart';
import '../../themes/stack_colors.dart';
import '../../utilities/assets.dart';
import '../../utilities/text_styles.dart';
import '../../widgets/desktop/primary_button.dart';
import '../../widgets/desktop/secondary_button.dart';
import '../../widgets/dialogs/request_external_link_navigation_dialog.dart';
import '../../widgets/rounded_white_container.dart';
import '../../widgets/stack_dialog.dart';
import '../shopinbit/shopinbit_setup_view.dart';
import '../shopinbit/shopinbit_step_2.dart';
import '../shopinbit/shopinbit_tickets_view.dart';

class ServicesView extends ConsumerStatefulWidget {
  const ServicesView({super.key});

  @override
  ConsumerState<ServicesView> createState() => _ServicesViewState();
}

class _ServicesViewState extends ConsumerState<ServicesView> {
  Future<void> _showShopDialog() async {
    final result =
        await showDialog<({ShopInBitSetting? settings, bool continuePressed})>(
          context: context,
          barrierDismissible: true,
          builder: (context) => StackDialogBase(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("ShopinBit", style: STextStyles.pageTitleH2(context)),
                const SizedBox(height: 8),
                RichText(
                  text: TextSpan(
                    style: STextStyles.smallMed14(context),
                    children: [
                      const TextSpan(
                        text:
                            "Please note the following before proceeding:"
                            "\n\n\u2022 Minimum order amount: 1,000 EUR"
                            "\n\u2022 Service fee: 10% of the order total"
                            "\n\nBy continuing, you agree to the ShopinBit ",
                      ),
                      TextSpan(
                        text: "Privacy Policy",
                        style: STextStyles.richLink(
                          context,
                        ).copyWith(fontSize: 16),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () async {
                            const url =
                                "https://api.shopinbit.com/static/policy/privacy.html";

                            await showRequestExternalLinkAndMaybeLaunch(
                              context,
                              uri: Uri.parse(url),
                            );
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
                      child: SecondaryButton(
                        label: "Cancel",
                        onPressed: Navigator.of(context).pop,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextButton(
                        style: Theme.of(context)
                            .extension<StackColors>()!
                            .getPrimaryEnabledButtonStyle(context),
                        onPressed: () async {
                          final settings = await ref
                              .read(pSharedDrift)
                              .shopInBitSettingsDao
                              .getCurrentSettings();

                          if (!context.mounted) return;

                          Navigator.of(
                            context,
                          ).pop((settings: settings, continuePressed: true));
                        },
                        child: Text(
                          "Continue",
                          style: STextStyles.button(context),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );

    if (mounted && result != null && result.continuePressed == true) {
      final settings = result.settings;
      if (settings != null && settings.setupComplete) {
        // Returning user: straight to category selection.
        await Navigator.of(context).pushNamed(ShopInBitStep2.routeName);
      } else {
        // First-time (or incomplete) setup: show the key-backup screen.
        await Navigator.of(context).pushNamed(ShopInBitSetupView.routeName);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: RoundedWhiteContainer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0E3E3),
                        borderRadius: .circular(20),
                      ),
                      width: 40,
                      height: 40,
                      child: Center(
                        child: SizedBox(
                          width: 27,
                          height: 27,
                          child: SvgPicture.asset(
                            Assets.svg.sib,
                            colorFilter: const .mode(Colors.black, .srcIn),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "ShopinBit",
                        style: STextStyles.titleBold12(context),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  "Turn your crypto into Electronics, Flights, Hotel, "
                  "Cars or any other legal product or service... "
                  "ShopinBit is a concierge shopping service that helps "
                  "you 'live the good life with crypto'...",
                  style: STextStyles.itemSubtitle12(context).copyWith(
                    color: Theme.of(
                      context,
                    ).extension<StackColors>()!.textSubtitle1,
                  ),
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
                            "Minimum order value of 1,000 EUR. "
                            "A 10% service fee applies to all orders.\n\n"
                            "By using ShopinBit, you agree to their ",
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

                            await showRequestExternalLinkAndMaybeLaunch(
                              context,
                              uri: Uri.parse(url),
                            );
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

                            await showRequestExternalLinkAndMaybeLaunch(
                              context,
                              uri: Uri.parse(url),
                            );
                          },
                      ),
                      const TextSpan(text: "."),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                PrimaryButton(
                  label: "Shop with ShopinBit",
                  enabled: true,
                  onPressed: _showShopDialog,
                ),
                const SizedBox(height: 12),
                SecondaryButton(
                  label: "My requests",
                  onPressed: () async {
                    await Navigator.of(
                      context,
                    ).pushNamed(ShopInBitTicketsView.routeName);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

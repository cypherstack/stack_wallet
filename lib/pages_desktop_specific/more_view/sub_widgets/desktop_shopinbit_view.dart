import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app_config.dart';
import '../../../db/isar/main_db.dart';
import '../../../models/shopinbit/shopinbit_order_model.dart';
import '../../../notifications/show_flush_bar.dart';
import '../../../pages/shopinbit/shopinbit_step_1.dart';
import '../../../pages/shopinbit/shopinbit_tickets_view.dart';
import '../../../providers/desktop/current_desktop_menu_item.dart';
import '../../../services/shopinbit/shopinbit_service.dart';
import '../../../themes/stack_colors.dart';
import '../../../utilities/assets.dart';
import '../../../utilities/text_styles.dart';
import '../../../widgets/desktop/desktop_dialog.dart';
import '../../../widgets/desktop/desktop_dialog_close_button.dart';
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

  void _showShopDialog(BuildContext context) async {
    final service = ShopInBitService.instance;
    final model = ShopInBitOrderModel();

    if (!service.loadSetupComplete()) {
      // First-time user: show setup.
      final completed = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (_) => _ShopInBitDesktopSetupDialog(model: model),
      );
      if (completed != true) return; // user cancelled
    } else {
      // Returning user: restore display name.
      final savedName = service.loadDisplayName();
      if (savedName != null && savedName.isNotEmpty) {
        model.displayName = savedName;
      }
    }

    // Show warning dialog.
    if (!mounted) return;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => DesktopDialog(
        maxWidth: 550,
        maxHeight: 300,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("ShopinBit", style: STextStyles.desktopH2(dialogContext)),
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
                    ),
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
                        barrierDismissible: false,
                        builder: (_) =>
                            ShopInBitStep1(model: model),
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
                          text: "ShopinBit",
                          style: STextStyles.desktopTextSmall(context),
                        ),
                        const TextSpan(
                          text:
                              "\n\nTurn your crypto into Electronics, Flights, Hotel, "
                              "Cars or any other legal product or service... "
                              "ShopinBit is a concierge shopping service that helps "
                              "you 'live the good life with crypto'..."
                              "\n\n"
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
                          style: STextStyles.richLink(
                            context,
                          ).copyWith(fontSize: 14),
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
                        label: "Shop with ShopinBit",
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
                                ? "My requests ($count)"
                                : "My requests",
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

class _ShopInBitDesktopSetupDialog extends StatefulWidget {
  const _ShopInBitDesktopSetupDialog({required this.model});

  final ShopInBitOrderModel model;

  @override
  State<_ShopInBitDesktopSetupDialog> createState() =>
      _ShopInBitDesktopSetupDialogState();
}

class _ShopInBitDesktopSetupDialogState
    extends State<_ShopInBitDesktopSetupDialog> {
  late final Future<String> _keyFuture;
  late final TextEditingController _nameController;
  late final FocusNode _nameFocusNode;

  bool get _canContinue => _nameController.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    _keyFuture = ShopInBitService.instance.ensureCustomerKey();
    _nameController = TextEditingController();
    _nameFocusNode = FocusNode();

    _nameFocusNode.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nameFocusNode.dispose();
    super.dispose();
  }

  Future<void> _completeSetup() async {
    final name = _nameController.text.trim();
    widget.model.displayName = name;
    await ShopInBitService.instance.setDisplayName(name);
    await ShopInBitService.instance.setSetupComplete(true);
    if (mounted) {
      Navigator.of(context, rootNavigator: true).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DesktopDialog(
      maxWidth: 580,
      maxHeight: 500,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 32),
                child: Text(
                  "ShopinBit Setup",
                  style: STextStyles.desktopH3(context),
                ),
              ),
              const DesktopDialogCloseButton(),
            ],
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    "Your Customer Key",
                    style: STextStyles.desktopTextSmall(context).copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "This is your ShopinBit customer key: save it "
                    "somewhere safe, you'll need it to recover "
                    "your ShopinBit account on a new device.",
                    style:
                        STextStyles.desktopTextExtraExtraSmall(context),
                  ),
                  const SizedBox(height: 12),
                  FutureBuilder<String>(
                    future: _keyFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState != ConnectionState.done) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }
                      if (snapshot.hasError) {
                        return Text(
                          "Failed to generate key. Please try again.",
                          style: STextStyles.desktopTextSmall(context).copyWith(
                            color: Theme.of(context)
                                .extension<StackColors>()!
                                .textError,
                          ),
                        );
                      }
                      final key = snapshot.data!;
                      return RoundedWhiteContainer(
                        child: Row(
                          children: [
                            Expanded(
                              child: SelectableText(
                                key,
                                style:
                                    STextStyles.desktopTextExtraExtraSmall(
                                      context,
                                    ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.copy, size: 20),
                              onPressed: () {
                                Clipboard.setData(
                                  ClipboardData(text: key),
                                );
                                showFloatingFlushBar(
                                  type: FlushBarType.info,
                                  message: "Copied to clipboard!",
                                  context: context,
                                );
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  Text(
                    "Display Name",
                    style: STextStyles.desktopTextSmall(context).copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _nameController,
                    focusNode: _nameFocusNode,
                    onChanged: (_) => setState(() {}),
                    style: STextStyles.desktopTextSmall(context),
                    decoration: const InputDecoration(
                      hintText: "Display name",
                    ),
                  ),
                  const Spacer(),
                  PrimaryButton(
                    label: "Complete Setup",
                    enabled: _canContinue,
                    onPressed: _canContinue ? _completeSetup : null,
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

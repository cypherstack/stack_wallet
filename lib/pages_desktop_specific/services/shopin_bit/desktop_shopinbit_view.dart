import 'package:drift/drift.dart' show TableOrViewStatements;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';

import '../../../app_config.dart';
import '../../../models/shopinbit/shopinbit_order_model.dart';
import '../../../notifications/show_flush_bar.dart';
import '../../../pages/shopinbit/shopinbit_step_2.dart';
import '../../../pages/shopinbit/shopinbit_tickets_view.dart';
import '../../../providers/db/drift_provider.dart';
import '../../../providers/desktop/current_desktop_menu_item.dart';
import '../../../providers/global/shopin_bit_service_provider.dart';
import '../../../themes/stack_colors.dart';
import '../../../utilities/assets.dart';
import '../../../utilities/text_styles.dart';
import '../../../widgets/desktop/desktop_dialog.dart';
import '../../../widgets/desktop/desktop_dialog_close_button.dart';
import '../../../widgets/desktop/primary_button.dart';
import '../../../widgets/desktop/secondary_button.dart';
import '../../../widgets/dialogs/nested_navigator_dialog/nested_navigator_dialog.dart';
import '../../../widgets/dialogs/request_external_link_navigation_dialog.dart';
import '../../../widgets/rounded_container.dart';
import '../../../widgets/rounded_white_container.dart';
import '../../../widgets/textfields/adaptive_text_field.dart';
import '../../desktop_menu.dart';
import '../../settings/settings_menu.dart';
import 'sub_widgets/desktop_shopin_bit_first_run.dart';

class DesktopShopInBitView extends ConsumerStatefulWidget {
  const DesktopShopInBitView({super.key});

  static const String routeName = "/desktopShopInBitView";

  @override
  ConsumerState<DesktopShopInBitView> createState() =>
      _DesktopServicesViewState();
}

class _DesktopServicesViewState extends ConsumerState<DesktopShopInBitView> {
  Future<void> _showShopDialog() async {
    final dao = ref.read(pSharedDrift).shopinBitSettingsDao;
    final settings = await dao.getSettings();
    final model = ShopInBitOrderModel();
    bool isFirstRun = false;

    if (!settings.setupComplete) {
      // something went wrong
      if (!mounted) return;

      // First-time user: show setup.
      final completed = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (_) => _ShopInBitDesktopSetupDialog(model: model),
      );
      if (completed != true) return; // user cancelled
      isFirstRun = true;
    } else {
      // Returning user: restore display name.
      final savedName = settings.displayName;
      if (savedName != null && savedName.isNotEmpty) {
        model.displayName = savedName;
      }
    }

    if (!mounted) return;

    if (isFirstRun) {
      // First run: show service overview then go directly to Step2
      // (name was just entered in setup dialog, no need to show Step1 again).
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => NestedNavigatorDialog(
          initialRoute: DesktopShopinBitFirstRun.routeName,
          initialRouteArgs: model,
        ),
      );
    } else {
      // Returning user: go directly to Step2 (skip service overview dialog
      // and the redundant display-name prompt; name is already loaded from
      // settings into model).
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => NestedNavigatorDialog(
          initialRoute: ShopInBitStep2.routeName,
          initialRouteArgs: model,
        ),
      );

      // TODO: figure out and comment why this is needed
      if (mounted) setState(() {});
    }
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
                ),
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Row(
                    children: [
                      PrimaryButton(
                        width: 224,
                        buttonHeight: ButtonHeight.m,
                        enabled: true,
                        label: "Shop with ShopinBit",
                        onPressed: _showShopDialog,
                      ),
                      const SizedBox(width: 16),
                      StreamBuilder(
                        stream: ref
                            .watch(pSharedDrift)
                            .shopInBitTickets
                            .count()
                            .watchSingleOrNull(),
                        builder: (context, snapshot) {
                          final count = snapshot.data ?? 0;

                          return SecondaryButton(
                            width: 196,
                            buttonHeight: ButtonHeight.m,
                            label: count > 0
                                ? "My requests ($count)"
                                : "My requests",
                            onPressed: () async {
                              await showDialog<void>(
                                context: context,
                                builder: (_) => const NestedNavigatorDialog(
                                  initialRoute: ShopInBitTicketsView.routeName,
                                ),
                              );
                              if (mounted) setState(() {});
                            },
                          );
                        },
                      ),
                      const SizedBox(width: 16),
                      SecondaryButton(
                        width: 118,
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

class _ShopInBitDesktopSetupDialog extends ConsumerStatefulWidget {
  const _ShopInBitDesktopSetupDialog({required this.model});

  final ShopInBitOrderModel model;

  @override
  ConsumerState<_ShopInBitDesktopSetupDialog> createState() =>
      _ShopInBitDesktopSetupDialogState();
}

class _ShopInBitDesktopSetupDialogState
    extends ConsumerState<_ShopInBitDesktopSetupDialog> {
  late final Future<String> _keyFuture;
  final TextEditingController _nameController = TextEditingController();

  bool get _canContinue => _nameController.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    _keyFuture = ref.read(pShopinBitService).ensureCustomerKey();

    // not the greatest solution but its the least invasive with the current
    // ui code impl
    () async {
      final settings = await ref
          .read(pSharedDrift)
          .shopinBitSettingsDao
          .getSettings();
      if (mounted) {
        setState(() {
          _nameController.text = settings.displayName ?? "";
        });
      }
    }();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _completeSetup() async {
    final name = _nameController.text.trim();
    widget.model.displayName = name;
    final dao = ref.read(pSharedDrift).shopinBitSettingsDao;
    await dao.setDisplayName(name);
    await dao.setSetupComplete(true);
    if (mounted) {
      Navigator.of(context, rootNavigator: true).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final maxDialogHeight = MediaQuery.sizeOf(context).height - 64;
    return DesktopDialog(
      maxWidth: 580,
      maxHeight: maxDialogHeight,
      child: Column(
        mainAxisSize: .min,
        crossAxisAlignment: .stretch,
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
          Flexible(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisSize: .min,
                crossAxisAlignment: .stretch,
                children: [
                  const SizedBox(height: 16),
                  Text(
                    "Your Customer Key",
                    style: STextStyles.w600_20(context),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "This is your ShopinBit customer key: save it "
                    "somewhere safe, you'll need it to recover "
                    "your ShopinBit account on a new device.",
                    style: STextStyles.desktopTextExtraExtraSmall(context),
                  ),
                  const SizedBox(height: 12),
                  FutureBuilder<String>(
                    future: _keyFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState != ConnectionState.done) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return RoundedContainer(
                          color: Theme.of(
                            context,
                          ).extension<StackColors>()!.warningBackground,
                          child: Text(
                            "Failed to generate key. Please try again.",
                            style: STextStyles.label700(context).copyWith(
                              color: Theme.of(
                                context,
                              ).extension<StackColors>()!.warningForeground,
                              fontSize: 14,
                            ),
                          ),
                        );
                      }
                      final key = snapshot.data!;
                      return RoundedWhiteContainer(
                        borderColor: Theme.of(
                          context,
                        ).extension<StackColors>()!.textSubtitle6,
                        child: Row(
                          children: [
                            const SizedBox(width: 10),
                            Expanded(
                              child: SelectableText(
                                key,
                                style: STextStyles.desktopTextExtraExtraSmall(
                                  context,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.copy, size: 20),
                              onPressed: () {
                                Clipboard.setData(ClipboardData(text: key));
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
                    style: STextStyles.desktopTextExtraExtraSmall(context)
                        .copyWith(
                          color: Theme.of(context)
                              .extension<StackColors>()!
                              .textFieldActiveSearchIconRight,
                        ),
                  ),
                  const SizedBox(height: 8),
                  AdaptiveTextField(
                    controller: _nameController,
                    showPasteClearButton: true,
                    maxLines: 1,
                    onChangedComprehensive: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 40),
                  Row(
                    mainAxisAlignment: .end,
                    children: [
                      PrimaryButton(
                        label: "Complete Setup",
                        enabled: _canContinue,
                        onPressed: _canContinue ? _completeSetup : null,
                        horizontalContentPadding: 20,
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

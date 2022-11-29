import 'dart:io';

import 'package:flutter/material.dart';
import 'package:epicmobile/pages/address_book_views/address_book_view.dart';
import 'package:epicmobile/pages/pinpad_views/lock_screen_view.dart';
import 'package:epicmobile/pages/settings_views/global_settings_view/about_view.dart';
import 'package:epicmobile/pages/settings_views/global_settings_view/advanced_views/advanced_settings_view.dart';
import 'package:epicmobile/pages/settings_views/global_settings_view/appearance_settings_view.dart';
import 'package:epicmobile/pages/settings_views/global_settings_view/currency_view.dart';
import 'package:epicmobile/pages/settings_views/global_settings_view/delete_account_view.dart';
import 'package:epicmobile/pages/settings_views/global_settings_view/language_view.dart';
import 'package:epicmobile/pages/settings_views/global_settings_view/manage_nodes_views/manage_nodes_view.dart';
import 'package:epicmobile/pages/settings_views/global_settings_view/security_views/security_view.dart';
import 'package:epicmobile/pages/settings_views/global_settings_view/stack_backup_views/stack_backup_view.dart';
import 'package:epicmobile/pages/settings_views/global_settings_view/startup_preferences/startup_preferences_view.dart';
import 'package:epicmobile/pages/settings_views/global_settings_view/support_view.dart';
import 'package:epicmobile/pages/settings_views/global_settings_view/syncing_preferences_views/syncing_preferences_view.dart';
import 'package:epicmobile/pages/settings_views/sub_widgets/settings_list_button.dart';
import 'package:epicmobile/route_generator.dart';
import 'package:epicmobile/utilities/assets.dart';
import 'package:epicmobile/utilities/delete_everything.dart';
import 'package:epicmobile/utilities/text_styles.dart';
import 'package:epicmobile/utilities/theme/stack_colors.dart';
import 'package:epicmobile/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:epicmobile/widgets/rounded_white_containerettingsView extends StatelessWidget {
  const GlobalSettingsView({
    Key? key,
  }) : super(key: key);

  static const String routeName = "/globalSettings";

  @override
  Widget build(BuildContext context) {
    debugPrint("BUILD: $runtimeType");
    return Scaffold(
      backgroundColor: Theme.of(context).extension<StackColors>()!.background,
      appBar: AppBar(
        leading: AppBarBackButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: Text(
          "Settings",
          style: STextStyles.navBarTitle(context),
        ),
      ),
      body: LayoutBuilder(
        builder: (builderContext, constraints) {
          return Padding(
            padding: const EdgeInsets.only(
              left: 12,
              top: 12,
              right: 12,
            ),
            child: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 24,
                ),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        RoundedWhiteContainer(
                          padding: const EdgeInsets.all(4),
                          child: Column(
                            children: [
                              SettingsListButton(
                                iconAssetName: Assets.svg.addressBook,
                                iconSize: 16,
                                title: "Address book",
                                onPressed: () {
                                  Navigator.of(context)
                                      .pushNamed(AddressBookView.routeName);
                                },
                              ),
                              const SizedBox(
                                height: 8,
                              ),
                              SettingsListButton(
                                iconAssetName: Assets.svg.downloadFolder,
                                iconSize: 14,
                                title: "Stack backup & restore",
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    RouteGenerator.getRoute(
                                      shouldUseMaterialRoute:
                                          RouteGenerator.useMaterialPageRoute,
                                      builder: (_) => const LockscreenView(
                                        showBackButton: true,
                                        routeOnSuccess:
                                            StackBackupView.routeName,
                                        biometricsCancelButtonString: "CANCEL",
                                        biometricsLocalizedReason:
                                            "Authenticate to access Stack backup & restore settings",
                                        biometricsAuthenticationTitle:
                                            "Stack backup",
                                      ),
                                      settings: const RouteSettings(
                                          name: "/swblockscreen"),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(
                                height: 8,
                              ),
                              SettingsListButton(
                                iconAssetName: Assets.svg.lock,
                                iconSize: 16,
                                title: "Security",
                                onPressed: () {
                                  Navigator.of(context)
                                      .pushNamed(SecurityView.routeName);
                                },
                              ),
                              const SizedBox(
                                height: 8,
                              ),
                              SettingsListButton(
                                iconAssetName: Assets.svg.dollarSign,
                                iconSize: 18,
                                title: "Currency",
                                onPressed: () {
                                  Navigator.of(context).pushNamed(
                                      BaseCurrencySettingsView.routeName);
                                },
                              ),
                              const SizedBox(
                                height: 8,
                              ),
                              SettingsListButton(
                                iconAssetName: Assets.svg.language,
                                iconSize: 18,
                                title: "Language",
                                onPressed: () {
                                  Navigator.of(context).pushNamed(
                                      LanguageSettingsView.routeName);
                                },
                              ),
                              const SizedBox(
                                height: 8,
                              ),
                              SettingsListButton(
                                iconAssetName: Assets.svg.node,
                                iconSize: 16,
                                title: "Manage nodes",
                                onPressed: () {
                                  Navigator.of(context)
                                      .pushNamed(ManageNodesView.routeName);
                                },
                              ),
                              const SizedBox(
                                height: 8,
                              ),
                              SettingsListButton(
                                iconAssetName: Assets.svg.arrowRotate3,
                                iconSize: 18,
                                title: "Syncing preferences",
                                onPressed: () {
                                  Navigator.of(context).pushNamed(
                                      SyncingPreferencesView.routeName);
                                },
                              ),
                              const SizedBox(
                                height: 8,
                              ),
                              SettingsListButton(
                                iconAssetName: Assets.svg.arrowUpRight,
                                iconSize: 16,
                                title: "Startup",
                                onPressed: () {
                                  Navigator.of(context).pushNamed(
                                      StartupPreferencesView.routeName);
                                },
                              ),
                              const SizedBox(
                                height: 8,
                              ),
                              SettingsListButton(
                                iconAssetName: Assets.svg.sun,
                                iconSize: 18,
                                title: "Appearance",
                                onPressed: () {
                                  Navigator.of(context).pushNamed(
                                      AppearanceSettingsView.routeName);
                                },
                              ),
                              if (Platform.isIOS)
                                const SizedBox(
                                  height: 8,
                                ),
                              if (Platform.isIOS)
                                SettingsListButton(
                                  iconAssetName: Assets.svg.circleAlert,
                                  iconSize: 16,
                                  title: "Delete account",
                                  onPressed: () async {
                                    await Navigator.of(context)
                                        .pushNamed(DeleteAccountView.routeName);
                                  },
                                ),
                              const SizedBox(
                                height: 8,
                              ),
                              SettingsListButton(
                                iconAssetName: Assets.svg.ellipsis,
                                iconSize: 18,
                                title: "About",
                                onPressed: () {
                                  Navigator.of(context)
                                      .pushNamed(AboutView.routeName);
                                },
                              ),
                              const SizedBox(
                                height: 8,
                              ),
                              SettingsListButton(
                                iconAssetName: Assets.svg.solidSliders,
                                iconSize: 16,
                                title: "Advanced",
                                onPressed: () {
                                  Navigator.of(context).pushNamed(
                                      AdvancedSettingsView.routeName);
                                },
                              ),
                              const SizedBox(
                                height: 8,
                              ),
                              SettingsListButton(
                                iconAssetName: Assets.svg.questionMessage,
                                iconSize: 16,
                                title: "Support",
                                onPressed: () {
                                  Navigator.of(context)
                                      .pushNamed(SupportView.routeName);
                                },
                              ),
                              // TextButton(
                              //   style: Theme.of(context)
                              //       .textButtonTheme
                              //       .style
                              //       ?.copyWith(
                              //         backgroundColor:
                              //             MaterialStateProperty.all<Color>(
                              //           Theme.of(context).extension<StackColors>()!.accentColorDark
                              //         ),
                              //       ),
                              //   child: Text(
                              //     "fire test notification",
                              //     style: STextStyles.button(context),
                              //   ),
                              //   onPressed: () async {
                              //     NotificationApi.showNotification2(
                              //       title: "Test notification",
                              //       body: "My doggy wallet",
                              //       walletId:
                              //           "3c5e2d70-fcc3-11ec-86a3-31a106a81c3b",
                              //       iconAssetName:
                              //           Assets.svg.iconFor(coin: Coin.dogecoin),
                              //       date: DateTime.now(),
                              //     );
                              //   },
                              // ),
                            ],
                          ),
                        ),
                        const SizedBox(
                          height: 12,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

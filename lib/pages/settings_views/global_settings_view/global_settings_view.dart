import 'dart:io';

import 'package:flutter/material.dart';
import 'package:stackduo/pages/address_book_views/address_book_view.dart';
import 'package:stackduo/pages/pinpad_views/lock_screen_view.dart';
import 'package:stackduo/pages/settings_views/global_settings_view/about_view.dart';
import 'package:stackduo/pages/settings_views/global_settings_view/advanced_views/advanced_settings_view.dart';
import 'package:stackduo/pages/settings_views/global_settings_view/appearance_settings_view.dart';
import 'package:stackduo/pages/settings_views/global_settings_view/currency_view.dart';
import 'package:stackduo/pages/settings_views/global_settings_view/delete_account_view.dart';
import 'package:stackduo/pages/settings_views/global_settings_view/language_view.dart';
import 'package:stackduo/pages/settings_views/global_settings_view/manage_nodes_views/manage_nodes_view.dart';
import 'package:stackduo/pages/settings_views/global_settings_view/security_views/security_view.dart';
import 'package:stackduo/pages/settings_views/global_settings_view/stack_backup_views/stack_backup_view.dart';
import 'package:stackduo/pages/settings_views/global_settings_view/startup_preferences/startup_preferences_view.dart';
import 'package:stackduo/pages/settings_views/global_settings_view/support_view.dart';
import 'package:stackduo/pages/settings_views/global_settings_view/syncing_preferences_views/syncing_preferences_view.dart';
import 'package:stackduo/pages/settings_views/sub_widgets/settings_list_button.dart';
import 'package:stackduo/route_generator.dart';
import 'package:stackduo/utilities/assets.dart';
import 'package:stackduo/utilities/text_styles.dart';
import 'package:stackduo/utilities/theme/stack_colors.dart';
import 'package:stackduo/widgets/background.dart';
import 'package:stackduo/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:stackduo/widgets/rounded_white_container.dart';

class GlobalSettingsView extends StatelessWidget {
  const GlobalSettingsView({
    Key? key,
  }) : super(key: key);

  static const String routeName = "/globalSettings";

  @override
  Widget build(BuildContext context) {
    debugPrint("BUILD: $runtimeType");
    return Background(
      child: Scaffold(
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
                                          biometricsCancelButtonString:
                                              "CANCEL",
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
                                      await Navigator.of(context).pushNamed(
                                          DeleteAccountView.routeName);
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
      ),
    );
  }
}

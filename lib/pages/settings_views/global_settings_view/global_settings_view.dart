import 'package:epicmobile/pages/address_book_views/address_book_view.dart';
import 'package:epicmobile/pages/settings_views/global_settings_view/currency_view.dart';
import 'package:epicmobile/pages/settings_views/global_settings_view/language_view.dart';
import 'package:epicmobile/pages/settings_views/global_settings_view/manage_nodes_views/manage_nodes_view.dart';
import 'package:epicmobile/pages/settings_views/global_settings_view/security_views/security_view.dart';
import 'package:epicmobile/pages/settings_views/sub_widgets/settings_list_button.dart';
import 'package:epicmobile/utilities/assets.dart';
import 'package:epicmobile/utilities/text_styles.dart';
import 'package:epicmobile/utilities/theme/stack_colors.dart';
import 'package:epicmobile/widgets/background.dart';
import 'package:epicmobile/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:flutter/material.dart';

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
          centerTitle: true,
          title: Text(
            "Settings",
            style: STextStyles.titleH4(context),
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
                          const _Div(),
                          SettingsListButton(
                            iconAssetName: Assets.svg.node,
                            iconSize: 16,
                            title: "Connections",
                            onPressed: () {
                              Navigator.of(context)
                                  .pushNamed(ManageNodesView.routeName);
                            },
                          ),
                          const _Div(),
                          SettingsListButton(
                            iconAssetName: Assets.svg.addressBook,
                            iconSize: 16,
                            title: "Address book",
                            onPressed: () {
                              Navigator.of(context)
                                  .pushNamed(AddressBookView.routeName);
                            },
                          ),
                          const _Div(),
                          SettingsListButton(
                            iconAssetName: Assets.svg.lock,
                            iconSize: 16,
                            title: "Security",
                            onPressed: () {
                              Navigator.of(context)
                                  .pushNamed(SecurityView.routeName);
                            },
                          ),
                          const _Div(),
                          SettingsListButton(
                            iconAssetName: Assets.svg.ellipsis,
                            iconSize: 18,
                            title: "Backup Wallet",
                            onPressed: () {
                              // Navigator.of(context)
                              //     .pushNamed(AboutView.routeName);
                            },
                          ),
                          const _Div(),
                          SettingsListButton(
                            iconAssetName: Assets.svg.solidSliders,
                            iconSize: 16,
                            title: "Wallet Settings",
                            onPressed: () {
                              // Navigator.of(context).pushNamed(
                              //     AdvancedSettingsView.routeName);
                            },
                          ),
                          const _Div(),
                          SettingsListButton(
                            iconAssetName: Assets.svg.dollarSign,
                            iconSize: 18,
                            title: "Currency",
                            onPressed: () {
                              Navigator.of(context).pushNamed(
                                  BaseCurrencySettingsView.routeName);
                            },
                          ),
                          const _Div(),
                          SettingsListButton(
                            iconAssetName: Assets.svg.language,
                            iconSize: 18,
                            title: "Language",
                            onPressed: () {
                              Navigator.of(context)
                                  .pushNamed(LanguageSettingsView.routeName);
                            },
                          ),
                          const _Div(),
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

class _Div extends StatelessWidget {
  const _Div({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Container(
        height: 0.5,
        color: Theme.of(context).extension<StackColors>()!.popupBG,
      ),
    );
  }
}

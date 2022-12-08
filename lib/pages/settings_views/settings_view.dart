import 'package:epicmobile/models/send_view_auto_fill_data.dart';
import 'package:epicmobile/pages/address_book_views/address_book_view.dart';
import 'package:epicmobile/pages/pinpad_views/lock_screen_view.dart';
import 'package:epicmobile/pages/send_view/send_view.dart';
import 'package:epicmobile/pages/settings_views/currency_view.dart';
import 'package:epicmobile/pages/settings_views/language_view.dart';
import 'package:epicmobile/pages/settings_views/network_settings_view/network_settings_view.dart';
import 'package:epicmobile/pages/settings_views/security_views/security_view.dart';
import 'package:epicmobile/pages/settings_views/settings_list_button.dart';
import 'package:epicmobile/pages/settings_views/wallet_backup_views/wallet_backup_view.dart';
import 'package:epicmobile/pages/settings_views/wallet_settings/wallet_settings_view.dart';
import 'package:epicmobile/providers/global/wallet_provider.dart';
import 'package:epicmobile/route_generator.dart';
import 'package:epicmobile/utilities/assets.dart';
import 'package:epicmobile/utilities/biometrics.dart';
import 'package:epicmobile/utilities/text_styles.dart';
import 'package:epicmobile/utilities/theme/stack_colors.dart';
import 'package:epicmobile/widgets/background.dart';
import 'package:epicmobile/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tuple/tuple.dart';

import '../../providers/ui/home_view_index_provider.dart';
import '../home_view/home_view.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({
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
                            iconAssetName: Assets.svg.wifi,
                            iconSize: 16,
                            title: "Connections",
                            onPressed: () {
                              Navigator.of(context).pushNamed(
                                NetworkSettingsView.routeName,
                              );
                            },
                          ),
                          const _Div(),
                          Consumer(builder: (context, ref, __) {
                            return SettingsListButton(
                              iconAssetName: Assets.svg.addressBook,
                              iconSize: 16,
                              title: "Address book",
                              onPressed: () {
                                Navigator.of(context).pushNamed(
                                    AddressBookView.routeName,
                                    arguments: (String name, String address) {
                                  Navigator.of(context).popUntil(
                                      ModalRoute.withName(HomeView.routeName));
                                  ref
                                      .read(
                                          homeViewPageIndexStateProvider.state)
                                      .state = 0;

                                  ref
                                      .read(sendViewFillDataProvider.state)
                                      .state = SendViewAutoFillData(
                                    address: address,
                                    contactLabel: name,
                                  );
                                });
                              },
                            );
                          }),
                          const _Div(),
                          SettingsListButton(
                            iconAssetName: Assets.svg.lock,
                            iconSize: 16,
                            title: "Security",
                            onPressed: () async {
                              final nav = Navigator.of(context);
                              final bio = await Biometrics.hasBiometrics;

                              await nav.pushNamed(
                                SecurityView.routeName,
                                arguments: bio,
                              );
                            },
                          ),
                          const _Div(),
                          Consumer(
                            builder: (_, ref, __) {
                              return SettingsListButton(
                                iconAssetName: Assets.svg.key,
                                iconSize: 18,
                                title: "Backup Wallet",
                                onPressed: () async {
                                  final navigator = Navigator.of(context);
                                  final mnemonic =
                                      await ref.read(walletProvider)!.mnemonic;
                                  await navigator.push(
                                    RouteGenerator.getRoute(
                                      shouldUseMaterialRoute:
                                          RouteGenerator.useMaterialPageRoute,
                                      builder: (_) => LockscreenView(
                                        routeOnSuccessArguments: Tuple2(
                                          ref.read(walletProvider)!.walletId,
                                          mnemonic,
                                        ),
                                        showBackButton: true,
                                        routeOnSuccess:
                                            WalletBackupView.routeName,
                                        biometricsCancelButtonString: "CANCEL",
                                        biometricsLocalizedReason:
                                            "Authenticate to view recovery phrase",
                                        biometricsAuthenticationTitle:
                                            "View recovery phrase",
                                      ),
                                      settings: const RouteSettings(
                                          name: "/viewRecoverPhraseLockscreen"),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                          const _Div(),
                          SettingsListButton(
                            iconAssetName: Assets.svg.gear,
                            iconSize: 16,
                            title: "Wallet Settings",
                            onPressed: () {
                              Navigator.of(context).pushNamed(
                                WalletSettingsView.routeName,
                              );
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
                            iconAssetName: Assets.svg.globe,
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

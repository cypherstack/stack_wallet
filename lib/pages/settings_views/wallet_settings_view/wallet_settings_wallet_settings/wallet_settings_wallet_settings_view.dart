import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stackduo/pages/pinpad_views/lock_screen_view.dart';
import 'package:stackduo/pages/settings_views/wallet_settings_view/wallet_settings_wallet_settings/delete_wallet_warning_view.dart';
import 'package:stackduo/pages/settings_views/wallet_settings_view/wallet_settings_wallet_settings/rename_wallet_view.dart';
import 'package:stackduo/providers/providers.dart';
import 'package:stackduo/route_generator.dart';
import 'package:stackduo/utilities/constants.dart';
import 'package:stackduo/utilities/text_styles.dart';
import 'package:stackduo/utilities/theme/stack_colors.dart';
import 'package:stackduo/widgets/background.dart';
import 'package:stackduo/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:stackduo/widgets/rounded_white_container.dart';
import 'package:stackduo/widgets/stack_dialog.dart';

class WalletSettingsWalletSettingsView extends ConsumerWidget {
  const WalletSettingsWalletSettingsView({
    Key? key,
    required this.walletId,
  }) : super(key: key);

  static const String routeName = "/walletSettingsWalletSettings";

  final String walletId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
            "Wallet settings",
            style: STextStyles.navBarTitle(context),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.only(
            top: 12,
            left: 16,
            right: 16,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                RoundedWhiteContainer(
                  padding: const EdgeInsets.all(0),
                  child: RawMaterialButton(
                    // splashColor: Theme.of(context).extension<StackColors>()!.highlight,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        Constants.size.circularBorderRadius,
                      ),
                    ),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    onPressed: () {
                      Navigator.of(context).pushNamed(
                        RenameWalletView.routeName,
                        arguments: walletId,
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12.0,
                        vertical: 20,
                      ),
                      child: Row(
                        children: [
                          Text(
                            "Rename wallet",
                            style: STextStyles.titleBold12(context),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(
                  height: 8,
                ),
                RoundedWhiteContainer(
                  padding: const EdgeInsets.all(0),
                  child: RawMaterialButton(
                    // splashColor: Theme.of(context).extension<StackColors>()!.highlight,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        Constants.size.circularBorderRadius,
                      ),
                    ),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    padding: const EdgeInsets.all(0),
                    onPressed: () {
                      showDialog(
                        barrierDismissible: true,
                        context: context,
                        builder: (_) => StackDialog(
                          title:
                              "Do you want to delete ${ref.read(walletsChangeNotifierProvider).getManager(walletId).walletName}?",
                          leftButton: TextButton(
                            style: Theme.of(context)
                                .extension<StackColors>()!
                                .getSecondaryEnabledButtonStyle(context),
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: Text(
                              "Cancel",
                              style: STextStyles.button(context).copyWith(
                                  color: Theme.of(context)
                                      .extension<StackColors>()!
                                      .accentColorDark),
                            ),
                          ),
                          rightButton: TextButton(
                            style: Theme.of(context)
                                .extension<StackColors>()!
                                .getPrimaryEnabledButtonStyle(context),
                            onPressed: () {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                RouteGenerator.getRoute(
                                  shouldUseMaterialRoute:
                                      RouteGenerator.useMaterialPageRoute,
                                  builder: (_) => LockscreenView(
                                    routeOnSuccessArguments: walletId,
                                    showBackButton: true,
                                    routeOnSuccess:
                                        DeleteWalletWarningView.routeName,
                                    biometricsCancelButtonString: "CANCEL",
                                    biometricsLocalizedReason:
                                        "Authenticate to delete wallet",
                                    biometricsAuthenticationTitle:
                                        "Delete wallet",
                                  ),
                                  settings: const RouteSettings(
                                      name: "/deleteWalletLockscreen"),
                                ),
                              );
                            },
                            child: Text(
                              "Delete",
                              style: STextStyles.button(context),
                            ),
                          ),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12.0,
                        vertical: 20,
                      ),
                      child: Row(
                        children: [
                          Text(
                            "Delete wallet",
                            style: STextStyles.titleBold12(context),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

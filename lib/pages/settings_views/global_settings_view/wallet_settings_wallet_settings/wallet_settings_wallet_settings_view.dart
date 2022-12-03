import 'package:epicmobile/pages/pinpad_views/lock_screen_view.dart';
import 'package:epicmobile/pages/settings_views/global_settings_view/wallet_settings_wallet_settings/delete_wallet_warning_view.dart';
import 'package:epicmobile/providers/providers.dart';
import 'package:epicmobile/route_generator.dart';
import 'package:epicmobile/utilities/constants.dart';
import 'package:epicmobile/utilities/text_styles.dart';
import 'package:epicmobile/utilities/theme/stack_colors.dart';
import 'package:epicmobile/widgets/background.dart';
import 'package:epicmobile/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:epicmobile/widgets/rounded_white_container.dart';
import 'package:epicmobile/widgets/stack_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class WalletSettingsWalletSettingsView extends ConsumerWidget {
  const WalletSettingsWalletSettingsView({
    Key? key,
  }) : super(key: key);

  static const String routeName = "/walletSettingsWalletSettings";

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
            style: STextStyles.titleH4(context),
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
                    padding: const EdgeInsets.all(0),
                    onPressed: () {
                      showDialog(
                        barrierDismissible: true,
                        context: context,
                        builder: (_) => StackDialog(
                          title:
                              "Do you want to delete ${ref.read(walletProvider)!.walletName}?",
                          leftButton: TextButton(
                            style: Theme.of(context)
                                .extension<StackColors>()!
                                .getSecondaryEnabledButtonColor(context),
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
                                .getPrimaryEnabledButtonColor(context),
                            onPressed: () {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                RouteGenerator.getRoute(
                                  shouldUseMaterialRoute:
                                      RouteGenerator.useMaterialPageRoute,
                                  builder: (_) => LockscreenView(
                                    routeOnSuccessArguments:
                                        ref.read(walletProvider)!.walletId,
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
                            style: STextStyles.bodyBold(context),
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

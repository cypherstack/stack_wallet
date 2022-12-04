import 'package:epicmobile/pages/pinpad_views/lock_screen_view.dart';
import 'package:epicmobile/pages/settings_views/wallet_settings/delete_wallet_recovery_phrase_view.dart';
import 'package:epicmobile/providers/providers.dart';
import 'package:epicmobile/route_generator.dart';
import 'package:epicmobile/utilities/text_styles.dart';
import 'package:epicmobile/utilities/theme/stack_colors.dart';
import 'package:epicmobile/widgets/background.dart';
import 'package:epicmobile/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:epicmobile/widgets/stack_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class WalletSettingsView extends ConsumerWidget {
  const WalletSettingsView({
    Key? key,
  }) : super(key: key);

  static const String routeName = "/walletSettings";

  Future<void> requestDelete(BuildContext context, WidgetRef ref) async {
    await showDialog<void>(
      context: context,
      builder: (context) {
        return StackDialogBase(
          mainAxisAlignment: MainAxisAlignment.center,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(
                height: 8,
              ),
              Text(
                "Delete wallet",
                style: STextStyles.titleH3(context).copyWith(
                  color: Theme.of(context).extension<StackColors>()!.textMedium,
                ),
              ),
              const SizedBox(
                height: 16,
              ),
              RichText(
                text: TextSpan(
                  style: STextStyles.bodyBold(context),
                  children: [
                    const TextSpan(text: "You are about to delete "),
                    TextSpan(
                      text: "My Wallet",
                      style: STextStyles.bodyBold(context).copyWith(
                        color: Theme.of(context)
                            .extension<StackColors>()!
                            .textGold,
                      ),
                    ),
                    const TextSpan(text: ". Are you sure you want to do that?"),
                  ],
                ),
              ),
              const SizedBox(
                height: 48,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  GestureDetector(
                    onTap: Navigator.of(context).pop,
                    child: Container(
                      color: Colors.transparent,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          "CANCEL",
                          style: STextStyles.buttonText(context),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(
                    width: 5,
                  ),
                  GestureDetector(
                    onTap: () async {
                      final navigator = Navigator.of(context);
                      final mnemonic = await ref.read(walletProvider)!.mnemonic;

                      // pop dialog before pushing next view
                      navigator.pop();
                      await navigator.push(
                        RouteGenerator.getRoute(
                          shouldUseMaterialRoute:
                              RouteGenerator.useMaterialPageRoute,
                          builder: (_) => LockscreenView(
                            routeOnSuccessArguments: mnemonic,
                            showBackButton: true,
                            routeOnSuccess:
                                DeleteWalletRecoveryPhraseView.routeName,
                            biometricsCancelButtonString: "CANCEL",
                            biometricsLocalizedReason:
                                "Authenticate to delete wallet",
                            biometricsAuthenticationTitle: "Delete wallet",
                          ),
                          settings: const RouteSettings(
                              name: "/deleteWalletLockscreen"),
                        ),
                      );
                    },
                    child: Container(
                      color: Colors.transparent,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          "YES, DELETE",
                          style: STextStyles.buttonText(context).copyWith(
                            color: Theme.of(context)
                                .extension<StackColors>()!
                                .textGold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

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
          centerTitle: true,
          title: Text(
            "Wallet Settings",
            style: STextStyles.titleH4(context),
          ),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(
              top: 24,
              left: 24,
              right: 24,
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  GestureDetector(
                    onTap: () {
                      requestDelete(context, ref);
                    },
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            color: Colors.transparent,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              child: Text(
                                "Delete wallet",
                                style: STextStyles.bodyBold(context),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

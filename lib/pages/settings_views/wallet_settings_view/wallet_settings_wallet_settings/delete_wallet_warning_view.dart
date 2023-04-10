import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stackwallet/pages/settings_views/wallet_settings_view/wallet_settings_wallet_settings/delete_wallet_recovery_phrase_view.dart';
import 'package:stackwallet/providers/providers.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';
import 'package:stackwallet/widgets/background.dart';
import 'package:stackwallet/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:stackwallet/widgets/rounded_container.dart';
import 'package:tuple/tuple.dart';

class DeleteWalletWarningView extends ConsumerWidget {
  const DeleteWalletWarningView({
    Key? key,
    required this.walletId,
  }) : super(key: key);

  static const String routeName = "/deleteWalletWarning";

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
        ),
        body: Padding(
          padding: const EdgeInsets.only(
            top: 12,
            left: 16,
            right: 16,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(
                height: 32,
              ),
              Center(
                child: Text(
                  "Attention!",
                  style: STextStyles.pageTitleH1(context),
                ),
              ),
              const SizedBox(
                height: 16,
              ),
              RoundedContainer(
                color: Theme.of(context)
                    .extension<StackColors>()!
                    .warningBackground,
                child: Text(
                  "You are going to permanently delete your wallet.\n\nIf you delete your wallet, the only way you can have access to your funds is by using your backup key.\n\nStack Wallet does not keep nor is able to restore your backup key or your wallet.\n\nPLEASE SAVE YOUR BACKUP KEY.",
                  style: STextStyles.baseXS(context).copyWith(
                    color: Theme.of(context)
                        .extension<StackColors>()!
                        .warningForeground,
                  ),
                ),
              ),
              const Spacer(),
              TextButton(
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
              const SizedBox(
                height: 12,
              ),
              TextButton(
                style: Theme.of(context)
                    .extension<StackColors>()!
                    .getPrimaryEnabledButtonStyle(context),
                onPressed: () async {
                  final manager = ref
                      .read(walletsChangeNotifierProvider)
                      .getManager(walletId);
                  final mnemonic = await manager.mnemonic;
                  Navigator.of(context).pushNamed(
                    DeleteWalletRecoveryPhraseView.routeName,
                    arguments: Tuple2(
                      manager,
                      mnemonic,
                    ),
                  );
                },
                child: Text(
                  "View Backup Key",
                  style: STextStyles.button(context),
                ),
              ),
              const SizedBox(
                height: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

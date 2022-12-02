import 'package:epicmobile/pages/settings_views/wallet_settings_view/wallet_settings_wallet_settings/delete_wallet_recovery_phrase_view.dart';
import 'package:epicmobile/providers/providers.dart';
import 'package:epicmobile/utilities/text_styles.dart';
import 'package:epicmobile/utilities/theme/stack_colors.dart';
import 'package:epicmobile/widgets/background.dart';
import 'package:epicmobile/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:epicmobile/widgets/rounded_container.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
                  "You are going to permanently delete you wallet.\n\nIf you delete your wallet, the only way you can have access to your funds is by using your backup key.\n\nEpic Mobile does not keep nor is able to restore your backup key or your wallet.\n\nPLEASE SAVE YOUR BACKUP KEY.",
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
              const SizedBox(
                height: 12,
              ),
              TextButton(
                style: Theme.of(context)
                    .extension<StackColors>()!
                    .getPrimaryEnabledButtonColor(context),
                onPressed: () async {
                  final manager = ref.read(walletProvider)!;
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

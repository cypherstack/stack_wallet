import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stackwallet/pages/add_wallet_views/create_or_restore_wallet_view/create_or_restore_wallet_view.dart';
import 'package:stackwallet/providers/providers.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';

class AddWalletNextButton extends ConsumerWidget {
  const AddWalletNextButton({
    Key? key,
    required this.isDesktop,
  }) : super(key: key);

  final bool isDesktop;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    debugPrint("BUILD: NextButton");
    final selectedCoin =
        ref.watch(addWalletSelectedCoinStateProvider.state).state;

    final enabled = selectedCoin != null;

    return TextButton(
      onPressed: !enabled
          ? null
          : () {
              final selectedCoin =
                  ref.read(addWalletSelectedCoinStateProvider.state).state;

              //todo: check if print needed
              // debugPrint("Next pressed with ${selectedCoin!.name} selected!");
              Navigator.of(context).pushNamed(
                CreateOrRestoreWalletView.routeName,
                arguments: selectedCoin,
              );
            },
      style: enabled
          ? Theme.of(context)
              .extension<StackColors>()!
              .getPrimaryEnabledButtonStyle(context)
          : Theme.of(context)
              .extension<StackColors>()!
              .getPrimaryDisabledButtonStyle(context),
      child: Text(
        "Next",
        style: isDesktop
            ? enabled
                ? STextStyles.desktopButtonEnabled(context)
                : STextStyles.desktopButtonDisabled(context)
            : STextStyles.button(context),
      ),
    );
  }
}

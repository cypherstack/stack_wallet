import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stackwallet/providers/wallet/wallet_balance_toggle_state_provider.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/constants.dart';
import 'package:stackwallet/utilities/enums/wallet_balance_toggle_state.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';

class DesktopBalanceToggleButton extends ConsumerWidget {
  const DesktopBalanceToggleButton({
    Key? key,
    this.onPressed,
  }) : super(key: key);

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      height: 22,
      width: 22,
      child: MaterialButton(
        color: Theme.of(context).extension<StackColors>()!.buttonBackSecondary,
        splashColor: Theme.of(context).extension<StackColors>()!.highlight,
        onPressed: () {
          if (ref.read(walletBalanceToggleStateProvider.state).state ==
              WalletBalanceToggleState.available) {
            ref.read(walletBalanceToggleStateProvider.state).state =
                WalletBalanceToggleState.full;
          } else {
            ref.read(walletBalanceToggleStateProvider.state).state =
                WalletBalanceToggleState.available;
          }
          onPressed?.call();
        },
        elevation: 0,
        highlightElevation: 0,
        hoverElevation: 0,
        padding: EdgeInsets.zero,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            Constants.size.circularBorderRadius,
          ),
        ),
        child: Center(
          child: Image(
            image: AssetImage(
              ref.watch(walletBalanceToggleStateProvider.state).state ==
                      WalletBalanceToggleState.available
                  ? Assets.png.glassesHidden
                  : Assets.png.glasses,
            ),
            width: 16,
          ),
        ),
      ),
    );
  }
}

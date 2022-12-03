import 'package:epicmobile/providers/wallet/wallet_balance_toggle_state_provider.dart';
import 'package:epicmobile/utilities/constants.dart';
import 'package:epicmobile/utilities/enums/wallet_balance_toggle_state.dart';
import 'package:epicmobile/utilities/text_styles.dart';
import 'package:epicmobile/utilities/theme/stack_colors.dart';
import 'package:epicmobile/widgets/rounded_container.dart';
import 'package:epicmobile/widgets/stack_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class WalletBalanceToggleDialog extends ConsumerWidget {
  const WalletBalanceToggleDialog({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return StackDialogBase(
      mainAxisAlignment: MainAxisAlignment.center,
      padding: const EdgeInsets.all(0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 20,
              horizontal: 16,
            ),
            child: RawMaterialButton(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  Constants.size.circularBorderRadius,
                ),
              ),
              onPressed: () {
                final state =
                    ref.read(walletBalanceToggleStateProvider.state).state;
                if (state != WalletBalanceToggleState.available) {
                  ref.read(walletBalanceToggleStateProvider.state).state =
                      WalletBalanceToggleState.available;
                }
                Navigator.of(context).pop();
              },
              child: Container(
                color: Colors.transparent,
                padding: const EdgeInsets.all(8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Available balance",
                      style: STextStyles.bodyBold(context),
                    ),
                    Stack(
                      children: [
                        RoundedContainer(
                          radiusMultiplier: 20,
                          height: 24,
                          width: 24,
                          color:
                              Theme.of(context).extension<StackColors>()!.coal,
                        ),
                        if (ref
                                .watch(walletBalanceToggleStateProvider.state)
                                .state ==
                            WalletBalanceToggleState.available)
                          Padding(
                            padding: const EdgeInsets.all(4),
                            child: RoundedContainer(
                              radiusMultiplier: 20,
                              height: 16,
                              width: 16,
                              color: Theme.of(context)
                                  .extension<StackColors>()!
                                  .radioButtonIconEnabled,
                            ),
                          )
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          Container(
            color: Theme.of(context).extension<StackColors>()!.coal,
            height: 1,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 20,
              horizontal: 16,
            ),
            child: RawMaterialButton(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  Constants.size.circularBorderRadius,
                ),
              ),
              onPressed: () {
                final state =
                    ref.read(walletBalanceToggleStateProvider.state).state;
                if (state != WalletBalanceToggleState.locked) {
                  ref.read(walletBalanceToggleStateProvider.state).state =
                      WalletBalanceToggleState.locked;
                }
                Navigator.of(context).pop();
              },
              child: Container(
                color: Colors.transparent,
                padding: const EdgeInsets.all(8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Locked balance",
                      style: STextStyles.bodyBold(context),
                    ),
                    Stack(
                      children: [
                        RoundedContainer(
                          radiusMultiplier: 20,
                          height: 24,
                          width: 24,
                          color:
                              Theme.of(context).extension<StackColors>()!.coal,
                        ),
                        if (ref
                                .watch(walletBalanceToggleStateProvider.state)
                                .state ==
                            WalletBalanceToggleState.locked)
                          Padding(
                            padding: const EdgeInsets.all(4),
                            child: RoundedContainer(
                              radiusMultiplier: 20,
                              height: 16,
                              width: 16,
                              color: Theme.of(context)
                                  .extension<StackColors>()!
                                  .radioButtonIconEnabled,
                            ),
                          )
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

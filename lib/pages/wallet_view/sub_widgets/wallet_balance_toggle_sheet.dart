import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stackwallet/providers/providers.dart';
import 'package:stackwallet/providers/wallet/wallet_balance_toggle_state_provider.dart';
import 'package:stackwallet/utilities/constants.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/utilities/enums/wallet_balance_toggle_state.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';

class WalletBalanceToggleSheet extends ConsumerWidget {
  const WalletBalanceToggleSheet({
    Key? key,
    required this.walletId,
  }) : super(key: key);

  final String walletId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final maxHeight = MediaQuery.of(context).size.height * 0.60;

    final coin = ref.watch(walletsChangeNotifierProvider
        .select((value) => value.getManager(walletId).coin));

    Future<Decimal>? totalBalanceFuture;
    Future<Decimal>? availableBalanceFuture;
    final manager = ref.watch(walletsChangeNotifierProvider
        .select((value) => value.getManager(walletId)));
    totalBalanceFuture = Future(() => manager.balance.getTotal());
    availableBalanceFuture = Future(() => manager.balance.getSpendable());

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).extension<StackColors>()!.popupBG,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      child: LimitedBox(
        maxHeight: maxHeight,
        child: Padding(
          padding: const EdgeInsets.only(
            left: 16,
            right: 16,
            top: 10,
            bottom: 0,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .extension<StackColors>()!
                        .textFieldDefaultBG,
                    borderRadius: BorderRadius.circular(
                      Constants.size.circularBorderRadius,
                    ),
                  ),
                  width: 60,
                  height: 4,
                ),
              ),
              const SizedBox(
                height: 36,
              ),
              Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Text(
                  "Wallet balance",
                  style: STextStyles.pageTitleH2(context),
                  textAlign: TextAlign.left,
                ),
              ),
              const SizedBox(
                height: 24,
              ),
              RawMaterialButton(
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
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: Radio(
                          activeColor: Theme.of(context)
                              .extension<StackColors>()!
                              .radioButtonIconEnabled,
                          value: WalletBalanceToggleState.available,
                          groupValue: ref
                              .watch(walletBalanceToggleStateProvider.state)
                              .state,
                          onChanged: (_) {
                            ref
                                .read(walletBalanceToggleStateProvider.state)
                                .state = WalletBalanceToggleState.available;
                            Navigator.of(context).pop();
                          },
                        ),
                      ),
                      const SizedBox(
                        width: 12,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(
                height: 12,
              ),
              RawMaterialButton(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    Constants.size.circularBorderRadius,
                  ),
                ),
                onPressed: () {
                  final state =
                      ref.read(walletBalanceToggleStateProvider.state).state;
                  if (state != WalletBalanceToggleState.full) {
                    ref.read(walletBalanceToggleStateProvider.state).state =
                        WalletBalanceToggleState.full;
                  }
                  Navigator.of(context).pop();
                },
                child: Container(
                  color: Colors.transparent,
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: Radio(
                          activeColor: Theme.of(context)
                              .extension<StackColors>()!
                              .radioButtonIconEnabled,
                          value: WalletBalanceToggleState.full,
                          groupValue: ref
                              .watch(walletBalanceToggleStateProvider.state)
                              .state,
                          onChanged: (_) {
                            ref
                                .read(walletBalanceToggleStateProvider.state)
                                .state = WalletBalanceToggleState.full;
                            Navigator.of(context).pop();
                          },
                        ),
                      ),
                      const SizedBox(
                        width: 12,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(
                height: 40,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:stackwallet/pages/paynym/paynym_claim_view.dart';
import 'package:stackwallet/pages/paynym/paynym_home_view.dart';
import 'package:stackwallet/providers/global/paynym_api_provider.dart';
import 'package:stackwallet/providers/global/wallets_provider.dart';
import 'package:stackwallet/providers/wallet/my_paynym_account_state_provider.dart';
import 'package:stackwallet/services/mixins/paynym_wallet_interface.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/utilities/enums/derive_path_type_enum.dart';
import 'package:stackwallet/utilities/logger.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';
import 'package:stackwallet/widgets/loading_indicator.dart';

class WalletNavigationBar extends ConsumerStatefulWidget {
  const WalletNavigationBar({
    Key? key,
    required this.onReceivePressed,
    required this.onSendPressed,
    required this.onExchangePressed,
    required this.onBuyPressed,
    required this.height,
    required this.enableExchange,
    required this.coin,
    required this.walletId,
  }) : super(key: key);

  final VoidCallback onReceivePressed;
  final VoidCallback onSendPressed;
  final VoidCallback onExchangePressed;
  final VoidCallback onBuyPressed;
  final double height;
  final bool enableExchange;
  final Coin coin;
  final String walletId;

  @override
  ConsumerState<WalletNavigationBar> createState() =>
      _WalletNavigationBarState();
}

class _WalletNavigationBarState extends ConsumerState<WalletNavigationBar> {
  double scale = 0;
  final duration = const Duration(milliseconds: 200);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // const Spacer(),

        AnimatedScale(
          scale: scale,
          duration: duration,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // AnimatedOpacity(
              //   opacity: scale,
              //   duration: duration,
              //   child: GestureDetector(
              //     onTap: () {},
              //     child: Container(
              //       padding: const EdgeInsets.all(16),
              //       width: 146,
              //       decoration: BoxDecoration(
              //         color:
              //             Theme.of(context).extension<StackColors>()!.popupBG,
              //         boxShadow: [
              //           Theme.of(context)
              //               .extension<StackColors>()!
              //               .standardBoxShadow
              //         ],
              //         borderRadius: BorderRadius.circular(
              //           widget.height / 2.0,
              //         ),
              //       ),
              //       child: Row(
              //         mainAxisAlignment: MainAxisAlignment.center,
              //         children: [
              //           Text(
              //             "Whirlpool",
              //             style: STextStyles.w600_12(context),
              //           ),
              //         ],
              //       ),
              //     ),
              //   ),
              // ),
              // const SizedBox(
              //   height: 8,
              // ),
              AnimatedOpacity(
                opacity: scale,
                duration: duration,
                child: Consumer(builder: (context, ref, __) {
                  return GestureDetector(
                    onTap: () async {
                      setState(() {
                        scale = 0;
                      });
                      unawaited(
                        showDialog(
                          context: context,
                          builder: (context) => const LoadingIndicator(
                            width: 100,
                          ),
                        ),
                      );

                      final manager = ref
                          .read(walletsChangeNotifierProvider)
                          .getManager(widget.walletId);

                      final paynymInterface =
                          manager.wallet as PaynymWalletInterface;

                      final code = await paynymInterface.getPaymentCode(
                          DerivePathTypeExt.primaryFor(manager.coin));

                      final account = await ref
                          .read(paynymAPIProvider)
                          .nym(code.toString());

                      Logging.instance.log(
                        "my nym account: $account",
                        level: LogLevel.Info,
                      );

                      if (mounted) {
                        Navigator.of(context).pop();

                        // check if account exists and for matching code to see if claimed
                        if (account.value != null &&
                            account.value!.codes.first.claimed) {
                          ref.read(myPaynymAccountStateProvider.state).state =
                              account.value!;

                          await Navigator.of(context).pushNamed(
                            PaynymHomeView.routeName,
                            arguments: widget.walletId,
                          );
                        } else {
                          await Navigator.of(context).pushNamed(
                            PaynymClaimView.routeName,
                            arguments: widget.walletId,
                          );
                        }
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      width: 146,
                      decoration: BoxDecoration(
                        color:
                            Theme.of(context).extension<StackColors>()!.popupBG,
                        boxShadow: [
                          Theme.of(context)
                              .extension<StackColors>()!
                              .standardBoxShadow
                        ],
                        borderRadius: BorderRadius.circular(
                          widget.height / 2.0,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Paynym",
                            style: STextStyles.w600_12(context),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(
                height: 8,
              ),
            ],
          ),
        ),
        Container(
          height: widget.height,
          decoration: BoxDecoration(
            color: Theme.of(context).extension<StackColors>()!.bottomNavBack,
            boxShadow: [
              Theme.of(context).extension<StackColors>()!.standardBoxShadow
            ],
            borderRadius: BorderRadius.circular(
              widget.height / 2.0,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 6,
              vertical: 4,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                const SizedBox(
                  width: 12,
                ),
                RawMaterialButton(
                  constraints: const BoxConstraints(
                    minWidth: 66,
                  ),
                  onPressed: widget.onReceivePressed,
                  splashColor:
                      Theme.of(context).extension<StackColors>()!.highlight,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      widget.height / 2.0,
                    ),
                  ),
                  child: Container(
                    color: Colors.transparent,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Spacer(),
                          Container(
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .extension<StackColors>()!
                                  .accentColorDark
                                  .withOpacity(0.4),
                              borderRadius: BorderRadius.circular(
                                24,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(6.0),
                              child: SvgPicture.asset(
                                Assets.svg.arrowDownLeft,
                                width: 12,
                                height: 12,
                                color: Theme.of(context)
                                    .extension<StackColors>()!
                                    .accentColorDark,
                              ),
                            ),
                          ),
                          const SizedBox(
                            height: 4,
                          ),
                          Text(
                            "Receive",
                            style: STextStyles.buttonSmall(context),
                          ),
                          const Spacer(),
                        ],
                      ),
                    ),
                  ),
                ),
                RawMaterialButton(
                  constraints: const BoxConstraints(
                    minWidth: 66,
                  ),
                  onPressed: widget.onSendPressed,
                  splashColor:
                      Theme.of(context).extension<StackColors>()!.highlight,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      widget.height / 2.0,
                    ),
                  ),
                  child: Container(
                    color: Colors.transparent,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Spacer(),
                          Container(
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .extension<StackColors>()!
                                  .accentColorDark
                                  .withOpacity(0.4),
                              borderRadius: BorderRadius.circular(
                                24,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(6.0),
                              child: SvgPicture.asset(
                                Assets.svg.arrowUpRight,
                                width: 12,
                                height: 12,
                                color: Theme.of(context)
                                    .extension<StackColors>()!
                                    .accentColorDark,
                              ),
                            ),
                          ),
                          const SizedBox(
                            height: 4,
                          ),
                          Text(
                            "Send",
                            style: STextStyles.buttonSmall(context),
                          ),
                          const Spacer(),
                        ],
                      ),
                    ),
                  ),
                ),
                if (widget.enableExchange)
                  RawMaterialButton(
                    constraints: const BoxConstraints(
                      minWidth: 66,
                    ),
                    onPressed: widget.onExchangePressed,
                    splashColor:
                        Theme.of(context).extension<StackColors>()!.highlight,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        widget.height / 2.0,
                      ),
                    ),
                    child: Container(
                      color: Colors.transparent,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Spacer(),
                            SvgPicture.asset(
                              Assets.svg.exchange(context),
                              width: 24,
                              height: 24,
                            ),
                            const SizedBox(
                              height: 4,
                            ),
                            Text(
                              "Exchange",
                              style: STextStyles.buttonSmall(context),
                            ),
                            const Spacer(),
                          ],
                        ),
                      ),
                    ),
                  ),
                if (ref.watch(walletsChangeNotifierProvider.select((value) =>
                    value.getManager(widget.walletId).hasPaynymSupport)))
                  RawMaterialButton(
                    constraints: const BoxConstraints(
                      minWidth: 66,
                    ),
                    onPressed: () {
                      if (scale == 0) {
                        setState(() {
                          scale = 1;
                        });
                      } else if (scale == 1) {
                        setState(() {
                          scale = 0;
                        });
                      }
                    },
                    splashColor:
                        Theme.of(context).extension<StackColors>()!.highlight,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        widget.height / 2.0,
                      ),
                    ),
                    child: Container(
                      color: Colors.transparent,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Spacer(),
                            const SizedBox(
                              height: 2,
                            ),
                            SvgPicture.asset(
                              Assets.svg.bars,
                              width: 20,
                              height: 20,
                            ),
                            const SizedBox(
                              height: 6,
                            ),
                            Text(
                              "More",
                              style: STextStyles.buttonSmall(context),
                            ),
                            const Spacer(),
                          ],
                        ),
                      ),
                    ),
                  ),
                const SizedBox(
                  width: 12,
                ),
                if (widget.coin.hasBuySupport)
                  RawMaterialButton(
                    constraints: const BoxConstraints(
                      minWidth: 66,
                    ),
                    onPressed: widget.onBuyPressed,
                    splashColor:
                        Theme.of(context).extension<StackColors>()!.highlight,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        widget.height / 2.0,
                      ),
                    ),
                    child: Container(
                      color: Colors.transparent,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Spacer(),
                            SvgPicture.asset(
                              Assets.svg.buy(context),
                              width: 24,
                              height: 24,
                            ),
                            const SizedBox(
                              height: 4,
                            ),
                            Text(
                              "Buy",
                              style: STextStyles.buttonSmall(context),
                            ),
                            const Spacer(),
                          ],
                        ),
                      ),
                    ),
                  ),
                if (widget.coin.hasBuySupport)
                  const SizedBox(
                    width: 12,
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:stackwallet/pages/wallet_view/wallet_view.dart';
import 'package:stackwallet/pages_desktop_specific/my_stack_view/wallet_view/desktop_wallet_view.dart';
import 'package:stackwallet/providers/providers.dart';
import 'package:stackwallet/services/coins/firo/firo_wallet.dart';
import 'package:stackwallet/themes/coin_icon_provider.dart';
import 'package:stackwallet/themes/stack_colors.dart';
import 'package:stackwallet/utilities/amount/amount.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/constants.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/util.dart';
import 'package:stackwallet/widgets/conditional_parent.dart';
import 'package:tuple/tuple.dart';

class FavoriteCard extends ConsumerStatefulWidget {
  const FavoriteCard({
    Key? key,
    required this.walletId,
    required this.width,
    required this.height,
  }) : super(key: key);

  final String walletId;
  final double width;
  final double height;

  @override
  ConsumerState<FavoriteCard> createState() => _FavoriteCardState();
}

class _FavoriteCardState extends ConsumerState<FavoriteCard> {
  late final String walletId;

  @override
  void initState() {
    walletId = widget.walletId;

    super.initState();
  }

  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final coin = ref.watch(
      walletsChangeNotifierProvider
          .select((value) => value.getManager(walletId).coin),
    );
    final externalCalls = ref.watch(
      prefsChangeNotifierProvider.select((value) => value.externalCalls),
    );

    return ConditionalParent(
      condition: Util.isDesktop,
      builder: (child) => MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) {
          setState(() {
            _hovering = true;
          });
        },
        onExit: (_) {
          setState(() {
            _hovering = false;
          });
        },
        child: AnimatedScale(
          duration: const Duration(milliseconds: 200),
          scale: _hovering ? 1.05 : 1,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: _hovering
                ? BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(
                      Constants.size.circularBorderRadius,
                    ),
                    boxShadow: [
                      Theme.of(context)
                          .extension<StackColors>()!
                          .standardBoxShadow,
                      Theme.of(context)
                          .extension<StackColors>()!
                          .standardBoxShadow,
                      Theme.of(context)
                          .extension<StackColors>()!
                          .standardBoxShadow,
                    ],
                  )
                : BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(
                      Constants.size.circularBorderRadius,
                    ),
                  ),
            child: child,
          ),
        ),
      ),
      child: GestureDetector(
        onTap: () async {
          if (coin == Coin.monero || coin == Coin.wownero) {
            await ref
                .read(walletsChangeNotifierProvider)
                .getManager(walletId)
                .initializeExisting();
          }
          if (mounted) {
            if (Util.isDesktop) {
              await Navigator.of(context).pushNamed(
                DesktopWalletView.routeName,
                arguments: walletId,
              );
            } else {
              await Navigator.of(context).pushNamed(
                WalletView.routeName,
                arguments: Tuple2(
                  walletId,
                  ref
                      .read(walletsChangeNotifierProvider)
                      .getManagerProvider(walletId),
                ),
              );
            }
          }
        },
        child: SizedBox(
          width: widget.width,
          height: widget.height,
          child: CardOverlayStack(
            background: Stack(
              children: [
                Container(
                  width: widget.width,
                  height: widget.height,
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .extension<StackColors>()!
                        .colorForCoin(coin),
                    borderRadius: BorderRadius.circular(
                      Constants.size.circularBorderRadius,
                    ),
                  ),
                ),
                Column(
                  children: [
                    const Spacer(),
                    SizedBox(
                      height: widget.width * 0.3,
                      child: Row(
                        children: [
                          const Spacer(
                            flex: 9,
                          ),
                          SvgPicture.asset(
                            Assets.svg.ellipse2,
                            height: widget.width * 0.3,
                          ),
                          // ),
                          const Spacer(
                            flex: 2,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    const Spacer(
                      flex: 5,
                    ),
                    SizedBox(
                      width: widget.width * 0.45,
                      child: Column(
                        children: [
                          SvgPicture.asset(
                            Assets.svg.ellipse1,
                            width: widget.width * 0.45,
                          ),
                          const Spacer(),
                        ],
                      ),
                    ),
                    const Spacer(
                      flex: 1,
                    ),
                  ],
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            ref.watch(
                              walletsChangeNotifierProvider.select(
                                (value) =>
                                    value.getManager(walletId).walletName,
                              ),
                            ),
                            style: STextStyles.itemSubtitle12(context).copyWith(
                              color: Theme.of(context)
                                  .extension<StackColors>()!
                                  .textFavoriteCard,
                            ),
                            overflow: TextOverflow.fade,
                          ),
                        ),
                        SvgPicture.file(
                          File(
                            ref.watch(coinIconProvider(coin)),
                          ),
                          width: 24,
                          height: 24,
                        ),
                      ],
                    ),
                  ),
                  Builder(
                    builder: (context) {
                      final balance = ref.watch(
                        walletsChangeNotifierProvider.select(
                          (value) => value.getManager(walletId).balance,
                        ),
                      );

                      Amount total = balance.total;
                      if (coin == Coin.firo || coin == Coin.firoTestNet) {
                        final balancePrivate = ref.watch(
                          walletsChangeNotifierProvider.select(
                            (value) => (value.getManager(walletId).wallet
                                    as FiroWallet)
                                .balancePrivate,
                          ),
                        );

                        total += balancePrivate.total;
                      }

                      Amount fiatTotal = Amount.zero;

                      if (externalCalls && total > Amount.zero) {
                        fiatTotal = (total.decimal *
                                ref
                                    .watch(
                                      priceAnd24hChangeNotifierProvider.select(
                                        (value) => value.getPrice(coin),
                                      ),
                                    )
                                    .item1)
                            .toAmount(fractionDigits: 2);
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              "${total.localizedStringAsFixed(
                                locale: ref.watch(
                                  localeServiceChangeNotifierProvider.select(
                                    (value) => value.locale,
                                  ),
                                ),
                                decimalPlaces: coin.decimals,
                              )} ${coin.ticker}",
                              style: STextStyles.titleBold12(context).copyWith(
                                fontSize: 16,
                                color: Theme.of(context)
                                    .extension<StackColors>()!
                                    .textFavoriteCard,
                              ),
                            ),
                          ),
                          if (externalCalls)
                            const SizedBox(
                              height: 4,
                            ),
                          if (externalCalls)
                            Text(
                              "${fiatTotal.localizedStringAsFixed(
                                locale: ref.watch(
                                  localeServiceChangeNotifierProvider.select(
                                    (value) => value.locale,
                                  ),
                                ),
                                decimalPlaces: 2,
                              )} ${ref.watch(
                                prefsChangeNotifierProvider.select(
                                  (value) => value.currency,
                                ),
                              )}",
                              style:
                                  STextStyles.itemSubtitle12(context).copyWith(
                                fontSize: 10,
                                color: Theme.of(context)
                                    .extension<StackColors>()!
                                    .textFavoriteCard,
                              ),
                            ),
                        ],
                      );
                    },
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

class CardOverlayStack extends StatelessWidget {
  const CardOverlayStack(
      {Key? key, required this.background, required this.child})
      : super(key: key);

  final Widget background;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        background,
        child,
      ],
    );
  }
}

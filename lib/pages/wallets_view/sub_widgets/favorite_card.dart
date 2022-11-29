import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:stackwallet/pages/wallet_view/wallet_view.dart';
import 'package:stackwallet/pages_desktop_specific/home/my_stack_view/wallet_view/desktop_wallet_view.dart';
import 'package:stackwallet/providers/providers.dart';
import 'package:stackwallet/services/coins/manager.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/constants.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/utilities/format.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';
import 'package:stackwallet/utilities/util.dart';
import 'package:stackwallet/widgets/conditional_parent.dart';
import 'package:tuple/tuple.dart';

class FavoriteCard extends ConsumerStatefulWidget {
  const FavoriteCard({
    Key? key,
    required this.walletId,
    required this.width,
    required this.height,
    required this.managerProvider,
  }) : super(key: key);

  final String walletId;
  final double width;
  final double height;
  final ChangeNotifierProvider<Manager> managerProvider;

  @override
  ConsumerState<FavoriteCard> createState() => _FavoriteCardState();
}

class _FavoriteCardState extends ConsumerState<FavoriteCard> {
  late final String walletId;
  late final ChangeNotifierProvider<Manager> managerProvider;

  Decimal _cachedBalance = Decimal.zero;
  Decimal _cachedFiatValue = Decimal.zero;

  @override
  void initState() {
    walletId = widget.walletId;
    managerProvider = widget.managerProvider;

    super.initState();
  }

  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final coin = ref.watch(managerProvider.select((value) => value.coin));
    final externalCalls = ref.watch(
        prefsChangeNotifierProvider.select((value) => value.externalCalls));

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
        onTap: () {
          if (Util.isDesktop) {
            Navigator.of(context).pushNamed(
              DesktopWalletView.routeName,
              arguments: walletId,
            );
          } else {
            Navigator.of(context).pushNamed(
              WalletView.routeName,
              arguments: Tuple2(
                walletId,
                managerProvider,
              ),
            );
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
                            ref.watch(managerProvider
                                .select((value) => value.walletName)),
                            style: STextStyles.itemSubtitle12(context).copyWith(
                              color: Theme.of(context)
                                  .extension<StackColors>()!
                                  .textFavoriteCard,
                            ),
                            overflow: TextOverflow.fade,
                          ),
                        ),
                        SvgPicture.asset(
                          Assets.svg.iconFor(coin: coin),
                          width: 24,
                          height: 24,
                        ),
                      ],
                    ),
                  ),
                  FutureBuilder(
                    future: ref.watch(
                        managerProvider.select((value) => value.totalBalance)),
                    builder: (builderContext, AsyncSnapshot<Decimal> snapshot) {
                      if (snapshot.connectionState == ConnectionState.done &&
                          snapshot.hasData) {
                        if (snapshot.data != null) {
                          _cachedBalance = snapshot.data!;
                          if (externalCalls) {
                            _cachedFiatValue = _cachedBalance *
                                ref
                                    .watch(
                                      priceAnd24hChangeNotifierProvider.select(
                                        (value) => value.getPrice(coin),
                                      ),
                                    )
                                    .item1;
                          }
                        }
                      }
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              "${Format.localizedStringAsFixed(
                                decimalPlaces: 8,
                                value: _cachedBalance,
                                locale: ref.watch(
                                  localeServiceChangeNotifierProvider
                                      .select((value) => value.locale),
                                ),
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
                              "${Format.localizedStringAsFixed(
                                decimalPlaces: 2,
                                value: _cachedFiatValue,
                                locale: ref.watch(
                                  localeServiceChangeNotifierProvider
                                      .select((value) => value.locale),
                                ),
                              )} ${ref.watch(
                                prefsChangeNotifierProvider
                                    .select((value) => value.currency),
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

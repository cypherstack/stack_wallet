import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';
import 'package:stackwallet/widgets/wallet_navigation_bar/components/wallet_navigation_bar_item.dart';

const _kMaxItems = 5;

final walletNavBarMore = StateProvider.autoDispose((ref) => false);

class WalletNavigationBar extends ConsumerStatefulWidget {
  const WalletNavigationBar({
    Key? key,
    required this.items,
  }) : super(key: key);

  final List<WalletNavigationBarItemData> items;

  @override
  ConsumerState<WalletNavigationBar> createState() =>
      _WalletNavigationBarState();
}

class _WalletNavigationBarState extends ConsumerState<WalletNavigationBar> {
  static const double horizontalPadding = 16;

  final _moreDuration = const Duration(milliseconds: 200);

  late final bool hasMore;

  double _moreScale = 0;

  void _onMorePressed() {
    ref.read(walletNavBarMore.state).state =
        !ref.read(walletNavBarMore.state).state;
  }

  @override
  void initState() {
    hasMore = widget.items.length > _kMaxItems;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        IgnorePointer(
          ignoring: !ref.read(walletNavBarMore.state).state,
          child: GestureDetector(
            onTap: () {
              if (ref.read(walletNavBarMore.state).state) {
                ref.read(walletNavBarMore.state).state = false;
              }
            },
            child: AnimatedOpacity(
              opacity: ref.watch(walletNavBarMore.state).state ? 1 : 0,
              duration: _moreDuration,
              child: Container(
                color: Colors.black.withOpacity(0.7),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(
            left: horizontalPadding,
            right: horizontalPadding,
            bottom: horizontalPadding,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedScale(
                    scale: ref.watch(walletNavBarMore.state).state ? 1 : 0,
                    duration: _moreDuration,
                    alignment: const Alignment(
                      0.5,
                      1.0,
                    ),
                    child: AnimatedOpacity(
                      opacity: ref.watch(walletNavBarMore.state).state ? 1 : 0,
                      duration: _moreDuration,
                      child: IntrinsicWidth(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ...widget.items.sublist(_kMaxItems - 1).map(
                              (e) {
                                return Column(
                                  children: [
                                    WalletNavigationBarMoreItem(data: e),
                                    const SizedBox(
                                      height: 8,
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
                  Material(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        1000,
                      ),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .extension<StackColors>()!
                            .bottomNavBack,
                        boxShadow: [
                          Theme.of(context)
                              .extension<StackColors>()!
                              .standardBoxShadow
                        ],
                        borderRadius: BorderRadius.circular(
                          1000,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 6,
                          horizontal: 12,
                        ),
                        child: IntrinsicWidth(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Spacer(),
                              if (!hasMore)
                                ...widget.items.map(
                                  (e) => Flexible(
                                    flex: 10000,
                                    child: WalletNavigationBarItem(
                                      data: e,
                                      disableDuration: _moreDuration,
                                    ),
                                  ),
                                ),
                              if (hasMore)
                                ...widget.items.sublist(0, _kMaxItems - 1).map(
                                      (e) => Flexible(
                                        flex: 10000,
                                        child: WalletNavigationBarItem(
                                          data: e,
                                          disableDuration: _moreDuration,
                                        ),
                                      ),
                                    ),
                              if (hasMore)
                                Flexible(
                                  flex: 10000,
                                  child: WalletNavigationBarItem(
                                    data: WalletNavigationBarItemData(
                                      icon: AnimatedCrossFade(
                                        firstChild: SvgPicture.asset(
                                          Assets.svg.bars,
                                          width: 20,
                                          height: 20,
                                          color: Theme.of(context)
                                              .extension<StackColors>()!
                                              .bottomNavIconIcon,
                                        ),
                                        secondChild: SvgPicture.asset(
                                          Assets.svg.bars,
                                          width: 20,
                                          height: 20,
                                          color: Theme.of(context)
                                              .extension<StackColors>()!
                                              .infoItemIcons,
                                        ),
                                        crossFadeState: ref
                                                .watch(walletNavBarMore.state)
                                                .state
                                            ? CrossFadeState.showSecond
                                            : CrossFadeState.showFirst,
                                        duration: _moreDuration,
                                      ),
                                      overrideText: AnimatedCrossFade(
                                        firstChild: Text(
                                          "More",
                                          style:
                                              STextStyles.buttonSmall(context),
                                        ),
                                        secondChild: Text(
                                          "More",
                                          style:
                                              STextStyles.buttonSmall(context)
                                                  .copyWith(
                                            color: Theme.of(context)
                                                .extension<StackColors>()!
                                                .infoItemIcons,
                                          ),
                                        ),
                                        crossFadeState: ref
                                                .watch(walletNavBarMore.state)
                                                .state
                                            ? CrossFadeState.showSecond
                                            : CrossFadeState.showFirst,
                                        duration: _moreDuration,
                                      ),
                                      label: null,
                                      isMore: true,
                                      onTap: _onMorePressed,
                                    ),
                                    disableDuration: _moreDuration,
                                  ),
                                ),
                              const Spacer(),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

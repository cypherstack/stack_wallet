import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:stackduo/utilities/assets.dart';
import 'package:stackduo/utilities/text_styles.dart';
import 'package:stackduo/utilities/theme/stack_colors.dart';
import 'package:stackduo/widgets/conditional_parent.dart';
import 'package:stackduo/widgets/wallet_navigation_bar/components/wallet_navigation_bar_item.dart';

final walletNavBarMore = StateProvider.autoDispose((ref) => false);

class WalletNavigationBar extends ConsumerStatefulWidget {
  const WalletNavigationBar({
    Key? key,
    required this.items,
    required this.moreItems,
  }) : super(key: key);

  final List<WalletNavigationBarItemData> items;
  final List<WalletNavigationBarItemData> moreItems;

  @override
  ConsumerState<WalletNavigationBar> createState() =>
      _WalletNavigationBarState();
}

class _WalletNavigationBarState extends ConsumerState<WalletNavigationBar> {
  static const double horizontalPadding = 16;

  final _moreDuration = const Duration(milliseconds: 200);

  void _onMorePressed() {
    ref.read(walletNavBarMore.state).state =
        !ref.read(walletNavBarMore.state).state;
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width - 40;

    final hasMore = widget.moreItems.isNotEmpty;
    final buttonCount = widget.items.length + (hasMore ? 1 : 0);

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
                            ...widget.moreItems.map(
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
                          horizontal: 20,
                        ),
                        // child: IntrinsicWidth(
                        child: ConditionalParent(
                          condition: buttonCount > 4,
                          builder: (child) => SizedBox(
                            width: width * 0.9,
                            child: child,
                          ),
                          child: ConditionalParent(
                            condition: buttonCount <= 4,
                            builder: (child) => SizedBox(
                              width: width * 0.2 * buttonCount,
                              child: child,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                ...widget.items.map(
                                  (e) => Expanded(
                                    child: WalletNavigationBarItem(
                                      data: e,
                                      disableDuration: _moreDuration,
                                    ),
                                  ),
                                ),
                                if (hasMore)
                                  Expanded(
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
                                            style: STextStyles.buttonSmall(
                                                context),
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
                              ],
                            ),
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

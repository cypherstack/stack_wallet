import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:stackduo/pages/manage_favorites_view/manage_favorites_view.dart';
import 'package:stackduo/pages/wallets_view/sub_widgets/favorite_card.dart';
import 'package:stackduo/providers/providers.dart';
import 'package:stackduo/services/coins/manager.dart';
import 'package:stackduo/utilities/assets.dart';
import 'package:stackduo/utilities/constants.dart';
import 'package:stackduo/utilities/text_styles.dart';
import 'package:stackduo/utilities/theme/stack_colors.dart';
import 'package:stackduo/widgets/custom_page_view/custom_page_view.dart' as cpv;

class FavoriteWallets extends ConsumerStatefulWidget {
  const FavoriteWallets({Key? key}) : super(key: key);

  @override
  ConsumerState<FavoriteWallets> createState() => _FavoriteWalletsState();
}

class _FavoriteWalletsState extends ConsumerState<FavoriteWallets> {
  int _focusedIndex = 0;

  static const cardWidth = 220.0;
  static const cardHeight = 125.0;

  late final cpv.PageController _pageController;
  late final double screenWidth;
  late final double viewportFraction;

  int _favLength = 0;

  static const standardPadding = 16.0;

  @override
  void initState() {
    screenWidth = (window.physicalSize.shortestSide / window.devicePixelRatio);
    viewportFraction = cardWidth / screenWidth;

    _pageController = cpv.PageController(
      viewportFraction: viewportFraction,
    );

    _pageController.addListener(() {
      if (_pageController.position.pixels > (cardWidth * (_favLength - 1))) {
        _pageController.animateToPage(_favLength - 1,
            duration: const Duration(milliseconds: 1),
            curve: Curves.decelerate);
      }
    });
    super.initState();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint("BUILD: $runtimeType");

    final favorites = ref.watch(favoritesProvider);
    _favLength = favorites.length;

    bool hasFavorites = favorites.length > 0;

    final remaining = ((screenWidth - cardWidth) / cardWidth).ceil();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: standardPadding,
          ),
          child: Row(
            children: [
              Text(
                "Favorite Wallets",
                style: STextStyles.itemSubtitle(context).copyWith(
                  color: Theme.of(context).extension<StackColors>()!.textDark3,
                ),
              ),
              const Spacer(),
              if (hasFavorites)
                TextButton(
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all<Color>(
                        Theme.of(context).extension<StackColors>()!.background),
                  ),
                  child: SvgPicture.asset(
                    Assets.svg.ellipsis,
                    width: 16,
                    height: 16,
                    color: Theme.of(context)
                        .extension<StackColors>()!
                        .accentColorDark,
                  ),
                  onPressed: () {
                    Navigator.of(context).pushNamed(
                      ManageFavoritesView.routeName,
                    );
                  },
                ),
            ],
          ),
        ),
        const SizedBox(
          height: 20,
        ),
        !hasFavorites
            ? Padding(
                padding: const EdgeInsets.only(
                  left: standardPadding,
                ),
                child: Container(
                  height: cardHeight,
                  width: cardWidth,
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .extension<StackColors>()!
                        .textFieldDefaultBG,
                    borderRadius: BorderRadius.circular(
                        Constants.size.circularBorderRadius),
                  ),
                  child: MaterialButton(
                    splashColor:
                        Theme.of(context).extension<StackColors>()!.highlight,
                    key: const Key("favoriteWalletsAddFavoriteButtonKey"),
                    padding: const EdgeInsets.all(12),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                          Constants.size.circularBorderRadius),
                    ),
                    onPressed: () {
                      Navigator.of(context)
                          .pushNamed(ManageFavoritesView.routeName);
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SvgPicture.asset(
                          Assets.svg.plus,
                          width: 8,
                          height: 8,
                          color: Theme.of(context)
                              .extension<StackColors>()!
                              .textSubtitle1,
                        ),
                        const SizedBox(
                          width: 4,
                        ),
                        Text(
                          "Add a favorite",
                          style: STextStyles.itemSubtitle(context).copyWith(
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            : SizedBox(
                height: cardHeight,
                width: screenWidth,
                child: cpv.CustomPageView.builder(
                  padEnds: false,
                  pageSnapping: true,
                  itemCount: favorites.length + remaining,
                  controller: _pageController,
                  viewportFractionalPadding:
                      standardPadding / MediaQuery.of(context).size.width,
                  onPageChanged: (int index) => setState(() {
                    _focusedIndex = index;
                  }),
                  itemBuilder: (_, index) {
                    String? walletId;
                    ChangeNotifierProvider<Manager>? managerProvider;

                    if (index < favorites.length) {
                      walletId = ref.read(favorites[index]).walletId;
                      managerProvider = ref
                          .read(walletsChangeNotifierProvider)
                          .getManagerProvider(walletId);
                    }

                    const double scaleDown = 0.95;
                    const int milliseconds = 333;

                    return AnimatedScale(
                      scale: index == _focusedIndex ? 1.0 : scaleDown,
                      duration: const Duration(milliseconds: milliseconds),
                      curve: Curves.decelerate,
                      child: AnimatedOpacity(
                        opacity: index == _focusedIndex ? 1 : 0.45,
                        duration: const Duration(milliseconds: milliseconds),
                        curve: Curves.decelerate,
                        child: index < favorites.length
                            ? index == _focusedIndex
                                ? Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                    ),
                                    child: FavoriteCard(
                                      key: Key("favCard_$walletId"),
                                      walletId: walletId!,
                                      managerProvider: managerProvider!,
                                      width: cardWidth,
                                      height: cardHeight,
                                    ),
                                  )
                                : FavoriteCard(
                                    key: Key("favCard_$walletId"),
                                    walletId: walletId!,
                                    managerProvider: managerProvider!,
                                    width: cardWidth,
                                    height: cardHeight,
                                  )
                            : Container(),
                      ),
                    );
                  },
                ),
              ),
      ],
    );
  }
}

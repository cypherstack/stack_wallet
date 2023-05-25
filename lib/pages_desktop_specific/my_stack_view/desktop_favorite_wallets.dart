import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:stackwallet/pages/manage_favorites_view/manage_favorites_view.dart';
import 'package:stackwallet/pages/wallets_view/sub_widgets/favorite_card.dart';
import 'package:stackwallet/providers/providers.dart';
import 'package:stackwallet/themes/stack_colors.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/constants.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/widgets/custom_buttons/blue_text_button.dart';

class DesktopFavoriteWallets extends ConsumerWidget {
  const DesktopFavoriteWallets({Key? key}) : super(key: key);

  static const cardWidth = 220.0;
  static const cardHeight = 125.0;
  static const standardPadding = 16.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    debugPrint("BUILD: $runtimeType");

    final favorites = ref.watch(favoritesProvider);
    bool hasFavorites = favorites.length > 0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Favorite wallets",
              style: STextStyles.desktopTextExtraSmall(context).copyWith(
                color: Theme.of(context)
                    .extension<StackColors>()!
                    .textFieldActiveSearchIconRight,
              ),
            ),
            CustomTextButton(
              text: "Edit",
              onTap: () {
                Navigator.of(context).pushNamed(ManageFavoritesView.routeName);
              },
            ),
          ],
        ),
        const SizedBox(
          height: 20,
        ),
        ConstrainedBox(
          constraints: const BoxConstraints(
            maxHeight: (cardHeight * 2) + standardPadding,
            minHeight: cardHeight,
          ),
          child: hasFavorites
              ? SingleChildScrollView(
                  primary: false,
                  child: Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      ...favorites.map((p0) {
                        final walletId = ref.read(p0).walletId;
                        final walletName = ref.read(p0).walletName;
                        final managerProvider = ref
                            .read(walletsChangeNotifierProvider)
                            .getManagerProvider(walletId);

                        return FavoriteCard(
                          walletId: walletId,
                          key: Key(walletName),
                          width: cardWidth,
                          height: cardHeight,
                        );
                      })
                    ],
                  ),
                )
              : Container(
                  height: cardHeight,
                  width: cardWidth,
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .extension<StackColors>()!
                        .textFieldDefaultBG,
                    borderRadius: BorderRadius.circular(
                      Constants.size.circularBorderRadius,
                    ),
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
                          width: 14,
                          height: 14,
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
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        ),
        const SizedBox(
          height: 40,
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:stackwallet/providers/providers.dart';
import 'package:stackwallet/themes/stack_colors.dart';
import 'package:stackwallet/themes/coin_icon_provider.dart';
import 'package:stackwallet/utilities/constants.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/util.dart';
import 'package:stackwallet/widgets/custom_buttons/favorite_toggle.dart';
import 'package:stackwallet/widgets/rounded_white_container.dart';

class ManagedFavorite extends ConsumerStatefulWidget {
  const ManagedFavorite({
    Key? key,
    required this.walletId,
  }) : super(key: key);

  final String walletId;

  @override
  ConsumerState<ManagedFavorite> createState() => _ManagedFavoriteCardState();
}

class _ManagedFavoriteCardState extends ConsumerState<ManagedFavorite> {
  @override
  Widget build(BuildContext context) {
    final manager = ref.watch(walletsChangeNotifierProvider
        .select((value) => value.getManager(widget.walletId)));
    debugPrint("BUILD: $runtimeType with walletId ${widget.walletId}");

    final isDesktop = Util.isDesktop;

    return RoundedWhiteContainer(
      padding: EdgeInsets.all(isDesktop ? 0 : 4.0),
      child: RawMaterialButton(
        onPressed: () {
          final provider = ref
              .read(walletsChangeNotifierProvider)
              .getManagerProvider(manager.walletId);
          if (!manager.isFavorite) {
            ref.read(favoritesProvider).add(provider, true);
            ref.read(nonFavoritesProvider).remove(provider, true);
            ref
                .read(walletsServiceChangeNotifierProvider)
                .addFavorite(manager.walletId);
          } else {
            ref.read(favoritesProvider).remove(provider, true);
            ref.read(nonFavoritesProvider).add(provider, true);
            ref
                .read(walletsServiceChangeNotifierProvider)
                .removeFavorite(manager.walletId);
          }

          manager.isFavorite = !manager.isFavorite;
        },
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            Constants.size.circularBorderRadius,
          ),
        ),
        child: Padding(
          padding: isDesktop
              ? const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                )
              : const EdgeInsets.all(8),
          child: Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .extension<StackColors>()!
                      .colorForCoin(manager.coin)
                      .withOpacity(0.5),
                  borderRadius: BorderRadius.circular(
                    Constants.size.circularBorderRadius,
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.all(isDesktop ? 6 : 4),
                  child: SvgPicture.asset(
                    ref.watch(coinIconProvider(manager.coin)),
                    width: 20,
                    height: 20,
                  ),
                ),
              ),
              const SizedBox(
                width: 12,
              ),
              if (isDesktop)
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          manager.walletName,
                          style: STextStyles.titleBold12(context),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          "${manager.balance.total.localizedStringAsFixed(
                            locale: ref.watch(
                              localeServiceChangeNotifierProvider.select(
                                (value) => value.locale,
                              ),
                            ),
                            decimalPlaces: manager.coin.decimals,
                          )} ${manager.coin.ticker}",
                          style: STextStyles.itemSubtitle(context),
                        ),
                      ),
                      Text(
                        manager.isFavorite
                            ? "Remove from favorites"
                            : "Add to favorites",
                        style:
                            STextStyles.desktopTextExtraSmall(context).copyWith(
                          color: manager.isFavorite
                              ? Theme.of(context)
                                  .extension<StackColors>()!
                                  .accentColorRed
                              : Theme.of(context)
                                  .extension<StackColors>()!
                                  .buttonTextBorderless,
                        ),
                      )
                    ],
                  ),
                ),
              if (!isDesktop)
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        manager.walletName,
                        style: STextStyles.titleBold12(context),
                      ),
                      const SizedBox(
                        height: 2,
                      ),
                      Text(
                        "${manager.balance.total.localizedStringAsFixed(
                          locale: ref.watch(
                            localeServiceChangeNotifierProvider.select(
                              (value) => value.locale,
                            ),
                          ),
                          decimalPlaces: manager.coin.decimals,
                        )} ${manager.coin.ticker}",
                        style: STextStyles.itemSubtitle(context),
                      ),
                    ],
                  ),
                ),
              if (!isDesktop)
                FavoriteToggle(
                  borderRadius: BorderRadius.circular(
                    Constants.size.circularBorderRadius,
                  ),
                  initialState: manager.isFavorite,
                  onChanged: null,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

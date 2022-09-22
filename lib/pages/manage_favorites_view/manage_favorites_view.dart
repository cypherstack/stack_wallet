import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stackwallet/providers/providers.dart';
import 'package:stackwallet/utilities/constants.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/theme/stack_theme.dart';
import 'package:stackwallet/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:stackwallet/widgets/managed_favorite.dart';

class ManageFavoritesView extends StatelessWidget {
  const ManageFavoritesView({Key? key}) : super(key: key);

  static const routeName = "/manageFavorites";

  @override
  Widget build(BuildContext context) {
    debugPrint("BUILD: $runtimeType");
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Favorite wallets",
          style: STextStyles.navBarTitle,
        ),
        leading: AppBarBackButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: Container(
        color: StackTheme.instance.color.background,
        child: Padding(
          padding: const EdgeInsets.only(
            left: 12,
            right: 12,
            top: 4,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Container(
                  decoration: BoxDecoration(
                    color: StackTheme.instance.color.popupBG,
                    borderRadius: BorderRadius.circular(
                      Constants.size.circularBorderRadius,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Text(
                      "Drag to change wallet order.",
                      style: STextStyles.label,
                    ),
                  ),
                ),
              ),
              const SizedBox(
                height: 8,
              ),
              Expanded(
                child: Consumer(
                  builder: (_, ref, __) {
                    final favorites = ref.watch(favoritesProvider);
                    return ReorderableListView.builder(
                      key: key,
                      itemCount: favorites.length,
                      itemBuilder: (builderContext, index) {
                        final walletId = ref.read(favorites[index]).walletId;
                        return Padding(
                          key: Key(
                            "manageFavoriteWalletsItem_$walletId",
                          ),
                          padding: const EdgeInsets.all(4.0),
                          child: ManagedFavorite(
                            walletId: walletId,
                          ),
                        );
                      },
                      onReorder: (oldIndex, newIndex) {
                        ref
                            .read(walletsServiceChangeNotifierProvider)
                            .moveFavorite(
                                fromIndex: oldIndex, toIndex: newIndex);

                        ref
                            .read(favoritesProvider)
                            .reorder(oldIndex, newIndex, true);
                      },
                      proxyDecorator: (child, index, animation) {
                        return Material(
                          elevation: 15,
                          color: Colors.transparent,
                          // shadowColor: Colors.red,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.all(
                              Radius.circular(
                                Constants.size.circularBorderRadius * 1.5,
                              ),
                            ),
                          ),
                          child: child,
                        );
                      },
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(
                  top: 30,
                  bottom: 12,
                  left: 4,
                  right: 4,
                ),
                child: Text(
                  "Add to favorites",
                  style: STextStyles.itemSubtitle12.copyWith(
                    color: StackTheme.instance.color.textDark3,
                  ),
                ),
              ),
              Expanded(
                child: Consumer(
                  builder: (_, ref, __) {
                    final nonFavorites = ref.watch(nonFavoritesProvider);

                    return ListView.builder(
                      itemCount: nonFavorites.length,
                      itemBuilder: (buildContext, index) {
                        // final walletId = ref.watch(
                        //     nonFavorites[index].select((value) => value.walletId));
                        final walletId = ref.read(nonFavorites[index]).walletId;
                        return Padding(
                          key: Key(
                            "manageNonFavoriteWalletsItem_$walletId",
                          ),
                          padding: const EdgeInsets.all(4.0),
                          child: ManagedFavorite(
                            walletId: walletId,
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

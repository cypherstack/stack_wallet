import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stackduo/pages/wallets_view/sub_widgets/all_wallets.dart';
import 'package:stackduo/pages/wallets_view/sub_widgets/empty_wallets.dart';
import 'package:stackduo/pages/wallets_view/sub_widgets/favorite_wallets.dart';
import 'package:stackduo/providers/providers.dart';
import 'package:stackduo/providers/ui/color_theme_provider.dart';
import 'package:stackduo/utilities/theme/color_theme.dart';

class WalletsView extends ConsumerWidget {
  const WalletsView({Key? key}) : super(key: key);

  static const routeName = "/wallets";

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    debugPrint("BUILD: $runtimeType");
    final hasWallets = ref.watch(walletsChangeNotifierProvider).hasWallets;

    final showFavorites = ref.watch(prefsChangeNotifierProvider
        .select((value) => value.showFavoriteWallets));

    return SafeArea(
      child: hasWallets
          ? Padding(
              padding: EdgeInsets.only(
                top: ref.watch(colorThemeProvider).themeType ==
                        ThemeType.fruitSorbet
                    ? 6
                    : 20,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (showFavorites) const FavoriteWallets(),
                  if (showFavorites)
                    const SizedBox(
                      height: 20,
                    ),
                  const Expanded(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16,
                      ),
                      child: AllWallets(),
                    ),
                  ),
                ],
              ),
            )
          : const Padding(
              padding: EdgeInsets.only(
                top: 20,
                left: 16,
                right: 16,
              ),
              child: EmptyWallets(),
            ),
    );
  }
}

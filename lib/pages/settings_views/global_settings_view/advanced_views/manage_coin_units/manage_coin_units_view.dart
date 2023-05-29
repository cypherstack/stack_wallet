import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:stackwallet/pages/settings_views/global_settings_view/advanced_views/manage_coin_units/edit_coin_units_view.dart';
import 'package:stackwallet/providers/global/prefs_provider.dart';
import 'package:stackwallet/themes/coin_icon_provider.dart';
import 'package:stackwallet/themes/stack_colors.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/util.dart';
import 'package:stackwallet/widgets/background.dart';
import 'package:stackwallet/widgets/conditional_parent.dart';
import 'package:stackwallet/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:stackwallet/widgets/desktop/desktop_dialog.dart';
import 'package:stackwallet/widgets/desktop/desktop_dialog_close_button.dart';
import 'package:stackwallet/widgets/rounded_white_container.dart';

class ManageCoinUnitsView extends ConsumerWidget {
  const ManageCoinUnitsView({Key? key}) : super(key: key);

  static const String routeName = "/manageCoinUnitsView";

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    bool showTestNet = ref.watch(
      prefsChangeNotifierProvider.select((value) => value.showTestNetCoins),
    );

    final _coins = Coin.values.where((e) => e != Coin.firoTestNet).toList();

    List<Coin> coins = showTestNet
        ? _coins
        : _coins.sublist(0, _coins.length - kTestNetCoinCount);

    return ConditionalParent(
      condition: Util.isDesktop,
      builder: (child) => DesktopDialog(
          child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Units",
                style: STextStyles.desktopH3(context),
              ),
              const DesktopDialogCloseButton(),
            ],
          )
        ],
      )),
      child: ConditionalParent(
        condition: !Util.isDesktop,
        builder: (child) => Background(
          child: Scaffold(
            backgroundColor:
                Theme.of(context).extension<StackColors>()!.background,
            appBar: AppBar(
              leading: AppBarBackButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              title: Text(
                "Units",
                style: STextStyles.navBarTitle(context),
              ),
            ),
            body: child,
          ),
        ),
        child: ListView.separated(
          itemCount: coins.length + 2,
          separatorBuilder: (_, __) => const SizedBox(
            height: 12,
          ),
          itemBuilder: (_, index) {
            if (index == 0) {
              return const SizedBox(height: 0);
            } else if (index > coins.length) {
              return const SizedBox(height: 10);
            }

            final coin = coins[index - 1];
            return Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
              ),
              child: RoundedWhiteContainer(
                onPressed: () {
                  Navigator.of(context).pushNamed(
                    EditCoinUnitsView.routeName,
                    arguments: coin,
                  );
                },
                child: Row(
                  children: [
                    SvgPicture.file(
                      File(
                        ref.watch(
                          coinIconProvider(coin),
                        ),
                      ),
                      width: 24,
                      height: 24,
                    ),
                    const SizedBox(
                      width: 12,
                    ),
                    Text(
                      "Edit ${coin.prettyName} units",
                      style: STextStyles.titleBold12(context),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

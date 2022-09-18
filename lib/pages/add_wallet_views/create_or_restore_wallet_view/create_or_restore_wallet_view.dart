import 'dart:io';

import 'package:flutter/material.dart';
import 'package:stackwallet/pages/add_wallet_views/name_your_wallet_view/name_your_wallet_view.dart';
import 'package:stackwallet/pages_desktop_specific/home/my_stack_view/exit_to_my_stack_button.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/cfcolors.dart';
import 'package:stackwallet/utilities/enums/add_wallet_type_enum.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:stackwallet/widgets/desktop/desktop_app_bar.dart';
import 'package:stackwallet/widgets/desktop/desktop_scaffold.dart';
import 'package:tuple/tuple.dart';

class CreateOrRestoreWalletView extends StatelessWidget {
  const CreateOrRestoreWalletView({
    Key? key,
    required this.coin,
  }) : super(key: key);

  static const routeName = "/createOrRestoreWallet";

  final Coin coin;

  @override
  Widget build(BuildContext context) {
    debugPrint("BUILD: $runtimeType");

    final isDesktop =
        Platform.isLinux || Platform.isWindows || Platform.isMacOS;

    if (isDesktop) {
      return DesktopScaffold(
        appBar: const DesktopAppBar(
          isCompactHeight: false,
          leading: AppBarBackButton(),
          trailing: ExitToMyStackButton(),
        ),
        body: SizedBox(
          width: 480,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(),
              CreateRestoreWalletTitle(
                coin: coin,
                isDesktop: isDesktop,
              ),
              const SizedBox(
                height: 16,
              ),
              CreateRestoreWalletSubTitle(
                isDesktop: isDesktop,
              ),
              const SizedBox(
                height: 32,
              ),
              CoinImage(
                coin: coin,
                isDesktop: isDesktop,
              ),
              const SizedBox(
                height: 32,
              ),
              CreateWalletButtonGroup(
                coin: coin,
                isDesktop: isDesktop,
              ),
              const Spacer(),
              const SizedBox(
                height: kDesktopAppBarHeight,
              ),
            ],
          ),
        ),
      );
    } else {
      return Scaffold(
        appBar: AppBar(
          leading: AppBarBackButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ),
        body: Container(
          color: CFColors.background,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.all(31),
                  child: CoinImage(
                    coin: coin,
                    isDesktop: isDesktop,
                  ),
                ),
                const Spacer(
                  flex: 2,
                ),
                CreateRestoreWalletTitle(
                  coin: coin,
                  isDesktop: isDesktop,
                ),
                const SizedBox(
                  height: 8,
                ),
                CreateRestoreWalletSubTitle(
                  isDesktop: isDesktop,
                ),
                const Spacer(
                  flex: 5,
                ),
                CreateWalletButtonGroup(
                  coin: coin,
                  isDesktop: isDesktop,
                ),
              ],
            ),
          ),
        ),
      );
    }
  }
}

class CreateRestoreWalletTitle extends StatelessWidget {
  const CreateRestoreWalletTitle({
    Key? key,
    required this.coin,
    required this.isDesktop,
  }) : super(key: key);

  final Coin coin;
  final bool isDesktop;

  @override
  Widget build(BuildContext context) {
    return Text(
      "Add ${coin.prettyName} wallet",
      textAlign: TextAlign.center,
      style: isDesktop ? STextStyles.desktopH2 : STextStyles.pageTitleH1,
    );
  }
}

class CreateRestoreWalletSubTitle extends StatelessWidget {
  const CreateRestoreWalletSubTitle({
    Key? key,
    required this.isDesktop,
  }) : super(key: key);

  final bool isDesktop;

  @override
  Widget build(BuildContext context) {
    return Text(
      "Create a new wallet or restore an existing wallet from seed.",
      textAlign: TextAlign.center,
      style: isDesktop ? STextStyles.desktopSubtitleH2 : STextStyles.subtitle,
    );
  }
}

class CoinImage extends StatelessWidget {
  const CoinImage({
    Key? key,
    required this.coin,
    required this.isDesktop,
  }) : super(key: key);

  final Coin coin;
  final bool isDesktop;

  @override
  Widget build(BuildContext context) {
    return Image(
      image: AssetImage(
        Assets.png.imageFor(coin: coin),
      ),
      width: isDesktop ? 324 : MediaQuery.of(context).size.width / 3,
    );
  }
}

class CreateWalletButtonGroup extends StatelessWidget {
  const CreateWalletButtonGroup({
    Key? key,
    required this.coin,
    required this.isDesktop,
  }) : super(key: key);

  final Coin coin;
  final bool isDesktop;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: isDesktop ? 70 : 0,
            minWidth: isDesktop ? 480 : 0,
          ),
          child: TextButton(
            style: CFColors.getPrimaryEnabledButtonColor(context),
            onPressed: () {
              Navigator.of(context).pushNamed(
                NameYourWalletView.routeName,
                arguments: Tuple2(
                  AddWalletType.New,
                  coin,
                ),
              );
            },
            child: Text(
              "Create new wallet",
              style: isDesktop
                  ? STextStyles.desktopButtonEnabled
                  : STextStyles.button,
            ),
          ),
        ),
        SizedBox(
          height: isDesktop ? 16 : 12,
        ),
        ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: isDesktop ? 70 : 0,
            minWidth: isDesktop ? 480 : 0,
          ),
          child: TextButton(
            style: CFColors.getSecondaryEnabledButtonColor(context),
            onPressed: () {
              Navigator.of(context).pushNamed(
                NameYourWalletView.routeName,
                arguments: Tuple2(
                  AddWalletType.Restore,
                  coin,
                ),
              );
            },
            child: Text(
              "Restore wallet",
              style: isDesktop
                  ? STextStyles.desktopButtonSecondaryEnabled
                  : STextStyles.button.copyWith(
                      color: CFColors.stackAccent,
                    ),
            ),
          ),
        ),
      ],
    );
  }
}

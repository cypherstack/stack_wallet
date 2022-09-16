import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:stackwallet/pages/add_wallet_views/add_wallet_view/sub_widgets/coin_select_item.dart';
import 'package:stackwallet/pages/add_wallet_views/add_wallet_view/sub_widgets/next_button.dart';
import 'package:stackwallet/pages_desktop_specific/desktop_app_bar.dart';
import 'package:stackwallet/providers/global/prefs_provider.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/cfcolors.dart';
import 'package:stackwallet/utilities/constants.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:stackwallet/widgets/icon_widgets/x_icon.dart';
import 'package:stackwallet/widgets/rounded_white_container.dart';
import 'package:stackwallet/widgets/stack_text_field.dart';
import 'package:stackwallet/widgets/textfield_icon_button.dart';

class AddWalletView extends StatefulWidget {
  const AddWalletView({Key? key}) : super(key: key);

  static const routeName = "/addWallet";

  @override
  State<AddWalletView> createState() => _AddWalletViewState();
}

class _AddWalletViewState extends State<AddWalletView> {
  late final TextEditingController _searchFieldController;
  late final FocusNode _searchFocusNode;

  String _searchTerm = "";

  final List<Coin> coins = [...Coin.values];

  @override
  void initState() {
    _searchFieldController = TextEditingController();
    _searchFocusNode = FocusNode();
    coins.remove(Coin.firoTestNet);
    super.initState();
  }

  @override
  void dispose() {
    _searchFieldController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint("BUILD: $runtimeType");

    if (Platform.isLinux || Platform.isMacOS || Platform.isWindows) {
      return Material(
        color: CFColors.background,
        child: Column(
          children: [
            DesktopAppBar(
              isCompactHeight: false,
              leading: AppBarBackButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ),
            Expanded(
              child: Column(
                children: [
                  const AddWalletText(
                    isDesktop: true,
                  ),
                  const SizedBox(
                    height: 16,
                  ),
                  Expanded(
                    child: SizedBox(
                      width: 480,
                      child: RoundedWhiteContainer(
                        radiusMultiplier: 2,
                        padding: const EdgeInsets.only(
                          left: 16,
                          top: 16,
                          right: 16,
                          bottom: 0,
                        ),
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(4.0),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(
                                  Constants.size.circularBorderRadius,
                                ),
                                child: TextField(
                                  controller: _searchFieldController,
                                  focusNode: _searchFocusNode,
                                  onChanged: (value) {
                                    setState(() {
                                      _searchTerm = value;
                                    });
                                  },
                                  style: STextStyles.desktopTextMedium.copyWith(
                                    height: 2,
                                  ),
                                  decoration: standardInputDecoration(
                                    "Search",
                                    _searchFocusNode,
                                  ).copyWith(
                                    contentPadding: const EdgeInsets.symmetric(
                                      vertical: 10,
                                    ),
                                    prefixIcon: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        // vertical: 20,
                                      ),
                                      child: SvgPicture.asset(
                                        Assets.svg.search,
                                        width: 24,
                                        height: 24,
                                        color: CFColors
                                            .textFieldDefaultSearchIconLeft,
                                      ),
                                    ),
                                    suffixIcon:
                                        _searchFieldController.text.isNotEmpty
                                            ? Padding(
                                                padding: const EdgeInsets.only(
                                                    right: 10),
                                                child: UnconstrainedBox(
                                                  child: Row(
                                                    children: [
                                                      TextFieldIconButton(
                                                        child: const XIcon(
                                                          width: 24,
                                                          height: 24,
                                                        ),
                                                        onTap: () async {
                                                          setState(() {
                                                            _searchFieldController
                                                                .text = "";
                                                            _searchTerm = "";
                                                          });
                                                        },
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              )
                                            : null,
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: SearchableCoinList(
                                coins: coins,
                                isDesktop: true,
                                searchTerm: _searchTerm,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 16,
                  ),
                  const SizedBox(
                    height: 70,
                    width: 480,
                    child: AddWalletNextButton(),
                  ),
                  const SizedBox(
                    height: 32,
                  ),
                ],
              ),
            ),
          ],
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
          color: CFColors.almostWhite,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const AddWalletText(
                  isDesktop: false,
                ),
                const SizedBox(
                  height: 16,
                ),
                Expanded(
                  child: MobileCoinList(
                    coins: coins,
                    isDesktop: false,
                  ),
                ),
                const SizedBox(
                  height: 16,
                ),
                const AddWalletNextButton(),
              ],
            ),
          ),
        ),
      );
    }
  }
}

class AddWalletText extends StatelessWidget {
  const AddWalletText({Key? key, required this.isDesktop}) : super(key: key);

  final bool isDesktop;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          "Add wallet",
          textAlign: TextAlign.center,
          style: isDesktop ? STextStyles.desktopH2 : STextStyles.pageTitleH1,
        ),
        const SizedBox(
          height: 16,
        ),
        Text(
          "Select wallet currency",
          textAlign: TextAlign.center,
          style:
              isDesktop ? STextStyles.desktopSubtitleH2 : STextStyles.subtitle,
        ),
      ],
    );
  }
}

class MobileCoinList extends StatelessWidget {
  const MobileCoinList({
    Key? key,
    required this.coins,
    required this.isDesktop,
  }) : super(key: key);

  final List<Coin> coins;
  final bool isDesktop;

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (_, ref, __) {
        bool showTestNet = ref.watch(
          prefsChangeNotifierProvider.select((value) => value.showTestNetCoins),
        );

        return ListView.builder(
          itemCount:
              showTestNet ? coins.length : coins.length - (kTestNetCoinCount),
          itemBuilder: (ctx, index) {
            return Padding(
              padding: const EdgeInsets.all(4),
              child: CoinSelectItem(
                coin: coins[index],
              ),
            );
          },
        );
      },
    );
  }
}

class SearchableCoinList extends StatelessWidget {
  const SearchableCoinList({
    Key? key,
    required this.coins,
    required this.isDesktop,
    required this.searchTerm,
  }) : super(key: key);

  final List<Coin> coins;
  final bool isDesktop;
  final String searchTerm;

  List<Coin> filterCoins(String text, bool showTestNetCoins) {
    final _coins = [...coins];
    if (text.isNotEmpty) {
      final lowercaseTerm = text.toLowerCase();
      _coins.retainWhere((e) =>
          e.ticker.toLowerCase().contains(lowercaseTerm) ||
          e.prettyName.toLowerCase().contains(lowercaseTerm) ||
          e.name.toLowerCase().contains(lowercaseTerm));
    }
    if (!showTestNetCoins) {
      _coins.removeWhere((e) => e.name.endsWith("TestNet"));
    }
    // remove firo testnet regardless
    _coins.remove(Coin.firoTestNet);

    return _coins;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (_, ref, __) {
        bool showTestNet = ref.watch(
          prefsChangeNotifierProvider.select((value) => value.showTestNetCoins),
        );

        final _coins = filterCoins(searchTerm, showTestNet);

        return ListView.builder(
          itemCount: _coins.length,
          itemBuilder: (ctx, index) {
            return Padding(
              padding: const EdgeInsets.all(4),
              child: CoinSelectItem(
                coin: _coins[index],
              ),
            );
          },
        );
      },
    );
  }
}

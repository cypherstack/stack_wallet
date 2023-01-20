import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:stackwallet/models/buy/response_objects/crypto.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/constants.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';
import 'package:stackwallet/utilities/util.dart';
import 'package:stackwallet/widgets/background.dart';
import 'package:stackwallet/widgets/conditional_parent.dart';
import 'package:stackwallet/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:stackwallet/widgets/icon_widgets/x_icon.dart';
import 'package:stackwallet/widgets/loading_indicator.dart';
import 'package:stackwallet/widgets/rounded_white_container.dart';
import 'package:stackwallet/widgets/stack_text_field.dart';
import 'package:stackwallet/widgets/textfield_icon_button.dart';

class CryptoSelectionView extends StatefulWidget {
  const CryptoSelectionView({
    Key? key,
    required this.coins,
  }) : super(key: key);

  final List<Crypto> coins;

  @override
  State<CryptoSelectionView> createState() => _CryptoSelectionViewState();
}

class _CryptoSelectionViewState extends State<CryptoSelectionView> {
  late TextEditingController _searchController;
  final _searchFocusNode = FocusNode();

  late final List<Crypto> coins;
  late List<Crypto> _coins;

  void filter(String text) {
    setState(() {
      _coins = [
        ...coins.where((e) =>
            e.name.toLowerCase().contains(text.toLowerCase()) ||
            e.ticker.toLowerCase().contains(text.toLowerCase()))
      ];
    });
  }

  @override
  void initState() {
    _searchController = TextEditingController();

    coins = [...widget.coins];
    coins.sort(
        (a, b) => a.ticker.toLowerCase().compareTo(b.ticker.toLowerCase()));
    for (Coin coin in Coin.values.reversed) {
      int index = coins.indexWhere((element) =>
          element.ticker.toLowerCase() == coin.ticker.toLowerCase());
      if (index > 0) {
        final currency = coins.removeAt(index);
        coins.insert(0, currency);
      }
    }

    _coins = [...coins];

    super.initState();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = Util.isDesktop;
    return ConditionalParent(
      condition: !isDesktop,
      builder: (child) {
        return Background(
          child: Scaffold(
            backgroundColor:
                Theme.of(context).extension<StackColors>()!.background,
            appBar: AppBar(
              leading: AppBarBackButton(
                onPressed: () async {
                  if (FocusScope.of(context).hasFocus) {
                    FocusScope.of(context).unfocus();
                    await Future<void>.delayed(
                        const Duration(milliseconds: 50));
                  }
                  if (mounted) {
                    Navigator.of(context).pop();
                  }
                },
              ),
              title: Text(
                "Choose a coin to buy",
                style: STextStyles.pageTitleH2(context),
              ),
            ),
            body: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
              ),
              child: child,
            ),
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: isDesktop ? MainAxisSize.min : MainAxisSize.max,
        children: [
          if (!isDesktop)
            const SizedBox(
              height: 16,
            ),
          ClipRRect(
            borderRadius: BorderRadius.circular(
              Constants.size.circularBorderRadius,
            ),
            child: TextField(
              autofocus: isDesktop,
              autocorrect: !isDesktop,
              enableSuggestions: !isDesktop,
              controller: _searchController,
              focusNode: _searchFocusNode,
              onChanged: filter,
              style: STextStyles.field(context),
              decoration: standardInputDecoration(
                "Search",
                _searchFocusNode,
                context,
                desktopMed: isDesktop,
              ).copyWith(
                prefixIcon: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 16,
                  ),
                  child: SvgPicture.asset(
                    Assets.svg.search,
                    width: 16,
                    height: 16,
                  ),
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? Padding(
                        padding: const EdgeInsets.only(right: 0),
                        child: UnconstrainedBox(
                          child: Row(
                            children: [
                              TextFieldIconButton(
                                child: const XIcon(),
                                onTap: () async {
                                  setState(() {
                                    _searchController.text = "";
                                  });
                                  filter("");
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
          const SizedBox(
            height: 10,
          ),
          Text(
            "All coins",
            style: STextStyles.smallMed12(context),
          ),
          const SizedBox(
            height: 12,
          ),
          Flexible(
            child: RoundedWhiteContainer(
              padding: const EdgeInsets.all(0),
              child: ListView.builder(
                shrinkWrap: true,
                primary: isDesktop ? false : null,
                itemCount: _coins.length,
                itemBuilder: (builderContext, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: GestureDetector(
                      onTap: () {
                        Navigator.of(context).pop(_coins[index]);
                      },
                      child: RoundedWhiteContainer(
                        child: Row(
                          children: [
                            SizedBox(
                                width: 24,
                                height: 24,
                                child: _coins[index].image.isNotEmpty
                                    ? SvgPicture.network(
                                        _coins[index].image,
                                        width: 24,
                                        height: 24,
                                        placeholderBuilder: (_) =>
                                            const LoadingIndicator(),
                                      )
                                    : getIconForTicker(_coins[index].ticker)),
                            const SizedBox(
                              width: 10,
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _coins[index].name,
                                    style: STextStyles.largeMedium14(context),
                                  ),
                                  const SizedBox(
                                    height: 2,
                                  ),
                                  Text(
                                    _coins[index].ticker.toUpperCase(),
                                    style: STextStyles.smallMed12(context)
                                        .copyWith(
                                      color: Theme.of(context)
                                          .extension<StackColors>()!
                                          .textSubtitle1,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Widget? getIconForTicker(String ticker) {
  print(ticker);
  if (!isCoinSupportedByTicker(ticker)) {
    return null;
  }
  Coin? coin = coinFromTickerCaseInsensitive(ticker);
  String iconAsset = Assets.svg.iconFor(coin: coin);
  if (iconAsset != null) {
    return SvgPicture.asset(iconAsset, height: 20, width: 20);
  }
  return null;
}

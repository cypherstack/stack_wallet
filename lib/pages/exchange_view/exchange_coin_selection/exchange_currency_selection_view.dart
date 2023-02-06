import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:isar/isar.dart';
import 'package:stackwallet/models/isar/exchange_cache/currency.dart';
import 'package:stackwallet/models/isar/exchange_cache/pair.dart';
import 'package:stackwallet/pages/buy_view/sub_widgets/crypto_selection_view.dart';
import 'package:stackwallet/services/exchange/exchange_data_loading_service.dart';
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

class ExchangeCurrencySelectionView extends StatefulWidget {
  const ExchangeCurrencySelectionView({
    Key? key,
    required this.exchangeName,
    required this.willChange,
    required this.paired,
    required this.isFixedRate,
  }) : super(key: key);

  final String exchangeName;
  final Currency? willChange;
  final Currency? paired;
  final bool isFixedRate;

  @override
  State<ExchangeCurrencySelectionView> createState() =>
      _ExchangeCurrencySelectionViewState();
}

class _ExchangeCurrencySelectionViewState
    extends State<ExchangeCurrencySelectionView> {
  late TextEditingController _searchController;
  final _searchFocusNode = FocusNode();
  final isDesktop = Util.isDesktop;

  late List<Currency> _currencies;

  void filter(String text) {
    setState(() {
      final query = ExchangeDataLoadingService.instance.isar.currencies
          .where()
          .exchangeNameEqualTo(widget.exchangeName)
          .filter()
          .group((q) => widget.isFixedRate
              ? q
                  .rateTypeEqualTo(SupportedRateType.both)
                  .or()
                  .rateTypeEqualTo(SupportedRateType.fixed)
              : q
                  .rateTypeEqualTo(SupportedRateType.both)
                  .or()
                  .rateTypeEqualTo(SupportedRateType.estimated))
          .and()
          .group((q) => q
              .nameContains(text, caseSensitive: false)
              .or()
              .tickerContains(text, caseSensitive: false));

      if (widget.paired != null) {
        _currencies = query
            .and()
            .not()
            .tickerEqualTo(widget.paired!.ticker)
            .sortByIsStackCoin()
            .thenByTicker()
            .findAllSync();
      } else {
        _currencies = query.sortByIsStackCoin().thenByTicker().findAllSync();
      }
    });
  }

  @override
  void initState() {
    _searchController = TextEditingController();

    final query = ExchangeDataLoadingService.instance.isar.currencies
        .where()
        .exchangeNameEqualTo(widget.exchangeName)
        .filter()
        .group((q) => widget.isFixedRate
            ? q
                .rateTypeEqualTo(SupportedRateType.both)
                .or()
                .rateTypeEqualTo(SupportedRateType.fixed)
            : q
                .rateTypeEqualTo(SupportedRateType.both)
                .or()
                .rateTypeEqualTo(SupportedRateType.estimated));

    if (widget.paired != null) {
      _currencies = query
          .and()
          .not()
          .tickerEqualTo(widget.paired!.ticker)
          .sortByIsStackCoin()
          .thenByTicker()
          .findAllSync();
    } else {
      _currencies = query.sortByIsStackCoin().thenByTicker().findAllSync();
    }

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
    print("==================================================");
    print("${widget.exchangeName}");
    print("${widget.isFixedRate}");
    print("==================================================");

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
                "Choose a coin to exchange",
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
            "Popular coins",
            style: STextStyles.smallMed12(context),
          ),
          const SizedBox(
            height: 12,
          ),
          Flexible(
            child: Builder(builder: (context) {
              final items = _currencies
                  .where((e) => Coin.values
                      .where((coin) =>
                          coin.ticker.toLowerCase() == e.ticker.toLowerCase())
                      .isNotEmpty)
                  .toList(growable: false);

              return RoundedWhiteContainer(
                padding: const EdgeInsets.all(0),
                child: ListView.builder(
                  shrinkWrap: true,
                  primary: isDesktop ? false : null,
                  itemCount: items.length,
                  itemBuilder: (builderContext, index) {
                    final bool hasImageUrl =
                        items[index].image.startsWith("http");
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: GestureDetector(
                        onTap: () {
                          Navigator.of(context).pop(items[index]);
                        },
                        child: RoundedWhiteContainer(
                          child: Row(
                            children: [
                              SizedBox(
                                width: 24,
                                height: 24,
                                child: isStackCoin(items[index].ticker)
                                    ? getIconForTicker(
                                        items[index].ticker,
                                        size: 24,
                                      )
                                    : hasImageUrl
                                        ? SvgPicture.network(
                                            items[index].image,
                                            width: 24,
                                            height: 24,
                                            placeholderBuilder: (_) =>
                                                const LoadingIndicator(),
                                          )
                                        : const SizedBox(
                                            width: 24,
                                            height: 24,
                                          ),
                              ),
                              const SizedBox(
                                width: 10,
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      items[index].name,
                                      style: STextStyles.largeMedium14(context),
                                    ),
                                    const SizedBox(
                                      height: 2,
                                    ),
                                    Text(
                                      items[index].ticker.toUpperCase(),
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
              );
            }),
          ),
          const SizedBox(
            height: 20,
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
                itemCount: _currencies.length,
                itemBuilder: (builderContext, index) {
                  final bool hasImageUrl =
                      _currencies[index].image.startsWith("http");
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: GestureDetector(
                      onTap: () {
                        Navigator.of(context).pop(_currencies[index]);
                      },
                      child: RoundedWhiteContainer(
                        child: Row(
                          children: [
                            SizedBox(
                              width: 24,
                              height: 24,
                              child: isStackCoin(_currencies[index].ticker)
                                  ? getIconForTicker(
                                      _currencies[index].ticker,
                                      size: 24,
                                    )
                                  : hasImageUrl
                                      ? SvgPicture.network(
                                          _currencies[index].image,
                                          width: 24,
                                          height: 24,
                                          placeholderBuilder: (_) =>
                                              const LoadingIndicator(),
                                        )
                                      : const SizedBox(
                                          width: 24,
                                          height: 24,
                                        ),
                            ),
                            const SizedBox(
                              width: 10,
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _currencies[index].name,
                                    style: STextStyles.largeMedium14(context),
                                  ),
                                  const SizedBox(
                                    height: 2,
                                  ),
                                  Text(
                                    _currencies[index].ticker.toUpperCase(),
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

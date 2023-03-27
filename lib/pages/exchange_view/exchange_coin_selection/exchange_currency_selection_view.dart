import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:isar/isar.dart';
import 'package:stackwallet/exceptions/exchange/unsupported_currency_exception.dart';
import 'package:stackwallet/models/isar/exchange_cache/currency.dart';
import 'package:stackwallet/models/isar/exchange_cache/pair.dart';
import 'package:stackwallet/pages/buy_view/sub_widgets/crypto_selection_view.dart';
import 'package:stackwallet/services/exchange/change_now/change_now_exchange.dart';
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
import 'package:stackwallet/widgets/custom_loading_overlay.dart';
import 'package:stackwallet/widgets/desktop/primary_button.dart';
import 'package:stackwallet/widgets/desktop/secondary_button.dart';
import 'package:stackwallet/widgets/icon_widgets/x_icon.dart';
import 'package:stackwallet/widgets/loading_indicator.dart';
import 'package:stackwallet/widgets/rounded_white_container.dart';
import 'package:stackwallet/widgets/stack_dialog.dart';
import 'package:stackwallet/widgets/stack_text_field.dart';
import 'package:stackwallet/widgets/textfield_icon_button.dart';

class ExchangeCurrencySelectionView extends StatefulWidget {
  const ExchangeCurrencySelectionView({
    Key? key,
    required this.willChangeTicker,
    required this.pairedTicker,
    required this.isFixedRate,
    required this.willChangeIsSend,
  }) : super(key: key);

  final String? willChangeTicker;
  final String? pairedTicker;
  final bool isFixedRate;
  final bool willChangeIsSend;

  @override
  State<ExchangeCurrencySelectionView> createState() =>
      _ExchangeCurrencySelectionViewState();
}

class _ExchangeCurrencySelectionViewState
    extends State<ExchangeCurrencySelectionView> {
  late TextEditingController _searchController;
  final _searchFocusNode = FocusNode();
  final isDesktop = Util.isDesktop;

  List<Currency> _currencies = [];

  bool _loaded = false;
  String _searchString = "";

  Future<T> _showUpdatingCurrencies<T>({
    required Future<T> whileFuture,
  }) async {
    unawaited(
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => WillPopScope(
          onWillPop: () async => false,
          child: Container(
            color: Theme.of(context)
                .extension<StackColors>()!
                .overlay
                .withOpacity(0.6),
            child: const CustomLoadingOverlay(
              message: "Loading currencies",
              eventBus: null,
            ),
          ),
        ),
      ),
    );

    final result = await whileFuture;

    if (mounted) {
      Navigator.of(context, rootNavigator: isDesktop).pop();
    }

    return result;
  }

  Future<List<Currency>> _loadCurrencies() async {
    if (widget.pairedTicker == null) {
      return await _getCurrencies();
    }
    List<Currency> currencies = [];
    // await ExchangeDataLoadingService
    //     .instance.isar.currencies
    //     .where()
    //     .exchangeNameEqualTo(MajesticBankExchange.exchangeName)
    //     .findAll();

    final cn = await ChangeNowExchange.instance.getPairedCurrencies(
      widget.pairedTicker!,
      widget.isFixedRate,
    );

    if (cn.value == null) {
      if (cn.exception is UnsupportedCurrencyException) {
        return currencies;
      }

      await showDialog<void>(
        context: context,
        builder: (context) => StackDialog(
          title: "ChangeNOW Error",
          message: "Failed to load currency data: ${cn.exception}",
          leftButton: SecondaryButton(
            label: "Ok",
            onPressed: Navigator.of(context, rootNavigator: isDesktop).pop,
          ),
          rightButton: PrimaryButton(
            label: "Retry",
            onPressed: () async {
              Navigator.of(context, rootNavigator: isDesktop).pop();
              _currencies =
                  await _showUpdatingCurrencies(whileFuture: _loadCurrencies());
              setState(() {});
            },
          ),
        ),
      );
    } else {
      currencies.addAll(cn.value!);
    }

    return _getDistinctCurrenciesFrom(currencies);
  }

  Future<List<Currency>> _getCurrencies() async {
    final currencies = await ExchangeDataLoadingService.instance.isar.currencies
        .where()
        .filter()
        .isFiatEqualTo(false)
        .and()
        .group((q) => widget.isFixedRate
            ? q
                .rateTypeEqualTo(SupportedRateType.both)
                .or()
                .rateTypeEqualTo(SupportedRateType.fixed)
            : q
                .rateTypeEqualTo(SupportedRateType.both)
                .or()
                .rateTypeEqualTo(SupportedRateType.estimated))
        .sortByIsStackCoin()
        .thenByName()
        .findAll();

    return _getDistinctCurrenciesFrom(currencies);
  }

  List<Currency> _getDistinctCurrenciesFrom(List<Currency> currencies) {
    final List<Currency> distinctCurrencies = [];
    for (final currency in currencies) {
      if (!distinctCurrencies.any((e) => e.ticker == currency.ticker)) {
        distinctCurrencies.add(currency);
      }
    }
    return distinctCurrencies;
  }

  List<Currency> filter(String text) {
    if (widget.pairedTicker == null) {
      if (text.isEmpty) {
        return _currencies;
      }

      return _currencies
          .where((e) =>
              e.name.toLowerCase().contains(text.toLowerCase()) ||
              e.ticker.toLowerCase().contains(text.toLowerCase()))
          .toList(growable: false);
    } else {
      if (text.isEmpty) {
        return _currencies
            .where((e) =>
                e.ticker.toLowerCase() != widget.pairedTicker!.toLowerCase())
            .toList(growable: false);
      }

      return _currencies
          .where((e) =>
              e.ticker.toLowerCase() != widget.pairedTicker!.toLowerCase() &&
              (e.name.toLowerCase().contains(text.toLowerCase()) ||
                  e.ticker.toLowerCase().contains(text.toLowerCase())))
          .toList(growable: false);
    }
  }

  @override
  void initState() {
    _searchController = TextEditingController();

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
    if (!_loaded) {
      _loaded = true;
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
        _currencies =
            await _showUpdatingCurrencies(whileFuture: _loadCurrencies());
        setState(() {});
      });
    }

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
              onChanged: (value) => setState(() => _searchString = value),
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
                                    _searchString = "";
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
              final coins = Coin.values.where((e) =>
                  e.ticker.toLowerCase() != widget.pairedTicker?.toLowerCase());

              final items = filter(_searchString)
                  .where((e) => coins
                      .where((coin) =>
                          coin.ticker.toLowerCase() == e.ticker.toLowerCase())
                      .isNotEmpty)
                  .toList(growable: false);
              items.sort((a, b) => a.name.compareTo(b.name));

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
            child: Builder(builder: (context) {
              final filtered = filter(_searchString);
              filtered.sort((a, b) => a.name.compareTo(b.name));
              return RoundedWhiteContainer(
                padding: const EdgeInsets.all(0),
                child: ListView.builder(
                  shrinkWrap: true,
                  primary: isDesktop ? false : null,
                  itemCount: filtered.length,
                  itemBuilder: (builderContext, index) {
                    final bool hasImageUrl =
                        filtered[index].image.startsWith("http");
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: GestureDetector(
                        onTap: () {
                          Navigator.of(context).pop(filtered[index]);
                        },
                        child: RoundedWhiteContainer(
                          child: Row(
                            children: [
                              SizedBox(
                                width: 24,
                                height: 24,
                                child: isStackCoin(filtered[index].ticker)
                                    ? getIconForTicker(
                                        filtered[index].ticker,
                                        size: 24,
                                      )
                                    : hasImageUrl
                                        ? SvgPicture.network(
                                            filtered[index].image,
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
                                      filtered[index].name,
                                      style: STextStyles.largeMedium14(context),
                                    ),
                                    const SizedBox(
                                      height: 2,
                                    ),
                                    Text(
                                      filtered[index].ticker.toUpperCase(),
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
        ],
      ),
    );
  }
}

import 'dart:async';

import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:stackwallet/models/exchange/change_now/available_floating_rate_pair.dart';
import 'package:stackwallet/models/exchange/change_now/currency.dart';
import 'package:stackwallet/models/exchange/change_now/fixed_rate_market.dart';
import 'package:stackwallet/models/exchange/incomplete_exchange.dart';
import 'package:stackwallet/notifications/show_flush_bar.dart';
import 'package:stackwallet/pages/exchange_view/exchange_coin_selection/fixed_rate_pair_coin_selection_view.dart';
import 'package:stackwallet/pages/exchange_view/exchange_coin_selection/floating_rate_currency_selection_view.dart';
import 'package:stackwallet/pages/exchange_view/exchange_step_views/step_2_view.dart';
import 'package:stackwallet/pages/exchange_view/exchange_view.dart';
import 'package:stackwallet/pages/exchange_view/sub_widgets/exchange_rate_sheet.dart';
import 'package:stackwallet/pages/exchange_view/sub_widgets/step_row.dart';
import 'package:stackwallet/providers/exchange/available_currencies_state_provider.dart';
import 'package:stackwallet/providers/exchange/available_floating_rate_pairs_state_provider.dart';
import 'package:stackwallet/providers/exchange/change_now_provider.dart';
import 'package:stackwallet/providers/exchange/estimate_rate_exchange_form_provider.dart';
import 'package:stackwallet/providers/exchange/exchange_send_from_wallet_id_provider.dart';
import 'package:stackwallet/providers/exchange/fixed_rate_exchange_form_provider.dart';
import 'package:stackwallet/providers/exchange/fixed_rate_market_pairs_provider.dart';
import 'package:stackwallet/providers/providers.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/cfcolors.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/utilities/enums/flush_bar_type.dart';
import 'package:stackwallet/utilities/format.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:stackwallet/widgets/custom_loading_overlay.dart';
import 'package:stackwallet/widgets/loading_indicator.dart';
import 'package:stackwallet/widgets/stack_dialog.dart';
import 'package:tuple/tuple.dart';

class WalletInitiatedExchangeView extends ConsumerStatefulWidget {
  const WalletInitiatedExchangeView({
    Key? key,
    required this.walletId,
    required this.coin,
  }) : super(key: key);

  static const String routeName = "/walletInitiatedExchange";

  final String walletId;
  final Coin coin;

  @override
  ConsumerState<WalletInitiatedExchangeView> createState() =>
      _WalletInitiatedExchangeViewState();
}

class _WalletInitiatedExchangeViewState
    extends ConsumerState<WalletInitiatedExchangeView> {
  late final String walletId;
  late final Coin coin;

  late final TextEditingController _sendController;
  late final TextEditingController _receiveController;

  String calcSend = "";
  String calcReceive = "";

  final FocusNode _sendFocusNode = FocusNode();
  final FocusNode _receiveFocusNode = FocusNode();

  bool _swapLock = false;

  Future<void> _swap() async {
    _swapLock = true;
    _sendFocusNode.unfocus();
    _receiveFocusNode.unfocus();

    unawaited(
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => WillPopScope(
          onWillPop: () async => false,
          child: Container(
            color: CFColors.stackAccent.withOpacity(0.8),
            child: const CustomLoadingOverlay(
              message: "Updating exchange rate",
              eventBus: null,
            ),
          ),
        ),
      ),
    );

    if (ref.watch(prefsChangeNotifierProvider
            .select((pref) => pref.exchangeRateType)) ==
        ExchangeRateType.estimated) {
      await ref.read(estimatedRateExchangeFormProvider).swap();
    } else {
      final from = ref.read(fixedRateExchangeFormProvider).market?.from;
      final to = ref.read(fixedRateExchangeFormProvider).market?.to;

      if (to != null && from != null) {
        final markets = ref
            .read(fixedRateMarketPairsStateProvider.state)
            .state
            .where((e) => e.from == to && e.to == from);

        if (markets.isNotEmpty) {
          await ref.read(fixedRateExchangeFormProvider).swap(markets.first);
        }
      }
    }
    if (mounted) {
      Navigator.of(context).pop();
    }
    _swapLock = false;
  }

  Future<void> _showFloatingRateSelectionSheet({
    required List<Currency> currencies,
    required String excludedTicker,
    required String fromTicker,
    required void Function(Currency) onSelected,
  }) async {
    _sendFocusNode.unfocus();
    _receiveFocusNode.unfocus();

    List<AvailableFloatingRatePair> availablePairs = [];
    if (fromTicker.isEmpty ||
        fromTicker == "-" ||
        excludedTicker.isEmpty ||
        excludedTicker == "-") {
      availablePairs =
          ref.read(availableFloatingRatePairsStateProvider.state).state;
    } else if (excludedTicker == fromTicker) {
      availablePairs = ref
          .read(availableFloatingRatePairsStateProvider.state)
          .state
          .where((e) => e.fromTicker == excludedTicker)
          .toList(growable: false);
    } else {
      availablePairs = ref
          .read(availableFloatingRatePairsStateProvider.state)
          .state
          .where((e) => e.toTicker == excludedTicker)
          .toList(growable: false);
    }

    final List<Currency> tickers = currencies.where((e) {
      if (excludedTicker == fromTicker) {
        return e.ticker != excludedTicker &&
            availablePairs.where((e2) => e2.toTicker == e.ticker).isNotEmpty;
      } else {
        return e.ticker != excludedTicker &&
            availablePairs.where((e2) => e2.fromTicker == e.ticker).isNotEmpty;
      }
    }).toList(growable: false);

    final result = await Navigator.of(context).push(
      MaterialPageRoute<dynamic>(
        builder: (_) => FloatingRateCurrencySelectionView(
          currencies: tickers,
        ),
      ),
    );

    if (mounted && result is Currency) {
      onSelected(result);
    }
  }

  String? _fetchIconUrlFromTickerForFixedRateFlow(String? ticker) {
    if (ticker == null) return null;

    final possibleCurrencies = ref
        .read(availableChangeNowCurrenciesStateProvider.state)
        .state
        .where((e) => e.ticker.toUpperCase() == ticker.toUpperCase());

    for (final currency in possibleCurrencies) {
      if (currency.image.isNotEmpty) {
        return currency.image;
      }
    }

    return null;
  }

  Future<void> _showFixedRateSelectionSheet({
    required String excludedTicker,
    required String fromTicker,
    required void Function(String) onSelected,
  }) async {
    _sendFocusNode.unfocus();
    _receiveFocusNode.unfocus();

    List<FixedRateMarket> marketsThatPairWithExcludedTicker = [];

    if (excludedTicker == "" ||
        excludedTicker == "-" ||
        fromTicker == "" ||
        fromTicker == "-") {
      marketsThatPairWithExcludedTicker =
          ref.read(fixedRateMarketPairsStateProvider.state).state;
    } else if (excludedTicker == fromTicker) {
      marketsThatPairWithExcludedTicker = ref
          .read(fixedRateMarketPairsStateProvider.state)
          .state
          .where((e) => e.from == excludedTicker && e.to != excludedTicker)
          .toList(growable: false);
    } else {
      marketsThatPairWithExcludedTicker = ref
          .read(fixedRateMarketPairsStateProvider.state)
          .state
          .where((e) => e.to == excludedTicker && e.from != excludedTicker)
          .toList(growable: false);
    }

    final result = await Navigator.of(context).push(
      MaterialPageRoute<dynamic>(
        builder: (_) => FixedRateMarketPairCoinSelectionView(
          markets: marketsThatPairWithExcludedTicker,
          currencies:
              ref.read(availableChangeNowCurrenciesStateProvider.state).state,
          isFrom: excludedTicker != fromTicker,
        ),
      ),
    );

    if (mounted && result is String) {
      onSelected(result);
    }
  }

  @override
  void initState() {
    walletId = widget.walletId;
    coin = widget.coin;
    _sendController = TextEditingController();
    _receiveController = TextEditingController();

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      ref.read(estimatedRateExchangeFormProvider).clearAmounts(true);
      // ref.read(fixedRateExchangeFormProvider);
    });
    super.initState();
  }

  @override
  void dispose() {
    _receiveController.dispose();
    _sendController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint("BUILD: $runtimeType");

    final isEstimated = ref.watch(prefsChangeNotifierProvider
            .select((pref) => pref.exchangeRateType)) ==
        ExchangeRateType.estimated;

    ref.listen(
        isEstimated
            ? estimatedRateExchangeFormProvider
                .select((value) => value.toAmountString)
            : fixedRateExchangeFormProvider.select(
                (value) => value.toAmountString), (previous, String next) {
      if (!_receiveFocusNode.hasFocus) {
        _receiveController.text = next;
        debugPrint("RECEIVE AMOUNT LISTENER ACTIVATED");
        if (_swapLock) {
          _sendController.text = isEstimated
              ? ref.read(estimatedRateExchangeFormProvider).fromAmountString
              : ref.read(fixedRateExchangeFormProvider).fromAmountString;
        }
      }
    });
    ref.listen(
        isEstimated
            ? estimatedRateExchangeFormProvider
                .select((value) => value.fromAmountString)
            : fixedRateExchangeFormProvider.select(
                (value) => value.fromAmountString), (previous, String next) {
      if (!_sendFocusNode.hasFocus) {
        _sendController.text = next;
        debugPrint("SEND AMOUNT LISTENER ACTIVATED");
        if (_swapLock) {
          _receiveController.text = isEstimated
              ? ref.read(estimatedRateExchangeFormProvider).toAmountString
              : ref.read(fixedRateExchangeFormProvider).toAmountString;
        }
      }
    });

    return Scaffold(
      backgroundColor: CFColors.almostWhite,
      appBar: AppBar(
        leading: AppBarBackButton(
          onPressed: () async {
            if (FocusScope.of(context).hasFocus) {
              FocusScope.of(context).unfocus();
              await Future<void>.delayed(const Duration(milliseconds: 75));
            }
            if (mounted) {
              Navigator.of(context).pop();
            }
          },
        ),
        title: Text(
          "Exchange",
          style: STextStyles.navBarTitle,
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = MediaQuery.of(context).size.width - 32;
          return Padding(
            padding: const EdgeInsets.all(12),
            child: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 24,
                ),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        StepRow(
                          count: 4,
                          current: 0,
                          width: width,
                        ),
                        const SizedBox(
                          height: 14,
                        ),
                        Text(
                          "Exchange amount",
                          style: STextStyles.pageTitleH1,
                        ),
                        const SizedBox(
                          height: 8,
                        ),
                        Text(
                          "Network fees and other exchange charges are included in the rate.",
                          style: STextStyles.itemSubtitle,
                        ),
                        const SizedBox(
                          height: 24,
                        ),
                        Text(
                          "You will send",
                          style: STextStyles.itemSubtitle.copyWith(
                            color: CFColors.neutral50,
                          ),
                        ),
                        const SizedBox(
                          height: 4,
                        ),
                        TextFormField(
                          focusNode: _sendFocusNode,
                          controller: _sendController,
                          textAlign: TextAlign.right,
                          onTap: () {
                            if (_sendController.text == "-") {
                              _sendController.text = "";
                            }
                          },
                          onChanged: (value) async {
                            final newFromAmount = Decimal.tryParse(value);
                            if (newFromAmount != null) {
                              if (ref
                                      .read(prefsChangeNotifierProvider)
                                      .exchangeRateType ==
                                  ExchangeRateType.estimated) {
                                await ref
                                    .read(estimatedRateExchangeFormProvider)
                                    .setFromAmountAndCalculateToAmount(
                                        newFromAmount, true);
                              } else {
                                await ref
                                    .read(fixedRateExchangeFormProvider)
                                    .setFromAmountAndCalculateToAmount(
                                        newFromAmount, true);
                              }
                            } else {
                              if (ref
                                      .read(prefsChangeNotifierProvider)
                                      .exchangeRateType ==
                                  ExchangeRateType.estimated) {
                                await ref
                                    .read(estimatedRateExchangeFormProvider)
                                    .setFromAmountAndCalculateToAmount(
                                        Decimal.zero, true);
                              } else {
                                await ref
                                    .read(fixedRateExchangeFormProvider)
                                    .setFromAmountAndCalculateToAmount(
                                        Decimal.zero, true);
                              }
                              _receiveController.text = "";
                            }
                          },
                          keyboardType: const TextInputType.numberWithOptions(
                            signed: false,
                            decimal: true,
                          ),
                          inputFormatters: [
                            // regex to validate a crypto amount with 8 decimal places
                            TextInputFormatter.withFunction((oldValue,
                                    newValue) =>
                                RegExp(r'^([0-9]*[,.]?[0-9]{0,8}|[,.][0-9]{0,8})$')
                                        .hasMatch(newValue.text)
                                    ? newValue
                                    : oldValue),
                          ],
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.only(
                              top: 12,
                              right: 12,
                            ),
                            hintText: "0",
                            hintStyle: STextStyles.fieldLabel.copyWith(
                              fontSize: 14,
                            ),
                            prefixIcon: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: GestureDetector(
                                onTap: () async {
                                  if (ref
                                          .read(prefsChangeNotifierProvider)
                                          .exchangeRateType ==
                                      ExchangeRateType.estimated) {
                                    final String fromTicker = ref
                                            .read(
                                                estimatedRateExchangeFormProvider)
                                            .from
                                            ?.ticker ??
                                        "-";

                                    if (fromTicker.toLowerCase() ==
                                        coin.ticker.toLowerCase()) {
                                      // do not allow changing away from wallet coin
                                      return;
                                    }

                                    await _showFloatingRateSelectionSheet(
                                        currencies: ref
                                            .read(
                                                availableChangeNowCurrenciesStateProvider
                                                    .state)
                                            .state,
                                        excludedTicker: ref
                                                .read(
                                                    estimatedRateExchangeFormProvider)
                                                .to
                                                ?.ticker ??
                                            "-",
                                        fromTicker: fromTicker,
                                        onSelected: (from) => ref
                                            .read(
                                                estimatedRateExchangeFormProvider)
                                            .updateFrom(from, true));
                                  } else {
                                    final toTicker = ref
                                            .read(fixedRateExchangeFormProvider)
                                            .market
                                            ?.to ??
                                        "";
                                    final fromTicker = ref
                                            .read(fixedRateExchangeFormProvider)
                                            .market
                                            ?.from ??
                                        "";

                                    if (fromTicker.toLowerCase() ==
                                        coin.ticker.toLowerCase()) {
                                      // do not allow changing away from wallet coin
                                      return;
                                    }
                                    await _showFixedRateSelectionSheet(
                                      excludedTicker: toTicker,
                                      fromTicker: fromTicker,
                                      onSelected: (selectedFromTicker) async {
                                        try {
                                          final market = ref
                                              .read(
                                                  fixedRateMarketPairsStateProvider
                                                      .state)
                                              .state
                                              .firstWhere(
                                                (e) =>
                                                    e.to == toTicker &&
                                                    e.from ==
                                                        selectedFromTicker,
                                              );

                                          await ref
                                              .read(
                                                  fixedRateExchangeFormProvider)
                                              .updateMarket(market, true);
                                        } catch (e) {
                                          unawaited(showDialog<dynamic>(
                                            context: context,
                                            builder: (_) => const StackDialog(
                                              title: "Fixed rate market error",
                                              message:
                                                  "Could not find the specified fixed rate trade pair",
                                            ),
                                          ));
                                          return;
                                        }
                                      },
                                    );
                                  }
                                },
                                child: Container(
                                  color: Colors.transparent,
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 18,
                                          height: 18,
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(18),
                                          ),
                                          child: Builder(
                                            builder: (context) {
                                              String? image;
                                              if (ref.watch(prefsChangeNotifierProvider
                                                      .select((value) => value
                                                          .exchangeRateType)) ==
                                                  ExchangeRateType.estimated) {
                                                image = ref
                                                    .watch(
                                                        estimatedRateExchangeFormProvider
                                                            .select((value) =>
                                                                value.from))
                                                    ?.image;
                                              } else {
                                                image = _fetchIconUrlFromTickerForFixedRateFlow(
                                                    ref.watch(
                                                        fixedRateExchangeFormProvider
                                                            .select((value) =>
                                                                value.market
                                                                    ?.from)));
                                              }
                                              if (image != null &&
                                                  image.isNotEmpty) {
                                                return Center(
                                                  child: SvgPicture.network(
                                                    image,
                                                    height: 18,
                                                    placeholderBuilder: (_) =>
                                                        Container(
                                                      width: 18,
                                                      height: 18,
                                                      decoration: BoxDecoration(
                                                        color: CFColors.gray3,
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(
                                                          18,
                                                        ),
                                                      ),
                                                      child: ClipRRect(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(
                                                          18,
                                                        ),
                                                        child:
                                                            const LoadingIndicator(),
                                                      ),
                                                    ),
                                                  ),
                                                );
                                              } else {
                                                return Container(
                                                  width: 18,
                                                  height: 18,
                                                  decoration: BoxDecoration(
                                                    // color: CFColors.stackAccent,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            18),
                                                  ),
                                                  child: SvgPicture.asset(
                                                    Assets.svg.circleQuestion,
                                                    width: 18,
                                                    height: 18,
                                                    color: CFColors.gray3,
                                                  ),
                                                );
                                              }
                                            },
                                          ),
                                        ),
                                        const SizedBox(
                                          width: 6,
                                        ),
                                        Text(
                                          isEstimated
                                              ? ref.watch(
                                                      estimatedRateExchangeFormProvider
                                                          .select((value) => value
                                                              .from?.ticker
                                                              .toUpperCase())) ??
                                                  "-"
                                              : ref.watch(
                                                      fixedRateExchangeFormProvider
                                                          .select((value) => value
                                                              .market?.from
                                                              .toUpperCase())) ??
                                                  "-",
                                          style:
                                              STextStyles.smallMed14.copyWith(
                                            color: CFColors.stackAccent,
                                          ),
                                        ),
                                        const SizedBox(
                                          width: 6,
                                        ),
                                        Builder(builder: (context) {
                                          final ticker = isEstimated
                                              ? ref.watch(
                                                      estimatedRateExchangeFormProvider
                                                          .select((value) =>
                                                              value.from
                                                                  ?.ticker)) ??
                                                  "-"
                                              : ref.watch(
                                                      fixedRateExchangeFormProvider
                                                          .select((value) =>
                                                              value.market
                                                                  ?.from)) ??
                                                  "-";
                                          if (ticker.toLowerCase() ==
                                              coin.ticker.toLowerCase()) {
                                            return Container();
                                          }
                                          return SvgPicture.asset(
                                            Assets.svg.chevronDown,
                                            width: 5,
                                            height: 2.5,
                                            color: CFColors.stackAccent,
                                          );
                                        }),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(
                          height: 4,
                        ),
                        Stack(
                          children: [
                            Positioned.fill(
                              child: Align(
                                alignment: Alignment.bottomLeft,
                                child: Text(
                                  "You will receive",
                                  style: STextStyles.itemSubtitle.copyWith(
                                    color: CFColors.neutral50,
                                  ),
                                ),
                              ),
                            ),
                            Center(
                              child: GestureDetector(
                                onTap: () async {
                                  await _swap();
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(4),
                                  child: SvgPicture.asset(
                                    Assets.svg.swap,
                                    width: 20,
                                    height: 20,
                                  ),
                                ),
                              ),
                            ),
                            Positioned.fill(
                              child: Align(
                                alignment: Alignment.topRight,
                                child: Text(
                                  isEstimated
                                      ? ref.watch(
                                          estimatedRateExchangeFormProvider
                                              .select((value) =>
                                                  value.minimumSendWarning))
                                      : ref.watch(fixedRateExchangeFormProvider
                                          .select((value) =>
                                              value.sendAmountWarning)),
                                  style: STextStyles.errorSmall,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(
                          height: 4,
                        ),
                        TextFormField(
                          focusNode: _receiveFocusNode,
                          controller: _receiveController,
                          onTap: () {
                            if (_receiveController.text == "-") {
                              _receiveController.text = "";
                            }
                          },
                          onChanged: (value) async {
                            final newToAmount = Decimal.tryParse(value);
                            if (newToAmount != null) {
                              if (ref
                                      .read(prefsChangeNotifierProvider)
                                      .exchangeRateType ==
                                  ExchangeRateType.estimated) {
                                await ref
                                    .read(estimatedRateExchangeFormProvider)
                                    .setToAmountAndCalculateFromAmount(
                                        newToAmount, true);
                              } else {
                                await ref
                                    .read(fixedRateExchangeFormProvider)
                                    .setToAmountAndCalculateFromAmount(
                                        newToAmount, true);
                              }
                            } else {
                              if (ref
                                      .read(prefsChangeNotifierProvider)
                                      .exchangeRateType ==
                                  ExchangeRateType.estimated) {
                                await ref
                                    .read(estimatedRateExchangeFormProvider)
                                    .setToAmountAndCalculateFromAmount(
                                        Decimal.zero, true);
                              } else {
                                await ref
                                    .read(fixedRateExchangeFormProvider)
                                    .setToAmountAndCalculateFromAmount(
                                        Decimal.zero, true);
                              }
                              _sendController.text = "";
                            }
                          },
                          textAlign: TextAlign.right,
                          keyboardType: const TextInputType.numberWithOptions(
                            signed: false,
                            decimal: true,
                          ),
                          inputFormatters: [
                            // regex to validate a crypto amount with 8 decimal places
                            TextInputFormatter.withFunction((oldValue,
                                    newValue) =>
                                RegExp(r'^([0-9]*[,.]?[0-9]{0,8}|[,.][0-9]{0,8})$')
                                        .hasMatch(newValue.text)
                                    ? newValue
                                    : oldValue),
                          ],
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.only(
                              top: 12,
                              right: 12,
                            ),
                            hintText: "0",
                            hintStyle: STextStyles.fieldLabel.copyWith(
                              fontSize: 14,
                            ),
                            prefixIcon: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: GestureDetector(
                                onTap: () async {
                                  if (ref
                                          .read(prefsChangeNotifierProvider)
                                          .exchangeRateType ==
                                      ExchangeRateType.estimated) {
                                    final toTicker = ref
                                            .read(
                                                estimatedRateExchangeFormProvider)
                                            .to
                                            ?.ticker ??
                                        "";

                                    if (toTicker.toLowerCase() ==
                                        coin.ticker.toLowerCase()) {
                                      // do not allow changing away from wallet coin
                                      return;
                                    }

                                    await _showFloatingRateSelectionSheet(
                                        currencies: ref
                                            .read(
                                                availableChangeNowCurrenciesStateProvider
                                                    .state)
                                            .state,
                                        excludedTicker: ref
                                                .read(
                                                    estimatedRateExchangeFormProvider)
                                                .from
                                                ?.ticker ??
                                            "",
                                        fromTicker: ref
                                                .read(
                                                    estimatedRateExchangeFormProvider)
                                                .from
                                                ?.ticker ??
                                            "",
                                        onSelected: (to) => ref
                                            .read(
                                                estimatedRateExchangeFormProvider)
                                            .updateTo(to, true));
                                  } else {
                                    final fromTicker = ref
                                            .read(fixedRateExchangeFormProvider)
                                            .market
                                            ?.from ??
                                        "";
                                    final toTicker = ref
                                            .read(fixedRateExchangeFormProvider)
                                            .market
                                            ?.to ??
                                        "";
                                    if (toTicker.toLowerCase() ==
                                        coin.ticker.toLowerCase()) {
                                      // do not allow changing away from wallet coin
                                      return;
                                    }
                                    await _showFixedRateSelectionSheet(
                                      excludedTicker: fromTicker,
                                      fromTicker: fromTicker,
                                      onSelected: (selectedToTicker) async {
                                        try {
                                          final market = ref
                                              .read(
                                                  fixedRateMarketPairsStateProvider
                                                      .state)
                                              .state
                                              .firstWhere(
                                                (e) =>
                                                    e.to == selectedToTicker &&
                                                    e.from == fromTicker,
                                              );

                                          await ref
                                              .read(
                                                  fixedRateExchangeFormProvider)
                                              .updateMarket(market, true);
                                        } catch (e) {
                                          unawaited(showDialog<dynamic>(
                                            context: context,
                                            builder: (_) => const StackDialog(
                                              title: "Fixed rate market error",
                                              message:
                                                  "Could not find the specified fixed rate trade pair",
                                            ),
                                          ));
                                          return;
                                        }
                                      },
                                    );
                                  }
                                },
                                child: Container(
                                  color: Colors.transparent,
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 18,
                                          height: 18,
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(18),
                                          ),
                                          child: Builder(
                                            builder: (context) {
                                              String? image;
                                              if (ref.watch(prefsChangeNotifierProvider
                                                      .select((value) => value
                                                          .exchangeRateType)) ==
                                                  ExchangeRateType.estimated) {
                                                image = ref
                                                    .watch(
                                                        estimatedRateExchangeFormProvider
                                                            .select((value) =>
                                                                value.to))
                                                    ?.image;
                                              } else {
                                                image = _fetchIconUrlFromTickerForFixedRateFlow(
                                                    ref.watch(
                                                        fixedRateExchangeFormProvider
                                                            .select((value) =>
                                                                value.market
                                                                    ?.to)));
                                              }
                                              if (image != null &&
                                                  image.isNotEmpty) {
                                                return Center(
                                                  child: SvgPicture.network(
                                                    image,
                                                    height: 18,
                                                    placeholderBuilder: (_) =>
                                                        Container(
                                                      width: 18,
                                                      height: 18,
                                                      decoration: BoxDecoration(
                                                        color: CFColors.gray3,
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(18),
                                                      ),
                                                      child: ClipRRect(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(
                                                          18,
                                                        ),
                                                        child:
                                                            const LoadingIndicator(),
                                                      ),
                                                    ),
                                                  ),
                                                );
                                              } else {
                                                return Container(
                                                  width: 18,
                                                  height: 18,
                                                  decoration: BoxDecoration(
                                                    // color: CFColors.stackAccent,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            18),
                                                  ),
                                                  child: SvgPicture.asset(
                                                    Assets.svg.circleQuestion,
                                                    width: 18,
                                                    height: 18,
                                                    color: CFColors.gray3,
                                                  ),
                                                );
                                              }
                                            },
                                          ),
                                        ),
                                        const SizedBox(
                                          width: 6,
                                        ),
                                        Text(
                                          isEstimated
                                              ? ref.watch(
                                                      estimatedRateExchangeFormProvider
                                                          .select((value) => value
                                                              .to?.ticker
                                                              .toUpperCase())) ??
                                                  "-"
                                              : ref.watch(
                                                      fixedRateExchangeFormProvider
                                                          .select((value) => value
                                                              .market?.to
                                                              .toUpperCase())) ??
                                                  "-",
                                          style:
                                              STextStyles.smallMed14.copyWith(
                                            color: CFColors.stackAccent,
                                          ),
                                        ),
                                        const SizedBox(
                                          width: 6,
                                        ),
                                        Builder(builder: (context) {
                                          final ticker = isEstimated
                                              ? ref.watch(
                                                      estimatedRateExchangeFormProvider
                                                          .select((value) =>
                                                              value.to
                                                                  ?.ticker)) ??
                                                  "-"
                                              : ref.watch(
                                                      fixedRateExchangeFormProvider
                                                          .select((value) =>
                                                              value.market
                                                                  ?.to)) ??
                                                  "-";
                                          if (ticker.toLowerCase() ==
                                              coin.ticker.toLowerCase()) {
                                            return Container();
                                          }
                                          return SvgPicture.asset(
                                            Assets.svg.chevronDown,
                                            width: 5,
                                            height: 2.5,
                                            color: CFColors.stackAccent,
                                          );
                                        }),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        // if (ref
                        //     .watch(exchangeFormSateProvider
                        //         .select((value) => value.minimumReceiveWarning))
                        //     .isNotEmpty)
                        //   SizedBox(
                        //     height: 4,
                        //   ),
                        //
                        // if (ref
                        //     .watch(exchangeFormSateProvider
                        //         .select((value) => value.minimumReceiveWarning))
                        //     .isNotEmpty)
                        //   Row(
                        //     children: [
                        //       Spacer(),
                        //       Text(
                        //         ref.watch(exchangeFormSateProvider.select(
                        //             (value) => value.minimumReceiveWarning)),
                        //         style: STextStyles.errorSmall,
                        //       ),
                        //     ],
                        //   ),

                        const SizedBox(
                          height: 12,
                        ),
                        RateInfo(
                          onChanged: (rateType) async {
                            _receiveFocusNode.unfocus();
                            _sendFocusNode.unfocus();
                            switch (rateType) {
                              case ExchangeRateType.estimated:
                                final market = ref
                                    .read(fixedRateExchangeFormProvider)
                                    .market;
                                final fromTicker = market?.from ?? "";
                                final toTicker = market?.to ?? "";
                                if (!(fromTicker.isEmpty ||
                                    toTicker.isEmpty ||
                                    toTicker == "-" ||
                                    fromTicker == "-")) {
                                  final available = ref
                                      .read(
                                          availableFloatingRatePairsStateProvider
                                              .state)
                                      .state
                                      .where((e) =>
                                          e.toTicker == toTicker &&
                                          e.fromTicker == fromTicker);
                                  if (available.isNotEmpty) {
                                    final availableCurrencies = ref
                                        .read(
                                            availableChangeNowCurrenciesStateProvider
                                                .state)
                                        .state
                                        .where((e) =>
                                            e.ticker == fromTicker ||
                                            e.ticker == toTicker);
                                    if (availableCurrencies.length > 1) {
                                      final from =
                                          availableCurrencies.firstWhere(
                                              (e) => e.ticker == fromTicker);
                                      final to = availableCurrencies.firstWhere(
                                          (e) => e.ticker == toTicker);

                                      await ref
                                          .read(
                                              estimatedRateExchangeFormProvider)
                                          .updateTo(to, false);
                                      await ref
                                          .read(
                                              estimatedRateExchangeFormProvider)
                                          .updateFrom(from, true);
                                      return;
                                    }
                                  }
                                }
                                unawaited(showFloatingFlushBar(
                                  type: FlushBarType.warning,
                                  message:
                                      "Estimated rate trade pair \"$fromTicker-$toTicker\" unavailable. Reverting to last estimated rate pair.",
                                  context: context,
                                ));
                                break;
                              case ExchangeRateType.fixed:
                                final fromTicker = ref
                                        .read(estimatedRateExchangeFormProvider)
                                        .from
                                        ?.ticker ??
                                    "";
                                final toTicker = ref
                                        .read(estimatedRateExchangeFormProvider)
                                        .to
                                        ?.ticker ??
                                    "";
                                if (!(fromTicker.isEmpty ||
                                    toTicker.isEmpty ||
                                    toTicker == "-" ||
                                    fromTicker == "-")) {
                                  FixedRateMarket? market;
                                  try {
                                    market = ref
                                        .read(fixedRateMarketPairsStateProvider
                                            .state)
                                        .state
                                        .firstWhere((e) =>
                                            e.from == fromTicker &&
                                            e.to == toTicker);
                                  } catch (_) {
                                    market = null;
                                  }
                                  await ref
                                      .read(fixedRateExchangeFormProvider)
                                      .updateMarket(market, true);
                                  await ref
                                      .read(fixedRateExchangeFormProvider)
                                      .setFromAmountAndCalculateToAmount(
                                        Decimal.tryParse(
                                                _sendController.text) ??
                                            Decimal.zero,
                                        true,
                                      );
                                  return;
                                }
                                unawaited(showFloatingFlushBar(
                                  type: FlushBarType.warning,
                                  message:
                                      "Fixed rate trade pair \"$fromTicker-$toTicker\" unavailable. Reverting to last fixed rate pair.",
                                  context: context,
                                ));
                                break;
                            }
                          },
                        ),
                        const SizedBox(
                          height: 12,
                        ),
                        const Spacer(),
                        TextButton(
                          style:
                              Theme.of(context).textButtonTheme.style?.copyWith(
                                    backgroundColor:
                                        MaterialStateProperty.all<Color>(
                                      ((ref
                                                      .read(
                                                          prefsChangeNotifierProvider)
                                                      .exchangeRateType ==
                                                  ExchangeRateType.estimated)
                                              ? ref.watch(
                                                  estimatedRateExchangeFormProvider
                                                      .select((value) =>
                                                          value.canExchange))
                                              : ref.watch(
                                                  fixedRateExchangeFormProvider
                                                      .select((value) =>
                                                          value.canExchange)))
                                          ? CFColors.stackAccent
                                          : CFColors.buttonGray,
                                    ),
                                  ),
                          onPressed: ((ref
                                          .read(prefsChangeNotifierProvider)
                                          .exchangeRateType ==
                                      ExchangeRateType.estimated)
                                  ? ref.watch(estimatedRateExchangeFormProvider
                                      .select((value) => value.canExchange))
                                  : ref.watch(fixedRateExchangeFormProvider
                                      .select((value) => value.canExchange)))
                              ? () async {
                                  final isEstimated = ref
                                          .read(prefsChangeNotifierProvider)
                                          .exchangeRateType ==
                                      ExchangeRateType.estimated;

                                  final ft = isEstimated
                                      ? ref
                                              .read(
                                                  estimatedRateExchangeFormProvider)
                                              .from
                                              ?.ticker ??
                                          ""
                                      : ref
                                              .read(
                                                  fixedRateExchangeFormProvider)
                                              .market
                                              ?.from ??
                                          "";

                                  final manager = ref
                                      .read(walletsChangeNotifierProvider)
                                      .getManager(walletId);
                                  final sendAmount = Decimal.parse(ref
                                      .read(estimatedRateExchangeFormProvider)
                                      .fromAmountString);

                                  if (ft.toLowerCase() ==
                                      coin.ticker.toLowerCase()) {
                                    bool shouldPop = false;
                                    bool wasPopped = false;
                                    unawaited(showDialog<void>(
                                      context: context,
                                      builder: (_) => WillPopScope(
                                        onWillPop: () async {
                                          if (shouldPop) {
                                            wasPopped = true;
                                          }
                                          return shouldPop;
                                        },
                                        child: const CustomLoadingOverlay(
                                          message: "Checking available balance",
                                          eventBus: null,
                                        ),
                                      ),
                                    ));

                                    final availableBalance =
                                        await manager.availableBalance;

                                    final feeObject = await manager.fees;

                                    final fee = await manager.estimateFeeFor(
                                        Format.decimalAmountToSatoshis(
                                            sendAmount),
                                        feeObject.medium);

                                    shouldPop = true;
                                    if (!wasPopped && mounted) {
                                      Navigator.of(context).pop();
                                    }

                                    if (availableBalance <
                                        sendAmount +
                                            Format.satoshisToAmount(fee)) {
                                      unawaited(showDialog<void>(
                                        context: context,
                                        builder: (_) => StackOkDialog(
                                          title: "Insufficient balance",
                                          message:
                                              "Current ${coin.prettyName} wallet does not have enough ${coin.ticker} for this trade",
                                        ),
                                      ));
                                      return;
                                    }
                                  }

                                  if (isEstimated) {
                                    final fromTicker = ref
                                            .read(
                                                estimatedRateExchangeFormProvider)
                                            .from
                                            ?.ticker ??
                                        "";
                                    final toTicker = ref
                                            .read(
                                                estimatedRateExchangeFormProvider)
                                            .to
                                            ?.ticker ??
                                        "";

                                    bool isAvailable = false;
                                    final availableFloatingPairs = ref
                                        .read(
                                            availableFloatingRatePairsStateProvider
                                                .state)
                                        .state;
                                    for (final pair in availableFloatingPairs) {
                                      if (pair.fromTicker == fromTicker &&
                                          pair.toTicker == toTicker) {
                                        isAvailable = true;
                                        break;
                                      }
                                    }

                                    if (!isAvailable) {
                                      unawaited(showDialog<dynamic>(
                                        context: context,
                                        barrierDismissible: true,
                                        builder: (_) => StackDialog(
                                          title:
                                              "Selected trade pair unavailable",
                                          message:
                                              "The $fromTicker - $toTicker market is currently disabled for estimated/floating rate trades",
                                        ),
                                      ));
                                      return;
                                    }

                                    final rateType = ref
                                        .read(prefsChangeNotifierProvider)
                                        .exchangeRateType;

                                    final response = await ref
                                        .read(changeNowProvider)
                                        .getEstimatedExchangeAmount(
                                          fromTicker: fromTicker,
                                          toTicker: toTicker,
                                          fromAmount: sendAmount,
                                        );

                                    if (response.value == null) {
                                      unawaited(showDialog<dynamic>(
                                        context: context,
                                        barrierDismissible: true,
                                        builder: (_) => StackDialog(
                                          title:
                                              "Failed to update trade estimate",
                                          message:
                                              response.exception?.toString(),
                                        ),
                                      ));
                                      return;
                                    }

                                    String rate =
                                        "1 ${fromTicker.toUpperCase()} ~${(response.value!.estimatedAmount / sendAmount).toDecimal(scaleOnInfinitePrecision: 8).toStringAsFixed(8)} ${toTicker.toUpperCase()}";

                                    final model = IncompleteExchangeModel(
                                      sendTicker: fromTicker.toUpperCase(),
                                      receiveTicker: toTicker.toUpperCase(),
                                      rateInfo: rate,
                                      sendAmount: sendAmount,
                                      receiveAmount:
                                          response.value!.estimatedAmount,
                                      rateId: response.value!.rateId,
                                      rateType: rateType,
                                    );

                                    if (mounted) {
                                      ref
                                          .read(
                                              exchangeSendFromWalletIdStateProvider
                                                  .state)
                                          .state = Tuple2(walletId, coin);
                                      unawaited(Navigator.of(context).pushNamed(
                                        Step2View.routeName,
                                        arguments: model,
                                      ));
                                    }
                                  } else {
                                    final fromTicker = ref
                                            .read(fixedRateExchangeFormProvider)
                                            .market
                                            ?.from ??
                                        "";
                                    final toTicker = ref
                                            .read(fixedRateExchangeFormProvider)
                                            .market
                                            ?.to ??
                                        "";

                                    final sendAmount = Decimal.parse(ref
                                        .read(fixedRateExchangeFormProvider)
                                        .fromAmountString);

                                    final rateType = ref
                                        .read(prefsChangeNotifierProvider)
                                        .exchangeRateType;

                                    final response = await ref
                                        .read(changeNowProvider)
                                        .getEstimatedFixedRateExchangeAmount(
                                          fromTicker: fromTicker,
                                          toTicker: toTicker,
                                          fromAmount: sendAmount,
                                          useRateId: true,
                                        );

                                    bool? shouldCancel;

                                    if (response.value == null) {
                                      unawaited(showDialog<dynamic>(
                                        context: context,
                                        barrierDismissible: true,
                                        builder: (_) => StackDialog(
                                          title:
                                              "Failed to update trade estimate",
                                          message:
                                              response.exception?.toString(),
                                        ),
                                      ));
                                      return;
                                    } else if (response.value!.warningMessage !=
                                            null &&
                                        response.value!.warningMessage!
                                            .isNotEmpty) {
                                      shouldCancel = await showDialog<bool?>(
                                        context: context,
                                        barrierDismissible: true,
                                        builder: (_) => StackDialog(
                                          title:
                                              "Failed to update trade estimate",
                                          message:
                                              "${response.value!.warningMessage!}\n\nDo you want to attempt trade anyways?",
                                          leftButton: TextButton(
                                            style: Theme.of(context)
                                                .textButtonTheme
                                                .style
                                                ?.copyWith(
                                                  backgroundColor:
                                                      MaterialStateProperty.all<
                                                          Color>(
                                                    CFColors.buttonGray,
                                                  ),
                                                ),
                                            child: Text(
                                              "Cancel",
                                              style: STextStyles.itemSubtitle12,
                                            ),
                                            onPressed: () {
                                              // notify return to cancel
                                              Navigator.of(context).pop(true);
                                            },
                                          ),
                                          rightButton: TextButton(
                                            style: Theme.of(context)
                                                .textButtonTheme
                                                .style
                                                ?.copyWith(
                                                  backgroundColor:
                                                      MaterialStateProperty.all<
                                                          Color>(
                                                    CFColors.stackAccent,
                                                  ),
                                                ),
                                            child: Text(
                                              "Attempt",
                                              style: STextStyles.button,
                                            ),
                                            onPressed: () {
                                              // continue and try to attempt trade
                                              Navigator.of(context).pop(false);
                                            },
                                          ),
                                        ),
                                      );
                                    }

                                    if (shouldCancel is bool && shouldCancel) {
                                      return;
                                    }

                                    String rate =
                                        "1 $fromTicker ~${ref.read(fixedRateExchangeFormProvider).market!.rate.toStringAsFixed(8)} $toTicker";

                                    final model = IncompleteExchangeModel(
                                      sendTicker: fromTicker,
                                      receiveTicker: toTicker,
                                      rateInfo: rate,
                                      sendAmount: sendAmount,
                                      receiveAmount:
                                          response.value!.estimatedAmount,
                                      rateId: response.value!.rateId,
                                      rateType: rateType,
                                    );

                                    if (mounted) {
                                      ref
                                          .read(
                                              exchangeSendFromWalletIdStateProvider
                                                  .state)
                                          .state = Tuple2(walletId, coin);
                                      unawaited(Navigator.of(context).pushNamed(
                                        Step2View.routeName,
                                        arguments: model,
                                      ));
                                    }
                                  }
                                }
                              : null,
                          child: Text(
                            "Next",
                            style: STextStyles.button,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

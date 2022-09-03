import 'dart:async';

import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_svg/svg.dart';
import 'package:stackwallet/models/exchange/change_now/available_floating_rate_pair.dart';
import 'package:stackwallet/models/exchange/change_now/currency.dart';
import 'package:stackwallet/models/exchange/change_now/fixed_rate_market.dart';
import 'package:stackwallet/models/exchange/incomplete_exchange.dart';
import 'package:stackwallet/notifications/show_flush_bar.dart';
import 'package:stackwallet/pages/exchange_view/exchange_coin_selection/fixed_rate_pair_coin_selection_view.dart';
import 'package:stackwallet/pages/exchange_view/exchange_coin_selection/floating_rate_currency_selection_view.dart';
import 'package:stackwallet/pages/exchange_view/exchange_step_views/step_1_view.dart';
import 'package:stackwallet/pages/exchange_view/sub_widgets/exchange_rate_sheet.dart';
import 'package:stackwallet/pages/exchange_view/trade_details_view.dart';
import 'package:stackwallet/providers/exchange/available_currencies_state_provider.dart';
import 'package:stackwallet/providers/exchange/available_floating_rate_pairs_state_provider.dart';
import 'package:stackwallet/providers/exchange/change_now_provider.dart';
import 'package:stackwallet/providers/exchange/changenow_initial_load_status.dart';
import 'package:stackwallet/providers/exchange/estimate_rate_exchange_form_provider.dart';
import 'package:stackwallet/providers/exchange/exchange_send_from_wallet_id_provider.dart';
import 'package:stackwallet/providers/exchange/fixed_rate_exchange_form_provider.dart';
import 'package:stackwallet/providers/exchange/fixed_rate_market_pairs_provider.dart';
import 'package:stackwallet/providers/exchange/trade_sent_from_stack_lookup_provider.dart';
import 'package:stackwallet/providers/global/trades_service_provider.dart';
import 'package:stackwallet/providers/providers.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/cfcolors.dart';
import 'package:stackwallet/utilities/constants.dart';
import 'package:stackwallet/utilities/enums/flush_bar_type.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/widgets/custom_loading_overlay.dart';
import 'package:stackwallet/widgets/loading_indicator.dart';
import 'package:stackwallet/widgets/stack_dialog.dart';
import 'package:stackwallet/widgets/trade_card.dart';
import 'package:tuple/tuple.dart';

const kFixedRateEnabled = true;

class ExchangeView extends ConsumerStatefulWidget {
  const ExchangeView({Key? key}) : super(key: key);

  @override
  ConsumerState<ExchangeView> createState() => _ExchangeViewState();
}

class _ExchangeViewState extends ConsumerState<ExchangeView> {
  late final TextEditingController _sendController;
  late final TextEditingController _receiveController;

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
    _sendController = TextEditingController();
    _receiveController = TextEditingController();

    final isEstimated =
        ref.read(prefsChangeNotifierProvider).exchangeRateType ==
            ExchangeRateType.estimated;
    _sendController.text = isEstimated
        ? ref.read(estimatedRateExchangeFormProvider).fromAmountString
        : ref.read(fixedRateExchangeFormProvider).fromAmountString;
    _receiveController.text = isEstimated
        ? ref.read(estimatedRateExchangeFormProvider).toAmountString
        : ref.read(fixedRateExchangeFormProvider).toAmountString;

    _sendFocusNode.addListener(() async {
      if (!_sendFocusNode.hasFocus) {
        final newFromAmount = Decimal.tryParse(_sendController.text);
        if (newFromAmount != null) {
          if (ref.read(prefsChangeNotifierProvider).exchangeRateType ==
              ExchangeRateType.estimated) {
            await ref
                .read(estimatedRateExchangeFormProvider)
                .setFromAmountAndCalculateToAmount(newFromAmount, true);
          } else {
            await ref
                .read(fixedRateExchangeFormProvider)
                .setFromAmountAndCalculateToAmount(newFromAmount, true);
          }
        } else {
          if (ref.read(prefsChangeNotifierProvider).exchangeRateType ==
              ExchangeRateType.estimated) {
            await ref
                .read(estimatedRateExchangeFormProvider)
                .setFromAmountAndCalculateToAmount(Decimal.zero, true);
          } else {
            await ref
                .read(fixedRateExchangeFormProvider)
                .setFromAmountAndCalculateToAmount(Decimal.zero, true);
          }
          _receiveController.text = "";
        }
      }
    });
    _receiveFocusNode.addListener(() async {
      if (!_receiveFocusNode.hasFocus) {
        final newToAmount = Decimal.tryParse(_receiveController.text);
        if (newToAmount != null) {
          if (ref.read(prefsChangeNotifierProvider).exchangeRateType ==
              ExchangeRateType.estimated) {
            // await ref
            //     .read(estimatedRateExchangeFormProvider)
            //     .setToAmountAndCalculateFromAmount(newToAmount, true);
          } else {
            await ref
                .read(fixedRateExchangeFormProvider)
                .setToAmountAndCalculateFromAmount(newToAmount, true);
          }
        } else {
          if (ref.read(prefsChangeNotifierProvider).exchangeRateType ==
              ExchangeRateType.estimated) {
            // await ref
            //     .read(estimatedRateExchangeFormProvider)
            //     .setToAmountAndCalculateFromAmount(Decimal.zero, true);
          } else {
            await ref
                .read(fixedRateExchangeFormProvider)
                .setToAmountAndCalculateFromAmount(Decimal.zero, true);
          }
          _sendController.text = "";
        }
      }
    });

    super.initState();
  }

  @override
  void dispose() {
    _receiveController.dispose();
    _sendController.dispose();
    super.dispose();
  }

  String calcSend = "";
  String calcReceive = "";

  final FocusNode _sendFocusNode = FocusNode();
  final FocusNode _receiveFocusNode = FocusNode();

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

    return SafeArea(
      child: NestedScrollView(
        floatHeaderSlivers: true,
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverOverlapAbsorber(
              handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
              sliver: SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(
                        height: 20,
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
                                      newFromAmount, false);
                            } else {
                              await ref
                                  .read(fixedRateExchangeFormProvider)
                                  .setFromAmountAndCalculateToAmount(
                                      newFromAmount, false);
                            }
                          } else {
                            if (ref
                                    .read(prefsChangeNotifierProvider)
                                    .exchangeRateType ==
                                ExchangeRateType.estimated) {
                              await ref
                                  .read(estimatedRateExchangeFormProvider)
                                  .setFromAmountAndCalculateToAmount(
                                      Decimal.zero, false);
                            } else {
                              await ref
                                  .read(fixedRateExchangeFormProvider)
                                  .setFromAmountAndCalculateToAmount(
                                      Decimal.zero, false);
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
                                      fromTicker: ref
                                              .read(
                                                  estimatedRateExchangeFormProvider)
                                              .from
                                              ?.ticker ??
                                          "-",
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
                                                  e.from == selectedFromTicker,
                                            );

                                        await ref
                                            .read(fixedRateExchangeFormProvider)
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
                                            if (ref.watch(
                                                    prefsChangeNotifierProvider
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
                                                          BorderRadius.circular(
                                                        18,
                                                      ),
                                                    ),
                                                    child: ClipRRect(
                                                      borderRadius:
                                                          BorderRadius.circular(
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
                                                      BorderRadius.circular(18),
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
                                        style: STextStyles.smallMed14.copyWith(
                                          color: CFColors.stackAccent,
                                        ),
                                      ),
                                      const SizedBox(
                                        width: 6,
                                      ),
                                      SvgPicture.asset(
                                        Assets.svg.chevronDown,
                                        width: 5,
                                        height: 2.5,
                                        color: CFColors.stackAccent,
                                      ),
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
                        readOnly: ref
                                .read(prefsChangeNotifierProvider)
                                .exchangeRateType ==
                            ExchangeRateType.estimated,
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
                              // await ref
                              //     .read(estimatedRateExchangeFormProvider)
                              //     .setToAmountAndCalculateFromAmount(
                              //         newToAmount, false);
                            } else {
                              await ref
                                  .read(fixedRateExchangeFormProvider)
                                  .setToAmountAndCalculateFromAmount(
                                      newToAmount, false);
                            }
                          } else {
                            if (ref
                                    .read(prefsChangeNotifierProvider)
                                    .exchangeRateType ==
                                ExchangeRateType.estimated) {
                              // await ref
                              //     .read(estimatedRateExchangeFormProvider)
                              //     .setToAmountAndCalculateFromAmount(
                              //         Decimal.zero, false);
                            } else {
                              await ref
                                  .read(fixedRateExchangeFormProvider)
                                  .setToAmountAndCalculateFromAmount(
                                      Decimal.zero, false);
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
                                            .read(fixedRateExchangeFormProvider)
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
                                            if (ref.watch(
                                                    prefsChangeNotifierProvider
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
                                                          BorderRadius.circular(
                                                              18),
                                                    ),
                                                    child: ClipRRect(
                                                      borderRadius:
                                                          BorderRadius.circular(
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
                                                      BorderRadius.circular(18),
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
                                        style: STextStyles.smallMed14.copyWith(
                                          color: CFColors.stackAccent,
                                        ),
                                      ),
                                      const SizedBox(
                                        width: 6,
                                      ),
                                      SvgPicture.asset(
                                        Assets.svg.chevronDown,
                                        width: 5,
                                        height: 2.5,
                                        color: CFColors.stackAccent,
                                      ),
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
                                    final from = availableCurrencies.firstWhere(
                                        (e) => e.ticker == fromTicker);
                                    final to = availableCurrencies.firstWhere(
                                        (e) => e.ticker == toTicker);

                                    await ref
                                        .read(estimatedRateExchangeFormProvider)
                                        .updateTo(to, false);
                                    await ref
                                        .read(estimatedRateExchangeFormProvider)
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
                                    .updateMarket(market, false);
                                await ref
                                    .read(fixedRateExchangeFormProvider)
                                    .setFromAmountAndCalculateToAmount(
                                      Decimal.tryParse(_sendController.text) ??
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
                      TextButton(
                        style: Theme.of(context)
                            .textButtonTheme
                            .style
                            ?.copyWith(
                              backgroundColor: MaterialStateProperty.all<Color>(
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
                                if (ref
                                        .read(prefsChangeNotifierProvider)
                                        .exchangeRateType ==
                                    ExchangeRateType.estimated) {
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

                                  final sendAmount = Decimal.parse(ref
                                      .read(estimatedRateExchangeFormProvider)
                                      .fromAmountString);

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
                                        message: response.exception?.toString(),
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
                                        .state = null;
                                    unawaited(Navigator.of(context).pushNamed(
                                      Step1View.routeName,
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
                                        message: response.exception?.toString(),
                                      ),
                                    ));
                                    return;
                                  } else if (response.value!.warningMessage !=
                                          null &&
                                      response
                                          .value!.warningMessage!.isNotEmpty) {
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
                                        .state = null;
                                    unawaited(Navigator.of(context).pushNamed(
                                      Step1View.routeName,
                                      arguments: model,
                                    ));
                                  }
                                }
                              }
                            : null,
                        child: Text(
                          "Exchange",
                          style: STextStyles.button,
                        ),
                      ),
                      const SizedBox(
                        height: 20,
                      ),
                      // Text(
                      //   "Trades",
                      //   style: STextStyles.itemSubtitle.copyWith(
                      //     color: CFColors.neutral50,
                      //   ),
                      // ),
                      // SizedBox(
                      //   height: 12,
                      // ),
                    ],
                  ),
                ),
              ),
            )
          ];
        },
        body: Builder(
          builder: (buildContext) {
            final trades = ref
                .watch(tradesServiceProvider.select((value) => value.trades));
            final tradeCount = trades.length;
            final hasHistory = tradeCount > 0;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: CustomScrollView(
                slivers: [
                  SliverOverlapInjector(
                    handle: NestedScrollView.sliverOverlapAbsorberHandleFor(
                        buildContext),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(
                            height: 12,
                          ),
                          Text(
                            "Trades",
                            style: STextStyles.itemSubtitle.copyWith(
                              color: CFColors.neutral50,
                            ),
                          ),
                          const SizedBox(
                            height: 12,
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (hasHistory)
                    SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        return Padding(
                          padding: const EdgeInsets.all(4),
                          child: TradeCard(
                            key: Key("tradeCard_${trades[index].uuid}"),
                            trade: trades[index],
                            onTap: () async {
                              final String tradeId = trades[index].id;

                              final lookup = ref
                                  .read(tradeSentFromStackLookupProvider)
                                  .all;

                              debugPrint("ALL: $lookup");

                              final String? txid = ref
                                  .read(tradeSentFromStackLookupProvider)
                                  .getTxidForTradeId(tradeId);
                              final List<String>? walletIds = ref
                                  .read(tradeSentFromStackLookupProvider)
                                  .getWalletIdsForTradeId(tradeId);

                              if (txid != null &&
                                  walletIds != null &&
                                  walletIds.isNotEmpty) {
                                final manager = ref
                                    .read(walletsChangeNotifierProvider)
                                    .getManager(walletIds.first);

                                debugPrint("name: ${manager.walletName}");

                                final txData = await manager.transactionData;

                                final tx = txData.getAllTransactions()[txid];

                                if (mounted) {
                                  unawaited(Navigator.of(context).pushNamed(
                                    TradeDetailsView.routeName,
                                    arguments: Tuple4(tradeId, tx,
                                        walletIds.first, manager.walletName),
                                  ));
                                }
                              } else {
                                unawaited(Navigator.of(context).pushNamed(
                                  TradeDetailsView.routeName,
                                  arguments: Tuple4(
                                      tradeId, null, walletIds?.first, null),
                                ));
                              }
                            },
                          ),
                        );
                      }, childCount: tradeCount),
                    ),
                  if (!hasHistory)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Container(
                          decoration: BoxDecoration(
                            color: CFColors.white,
                            borderRadius: BorderRadius.circular(
                              Constants.size.circularBorderRadius,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Text(
                              "Trades will appear here",
                              textAlign: TextAlign.center,
                              style: STextStyles.itemSubtitle,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class RateInfo extends ConsumerWidget {
  const RateInfo({
    Key? key,
    required this.onChanged,
  }) : super(key: key);

  final void Function(ExchangeRateType) onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final type = ref.watch(
        prefsChangeNotifierProvider.select((pref) => pref.exchangeRateType));
    final isEstimated = type == ExchangeRateType.estimated;

    return Container(
      decoration: BoxDecoration(
        color: CFColors.white,
        borderRadius: BorderRadius.circular(
          Constants.size.circularBorderRadius,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton(
              onPressed: kFixedRateEnabled
                  ? () async {
                      if (isEstimated) {
                        if (ref
                                .read(
                                    changeNowFixedInitialLoadStatusStateProvider
                                        .state)
                                .state ==
                            ChangeNowLoadStatus.loading) {
                          bool userPoppedDialog = false;
                          await showDialog<void>(
                            context: context,
                            builder: (context) => Consumer(
                              builder: (context, ref, __) {
                                return StackOkDialog(
                                  title: "Loading rate data...",
                                  message:
                                      "Performing initial fetch of ChangeNOW fixed rate market data",
                                  onOkPressed: (value) {
                                    userPoppedDialog = value == "OK";
                                  },
                                );
                              },
                            ),
                          );
                          if (ref
                                  .read(
                                      changeNowFixedInitialLoadStatusStateProvider
                                          .state)
                                  .state ==
                              ChangeNowLoadStatus.loading) {
                            return;
                          }
                        }
                      }

                      unawaited(showModalBottomSheet<dynamic>(
                        backgroundColor: Colors.transparent,
                        context: context,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(20),
                          ),
                        ),
                        builder: (_) => const ExchangeRateSheet(),
                      ).then((value) {
                        if (value is ExchangeRateType && value != type) {
                          onChanged(value);
                        }
                      }));
                    }
                  : null,
              style: Theme.of(context).textButtonTheme.style?.copyWith(
                    minimumSize: MaterialStateProperty.all(
                      const Size(0, 0),
                    ),
                    padding: MaterialStateProperty.all<EdgeInsetsGeometry>(
                      const EdgeInsets.all(2),
                    ),
                    backgroundColor: MaterialStateProperty.all<Color>(
                      Colors.transparent,
                    ),
                  ),
              child: Row(
                children: [
                  Text(
                    isEstimated ? "Estimated rate" : "Fixed rate",
                    style: STextStyles.itemSubtitle,
                  ),
                  const SizedBox(
                    width: 6,
                  ),
                  if (kFixedRateEnabled)
                    SvgPicture.asset(
                      Assets.svg.chevronDown,
                      width: 5,
                      height: 2.5,
                      color: CFColors.neutral60,
                    ),
                ],
              ),
            ),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  minWidth: 1,
                ),
                child: Text(
                  isEstimated
                      ? ref.watch(estimatedRateExchangeFormProvider
                          .select((value) => value.rateDisplayString))
                      : ref.watch(fixedRateExchangeFormProvider
                          .select((value) => value.rateDisplayString)),
                  style: STextStyles.itemSubtitle12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

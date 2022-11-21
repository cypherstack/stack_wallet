import 'dart:async';

import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_svg/svg.dart';
import 'package:stackwallet/models/exchange/incomplete_exchange.dart';
import 'package:stackwallet/models/exchange/response_objects/currency.dart';
import 'package:stackwallet/models/exchange/response_objects/fixed_rate_market.dart';
import 'package:stackwallet/models/exchange/response_objects/pair.dart';
import 'package:stackwallet/notifications/show_flush_bar.dart';
import 'package:stackwallet/pages/exchange_view/exchange_coin_selection/fixed_rate_pair_coin_selection_view.dart';
import 'package:stackwallet/pages/exchange_view/exchange_coin_selection/floating_rate_currency_selection_view.dart';
import 'package:stackwallet/pages/exchange_view/exchange_step_views/step_1_view.dart';
import 'package:stackwallet/pages/exchange_view/exchange_step_views/step_2_view.dart';
import 'package:stackwallet/pages/exchange_view/sub_widgets/exchange_provider_options.dart';
import 'package:stackwallet/pages/exchange_view/sub_widgets/exchange_rate_sheet.dart';
import 'package:stackwallet/pages/exchange_view/sub_widgets/rate_type_toggle.dart';
import 'package:stackwallet/pages_desktop_specific/desktop_exchange/exchange_steps/step_scaffold.dart';
import 'package:stackwallet/pages_desktop_specific/desktop_exchange/exchange_steps/subwidgets/desktop_step_1.dart';
import 'package:stackwallet/pages_desktop_specific/desktop_exchange/exchange_steps/subwidgets/desktop_step_2.dart';
import 'package:stackwallet/providers/providers.dart';
import 'package:stackwallet/services/exchange/change_now/change_now_exchange.dart';
import 'package:stackwallet/services/exchange/simpleswap/simpleswap_exchange.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/utilities/logger.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';
import 'package:stackwallet/utilities/util.dart';
import 'package:stackwallet/widgets/conditional_parent.dart';
import 'package:stackwallet/widgets/custom_loading_overlay.dart';
import 'package:stackwallet/widgets/desktop/desktop_dialog.dart';
import 'package:stackwallet/widgets/desktop/desktop_dialog_close_button.dart';
import 'package:stackwallet/widgets/desktop/primary_button.dart';
import 'package:stackwallet/widgets/desktop/secondary_button.dart';
import 'package:stackwallet/widgets/desktop/simple_desktop_dialog.dart';
import 'package:stackwallet/widgets/loading_indicator.dart';
import 'package:stackwallet/widgets/rounded_container.dart';
import 'package:stackwallet/widgets/rounded_white_container.dart';
import 'package:stackwallet/widgets/stack_dialog.dart';
import 'package:tuple/tuple.dart';

class ExchangeForm extends ConsumerStatefulWidget {
  const ExchangeForm({
    Key? key,
    this.walletId,
    this.coin,
  }) : super(key: key);

  final String? walletId;
  final Coin? coin;

  @override
  ConsumerState<ExchangeForm> createState() => _ExchangeFormState();
}

class _ExchangeFormState extends ConsumerState<ExchangeForm> {
  late final String? walletId;
  late final Coin? coin;
  late final bool walletInitiated;

  late final TextEditingController _sendController;
  late final TextEditingController _receiveController;
  final isDesktop = Util.isDesktop;
  final FocusNode _sendFocusNode = FocusNode();
  final FocusNode _receiveFocusNode = FocusNode();

  bool _swapLock = false;

  void sendFieldOnChanged(String value) async {
    final newFromAmount = Decimal.tryParse(value);

    ref.read(exchangeFormStateProvider).fromAmount =
        newFromAmount ?? Decimal.zero;

    if (newFromAmount == null) {
      _receiveController.text =
          ref.read(prefsChangeNotifierProvider).exchangeRateType ==
                  ExchangeRateType.estimated
              ? "-"
              : "";
    }
  }

  void selectSendCurrency() async {
    if (ref.read(prefsChangeNotifierProvider).exchangeRateType ==
        ExchangeRateType.estimated) {
      final fromTicker = ref.read(exchangeFormStateProvider).fromTicker ?? "-";
      // ref.read(estimatedRateExchangeFormProvider).from?.ticker ?? "-";

      if (walletInitiated &&
          fromTicker.toLowerCase() == coin!.ticker.toLowerCase()) {
        // do not allow changing away from wallet coin
        return;
      }

      List<Currency> currencies;
      switch (ref.read(currentExchangeNameStateProvider.state).state) {
        case ChangeNowExchange.exchangeName:
          currencies =
              ref.read(availableChangeNowCurrenciesProvider).currencies;
          break;
        case SimpleSwapExchange.exchangeName:
          currencies = ref
              .read(availableSimpleswapCurrenciesProvider)
              .floatingRateCurrencies;
          break;
        default:
          currencies = [];
      }

      await _showFloatingRateSelectionSheet(
          currencies: currencies,
          excludedTicker: ref.read(exchangeFormStateProvider).toTicker ?? "-",
          fromTicker: fromTicker,
          onSelected: (from) =>
              ref.read(exchangeFormStateProvider).updateFrom(from, true));
    } else {
      final toTicker = ref.read(exchangeFormStateProvider).toTicker ?? "";
      final fromTicker = ref.read(exchangeFormStateProvider).fromTicker ?? "";

      if (walletInitiated &&
          fromTicker.toLowerCase() == coin!.ticker.toLowerCase()) {
        // do not allow changing away from wallet coin
        return;
      }

      switch (ref.read(currentExchangeNameStateProvider.state).state) {
        case ChangeNowExchange.exchangeName:
          await _showFixedRateSelectionSheet(
            excludedTicker: toTicker,
            fromTicker: fromTicker,
            onSelected: (selectedFromTicker) async {
              try {
                final market = ref
                    .read(availableChangeNowCurrenciesProvider)
                    .markets
                    .firstWhere(
                      (e) => e.to == toTicker && e.from == selectedFromTicker,
                    );

                await ref
                    .read(exchangeFormStateProvider)
                    .updateMarket(market, true);
              } catch (e) {
                unawaited(
                  showDialog<dynamic>(
                    context: context,
                    builder: (_) {
                      if (isDesktop) {
                        return const SimpleDesktopDialog(
                          title: "Fixed rate market error",
                          message:
                              "Could not find the specified fixed rate trade pair",
                        );
                      } else {
                        return const StackDialog(
                          title: "Fixed rate market error",
                          message:
                              "Could not find the specified fixed rate trade pair",
                        );
                      }
                    },
                  ),
                );

                return;
              }
            },
          );
          break;
        case SimpleSwapExchange.exchangeName:
          await _showFloatingRateSelectionSheet(
              currencies: ref
                  .read(availableSimpleswapCurrenciesProvider)
                  .fixedRateCurrencies,
              excludedTicker:
                  ref.read(exchangeFormStateProvider).toTicker ?? "-",
              fromTicker: fromTicker,
              onSelected: (from) =>
                  ref.read(exchangeFormStateProvider).updateFrom(from, true));
          break;
        default:
        // TODO show error?
      }
    }
  }

  void selectReceiveCurrency() async {
    if (ref.read(prefsChangeNotifierProvider).exchangeRateType ==
        ExchangeRateType.estimated) {
      final toTicker = ref.read(exchangeFormStateProvider).toTicker ?? "";

      if (walletInitiated &&
          toTicker.toLowerCase() == coin!.ticker.toLowerCase()) {
        // do not allow changing away from wallet coin
        return;
      }

      List<Currency> currencies;
      switch (ref.read(currentExchangeNameStateProvider.state).state) {
        case ChangeNowExchange.exchangeName:
          currencies =
              ref.read(availableChangeNowCurrenciesProvider).currencies;
          break;
        case SimpleSwapExchange.exchangeName:
          currencies = ref
              .read(availableSimpleswapCurrenciesProvider)
              .floatingRateCurrencies;
          break;
        default:
          currencies = [];
      }

      await _showFloatingRateSelectionSheet(
          currencies: currencies,
          excludedTicker: ref.read(exchangeFormStateProvider).fromTicker ?? "",
          fromTicker: ref.read(exchangeFormStateProvider).fromTicker ?? "",
          onSelected: (to) =>
              ref.read(exchangeFormStateProvider).updateTo(to, true));
    } else {
      final fromTicker = ref.read(exchangeFormStateProvider).fromTicker ?? "";
      final toTicker = ref.read(exchangeFormStateProvider).toTicker ?? "";

      if (walletInitiated &&
          toTicker.toLowerCase() == coin!.ticker.toLowerCase()) {
        // do not allow changing away from wallet coin
        return;
      }

      switch (ref.read(currentExchangeNameStateProvider.state).state) {
        case ChangeNowExchange.exchangeName:
          await _showFixedRateSelectionSheet(
            excludedTicker: fromTicker,
            fromTicker: fromTicker,
            onSelected: (selectedToTicker) async {
              try {
                final market = ref
                    .read(availableChangeNowCurrenciesProvider)
                    .markets
                    .firstWhere(
                      (e) => e.to == selectedToTicker && e.from == fromTicker,
                    );

                await ref
                    .read(exchangeFormStateProvider)
                    .updateMarket(market, true);
              } catch (e) {
                unawaited(
                  showDialog<dynamic>(
                    context: context,
                    builder: (_) {
                      if (isDesktop) {
                        return const SimpleDesktopDialog(
                          title: "Fixed rate market error",
                          message:
                              "Could not find the specified fixed rate trade pair",
                        );
                      } else {
                        return const StackDialog(
                          title: "Fixed rate market error",
                          message:
                              "Could not find the specified fixed rate trade pair",
                        );
                      }
                    },
                  ),
                );
                return;
              }
            },
          );
          break;
        case SimpleSwapExchange.exchangeName:
          await _showFloatingRateSelectionSheet(
              currencies: ref
                  .read(availableSimpleswapCurrenciesProvider)
                  .fixedRateCurrencies,
              excludedTicker:
                  ref.read(exchangeFormStateProvider).fromTicker ?? "",
              fromTicker: ref.read(exchangeFormStateProvider).fromTicker ?? "",
              onSelected: (to) =>
                  ref.read(exchangeFormStateProvider).updateTo(to, true));
          break;
        default:
        // TODO show error?
      }
    }
  }

  void receiveFieldOnChanged(String value) async {
    final newToAmount = Decimal.tryParse(value);
    final isEstimated =
        ref.read(prefsChangeNotifierProvider).exchangeRateType ==
            ExchangeRateType.estimated;
    if (!isEstimated) {
      ref.read(exchangeFormStateProvider).toAmount =
          newToAmount ?? Decimal.zero;
    }
    if (newToAmount == null) {
      _sendController.text = "";
    }
  }

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
            color: Theme.of(context)
                .extension<StackColors>()!
                .overlay
                .withOpacity(0.6),
            child: const CustomLoadingOverlay(
              message: "Updating exchange rate",
              eventBus: null,
            ),
          ),
        ),
      ),
    );

    if (ref.read(prefsChangeNotifierProvider).exchangeRateType ==
            ExchangeRateType.fixed &&
        ref.read(exchangeFormStateProvider).exchange?.name ==
            ChangeNowExchange.exchangeName) {
      final from = ref.read(exchangeFormStateProvider).fromTicker;
      final to = ref.read(exchangeFormStateProvider).toTicker;

      if (to != null && from != null) {
        final markets = ref
            .read(availableChangeNowCurrenciesProvider)
            .markets
            .where((e) => e.from == to && e.to == from);

        if (markets.isNotEmpty) {
          await ref.read(exchangeFormStateProvider).swap(market: markets.first);
        } else {
          Logging.instance.log(
            "swap to fixed rate market failed",
            level: LogLevel.Warning,
          );
        }
      }
    } else {
      await ref.read(exchangeFormStateProvider).swap();
    }
    if (mounted) {
      Navigator.of(context, rootNavigator: isDesktop).pop();
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

    List<Pair> allPairs;

    switch (ref.read(currentExchangeNameStateProvider.state).state) {
      case ChangeNowExchange.exchangeName:
        allPairs = ref.read(availableChangeNowCurrenciesProvider).pairs;
        break;
      case SimpleSwapExchange.exchangeName:
        allPairs = ref.read(exchangeFormStateProvider).exchangeType ==
                ExchangeRateType.fixed
            ? ref.read(availableSimpleswapCurrenciesProvider).fixedRatePairs
            : ref.read(availableSimpleswapCurrenciesProvider).floatingRatePairs;
        break;
      default:
        allPairs = [];
    }

    List<Pair> availablePairs;
    if (fromTicker.isEmpty ||
        fromTicker == "-" ||
        excludedTicker.isEmpty ||
        excludedTicker == "-") {
      availablePairs = allPairs;
    } else if (excludedTicker == fromTicker) {
      availablePairs = allPairs
          .where((e) => e.from == excludedTicker)
          .toList(growable: false);
    } else {
      availablePairs =
          allPairs.where((e) => e.to == excludedTicker).toList(growable: false);
    }

    final List<Currency> tickers = currencies.where((e) {
      if (excludedTicker == fromTicker) {
        return e.ticker != excludedTicker &&
            availablePairs.where((e2) => e2.to == e.ticker).isNotEmpty;
      } else {
        return e.ticker != excludedTicker &&
            availablePairs.where((e2) => e2.from == e.ticker).isNotEmpty;
      }
    }).toList(growable: false);

    final result = isDesktop
        ? await showDialog<Currency?>(
            context: context,
            builder: (context) {
              return DesktopDialog(
                maxHeight: 700,
                maxWidth: 580,
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(
                            left: 32,
                          ),
                          child: Text(
                            "Choose a coin to exchange",
                            style: STextStyles.desktopH3(context),
                          ),
                        ),
                        const DesktopDialogCloseButton(),
                      ],
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(
                          left: 32,
                          right: 32,
                          bottom: 32,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: RoundedWhiteContainer(
                                padding: const EdgeInsets.all(16),
                                borderColor: Theme.of(context)
                                    .extension<StackColors>()!
                                    .background,
                                child: FloatingRateCurrencySelectionView(
                                  currencies: tickers,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            })
        : await Navigator.of(context).push(
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

  String? _fetchIconUrlFromTicker(String? ticker) {
    if (ticker == null) return null;

    Iterable<Currency> possibleCurrencies;

    switch (ref.read(currentExchangeNameStateProvider.state).state) {
      case ChangeNowExchange.exchangeName:
        possibleCurrencies = ref
            .read(availableChangeNowCurrenciesProvider)
            .currencies
            .where((e) => e.ticker.toUpperCase() == ticker.toUpperCase());
        break;
      case SimpleSwapExchange.exchangeName:
        possibleCurrencies = [
          ...ref
              .read(availableSimpleswapCurrenciesProvider)
              .fixedRateCurrencies
              .where((e) => e.ticker.toUpperCase() == ticker.toUpperCase()),
          ...ref
              .read(availableSimpleswapCurrenciesProvider)
              .floatingRateCurrencies
              .where((e) => e.ticker.toUpperCase() == ticker.toUpperCase()),
        ];
        break;
      default:
        possibleCurrencies = [];
    }

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
          ref.read(availableChangeNowCurrenciesProvider).markets;
    } else if (excludedTicker == fromTicker) {
      marketsThatPairWithExcludedTicker = ref
          .read(availableChangeNowCurrenciesProvider)
          .markets
          .where((e) => e.from == excludedTicker && e.to != excludedTicker)
          .toList(growable: false);
    } else {
      marketsThatPairWithExcludedTicker = ref
          .read(availableChangeNowCurrenciesProvider)
          .markets
          .where((e) => e.to == excludedTicker && e.from != excludedTicker)
          .toList(growable: false);
    }

    final result = isDesktop
        ? await showDialog<String?>(
            context: context,
            builder: (context) {
              return DesktopDialog(
                maxHeight: 700,
                maxWidth: 580,
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(
                            left: 32,
                          ),
                          child: Text(
                            "Choose a coin to exchange",
                            style: STextStyles.desktopH3(context),
                          ),
                        ),
                        const DesktopDialogCloseButton(),
                      ],
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(
                          left: 32,
                          right: 32,
                          bottom: 32,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: RoundedWhiteContainer(
                                padding: const EdgeInsets.all(16),
                                borderColor: Theme.of(context)
                                    .extension<StackColors>()!
                                    .background,
                                child: FixedRateMarketPairCoinSelectionView(
                                  markets: marketsThatPairWithExcludedTicker,
                                  currencies: ref
                                      .read(
                                          availableChangeNowCurrenciesProvider)
                                      .currencies,
                                  isFrom: excludedTicker != fromTicker,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            })
        : await Navigator.of(context).push(
            MaterialPageRoute<dynamic>(
              builder: (_) => FixedRateMarketPairCoinSelectionView(
                markets: marketsThatPairWithExcludedTicker,
                currencies:
                    ref.read(availableChangeNowCurrenciesProvider).currencies,
                isFrom: excludedTicker != fromTicker,
              ),
            ),
          );

    if (mounted && result is String) {
      onSelected(result);
    }
  }

  void onRateTypeChanged(ExchangeRateType rateType) async {
    _receiveFocusNode.unfocus();
    _sendFocusNode.unfocus();

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
              message: "Updating exchange rate",
              eventBus: null,
            ),
          ),
        ),
      ),
    );

    final fromTicker = ref.read(exchangeFormStateProvider).fromTicker ?? "-";
    final toTicker = ref.read(exchangeFormStateProvider).toTicker ?? "-";

    ref.read(exchangeFormStateProvider).exchangeType = rateType;
    ref.read(exchangeFormStateProvider).reversed = false;
    switch (rateType) {
      case ExchangeRateType.estimated:
        if (!(toTicker == "-" || fromTicker == "-")) {
          late final Iterable<Pair> available;

          switch (ref.read(currentExchangeNameStateProvider.state).state) {
            case ChangeNowExchange.exchangeName:
              available = ref
                  .read(availableChangeNowCurrenciesProvider)
                  .pairs
                  .where((e) => e.to == toTicker && e.from == fromTicker);
              break;
            case SimpleSwapExchange.exchangeName:
              available = ref
                  .read(availableSimpleswapCurrenciesProvider)
                  .floatingRatePairs
                  .where((e) => e.to == toTicker && e.from == fromTicker);
              break;
            default:
              available = [];
          }

          if (available.isNotEmpty) {
            late final Iterable<Currency> availableCurrencies;
            switch (ref.read(currentExchangeNameStateProvider.state).state) {
              case ChangeNowExchange.exchangeName:
                availableCurrencies = ref
                    .read(availableChangeNowCurrenciesProvider)
                    .currencies
                    .where(
                        (e) => e.ticker == fromTicker || e.ticker == toTicker);
                break;
              case SimpleSwapExchange.exchangeName:
                availableCurrencies = ref
                    .read(availableSimpleswapCurrenciesProvider)
                    .floatingRateCurrencies
                    .where(
                        (e) => e.ticker == fromTicker || e.ticker == toTicker);
                break;
              default:
                availableCurrencies = [];
            }

            if (availableCurrencies.length > 1) {
              final from =
                  availableCurrencies.firstWhere((e) => e.ticker == fromTicker);
              final to =
                  availableCurrencies.firstWhere((e) => e.ticker == toTicker);

              final newFromAmount = Decimal.tryParse(_sendController.text);
              ref.read(exchangeFormStateProvider).fromAmount =
                  newFromAmount ?? Decimal.zero;
              if (newFromAmount == null) {
                _receiveController.text = "";
              }

              await ref.read(exchangeFormStateProvider).updateTo(to, false);
              await ref.read(exchangeFormStateProvider).updateFrom(from, true);

              _receiveController.text =
                  ref.read(exchangeFormStateProvider).toAmountString.isEmpty
                      ? "-"
                      : ref.read(exchangeFormStateProvider).toAmountString;
              if (mounted) {
                Navigator.of(context, rootNavigator: isDesktop).pop();
              }
              return;
            }
          }
        }
        if (mounted) {
          Navigator.of(context, rootNavigator: isDesktop).pop();
        }
        if (!(fromTicker == "-" || toTicker == "-")) {
          unawaited(
            showFloatingFlushBar(
              type: FlushBarType.warning,
              message:
                  "Estimated rate trade pair \"$fromTicker-$toTicker\" unavailable. Reverting to last estimated rate pair.",
              context: context,
            ),
          );
        }
        break;
      case ExchangeRateType.fixed:
        if (!(toTicker == "-" || fromTicker == "-")) {
          switch (ref.read(currentExchangeNameStateProvider.state).state) {
            case ChangeNowExchange.exchangeName:
              FixedRateMarket? market;
              try {
                market = ref
                    .read(availableChangeNowCurrenciesProvider)
                    .markets
                    .firstWhere(
                        (e) => e.from == fromTicker && e.to == toTicker);
              } catch (_) {
                market = null;
              }

              final newFromAmount = Decimal.tryParse(_sendController.text);
              ref.read(exchangeFormStateProvider).fromAmount =
                  newFromAmount ?? Decimal.zero;

              if (newFromAmount == null) {
                _receiveController.text = "";
              }

              await ref
                  .read(exchangeFormStateProvider)
                  .updateMarket(market, false);
              await ref
                  .read(exchangeFormStateProvider)
                  .setFromAmountAndCalculateToAmount(
                    Decimal.tryParse(_sendController.text) ?? Decimal.zero,
                    true,
                  );
              if (mounted) {
                Navigator.of(context, rootNavigator: isDesktop).pop();
              }
              return;
            case SimpleSwapExchange.exchangeName:
              final available = ref
                  .read(availableSimpleswapCurrenciesProvider)
                  .floatingRatePairs
                  .where((e) => e.to == toTicker && e.from == fromTicker);
              if (available.isNotEmpty) {
                final availableCurrencies = ref
                    .read(availableSimpleswapCurrenciesProvider)
                    .fixedRateCurrencies
                    .where(
                        (e) => e.ticker == fromTicker || e.ticker == toTicker);
                if (availableCurrencies.length > 1) {
                  final from = availableCurrencies
                      .firstWhere((e) => e.ticker == fromTicker);
                  final to = availableCurrencies
                      .firstWhere((e) => e.ticker == toTicker);

                  final newFromAmount = Decimal.tryParse(_sendController.text);
                  ref.read(exchangeFormStateProvider).fromAmount =
                      newFromAmount ?? Decimal.zero;
                  if (newFromAmount == null) {
                    _receiveController.text = "";
                  }

                  await ref.read(exchangeFormStateProvider).updateTo(to, false);
                  await ref
                      .read(exchangeFormStateProvider)
                      .updateFrom(from, true);

                  _receiveController.text =
                      ref.read(exchangeFormStateProvider).toAmountString.isEmpty
                          ? "-"
                          : ref.read(exchangeFormStateProvider).toAmountString;
                  if (mounted) {
                    Navigator.of(context, rootNavigator: isDesktop).pop();
                  }
                  return;
                }
              }

              break;
            default:
            //
          }
        }
        if (mounted) {
          Navigator.of(context, rootNavigator: isDesktop).pop();
        }
        unawaited(
          showFloatingFlushBar(
            type: FlushBarType.warning,
            message:
                "Fixed rate trade pair \"$fromTicker-$toTicker\" unavailable. Reverting to last fixed rate pair.",
            context: context,
          ),
        );
        break;
    }
  }

  void onExchangePressed() async {
    final rateType = ref.read(prefsChangeNotifierProvider).exchangeRateType;
    final fromTicker = ref.read(exchangeFormStateProvider).fromTicker ?? "";
    final toTicker = ref.read(exchangeFormStateProvider).toTicker ?? "";
    final sendAmount = ref.read(exchangeFormStateProvider).fromAmount!;
    final estimate = ref.read(exchangeFormStateProvider).estimate!;

    String rate;

    switch (rateType) {
      case ExchangeRateType.estimated:
        bool isAvailable = false;
        late final Iterable<Pair> availableFloatingPairs;

        switch (ref.read(currentExchangeNameStateProvider.state).state) {
          case ChangeNowExchange.exchangeName:
            availableFloatingPairs = ref
                .read(availableChangeNowCurrenciesProvider)
                .pairs
                .where((e) => e.to == toTicker && e.from == fromTicker);
            break;
          case SimpleSwapExchange.exchangeName:
            availableFloatingPairs = ref
                .read(availableSimpleswapCurrenciesProvider)
                .floatingRatePairs
                .where((e) => e.to == toTicker && e.from == fromTicker);
            break;
          default:
            availableFloatingPairs = [];
        }

        for (final pair in availableFloatingPairs) {
          if (pair.from == fromTicker && pair.to == toTicker) {
            isAvailable = true;
            break;
          }
        }

        if (!isAvailable) {
          unawaited(
            showDialog<dynamic>(
              context: context,
              barrierDismissible: true,
              builder: (_) {
                if (isDesktop) {
                  return SimpleDesktopDialog(
                    title: "Selected trade pair unavailable",
                    message:
                        "The $fromTicker - $toTicker market is currently disabled for estimated/floating rate trades",
                  );
                } else {
                  return StackDialog(
                    title: "Selected trade pair unavailable",
                    message:
                        "The $fromTicker - $toTicker market is currently disabled for estimated/floating rate trades",
                  );
                }
              },
            ),
          );
          return;
        }
        rate =
            "1 ${fromTicker.toUpperCase()} ~${(estimate.estimatedAmount / sendAmount).toDecimal(scaleOnInfinitePrecision: 8).toStringAsFixed(8)} ${toTicker.toUpperCase()}";
        break;
      case ExchangeRateType.fixed:
        bool? shouldCancel;

        if (estimate.warningMessage != null &&
            estimate.warningMessage!.isNotEmpty) {
          shouldCancel = await showDialog<bool?>(
            context: context,
            barrierDismissible: true,
            builder: (_) {
              if (isDesktop) {
                return DesktopDialog(
                  maxWidth: 500,
                  maxHeight: 300,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Failed to update trade estimate",
                            style: STextStyles.desktopH3(context),
                          ),
                          const DesktopDialogCloseButton(),
                        ],
                      ),
                      const Spacer(),
                      Text(
                        estimate.warningMessage!,
                        style: STextStyles.desktopTextSmall(context),
                      ),
                      const Spacer(),
                      Text(
                        "Do you want to attempt trade anyways?",
                        style: STextStyles.desktopTextSmall(context),
                      ),
                      const Spacer(
                        flex: 2,
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: SecondaryButton(
                              label: "Cancel",
                              buttonHeight: ButtonHeight.l,
                              onPressed: () => Navigator.of(
                                context,
                                rootNavigator: true,
                              ).pop(true),
                            ),
                          ),
                          const SizedBox(
                            width: 16,
                          ),
                          Expanded(
                            child: PrimaryButton(
                              label: "Attempt",
                              buttonHeight: ButtonHeight.l,
                              onPressed: () => Navigator.of(
                                context,
                                rootNavigator: true,
                              ).pop(false),
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                );
              } else {
                return StackDialog(
                  title: "Failed to update trade estimate",
                  message:
                      "${estimate.warningMessage!}\n\nDo you want to attempt trade anyways?",
                  leftButton: TextButton(
                    style: Theme.of(context)
                        .extension<StackColors>()!
                        .getSecondaryEnabledButtonColor(context),
                    child: Text(
                      "Cancel",
                      style: STextStyles.itemSubtitle12(context),
                    ),
                    onPressed: () {
                      // notify return to cancel
                      Navigator.of(context).pop(true);
                    },
                  ),
                  rightButton: TextButton(
                    style: Theme.of(context)
                        .extension<StackColors>()!
                        .getPrimaryEnabledButtonColor(context),
                    child: Text(
                      "Attempt",
                      style: STextStyles.button(context),
                    ),
                    onPressed: () {
                      // continue and try to attempt trade
                      Navigator.of(context).pop(false);
                    },
                  ),
                );
              }
            },
          );
        }

        if (shouldCancel is bool && shouldCancel) {
          return;
        }
        rate =
            "1 ${fromTicker.toUpperCase()} ~${ref.read(exchangeFormStateProvider).rate!.toStringAsFixed(8)} ${toTicker.toUpperCase()}";
        break;
    }

    final model = IncompleteExchangeModel(
      sendTicker: fromTicker.toUpperCase(),
      receiveTicker: toTicker.toUpperCase(),
      rateInfo: rate,
      sendAmount: estimate.reversed ? estimate.estimatedAmount : sendAmount,
      receiveAmount: estimate.reversed
          ? ref.read(exchangeFormStateProvider).toAmount!
          : estimate.estimatedAmount,
      rateType: rateType,
      rateId: estimate.rateId,
      reversed: estimate.reversed,
    );

    if (mounted) {
      if (walletInitiated) {
        ref.read(exchangeSendFromWalletIdStateProvider.state).state =
            Tuple2(walletId!, coin!);
        if (isDesktop) {
          await showDialog<void>(
            context: context,
            builder: (context) {
              return DesktopDialog(
                maxWidth: 720,
                maxHeight: double.infinity,
                child: StepScaffold(
                  step: 2,
                  body: DesktopStep2(
                    model: model,
                  ),
                ),
              );
            },
          );
        } else {
          unawaited(
            Navigator.of(context).pushNamed(
              Step2View.routeName,
              arguments: model,
            ),
          );
        }
      } else {
        ref.read(exchangeSendFromWalletIdStateProvider.state).state = null;

        if (isDesktop) {
          await showDialog<void>(
            context: context,
            builder: (context) {
              return DesktopDialog(
                maxWidth: 720,
                maxHeight: double.infinity,
                child: StepScaffold(
                  step: 1,
                  body: DesktopStep1(
                    model: model,
                  ),
                ),
              );
            },
          );
        } else {
          unawaited(
            Navigator.of(context).pushNamed(
              Step1View.routeName,
              arguments: model,
            ),
          );
        }
      }
    }
  }

  bool isWalletCoin(Coin? coin, bool isSend) {
    if (coin == null) {
      return false;
    }

    String? ticker;

    if (isSend) {
      ticker = ref.read(exchangeFormStateProvider).fromTicker;
    } else {
      ticker = ref.read(exchangeFormStateProvider).toTicker;
    }

    if (ticker == null) {
      return false;
    }

    return coin.ticker.toUpperCase() == ticker.toUpperCase();
  }

  @override
  void initState() {
    _sendController = TextEditingController();
    _receiveController = TextEditingController();

    walletId = widget.walletId;
    coin = widget.coin;
    walletInitiated = walletId != null && coin != null;

    if (walletInitiated) {
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
        ref.read(exchangeFormStateProvider).clearAmounts(true);
        // ref.read(fixedRateExchangeFormProvider);
      });
    } else {
      final isEstimated =
          ref.read(prefsChangeNotifierProvider).exchangeRateType ==
              ExchangeRateType.estimated;
      _sendController.text =
          ref.read(exchangeFormStateProvider).fromAmountString;
      _receiveController.text = isEstimated
          ? "-" //ref.read(estimatedRateExchangeFormProvider).toAmountString
          : ref.read(exchangeFormStateProvider).toAmountString;
    }

    _sendFocusNode.addListener(() async {
      if (!_sendFocusNode.hasFocus) {
        final newFromAmount = Decimal.tryParse(_sendController.text);
        await ref
            .read(exchangeFormStateProvider)
            .setFromAmountAndCalculateToAmount(
                newFromAmount ?? Decimal.zero, true);

        if (newFromAmount == null) {
          _receiveController.text =
              ref.read(prefsChangeNotifierProvider).exchangeRateType ==
                      ExchangeRateType.estimated
                  ? "-"
                  : "";
        }
      }
    });
    _receiveFocusNode.addListener(() async {
      if (!_receiveFocusNode.hasFocus) {
        final newToAmount = Decimal.tryParse(_receiveController.text);
        if (ref.read(prefsChangeNotifierProvider).exchangeRateType !=
            ExchangeRateType.estimated) {
          await ref
              .read(exchangeFormStateProvider)
              .setToAmountAndCalculateFromAmount(
                  newToAmount ?? Decimal.zero, true);
        }
        if (newToAmount == null) {
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

  @override
  Widget build(BuildContext context) {
    debugPrint("BUILD: $runtimeType");

    ref.listen<String>(currentExchangeNameStateProvider, (previous, next) {
      ref.read(exchangeFormStateProvider).exchange = ref.read(exchangeProvider);
    });

    final isEstimated = ref.watch(prefsChangeNotifierProvider
            .select((pref) => pref.exchangeRateType)) ==
        ExchangeRateType.estimated;

    ref.listen(
        exchangeFormStateProvider.select((value) => value.toAmountString),
        (previous, String next) {
      if (!_receiveFocusNode.hasFocus) {
        _receiveController.text = isEstimated &&
                ref.watch(exchangeProvider).name ==
                    SimpleSwapExchange.exchangeName &&
                next.isEmpty
            ? "-"
            : next;
        debugPrint("RECEIVE AMOUNT LISTENER ACTIVATED");
        if (_swapLock) {
          _sendController.text =
              ref.read(exchangeFormStateProvider).fromAmountString;
        }
      }
    });
    ref.listen(
        exchangeFormStateProvider.select((value) => value.fromAmountString),
        (previous, String next) {
      if (!_sendFocusNode.hasFocus) {
        _sendController.text = next;
        debugPrint("SEND AMOUNT LISTENER ACTIVATED");
        if (_swapLock) {
          _receiveController.text = isEstimated
              ? ref.read(exchangeFormStateProvider).toAmountString.isEmpty
                  ? "-"
                  : ref.read(exchangeFormStateProvider).toAmountString
              : ref.read(exchangeFormStateProvider).toAmountString;
        }
      }
    });

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          "You will send",
          style: STextStyles.itemSubtitle(context).copyWith(
            color: Theme.of(context).extension<StackColors>()!.textDark3,
          ),
        ),
        SizedBox(
          height: isDesktop ? 10 : 4,
        ),
        TextFormField(
          style: STextStyles.smallMed14(context).copyWith(
            color: Theme.of(context).extension<StackColors>()!.textDark,
          ),
          focusNode: _sendFocusNode,
          controller: _sendController,
          textAlign: TextAlign.right,
          enableSuggestions: false,
          autocorrect: false,
          onTap: () {
            if (_sendController.text == "-") {
              _sendController.text = "";
            }
          },
          onChanged: sendFieldOnChanged,
          keyboardType: const TextInputType.numberWithOptions(
            signed: false,
            decimal: true,
          ),
          inputFormatters: [
            // regex to validate a crypto amount with 8 decimal places
            TextInputFormatter.withFunction((oldValue, newValue) =>
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
            hintStyle: STextStyles.fieldLabel(context).copyWith(
              fontSize: 14,
            ),
            prefixIcon: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: GestureDetector(
                onTap: selectSendCurrency,
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
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Builder(
                            builder: (context) {
                              final image = _fetchIconUrlFromTicker(ref.watch(
                                  exchangeFormStateProvider
                                      .select((value) => value.fromTicker)));

                              if (image != null && image.isNotEmpty) {
                                return Center(
                                  child: SvgPicture.network(
                                    image,
                                    height: 18,
                                    placeholderBuilder: (_) => Container(
                                      width: 18,
                                      height: 18,
                                      decoration: BoxDecoration(
                                        color: Theme.of(context)
                                            .extension<StackColors>()!
                                            .textFieldDefaultBG,
                                        borderRadius: BorderRadius.circular(
                                          18,
                                        ),
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(
                                          18,
                                        ),
                                        child: const LoadingIndicator(),
                                      ),
                                    ),
                                  ),
                                );
                              } else {
                                return Container(
                                  width: 18,
                                  height: 18,
                                  decoration: BoxDecoration(
                                    // color: Theme.of(context).extension<StackColors>()!.accentColorDark
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  child: SvgPicture.asset(
                                    Assets.svg.circleQuestion,
                                    width: 18,
                                    height: 18,
                                    color: Theme.of(context)
                                        .extension<StackColors>()!
                                        .textFieldDefaultBG,
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
                          ref.watch(exchangeFormStateProvider.select((value) =>
                                  value.fromTicker?.toUpperCase())) ??
                              "-",
                          style: STextStyles.smallMed14(context).copyWith(
                            color: Theme.of(context)
                                .extension<StackColors>()!
                                .textDark,
                          ),
                        ),
                        if (!isWalletCoin(coin, true))
                          const SizedBox(
                            width: 6,
                          ),
                        if (!isWalletCoin(coin, true))
                          SvgPicture.asset(
                            Assets.svg.chevronDown,
                            width: 5,
                            height: 2.5,
                            color: Theme.of(context)
                                .extension<StackColors>()!
                                .textDark,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),

        SizedBox(
          height: isDesktop ? 10 : 4,
        ),
        if (ref
                .watch(
                    exchangeFormStateProvider.select((value) => value.warning))
                .isNotEmpty &&
            !ref.watch(
                exchangeFormStateProvider.select((value) => value.reversed)))
          Text(
            ref.watch(
                exchangeFormStateProvider.select((value) => value.warning)),
            style: STextStyles.errorSmall(context),
          ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "You will receive",
              style: STextStyles.itemSubtitle(context).copyWith(
                color: Theme.of(context).extension<StackColors>()!.textDark3,
              ),
            ),
            ConditionalParent(
              condition: isDesktop,
              builder: (child) => MouseRegion(
                cursor: SystemMouseCursors.click,
                child: RoundedContainer(
                  padding: const EdgeInsets.all(6),
                  color: Theme.of(context)
                      .extension<StackColors>()!
                      .buttonBackSecondary,
                  radiusMultiplier: 0.75,
                  child: child,
                ),
              ),
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
                    color: Theme.of(context)
                        .extension<StackColors>()!
                        .accentColorDark,
                  ),
                ),
              ),
            ),
          ],
        ),
        // Stack(
        //   children: [
        //     Positioned.fill(
        //       child: Align(
        //         alignment: Alignment.bottomLeft,
        //         child: Text(
        //           "You will receive",
        //           style: STextStyles.itemSubtitle(context).copyWith(
        //             color:
        //                 Theme.of(context).extension<StackColors>()!.textDark3,
        //           ),
        //         ),
        //       ),
        //     ),
        //     Center(
        //       child: Column(
        //         children: [
        //           const SizedBox(
        //             height: 6,
        //           ),
        //           GestureDetector(
        //             onTap: () async {
        //               await _swap();
        //             },
        //             child: Padding(
        //               padding: const EdgeInsets.all(4),
        //               child: SvgPicture.asset(
        //                 Assets.svg.swap,
        //                 width: 20,
        //                 height: 20,
        //                 color: Theme.of(context)
        //                     .extension<StackColors>()!
        //                     .accentColorDark,
        //               ),
        //             ),
        //           ),
        //           const SizedBox(
        //             height: 6,
        //           ),
        //         ],
        //       ),
        //     ),
        //     Positioned.fill(
        //       child: Align(
        //         alignment: ref.watch(exchangeFormStateProvider
        //                 .select((value) => value.reversed))
        //             ? Alignment.bottomRight
        //             : Alignment.topRight,
        //         child: Text(
        //           ref.watch(exchangeFormStateProvider
        //               .select((value) => value.warning)),
        //           style: STextStyles.errorSmall(context),
        //         ),
        //       ),
        //     ),
        //   ],
        // ),
        SizedBox(
          height: isDesktop ? 10 : 4,
        ),
        TextFormField(
          style: STextStyles.smallMed14(context).copyWith(
            color: Theme.of(context).extension<StackColors>()!.textDark,
          ),
          focusNode: _receiveFocusNode,
          controller: _receiveController,
          enableSuggestions: false,
          autocorrect: false,
          readOnly: ref.watch(prefsChangeNotifierProvider
                      .select((value) => value.exchangeRateType)) ==
                  ExchangeRateType.estimated ||
              ref.watch(exchangeProvider).name ==
                  SimpleSwapExchange.exchangeName,
          onTap: () {
            if (!(ref.read(prefsChangeNotifierProvider).exchangeRateType ==
                    ExchangeRateType.estimated) &&
                _receiveController.text == "-") {
              _receiveController.text = "";
            }
          },
          onChanged: receiveFieldOnChanged,
          textAlign: TextAlign.right,
          keyboardType: const TextInputType.numberWithOptions(
            signed: false,
            decimal: true,
          ),
          inputFormatters: [
            // regex to validate a crypto amount with 8 decimal places
            TextInputFormatter.withFunction((oldValue, newValue) =>
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
            hintStyle: STextStyles.fieldLabel(context).copyWith(
              fontSize: 14,
            ),
            prefixIcon: FittedBox(
              fit: BoxFit.scaleDown,
              child: GestureDetector(
                onTap: selectReceiveCurrency,
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
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Builder(
                            builder: (context) {
                              final image = _fetchIconUrlFromTicker(ref.watch(
                                  exchangeFormStateProvider
                                      .select((value) => value.toTicker)));

                              if (image != null && image.isNotEmpty) {
                                return Center(
                                  child: SvgPicture.network(
                                    image,
                                    height: 18,
                                    placeholderBuilder: (_) => Container(
                                      width: 18,
                                      height: 18,
                                      decoration: BoxDecoration(
                                        color: Theme.of(context)
                                            .extension<StackColors>()!
                                            .textFieldDefaultBG,
                                        borderRadius: BorderRadius.circular(18),
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(
                                          18,
                                        ),
                                        child: const LoadingIndicator(),
                                      ),
                                    ),
                                  ),
                                );
                              } else {
                                return Container(
                                  width: 18,
                                  height: 18,
                                  decoration: BoxDecoration(
                                    // color: Theme.of(context).extension<StackColors>()!.accentColorDark
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  child: SvgPicture.asset(
                                    Assets.svg.circleQuestion,
                                    width: 18,
                                    height: 18,
                                    color: Theme.of(context)
                                        .extension<StackColors>()!
                                        .textFieldDefaultBG,
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
                          ref.watch(exchangeFormStateProvider.select(
                                  (value) => value.toTicker?.toUpperCase())) ??
                              "-",
                          style: STextStyles.smallMed14(context).copyWith(
                            color: Theme.of(context)
                                .extension<StackColors>()!
                                .textDark,
                          ),
                        ),
                        if (!isWalletCoin(coin, false))
                          const SizedBox(
                            width: 6,
                          ),
                        if (!isWalletCoin(coin, false))
                          SvgPicture.asset(
                            Assets.svg.chevronDown,
                            width: 5,
                            height: 2.5,
                            color: Theme.of(context)
                                .extension<StackColors>()!
                                .textDark,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        if (ref
                .watch(
                    exchangeFormStateProvider.select((value) => value.warning))
                .isNotEmpty &&
            ref.watch(
                exchangeFormStateProvider.select((value) => value.reversed)))
          Text(
            ref.watch(
                exchangeFormStateProvider.select((value) => value.warning)),
            style: STextStyles.errorSmall(context),
          ),
        SizedBox(
          height: isDesktop ? 20 : 12,
        ),
        RateTypeToggle(
          onChanged: onRateTypeChanged,
        ),
        if (ref.read(exchangeFormStateProvider).fromAmount != null &&
            ref.read(exchangeFormStateProvider).fromAmount != Decimal.zero)
          SizedBox(
            height: isDesktop ? 20 : 12,
          ),
        if (ref.read(exchangeFormStateProvider).fromAmount != null &&
            ref.read(exchangeFormStateProvider).fromAmount != Decimal.zero)
          ExchangeProviderOptions(
            from: ref.watch(exchangeFormStateProvider).fromTicker,
            to: ref.watch(exchangeFormStateProvider).toTicker,
            fromAmount: ref.watch(exchangeFormStateProvider).fromAmount,
            toAmount: ref.watch(exchangeFormStateProvider).toAmount,
            fixedRate: ref.watch(prefsChangeNotifierProvider
                    .select((value) => value.exchangeRateType)) ==
                ExchangeRateType.fixed,
            reversed: ref.watch(
                exchangeFormStateProvider.select((value) => value.reversed)),
          ),
        SizedBox(
          height: isDesktop ? 20 : 12,
        ),
        PrimaryButton(
          buttonHeight: isDesktop ? ButtonHeight.l : null,
          enabled: ref.watch(
              exchangeFormStateProvider.select((value) => value.canExchange)),
          onPressed: ref.watch(exchangeFormStateProvider
                  .select((value) => value.canExchange))
              ? onExchangePressed
              : null,
          label: "Exchange",
        )
      ],
    );
  }
}

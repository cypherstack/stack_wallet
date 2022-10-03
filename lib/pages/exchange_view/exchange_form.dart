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
import 'package:stackwallet/pages/exchange_view/sub_widgets/exchange_provider_options.dart';
import 'package:stackwallet/pages/exchange_view/sub_widgets/exchange_rate_sheet.dart';
import 'package:stackwallet/pages/exchange_view/sub_widgets/rate_type_toggle.dart';
import 'package:stackwallet/providers/exchange/available_currencies_state_provider.dart';
import 'package:stackwallet/providers/exchange/available_floating_rate_pairs_state_provider.dart';
import 'package:stackwallet/providers/exchange/change_now_provider.dart';
import 'package:stackwallet/providers/exchange/estimate_rate_exchange_form_provider.dart';
import 'package:stackwallet/providers/exchange/exchange_send_from_wallet_id_provider.dart';
import 'package:stackwallet/providers/exchange/fixed_rate_exchange_form_provider.dart';
import 'package:stackwallet/providers/exchange/fixed_rate_market_pairs_provider.dart';
import 'package:stackwallet/providers/providers.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/enums/flush_bar_type.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';
import 'package:stackwallet/widgets/custom_loading_overlay.dart';
import 'package:stackwallet/widgets/desktop/primary_button.dart';
import 'package:stackwallet/widgets/loading_indicator.dart';
import 'package:stackwallet/widgets/stack_dialog.dart';

class ExchangeForm extends ConsumerStatefulWidget {
  const ExchangeForm({Key? key}) : super(key: key);

  @override
  ConsumerState<ExchangeForm> createState() => _ExchangeFormState();
}

class _ExchangeFormState extends ConsumerState<ExchangeForm> {
  late final TextEditingController _sendController;
  late final TextEditingController _receiveController;
  final FocusNode _sendFocusNode = FocusNode();
  final FocusNode _receiveFocusNode = FocusNode();

  bool _swapLock = false;
  bool _reversed = false;

  void sendFieldOnChanged(String value) async {
    final newFromAmount = Decimal.tryParse(value);
    final isEstimated =
        ref.read(prefsChangeNotifierProvider).exchangeRateType ==
            ExchangeRateType.estimated;
    if (newFromAmount != null) {
      if (isEstimated) {
        await ref
            .read(estimatedRateExchangeFormProvider)
            .setFromAmountAndCalculateToAmount(newFromAmount, false);
      } else {
        await ref
            .read(fixedRateExchangeFormProvider)
            .setFromAmountAndCalculateToAmount(newFromAmount, false);
      }
    } else {
      if (isEstimated) {
        await ref
            .read(estimatedRateExchangeFormProvider)
            .setFromAmountAndCalculateToAmount(Decimal.zero, false);
      } else {
        await ref
            .read(fixedRateExchangeFormProvider)
            .setFromAmountAndCalculateToAmount(Decimal.zero, false);
      }
      _receiveController.text = isEstimated ? "-" : "";
    }
  }

  void selectSendCurrency() async {
    if (ref.read(prefsChangeNotifierProvider).exchangeRateType ==
        ExchangeRateType.estimated) {
      await _showFloatingRateSelectionSheet(
          currencies:
              ref.read(availableChangeNowCurrenciesStateProvider.state).state,
          excludedTicker:
              ref.read(estimatedRateExchangeFormProvider).to?.ticker ?? "-",
          fromTicker:
              ref.read(estimatedRateExchangeFormProvider).from?.ticker ?? "-",
          onSelected: (from) => ref
              .read(estimatedRateExchangeFormProvider)
              .updateFrom(from, true));
    } else {
      final toTicker = ref.read(fixedRateExchangeFormProvider).market?.to ?? "";
      final fromTicker =
          ref.read(fixedRateExchangeFormProvider).market?.from ?? "";
      await _showFixedRateSelectionSheet(
        excludedTicker: toTicker,
        fromTicker: fromTicker,
        onSelected: (selectedFromTicker) async {
          try {
            final market = ref
                .read(fixedRateMarketPairsStateProvider.state)
                .state
                .firstWhere(
                  (e) => e.to == toTicker && e.from == selectedFromTicker,
                );

            await ref
                .read(fixedRateExchangeFormProvider)
                .updateMarket(market, true);
          } catch (e) {
            unawaited(showDialog<dynamic>(
              context: context,
              builder: (_) => const StackDialog(
                title: "Fixed rate market error",
                message: "Could not find the specified fixed rate trade pair",
              ),
            ));
            return;
          }
        },
      );
    }
  }

  void selectReceiveCurrency() async {
    if (ref.read(prefsChangeNotifierProvider).exchangeRateType ==
        ExchangeRateType.estimated) {
      await _showFloatingRateSelectionSheet(
          currencies:
              ref.read(availableChangeNowCurrenciesStateProvider.state).state,
          excludedTicker:
              ref.read(estimatedRateExchangeFormProvider).from?.ticker ?? "",
          fromTicker:
              ref.read(estimatedRateExchangeFormProvider).from?.ticker ?? "",
          onSelected: (to) =>
              ref.read(estimatedRateExchangeFormProvider).updateTo(to, true));
    } else {
      final fromTicker =
          ref.read(fixedRateExchangeFormProvider).market?.from ?? "";
      await _showFixedRateSelectionSheet(
        excludedTicker: fromTicker,
        fromTicker: fromTicker,
        onSelected: (selectedToTicker) async {
          try {
            final market = ref
                .read(fixedRateMarketPairsStateProvider.state)
                .state
                .firstWhere(
                  (e) => e.to == selectedToTicker && e.from == fromTicker,
                );

            await ref
                .read(fixedRateExchangeFormProvider)
                .updateMarket(market, true);
          } catch (e) {
            unawaited(showDialog<dynamic>(
              context: context,
              builder: (_) => const StackDialog(
                title: "Fixed rate market error",
                message: "Could not find the specified fixed rate trade pair",
              ),
            ));
            return;
          }
        },
      );
    }
  }

  void receiveFieldOnChanged(String value) async {
    final newToAmount = Decimal.tryParse(value);
    if (newToAmount != null) {
      if (ref.read(prefsChangeNotifierProvider).exchangeRateType ==
          ExchangeRateType.estimated) {
        // await ref
        //     .read(estimatedRateExchangeFormProvider)
        //     .setToAmountAndCalculateFromAmount(
        //         newToAmount, false);
      } else {
        await ref
            .read(fixedRateExchangeFormProvider)
            .setToAmountAndCalculateFromAmount(newToAmount, false);
      }
    } else {
      if (ref.read(prefsChangeNotifierProvider).exchangeRateType ==
          ExchangeRateType.estimated) {
        // await ref
        //     .read(estimatedRateExchangeFormProvider)
        //     .setToAmountAndCalculateFromAmount(
        //         Decimal.zero, false);
      } else {
        await ref
            .read(fixedRateExchangeFormProvider)
            .setToAmountAndCalculateFromAmount(Decimal.zero, false);
      }
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

    List<Pair> availablePairs = [];
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
          .where((e) => e.from == excludedTicker)
          .toList(growable: false);
    } else {
      availablePairs = ref
          .read(availableFloatingRatePairsStateProvider.state)
          .state
          .where((e) => e.to == excludedTicker)
          .toList(growable: false);
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

  void onRateTypeChanged(ExchangeRateType rateType) async {
    _receiveFocusNode.unfocus();
    _sendFocusNode.unfocus();
    switch (rateType) {
      case ExchangeRateType.estimated:
        final market = ref.read(fixedRateExchangeFormProvider).market;
        final fromTicker = market?.from ?? "";
        final toTicker = market?.to ?? "";
        if (!(fromTicker.isEmpty ||
            toTicker.isEmpty ||
            toTicker == "-" ||
            fromTicker == "-")) {
          final available = ref
              .read(availableFloatingRatePairsStateProvider.state)
              .state
              .where((e) => e.to == toTicker && e.from == fromTicker);
          if (available.isNotEmpty) {
            final availableCurrencies = ref
                .read(availableChangeNowCurrenciesStateProvider.state)
                .state
                .where((e) => e.ticker == fromTicker || e.ticker == toTicker);
            if (availableCurrencies.length > 1) {
              final from =
                  availableCurrencies.firstWhere((e) => e.ticker == fromTicker);
              final to =
                  availableCurrencies.firstWhere((e) => e.ticker == toTicker);

              final newFromAmount = Decimal.tryParse(_sendController.text);
              if (newFromAmount != null) {
                await ref
                    .read(estimatedRateExchangeFormProvider)
                    .setFromAmountAndCalculateToAmount(newFromAmount, false);
              } else {
                await ref
                    .read(estimatedRateExchangeFormProvider)
                    .setFromAmountAndCalculateToAmount(Decimal.zero, false);

                _receiveController.text = "";
              }

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
        final fromTicker =
            ref.read(estimatedRateExchangeFormProvider).from?.ticker ?? "";
        final toTicker =
            ref.read(estimatedRateExchangeFormProvider).to?.ticker ?? "";
        if (!(fromTicker.isEmpty ||
            toTicker.isEmpty ||
            toTicker == "-" ||
            fromTicker == "-")) {
          FixedRateMarket? market;
          try {
            market = ref
                .read(fixedRateMarketPairsStateProvider.state)
                .state
                .firstWhere((e) => e.from == fromTicker && e.to == toTicker);
          } catch (_) {
            market = null;
          }

          final newFromAmount = Decimal.tryParse(_sendController.text);
          if (newFromAmount != null) {
            await ref
                .read(fixedRateExchangeFormProvider)
                .setFromAmountAndCalculateToAmount(newFromAmount, false);
          } else {
            await ref
                .read(fixedRateExchangeFormProvider)
                .setFromAmountAndCalculateToAmount(Decimal.zero, false);

            _receiveController.text = "";
          }

          await ref
              .read(fixedRateExchangeFormProvider)
              .updateMarket(market, false);
          await ref
              .read(fixedRateExchangeFormProvider)
              .setFromAmountAndCalculateToAmount(
                Decimal.tryParse(_sendController.text) ?? Decimal.zero,
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
  }

  void onExchangePressed() async {
    if (ref.read(prefsChangeNotifierProvider).exchangeRateType ==
        ExchangeRateType.estimated) {
      final fromTicker =
          ref.read(estimatedRateExchangeFormProvider).from?.ticker ?? "";
      final toTicker =
          ref.read(estimatedRateExchangeFormProvider).to?.ticker ?? "";

      bool isAvailable = false;
      final availableFloatingPairs =
          ref.read(availableFloatingRatePairsStateProvider.state).state;
      for (final pair in availableFloatingPairs) {
        if (pair.from == fromTicker && pair.to == toTicker) {
          isAvailable = true;
          break;
        }
      }

      if (!isAvailable) {
        unawaited(showDialog<dynamic>(
          context: context,
          barrierDismissible: true,
          builder: (_) => StackDialog(
            title: "Selected trade pair unavailable",
            message:
                "The $fromTicker - $toTicker market is currently disabled for estimated/floating rate trades",
          ),
        ));
        return;
      }

      final sendAmount = Decimal.parse(
          ref.read(estimatedRateExchangeFormProvider).fromAmountString);

      final rateType = ref.read(prefsChangeNotifierProvider).exchangeRateType;

      final response = await ref.read(changeNowProvider).getEstimate(
            fromTicker,
            toTicker,
            sendAmount,
            false,
            false,
          );

      if (response.value == null) {
        unawaited(showDialog<dynamic>(
          context: context,
          barrierDismissible: true,
          builder: (_) => StackDialog(
            title: "Failed to update trade estimate",
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
        receiveAmount: response.value!.estimatedAmount,
        rateType: rateType,
        rateId: response.value!.rateId,
      );

      if (mounted) {
        ref.read(exchangeSendFromWalletIdStateProvider.state).state = null;
        unawaited(Navigator.of(context).pushNamed(
          Step1View.routeName,
          arguments: model,
        ));
      }
    } else {
      final fromTicker =
          ref.read(fixedRateExchangeFormProvider).market?.from ?? "";
      final toTicker = ref.read(fixedRateExchangeFormProvider).market?.to ?? "";

      final sendAmount = Decimal.parse(
          ref.read(fixedRateExchangeFormProvider).fromAmountString);

      final rateType = ref.read(prefsChangeNotifierProvider).exchangeRateType;

      final response = await ref.read(changeNowProvider).getEstimate(
            fromTicker,
            toTicker,
            sendAmount,
            true,
            false,
          );

      bool? shouldCancel;

      if (response.value == null) {
        unawaited(showDialog<dynamic>(
          context: context,
          barrierDismissible: true,
          builder: (_) => StackDialog(
            title: "Failed to update trade estimate",
            message: response.exception?.toString(),
          ),
        ));
        return;
      } else if (response.value!.warningMessage != null &&
          response.value!.warningMessage!.isNotEmpty) {
        shouldCancel = await showDialog<bool?>(
          context: context,
          barrierDismissible: true,
          builder: (_) => StackDialog(
            title: "Failed to update trade estimate",
            message:
                "${response.value!.warningMessage!}\n\nDo you want to attempt trade anyways?",
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
          ),
        );
      }

      if (shouldCancel is bool && shouldCancel) {
        return;
      }

      String rate =
          "1 ${fromTicker.toUpperCase()} ~${ref.read(fixedRateExchangeFormProvider).rate!.toStringAsFixed(8)} ${toTicker.toUpperCase()}";

      final model = IncompleteExchangeModel(
        sendTicker: fromTicker,
        receiveTicker: toTicker,
        rateInfo: rate,
        sendAmount: sendAmount,
        receiveAmount: response.value!.estimatedAmount,
        rateType: rateType,
        rateId: response.value!.rateId,
      );

      if (mounted) {
        ref.read(exchangeSendFromWalletIdStateProvider.state).state = null;
        unawaited(Navigator.of(context).pushNamed(
          Step1View.routeName,
          arguments: model,
        ));
      }
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
        ? "-" //ref.read(estimatedRateExchangeFormProvider).toAmountString
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
        _receiveController.text = isEstimated && next.isEmpty ? "-" : next;
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
              ? ref
                      .read(estimatedRateExchangeFormProvider)
                      .toAmountString
                      .isEmpty
                  ? "-"
                  : ref.read(estimatedRateExchangeFormProvider).toAmountString
              : ref.read(fixedRateExchangeFormProvider).toAmountString;
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
        const SizedBox(
          height: 4,
        ),
        TextFormField(
          style: STextStyles.smallMed14(context).copyWith(
            color: Theme.of(context).extension<StackColors>()!.textDark,
          ),
          focusNode: _sendFocusNode,
          controller: _sendController,
          textAlign: TextAlign.right,
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
                              String? image;
                              if (ref.watch(prefsChangeNotifierProvider.select(
                                      (value) => value.exchangeRateType)) ==
                                  ExchangeRateType.estimated) {
                                image = ref
                                    .watch(estimatedRateExchangeFormProvider
                                        .select((value) => value.from))
                                    ?.image;
                              } else {
                                image = _fetchIconUrlFromTickerForFixedRateFlow(
                                    ref.watch(
                                        fixedRateExchangeFormProvider.select(
                                            (value) => value.market?.from)));
                              }
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
                          ref.watch(prefsChangeNotifierProvider.select(
                                      (value) => value.exchangeRateType)) ==
                                  ExchangeRateType.estimated
                              ? ref.watch(estimatedRateExchangeFormProvider
                                      .select((value) =>
                                          value.from?.ticker.toUpperCase())) ??
                                  "-"
                              : ref.watch(fixedRateExchangeFormProvider.select(
                                      (value) =>
                                          value.market?.from.toUpperCase())) ??
                                  "-",
                          style: STextStyles.smallMed14(context).copyWith(
                            color: Theme.of(context)
                                .extension<StackColors>()!
                                .textDark,
                          ),
                        ),
                        const SizedBox(
                          width: 6,
                        ),
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
                  style: STextStyles.itemSubtitle(context).copyWith(
                    color:
                        Theme.of(context).extension<StackColors>()!.textDark3,
                  ),
                ),
              ),
            ),
            Center(
              child: Column(
                children: [
                  const SizedBox(
                    height: 6,
                  ),
                  GestureDetector(
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
                  const SizedBox(
                    height: 6,
                  ),
                ],
              ),
            ),
            Positioned.fill(
              child: Align(
                alignment: Alignment.topRight,
                child: Text(
                  ref.read(prefsChangeNotifierProvider).exchangeRateType ==
                          ExchangeRateType.estimated
                      ? ref.watch(estimatedRateExchangeFormProvider
                          .select((value) => value.minimumSendWarning))
                      : ref.watch(fixedRateExchangeFormProvider
                          .select((value) => value.sendAmountWarning)),
                  style: STextStyles.errorSmall(context),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(
          height: 4,
        ),
        TextFormField(
          style: STextStyles.smallMed14(context).copyWith(
            color: Theme.of(context).extension<StackColors>()!.textDark,
          ),
          focusNode: _receiveFocusNode,
          controller: _receiveController,
          readOnly: ref.watch(prefsChangeNotifierProvider
                  .select((value) => value.exchangeRateType)) ==
              ExchangeRateType.estimated,
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
                              String? image;
                              if (ref.watch(prefsChangeNotifierProvider.select(
                                      (value) => value.exchangeRateType)) ==
                                  ExchangeRateType.estimated) {
                                image = ref
                                    .watch(estimatedRateExchangeFormProvider
                                        .select((value) => value.to))
                                    ?.image;
                              } else {
                                image = _fetchIconUrlFromTickerForFixedRateFlow(
                                    ref.watch(fixedRateExchangeFormProvider
                                        .select((value) => value.market?.to)));
                              }
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
                          ref.watch(prefsChangeNotifierProvider.select(
                                      (value) => value.exchangeRateType)) ==
                                  ExchangeRateType.estimated
                              ? ref.watch(estimatedRateExchangeFormProvider
                                      .select((value) =>
                                          value.to?.ticker.toUpperCase())) ??
                                  "-"
                              : ref.watch(fixedRateExchangeFormProvider.select(
                                      (value) =>
                                          value.market?.to.toUpperCase())) ??
                                  "-",
                          style: STextStyles.smallMed14(context).copyWith(
                            color: Theme.of(context)
                                .extension<StackColors>()!
                                .textDark,
                          ),
                        ),
                        const SizedBox(
                          width: 6,
                        ),
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
        const SizedBox(
          height: 12,
        ),
        RateTypeToggle(
          onChanged: onRateTypeChanged,
        ),
        const SizedBox(
          height: 8,
        ),
        ExchangeProviderOptions(
          fromAmount: null,
          toAmount: null,
          fixedRate: ref.watch(prefsChangeNotifierProvider
                  .select((value) => value.exchangeRateType)) ==
              ExchangeRateType.fixed,
          reversed: _reversed,
        ),
        const SizedBox(
          height: 12,
        ),
        PrimaryButton(
          enabled: ((ref.read(prefsChangeNotifierProvider).exchangeRateType ==
                  ExchangeRateType.estimated)
              ? ref.watch(estimatedRateExchangeFormProvider
                  .select((value) => value.canExchange))
              : ref.watch(fixedRateExchangeFormProvider
                  .select((value) => value.canExchange))),
          onPressed: ((ref.read(prefsChangeNotifierProvider).exchangeRateType ==
                      ExchangeRateType.estimated)
                  ? ref.watch(estimatedRateExchangeFormProvider
                      .select((value) => value.canExchange))
                  : ref.watch(fixedRateExchangeFormProvider
                      .select((value) => value.canExchange)))
              ? onExchangePressed
              : null,
          label: "Exchange",
        )
      ],
    );
  }
}

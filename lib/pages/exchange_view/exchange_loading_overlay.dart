import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stackwallet/providers/exchange/available_currencies_state_provider.dart';
import 'package:stackwallet/providers/exchange/available_floating_rate_pairs_state_provider.dart';
import 'package:stackwallet/providers/exchange/change_now_provider.dart';
import 'package:stackwallet/providers/exchange/changenow_initial_load_status.dart';
import 'package:stackwallet/providers/exchange/exchange_form_provider.dart';
import 'package:stackwallet/providers/exchange/fixed_rate_exchange_form_provider.dart';
import 'package:stackwallet/providers/exchange/fixed_rate_market_pairs_provider.dart';
import 'package:stackwallet/utilities/cfcolors.dart';
import 'package:stackwallet/utilities/logger.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/widgets/custom_loading_overlay.dart';
import 'package:stackwallet/widgets/stack_dialog.dart';

class ExchangeLoadingOverlayView extends ConsumerStatefulWidget {
  const ExchangeLoadingOverlayView({Key? key}) : super(key: key);

  @override
  ConsumerState<ExchangeLoadingOverlayView> createState() =>
      _ExchangeLoadingOverlayViewState();
}

class _ExchangeLoadingOverlayViewState
    extends ConsumerState<ExchangeLoadingOverlayView> {
  late ChangeNowLoadStatus _statusEst;
  late ChangeNowLoadStatus _statusFixed;

  bool userReloaded = false;

  Future<void> _loadFixedRateMarkets() async {
    if (ref.read(changeNowFixedInitialLoadStatusStateProvider.state).state ==
        ChangeNowLoadStatus.loading) {
      // already in progress so just
      return;
    }

    ref.read(changeNowFixedInitialLoadStatusStateProvider.state).state =
        ChangeNowLoadStatus.loading;

    final response3 =
        await ref.read(changeNowProvider).getAvailableFixedRateMarkets();
    if (response3.value != null) {
      ref.read(fixedRateMarketPairsStateProvider.state).state =
          response3.value!;

      if (ref.read(fixedRateExchangeFormProvider).market == null) {
        final matchingMarkets =
            response3.value!.where((e) => e.to == "doge" && e.from == "btc");
        if (matchingMarkets.isNotEmpty) {
          await ref
              .read(fixedRateExchangeFormProvider)
              .updateMarket(matchingMarkets.first, true);
        }
      }
    } else {
      Logging.instance.log(
          "Failed to load changeNOW fixed rate markets: ${response3.exception?.errorMessage}",
          level: LogLevel.Error);

      ref.read(changeNowFixedInitialLoadStatusStateProvider.state).state =
          ChangeNowLoadStatus.failed;
      return;
    }

    ref.read(changeNowFixedInitialLoadStatusStateProvider.state).state =
        ChangeNowLoadStatus.success;
  }

  Future<void> _loadChangeNowStandardCurrencies() async {
    if (ref
            .read(changeNowEstimatedInitialLoadStatusStateProvider.state)
            .state ==
        ChangeNowLoadStatus.loading) {
      // already in progress so just
      return;
    }

    ref.read(changeNowEstimatedInitialLoadStatusStateProvider.state).state =
        ChangeNowLoadStatus.loading;

    final response = await ref.read(changeNowProvider).getAvailableCurrencies();
    final response2 =
        await ref.read(changeNowProvider).getAvailableFloatingRatePairs();
    if (response.value != null) {
      ref.read(availableChangeNowCurrenciesStateProvider.state).state =
          response.value!;
      if (response2.value != null) {
        ref.read(availableFloatingRatePairsStateProvider.state).state =
            response2.value!;

        if (response.value!.length > 1) {
          if (ref.read(estimatedRateExchangeFormProvider).from == null) {
            if (response.value!.where((e) => e.ticker == "btc").isNotEmpty) {
              await ref.read(estimatedRateExchangeFormProvider).updateFrom(
                  response.value!.firstWhere((e) => e.ticker == "btc"), false);
            }
          }
          if (ref.read(estimatedRateExchangeFormProvider).to == null) {
            if (response.value!.where((e) => e.ticker == "doge").isNotEmpty) {
              await ref.read(estimatedRateExchangeFormProvider).updateTo(
                  response.value!.firstWhere((e) => e.ticker == "doge"), false);
            }
          }
        }
      } else {
        Logging.instance.log(
            "Failed to load changeNOW available floating rate pairs: ${response2.exception?.errorMessage}",
            level: LogLevel.Error);
        ref.read(changeNowEstimatedInitialLoadStatusStateProvider.state).state =
            ChangeNowLoadStatus.failed;
        return;
      }
    } else {
      Logging.instance.log(
          "Failed to load changeNOW currencies: ${response.exception?.errorMessage}",
          level: LogLevel.Error);
      await Future<void>.delayed(const Duration(seconds: 3));
      ref.read(changeNowEstimatedInitialLoadStatusStateProvider.state).state =
          ChangeNowLoadStatus.failed;
      return;
    }

    ref.read(changeNowEstimatedInitialLoadStatusStateProvider.state).state =
        ChangeNowLoadStatus.success;
  }

  @override
  void initState() {
    _statusEst =
        ref.read(changeNowEstimatedInitialLoadStatusStateProvider.state).state;
    _statusFixed =
        ref.read(changeNowFixedInitialLoadStatusStateProvider.state).state;

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint("BUILD: $runtimeType");

    ref.listen(
        changeNowEstimatedInitialLoadStatusStateProvider
            .select((value) => value), (previous, next) {
      if (next is ChangeNowLoadStatus) {
        setState(() {
          _statusEst = next;
        });
      }
    });

    ref.listen(
        changeNowFixedInitialLoadStatusStateProvider.select((value) => value),
        (previous, next) {
      if (next is ChangeNowLoadStatus) {
        setState(() {
          _statusFixed = next;
        });
      }
    });

    return Stack(
      children: [
        if (_statusEst == ChangeNowLoadStatus.loading ||
            (_statusFixed == ChangeNowLoadStatus.loading && userReloaded))
          Container(
            color: CFColors.stackAccent.withOpacity(0.7),
            child: const CustomLoadingOverlay(
                message: "Loading ChangeNOW data", eventBus: null),
          ),
        if (_statusEst == ChangeNowLoadStatus.failed ||
            _statusFixed == ChangeNowLoadStatus.failed)
          Container(
            color: CFColors.stackAccent.withOpacity(0.7),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                StackDialog(
                  title: "Failed to fetch ChangeNow data",
                  message:
                      "ChangeNOW requires a working internet connection. Tap OK to try fetching again.",
                  rightButton: TextButton(
                    child: Text(
                      "OK",
                      style: STextStyles.button
                          .copyWith(color: CFColors.stackAccent),
                    ),
                    onPressed: () {
                      if (_statusEst == ChangeNowLoadStatus.failed) {
                        _loadChangeNowStandardCurrencies();
                      }
                      if (_statusFixed == ChangeNowLoadStatus.failed) {
                        userReloaded = true;
                        _loadFixedRateMarkets();
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

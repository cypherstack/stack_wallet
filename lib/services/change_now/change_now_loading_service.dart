import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stackwallet/providers/exchange/available_currencies_state_provider.dart';
import 'package:stackwallet/providers/exchange/available_floating_rate_pairs_state_provider.dart';
import 'package:stackwallet/providers/exchange/change_now_provider.dart';
import 'package:stackwallet/providers/exchange/changenow_initial_load_status.dart';
import 'package:stackwallet/providers/exchange/estimate_rate_exchange_form_provider.dart';
import 'package:stackwallet/providers/exchange/fixed_rate_exchange_form_provider.dart';
import 'package:stackwallet/providers/exchange/fixed_rate_market_pairs_provider.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/utilities/logger.dart';

class ChangeNowLoadingService {
  Future<void> loadAll(WidgetRef ref, {Coin? coin}) async {
    try {
      await Future.wait([
        _loadFixedRateMarkets(ref, coin: coin),
        _loadChangeNowStandardCurrencies(ref, coin: coin),
      ]);
    } catch (e, s) {
      Logging.instance.log("ChangeNowLoadingService.loadAll failed: $e\n$s",
          level: LogLevel.Error);
    }
  }

  Future<void> _loadFixedRateMarkets(WidgetRef ref, {Coin? coin}) async {
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
        String fromTicker = "btc";
        String toTicker = "xmr";

        if (coin != null) {
          fromTicker = coin.ticker.toLowerCase();
        }

        final matchingMarkets = response3.value!
            .where((e) => e.to == toTicker && e.from == fromTicker);
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

  Future<void> _loadChangeNowStandardCurrencies(WidgetRef ref,
      {Coin? coin}) async {
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

        String fromTicker = "btc";
        String toTicker = "xmr";

        if (coin != null) {
          fromTicker = coin.ticker.toLowerCase();
        }

        if (response.value!.length > 1) {
          if (ref.read(estimatedRateExchangeFormProvider).from == null) {
            if (response.value!
                .where((e) => e.ticker == fromTicker)
                .isNotEmpty) {
              await ref.read(estimatedRateExchangeFormProvider).updateFrom(
                  response.value!.firstWhere((e) => e.ticker == fromTicker),
                  false);
            }
          }
          if (ref.read(estimatedRateExchangeFormProvider).to == null) {
            if (response.value!.where((e) => e.ticker == toTicker).isNotEmpty) {
              await ref.read(estimatedRateExchangeFormProvider).updateTo(
                  response.value!.firstWhere((e) => e.ticker == toTicker),
                  false);
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
}

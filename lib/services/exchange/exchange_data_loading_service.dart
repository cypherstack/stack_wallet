import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stackwallet/providers/providers.dart';
import 'package:stackwallet/services/exchange/change_now/change_now_api.dart';
import 'package:stackwallet/services/exchange/simpleswap/simpleswap_exchange.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/utilities/logger.dart';

class ExchangeDataLoadingService {
  Future<void> loadAll(WidgetRef ref, {Coin? coin}) async {
    try {
      await Future.wait([
        _loadFixedRateMarkets(ref, coin: coin),
        _loadChangeNowStandardCurrencies(ref, coin: coin),
        loadSimpleswapFixedRateCurrencies(ref),
        loadSimpleswapFloatingRateCurrencies(ref),
      ]);
    } catch (e, s) {
      Logging.instance.log("ExchangeDataLoadingService.loadAll failed: $e\n$s",
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
        await ChangeNowAPI.instance.getAvailableFixedRateMarkets();
    if (response3.value != null) {
      ref
          .read(availableChangeNowCurrenciesProvider)
          .updateMarkets(response3.value!);

      if (ref.read(exchangeFormStateProvider).market == null) {
        String fromTicker = "btc";
        String toTicker = "xmr";

        if (coin != null) {
          fromTicker = coin.ticker.toLowerCase();
        }

        final matchingMarkets = response3.value!
            .where((e) => e.to == toTicker && e.from == fromTicker);
        if (matchingMarkets.isNotEmpty) {
          await ref
              .read(exchangeFormStateProvider)
              .updateMarket(matchingMarkets.first, true);
        }
      }
    } else {
      Logging.instance.log(
          "Failed to load changeNOW fixed rate markets: ${response3.exception?.message}",
          level: LogLevel.Error);

      ref.read(changeNowFixedInitialLoadStatusStateProvider.state).state =
          ChangeNowLoadStatus.failed;
      return;
    }

    ref.read(changeNowFixedInitialLoadStatusStateProvider.state).state =
        ChangeNowLoadStatus.success;
  }

  Future<void> _loadChangeNowStandardCurrencies(
    WidgetRef ref, {
    Coin? coin,
  }) async {
    if (ref
            .read(changeNowEstimatedInitialLoadStatusStateProvider.state)
            .state ==
        ChangeNowLoadStatus.loading) {
      // already in progress so just
      return;
    }

    ref.read(changeNowEstimatedInitialLoadStatusStateProvider.state).state =
        ChangeNowLoadStatus.loading;

    final response = await ChangeNowAPI.instance.getAvailableCurrencies();
    final response2 =
        await ChangeNowAPI.instance.getAvailableFloatingRatePairs();
    if (response.value != null) {
      ref
          .read(availableChangeNowCurrenciesProvider)
          .updateCurrencies(response.value!);

      if (response2.value != null) {
        ref
            .read(availableChangeNowCurrenciesProvider)
            .updateFloatingPairs(response2.value!);

        String fromTicker = "btc";
        String toTicker = "xmr";

        if (coin != null) {
          fromTicker = coin.ticker.toLowerCase();
        }

        if (response.value!.length > 1) {
          if (ref.read(exchangeFormStateProvider).from == null) {
            if (response.value!
                .where((e) => e.ticker == fromTicker)
                .isNotEmpty) {
              await ref.read(exchangeFormStateProvider).updateFrom(
                  response.value!.firstWhere((e) => e.ticker == fromTicker),
                  false);
            }
          }
          if (ref.read(exchangeFormStateProvider).to == null) {
            if (response.value!.where((e) => e.ticker == toTicker).isNotEmpty) {
              await ref.read(exchangeFormStateProvider).updateTo(
                  response.value!.firstWhere((e) => e.ticker == toTicker),
                  false);
            }
          }
        }
      } else {
        Logging.instance.log(
            "Failed to load changeNOW available floating rate pairs: ${response2.exception?.message}",
            level: LogLevel.Error);
        ref.read(changeNowEstimatedInitialLoadStatusStateProvider.state).state =
            ChangeNowLoadStatus.failed;
        return;
      }
    } else {
      Logging.instance.log(
          "Failed to load changeNOW currencies: ${response.exception?.message}",
          level: LogLevel.Error);
      await Future<void>.delayed(const Duration(seconds: 3));
      ref.read(changeNowEstimatedInitialLoadStatusStateProvider.state).state =
          ChangeNowLoadStatus.failed;
      return;
    }

    ref.read(changeNowEstimatedInitialLoadStatusStateProvider.state).state =
        ChangeNowLoadStatus.success;
  }

  Future<void> loadSimpleswapFloatingRateCurrencies(WidgetRef ref) async {
    final exchange = SimpleSwapExchange();
    final responseCurrencies = await exchange.getAllCurrencies(false);

    if (responseCurrencies.value != null) {
      ref
          .read(availableSimpleswapCurrenciesProvider)
          .updateFloatingCurrencies(responseCurrencies.value!);

      final responsePairs = await exchange.getAllPairs(false);

      if (responsePairs.value != null) {
        ref
            .read(availableSimpleswapCurrenciesProvider)
            .updateFloatingPairs(responsePairs.value!);
      } else {
        Logging.instance.log(
          "loadSimpleswapFloatingRateCurrencies: $responsePairs",
          level: LogLevel.Warning,
        );
      }
    } else {
      Logging.instance.log(
        "loadSimpleswapFloatingRateCurrencies: $responseCurrencies",
        level: LogLevel.Warning,
      );
    }
  }

  Future<void> loadSimpleswapFixedRateCurrencies(WidgetRef ref) async {
    final exchange = SimpleSwapExchange();
    final responseCurrencies = await exchange.getAllCurrencies(true);

    if (responseCurrencies.value != null) {
      ref
          .read(availableSimpleswapCurrenciesProvider)
          .updateFixedCurrencies(responseCurrencies.value!);

      final responsePairs = await exchange.getAllPairs(true);

      if (responsePairs.value != null) {
        ref
            .read(availableSimpleswapCurrenciesProvider)
            .updateFixedPairs(responsePairs.value!);
      } else {
        Logging.instance.log(
          "loadSimpleswapFixedRateCurrencies: $responsePairs",
          level: LogLevel.Warning,
        );
      }
    } else {
      Logging.instance.log(
        "loadSimpleswapFixedRateCurrencies: $responseCurrencies",
        level: LogLevel.Warning,
      );
    }
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stackwallet/providers/providers.dart';
import 'package:stackwallet/services/buy/simplex/simplex_api.dart';
import 'package:stackwallet/utilities/logger.dart';

class BuyDataLoadingService {
  Future<void> loadAll(WidgetRef ref) async {
    try {
      await Future.wait([
        _loadSimplexCurrencies(ref),
      ]);
    } catch (e, s) {
      Logging.instance.log("BuyDataLoadingService.loadAll failed: $e\n$s",
          level: LogLevel.Error);
    }
  }

  Future<void> _loadSimplexCurrencies(WidgetRef ref) async {
    // if (ref
    //         .read(changeNowEstimatedInitialLoadStatusStateProvider.state)
    //         .state ==
    //     ChangeNowLoadStatus.loading) {
    //   // already in progress so just
    //   return;
    // }

    ref.read(simplexLoadStatusStateProvider.state).state =
        SimplexLoadStatus.loading;

    print(11);

    final response = await SimplexAPI.instance.getSupported();

    return;
    // if (response.value != null) {
    //   ref
    //       .read(availableChangeNowCurrenciesProvider)
    //       .updateCurrencies(response.value!);
    //
    //   if (response2.value != null) {
    //     ref
    //         .read(availableChangeNowCurrenciesProvider)
    //         .updateFloatingPairs(response2.value!);
    //
    //     String fromTicker = "btc";
    //     String toTicker = "xmr";
    //
    //     if (coin != null) {
    //       fromTicker = coin.ticker.toLowerCase();
    //     }
    //
    //     if (response.value!.length > 1) {
    //       if (ref.read(buyFormStateProvider).from == null) {
    //         if (response.value!
    //             .where((e) => e.ticker == fromTicker)
    //             .isNotEmpty) {
    //           await ref.read(buyFormStateProvider).updateFrom(
    //               response.value!.firstWhere((e) => e.ticker == fromTicker),
    //               false);
    //         }
    //       }
    //       if (ref.read(buyFormStateProvider).to == null) {
    //         if (response.value!.where((e) => e.ticker == toTicker).isNotEmpty) {
    //           await ref.read(buyFormStateProvider).updateTo(
    //               response.value!.firstWhere((e) => e.ticker == toTicker),
    //               false);
    //         }
    //       }
    //     }
    //   } else {
    //     Logging.instance.log(
    //         "Failed to load changeNOW available floating rate pairs: ${response2.exception?.errorMessage}",
    //         level: LogLevel.Error);
    //     ref.read(changeNowEstimatedInitialLoadStatusStateProvider.state).state =
    //         ChangeNowLoadStatus.failed;
    //     return;
    //   }
    // } else {
    //   Logging.instance.log(
    //       "Failed to load changeNOW currencies: ${response.exception?.errorMessage}",
    //       level: LogLevel.Error);
    //   await Future<void>.delayed(const Duration(seconds: 3));
    //   ref.read(changeNowEstimatedInitialLoadStatusStateProvider.state).state =
    //       ChangeNowLoadStatus.failed;
    //   return;
    // }
    //
    // ref.read(changeNowEstimatedInitialLoadStatusStateProvider.state).state =
    //     ChangeNowLoadStatus.success;
  }
}

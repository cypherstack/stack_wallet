import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import 'package:stackwallet/models/isar/exchange_cache/currency.dart';
import 'package:stackwallet/models/isar/exchange_cache/pair.dart';
import 'package:stackwallet/services/exchange/change_now/change_now_exchange.dart';
import 'package:stackwallet/services/exchange/majestic_bank/majestic_bank_exchange.dart';
import 'package:stackwallet/utilities/logger.dart';
import 'package:stackwallet/utilities/stack_file_system.dart';

class ExchangeDataLoadingService {
  ExchangeDataLoadingService._();
  static final ExchangeDataLoadingService _instance =
      ExchangeDataLoadingService._();
  static ExchangeDataLoadingService get instance => _instance;

  Isar? _isar;
  Isar get isar => _isar!;

  Future<void> init() async {
    if (_isar != null && isar.isOpen) return;
    _isar = await Isar.open(
      [
        CurrencySchema,
        PairSchema,
      ],
      directory: (await StackFileSystem.applicationIsarDirectory()).path,
      inspector: kDebugMode,
      name: "exchange_cache",
    );
  }

  bool _locked = false;

  Future<void> loadAll() async {
    print("LOADINGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG: LOCKED=$_locked");
    if (!_locked) {
      _locked = true;
      print("LOADINGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG");
      final time = DateTime.now();
      try {
        await Future.wait([
          _loadChangeNowCurrencies(),
          _loadChangeNowFixedRatePairs(),
          _loadChangeNowEstimatedRatePairs(),
          // loadSimpleswapFixedRateCurrencies(ref),
          // loadSimpleswapFloatingRateCurrencies(ref),
          loadMajesticBankCurrencies(),
        ]);

        print(
            "LOADINGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG done in ${DateTime.now().difference(time).inSeconds} seconds");
      } catch (e, s) {
        Logging.instance.log(
            "ExchangeDataLoadingService.loadAll failed: $e\n$s",
            level: LogLevel.Error);
      }
      _locked = false;
    }
  }

  Future<void> _loadChangeNowCurrencies() async {
    final exchange = ChangeNowExchange.instance;
    final responseCurrencies = await exchange.getAllCurrencies(false);
    if (responseCurrencies.value != null) {
      await isar.writeTxn(() async {
        final idsToDelete = await isar.currencies
            .where()
            .exchangeNameEqualTo(ChangeNowExchange.exchangeName)
            .idProperty()
            .findAll();
        await isar.currencies.deleteAll(idsToDelete);
        await isar.currencies.putAll(responseCurrencies.value!);
      });
    } else {
      Logging.instance.log(
          "Failed to load changeNOW currencies: ${responseCurrencies.exception?.message}",
          level: LogLevel.Error);
      return;
    }
  }

  Future<void> _loadChangeNowFixedRatePairs() async {
    final exchange = ChangeNowExchange.instance;

    final responsePairs = await exchange.getAllPairs(true);

    if (responsePairs.value != null) {
      await isar.writeTxn(() async {
        final idsToDelete2 = await isar.pairs
            .where()
            .exchangeNameEqualTo(ChangeNowExchange.exchangeName)
            .filter()
            .rateTypeEqualTo(SupportedRateType.fixed)
            .idProperty()
            .findAll();
        await isar.pairs.deleteAll(idsToDelete2);
        await isar.pairs.putAll(responsePairs.value!);
      });
    } else {
      Logging.instance.log(
          "Failed to load changeNOW available fixed rate pairs: ${responsePairs.exception?.message}",
          level: LogLevel.Error);
      return;
    }
  }

  Future<void> _loadChangeNowEstimatedRatePairs() async {
    final exchange = ChangeNowExchange.instance;

    final responsePairs = await exchange.getAllPairs(false);

    if (responsePairs.value != null) {
      await isar.writeTxn(() async {
        final idsToDelete = await isar.pairs
            .where()
            .exchangeNameEqualTo(ChangeNowExchange.exchangeName)
            .filter()
            .rateTypeEqualTo(SupportedRateType.estimated)
            .idProperty()
            .findAll();
        await isar.pairs.deleteAll(idsToDelete);
        await isar.pairs.putAll(responsePairs.value!);
      });
    } else {
      Logging.instance.log(
          "Failed to load changeNOW available floating rate pairs: ${responsePairs.exception?.message}",
          level: LogLevel.Error);
      return;
    }
  }
  //
  // Future<void> loadSimpleswapFloatingRateCurrencies(WidgetRef ref) async {
  //   final exchange = SimpleSwapExchange();
  //   final responseCurrencies = await exchange.getAllCurrencies(false);
  //
  //   if (responseCurrencies.value != null) {
  //     ref
  //         .read(availableSimpleswapCurrenciesProvider)
  //         .updateFloatingCurrencies(responseCurrencies.value!);
  //
  //     final responsePairs = await exchange.getAllPairs(false);
  //
  //     if (responsePairs.value != null) {
  //       ref
  //           .read(availableSimpleswapCurrenciesProvider)
  //           .updateFloatingPairs(responsePairs.value!);
  //     } else {
  //       Logging.instance.log(
  //         "loadSimpleswapFloatingRateCurrencies: $responsePairs",
  //         level: LogLevel.Warning,
  //       );
  //     }
  //   } else {
  //     Logging.instance.log(
  //       "loadSimpleswapFloatingRateCurrencies: $responseCurrencies",
  //       level: LogLevel.Warning,
  //     );
  //   }
  // }
  //
  // Future<void> loadSimpleswapFixedRateCurrencies(WidgetRef ref) async {
  //   final exchange = SimpleSwapExchange();
  //   final responseCurrencies = await exchange.getAllCurrencies(true);
  //
  //   if (responseCurrencies.value != null) {
  //     ref
  //         .read(availableSimpleswapCurrenciesProvider)
  //         .updateFixedCurrencies(responseCurrencies.value!);
  //
  //     final responsePairs = await exchange.getAllPairs(true);
  //
  //     if (responsePairs.value != null) {
  //       ref
  //           .read(availableSimpleswapCurrenciesProvider)
  //           .updateFixedPairs(responsePairs.value!);
  //     } else {
  //       Logging.instance.log(
  //         "loadSimpleswapFixedRateCurrencies: $responsePairs",
  //         level: LogLevel.Warning,
  //       );
  //     }
  //   } else {
  //     Logging.instance.log(
  //       "loadSimpleswapFixedRateCurrencies: $responseCurrencies",
  //       level: LogLevel.Warning,
  //     );
  //   }
  // }

  Future<void> loadMajesticBankCurrencies() async {
    final exchange = MajesticBankExchange.instance;
    final responseCurrencies = await exchange.getAllCurrencies(false);

    if (responseCurrencies.value != null) {
      final responsePairs = await exchange.getAllPairs(false);
      if (responsePairs.value != null) {
        await isar.writeTxn(() async {
          final idsToDelete = await isar.currencies
              .where()
              .exchangeNameEqualTo(MajesticBankExchange.exchangeName)
              .idProperty()
              .findAll();
          await isar.currencies.deleteAll(idsToDelete);
          await isar.currencies.putAll(responseCurrencies.value!);

          final idsToDelete2 = await isar.pairs
              .where()
              .exchangeNameEqualTo(MajesticBankExchange.exchangeName)
              .idProperty()
              .findAll();
          await isar.pairs.deleteAll(idsToDelete2);
          await isar.pairs.putAll(responsePairs.value!);
        });
      } else {
        Logging.instance.log(
          "loadMajesticBankCurrencies: $responsePairs",
          level: LogLevel.Warning,
        );
      }
    } else {
      Logging.instance.log(
        "loadMajesticBankCurrencies: $responseCurrencies",
        level: LogLevel.Warning,
      );
    }
  }
}

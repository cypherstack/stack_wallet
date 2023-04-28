import 'package:decimal/decimal.dart';
import 'package:stackwallet/models/exchange/response_objects/estimate.dart';
import 'package:stackwallet/models/exchange/response_objects/range.dart';
import 'package:stackwallet/models/exchange/response_objects/trade.dart';
import 'package:stackwallet/models/isar/exchange_cache/currency.dart';
import 'package:stackwallet/models/isar/exchange_cache/pair.dart';
import 'package:stackwallet/services/exchange/change_now/change_now_exchange.dart';
import 'package:stackwallet/services/exchange/exchange_response.dart';
import 'package:stackwallet/services/exchange/majestic_bank/majestic_bank_exchange.dart';
import 'package:stackwallet/services/exchange/simpleswap/simpleswap_exchange.dart';
import 'package:stackwallet/services/exchange/trocador/trocador_exchange.dart';

abstract class Exchange {
  static Exchange get defaultExchange => ChangeNowExchange.instance;

  static Exchange fromName(String name) {
    switch (name) {
      case ChangeNowExchange.exchangeName:
        return ChangeNowExchange.instance;
      case SimpleSwapExchange.exchangeName:
        return SimpleSwapExchange.instance;
      case MajesticBankExchange.exchangeName:
        return MajesticBankExchange.instance;
      case TrocadorExchange.exchangeName:
        return TrocadorExchange.instance;
      default:
        final split = name.split(" ");
        if (split.length >= 2) {
          // silly way to check for 'Trocador ($providerName)'
          return fromName(split.first);
        }
        throw ArgumentError("Unknown exchange name");
    }
  }

  String get name;

  Future<ExchangeResponse<List<Currency>>> getAllCurrencies(bool fixedRate);

  Future<ExchangeResponse<List<Currency>>> getPairedCurrencies(
    String forCurrency,
    bool fixedRate,
  );

  Future<ExchangeResponse<List<Pair>>> getPairsFor(
    String currency,
    bool fixedRate,
  );

  Future<ExchangeResponse<List<Pair>>> getAllPairs(bool fixedRate);

  Future<ExchangeResponse<Trade>> getTrade(String tradeId);
  Future<ExchangeResponse<Trade>> updateTrade(Trade trade);

  Future<ExchangeResponse<List<Trade>>> getTrades();

  Future<ExchangeResponse<Range>> getRange(
    String from,
    String to,
    bool fixedRate,
  );

  Future<ExchangeResponse<Estimate>> getEstimate(
    String from,
    String to,
    Decimal amount,
    bool fixedRate,
    bool reversed,
  );

  Future<ExchangeResponse<Trade>> createTrade({
    required String from,
    required String to,
    required bool fixedRate,
    required Decimal amount,
    required String addressTo,
    String? extraId,
    required String addressRefund,
    required String refundExtraId,
    Estimate? estimate,
    required bool reversed,
  });
}

import 'dart:convert';

import 'package:decimal/decimal.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:stackwallet/models/buy/response_objects/crypto.dart';
// import 'package:stackwallet/models/exchange/response_objects/fixed_rate_market.dart';
// import 'package:stackwallet/models/exchange/response_objects/pair.dart';
// import 'package:stackwallet/models/exchange/response_objects/range.dart';
// import 'package:stackwallet/models/exchange/response_objects/trade.dart';
import 'package:stackwallet/models/buy/response_objects/fiat.dart';
import 'package:stackwallet/models/buy/response_objects/quote.dart';
// import 'package:stackwallet/models/buy/response_objects/crypto.dart';
import 'package:stackwallet/services/buy/buy_response.dart';
import 'package:stackwallet/utilities/logger.dart';
import 'package:tuple/tuple.dart';

class SimplexAPI {
  static const String scheme = "https";
  static const String authority = "sandbox-api.stackwallet.com";

  SimplexAPI._();
  static final SimplexAPI _instance = SimplexAPI._();
  static SimplexAPI get instance => _instance;

  /// set this to override using standard http client. Useful for testing
  http.Client? client;

  Uri _buildUri(String path, Map<String, String>? params) {
    return Uri.https(authority, path, params);
  }

  Future<BuyResponse<Tuple2<List<Crypto>, List<Fiat>>>> getSupported() async {
    // example for quote courtesy of @danrmiller
    // curl -H "Content-Type: application/json" -d '{"digital_currency": "BTC", "fiat_currency": "USD", "requested_currency": "USD", "requested_amount": 100}' http://sandbox-api.stackwallet.com/quote
    // official docs reference eg
    // curl --request GET \
    //      --url https://sandbox.test-simplexcc.com/v2/supported_crypto_currencies \
    //      --header 'accept: application/json'

    try {
      Map<String, String> headers = {
        'Content-Type': 'application/json',
      };
      String data =
          '{"digital_currency": "BTC", "fiat_currency": "USD", "requested_currency": "USD", "requested_amount": 100}';
      Uri url = Uri.parse('http://sandbox-api.stackwallet.com/quote');

      var res = await http.post(url, headers: headers, body: data);

      if (res.statusCode != 200) {
        throw Exception(
            'getAvailableCurrencies exception: statusCode= ${res.statusCode}');
      }

      final jsonArray = jsonDecode(res.body);

      return await compute(_parseSupported, jsonArray);
    } catch (e, s) {
      Logging.instance.log("getAvailableCurrencies exception: $e\n$s",
          level: LogLevel.Error);
      return BuyResponse(
        exception: BuyException(
          e.toString(),
          BuyExceptionType.generic,
        ),
      );
    }
  }

  BuyResponse<Tuple2<List<Crypto>, List<Fiat>>> _parseSupported(
      dynamic jsonArray) {
    try {
      List<Crypto> cryptos = [];
      List<Fiat> fiats = [];

      var supportedCryptos =
          jsonArray['result']['supported_digital_currencies'];
      // TODO map List<String> supportedCryptos to List<Crypto>
      for (final ticker in supportedCryptos as List) {
        cryptos.add(Crypto.fromJson({
          'ticker': ticker as String,
          'name': ticker,
          'image': "",
        }));
      }
      var supportedFiats = jsonArray['result']['supported_fiat_currencies'];
      // TODO map List<String> supportedFiats to List<Fiat>
      for (final ticker in supportedFiats as List) {
        fiats.add(Fiat.fromJson({
          'ticker': ticker as String,
          'name': ticker,
          'image': "",
        }));
      }

      return BuyResponse(value: Tuple2(cryptos, fiats));
    } catch (e, s) {
      Logging.instance
          .log("_parseSupported exception: $e\n$s", level: LogLevel.Error);
      return BuyResponse(
        exception: BuyException(
          e.toString(),
          BuyExceptionType.generic,
        ),
      );
    }
  }

  Future<BuyResponse<SimplexQuote>> getQuote(SimplexQuote quote) async {
    // example for quote courtesy of @danrmiller
    // curl -H "Content-Type: application/json" -d '{"digital_currency": "BTC", "fiat_currency": "USD", "requested_currency": "USD", "requested_amount": 100}' http://sandbox-api.stackwallet.com/quote
    // official docs reference eg
    // curl --request GET \
    //      --url https://sandbox.test-simplexcc.com/v2/supported_crypto_currencies \
    //      --header 'accept: application/json'

    try {
      Map<String, String> headers = {
        'Content-Type': 'application/json',
      };
      String data =
          '{"digital_currency": "${quote.crypto.ticker.toUpperCase()}", "fiat_currency": "${quote.fiat.ticker.toUpperCase()}", "requested_currency": "USD", "requested_amount": ${quote.youPayFiatPrice}}';
      Uri url = Uri.parse('http://sandbox-api.stackwallet.com/quote');

      var res = await http.post(url, headers: headers, body: data);

      if (res.statusCode != 200) {
        throw Exception(
            'getAvailableCurrencies exception: statusCode= ${res.statusCode}');
      }

      final jsonArray = jsonDecode(res.body);

      return await compute(_parseQuote, jsonArray);
    } catch (e, s) {
      Logging.instance.log("getAvailableCurrencies exception: $e\n$s",
          level: LogLevel.Error);
      return BuyResponse(
        exception: BuyException(
          e.toString(),
          BuyExceptionType.generic,
        ),
      );
    }
  }

  BuyResponse<SimplexQuote> _parseQuote(dynamic jsonArray) {
    try {
      String fiatPrice = "${jsonArray['result']['fiat_money']['total_amount']}";
      String cryptoAmount = "${jsonArray['result']['digital_money']['amount']}";

      final quote = SimplexQuote(
        crypto: Crypto.fromJson({
          'ticker': jsonArray['result']['digital_money'][
              'currency'], // // TODO a Crypto.fromTicker here, requiring enums there?
          'name': 'Bitcoin',
          'image': ''
        }),
        fiat: Fiat.fromJson({
          'ticker': jsonArray['result']['fiat_money'][
              'currency'], // // TODO a Fiat.fromTicker here, requiring enums there?
          'name': 'Bitcoin',
          'image': ''
        }),
        youPayFiatPrice: Decimal.parse(fiatPrice),
        youReceiveCryptoAmount: Decimal.parse(cryptoAmount),
        purchaseId: jsonArray['result']['quote_id'] as String,
        receivingAddress: '',
      );
  //
  //   try {

      return BuyResponse(value: quote);
    } catch (e, s) {
      Logging.instance
          .log("_parseSupported exception: $e\n$s", level: LogLevel.Error);
      return BuyResponse(
        exception: BuyException(
          e.toString(),
          BuyExceptionType.generic,
        ),
      );
    }
  }
}

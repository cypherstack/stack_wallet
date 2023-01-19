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
    try {
      Map<String, String> headers = {
        'Content-Type': 'application/json',
      };
      String data =
          '{"CRYPTO_TICKER": "${quote.crypto.ticker.toUpperCase()}", "FIAT_TICKER": "${quote.fiat.ticker.toUpperCase()}", "REQUESTED_TICKER": "${quote.buyWithFiat ? quote.fiat.ticker.toUpperCase() : quote.crypto.ticker.toUpperCase()}", "REQUESTED_AMOUNT": ${quote.buyWithFiat ? quote.youPayFiatPrice : quote.youReceiveCryptoAmount}}';
      // TODO add USER_ID
      Uri url = Uri.parse('http://localhost/api.php/quote');
      // TODO update to stackwallet.com hosted API

      var res = await http.post(url, headers: headers, body: data);

      if (res.statusCode != 200) {
        throw Exception('getQuote exception: statusCode= ${res.statusCode}');
      }

      final jsonArray = jsonDecode(res.body);

      jsonArray['quote'] = quote; // Add and pass this on

      return await compute(_parseQuote, jsonArray);
    } catch (e, s) {
      Logging.instance.log("getQuote exception: $e\n$s", level: LogLevel.Error);
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
      String cryptoAmount = "${jsonArray['digital_money']['amount']}";

      SimplexQuote quote = jsonArray['quote'] as SimplexQuote;
      final SimplexQuote _quote = SimplexQuote(
        crypto: quote.crypto,
        fiat: quote.fiat,
        youPayFiatPrice: quote.youPayFiatPrice,
        youReceiveCryptoAmount: Decimal.parse(cryptoAmount),
        purchaseId: jsonArray['quote_id'] as String,
        receivingAddress: quote.receivingAddress,
        buyWithFiat: quote.buyWithFiat,
      );

      return BuyResponse(value: _quote);
    } catch (e, s) {
      Logging.instance
          .log("_parseQuote exception: $e\n$s", level: LogLevel.Error);
      return BuyResponse(
        exception: BuyException(
          e.toString(),
          BuyExceptionType.generic,
        ),
      );
    }
  }

  void newOrder(SimplexQuote quote) async {
    try {
      /*
      String version = "123"; // TODO pull from app version variable
      String app_end_user_id =
          "01e7a0b9-8dfc-4988-a28d-84a34e5f0a63"; // TODO generate per-user ID (pull from wallet?)
      String signup_timestamp =
          "1994-11-05T08:15:30-05:00"; // TODO supply real signup timestamp (pull from wallet?)
      String referral_ip = "207.66.86.226"; // TODO update to API server IP
      String payment_id =
          "faaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa"; // TODO make unique and save
      String order_id = "789"; // TODO generate unique ID per order
      String referrer = "https://stackwallet.com/simplex"; // TODO update
      String apiKey =
          "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJwYXJ0bmVyIjoic3RhY2t3YWxsZXQiLCJpcCI6WyIxLjIuMy40Il0sInNhbmRib3giOnRydWV9.VRaNZKPlc8wtkHGn0XscbsHnBMweZrMEyl2P94GfH94";
      String publicKey = "pk_test_7cce3f58-680d-420c-9888-f53d44763fe6";

      // Using simplex_api/order; doesn't work:
      Map<String, String> headers = {'Content-Type': 'application/json'};
      String data =
          '{"account_details": {"app_end_user_id": "${app_end_user_id}"}, "transaction_details": {"payment_details": {"fiat_total_amount": {"currency": "${quote.fiat.ticker.toUpperCase()}", "amount": "${quote.youPayFiatPrice}"}, "requested_digital_amount": {"currency": "${quote.crypto.ticker.toUpperCase()}", "amount": "${quote.youReceiveCryptoAmount}"}, "destination_wallet": {"currency": "${quote.crypto.ticker.toUpperCase()}", "address": "${quote.receivingAddress}", "validation": "bypass"}}';
      Uri url = Uri.parse('http://sandbox-api.stackwallet.com/order');
      var res = await http.post(url, headers: headers, body: data);

      if (res.statusCode != 200) {
        throw Exception('newOrder exception: statusCode= ${res.statusCode}');
      }
      final jsonArray = jsonDecode(res.body);
      print(jsonArray);
      /*

      // Calling Simplex's API manually:
      // curl --request POST \
      //      --url https://sandbox.test-simplexcc.com/wallet/merchant/v2/payments/partner/data \
      //      --header 'Authorization: ApiKey $apiKey' \
      //      --header 'accept: application/json' \
      //      --header 'content-type: application/json' \
      //      -d '{"account_details": {"app_provider_id": "$publicKey", "app_version_id": "123", "app_end_user_id": "01e7a0b9-8dfc-4988-a28d-84a34e5f0a63", "signup_login": {"timestamp": "1994-11-05T08:15:30-05:00", "ip": "207.66.86.226"}}, "transaction_details": {"payment_details": {"quote_id": "3b58f4b4-ed6f-447c-b96a-ffe97d7b6803", "payment_id": "baaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa", "order_id": "789", "original_http_ref_url": "https://stackwallet.com/simplex", "destination_wallet": {"currency": "BTC", "address": "bc1qjvj9ca8gdsv3g58yrzrk6jycvgnjh9uj35rja2"}}}}'

      Map<String, String> headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'ApiKey ${apiKey}',
      };
      String data =
          '{"account_details": {"app_provider_id": "$publicKey", "app_version_id": "$version", "app_end_user_id": "$app_end_user_id", "signup_login": {"timestamp": "$signup_timestamp", "ip": "$referral_ip"}}, "transaction_details": {"payment_details": {"quote_id": "${quote.purchaseId}", "payment_id": "$payment_id", "order_id": "$order_id", "original_http_ref_url": "$referrer", "destination_wallet": {"currency": "${quote.crypto.ticker.toUpperCase()}", "address": "${quote.receivingAddress}"}}}}';
      Uri url = Uri.parse(
          'https://sandbox.test-simplexcc.com/wallet/merchant/v2/payments/partner/data');
      var res = await http.post(url, headers: headers, body: data);

      if (res.statusCode != 200) {
        throw Exception('newOrder exception: statusCode= ${res.statusCode}');
      }
      final jsonArray = jsonDecode(res.body);
      print(jsonArray);
      // TODO check if {is_key_required: true} (indicates success)
      */*/

      print('test');
      return;
    } catch (e, s) {
      Logging.instance.log("newOrder exception: $e\n$s", level: LogLevel.Error);
      return; /*BuyResponse(
        exception: BuyException(
          e.toString(),
          BuyExceptionType.generic,
        ),
      );*/
    }
  }
}

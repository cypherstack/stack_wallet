// TODO use _buildUri

import 'dart:async';
import 'dart:convert';

import 'package:decimal/decimal.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:stackwallet/models/buy/response_objects/crypto.dart';
import 'package:stackwallet/models/buy/response_objects/fiat.dart';
import 'package:stackwallet/models/buy/response_objects/order.dart';
import 'package:stackwallet/models/buy/response_objects/quote.dart';
import 'package:stackwallet/services/buy/buy_response.dart';
import 'package:stackwallet/utilities/logger.dart';
import 'package:url_launcher/url_launcher.dart';

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

  Future<BuyResponse<List<Crypto>>> getSupportedCryptos() async {
    try {
      Map<String, String> headers = {
        'Content-Type': 'application/x-www-form-urlencoded',
      };
      Uri url = Uri.parse('http://localhost/api.php?ROUTE=supported_cryptos');

      var res = await http.post(url, headers: headers);
      if (res.statusCode != 200) {
        throw Exception(
            'getAvailableCurrencies exception: statusCode= ${res.statusCode}');
      }
      final jsonArray = jsonDecode(res.body); // TODO handle if invalid json

      return await compute(_parseSupportedCryptos, jsonArray);
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

  BuyResponse<List<Crypto>> _parseSupportedCryptos(dynamic jsonArray) {
    try {
      List<Crypto> cryptos = [];
      List<Fiat> fiats = [];

      for (final crypto in jsonArray as List) {
        // TODO validate jsonArray
        cryptos.add(Crypto.fromJson({
          'ticker': "${crypto['ticker_symbol']}",
          'name': crypto['name'],
          'network': "${crypto['network']}",
          'contractAddress': "${crypto['contractAddress']}",
          'image': "",
        }));
      }

      return BuyResponse(value: cryptos);
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

  Future<BuyResponse<List<Fiat>>> getSupportedFiats() async {
    try {
      Map<String, String> headers = {
        'Content-Type': 'application/x-www-form-urlencoded',
      };
      Uri url = Uri.parse('http://localhost/api.php?ROUTE=supported_fiats');

      var res = await http.post(url, headers: headers);
      if (res.statusCode != 200) {
        throw Exception(
            'getAvailableCurrencies exception: statusCode= ${res.statusCode}');
      }
      final jsonArray = jsonDecode(res.body); // TODO validate json

      return await compute(_parseSupportedFiats, jsonArray);
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

  BuyResponse<List<Fiat>> _parseSupportedFiats(dynamic jsonArray) {
    try {
      List<Crypto> cryptos = [];
      List<Fiat> fiats = [];

      for (final fiat in jsonArray as List) {
        // TODO validate list
        fiats.add(Fiat.fromJson({
          'ticker': "${fiat['ticker_symbol']}",
          'name': "${fiat['ticker_symbol']}",
          'min_amount': "${fiat['min_amount']}",
          'max_amount': "${fiat['max_amount']}",
          'image': "",
        }));
      }

      return BuyResponse(value: fiats);
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
        'Content-Type': 'application/x-www-form-urlencoded',
      };
      Map<String, String> data = {
        'ROUTE': 'quote',
        'CRYPTO_TICKER': quote.crypto.ticker.toUpperCase(),
        'FIAT_TICKER': quote.fiat.ticker.toUpperCase(),
        'REQUESTED_TICKER': quote.buyWithFiat
            ? quote.fiat.ticker.toUpperCase()
            : quote.crypto.ticker.toUpperCase(),
        'REQUESTED_AMOUNT': quote.buyWithFiat
            ? "${quote.youPayFiatPrice}"
            : "${quote.youReceiveCryptoAmount}",
      };
      // TODO add USER_ID
      Uri url = Uri.http('localhost', 'api.php', data);
      // TODO update to stackwallet.com hosted API and use HTTPS

      var res = await http.post(url, headers: headers, body: json.encode(data));
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
        id: jsonArray['quote_id'] as String,
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

  Future<BuyResponse<SimplexOrder>> newOrder(SimplexQuote quote) async {
    // Calling Simplex's API manually:
    // curl --request POST \
    //      --url https://sandbox.test-simplexcc.com/wallet/merchant/v2/payments/partner/data \
    //      --header 'Authorization: ApiKey $apiKey' \
    //      --header 'accept: application/json' \
    //      --header 'content-type: application/json' \
    //      -d '{"account_details": {"app_provider_id": "$publicKey", "app_version_id": "123", "app_end_user_id": "01e7a0b9-8dfc-4988-a28d-84a34e5f0a63", "signup_login": {"timestamp": "1994-11-05T08:15:30-05:00", "ip": "207.66.86.226"}}, "transaction_details": {"payment_details": {"quote_id": "3b58f4b4-ed6f-447c-b96a-ffe97d7b6803", "payment_id": "baaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa", "order_id": "789", "original_http_ref_url": "https://stackwallet.com/simplex", "destination_wallet": {"currency": "BTC", "address": "bc1qjvj9ca8gdsv3g58yrzrk6jycvgnjh9uj35rja2"}}}}'
    try {
      Map<String, String> headers = {
        'Content-Type': 'application/x-www-form-urlencoded',
      };
      Map<String, String> data = {
        'ROUTE': 'order',
        'QUOTE_ID': "${quote.id}",
        'ADDRESS': "${quote.receivingAddress}",
        'CRYPTO_TICKER': "${quote.crypto.ticker.toUpperCase()}",
      };
      // TODO add USER_ID

      Uri url = Uri.http('localhost', 'api.php', data);
      // TODO update to stackwallet.com hosted API and use HTTPS
      var res = await http.post(url, headers: headers, body: json.encode(data));
      if (res.statusCode != 200) {
        throw Exception('newOrder exception: statusCode= ${res.statusCode}');
      }
      final jsonArray = jsonDecode(res.body); // TODO check if valid json

      SimplexOrder _order = SimplexOrder(
        quote: quote,
        paymentId: "${jsonArray['paymentId']}",
        orderId: "${jsonArray['orderId']}",
        userId: "${jsonArray['userId']}",
      );

      return BuyResponse(value: _order);
    } catch (e, s) {
      Logging.instance.log("newOrder exception: $e\n$s", level: LogLevel.Error);
      return BuyResponse(
        exception: BuyException(
          e.toString(),
          BuyExceptionType.generic,
        ),
      );
    }
  }

  Future<BuyResponse<bool>> redirect(SimplexOrder order) async {
    try {
      bool status = await launchUrl(
        Uri.parse(
            "http://localhost/api.php?ROUTE=redirect&PAYMENT_ID=${order.paymentId}"),
        mode: LaunchMode.externalApplication,
      );

      return BuyResponse(value: status);
    } catch (e, s) {
      Logging.instance.log("newOrder exception: $e\n$s", level: LogLevel.Error);
      return BuyResponse(
          exception: BuyException(
        e.toString(),
        BuyExceptionType.generic,
      ));
    }
  }
}

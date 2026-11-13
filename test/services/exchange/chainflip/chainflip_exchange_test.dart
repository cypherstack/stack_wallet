import 'dart:convert';
import 'dart:io';

import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/models/exchange/response_objects/estimate.dart';
import 'package:stackwallet/models/exchange/response_objects/trade.dart';
import 'package:stackwallet/models/isar/exchange_cache/currency.dart';
import 'package:stackwallet/models/isar/exchange_cache/pair.dart';
import 'package:stackwallet/networking/http.dart';
import 'package:stackwallet/services/exchange/chainflip/chainflip_api.dart';
import 'package:stackwallet/services/exchange/chainflip/chainflip_exchange.dart';

class _FakeHttp extends HTTP {
  _FakeHttp(this.handler);

  final Future<Response> Function(Uri url, Map<String, String>? headers)
  handler;

  @override
  Future<Response> get({
    required Uri url,
    Map<String, String>? headers,
    required ({InternetAddress host, int port})? proxyInfo,
    Duration? connectionTimeout,
  }) {
    return handler(url, headers);
  }
}

Response _json(Object body, {int code = 200}) {
  return Response(utf8.encode(jsonEncode(body)), code);
}

Map<String, dynamic> _asset({
  required String id,
  required String ticker,
  required String network,
  required int decimals,
  required String minimalAmountNative,
  String? contractAddress,
}) {
  return <String, dynamic>{
    "id": id,
    "ticker": ticker,
    "name": network,
    "network": network,
    "contractAddress": contractAddress,
    "assetLogo": "/assets/$id/logo.svg",
    "networkLogo": "/networks/${id.split(".").last}/logo.svg",
    "decimals": decimals,
    "enabled": true,
    "direction": "both",
    "minimalAmountNative": minimalAmountNative,
    "usdPrice": 1.0,
  };
}

Map<String, dynamic> _assetsBody() {
  return <String, dynamic>{
    "assets": <Map<String, dynamic>>[
      _asset(
        id: "bnb.bsc",
        ticker: "BNB",
        network: "Bsc",
        decimals: 18,
        minimalAmountNative: "20000000000000000",
      ),
      _asset(
        id: "btc.btc",
        ticker: "BTC",
        network: "Bitcoin",
        decimals: 8,
        minimalAmountNative: "40000",
      ),
      _asset(
        id: "cbbtc.eth",
        ticker: "CBBTC",
        network: "Ethereum",
        decimals: 8,
        minimalAmountNative: "40000",
        contractAddress: "0xcbB7C0000aB88B473b1f5aFd9ef808440eed33Bf",
      ),
      _asset(
        id: "dot.hub",
        ticker: "DOT",
        network: "Assethub",
        decimals: 10,
        minimalAmountNative: "40000000000",
      ),
      _asset(
        id: "eth.arb",
        ticker: "ETH",
        network: "Arbitrum",
        decimals: 18,
        minimalAmountNative: "3900000000000000",
      ),
      _asset(
        id: "eth.eth",
        ticker: "ETH",
        network: "Ethereum",
        decimals: 18,
        minimalAmountNative: "10000000000000000",
      ),
      _asset(
        id: "flip.eth",
        ticker: "FLIP",
        network: "Ethereum",
        decimals: 18,
        minimalAmountNative: "4000000000000000000",
        contractAddress: "0x826180541412D574cf1336d22c0C0a287822678A",
      ),
      _asset(
        id: "sol.sol",
        ticker: "SOL",
        network: "Solana",
        decimals: 9,
        minimalAmountNative: "68000000",
      ),
      _asset(
        id: "trx.tron",
        ticker: "TRX",
        network: "Tron",
        decimals: 6,
        minimalAmountNative: "30000000",
      ),
      _asset(
        id: "usdc.arb",
        ticker: "USDC",
        network: "Arbitrum",
        decimals: 6,
        minimalAmountNative: "10000000",
        contractAddress: "0xaf88d065e77c8cC2239327C5EDb3A432268e5831",
      ),
      _asset(
        id: "usdc.eth",
        ticker: "USDC",
        network: "Ethereum",
        decimals: 6,
        minimalAmountNative: "20000000",
        contractAddress: "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48",
      ),
      _asset(
        id: "usdc.hub",
        ticker: "USDC",
        network: "Assethub",
        decimals: 6,
        minimalAmountNative: "20000000",
        contractAddress: "1337",
      ),
      _asset(
        id: "usdc.sol",
        ticker: "USDC",
        network: "Solana",
        decimals: 6,
        minimalAmountNative: "10000000",
        contractAddress: "EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v",
      ),
      _asset(
        id: "usdt.arb",
        ticker: "USDT",
        network: "Arbitrum",
        decimals: 6,
        minimalAmountNative: "10000000",
        contractAddress: "0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9",
      ),
      _asset(
        id: "usdt.bsc",
        ticker: "USDT",
        network: "Bsc",
        decimals: 18,
        minimalAmountNative: "10000000000000000000",
        contractAddress: "0x55d398326f99059fF775485246999027B3197955",
      ),
      _asset(
        id: "usdt.eth",
        ticker: "USDT",
        network: "Ethereum",
        decimals: 6,
        minimalAmountNative: "20000000",
        contractAddress: "0xdAC17F958D2ee523a2206206994597C13D831ec7",
      ),
      _asset(
        id: "usdt.hub",
        ticker: "USDT",
        network: "Assethub",
        decimals: 6,
        minimalAmountNative: "20000000",
        contractAddress: "1984",
      ),
      _asset(
        id: "usdt.sol",
        ticker: "USDT",
        network: "Solana",
        decimals: 6,
        minimalAmountNative: "10000000",
        contractAddress: "Es9vMFrzaCERmJfrF4H2FYD4KCoNkY11McCe8BenwNYB",
      ),
      _asset(
        id: "usdt.tron",
        ticker: "USDT",
        network: "Tron",
        decimals: 6,
        minimalAmountNative: "10000000",
        contractAddress: "TR7NHqjeKQxGTCi8q8ZY4pL8otSzgjLj6t",
      ),
      _asset(
        id: "wbtc.eth",
        ticker: "WBTC",
        network: "Ethereum",
        decimals: 8,
        minimalAmountNative: "40000",
        contractAddress: "0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599",
      ),
    ],
  };
}

List<Map<String, dynamic>> _quoteBody() {
  return <Map<String, dynamic>>[
    <String, dynamic>{
      "type": "regular",
      "ingressAmountNative": "1000000",
      "egressAmountNative": "353856642395626881",
      "estimatedPrice": 35.3856642395626881,
      "recommendedSlippageTolerancePercent": 2.5,
      "recommendedRetryDurationInBlocks": 150,
      "recommendedLivePriceSlippageTolerancePercent": 0.5,
      "lowLiquidityWarning": false,
      "boostQuote": <String, dynamic>{
        "type": "regular",
        "ingressAmountNative": "1000000",
        "egressAmountNative": "999999999999999999",
        "estimatedPrice": 99.9,
        "recommendedSlippageTolerancePercent": 2.5,
        "recommendedRetryDurationInBlocks": 150,
        "lowLiquidityWarning": false,
      },
    },
    <String, dynamic>{
      "type": "dca",
      "ingressAmountNative": "1000000",
      "egressAmountNative": "353856642395626881",
      "recommendedSlippageTolerancePercent": 2.5,
      "recommendedRetryDurationInBlocks": 150,
      "lowLiquidityWarning": false,
    },
  ];
}

Map<String, dynamic> _depositBody() {
  return <String, dynamic>{
    "id": 42,
    "address": "deposit-address",
    "issuedBlock": 123,
    "network": "Bitcoin",
    "channelId": 7,
    "sourceExpiryBlock": 456,
    "explorerUrl": "https://scan.chainflip.io/channels/123-Bitcoin-7",
    "channelOpeningFeeNative": "0",
    "destinationAddress": "destination-address",
  };
}

Map<String, dynamic> _statusBody({
  required String state,
  bool swapped = true,
  bool refunded = false,
  bool failed = false,
  String egressAmountNative = "353856642395626881",
}) {
  return <String, dynamic>{
    "id": 42,
    "status": <String, dynamic>{
      "state": state,
      "swapId": "99",
      "sourceAsset": "btc.btc",
      "destinationAsset": "eth.eth",
      "destinationAddress": "destination-address",
      "depositChannel": <String, dynamic>{
        "id": "123-Bitcoin-7",
        "depositAddress": "deposit-address",
        "createdAt": 1700000000000,
      },
      "fillOrKillParams": <String, dynamic>{"refundAddress": "refund-address"},
      "deposit": <String, dynamic>{
        "amountNative": "1000000",
        "transactionReference": "tx-in",
        if (failed)
          "failure": <String, dynamic>{
            "mode": "DEPOSIT_REJECTED",
            "reason": <String, dynamic>{
              "code": "TransactionRejectedByBroker",
              "message": "rejected",
            },
          },
      },
      if (swapped)
        "swapEgress": <String, dynamic>{
          "amountNative": egressAmountNative,
          "transactionReference": "tx-out",
        },
      if (refunded)
        "refundEgress": <String, dynamic>{
          "amountNative": "1000000",
          "transactionReference": "tx-refund",
        },
    },
  };
}

Trade _oldTrade() {
  return Trade(
    uuid: "uuid",
    tradeId: "42",
    rateType: "estimated",
    direction: "direct",
    timestamp: DateTime.fromMillisecondsSinceEpoch(1700000000000),
    updatedAt: DateTime.fromMillisecondsSinceEpoch(1700000000000),
    payInCurrency: "BTC",
    payInAmount: "0.01",
    payInAddress: "deposit-address",
    payInNetwork: "Bitcoin",
    payInExtraId: "",
    payInTxid: "",
    payOutCurrency: "ETH",
    payOutAmount: "0.35",
    payOutAddress: "destination-address",
    payOutNetwork: "Ethereum",
    payOutExtraId: "",
    payOutTxid: "",
    refundAddress: "refund-address",
    refundExtraId: "",
    status: "Waiting",
    exchangeName: ChainflipExchange.exchangeName,
    other: jsonEncode(<String, dynamic>{
      "explorerUrl": "https://scan.chainflip.io/channels/123-Bitcoin-7",
    }),
  );
}

void main() {
  late ChainflipExchange exchange;
  late Uri lastUri;
  late Map<String, String>? lastHeaders;
  late List<String> paths;

  setUp(() {
    ChainflipApi.apiKeyOverride = "test-key";
    exchange = ChainflipExchange.forTesting();
    paths = <String>[];
  });

  void useFake(
    Future<Response> Function(Uri url, Map<String, String>? headers) handler,
  ) {
    ChainflipApi.client = _FakeHttp((url, headers) {
      lastUri = url;
      lastHeaders = headers;
      paths.add(url.path);
      return handler(url, headers);
    });
  }

  Future<String?> statusFor(Map<String, dynamic> body) async {
    useFake((url, headers) async {
      if (url.path == "/assets") return _json(_assetsBody());
      if (url.path == "/status-by-id") return _json(body);
      throw StateError("unexpected ${url.path}");
    });
    final response = await exchange.updateTrade(_oldTrade());
    expect(response.exception, isNull);
    return response.value!.status;
  }

  test("offers only the assets Stack Wallet holds", () async {
    useFake((url, headers) async => _json(_assetsBody()));

    final response = await exchange.getAllCurrencies(false);
    expect(response.exception, isNull);
    final byId = <String?, Currency>{
      for (final currency in response.value!) currency.externalId: currency,
    };

    // The live catalog has 20 assets; ETH on Arbitrum, USDT on BSC/Tron,
    // Asset Hub, WBTC, cbBTC, FLIP etc. are not offered.
    expect(byId.keys.toSet(), <String>{
      "btc.btc",
      "eth.eth",
      "sol.sol",
      "usdc.eth",
      "usdt.eth",
      "usdc.sol",
      "usdt.sol",
    });
    for (final currency in byId.values) {
      expect(currency.isStackCoin, isTrue, reason: currency.externalId);
      expect(currency.rateType, SupportedRateType.estimated);
    }
    expect(byId["usdt.eth"]!.network, "Ethereum");
    expect(byId["usdt.sol"]!.network, "Solana");
    expect(
      byId["usdt.sol"]!.image,
      startsWith("https://chainflip-broker.io/assets/"),
    );
  });

  test("declines assets Stack Wallet does not hold", () async {
    useFake((url, headers) async {
      if (url.path == "/assets") return _json(_assetsBody());
      throw StateError("unexpected ${url.path}");
    });

    final estimate = await exchange.getEstimates(
      "ETH",
      "Arbitrum",
      "BTC",
      "Bitcoin",
      Decimal.one,
      false,
      false,
    );
    expect(estimate.value, isNull);
    expect(
      estimate.exception.toString(),
      contains("does not support ETH on Arbitrum"),
    );

    final range = await exchange.getRange(
      "USDT",
      "Bsc",
      "BTC",
      "Bitcoin",
      false,
    );
    expect(range.value, isNull);
    expect(
      range.exception.toString(),
      contains("does not support USDT on Bsc"),
    );
    expect(paths, isNot(contains("/quotes-native")));
  });

  test("declines fixed-rate currency loading", () async {
    final response = await exchange.getAllCurrencies(true);
    expect(response.value, isNull);
    expect(response.exception.toString(), contains("Fixed-rate"));
  });

  test("returns the live minimum and the BaaS hard maximum", () async {
    useFake((url, headers) async => _json(_assetsBody()));

    final btc = await exchange.getRange(
      "BTC",
      "Bitcoin",
      "ETH",
      "Ethereum",
      false,
    );
    expect(btc.exception, isNull);
    expect(btc.value!.min, Decimal.parse("0.0004"));
    expect(btc.value!.max, Decimal.parse("792281625142643375935.43950335"));

    final eth = await exchange.getRange(
      "ETH",
      "Ethereum",
      "BTC",
      "Bitcoin",
      false,
    );
    expect(eth.exception, isNull);
    expect(eth.value!.min, Decimal.parse("0.01"));
    expect(eth.value!.max, Decimal.parse("79228162514.264337593543950335"));

    final expected = <(String, String), (String, String)>{
      ("USDC", "Ethereum"): ("20", "79228162514264337593543.950335"),
      ("SOL", "Solana"): ("0.068", "79228162514264337593.543950335"),
      ("USDT", "Solana"): ("10", "79228162514264337593543.950335"),
    };
    for (final entry in expected.entries) {
      final range = await exchange.getRange(
        entry.key.$1,
        entry.key.$2,
        "BTC",
        "Bitcoin",
        false,
      );
      expect(range.exception, isNull, reason: entry.key.$1);
      expect(range.value!.min, Decimal.parse(entry.value.$1));
      expect(range.value!.max, Decimal.parse(entry.value.$2));
    }
  });

  test("declines fixed-rate ranges", () async {
    final response = await exchange.getRange(
      "BTC",
      "Bitcoin",
      "ETH",
      "Ethereum",
      true,
    );
    expect(response.value, isNull);
    expect(response.exception.toString(), contains("Fixed-rate"));
  });

  test("uses the regular quote and exact native amounts", () async {
    useFake((url, headers) async {
      if (url.path == "/assets") return _json(_assetsBody());
      if (url.path == "/quotes-native") return _json(_quoteBody());
      throw StateError("unexpected ${url.path}");
    });

    final response = await exchange.getEstimates(
      "BTC",
      "Bitcoin",
      "ETH",
      "Ethereum",
      Decimal.parse("0.01"),
      false,
      false,
    );

    expect(response.exception, isNull);
    expect(response.value!.length, 1);
    final estimate = response.value!.first;
    expect(estimate.estimatedAmount, Decimal.parse("0.353856642395626881"));
    expect(estimate.fixedRate, isFalse);
    expect(estimate.reversed, isFalse);

    final rateId = jsonDecode(estimate.rateId!) as Map<String, dynamic>;
    expect(rateId["sourceAsset"], "btc.btc");
    expect(rateId["destinationAsset"], "eth.eth");
    expect(rateId["amountNative"], "1000000");
    expect(rateId["estimatedPrice"], "35.385664239562686");
    expect(rateId["recommendedSlippageTolerancePercent"], 2.5);
    expect(rateId["recommendedRetryDurationInBlocks"], 150);
    expect(rateId["recommendedLivePriceSlippageTolerancePercent"], 0.5);
    expect(lastUri.queryParameters["amount"], "1000000");
    expect(lastUri.queryParameters.containsKey("apiKey"), isFalse);
    expect(lastUri.toString(), isNot(contains("test-key")));
    expect(lastHeaders!["X-API-Key"], "test-key");
  });

  test("rejects a quote without a positive output or price", () async {
    useFake((url, headers) async {
      if (url.path == "/assets") return _json(_assetsBody());
      if (url.path == "/quotes-native") {
        return _json(<Map<String, dynamic>>[
          <String, dynamic>{
            "type": "regular",
            "ingressAmountNative": "1000000",
            "estimatedPrice": 35.3,
          },
        ]);
      }
      throw StateError("unexpected ${url.path}");
    });

    final response = await exchange.getEstimates(
      "BTC",
      "Bitcoin",
      "ETH",
      "Ethereum",
      Decimal.parse("0.01"),
      false,
      false,
    );
    expect(response.value, isNull);
    expect(response.exception.toString(), contains("incomplete quote"));
  });

  test("converts 18-decimal amounts exactly", () async {
    useFake((url, headers) async {
      if (url.path == "/assets") return _json(_assetsBody());
      if (url.path == "/quotes-native") return _json(_quoteBody());
      throw StateError("unexpected ${url.path}");
    });

    await exchange.getEstimates(
      "ETH",
      "Ethereum",
      "BTC",
      "Bitcoin",
      Decimal.parse("1.5"),
      false,
      false,
    );

    expect(lastUri.queryParameters["amount"], "1500000000000000000");

    final cases = <(String, String, String, String)>[
      ("ETH", "Ethereum", "0.02", "20000000000000000"),
      ("BTC", "Bitcoin", "0.0004", "40000"),
      ("USDC", "Ethereum", "20", "20000000"),
      ("SOL", "Solana", "0.068", "68000000"),
    ];
    for (final (ticker, network, human, native) in cases) {
      await exchange.getEstimates(
        ticker,
        network,
        "USDT",
        "Solana",
        Decimal.parse(human),
        false,
        false,
      );
      expect(lastUri.queryParameters["amount"], native, reason: ticker);
    }
  });

  test("rejects amounts finer than the asset's decimals", () async {
    useFake((url, headers) async {
      if (url.path == "/assets") return _json(_assetsBody());
      throw StateError("unexpected ${url.path}");
    });

    final response = await exchange.getEstimates(
      "USDC",
      "Ethereum",
      "BTC",
      "Bitcoin",
      Decimal.parse("1.2345678"),
      false,
      false,
    );
    expect(response.value, isNull);
    expect(response.exception.toString(), contains("at most 6 decimal"));
    expect(paths, isNot(contains("/quotes-native")));
  });

  test("declines fixed and reversed estimates", () async {
    final fixed = await exchange.getEstimates(
      "BTC",
      "Bitcoin",
      "ETH",
      "Ethereum",
      Decimal.one,
      true,
      false,
    );
    expect(fixed.value, isNull);
    expect(fixed.exception.toString(), contains("Fixed-rate"));

    final reversed = await exchange.getEstimates(
      "BTC",
      "Bitcoin",
      "ETH",
      "Ethereum",
      Decimal.one,
      false,
      true,
    );
    expect(reversed.value, isNull);
    expect(reversed.exception.toString(), contains("Reversed"));
  });

  test("opens a channel and returns a complete waiting trade", () async {
    useFake((url, headers) async {
      if (url.path == "/assets") return _json(_assetsBody());
      if (url.path == "/swap") return _json(_depositBody());
      throw StateError("unexpected ${url.path}");
    });

    final estimate = Estimate(
      estimatedAmount: Decimal.parse("0.353856642395626881"),
      fixedRate: false,
      reversed: false,
      rateId: jsonEncode(<String, dynamic>{
        "sourceAsset": "btc.btc",
        "destinationAsset": "eth.eth",
        "amountNative": "1000000",
        "ingressAmountNative": "1000000",
        "egressAmountNative": "353856642395626881",
        "estimatedPrice": "35.3856642395626881",
        "recommendedSlippageTolerancePercent": 2.5,
        "recommendedRetryDurationInBlocks": 150,
      }),
      exchangeProvider: ChainflipExchange.exchangeName,
    );

    final response = await exchange.createTrade(
      from: "BTC",
      fromNetwork: "Bitcoin",
      to: "ETH",
      toNetwork: "Ethereum",
      fixedRate: false,
      amount: Decimal.parse("0.01"),
      addressTo: "destination-address",
      addressRefund: "refund-address",
      refundExtraId: "",
      estimate: estimate,
      reversed: false,
    );

    expect(response.exception, isNull);
    final trade = response.value!;
    expect(trade.tradeId, "42");
    expect(trade.payInAddress, "deposit-address");
    expect(trade.payInAmount, "0.01");
    expect(trade.payOutAmount, "0.353856642395626881");
    expect(trade.payOutAddress, "destination-address");
    expect(trade.refundAddress, "refund-address");
    expect(trade.status, "Waiting");
    expect(trade.other, contains('"explorerUrl"'));
    expect(trade.other, contains("123-Bitcoin-7"));
    expect(exchange.supportsRefundAddress, isTrue);
    expect(exchange.supportsExtraId, isFalse);
    expect(lastUri.queryParameters["retryDurationInBlocks"], "150");
    // estimatedPrice * (1 - 2.5 / 100), floored to 18 decimal places.
    expect(lastUri.queryParameters["minimumPrice"], "34.501022633573620897");
    expect(paths, isNot(contains("/quotes-native")));
  });

  test("requotes when the estimate does not match the trade", () async {
    useFake((url, headers) async {
      if (url.path == "/assets") return _json(_assetsBody());
      if (url.path == "/quotes-native") return _json(_quoteBody());
      if (url.path == "/swap") return _json(_depositBody());
      throw StateError("unexpected ${url.path}");
    });

    // Issued for 0.02 BTC; the trade is for 0.01 BTC.
    final stale = Estimate(
      estimatedAmount: Decimal.parse("0.7"),
      fixedRate: false,
      reversed: false,
      rateId: jsonEncode(<String, dynamic>{
        "sourceAsset": "btc.btc",
        "destinationAsset": "eth.eth",
        "amountNative": "2000000",
        "ingressAmountNative": "2000000",
        "egressAmountNative": "700000000000000000",
        "estimatedPrice": "1",
        "recommendedSlippageTolerancePercent": 2.5,
        "recommendedRetryDurationInBlocks": 150,
      }),
      exchangeProvider: ChainflipExchange.exchangeName,
    );

    final response = await exchange.createTrade(
      from: "BTC",
      fromNetwork: "Bitcoin",
      to: "ETH",
      toNetwork: "Ethereum",
      fixedRate: false,
      amount: Decimal.parse("0.01"),
      addressTo: "destination-address",
      addressRefund: "refund-address",
      refundExtraId: "",
      estimate: stale,
      reversed: false,
    );

    expect(response.exception, isNull);
    expect(paths, contains("/quotes-native"));
    expect(response.value!.payInAmount, "0.01");
    expect(response.value!.payOutAmount, "0.353856642395626881");
    expect(lastUri.queryParameters["livePriceSlippageTolerancePercent"], "0.5");
    expect(lastUri.queryParameters["minimumPrice"], startsWith("34.50102263"));
  });

  test("declines fixed and reversed trades before a network call", () async {
    final fixed = await exchange.createTrade(
      from: "BTC",
      fromNetwork: "Bitcoin",
      to: "ETH",
      toNetwork: "Ethereum",
      fixedRate: true,
      amount: Decimal.one,
      addressTo: "destination-address",
      addressRefund: "refund-address",
      refundExtraId: "",
      reversed: false,
    );
    expect(fixed.value, isNull);
    expect(fixed.exception.toString(), contains("Fixed-rate"));

    final reversed = await exchange.createTrade(
      from: "BTC",
      fromNetwork: "Bitcoin",
      to: "ETH",
      toNetwork: "Ethereum",
      fixedRate: false,
      amount: Decimal.one,
      addressTo: "destination-address",
      addressRefund: "refund-address",
      refundExtraId: "",
      reversed: true,
    );
    expect(reversed.value, isNull);
    expect(reversed.exception.toString(), contains("Reversed"));
  });

  test("rejects unsupported destination and refund memos", () async {
    for (final values in [
      (destination: "12345", refund: ""),
      (destination: null, refund: "refund memo"),
    ]) {
      final response = await exchange.createTrade(
        from: "BTC",
        fromNetwork: "Bitcoin",
        to: "ETH",
        toNetwork: "Ethereum",
        fixedRate: false,
        amount: Decimal.one,
        addressTo: "destination-address",
        extraId: values.destination,
        addressRefund: "",
        refundExtraId: values.refund,
        reversed: false,
      );
      expect(response.value, isNull);
      expect(response.exception.toString(), contains("does not support"));
    }
  });

  test("requires a refund address", () async {
    final response = await exchange.createTrade(
      from: "BTC",
      fromNetwork: "Bitcoin",
      to: "ETH",
      toNetwork: "Ethereum",
      fixedRate: false,
      amount: Decimal.one,
      addressTo: "destination-address",
      addressRefund: "",
      refundExtraId: "",
      reversed: false,
    );
    expect(response.value, isNull);
    expect(
      response.exception.toString(),
      contains("Refund address is required"),
    );
  });

  test("maps BaaS states onto the wallet's status vocabulary", () async {
    expect(await statusFor(_statusBody(state: "waiting")), "Waiting");
    expect(await statusFor(_statusBody(state: "receiving")), "Confirming");
    expect(await statusFor(_statusBody(state: "swapping")), "Exchanging");
    expect(await statusFor(_statusBody(state: "sending")), "Sending");
    expect(await statusFor(_statusBody(state: "sent")), "Sending");
    expect(await statusFor(_statusBody(state: "failed")), "Failed");

    useFake((url, headers) async {
      if (url.path == "/assets") return _json(_assetsBody());
      if (url.path == "/status-by-id") {
        return _json(_statusBody(state: "completed"));
      }
      throw StateError("unexpected ${url.path}");
    });
    final completed = await exchange.updateTrade(_oldTrade());
    expect(completed.exception, isNull);
    expect(completed.value!.status, "Completed");
    expect(completed.value!.payOutTxid, "tx-out");
    expect(completed.value!.payOutAmount, "0.353856642395626881");
    expect(completed.value!.payInAmount, "0.01");
  });

  test("reports only a full refund as refunded", () async {
    expect(
      await statusFor(
        _statusBody(state: "completed", swapped: false, refunded: true),
      ),
      "Refunded",
    );

    // A partial refund still paid out the swapped part.
    useFake((url, headers) async {
      if (url.path == "/assets") return _json(_assetsBody());
      if (url.path == "/status-by-id") {
        return _json(_statusBody(state: "completed", refunded: true));
      }
      throw StateError("unexpected ${url.path}");
    });
    final partial = await exchange.updateTrade(_oldTrade());
    expect(partial.value!.status, "Completed");
    expect(partial.value!.other, contains("tx-refund"));

    final failedRefund = _statusBody(
      state: "completed",
      swapped: false,
      refunded: true,
    );
    ((failedRefund["status"] as Map<String, dynamic>)["refundEgress"]
        as Map<String, dynamic>)["failure"] = <String, dynamic>{
      "mode": "TRANSACTION_REJECTED",
    };
    expect(await statusFor(failedRefund), "Failed");
  });

  test("keeps deposit failures in the trade details", () async {
    useFake((url, headers) async {
      if (url.path == "/assets") return _json(_assetsBody());
      if (url.path == "/status-by-id") {
        return _json(_statusBody(state: "failed", failed: true));
      }
      throw StateError("unexpected ${url.path}");
    });

    final failed = await exchange.updateTrade(_oldTrade());
    expect(failed.exception, isNull);
    expect(failed.value!.status, "Failed");
    expect(failed.value!.other, contains("depositFailure"));
  });

  test("parses exponent-notation native amounts", () async {
    useFake((url, headers) async {
      if (url.path == "/assets") return _json(_assetsBody());
      if (url.path == "/status-by-id") {
        return _json(
          _statusBody(
            state: "completed",
            egressAmountNative: "3.53856642395626881e+17",
          ),
        );
      }
      throw StateError("unexpected ${url.path}");
    });

    final updated = await exchange.updateTrade(_oldTrade());
    expect(updated.exception, isNull);
    expect(updated.value!.payOutAmount, "0.353856642395626881");
  });

  test("stores fallback egress evidence", () async {
    useFake((url, headers) async {
      if (url.path == "/assets") return _json(_assetsBody());
      if (url.path == "/status-by-id") {
        final body = _statusBody(state: "completed");
        final status = body["status"] as Map<String, dynamic>;
        status["fallbackEgress"] = <String, dynamic>{
          "amountNative": "1000000",
          "transactionReference": "tx-fallback",
        };
        return _json(body);
      }
      throw StateError("unexpected ${url.path}");
    });

    final updated = await exchange.updateTrade(_oldTrade());
    expect(updated.exception, isNull);
    expect(updated.value!.status, "Completed");
    expect(updated.value!.other, contains("fallbackEgress"));
    expect(updated.value!.other, contains("tx-fallback"));
  });

  test("keeps polling when a status is pending", () async {
    useFake((url, headers) async {
      if (url.path == "/assets") return _json(_assetsBody());
      if (url.path == "/status-by-id") {
        return _json(<String, dynamic>{
          "status": 404,
          "code": "swap_pending",
        }, code: 404);
      }
      throw StateError("unexpected ${url.path}");
    });

    final oldTrade = _oldTrade();
    final updated = await exchange.updateTrade(oldTrade);
    expect(updated.exception, isNull);
    expect(updated.value!.status, "Waiting");
    expect(updated.value!.updatedAt.isAfter(oldTrade.updatedAt), isTrue);

    final fetched = await exchange.getTrade("42");
    expect(fetched.exception, isNull);
    expect(fetched.value!.tradeId, "42");
    expect(fetched.value!.status, "Waiting");
  });

  test("returns order-not-found for an unknown swap", () async {
    useFake((url, headers) async {
      if (url.path == "/assets") return _json(_assetsBody());
      if (url.path == "/status-by-id") {
        return _json(<String, dynamic>{
          "status": 404,
          "code": "swap_unknown",
        }, code: 404);
      }
      throw StateError("unexpected ${url.path}");
    });

    final response = await exchange.getTrade("42");
    expect(response.value, isNull);
    expect(response.exception.toString(), contains("Swap not found"));
  });

  test("declines listing partner-wide trades", () async {
    useFake((url, headers) async => throw StateError("unexpected ${url.path}"));

    final response = await exchange.getTrades();
    expect(response.value, isNull);
    expect(response.exception.toString(), contains("listing trades"));
    expect(paths, isEmpty);
  });

  test("maps auth and temporary failures", () async {
    useFake((url, headers) async {
      return _json(<String, dynamic>{"detail": "Invalid partner."}, code: 401);
    });

    final unauthorized = await exchange.getEstimates(
      "BTC",
      "Bitcoin",
      "ETH",
      "Ethereum",
      Decimal.one,
      false,
      false,
    );
    expect(unauthorized.value, isNull);
    expect(
      unauthorized.exception.toString(),
      contains("Invalid Chainflip API key"),
    );

    useFake((url, headers) async {
      return _json(<String, dynamic>{"detail": "down"}, code: 503);
    });

    final unavailable = await exchange.getEstimates(
      "BTC",
      "Bitcoin",
      "ETH",
      "Ethereum",
      Decimal.one,
      false,
      false,
    );
    expect(unavailable.value, isNull);
    expect(
      unavailable.exception.toString(),
      contains("temporarily unavailable"),
    );

    final cases = <(int, Map<String, dynamic>, String)>[
      (
        400,
        <String, dynamic>{
          "detail": "One or more validation errors occurred.",
          "errors": <String, dynamic>{
            "amount": <String>["Amount too large."],
          },
        },
        "Amount too large.",
      ),
      (
        400,
        <String, dynamic>{
          "detail": "Not enough liquidity.",
          "code": "insufficient_liquidity",
        },
        "Not enough liquidity. (insufficient_liquidity)",
      ),
      (403, <String, dynamic>{"detail": "denied"}, "not enabled"),
      (500, <String, dynamic>{"detail": "boom"}, "error 500: boom"),
    ];
    for (final (code, body, message) in cases) {
      useFake((url, headers) async {
        if (url.path == "/assets") return _json(_assetsBody());
        return _json(body, code: code);
      });
      final response = await exchange.getEstimates(
        "BTC",
        "Bitcoin",
        "ETH",
        "Ethereum",
        Decimal.one,
        false,
        false,
      );
      expect(response.value, isNull, reason: "$code");
      expect(response.exception.toString(), contains(message), reason: "$code");
    }
  });

  test("declines keyed calls when the build key is empty", () async {
    ChainflipApi.apiKeyOverride = "";
    var calls = 0;
    useFake((url, headers) async {
      calls++;
      if (url.path == "/assets") return _json(_assetsBody());
      throw StateError("unexpected ${url.path}");
    });

    final assets = await exchange.getAllCurrencies(false);
    expect(assets.value, isNotNull);
    expect(calls, 1);

    final estimates = await exchange.getEstimates(
      "BTC",
      "Bitcoin",
      "ETH",
      "Ethereum",
      Decimal.one,
      false,
      false,
    );
    expect(estimates.value, isNull);
    expect(estimates.exception.toString(), contains("not configured"));
    expect(calls, 1);

    final trade = await exchange.createTrade(
      from: "BTC",
      fromNetwork: "Bitcoin",
      to: "ETH",
      toNetwork: "Ethereum",
      fixedRate: false,
      amount: Decimal.one,
      addressTo: "destination-address",
      addressRefund: "refund-address",
      refundExtraId: "",
      reversed: false,
    );
    expect(trade.value, isNull);
    expect(trade.exception.toString(), contains("not configured"));
    expect(calls, 1);
  });

  test("groups Chainflip currencies by short asset-id suffix", () {
    final currency = Currency(
      exchangeName: ChainflipExchange.exchangeName,
      ticker: "BTC",
      name: "Bitcoin",
      network: "Bitcoin",
      image: "",
      externalId: "btc.btc",
      isFiat: false,
      rateType: SupportedRateType.estimated,
      isStackCoin: true,
      tokenContract: null,
    );

    expect(currency.getFuzzyNet(), "btc");

    Currency baas(String id, String ticker, String network) => Currency(
      exchangeName: ChainflipExchange.exchangeName,
      ticker: ticker,
      name: ticker,
      network: network,
      image: "",
      externalId: id,
      isFiat: false,
      rateType: SupportedRateType.estimated,
      isStackCoin: false,
      tokenContract: null,
    );
    expect(baas("usdt.eth", "USDT", "Ethereum").getFuzzyNet(), "eth");
    expect(baas("usdc.sol", "USDC", "Solana").getFuzzyNet(), "sol");
  });

  test(
    "tracks a channel-id trade through the deposit-channel status",
    () async {
      useFake((url, headers) async {
        if (url.path == "/assets") return _json(_assetsBody());
        if (url.path == "/status-by-deposit-channel") {
          return _json(_statusBody(state: "swapping"));
        }
        throw StateError("unexpected ${url.path}");
      });

      final response = await exchange.getTrade("channel:1519086-Bitcoin-125");
      expect(response.exception, isNull);
      expect(response.value!.tradeId, "channel:1519086-Bitcoin-125");
      expect(response.value!.status, "Exchanging");
      expect(lastUri.queryParameters, <String, String>{
        "issuedBlock": "1519086",
        "network": "Bitcoin",
        "channelId": "125",
      });
    },
  );

  test("keeps polling on stale assets when the refresh fails", () async {
    var assetCalls = 0;
    useFake((url, headers) async {
      if (url.path == "/assets") {
        assetCalls++;
        return assetCalls == 1
            ? _json(_assetsBody())
            : _json(<String, dynamic>{"detail": "down"}, code: 503);
      }
      if (url.path == "/status-by-id") {
        return _json(_statusBody(state: "completed"));
      }
      throw StateError("unexpected ${url.path}");
    });

    expect((await exchange.getAllCurrencies(false)).exception, isNull);
    exchange.expireAssetCache();

    final updated = await exchange.updateTrade(_oldTrade());
    expect(updated.exception, isNull);
    expect(updated.value!.status, "Completed");
  });
}

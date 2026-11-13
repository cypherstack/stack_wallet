/*
 * This file is part of Stack Wallet.
 *
 * Copyright (c) 2026 Cypher Stack
 * All Rights Reserved.
 * The code is distributed under GPLv3 license, see LICENSE file for details.
 *
 */

import 'dart:convert';

import 'package:decimal/decimal.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../../exceptions/exchange/exchange_exception.dart';
import '../../../models/exchange/response_objects/estimate.dart';
import '../../../models/exchange/response_objects/range.dart';
import '../../../models/exchange/response_objects/trade.dart';
import '../../../models/isar/exchange_cache/currency.dart';
import '../../../models/isar/exchange_cache/pair.dart';
import '../../../utilities/default_eth_tokens.dart';
import '../../../utilities/default_sol_tokens.dart';
import '../exchange.dart';
import '../exchange_response.dart';
import 'api_response_models/chainflip_asset.dart';
import 'api_response_models/chainflip_swap_status.dart';
import 'chainflip_api.dart';

class ChainflipExchange extends Exchange {
  ChainflipExchange._();

  static final ChainflipExchange _instance = ChainflipExchange._();

  static ChainflipExchange get instance => _instance;

  @visibleForTesting
  factory ChainflipExchange.forTesting() => ChainflipExchange._();

  static const exchangeName = "Chainflip";

  /// The BaaS quote controller rejects amounts above
  /// `AssetInfoExtensions.MaxQuoteAmountNative`, which is
  /// `new BigInteger(decimal.MaxValue)` (`src/baas-api/Assets/AssetInfo.cs:220`).
  /// Liquidity limits are enforced by `/quotes-native` before confirmation;
  /// this is the API's hard upper bound, not a liquidity estimate.
  static const _maxQuoteAmountNative = "79228162514264337593543950335";

  /// Minimums, enabled flags and the asset list change server-side; the
  /// cache only spares a `/assets` round trip per quote.
  static const _assetsMaxAge = Duration(minutes: 10);

  final Map<String, ChainflipAsset> _byKey = <String, ChainflipAsset>{};
  List<ChainflipAsset> _assets = <ChainflipAsset>[];
  DateTime? _assetsLoadedAt;

  @visibleForTesting
  void expireAssetCache() => _assetsLoadedAt = null;

  @override
  String get name => exchangeName;

  @override
  bool get supportsRefundAddress => true;

  @override
  bool get supportsExtraId => false;

  @override
  Future<ExchangeResponse<List<Currency>>> getAllCurrencies(
    bool fixedRate,
  ) async {
    if (fixedRate) {
      return ExchangeResponse(exception: _unsupported("Fixed-rate swaps"));
    }

    final assetsResponse = await _loadAssets(force: true);
    if (assetsResponse.exception != null) {
      return ExchangeResponse(exception: assetsResponse.exception);
    }

    final currencies = assetsResponse.value!
        .map(
          (asset) => Currency(
            exchangeName: exchangeName,
            ticker: asset.ticker,
            name: asset.name,
            network: asset.network,
            image: ChainflipApi.assetLogoUrl(asset.assetLogo),
            externalId: asset.id,
            isFiat: false,
            rateType: SupportedRateType.estimated,
            isAvailable: asset.enabled,
            isStackCoin: true,
            tokenContract: asset.contractAddress,
          ),
        )
        .toList();

    return ExchangeResponse(value: currencies);
  }

  @override
  Future<ExchangeResponse<Range>> getRange(
    String from,
    String? fromNetwork,
    String to,
    String? toNetwork,
    bool fixedRate,
  ) async {
    if (fixedRate) {
      return ExchangeResponse(exception: _unsupported("Fixed-rate swaps"));
    }

    try {
      final asset = await _resolveAsset(from, fromNetwork);
      final min = _humanFromNative(asset.minimalAmountNative, asset.decimals);
      final max = _humanFromNative(_maxQuoteAmountNative, asset.decimals);
      return ExchangeResponse(
        value: Range(min: min, max: max),
      );
    } on ExchangeException catch (e) {
      return ExchangeResponse(exception: e);
    } catch (e) {
      return ExchangeResponse(exception: _generic(e));
    }
  }

  @override
  Future<ExchangeResponse<List<Estimate>>> getEstimates(
    String from,
    String? fromNetwork,
    String to,
    String? toNetwork,
    Decimal amount,
    bool fixedRate,
    bool reversed,
  ) async {
    if (fixedRate) {
      return ExchangeResponse(exception: _unsupported("Fixed-rate swaps"));
    }
    if (reversed) {
      return ExchangeResponse(exception: _unsupported("Reversed quotes"));
    }

    try {
      final fromAsset = await _resolveAsset(from, fromNetwork);
      final toAsset = await _resolveAsset(to, toNetwork);
      final amountNative = _nativeFromHuman(
        amount,
        fromAsset.decimals,
        fromAsset.ticker,
      );

      final response = await ChainflipApi.instance.getQuotes(
        sourceAsset: fromAsset.id,
        destinationAsset: toAsset.id,
        amountNative: amountNative,
      );
      if (response.exception != null) {
        return ExchangeResponse(exception: response.exception);
      }

      final regular = response.value!
          .where((quote) => quote.type == "regular")
          .toList();
      if (regular.isEmpty) {
        return ExchangeResponse(
          exception: ExchangeException(
            "No regular quote available for this pair and amount",
            ExchangeExceptionType.generic,
          ),
        );
      }

      final quote = regular.first;
      final ingress = _humanFromNative(
        quote.ingressAmountNative,
        fromAsset.decimals,
      );
      final estimatedAmount = _humanFromNative(
        quote.egressAmountNative,
        toAsset.decimals,
      );
      final estimatedPrice = quote.estimatedPrice == null
          ? null
          : Decimal.tryParse(quote.estimatedPrice.toString());
      if (ingress <= Decimal.zero ||
          estimatedAmount <= Decimal.zero ||
          estimatedPrice == null ||
          estimatedPrice <= Decimal.zero) {
        return ExchangeResponse(
          exception: ExchangeException(
            "Chainflip returned an incomplete quote",
            ExchangeExceptionType.generic,
          ),
        );
      }

      final rateId = jsonEncode(<String, dynamic>{
        "sourceAsset": fromAsset.id,
        "destinationAsset": toAsset.id,
        "amountNative": amountNative,
        "ingressAmountNative": quote.ingressAmountNative,
        "egressAmountNative": quote.egressAmountNative,
        "estimatedPrice": estimatedPrice.toString(),
        "recommendedSlippageTolerancePercent":
            quote.recommendedSlippageTolerancePercent,
        "recommendedRetryDurationInBlocks":
            quote.recommendedRetryDurationInBlocks,
        "recommendedLivePriceSlippageTolerancePercent":
            quote.recommendedLivePriceSlippageTolerancePercent,
      });

      return ExchangeResponse(
        value: <Estimate>[
          Estimate(
            estimatedAmount: estimatedAmount,
            fixedRate: false,
            reversed: false,
            warningMessage: quote.lowLiquidityWarning
                ? "Low liquidity warning for this amount"
                : null,
            rateId: rateId,
            exchangeProvider: exchangeName,
          ),
        ],
      );
    } on ExchangeException catch (e) {
      return ExchangeResponse(exception: e);
    } catch (e) {
      return ExchangeResponse(exception: _generic(e));
    }
  }

  @override
  Future<ExchangeResponse<Trade>> createTrade({
    required String from,
    required String to,
    required String? fromNetwork,
    required String? toNetwork,
    required bool fixedRate,
    required Decimal amount,
    required String addressTo,
    String? extraId,
    required String addressRefund,
    required String refundExtraId,
    Estimate? estimate,
    required bool reversed,
  }) async {
    if (fixedRate) {
      return ExchangeResponse(exception: _unsupported("Fixed-rate swaps"));
    }
    if (reversed) {
      return ExchangeResponse(exception: _unsupported("Reversed quotes"));
    }
    if ((extraId != null && extraId.isNotEmpty) || refundExtraId.isNotEmpty) {
      return ExchangeResponse(
        exception: ExchangeException(
          "Chainflip does not support destination or refund memos",
          ExchangeExceptionType.generic,
        ),
      );
    }
    if (addressTo.isEmpty) {
      return ExchangeResponse(
        exception: ExchangeException(
          "Destination address is required",
          ExchangeExceptionType.generic,
        ),
      );
    }
    if (addressRefund.isEmpty) {
      return ExchangeResponse(
        exception: ExchangeException(
          "Refund address is required",
          ExchangeExceptionType.generic,
        ),
      );
    }

    try {
      final fromAsset = await _resolveAsset(from, fromNetwork);
      final toAsset = await _resolveAsset(to, toNetwork);
      final amountNative = _nativeFromHuman(
        amount,
        fromAsset.decimals,
        fromAsset.ticker,
      );
      final quoteDetails = await _quoteDetailsFor(
        estimate,
        fromAsset,
        toAsset,
        amountNative,
        amount,
      );

      final ingressNative =
          quoteDetails["ingressAmountNative"] as String? ?? "";
      final egressNative = quoteDetails["egressAmountNative"] as String? ?? "";
      final ingress = _humanFromNative(ingressNative, fromAsset.decimals);
      final egress = _humanFromNative(egressNative, toAsset.decimals);
      final estimatedPrice = Decimal.tryParse(
        quoteDetails["estimatedPrice"] as String? ?? "",
      );
      if (ingress <= Decimal.zero ||
          egress <= Decimal.zero ||
          estimatedPrice == null ||
          estimatedPrice <= Decimal.zero) {
        throw ExchangeException(
          "Chainflip returned an incomplete quote",
          ExchangeExceptionType.generic,
        );
      }

      // BaaS documents the floor as `estimatedPrice * (1 - slippage / 100)`,
      // using the quote's own price rather than egress/ingress (which is net
      // of fees). Rounded down so the floor never exceeds that bound.
      final slippage = _decimalFromValue(
        quoteDetails["recommendedSlippageTolerancePercent"],
        fallback: Decimal.parse("2.5"),
      );
      final slippageFactor =
          Decimal.one -
          (slippage / Decimal.fromInt(100)).toDecimal(
            scaleOnInfinitePrecision: 8,
          );
      final minimumPrice = (estimatedPrice * slippageFactor).floor(scale: 18);
      if (minimumPrice <= Decimal.zero) {
        throw ExchangeException(
          "Chainflip returned an incomplete quote",
          ExchangeExceptionType.generic,
        );
      }

      final retryDuration =
          quoteDetails["recommendedRetryDurationInBlocks"] as int? ?? 150;
      final livePrice =
          quoteDetails["recommendedLivePriceSlippageTolerancePercent"];

      final depositResponse = await ChainflipApi.instance.createSwap(
        sourceAsset: fromAsset.id,
        destinationAsset: toAsset.id,
        destinationAddress: addressTo,
        refundAddress: addressRefund,
        minimumPrice: minimumPrice.toString(),
        retryDurationInBlocks: retryDuration,
        livePriceSlippageTolerancePercent: livePrice?.toString(),
      );
      if (depositResponse.exception != null) {
        return ExchangeResponse(exception: depositResponse.exception);
      }

      final deposit = depositResponse.value!;
      final tradeId =
          deposit.id?.toString() ??
          "channel:${deposit.issuedBlock}-${deposit.network}-"
              "${deposit.channelId}";
      final now = DateTime.now();

      final trade = Trade(
        uuid: const Uuid().v1(),
        tradeId: tradeId,
        rateType: "estimated",
        direction: "direct",
        timestamp: now,
        updatedAt: now,
        payInCurrency: fromAsset.ticker,
        payInAmount: ingress.toString(),
        payInAddress: deposit.address,
        payInNetwork: deposit.network,
        payInExtraId: "",
        payInTxid: "",
        payOutCurrency: toAsset.ticker,
        payOutAmount: egress.toString(),
        payOutAddress: deposit.destinationAddress,
        payOutNetwork: toAsset.network,
        payOutExtraId: "",
        payOutTxid: "",
        refundAddress: addressRefund,
        refundExtraId: "",
        status: "Waiting",
        exchangeName: exchangeName,
        other: jsonEncode(<String, dynamic>{
          "swapId": deposit.id,
          "issuedBlock": deposit.issuedBlock,
          "network": deposit.network,
          "channelId": deposit.channelId,
          "sourceExpiryBlock": deposit.sourceExpiryBlock,
          "explorerUrl": deposit.explorerUrl,
          "channelOpeningFeeNative": deposit.channelOpeningFeeNative,
          "destinationAddress": deposit.destinationAddress,
          "quote": quoteDetails,
        }),
      );

      return ExchangeResponse(value: trade);
    } on ExchangeException catch (e) {
      return ExchangeResponse(exception: e);
    } catch (e) {
      return ExchangeResponse(exception: _generic(e));
    }
  }

  @override
  Future<ExchangeResponse<Trade>> getTrade(String tradeId) async {
    final assetsResponse = await _loadAssets();
    if (assetsResponse.exception != null) {
      return ExchangeResponse(exception: assetsResponse.exception);
    }

    final statusResponse = await _statusForTradeId(tradeId);
    if (statusResponse.exception != null) {
      return ExchangeResponse(exception: statusResponse.exception);
    }

    final status = statusResponse.value!;
    if (status.pending) {
      return ExchangeResponse(value: _emptyTrade(tradeId));
    }

    return ExchangeResponse(value: _tradeFromStatus(status, tradeId: tradeId));
  }

  @override
  Future<ExchangeResponse<Trade>> updateTrade(Trade trade) async {
    final assetsResponse = await _loadAssets();
    if (assetsResponse.exception != null) {
      return ExchangeResponse(exception: assetsResponse.exception);
    }

    final statusResponse = await _statusForTradeId(trade.tradeId);
    if (statusResponse.exception != null) {
      return ExchangeResponse(exception: statusResponse.exception);
    }

    final status = statusResponse.value!;
    if (status.pending) {
      return ExchangeResponse(value: trade.copyWith(updatedAt: DateTime.now()));
    }

    return ExchangeResponse(value: _tradeFromStatus(status, oldTrade: trade));
  }

  @override
  Future<ExchangeResponse<List<Trade>>> getTrades() async {
    // BaaS `/swaps` lists every swap made under the partner key, i.e. every
    // user of this build, not this wallet's trades. The wallet tracks its own
    // trades through getTrade/updateTrade.
    return ExchangeResponse(exception: _unsupported("listing trades"));
  }

  Future<ExchangeResponse<List<ChainflipAsset>>> _loadAssets({
    bool force = false,
  }) async {
    final loadedAt = _assetsLoadedAt;
    if (!force &&
        _assets.isNotEmpty &&
        loadedAt != null &&
        DateTime.now().difference(loadedAt) < _assetsMaxAge) {
      return ExchangeResponse(value: _assets);
    }

    final response = await ChainflipApi.instance.getAllAssets();
    if (response.value != null) {
      // Only offer assets Stack Wallet itself holds. "Send from" matches
      // wallets by ticker, so e.g. ETH on Arbitrum would be paid from the
      // mainnet ETH wallet.
      _assets = response.value!.where(_isStackCoin).toList();
      _assetsLoadedAt = DateTime.now();
      _byKey
        ..clear()
        ..addEntries(
          _assets.map(
            (asset) => MapEntry(_key(asset.ticker, asset.network), asset),
          ),
        );
      return ExchangeResponse(value: _assets);
    }

    // A failed refresh must not stop status polling for in-flight trades:
    // fall back to the stale list unless the caller asked for fresh data.
    if (!force && _assets.isNotEmpty) {
      return ExchangeResponse(value: _assets);
    }

    if (response.exception == null) {
      return ExchangeResponse(exception: _generic("No assets returned"));
    }

    return response;
  }

  Future<ChainflipAsset> _resolveAsset(String ticker, String? network) async {
    final response = await _loadAssets();
    if (response.exception != null) {
      throw response.exception!;
    }
    if (response.value == null) {
      throw _generic("No assets returned");
    }

    final exact = _byKey[_key(ticker, network)];
    if (exact != null) return exact;
    if (network != null && network.isNotEmpty) {
      throw ExchangeException(
        "Chainflip does not support $ticker on $network",
        ExchangeExceptionType.generic,
      );
    }

    final candidates = _assets
        .where((asset) => asset.ticker.toUpperCase() == ticker.toUpperCase())
        .toList();

    if (candidates.length == 1) return candidates.first;
    if (candidates.isEmpty) {
      throw ExchangeException(
        "Unknown asset $ticker",
        ExchangeExceptionType.generic,
      );
    }
    throw ExchangeException(
      "Network is required for $ticker",
      ExchangeExceptionType.generic,
    );
  }

  /// The quote behind [estimate] when it was issued by this provider for
  /// exactly this pair and source amount; otherwise a fresh quote.
  Future<Map<String, dynamic>> _quoteDetailsFor(
    Estimate? estimate,
    ChainflipAsset fromAsset,
    ChainflipAsset toAsset,
    String amountNative,
    Decimal amount,
  ) async {
    final rateId = estimate?.rateId;
    if (estimate?.exchangeProvider == exchangeName &&
        rateId != null &&
        rateId.isNotEmpty) {
      try {
        final decoded = jsonDecode(rateId);
        if (decoded is Map<dynamic, dynamic> &&
            decoded["sourceAsset"] == fromAsset.id &&
            decoded["destinationAsset"] == toAsset.id &&
            decoded["amountNative"] == amountNative) {
          return Map<String, dynamic>.from(decoded);
        }
      } catch (_) {
        // Fall through to a fresh quote.
      }
    }

    final response = await getEstimates(
      fromAsset.ticker,
      fromAsset.network,
      toAsset.ticker,
      toAsset.network,
      amount,
      false,
      false,
    );
    if (response.exception != null) {
      throw response.exception!;
    }

    final freshRateId = response.value!.first.rateId;
    if (freshRateId == null || freshRateId.isEmpty) {
      throw ExchangeException(
        "No quote available to start the swap",
        ExchangeExceptionType.generic,
      );
    }

    final decoded = jsonDecode(freshRateId);
    return Map<String, dynamic>.from(decoded as Map<dynamic, dynamic>);
  }

  Future<ExchangeResponse<ChainflipSwapStatus>> _statusForTradeId(
    String tradeId,
  ) async {
    if (tradeId.startsWith("channel:")) {
      final parts = tradeId.split("-");
      if (parts.length < 3) {
        return ExchangeResponse(
          exception: ExchangeException(
            "Invalid trade id",
            ExchangeExceptionType.generic,
          ),
        );
      }
      final issuedBlock = int.tryParse(parts[0].substring("channel:".length));
      final channelId = int.tryParse(parts[2]);
      if (issuedBlock == null || channelId == null) {
        return ExchangeResponse(
          exception: ExchangeException(
            "Invalid trade id",
            ExchangeExceptionType.generic,
          ),
        );
      }
      return ChainflipApi.instance.getStatusByDepositChannel(
        issuedBlock: issuedBlock,
        network: parts[1],
        channelId: channelId,
      );
    }

    return ChainflipApi.instance.getStatusById(tradeId);
  }

  Trade _tradeFromStatus(
    ChainflipSwapStatus status, {
    Trade? oldTrade,
    String? tradeId,
  }) {
    final now = DateTime.now();
    final sourceAsset = _assetById(status.sourceAsset);
    final destinationAsset = _assetById(status.destinationAsset);

    final payInCurrency = _firstNonEmpty(
      sourceAsset?.ticker,
      _tickerFromId(status.sourceAsset),
    );
    final payOutCurrency = _firstNonEmpty(
      destinationAsset?.ticker,
      _tickerFromId(status.destinationAsset),
    );
    final payInNetwork = _firstNonEmpty(
      sourceAsset?.network,
      _networkFromId(status.sourceAsset),
    );
    final payOutNetwork = _firstNonEmpty(
      destinationAsset?.network,
      _networkFromId(status.destinationAsset),
    );

    final payInAmount = _humanStringFromNative(
      status.deposit?.amountNative ?? status.swap?.originalInputAmountNative,
      sourceAsset?.decimals,
      oldTrade?.payInAmount,
    );
    final payOutAmount = _humanStringFromNative(
      status.swapEgress?.amountNative ?? status.swap?.swappedOutputAmountNative,
      destinationAsset?.decimals,
      oldTrade?.payOutAmount,
    );

    final depositChannel = status.depositChannel;
    final explorerUrl = depositChannel?.id != null
        ? "https://scan.chainflip.io/channels/${depositChannel!.id}"
        : _parseOther(oldTrade?.other)["explorerUrl"] as String?;

    final other = <String, dynamic>{
      ..._parseOther(oldTrade?.other),
      "swapId": status.id ?? tradeId ?? oldTrade?.tradeId,
      "state": status.state,
      if (status.deposit?.failure != null)
        "depositFailure": status.deposit!.failure,
      if (status.swapEgress?.failure != null)
        "egressFailure": status.swapEgress!.failure,
      if (status.refundEgress != null)
        "refundEgress": <String, dynamic>{
          "amountNative": status.refundEgress!.amountNative,
          "transactionReference": status.refundEgress!.transactionReference,
        },
      if (status.fallbackEgress != null)
        "fallbackEgress": <String, dynamic>{
          "amountNative": status.fallbackEgress!.amountNative,
          "transactionReference": status.fallbackEgress!.transactionReference,
        },
      if (explorerUrl != null) "explorerUrl": explorerUrl,
    };

    final createdAt = depositChannel?.createdAt;

    return Trade(
      uuid: oldTrade?.uuid ?? const Uuid().v1(),
      tradeId: tradeId ?? oldTrade?.tradeId ?? "",
      rateType: oldTrade?.rateType ?? "estimated",
      direction: oldTrade?.direction ?? "direct",
      timestamp:
          oldTrade?.timestamp ??
          (createdAt != null
              ? DateTime.fromMillisecondsSinceEpoch(createdAt)
              : now),
      updatedAt: now,
      payInCurrency: _firstNonEmpty(payInCurrency, oldTrade?.payInCurrency),
      payInAmount: payInAmount.isEmpty
          ? (oldTrade?.payInAmount ?? "")
          : payInAmount,
      payInAddress: _firstNonEmpty(
        depositChannel?.depositAddress,
        oldTrade?.payInAddress,
      ),
      payInNetwork: _firstNonEmpty(payInNetwork, oldTrade?.payInNetwork),
      payInExtraId: oldTrade?.payInExtraId ?? "",
      payInTxid: _firstNonEmpty(
        status.deposit?.transactionReference,
        oldTrade?.payInTxid,
      ),
      payOutCurrency: _firstNonEmpty(payOutCurrency, oldTrade?.payOutCurrency),
      payOutAmount: payOutAmount.isEmpty
          ? (oldTrade?.payOutAmount ?? "")
          : payOutAmount,
      payOutAddress: _firstNonEmpty(
        status.destinationAddress,
        oldTrade?.payOutAddress,
      ),
      payOutNetwork: _firstNonEmpty(payOutNetwork, oldTrade?.payOutNetwork),
      payOutExtraId: oldTrade?.payOutExtraId ?? "",
      payOutTxid: _firstNonEmpty(
        status.swapEgress?.transactionReference,
        oldTrade?.payOutTxid,
      ),
      refundAddress: _firstNonEmpty(
        status.fillOrKillParams?.refundAddress,
        oldTrade?.refundAddress,
      ),
      refundExtraId: oldTrade?.refundExtraId ?? "",
      status: _mapState(status),
      exchangeName: exchangeName,
      other: jsonEncode(other),
    );
  }

  Trade _emptyTrade(String tradeId) {
    final now = DateTime.now();
    return Trade(
      uuid: const Uuid().v1(),
      tradeId: tradeId,
      rateType: "estimated",
      direction: "direct",
      timestamp: now,
      updatedAt: now,
      payInCurrency: "",
      payInAmount: "",
      payInAddress: "",
      payInNetwork: "",
      payInExtraId: "",
      payInTxid: "",
      payOutCurrency: "",
      payOutAmount: "",
      payOutAddress: "",
      payOutNetwork: "",
      payOutExtraId: "",
      payOutTxid: "",
      refundAddress: "",
      refundExtraId: "",
      status: "Waiting",
      exchangeName: exchangeName,
      other: jsonEncode(<String, dynamic>{"swapId": tradeId}),
    );
  }

  ChainflipAsset? _assetById(String id) {
    if (id.isEmpty) return null;
    for (final asset in _assets) {
      if (asset.id == id) return asset;
    }
    return null;
  }

  static String _key(String ticker, String? network) =>
      "${ticker.toUpperCase()}|${network ?? ''}";

  /// Maps BaaS states onto the status vocabulary the trade card, trade
  /// details, status colours and notifications already understand. The raw
  /// BaaS state stays in `Trade.other["state"]`.
  static String _mapState(ChainflipSwapStatus status) {
    if (status.pending) return "Waiting";
    switch (status.state) {
      case "completed":
        // BaaS ends full and partial refunds as `completed` with a
        // `refundEgress`; only a refund with no swap output is "Refunded".
        final refund = status.refundEgress;
        if (refund != null && status.swapEgress == null) {
          return refund.failure == null ? "Refunded" : "Failed";
        }
        return "Completed";
      case "failed":
        return "Failed";
      case "receiving":
        return "Confirming";
      case "swapping":
        return "Exchanging";
      case "sending":
      case "sent":
        return "Sending";
      default:
        return "Waiting";
    }
  }

  static bool _isStackCoin(ChainflipAsset asset) {
    switch (asset.id) {
      case "btc.btc":
      case "eth.eth":
      case "sol.sol":
        return true;
    }

    final contract = asset.contractAddress;
    if (contract == null || contract.isEmpty) return false;

    if (asset.network == "Ethereum") {
      final lower = contract.toLowerCase();
      return lower == DefaultTokens.usdc.address.toLowerCase() ||
          lower == DefaultTokens.usdt.address.toLowerCase();
    }

    if (asset.network == "Solana") {
      for (final token in DefaultSolTokens.list) {
        if (token.address == contract) return true;
      }
    }

    return false;
  }

  static final _digits = RegExp(r"^\d+$");

  static Decimal _humanFromNative(String native, int decimals) {
    if (native.isEmpty) return Decimal.zero;
    // Chainflip can render large native amounts in exponent notation
    // (`1e+21`), which status responses pass through verbatim.
    final integer = _digits.hasMatch(native)
        ? native
        : Decimal.parse(native).toBigInt().toString();
    if (decimals == 0) return Decimal.parse(integer);

    final padded = integer.padLeft(decimals + 1, "0");
    final whole = padded.substring(0, padded.length - decimals);
    final fraction = padded.substring(padded.length - decimals);
    return Decimal.parse("$whole.$fraction");
  }

  static String _nativeFromHuman(Decimal amount, int decimals, String ticker) {
    final parts = amount.toString().split(".");
    final whole = parts[0];
    var fraction = parts.length > 1 ? parts[1] : "";
    if (fraction.length > decimals) {
      throw ExchangeException(
        "$ticker supports at most $decimals decimal places",
        ExchangeExceptionType.generic,
      );
    }
    fraction = fraction.padRight(decimals, "0");
    return BigInt.parse("$whole$fraction").toString();
  }

  static String _humanStringFromNative(
    String? native,
    int? decimals,
    String? fallback,
  ) {
    if (native == null || native.isEmpty || decimals == null) {
      return fallback ?? "";
    }
    return _humanFromNative(native, decimals).toString();
  }

  static String _firstNonEmpty(String? first, String? second) {
    if (first != null && first.isNotEmpty) return first;
    if (second != null && second.isNotEmpty) return second;
    return "";
  }

  static String? _tickerFromId(String id) {
    if (id.isEmpty) return null;
    final ticker = id.split(".").first;
    if (ticker.isEmpty) return null;
    return ticker.toUpperCase();
  }

  static String? _networkFromId(String id) {
    final parts = id.split(".");
    if (parts.length != 2) return null;
    return const <String, String>{
      "btc": "Bitcoin",
      "eth": "Ethereum",
      "arb": "Arbitrum",
      "sol": "Solana",
      "hub": "Assethub",
      "tron": "Tron",
      "bsc": "Bsc",
    }[parts[1]];
  }

  static Map<String, dynamic> _parseOther(String? other) {
    if (other == null || other.isEmpty) {
      return <String, dynamic>{};
    }
    try {
      final decoded = jsonDecode(other);
      if (decoded is Map<dynamic, dynamic>) {
        return Map<String, dynamic>.from(decoded);
      }
    } catch (_) {
      // The field was written by an older trade shape; ignore it.
    }
    return <String, dynamic>{};
  }

  static String explorerUrlFromOther(String? other) {
    final url = _parseOther(other)["explorerUrl"];
    if (url is String && url.isNotEmpty) return url;
    return "https://scan.chainflip.io";
  }

  static Decimal _decimalFromValue(Object? value, {required Decimal fallback}) {
    if (value is num) return Decimal.parse(value.toString());
    return fallback;
  }

  static ExchangeException _unsupported(String feature) {
    return ExchangeException(
      "Chainflip does not support $feature",
      ExchangeExceptionType.generic,
    );
  }

  static ExchangeException _generic(Object error) {
    return ExchangeException(error.toString(), ExchangeExceptionType.generic);
  }
}

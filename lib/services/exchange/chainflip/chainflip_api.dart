/*
 * This file is part of Stack Wallet.
 *
 * Copyright (c) 2026 Cypher Stack
 * All Rights Reserved.
 * The code is distributed under GPLv3 license, see LICENSE file for details.
 *
 */

import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../../app_config.dart';
import '../../../exceptions/exchange/exchange_exception.dart';
import '../../../external_api_keys.dart';
import '../../../networking/http.dart';
import '../../../utilities/logger.dart';
import '../../../utilities/prefs.dart';
import '../../tor_service.dart';
import '../exchange_response.dart';
import 'api_response_models/chainflip_asset.dart';
import 'api_response_models/chainflip_deposit_address.dart';
import 'api_response_models/chainflip_quote.dart';
import 'api_response_models/chainflip_swap_status.dart';

class ChainflipApi {
  ChainflipApi._();

  static final ChainflipApi _instance = ChainflipApi._();
  static ChainflipApi get instance => _instance;

  static const String authority = "chainflip-broker.io";
  static const String onionAuthority =
      "chainflip37gkyf3nkgufkolp2grpbchoysvro57wz3d3kurhhyj4zad.onion";

  static HTTP _client = const HTTP();

  /// Test seam: replaces the generated `kChainflipApiKey` when non-null,
  /// so tests neither depend on nor write the gitignored key file.
  @visibleForTesting
  static String? apiKeyOverride;

  /// Test seam: forces the Tor gate instead of reading app config and prefs.
  @visibleForTesting
  static bool? useTorOverride;

  /// Test seam: the SOCKS proxy used in Tor mode.
  @visibleForTesting
  static ({InternetAddress host, int port}) Function() torProxyInfo = () =>
      TorService.sharedInstance.getProxyInfo();

  @visibleForTesting
  static set client(HTTP value) => _client = value;

  static String get _apiKey => apiKeyOverride ?? kChainflipApiKey;

  static bool get _useTor =>
      useTorOverride ??
      (AppConfig.hasFeature(AppFeature.tor) && Prefs.instance.useTor);

  static Uri _buildUri(String path, Map<String, String>? params) {
    return _useTor
        ? Uri.http(onionAuthority, path, params)
        : Uri.https(authority, path, params);
  }

  static ({InternetAddress host, int port})? _proxyInfo() {
    return _useTor ? torProxyInfo() : null;
  }

  static Map<String, String> _headers({required bool keyed}) {
    final headers = <String, String>{"Accept": "application/json"};
    if (keyed) {
      headers["X-API-Key"] = _apiKey;
    }
    return headers;
  }

  static ExchangeException? _missingKey() {
    if (_apiKey.isEmpty) {
      return ExchangeException(
        "Chainflip API key is not configured",
        ExchangeExceptionType.generic,
      );
    }
    return null;
  }

  /// Logo URLs are persisted in the currency cache, so they always use the
  /// clearnet host: an onion URL cached in Tor mode would break once Tor is
  /// off, while the app's Tor-aware image loaders already proxy clearnet URLs.
  static String assetLogoUrl(String assetLogo) {
    if (assetLogo.startsWith("http")) return assetLogo;
    return "https://$authority$assetLogo";
  }

  Future<ExchangeResponse<List<ChainflipAsset>>> getAllAssets() async {
    try {
      final response = await _client.get(
        url: _buildUri("/assets", null),
        headers: _headers(keyed: false),
        proxyInfo: _proxyInfo(),
      );

      if (response.code != 200) {
        return ExchangeResponse(exception: _errorFromResponse(response));
      }

      final json = jsonDecode(response.body);
      final map = Map<String, dynamic>.from(json as Map<dynamic, dynamic>);
      final assets = map["assets"] as List<dynamic>;
      final parsed = assets
          .map(
            (element) => ChainflipAsset.fromJson(
              Map<String, dynamic>.from(element as Map<dynamic, dynamic>),
            ),
          )
          .toList();

      return ExchangeResponse(value: parsed);
    } catch (e, s) {
      Logging.instance.e("getAllAssets()", error: e, stackTrace: s);
      return ExchangeResponse(exception: _generic(e));
    }
  }

  Future<ExchangeResponse<List<ChainflipQuote>>> getQuotes({
    required String sourceAsset,
    required String destinationAsset,
    required String amountNative,
  }) async {
    final keyError = _missingKey();
    if (keyError != null) {
      return ExchangeResponse(exception: keyError);
    }

    try {
      final response = await _client.get(
        url: _buildUri("/quotes-native", <String, String>{
          "sourceAsset": sourceAsset,
          "destinationAsset": destinationAsset,
          "amount": amountNative,
        }),
        headers: _headers(keyed: true),
        proxyInfo: _proxyInfo(),
      );

      if (response.code != 200) {
        return ExchangeResponse(exception: _errorFromResponse(response));
      }

      final json = jsonDecode(response.body);
      final list = json as List<dynamic>;
      final parsed = list
          .map(
            (element) => ChainflipQuote.fromJson(
              Map<String, dynamic>.from(element as Map<dynamic, dynamic>),
            ),
          )
          .toList();

      return ExchangeResponse(value: parsed);
    } catch (e, s) {
      Logging.instance.e("getQuotes()", error: e, stackTrace: s);
      return ExchangeResponse(exception: _generic(e));
    }
  }

  Future<ExchangeResponse<ChainflipDepositAddress>> createSwap({
    required String sourceAsset,
    required String destinationAsset,
    required String destinationAddress,
    required String refundAddress,
    required String minimumPrice,
    required int retryDurationInBlocks,
    String? livePriceSlippageTolerancePercent,
  }) async {
    final keyError = _missingKey();
    if (keyError != null) {
      return ExchangeResponse(exception: keyError);
    }

    try {
      final params = <String, String>{
        "sourceAsset": sourceAsset,
        "destinationAsset": destinationAsset,
        "destinationAddress": destinationAddress,
        "refundAddress": refundAddress,
        "minimumPrice": minimumPrice,
        "retryDurationInBlocks": retryDurationInBlocks.toString(),
        if (livePriceSlippageTolerancePercent != null)
          "livePriceSlippageTolerancePercent":
              livePriceSlippageTolerancePercent,
      };

      final response = await _client.get(
        url: _buildUri("/swap", params),
        headers: _headers(keyed: true),
        proxyInfo: _proxyInfo(),
      );

      if (response.code != 200) {
        return ExchangeResponse(exception: _errorFromResponse(response));
      }

      final json = jsonDecode(response.body);
      final parsed = ChainflipDepositAddress.fromJson(
        Map<String, dynamic>.from(json as Map<dynamic, dynamic>),
      );

      return ExchangeResponse(value: parsed);
    } catch (e, s) {
      Logging.instance.e("createSwap()", error: e, stackTrace: s);
      return ExchangeResponse(exception: _generic(e));
    }
  }

  Future<ExchangeResponse<ChainflipSwapStatus>> getStatusById(
    String swapId,
  ) async {
    final keyError = _missingKey();
    if (keyError != null) {
      return ExchangeResponse(exception: keyError);
    }

    try {
      final response = await _client.get(
        url: _buildUri("/status-by-id", <String, String>{"swapId": swapId}),
        headers: _headers(keyed: true),
        proxyInfo: _proxyInfo(),
      );

      if (response.code == 404) {
        final code = _problemCode(response);
        if (code == "swap_pending") {
          return ExchangeResponse(
            value: ChainflipSwapStatus.pending(int.tryParse(swapId)),
          );
        }
        if (code == "swap_unknown") {
          return ExchangeResponse(
            exception: ExchangeException(
              "Swap not found",
              ExchangeExceptionType.orderNotFound,
            ),
          );
        }
      }

      if (response.code != 200) {
        return ExchangeResponse(exception: _errorFromResponse(response));
      }

      final json = jsonDecode(response.body);
      final parsed = ChainflipSwapStatus.fromJson(
        Map<String, dynamic>.from(json as Map<dynamic, dynamic>),
      );

      return ExchangeResponse(value: parsed);
    } catch (e, s) {
      Logging.instance.e("getStatusById()", error: e, stackTrace: s);
      return ExchangeResponse(exception: _generic(e));
    }
  }

  Future<ExchangeResponse<ChainflipSwapStatus>> getStatusByDepositChannel({
    required int issuedBlock,
    required String network,
    required int channelId,
  }) async {
    final keyError = _missingKey();
    if (keyError != null) {
      return ExchangeResponse(exception: keyError);
    }

    try {
      final response = await _client.get(
        url: _buildUri("/status-by-deposit-channel", <String, String>{
          "issuedBlock": issuedBlock.toString(),
          "network": network,
          "channelId": channelId.toString(),
        }),
        headers: _headers(keyed: true),
        proxyInfo: _proxyInfo(),
      );

      if (response.code == 404) {
        final code = _problemCode(response);
        if (code == "swap_pending") {
          return ExchangeResponse(value: ChainflipSwapStatus.pending(null));
        }
        if (code == "swap_unknown") {
          return ExchangeResponse(
            exception: ExchangeException(
              "Swap not found",
              ExchangeExceptionType.orderNotFound,
            ),
          );
        }
      }

      if (response.code != 200) {
        return ExchangeResponse(exception: _errorFromResponse(response));
      }

      final json = jsonDecode(response.body);
      final parsed = ChainflipSwapStatus.fromJson(
        Map<String, dynamic>.from(json as Map<dynamic, dynamic>),
      );

      return ExchangeResponse(value: parsed);
    } catch (e, s) {
      Logging.instance.e(
        "getStatusByDepositChannel()",
        error: e,
        stackTrace: s,
      );
      return ExchangeResponse(exception: _generic(e));
    }
  }

  static ExchangeException _generic(Object error) {
    return ExchangeException(error.toString(), ExchangeExceptionType.generic);
  }

  static String? _problemCode(Response response) {
    try {
      final json = jsonDecode(response.body);
      if (json is Map<dynamic, dynamic>) {
        final map = Map<String, dynamic>.from(json);
        return map["code"] as String?;
      }
    } catch (_) {
      // The body was not JSON; fall back to the HTTP status.
    }
    return null;
  }

  static String _problemDetail(Response response) {
    try {
      final json = jsonDecode(response.body);
      if (json is Map<dynamic, dynamic>) {
        final map = Map<String, dynamic>.from(json);
        final errors = map["errors"];
        if (errors is Map<dynamic, dynamic>) {
          final parts = <String>[];
          for (final value in errors.values) {
            if (value is List<dynamic>) {
              for (final item in value) {
                parts.add(item.toString());
              }
            } else {
              parts.add(value.toString());
            }
          }
          if (parts.isNotEmpty) return parts.join(" ");
        }
        final detail = map["detail"] as String?;
        if (detail != null && detail.isNotEmpty) return detail;
      }
    } catch (_) {
      // The body was not JSON; use it verbatim.
    }
    return response.body;
  }

  static ExchangeException _errorFromResponse(Response response) {
    final detail = _problemDetail(response);
    final code = _problemCode(response);
    final suffix = code == null ? "" : " ($code)";

    switch (response.code) {
      case 400:
        return ExchangeException(
          "$detail$suffix",
          ExchangeExceptionType.generic,
        );
      case 401:
        return ExchangeException(
          "Invalid Chainflip API key.",
          ExchangeExceptionType.generic,
        );
      case 403:
        return ExchangeException(
          "This route is not enabled for the Chainflip partner.",
          ExchangeExceptionType.generic,
        );
      case 404:
        if (code == "swap_pending") {
          return ExchangeException(
            "Swap pending; poll again.",
            ExchangeExceptionType.generic,
          );
        }
        if (code == "swap_unknown") {
          return ExchangeException(
            "Swap not found",
            ExchangeExceptionType.orderNotFound,
          );
        }
        return ExchangeException(detail, ExchangeExceptionType.generic);
      case 503:
        return ExchangeException(
          "Chainflip is temporarily unavailable: "
          "$detail$suffix",
          ExchangeExceptionType.generic,
        );
      default:
        return ExchangeException(
          "Chainflip error ${response.code}: $detail$suffix",
          ExchangeExceptionType.generic,
        );
    }
  }
}

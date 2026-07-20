import 'dart:convert';
import 'dart:io';

import 'package:decimal/decimal.dart';

import '../../../app_config.dart';
import '../../../networking/http.dart';
import '../../../services/tor_service.dart';
import '../../../utilities/logger.dart';
import '../../../utilities/prefs.dart';

/// Parsed `account_info` result for an XRP account.
class XrpAccountInfo {
  XrpAccountInfo({
    required this.balanceDrops,
    required this.sequence,
    required this.ownerCount,
  });

  final BigInt balanceDrops;
  final int sequence;
  final int ownerCount;
}

/// Thin rippled JSON-RPC client routed through the repo's [HTTP] wrapper so
/// Tor/proxy and failover behaviour stay consistent with the other coins.
/// Mirrors the `TezosRpcAPI` pattern.
abstract final class XrpRpcClient {
  static final HTTP _client = HTTP();

  static Uri _url(({String host, int port}) n) =>
      Uri.parse("${n.host}:${n.port}/");

  static ({InternetAddress host, int port})? get _proxyInfo =>
      !AppConfig.hasFeature(AppFeature.tor)
      ? null
      : Prefs.instance.useTor
      ? TorService.sharedInstance.getProxyInfo()
      : null;

  /// Low-level rippled JSON-RPC call. Returns the `result` object.
  /// Throws on transport/HTTP error; rippled-level errors are left in the
  /// returned map (`result["error"]`) for the caller to interpret.
  static Future<Map<String, dynamic>> _call({
    required ({String host, int port}) nodeInfo,
    required String method,
    Map<String, dynamic> params = const {},
  }) async {
    final response = await _client.post(
      url: _url(nodeInfo),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "method": method,
        "params": [params],
      }),
      proxyInfo: _proxyInfo,
    );

    if (response.code != 200) {
      throw Exception("XRP RPC $method failed: HTTP ${response.code}");
    }

    final decoded = jsonDecode(response.body) as Map;
    return Map<String, dynamic>.from(decoded["result"] as Map);
  }

  /// `account_info` for [address]. Returns `null` when the account is not yet
  /// activated on-ledger (`actNotFound`) — i.e. it holds no XRP.
  static Future<XrpAccountInfo?> accountInfo({
    required ({String host, int port}) nodeInfo,
    required String address,
  }) async {
    final result = await _call(
      nodeInfo: nodeInfo,
      method: "account_info",
      params: {"account": address, "ledger_index": "validated"},
    );

    if (result["error"] == "actNotFound") return null;
    if (result["account_data"] == null) {
      throw Exception("XRP account_info error: ${result["error"] ?? result}");
    }

    final data = Map<String, dynamic>.from(result["account_data"] as Map);
    return XrpAccountInfo(
      balanceDrops: BigInt.parse(data["Balance"].toString()),
      sequence: int.parse(data["Sequence"].toString()),
      ownerCount: int.tryParse((data["OwnerCount"] ?? 0).toString()) ?? 0,
    );
  }

  /// Live reserve requirement (in drops) + validated ledger index, from
  /// `server_info`. Reserves are validator-adjustable, so always read live.
  static Future<
    ({BigInt baseReserveDrops, BigInt ownerReserveDrops, int ledgerIndex})
  >
  serverState({required ({String host, int port}) nodeInfo}) async {
    final result = await _call(nodeInfo: nodeInfo, method: "server_info");
    final info = Map<String, dynamic>.from(result["info"] as Map);
    final vl = Map<String, dynamic>.from(info["validated_ledger"] as Map);

    BigInt xrpToDrops(Object? xrp) =>
        (Decimal.parse(xrp.toString()) * Decimal.fromInt(1000000)).toBigInt();

    return (
      baseReserveDrops: xrpToDrops(vl["reserve_base_xrp"]),
      ownerReserveDrops: xrpToDrops(vl["reserve_inc_xrp"]),
      ledgerIndex: int.parse(vl["seq"].toString()),
    );
  }

  /// Recent transactions affecting [address], newest first. Empty for an
  /// unactivated account.
  static Future<List<Map<String, dynamic>>> accountTx({
    required ({String host, int port}) nodeInfo,
    required String address,
    int limit = 100,
  }) async {
    final result = await _call(
      nodeInfo: nodeInfo,
      method: "account_tx",
      params: {
        "account": address,
        "ledger_index_min": -1,
        "ledger_index_max": -1,
        "binary": false,
        "forward": false,
        "limit": limit,
      },
    );

    if (result["error"] == "actNotFound") return [];
    final txns = (result["transactions"] as List?) ?? [];
    return txns
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList(growable: false);
  }

  /// Current reference transaction cost in drops (open-ledger fee).
  static Future<BigInt> baseFeeDrops({
    required ({String host, int port}) nodeInfo,
  }) async {
    try {
      final result = await _call(nodeInfo: nodeInfo, method: "fee");
      final drops = Map<String, dynamic>.from(result["drops"] as Map);
      final fee = drops["open_ledger_fee"] ?? drops["base_fee"] ?? "10";
      return BigInt.parse(fee.toString());
    } catch (e, s) {
      Logging.instance.w(
        "XRP baseFeeDrops failed, using 10: $e",
        stackTrace: s,
      );
      return BigInt.from(10);
    }
  }

  /// Submit a signed transaction blob. Returns the `engine_result` code.
  /// (Used by the send flow in a later PR.)
  static Future<String> submit({
    required ({String host, int port}) nodeInfo,
    required String txBlobHex,
  }) async {
    final result = await _call(
      nodeInfo: nodeInfo,
      method: "submit",
      params: {"tx_blob": txBlobHex},
    );
    return (result["engine_result"] ?? result["error"] ?? "unknown").toString();
  }
}

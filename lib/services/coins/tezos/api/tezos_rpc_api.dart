import 'dart:convert';

import '../../../../app_config.dart';
import '../../../../networking/http.dart';
import '../../../../utilities/logger.dart';
import '../../../../utilities/prefs.dart';
import '../../../tor_service.dart';

abstract final class TezosRpcAPI {
  static final HTTP _client = HTTP();

  static Future<BigInt?> getBalance({
    required ({String host, int port}) nodeInfo,
    required String address,
  }) async {
    try {
      final String balanceCall =
          "${nodeInfo.host}:${nodeInfo.port}/chains/main/blocks/head/context/contracts/$address/balance";

      final response = await _client.get(
        url: Uri.parse(balanceCall),
        headers: {'Content-Type': 'application/json'},
        proxyInfo: !AppConfig.hasFeature(AppFeature.tor)
            ? null
            : Prefs.instance.useTor
            ? TorService.sharedInstance.getProxyInfo()
            : null,
      );

      final balance = BigInt.parse(
        response.body.substring(1, response.body.length - 2),
      );
      return balance;
    } catch (e, s) {
      Logging.instance.e(
        "Error occurred in tezos_rpc_api.dart while getting balance for $address",
        error: e,
        stackTrace: s,
      );
    }
    return null;
  }

  static Future<int?> getChainHeight({
    required ({String host, int port}) nodeInfo,
  }) async {
    try {
      final api =
          "${nodeInfo.host}:${nodeInfo.port}/chains/main/blocks/head/header/shell";

      final response = await _client.get(
        url: Uri.parse(api),
        headers: {'Content-Type': 'application/json'},
        proxyInfo: !AppConfig.hasFeature(AppFeature.tor)
            ? null
            : Prefs.instance.useTor
            ? TorService.sharedInstance.getProxyInfo()
            : null,
      );

      final jsonParsedResponse = jsonDecode(response.body);
      return int.parse(jsonParsedResponse["level"].toString());
    } catch (e, s) {
      Logging.instance.e(
        "Error occurred in tezos_rpc_api.dart while getting chain height for tezos",
        error: e,
        stackTrace: s,
      );
    }
    return null;
  }

  static Future<bool> testNetworkConnection({
    required ({String host, int port}) nodeInfo,
  }) async {
    final result = await getChainHeight(nodeInfo: nodeInfo);
    return result != null;
  }
}

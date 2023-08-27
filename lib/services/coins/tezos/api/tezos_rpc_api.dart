import 'dart:convert';

import 'package:http/http.dart';

import 'package:stackwallet/utilities/logger.dart';

class TezosRpcAPI {
  Future<BigInt?> getBalance(
      {required ({String host, int port}) nodeInfo,
      required String address}) async {
    try {
      String balanceCall =
          "${nodeInfo.host}:${nodeInfo.port}/chains/main/blocks/head/context/contracts/$address/balance";
      var response =
          await get(Uri.parse(balanceCall)).then((value) => value.body);
      var balance = BigInt.parse(response.substring(1, response.length - 2));
      return balance;
    } catch (e) {
      Logging.instance.log(
          "Error occured in tezos_rpc_api.dart while getting balance for $address: $e",
          level: LogLevel.Error);
    }
    return null;
  }

  Future<int?> getChainHeight(
      {required ({String host, int port}) nodeInfo}) async {
    try {
      var api =
          "${nodeInfo.host}:${nodeInfo.port}/chains/main/blocks/head/header/shell";
      var jsonParsedResponse =
          jsonDecode(await get(Uri.parse(api)).then((value) => value.body));
      return int.parse(jsonParsedResponse["level"].toString());
    } catch (e) {
      Logging.instance.log(
          "Error occured in tezos_rpc_api.dart while getting chain height for tezos: $e",
          level: LogLevel.Error);
    }
    return null;
  }

  Future<bool> testNetworkConnection(
      {required ({String host, int port}) nodeInfo}) async {
    try {
      await get(Uri.parse(
          "${nodeInfo.host}:${nodeInfo.port}/chains/main/blocks/head/header/shell"));
      return true;
    } catch (e) {
      return false;
    }
  }
}

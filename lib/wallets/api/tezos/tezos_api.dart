import 'dart:convert';
import 'dart:math';

import 'package:stackwallet/networking/http.dart';
import 'package:stackwallet/services/tor_service.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/utilities/logger.dart';
import 'package:stackwallet/utilities/prefs.dart';
import 'package:stackwallet/wallets/api/tezos/tezos_transaction.dart';

abstract final class TezosAPI {
  static final HTTP _client = HTTP();
  static const String _baseURL = 'https://api.mainnet.tzkt.io';

  static Future<List<TezosTransaction>?> getTransactions(String address) async {
    try {
      final transactionsCall = "$_baseURL/explorer/account/$address/operations";

      final response = await _client.get(
        url: Uri.parse(transactionsCall),
        headers: {'Content-Type': 'application/json'},
        proxyInfo: Prefs.instance.useTor
            ? TorService.sharedInstance.getProxyInfo()
            : null,
      );

      final result = jsonDecode(response.body) as List;

      List<TezosTransaction> txs = [];
      for (var tx in result) {
        if (tx["type"] == "transaction") {
          int? burnedAmountInMicroTez;
          int? storageLimit;
          if (tx["burned"] != null) {
            burnedAmountInMicroTez = double.parse(
                    (tx["burned"] * pow(10, Coin.tezos.decimals)).toString())
                .toInt();
          }
          if (tx["storage_limit"] != null) {
            storageLimit = tx["storage_limit"] as int;
          }
          final theTx = TezosTransaction(
            id: tx["id"] as int,
            hash: tx["hash"] as String,
            type: tx["type"] as String,
            height: tx["height"] as int,
            timestamp: DateTime.parse(tx["time"].toString())
                    .toUtc()
                    .millisecondsSinceEpoch ~/
                1000,
            cycle: tx["cycle"] as int,
            counter: tx["counter"] as int,
            opN: tx["op_n"] as int,
            opP: tx["op_p"] as int,
            status: tx["status"] as String,
            isSuccess: tx["is_success"] as bool,
            gasLimit: tx["gas_limit"] as int,
            gasUsed: tx["gas_used"] as int,
            storageLimit: storageLimit,
            amountInMicroTez: double.parse(
                    (tx["volume"] * pow(10, Coin.tezos.decimals)).toString())
                .toInt(),
            feeInMicroTez: double.parse(
                    (tx["fee"] * pow(10, Coin.tezos.decimals)).toString())
                .toInt(),
            burnedAmountInMicroTez: burnedAmountInMicroTez,
            senderAddress: tx["sender"] as String,
            receiverAddress: tx["receiver"] as String,
            confirmations: tx["confirmations"] as int,
          );
          txs.add(theTx);
        }
      }
      return txs;
    } catch (e) {
      Logging.instance.log(
        "Error occurred in tezos_api.dart while getting transactions for $address: $e",
        level: LogLevel.Error,
      );
    }
    return null;
  }

  static Future<int?> getFeeEstimationFromLastDays(int days) async {
    try {
      var api = "$_baseURL/series/op?start_date=today&collapse=$days";

      final response = await _client.get(
        url: Uri.parse(api),
        headers: {'Content-Type': 'application/json'},
        proxyInfo: Prefs.instance.useTor
            ? TorService.sharedInstance.getProxyInfo()
            : null,
      );

      final result = jsonDecode(response.body);

      double totalFees = result[0][4] as double;
      int totalTxs = result[0][8] as int;
      return ((totalFees / totalTxs * Coin.tezos.decimals).floor());
    } catch (e) {
      Logging.instance.log(
        "Error occurred in tezos_api.dart while getting fee estimation for tezos: $e",
        level: LogLevel.Error,
      );
    }
    return null;
  }
}

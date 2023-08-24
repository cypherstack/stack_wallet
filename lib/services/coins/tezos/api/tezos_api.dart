import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart';
import 'package:stackwallet/services/coins/tezos/api/tezos_transaction.dart';
import 'package:stackwallet/utilities/logger.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';

class TezosAPI {
  static const String _baseURL = 'https://api.tzstats.com';

  Future<List<TezosOperation>?> getTransactions(String address) async {
    try {
      String transactionsCall = "$_baseURL/explorer/account/$address/operations";
      var response = jsonDecode(
          await get(Uri.parse(transactionsCall)).then((value) => value.body));
      List<TezosOperation> txs = [];
      for (var tx in response as List) {
        if (tx["type"] == "transaction") {
          int? burnedAmountInMicroTez;
          int? storage_limit;
          if (tx["burned"] != null) {
            burnedAmountInMicroTez = double.parse((tx["burned"] * pow(10, Coin.tezos.decimals)).toString()).toInt();
          }
          if (tx["storage_limit"] != null) {
            storage_limit = tx["storage_limit"] as int;
          }
          final theTx = TezosOperation(
              id: tx["id"] as int,
              hash: tx["hash"] as String,
              type: tx["type"] as String,
              height: tx["height"] as int,
              timestamp: DateTime.parse(tx["time"].toString()).toUtc().millisecondsSinceEpoch ~/ 1000,
              cycle: tx["cycle"] as int,
              counter: tx["counter"] as int,
              op_n: tx["op_n"] as int,
              op_p: tx["op_p"] as int,
              status: tx["status"] as String,
              is_success: tx["is_success"] as bool,
              gas_limit: tx["gas_limit"] as int,
              gas_used: tx["gas_used"] as int,
              storage_limit: storage_limit,
              amountInMicroTez: double.parse((tx["volume"] * pow(10, Coin.tezos.decimals)).toString()).toInt(),
              feeInMicroTez: double.parse((tx["fee"] * pow(10, Coin.tezos.decimals)).toString()).toInt(),
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
          "Error occured while getting transactions for $address: $e",
          level: LogLevel.Error);
    }
    return null;
  }

  Future<int?> getFeeEstimationFromLastDays(int days) async {
    try {
      var api = "$_baseURL/series/op?start_date=today&collapse=$days";
      var response = jsonDecode((await get(Uri.parse(api))).body);
      double totalFees = response[0][4] as double;
      int totalTxs = response[0][8] as int;
      return ((totalFees / totalTxs * Coin.tezos.decimals).floor());
    } catch (e) {
      Logging.instance.log("Error occured while getting fee estimation: $e",
          level: LogLevel.Error);
    }
    return null;
  }
}

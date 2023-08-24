import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart';
import 'package:stackwallet/services/coins/tezos/api/tezos_transaction.dart';
import 'package:stackwallet/utilities/logger.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';

class TezosAPI {
  static const String _baseURL = 'https://api.tzstats.com';

  Future<List<TezosTransaction>?> getTransactions(String address) async {
    try {
      String transactionsCall = "$_baseURL/explorer/account/$address/operations";
      var response = jsonDecode(
          await get(Uri.parse(transactionsCall)).then((value) => value.body));
      List<TezosTransaction> txs = [];
      for (var tx in response as List) {
        if (tx["type"] == "transaction") {
          final theTx = TezosTransaction(
              hash: tx["hash"] as String,
              height: tx["height"] as int,
              timestamp: DateTime.parse(tx["time"].toString()).toUtc().millisecondsSinceEpoch ~/ 1000,
              amountInMicroTez: double.parse((tx["volume"] * pow(10, Coin.tezos.decimals)).toString()).toInt(),
              feeInMicroTez: double.parse((tx["fee"] * pow(10, Coin.tezos.decimals)).toString()).toInt(),
              senderAddress: tx["sender"] as String,
              receiverAddress: tx["receiver"] as String
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

import 'dart:convert';

import 'package:stackwallet/networking/http.dart';
import 'package:stackwallet/services/tor_service.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/utilities/logger.dart';
import 'package:stackwallet/utilities/prefs.dart';
import 'package:stackwallet/wallets/api/tezos/tezos_transaction.dart';

abstract final class TezosAPI {
  static final HTTP _client = HTTP();
  static const String _baseURL = 'https://api.tzkt.io';

  static Future<List<TezosTransaction>?> getTransactions(String address) async {
    try {
      final transactionsCall =
          "$_baseURL/v1/accounts/$address/operations?type=transaction";

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
          final theTx = TezosTransaction(
            id: tx["id"] as int,
            hash: tx["hash"] as String,
            type: tx["type"] as String,
            height: tx["level"] as int,
            timestamp: DateTime.parse(tx["timestamp"].toString())
                    .toUtc()
                    .millisecondsSinceEpoch ~/
                1000,
            cycle: tx["cycle"] as int?,
            counter: tx["counter"] as int,
            opN: tx["op_n"] as int?,
            opP: tx["op_p"] as int?,
            status: tx["status"] as String,
            gasLimit: tx["gasLimit"] as int,
            gasUsed: tx["gasUsed"] as int,
            storageLimit: tx["storageLimit"] as int?,
            amountInMicroTez: tx["amount"] as int,
            feeInMicroTez: (tx["bakerFee"] as int? ?? 0) +
                (tx["storageFee"] as int? ?? 0) +
                (tx["allocationFee"] as int? ?? 0),
            burnedAmountInMicroTez: tx["burned"] as int?,
            senderAddress: tx["sender"]["address"] as String,
            receiverAddress: tx["target"]["address"] as String,
          );
          txs.add(theTx);
        }
      }
      return txs;
    } catch (e, s) {
      Logging.instance.log(
        "Error occurred in tezos_api.dart while getting transactions for $address: $e\n$s",
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

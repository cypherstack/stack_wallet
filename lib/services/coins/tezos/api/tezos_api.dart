import 'dart:convert';

import '../../../../networking/http.dart';
import '../../../../utilities/logger.dart';
import '../../../../utilities/prefs.dart';
import '../../../tor_service.dart';
import 'tezos_account.dart';
import 'tezos_transaction.dart';

abstract final class TezosAPI {
  static final HTTP _client = HTTP();
  static const String _baseURL = 'https://api.tzkt.io';

  static Future<int> getCounter(String address) async {
    try {
      final uriString = "$_baseURL/v1/accounts/$address/counter";
      final response = await _client.get(
        url: Uri.parse(uriString),
        headers: {'Content-Type': 'application/json'},
        proxyInfo: Prefs.instance.useTor
            ? TorService.sharedInstance.getProxyInfo()
            : null,
      );

      final result = jsonDecode(response.body);
      return result as int;
    } catch (e, s) {
      Logging.instance.logd(
        "Error occurred in TezosAPI while getting counter for $address: $e\n$s",
        level: LogLevel.Error,
      );
      rethrow;
    }
  }

  static Future<TezosAccount> getAccount(
    String address, {
    String type = "user",
  }) async {
    try {
      final uriString = "$_baseURL/v1/accounts/$address?legacy=false";
      final response = await _client.get(
        url: Uri.parse(uriString),
        headers: {'Content-Type': 'application/json'},
        proxyInfo: Prefs.instance.useTor
            ? TorService.sharedInstance.getProxyInfo()
            : null,
      );

      final result = jsonDecode(response.body) as Map;

      final account = TezosAccount.fromMap(Map<String, dynamic>.from(result));

      return account;
    } catch (e, s) {
      Logging.instance.logd(
        "Error occurred in TezosAPI while getting account for $address: $e\n$s",
        level: LogLevel.Error,
      );
      rethrow;
    }
  }

  static Future<List<TezosTransaction>> getTransactions(String address) async {
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

      final List<TezosTransaction> txs = [];
      for (final tx in result) {
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
      Logging.instance.logd(
        "Error occurred in TezosAPI while getting transactions for $address: $e\n$s",
        level: LogLevel.Error,
      );
      rethrow;
    }
  }
}

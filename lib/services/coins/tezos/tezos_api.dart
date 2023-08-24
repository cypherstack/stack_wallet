import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart';
import 'package:stackwallet/utilities/logger.dart';
import 'package:tuple/tuple.dart';

import 'package:stackwallet/models/isar/models/blockchain_data/address.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/transaction.dart';
import 'package:stackwallet/utilities/amount/amount.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';

class TezosAPI {
  static const String _baseURL = 'https://api.tzstats.com';

  Future<List<Tuple2<Transaction, Address>>?> getTransactions(
      String walletId, String address) async {
    try {
      String transactionsCall = "$_baseURL/explorer/account/$address/operations";
      var response = jsonDecode(
          await get(Uri.parse(transactionsCall)).then((value) => value.body));
      List<Tuple2<Transaction, Address>> txs = [];
      for (var tx in response as List) {
        if (tx["type"] == "transaction") {
          TransactionType txType;
          final String myAddress = address;
          final String senderAddress = tx["sender"] as String;
          final String targetAddress = tx["receiver"] as String;
          if (senderAddress == myAddress && targetAddress == myAddress) {
            txType = TransactionType.sentToSelf;
          } else if (senderAddress == myAddress) {
            txType = TransactionType.outgoing;
          } else if (targetAddress == myAddress) {
            txType = TransactionType.incoming;
          } else {
            txType = TransactionType.unknown;
          }
          var amount = double.parse((tx["volume"] * pow(10, Coin.tezos.decimals)).toString()).toInt();
          var fee = double.parse((tx["fee"] * pow(10, Coin.tezos.decimals)).toString()).toInt();
          var theTx = Transaction(
            walletId: walletId,
            txid: tx["hash"].toString(),
            timestamp: DateTime.parse(tx["time"].toString())
                    .toUtc()
                    .millisecondsSinceEpoch ~/
                1000,
            type: txType,
            subType: TransactionSubType.none,
            amount: amount,
            amountString: Amount(
                    rawValue:
                        BigInt.parse((amount).toInt().toString()),
                    fractionDigits: Coin.tezos.decimals)
                .toJsonString(),
            fee: fee,
            height: int.parse(tx["height"].toString()),
            isCancelled: false,
            isLelantus: false,
            slateId: "",
            otherData: "",
            inputs: [],
            outputs: [],
            nonce: 0,
            numberOfMessages: null,
          );
          final AddressSubType subType;
          switch (txType) {
            case TransactionType.incoming:
            case TransactionType.sentToSelf:
              subType = AddressSubType.receiving;
              break;
            case TransactionType.outgoing:
            case TransactionType.unknown:
              subType = AddressSubType.unknown;
              break;
          }
          final theAddress = Address(
            walletId: walletId,
            value: targetAddress,
            publicKey: [],
            derivationIndex: 0,
            derivationPath: null,
            type: AddressType.unknown,
            subType: subType,
          );
          txs.add(Tuple2(theTx, theAddress));
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

  Future<int?> getFeeEstimation() async {
    try {
      var api = "$_baseURL/series/op?start_date=today&collapse=1d";
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

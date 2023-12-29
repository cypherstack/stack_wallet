import 'dart:convert';
import 'dart:math';

import 'package:isar/isar.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/transaction.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/v2/input_v2.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/v2/output_v2.dart';
import 'package:stackwallet/utilities/amount/amount.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/utilities/extensions/extensions.dart';
import 'package:stackwallet/wallets/wallet/wallet_mixin_interfaces/spark_interface.dart';

part 'transaction_v2.g.dart';

@Collection()
class TransactionV2 {
  Id id = Isar.autoIncrement;

  @Index()
  final String walletId;

  @Index(unique: true, composite: [CompositeIndex("walletId")])
  final String txid;

  final String hash;

  @Index()
  late final int timestamp;

  final int? height;
  final String? blockHash;
  final int version;

  final List<InputV2> inputs;
  final List<OutputV2> outputs;

  @enumerated
  final TransactionType type;

  @enumerated
  final TransactionSubType subType;

  final String? otherData;

  TransactionV2({
    required this.walletId,
    required this.blockHash,
    required this.hash,
    required this.txid,
    required this.timestamp,
    required this.height,
    required this.inputs,
    required this.outputs,
    required this.version,
    required this.type,
    required this.subType,
    required this.otherData,
  });

  int getConfirmations(int currentChainHeight) {
    if (height == null || height! <= 0) return 0;
    return max(0, currentChainHeight - (height! - 1));
  }

  bool isConfirmed(int currentChainHeight, int minimumConfirms) {
    final confirmations = getConfirmations(currentChainHeight);
    return confirmations >= minimumConfirms;
  }

  Amount getFee({required Coin coin}) {
    final inSum =
        inputs.map((e) => e.value).reduce((value, element) => value += element);
    final outSum = outputs
        .map((e) => e.value)
        .reduce((value, element) => value += element);

    return Amount(rawValue: inSum - outSum, fractionDigits: coin.decimals);
  }

  Amount getAmountReceivedInThisWallet({required Coin coin}) {
    final outSum = outputs
        .where((e) => e.walletOwns)
        .fold(BigInt.zero, (p, e) => p + e.value);

    return Amount(rawValue: outSum, fractionDigits: coin.decimals);
  }

  Amount getAmountSparkSelfMinted({required Coin coin}) {
    final outSum = outputs.where((e) {
      final op = e.scriptPubKeyHex.substring(0, 2).toUint8ListFromHex.first;
      return e.walletOwns && (op == OP_SPARKMINT);
    }).fold(BigInt.zero, (p, e) => p + e.value);

    return Amount(rawValue: outSum, fractionDigits: coin.decimals);
  }

  Amount getAmountSentFromThisWallet({required Coin coin}) {
    final inSum = inputs
        .where((e) => e.walletOwns)
        .fold(BigInt.zero, (p, e) => p + e.value);

    return Amount(
          rawValue: inSum,
          fractionDigits: coin.decimals,
        ) -
        getAmountReceivedInThisWallet(
          coin: coin,
        ) -
        getFee(coin: coin);
  }

  Set<String> associatedAddresses() => {
        ...inputs.map((e) => e.addresses).expand((e) => e),
        ...outputs.map((e) => e.addresses).expand((e) => e),
      };

  Amount? getAnonFee() {
    try {
      final map = jsonDecode(otherData!) as Map;
      return Amount.fromSerializedJsonString(map["anonFees"] as String);
    } catch (_) {
      return null;
    }
  }

  String statusLabel({
    required int currentChainHeight,
    required int minConfirms,
  }) {
    if (subType == TransactionSubType.cashFusion ||
        subType == TransactionSubType.mint ||
        (subType == TransactionSubType.sparkMint &&
            type == TransactionType.sentToSelf)) {
      if (isConfirmed(currentChainHeight, minConfirms)) {
        return "Anonymized";
      } else {
        return "Anonymizing";
      }
    }

    // if (coin == Coin.epicCash) {
    //   if (_transaction.isCancelled) {
    //     return "Cancelled";
    //   } else if (type == TransactionType.incoming) {
    //     if (isConfirmed(height, minConfirms)) {
    //       return "Received";
    //     } else {
    //       if (_transaction.numberOfMessages == 1) {
    //         return "Receiving (waiting for sender)";
    //       } else if ((_transaction.numberOfMessages ?? 0) > 1) {
    //         return "Receiving (waiting for confirmations)"; // TODO test if the sender still has to open again after the receiver has 2 messages present, ie. sender->receiver->sender->node (yes) vs. sender->receiver->node (no)
    //       } else {
    //         return "Receiving";
    //       }
    //     }
    //   } else if (type == TransactionType.outgoing) {
    //     if (isConfirmed(height, minConfirms)) {
    //       return "Sent (confirmed)";
    //     } else {
    //       if (_transaction.numberOfMessages == 1) {
    //         return "Sending (waiting for receiver)";
    //       } else if ((_transaction.numberOfMessages ?? 0) > 1) {
    //         return "Sending (waiting for confirmations)";
    //       } else {
    //         return "Sending";
    //       }
    //     }
    //   }
    // }

    if (type == TransactionType.incoming) {
      // if (_transaction.isMinting) {
      //   return "Minting";
      // } else
      if (isConfirmed(currentChainHeight, minConfirms)) {
        return "Received";
      } else {
        return "Receiving";
      }
    } else if (type == TransactionType.outgoing) {
      if (isConfirmed(currentChainHeight, minConfirms)) {
        return "Sent";
      } else {
        return "Sending";
      }
    } else if (type == TransactionType.sentToSelf) {
      return "Sent to self";
    } else {
      return type.name;
    }
  }

  @override
  String toString() {
    return 'TransactionV2(\n'
        '  walletId: $walletId,\n'
        '  hash: $hash,\n'
        '  txid: $txid,\n'
        '  type: $type,\n'
        '  subType: $subType,\n'
        '  timestamp: $timestamp,\n'
        '  height: $height,\n'
        '  blockHash: $blockHash,\n'
        '  version: $version,\n'
        '  inputs: $inputs,\n'
        '  outputs: $outputs,\n'
        '  otherData: $otherData,\n'
        ')';
  }
}

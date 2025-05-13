import 'dart:convert';
import 'dart:math';

import 'package:isar/isar.dart';

import '../../../../../utilities/amount/amount.dart';
import '../../../../../utilities/extensions/extensions.dart';
import '../../../../../wallets/wallet/wallet_mixin_interfaces/spark_interface.dart';
import '../transaction.dart';
import 'input_v2.dart';
import 'output_v2.dart';

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

  TransactionV2 copyWith({
    String? walletId,
    String? txid,
    String? hash,
    int? timestamp,
    int? height,
    String? blockHash,
    int? version,
    List<InputV2>? inputs,
    List<OutputV2>? outputs,
    TransactionType? type,
    TransactionSubType? subType,
    String? otherData,
  }) {
    return TransactionV2(
      walletId: walletId ?? this.walletId,
      txid: txid ?? this.txid,
      hash: hash ?? this.hash,
      timestamp: timestamp ?? this.timestamp,
      height: height ?? this.height,
      blockHash: blockHash ?? this.blockHash,
      version: version ?? this.version,
      inputs: inputs ?? this.inputs,
      outputs: outputs ?? this.outputs,
      type: type ?? this.type,
      subType: subType ?? this.subType,
      otherData: otherData ?? this.otherData,
    );
  }

  @ignore
  int? get size => _getFromOtherData(key: TxV2OdKeys.size) as int?;

  @ignore
  int? get vSize => _getFromOtherData(key: TxV2OdKeys.vSize) as int?;

  bool get isEpiccashTransaction =>
      _getFromOtherData(key: TxV2OdKeys.isEpiccashTransaction) == true;
  int? get numberOfMessages =>
      _getFromOtherData(key: TxV2OdKeys.numberOfMessages) as int?;
  String? get slateId => _getFromOtherData(key: TxV2OdKeys.slateId) as String?;
  String? get onChainNote =>
      _getFromOtherData(key: TxV2OdKeys.onChainNote) as String?;
  bool get isCancelled =>
      _getFromOtherData(key: TxV2OdKeys.isCancelled) == true;

  String? get contractAddress =>
      _getFromOtherData(key: TxV2OdKeys.contractAddress) as String?;
  int? get nonce => _getFromOtherData(key: TxV2OdKeys.nonce) as int?;

  int getConfirmations(int currentChainHeight) {
    if (height == null || height! <= 0) return 0;
    return _isMonero()
        ? max(0, currentChainHeight - (height!))
        : max(0, currentChainHeight - (height! - 1));
  }

  bool isConfirmed(
    int currentChainHeight,
    int minimumConfirms,
    int minimumCoinbaseConfirms,
  ) {
    final confirmations = getConfirmations(currentChainHeight);
    return confirmations >=
        (isCoinbase() ? minimumCoinbaseConfirms : minimumConfirms);
  }

  Amount getFee({required int fractionDigits}) {
    // check for override fee
    final fee = _getOverrideFee();
    if (fee != null) {
      return fee;
    }

    if (isCoinbase()) {
      return Amount.zeroWith(fractionDigits: fractionDigits);
    }

    final inSum = inputs
        .map((e) => e.value)
        .reduce((value, element) => value += element);
    final outSum = outputs
        .map((e) => e.value)
        .reduce((value, element) => value += element);

    return Amount(rawValue: inSum - outSum, fractionDigits: fractionDigits);
  }

  Amount getAmountReceivedInThisWallet({required int fractionDigits}) {
    if (_isMonero()) {
      if (type == TransactionType.incoming) {
        return _getMoneroAmount()!;
      } else {
        return Amount.zeroWith(fractionDigits: fractionDigits);
      }
    }

    final outSum = outputs
        .where((e) => e.walletOwns)
        .fold(BigInt.zero, (p, e) => p + e.value);

    return Amount(rawValue: outSum, fractionDigits: fractionDigits);
  }

  Amount getAmountSparkSelfMinted({required int fractionDigits}) {
    final outSum = outputs
        .where((e) {
          final op = e.scriptPubKeyHex.substring(0, 2).toUint8ListFromHex.first;
          return e.walletOwns && (op == OP_SPARKMINT);
        })
        .fold(BigInt.zero, (p, e) => p + e.value);

    return Amount(rawValue: outSum, fractionDigits: fractionDigits);
  }

  Amount getAmountSentFromThisWallet({
    required int fractionDigits,
    required bool subtractFee,
  }) {
    if (_isMonero()) {
      if (type == TransactionType.outgoing) {
        return _getMoneroAmount()!;
      } else {
        return Amount.zeroWith(fractionDigits: fractionDigits);
      }
    }

    final inSum = inputs
        .where((e) => e.walletOwns)
        .fold(BigInt.zero, (p, e) => p + e.value);

    Amount amount =
        Amount(rawValue: inSum, fractionDigits: fractionDigits) -
        getAmountReceivedInThisWallet(fractionDigits: fractionDigits);

    if (subtractFee) {
      amount = amount - getFee(fractionDigits: fractionDigits);
    }

    // negative amounts are likely an error or can happen with coins such as eth
    // that don't use the btc style inputs/outputs
    if (amount.raw < BigInt.zero) {
      return Amount.zeroWith(fractionDigits: fractionDigits);
    }

    return amount;
  }

  Set<String> associatedAddresses() => {
    ...inputs.map((e) => e.addresses).expand((e) => e),
    ...outputs.map((e) => e.addresses).expand((e) => e),
  };

  Amount? _getOverrideFee() {
    try {
      return Amount.fromSerializedJsonString(
        _getFromOtherData(key: TxV2OdKeys.overrideFee) as String,
      );
    } catch (_) {
      return null;
    }
  }

  Amount? _getMoneroAmount() {
    try {
      return Amount.fromSerializedJsonString(
        _getFromOtherData(key: TxV2OdKeys.moneroAmount) as String,
      );
    } catch (_) {
      return null;
    }
  }

  bool _isMonero() {
    final value = _getFromOtherData(key: TxV2OdKeys.isMoneroTransaction);
    return value is bool ? value : false;
  }

  String statusLabel({
    required int currentChainHeight,
    required int minConfirms,
    required int minCoinbaseConfirms,
  }) {
    String prettyConfirms() =>
        "("
        "${getConfirmations(currentChainHeight)}"
        "/"
        "${(isCoinbase() ? minCoinbaseConfirms : minConfirms)}"
        ")";

    if (subType == TransactionSubType.cashFusion ||
        subType == TransactionSubType.mint ||
        (subType == TransactionSubType.sparkMint &&
            type == TransactionType.sentToSelf)) {
      if (isConfirmed(currentChainHeight, minConfirms, minCoinbaseConfirms)) {
        return "Anonymized";
      } else {
        return "Anonymizing ${prettyConfirms()}";
      }
    }

    if (isEpiccashTransaction) {
      if (slateId == null) {
        return "Restored Funds";
      }

      if (isCancelled) {
        return "Cancelled";
      } else if (type == TransactionType.incoming) {
        if (isConfirmed(currentChainHeight, minConfirms, minCoinbaseConfirms)) {
          return "Received";
        } else {
          if (numberOfMessages == 1) {
            return "Receiving (waiting for sender)";
          } else if ((numberOfMessages ?? 0) > 1) {
            return "Receiving (waiting for confirmations)"; // TODO test if the sender still has to open again after the receiver has 2 messages present, ie. sender->receiver->sender->node (yes) vs. sender->receiver->node (no)
          } else {
            return "Receiving ${prettyConfirms()}";
          }
        }
      } else if (type == TransactionType.outgoing) {
        if (isConfirmed(currentChainHeight, minConfirms, minCoinbaseConfirms)) {
          return "Sent (confirmed)";
        } else {
          if (numberOfMessages == 1) {
            return "Sending (waiting for receiver)";
          } else if ((numberOfMessages ?? 0) > 1) {
            return "Sending (waiting for confirmations)";
          } else {
            return "Sending ${prettyConfirms()}";
          }
        }
      }
    }

    if (type == TransactionType.incoming) {
      // if (_transaction.isMinting) {
      //   return "Minting";
      // } else
      if (isConfirmed(currentChainHeight, minConfirms, minCoinbaseConfirms)) {
        return "Received";
      } else {
        return "Receiving ${prettyConfirms()}";
      }
    } else if (type == TransactionType.outgoing) {
      if (isConfirmed(currentChainHeight, minConfirms, minCoinbaseConfirms)) {
        return "Sent";
      } else {
        return "Sending ${prettyConfirms()}";
      }
    } else if (type == TransactionType.sentToSelf) {
      if (isConfirmed(currentChainHeight, minConfirms, minCoinbaseConfirms)) {
        return "Sent to self";
      } else {
        return "Sent to self ${prettyConfirms()}";
      }
    } else {
      return type.name;
    }
  }

  dynamic _getFromOtherData({required dynamic key}) {
    if (otherData == null) {
      return null;
    }
    final map = jsonDecode(otherData!);
    return map[key];
  }

  bool isCoinbase() =>
      type == TransactionType.incoming && inputs.any((e) => e.coinbase != null);

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

abstract final class TxV2OdKeys {
  static const size = "size";
  static const vSize = "vSize";
  static const isEpiccashTransaction = "isEpiccashTransaction";
  static const numberOfMessages = "numberOfMessages";
  static const slateId = "slateId";
  static const onChainNote = "onChainNote";
  static const isCancelled = "isCancelled";
  static const contractAddress = "contractAddress";
  static const nonce = "nonce";
  static const overrideFee = "overrideFee";
  static const moneroAmount = "moneroAmount";
  static const moneroAccountIndex = "moneroAccountIndex";
  static const isMoneroTransaction = "isMoneroTransaction";
}

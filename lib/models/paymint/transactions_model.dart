import 'package:dart_numerics/dart_numerics.dart';
import 'package:decimal/decimal.dart';
import 'package:hive/hive.dart';
import 'package:stackwallet/utilities/constants.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';

part '../type_adaptors/transactions_model.g.dart';

String extractDateFromTimestamp(int? timestamp) {
  if (timestamp == 0 || timestamp == null) {
    return 'Now...';
  }

  final int day = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000).day;
  final int month = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000).month;
  final int year = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000).year;

  return '$year${month < 10 ? "0$month" : month.toString()}${day < 10 ? "0$day" : day.toString()}';
}

// @HiveType(typeId: 1)
class TransactionData {
  // @HiveField(0)
  final List<TransactionChunk> txChunks;

  TransactionData({this.txChunks = const []});

  factory TransactionData.fromJson(Map<String, dynamic> json) {
    var dateTimeChunks = json['dateTimeChunks'] as List;
    List<TransactionChunk> chunksList = dateTimeChunks
        .map((txChunk) =>
            TransactionChunk.fromJson(txChunk as Map<String, dynamic>))
        .toList();

    return TransactionData(txChunks: chunksList);
  }

  factory TransactionData.fromMap(Map<String, Transaction> transactions) {
    Map<String, List<Transaction>> chunks = {};
    transactions.forEach((key, value) {
      String date = extractDateFromTimestamp(value.timestamp);
      if (!chunks.containsKey(date)) {
        chunks[date] = [];
      }
      chunks[date]!.add(value);
    });
    List<TransactionChunk> chunksList = [];
    chunks.forEach((key, value) {
      value.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      chunksList.add(
          TransactionChunk(timestamp: value[0].timestamp, transactions: value));
    });
    chunksList.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return TransactionData(txChunks: chunksList);
  }

  Transaction? findTransaction(String txid) {
    for (var i = 0; i < txChunks.length; i++) {
      var txChunk = txChunks[i].transactions;
      for (var j = 0; j < txChunk.length; j++) {
        var tx = txChunk[j];
        if (tx.txid == txid) {
          return tx;
        }
      }
    }
    return null;
  }

  Map<String, Transaction> getAllTransactions() {
    Map<String, Transaction> transactions = {};
    for (var i = 0; i < txChunks.length; i++) {
      var txChunk = txChunks[i].transactions;
      for (var j = 0; j < txChunk.length; j++) {
        var tx = txChunk[j];
        transactions[tx.txid] = tx;
      }
    }
    return transactions;
  }
}

// @HiveType(typeId: 2)
class TransactionChunk {
  // @HiveField(0)
  final int timestamp;
  // @HiveField(1)
  final List<Transaction> transactions;

  TransactionChunk({required this.timestamp, required this.transactions});

  factory TransactionChunk.fromJson(Map<String, dynamic> json) {
    var txArray = json['transactions'] as List;
    List<Transaction> txList = txArray
        .map((tx) => Transaction.fromJson(tx as Map<String, dynamic>))
        .toList();

    return TransactionChunk(
        timestamp: int.parse(json['timestamp'].toString()),
        transactions: txList);
  }

  @override
  String toString() {
    String transaction = "timestamp: $timestamp transactions: [\n";
    for (final tx in transactions) {
      transaction += "    $tx \n";
    }
    transaction += "]";

    return transaction;
  }
}

// @HiveType(typeId: 3)
class Transaction {
  // @HiveField(0)
  final String txid;
  // @HiveField(1)
  final bool confirmedStatus;
  // @HiveField(2)
  final int timestamp;
  // @HiveField(3)
  final String txType;
  // @HiveField(4)
  final int amount;
  // @HiveField(5)
  final List<dynamic> aliens;
  // @HiveField(6)
  final String worthNow;
  // @HiveField(7)
  final String worthAtBlockTimestamp;
  // @HiveField(8)
  final int fees;
  // @HiveField(9)
  final int inputSize;
  // @HiveField(10)
  final int outputSize;
  // @HiveField(11)
  final List<Input> inputs;
  // @HiveField(12)
  final List<Output> outputs;
  // @HiveField(13)
  final String address;
  // @HiveField(14)
  final int height;
  // @HiveField(15)
  final String subType;
  // @HiveField(16)
  final int confirmations;
  // @HiveField(17)
  final bool isCancelled;
  // @HiveField(18)
  final String? slateId;
  // @HiveField(18)
  final String? otherData;

  // @HiveField(16)
  final int? numberOfMessages;

  Transaction({
    required this.txid,
    required this.confirmedStatus,
    required this.timestamp,
    required this.txType,
    required this.amount,
    this.aliens = const [],
    required this.worthNow,
    required this.worthAtBlockTimestamp,
    required this.fees,
    required this.inputSize,
    required this.outputSize,
    required this.inputs,
    required this.outputs,
    required this.address,
    required this.height,
    this.subType = "",
    required this.confirmations,
    this.isCancelled = false,
    this.slateId,
    this.otherData,
    this.numberOfMessages,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    var inputArray = json['inputs'] as List;
    var outputArray = json['outputs'] as List;

    List<Input> inputList = inputArray
        .map((input) => Input.fromJson(Map<String, dynamic>.from(input as Map)))
        .toList();
    List<Output> outputList = outputArray
        .map((output) =>
            Output.fromJson(Map<String, dynamic>.from(output as Map)))
        .toList();

    return Transaction(
      txid: json['txid'] as String,
      confirmedStatus: json['confirmed_status'] as bool,
      timestamp: int.parse(json['timestamp'].toString()),
      txType: json['txType'] as String,
      amount: json['amount'] as int,
      aliens: json['aliens'] as List,
      worthNow: json['worthNow'] as String? ?? "",
      worthAtBlockTimestamp: json['worthAtBlockTimestamp'] as String? ?? "",
      fees: int.parse(json['fees'].toString()),
      inputSize: json['inputSize'] as int,
      outputSize: json['outputSize'] as int,
      inputs: inputList,
      outputs: outputList,
      address: json['address'] as String,
      height: json['height'] as int? ?? -1,
      subType: json["subType"] as String? ?? "",
      confirmations: json['confirmations'] as int? ?? 0,
      isCancelled: json["isCancelled"] as bool? ?? false,
      slateId: json["slateId"] as String?,
      otherData: json["otherData"] as String?,
      numberOfMessages: json["numberOfMessages"] as int?,
    );
  }

  factory Transaction.fromLelantusJson(Map<String, dynamic> json) {
    return Transaction(
      txid: json['txid'] as String,
      confirmedStatus: json['confirmed_status'] as bool? ?? false,
      timestamp: json['timestamp'] as int? ??
          (DateTime.now().millisecondsSinceEpoch ~/ 1000),
      txType: json['txType'] as String,
      amount: (Decimal.parse(json["amount"].toString()) *
              Decimal.fromInt(Constants.satsPerCoin(Coin
                  .firo))) // dirty hack but we need 8 decimal places here to keep consistent data structure
          .toBigInt()
          .toInt(),
      aliens: [],
      worthNow: json['worthNow'] as String,
      worthAtBlockTimestamp: json['worthAtBlockTimestamp'] as String? ?? "0",
      fees: (Decimal.parse(json["fees"].toString()) *
              Decimal.fromInt(Constants.satsPerCoin(Coin
                  .firo))) // dirty hack but we need 8 decimal places here to keep consistent data structure
          .toBigInt()
          .toInt(),
      inputSize: json['inputSize'] as int? ?? 0,
      outputSize: json['outputSize'] as int? ?? 0,
      inputs: [],
      outputs: [],
      address: json["address"] as String,
      height: json["height"] as int? ?? int64MaxValue,
      subType: json["subType"] as String? ?? "",
      confirmations: json["confirmations"] as int? ?? 0,
      otherData: json["otherData"] as String?,
    );
  }

  bool get isMinting => subType.toLowerCase() == "mint" && !confirmedStatus;

  Transaction copyWith({
    String? txid,
    bool? confirmedStatus,
    int? timestamp,
    String? txType,
    int? amount,
    List<dynamic>? aliens,
    String? worthNow,
    String? worthAtBlockTimestamp,
    int? fees,
    int? inputSize,
    int? outputSize,
    List<Input>? inputs,
    List<Output>? outputs,
    String? address,
    int? height,
    String? subType,
    int? confirmations,
    bool? isCancelled,
    String? slateId,
    String? otherData,
    int? numberOfMessages,
  }) {
    return Transaction(
      txid: txid ?? this.txid,
      confirmedStatus: confirmedStatus ?? this.confirmedStatus,
      timestamp: timestamp ?? this.timestamp,
      txType: txType ?? this.txType,
      amount: amount ?? this.amount,
      aliens: aliens ?? this.aliens,
      worthNow: worthNow ?? this.worthNow,
      worthAtBlockTimestamp:
          worthAtBlockTimestamp ?? this.worthAtBlockTimestamp,
      fees: fees ?? this.fees,
      inputSize: inputSize ?? this.inputSize,
      outputSize: outputSize ?? this.outputSize,
      inputs: inputs ?? this.inputs,
      outputs: outputs ?? this.outputs,
      address: address ?? this.address,
      height: height ?? this.height,
      subType: subType ?? this.subType,
      confirmations: confirmations ?? this.confirmations,
      isCancelled: isCancelled ?? this.isCancelled,
      slateId: slateId ?? this.slateId,
      otherData: otherData ?? this.otherData,
      numberOfMessages: numberOfMessages ?? this.numberOfMessages,
    );
  }

  @override
  String toString() {
    String transaction =
        "{txid: $txid, type: $txType, subType: $subType, value: $amount, fee: $fees, height: $height, confirm: $confirmedStatus, confirmations: $confirmations, address: $address, timestamp: $timestamp, worthNow: $worthNow, inputs: $inputs, slateid: $slateId, numberOfMessages: $numberOfMessages }";
    return transaction;
  }
}

// @HiveType(typeId: 4)
class Input {
  // @HiveField(0)
  final String txid;
  // @HiveField(1)
  final int vout;
  // // @HiveField(2)
  final Output? prevout;
  // @HiveField(3)
  final String? scriptsig;
  // @HiveField(4)
  final String? scriptsigAsm;
  // @HiveField(5)
  final List<dynamic>? witness;
  // @HiveField(6)
  final bool? isCoinbase;
  // @HiveField(7)
  final int? sequence;
  // @HiveField(8)
  final String? innerRedeemscriptAsm;

  Input({
    required this.txid,
    required this.vout,
    this.prevout,
    this.scriptsig,
    this.scriptsigAsm,
    this.witness,
    this.isCoinbase,
    this.sequence,
    this.innerRedeemscriptAsm,
  });

  factory Input.fromJson(Map<String, dynamic> json) {
    bool iscoinBase = json['coinbase'] != null;
    return Input(
      txid: json['txid'] as String? ?? "",
      vout: json['vout'] as int? ?? -1,
      // electrumx calls do not return prevout so we set this to null for now
      prevout: null, //Output.fromJson(json['prevout']),
      scriptsig: iscoinBase ? "" : json['scriptSig']['hex'] as String?,
      scriptsigAsm: iscoinBase ? "" : json['scriptSig']['asm'] as String?,
      witness: json['witness'] as List? ?? [],
      isCoinbase: iscoinBase ? iscoinBase : json['is_coinbase'] as bool?,
      sequence: json['sequence'] as int?,
      innerRedeemscriptAsm: json['innerRedeemscriptAsm'] as String? ?? "",
    );
  }

  @override
  String toString() {
    String transaction = "{txid: $txid}";
    return transaction;
  }
}

// @HiveType(typeId: 5)
class Output {
  // @HiveField(0)
  final String? scriptpubkey;

  // @HiveField(1)
  final String? scriptpubkeyAsm;

  // @HiveField(2)
  final String? scriptpubkeyType;

  // @HiveField(3)
  final String scriptpubkeyAddress;

  // @HiveField(4)
  final int value;

  Output(
      {this.scriptpubkey,
      this.scriptpubkeyAsm,
      this.scriptpubkeyType,
      required this.scriptpubkeyAddress,
      required this.value});

  factory Output.fromJson(Map<String, dynamic> json) {
    // TODO determine if any of this code is needed.
    try {
      final address = json["scriptPubKey"]["addresses"] == null
          ? json['scriptPubKey']['type'] as String
          : json["scriptPubKey"]["addresses"][0] as String;
      return Output(
        scriptpubkey: json['scriptPubKey']['hex'] as String?,
        scriptpubkeyAsm: json['scriptPubKey']['asm'] as String?,
        scriptpubkeyType: json['scriptPubKey']['type'] as String?,
        scriptpubkeyAddress: address,
        value: (Decimal.parse(
                    (json["value"] ?? 0).toString()) *
                Decimal.fromInt(Constants.satsPerCoin(Coin
                    .firo))) // dirty hack but we need 8 decimal places here to keep consistent data structure
            .toBigInt()
            .toInt(),
      );
    } catch (s, e) {
      return Output(
          // Return output object with null values; allows wallet history to be built
          scriptpubkey: "",
          scriptpubkeyAsm: "",
          scriptpubkeyType: "",
          scriptpubkeyAddress: "",
          value: (Decimal.parse(0.toString()) *
                  Decimal.fromInt(Constants.satsPerCoin(Coin
                      .firo))) // dirty hack but we need 8 decimal places here to keep consistent data structure
              .toBigInt()
              .toInt());
    }
  }
}

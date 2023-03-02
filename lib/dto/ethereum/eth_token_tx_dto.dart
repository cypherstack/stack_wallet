import 'package:stackwallet/utilities/logger.dart';

class EthTokenTxDTO {
  final String blockHash;
  final int blockNumber;
  final int confirmations;
  final String contractAddress;
  final int cumulativeGasUsed;
  final String from;
  final int gas;
  final BigInt gasPrice;
  final int gasUsed;
  final String hash;
  final String input;
  final int logIndex;
  final int nonce;
  final int timeStamp;
  final String to;
  final int tokenDecimal;
  final String tokenName;
  final String tokenSymbol;
  final int transactionIndex;
  final BigInt value;

  EthTokenTxDTO({
    required this.blockHash,
    required this.blockNumber,
    required this.confirmations,
    required this.contractAddress,
    required this.cumulativeGasUsed,
    required this.from,
    required this.gas,
    required this.gasPrice,
    required this.gasUsed,
    required this.hash,
    required this.input,
    required this.logIndex,
    required this.nonce,
    required this.timeStamp,
    required this.to,
    required this.tokenDecimal,
    required this.tokenName,
    required this.tokenSymbol,
    required this.transactionIndex,
    required this.value,
  });

  factory EthTokenTxDTO.fromMap({
    required Map<String, dynamic> map,
  }) {
    try {
      return EthTokenTxDTO(
        blockHash: map["blockHash"] as String,
        blockNumber: int.parse(map["blockNumber"] as String),
        confirmations: int.parse(map["confirmations"] as String),
        contractAddress: map["contractAddress"] as String,
        cumulativeGasUsed: int.parse(map["cumulativeGasUsed"] as String),
        from: map["from"] as String,
        gas: int.parse(map["gas"] as String),
        gasPrice: BigInt.parse(map["gasPrice"] as String),
        gasUsed: int.parse(map["gasUsed"] as String),
        hash: map["hash"] as String,
        input: map["input"] as String,
        logIndex: int.parse(map["logIndex"] as String? ?? "-1"),
        nonce: int.parse(map["nonce"] as String),
        timeStamp: int.parse(map["timeStamp"] as String),
        to: map["to"] as String,
        tokenDecimal: int.parse(map["tokenDecimal"] as String),
        tokenName: map["tokenName"] as String,
        tokenSymbol: map["tokenSymbol"] as String,
        transactionIndex: int.parse(map["transactionIndex"] as String),
        value: BigInt.parse(map["value"] as String),
      );
    } catch (e, s) {
      Logging.instance.log(
        "EthTokenTxDTO.fromMap() failed: $e\n$s",
        level: LogLevel.Fatal,
      );
      rethrow;
    }
  }
}

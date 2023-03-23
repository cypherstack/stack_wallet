import 'dart:convert';

class EthTokenTxExtraDTO {
  EthTokenTxExtraDTO({
    required this.blockHash,
    required this.blockNumber,
    required this.from,
    required this.gas,
    required this.gasCost,
    required this.gasPrice,
    required this.gasUsed,
    required this.hash,
    required this.input,
    required this.nonce,
    required this.timestamp,
    required this.to,
    required this.transactionIndex,
    required this.value,
  });

  factory EthTokenTxExtraDTO.fromMap(Map<String, dynamic> map) =>
      EthTokenTxExtraDTO(
        hash: map['hash'] as String,
        blockHash: map['blockHash'] as String,
        blockNumber: map['blockNumber'] as int,
        transactionIndex: map['transactionIndex'] as int,
        timestamp: map['timestamp'] as int,
        from: map['from'] as String,
        to: map['to'] as String,
        value: int.parse(map['value'] as String),
        gas: map['gas'] as int,
        gasPrice: map['gasPrice'] as int,
        nonce: map['nonce'] as int,
        input: map['input'] as String,
        gasCost: map['gasCost'] as int,
        gasUsed: map['gasUsed'] as int,
      );

  factory EthTokenTxExtraDTO.fromJsonString(String jsonString) =>
      EthTokenTxExtraDTO.fromMap(
        Map<String, dynamic>.from(
          jsonDecode(jsonString) as Map,
        ),
      );

  final String hash;
  final String blockHash;
  final int blockNumber;
  final int transactionIndex;
  final int timestamp;
  final String from;
  final String to;
  final int value;
  final int gas;
  final int gasPrice;
  final String input;
  final int nonce;
  final int gasCost;
  final int gasUsed;

  EthTokenTxExtraDTO copyWith({
    String? hash,
    String? blockHash,
    int? blockNumber,
    int? transactionIndex,
    int? timestamp,
    String? from,
    String? to,
    int? value,
    int? gas,
    int? gasPrice,
    int? nonce,
    String? input,
    int? gasCost,
    int? gasUsed,
  }) =>
      EthTokenTxExtraDTO(
        hash: hash ?? this.hash,
        blockHash: blockHash ?? this.blockHash,
        blockNumber: blockNumber ?? this.blockNumber,
        transactionIndex: transactionIndex ?? this.transactionIndex,
        timestamp: timestamp ?? this.timestamp,
        from: from ?? this.from,
        to: to ?? this.to,
        value: value ?? this.value,
        gas: gas ?? this.gas,
        gasPrice: gasPrice ?? this.gasPrice,
        nonce: nonce ?? this.nonce,
        input: input ?? this.input,
        gasCost: gasCost ?? this.gasCost,
        gasUsed: gasUsed ?? this.gasUsed,
      );

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{};
    map['hash'] = hash;
    map['blockHash'] = blockHash;
    map['blockNumber'] = blockNumber;
    map['transactionIndex'] = transactionIndex;
    map['timestamp'] = timestamp;
    map['from'] = from;
    map['to'] = to;
    map['value'] = value;
    map['gas'] = gas;
    map['gasPrice'] = gasPrice;
    map['input'] = input;
    map['nonce'] = nonce;
    map['gasCost'] = gasCost;
    map['gasUsed'] = gasUsed;
    return map;
  }

  @override
  String toString() => jsonEncode(toMap());
}

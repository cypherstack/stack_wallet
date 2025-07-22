import 'dart:math';

import 'package:isar/isar.dart';

part 'spark_coin.g.dart';

enum SparkCoinType {
  mint(0),
  spend(1);

  const SparkCoinType(this.value);

  final int value;
}

@Collection()
class SparkCoin {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true, composite: [CompositeIndex("lTagHash")])
  final String walletId;

  @enumerated
  final SparkCoinType type;

  final bool isUsed;
  final int groupId;

  final List<int>? nonce;

  final String address;
  final String txHash;

  final String valueIntString;

  final String? memo;
  final List<int>? serialContext;

  final String diversifierIntString;
  final List<int>? encryptedDiversifier;

  final List<int>? serial;
  final List<int>? tag;

  final String lTagHash;

  final int? height;

  final String? serializedCoinB64;
  final String? contextB64;

  // prefix name with zzz to ensure serialization order remains unchanged
  @Name("zzzIsLocked")
  final bool? isLocked;

  @ignore
  BigInt get value => BigInt.parse(valueIntString);

  @ignore
  BigInt get diversifier => BigInt.parse(diversifierIntString);

  int getConfirmations(int currentChainHeight) {
    if (height == null || height! <= 0) return 0;
    return max(0, currentChainHeight - (height! - 1));
  }

  bool isConfirmed(int currentChainHeight, int minimumConfirms) {
    final confirmations = getConfirmations(currentChainHeight);
    return confirmations >= minimumConfirms;
  }

  SparkCoin({
    required this.walletId,
    required this.type,
    required this.isUsed,
    required this.groupId,
    this.nonce,
    required this.address,
    required this.txHash,
    required this.valueIntString,
    this.memo,
    this.serialContext,
    required this.diversifierIntString,
    this.encryptedDiversifier,
    this.serial,
    this.tag,
    required this.lTagHash,
    this.height,
    this.serializedCoinB64,
    this.contextB64,
    this.isLocked,
  });

  SparkCoin copyWith({
    SparkCoinType? type,
    bool? isUsed,
    int? groupId,
    List<int>? nonce,
    String? address,
    String? txHash,
    BigInt? value,
    String? memo,
    List<int>? serialContext,
    BigInt? diversifier,
    List<int>? encryptedDiversifier,
    List<int>? serial,
    List<int>? tag,
    String? lTagHash,
    int? height,
    String? serializedCoinB64,
    String? contextB64,
    bool? isLocked,
  }) {
    return SparkCoin(
      walletId: walletId,
      type: type ?? this.type,
      isUsed: isUsed ?? this.isUsed,
      groupId: groupId ?? this.groupId,
      nonce: nonce ?? this.nonce,
      address: address ?? this.address,
      txHash: txHash ?? this.txHash,
      valueIntString: value?.toString() ?? this.value.toString(),
      memo: memo ?? this.memo,
      serialContext: serialContext ?? this.serialContext,
      diversifierIntString:
          diversifier?.toString() ?? this.diversifier.toString(),
      encryptedDiversifier: encryptedDiversifier ?? this.encryptedDiversifier,
      serial: serial ?? this.serial,
      tag: tag ?? this.tag,
      lTagHash: lTagHash ?? this.lTagHash,
      height: height ?? this.height,
      serializedCoinB64: serializedCoinB64 ?? this.serializedCoinB64,
      contextB64: contextB64 ?? this.contextB64,
      isLocked: isLocked ?? this.isLocked,
    );
  }

  @override
  String toString() {
    return 'SparkCoin('
        'walletId: $walletId'
        ', type: $type'
        ', isUsed: $isUsed'
        ', groupId: $groupId'
        ', k: $nonce'
        ', address: $address'
        ', txHash: $txHash'
        ', value: $value'
        ', memo: $memo'
        ', serialContext: $serialContext'
        ', diversifier: $diversifier'
        ', encryptedDiversifier: $encryptedDiversifier'
        ', serial: $serial'
        ', tag: $tag'
        ', lTagHash: $lTagHash'
        ', height: $height'
        ', serializedCoinB64: $serializedCoinB64'
        ', contextB64: $contextB64'
        ', isLocked: $isLocked'
        ')';
  }
}

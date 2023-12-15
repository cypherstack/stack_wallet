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

  @Index(
    unique: true,
    replace: true,
    composite: [
      CompositeIndex("lTagHash"),
    ],
  )
  final String walletId;

  @enumerated
  final SparkCoinType type;

  final bool isUsed;

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

  @ignore
  BigInt get value => BigInt.parse(valueIntString);

  @ignore
  BigInt get diversifier => BigInt.parse(diversifierIntString);

  SparkCoin({
    required this.walletId,
    required this.type,
    required this.isUsed,
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
  });

  SparkCoin copyWith({
    SparkCoinType? type,
    bool? isUsed,
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
  }) {
    return SparkCoin(
      walletId: walletId,
      type: type ?? this.type,
      isUsed: isUsed ?? this.isUsed,
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
    );
  }

  @override
  String toString() {
    return 'SparkCoin('
        'walletId: $walletId'
        ', type: $type'
        ', isUsed: $isUsed'
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
        ')';
  }
}

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

  final List<int>? k; // TODO: proper name (not single char!!) is this nonce???

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

  @ignore
  BigInt get value => BigInt.parse(valueIntString);

  @ignore
  BigInt get diversifier => BigInt.parse(diversifierIntString);

  SparkCoin({
    required this.walletId,
    required this.type,
    required this.isUsed,
    this.k,
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
  });

  SparkCoin copyWith({
    SparkCoinType? type,
    bool? isUsed,
    List<int>? k,
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
  }) {
    return SparkCoin(
      walletId: walletId,
      type: type ?? this.type,
      isUsed: isUsed ?? this.isUsed,
      k: k ?? this.k,
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
    );
  }

  @override
  String toString() {
    return 'SparkCoin('
        ', walletId: $walletId'
        ', type: $type'
        ', isUsed: $isUsed'
        ', k: $k'
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
        ')';
  }
}

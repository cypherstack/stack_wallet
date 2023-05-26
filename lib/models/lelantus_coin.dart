import 'package:hive/hive.dart';

part 'type_adaptors/lelantus_coin.g.dart';

// @HiveType(typeId: 9)
class LelantusCoin {
  // @HiveField(0)
  int index;
  // @HiveField(1)
  int value;
  // @HiveField(2)
  String publicCoin;
  // @HiveField(3)
  String txId;
  // @HiveField(4)
  int anonymitySetId;
  // @HiveField(5)
  bool isUsed;

  LelantusCoin(
    this.index,
    this.value,
    this.publicCoin,
    this.txId,
    this.anonymitySetId,
    this.isUsed,
  );

  @override
  String toString() {
    String coin =
        "{index: $index, value: $value, publicCoin: $publicCoin, txId: $txId, anonymitySetId: $anonymitySetId, isUsed: $isUsed}";
    return coin;
  }
}

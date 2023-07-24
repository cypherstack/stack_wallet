import 'package:isar/isar.dart';

part 'lelantus_coin.g.dart';

@collection
class LelantusCoin {
  Id id = Isar.autoIncrement;

  @Index()
  final String walletId;

  @Index(
    unique: true,
    composite: [
      CompositeIndex("walletId"),
      CompositeIndex("txid"),
    ],
    replace: false,
  )
  final String publicCoin;

  final String txid;

  final String value; // can't use BigInt in isar :shrug:

  final int index;

  final int anonymitySetId;

  final bool isUsed;

  LelantusCoin({
    required this.walletId,
    required this.publicCoin,
    required this.txid,
    required this.value,
    required this.index,
    required this.anonymitySetId,
    required this.isUsed,
  });

  LelantusCoin copyWith({
    String? walletId,
    String? publicCoin,
    String? txid,
    String? value,
    int? index,
    int? anonymitySetId,
    bool? isUsed,
  }) {
    return LelantusCoin(
      walletId: walletId ?? this.walletId,
      publicCoin: publicCoin ?? this.publicCoin,
      txid: txid ?? this.txid,
      value: value ?? this.value,
      index: index ?? this.index,
      anonymitySetId: anonymitySetId ?? this.anonymitySetId,
      isUsed: isUsed ?? this.isUsed,
    );
  }

  @override
  String toString() {
    return 'LelantusCoin{'
        'id: $id, '
        'walletId: $walletId, '
        'publicCoin: $publicCoin, '
        'txid: $txid, '
        'value: $value, '
        'index: $index, '
        'anonymitySetId: $anonymitySetId, '
        'isUsed: $isUsed'
        '}';
  }
}

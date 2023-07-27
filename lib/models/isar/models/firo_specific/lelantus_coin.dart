import 'package:isar/isar.dart';

part 'lelantus_coin.g.dart';

@collection
class LelantusCoin {
  Id id = Isar.autoIncrement;

  @Index()
  final String walletId;

  final String txid;

  final String value; // can't use BigInt in isar :shrug:

  @Index(
    unique: true,
    replace: false,
    composite: [
      CompositeIndex("walletId"),
    ],
  )
  final int mintIndex;

  final int anonymitySetId;

  final bool isUsed;

  final bool isJMint;

  final String? otherData;

  LelantusCoin({
    required this.walletId,
    required this.txid,
    required this.value,
    required this.mintIndex,
    required this.anonymitySetId,
    required this.isUsed,
    required this.isJMint,
    required this.otherData,
  });

  LelantusCoin copyWith({
    String? walletId,
    String? publicCoin,
    String? txid,
    String? value,
    int? mintIndex,
    int? anonymitySetId,
    bool? isUsed,
    bool? isJMint,
    String? otherData,
  }) {
    return LelantusCoin(
      walletId: walletId ?? this.walletId,
      txid: txid ?? this.txid,
      value: value ?? this.value,
      mintIndex: mintIndex ?? this.mintIndex,
      anonymitySetId: anonymitySetId ?? this.anonymitySetId,
      isUsed: isUsed ?? this.isUsed,
      isJMint: isJMint ?? this.isJMint,
      otherData: otherData ?? this.otherData,
    );
  }

  @override
  String toString() {
    return 'LelantusCoin{'
        'id: $id, '
        'walletId: $walletId, '
        'txid: $txid, '
        'value: $value, '
        'mintIndex: $mintIndex, '
        'anonymitySetId: $anonymitySetId, '
        'otherData: $otherData, '
        'isJMint: $isJMint, '
        'isUsed: $isUsed'
        '}';
  }
}

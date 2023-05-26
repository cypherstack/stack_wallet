import 'package:hive/hive.dart';

part 'type_adaptors/trade_wallet_lookup.g.dart';

// @HiveType(typeId: 21)
class TradeWalletLookup {
  // @HiveField(0)
  final String uuid;
  // @HiveField(1)
  final String txid;
  // @HiveField(2)
  final String tradeId;
  // @HiveField(3)
  final List<String> walletIds;

  TradeWalletLookup({
    required this.uuid,
    required this.txid,
    required this.tradeId,
    required this.walletIds,
  });

  TradeWalletLookup copyWith({
    String? txid,
    String? tradeId,
    List<String>? walletIds,
  }) {
    return TradeWalletLookup(
      uuid: uuid,
      txid: txid ?? this.txid,
      tradeId: tradeId ?? this.tradeId,
      walletIds: walletIds ?? this.walletIds,
    );
  }

  factory TradeWalletLookup.fromJson(Map<String, dynamic> json) {
    return TradeWalletLookup(
      uuid: json["uuid"] as String,
      txid: json["txid"] as String,
      tradeId: json["tradeId"] as String,
      walletIds: List<String>.from(json["walletIds"] as List),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      "uuid": uuid,
      "txid": txid,
      "tradeId": tradeId,
      "walletIds": walletIds,
    };
  }

  @override
  String toString() {
    return toMap().toString();
  }
}

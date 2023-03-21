import 'dart:convert';

import 'package:decimal/decimal.dart';
import 'package:stackduo/utilities/enums/coin_enum.dart';
import 'package:stackduo/utilities/format.dart';

class Balance {
  final Coin coin;
  final int total;
  final int spendable;
  final int blockedTotal;
  final int pendingSpendable;

  Balance({
    required this.coin,
    required this.total,
    required this.spendable,
    required this.blockedTotal,
    required this.pendingSpendable,
  });

  Decimal getTotal({bool includeBlocked = true}) => Format.satoshisToAmount(
        includeBlocked ? total : total - blockedTotal,
        coin: coin,
      );

  Decimal getSpendable() => Format.satoshisToAmount(
        spendable,
        coin: coin,
      );

  Decimal getPending() => Format.satoshisToAmount(
        pendingSpendable,
        coin: coin,
      );

  Decimal getBlocked() => Format.satoshisToAmount(
        blockedTotal,
        coin: coin,
      );

  String toJsonIgnoreCoin() => jsonEncode(toMap()..remove("coin"));

  factory Balance.fromJson(String json, Coin coin) {
    final decoded = jsonDecode(json);
    return Balance(
      coin: coin,
      total: decoded["total"] as int,
      spendable: decoded["spendable"] as int,
      blockedTotal: decoded["blockedTotal"] as int,
      pendingSpendable: decoded["pendingSpendable"] as int,
    );
  }

  Map<String, dynamic> toMap() => {
        "coin": coin,
        "total": total,
        "spendable": spendable,
        "blockedTotal": blockedTotal,
        "pendingSpendable": pendingSpendable,
      };

  @override
  String toString() {
    return toMap().toString();
  }
}

import 'dart:convert';

import 'package:stackwallet/utilities/amount.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';

enum Unit {
  base,
  u,
  m,
  normal;
}

class Balance {
  final Coin coin;
  final Amount total;
  final Amount spendable;
  final Amount blockedTotal;
  final Amount pendingSpendable;

  Balance({
    required this.coin,
    required this.total,
    required this.spendable,
    required this.blockedTotal,
    required this.pendingSpendable,
  });

  // Decimal getTotal({bool includeBlocked = true}) => Format.satoshisToAmount(
  //       includeBlocked ? total : total - blockedTotal,
  //       coin: coin,
  //     );
  //
  // Decimal getSpendable() => Format.satoshisToAmount(
  //       spendable,
  //       coin: coin,
  //     );
  //
  // Decimal getPending() => Format.satoshisToAmount(
  //       pendingSpendable,
  //       coin: coin,
  //     );
  //
  // Decimal getBlocked() => Format.satoshisToAmount(
  //       blockedTotal,
  //       coin: coin,
  //     );

  String toJsonIgnoreCoin() => jsonEncode({
        "total": total.toJsonString(),
        "spendable": spendable.toJsonString(),
        "blockedTotal": blockedTotal.toJsonString(),
        "pendingSpendable": pendingSpendable.toJsonString(),
      });

  // need to fall back to parsing from in due to cached balances being previously
  // stored as int values instead of Amounts
  factory Balance.fromJson(String json, Coin coin) {
    final decoded = jsonDecode(json);
    return Balance(
      coin: coin,
      total: decoded["total"] is String
          ? Amount.fromSerializedJsonString(decoded["total"] as String)
          : Amount(
              rawValue: BigInt.from(decoded["total"] as int),
              fractionDigits: coin.decimals,
            ),
      spendable: decoded["spendable"] is String
          ? Amount.fromSerializedJsonString(decoded["spendable"] as String)
          : Amount(
              rawValue: BigInt.from(decoded["spendable"] as int),
              fractionDigits: coin.decimals,
            ),
      blockedTotal: decoded["blockedTotal"] is String
          ? Amount.fromSerializedJsonString(decoded["blockedTotal"] as String)
          : Amount(
              rawValue: BigInt.from(decoded["blockedTotal"] as int),
              fractionDigits: coin.decimals,
            ),
      pendingSpendable: decoded["pendingSpendable"] is String
          ? Amount.fromSerializedJsonString(
              decoded["pendingSpendable"] as String)
          : Amount(
              rawValue: BigInt.from(decoded["pendingSpendable"] as int),
              fractionDigits: coin.decimals,
            ),
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

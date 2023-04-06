import 'dart:convert';

import 'package:stackwallet/models/balance.dart';
import 'package:stackwallet/utilities/amount/amount.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';

class TokenBalance extends Balance {
  TokenBalance({
    required this.contractAddress,
    required super.total,
    required super.spendable,
    required super.blockedTotal,
    required super.pendingSpendable,
    super.coin = Coin.ethereum,
  });

  final String contractAddress;

  // @override
  // Decimal getTotal({bool includeBlocked = false}) =>
  //     Format.satoshisToEthTokenAmount(
  //       includeBlocked ? total : total - blockedTotal,
  //       decimalPlaces,
  //     );
  //
  // @override
  // Decimal getSpendable() => Format.satoshisToEthTokenAmount(
  //       spendable,
  //       decimalPlaces,
  //     );
  //
  // @override
  // Decimal getPending() => Format.satoshisToEthTokenAmount(
  //       pendingSpendable,
  //       decimalPlaces,
  //     );
  //
  // @override
  // Decimal getBlocked() => Format.satoshisToEthTokenAmount(
  //       blockedTotal,
  //       decimalPlaces,
  //     );

  @override
  String toJsonIgnoreCoin() => jsonEncode({
        "contractAddress": contractAddress,
        "total": total,
        "spendable": spendable,
        "blockedTotal": blockedTotal,
        "pendingSpendable": pendingSpendable,
      });

  factory TokenBalance.fromJson(
    String json,
    int fractionDigits,
  ) {
    final decoded = jsonDecode(json);
    return TokenBalance(
      contractAddress: decoded["contractAddress"] as String,
      total: decoded["total"] is String
          ? Amount.fromSerializedJsonString(decoded["total"] as String)
          : Amount(
              rawValue: BigInt.from(decoded["total"] as int),
              fractionDigits: fractionDigits,
            ),
      spendable: decoded["spendable"] is String
          ? Amount.fromSerializedJsonString(decoded["spendable"] as String)
          : Amount(
              rawValue: BigInt.from(decoded["spendable"] as int),
              fractionDigits: fractionDigits,
            ),
      blockedTotal: decoded["blockedTotal"] is String
          ? Amount.fromSerializedJsonString(decoded["blockedTotal"] as String)
          : Amount(
              rawValue: BigInt.from(decoded["blockedTotal"] as int),
              fractionDigits: fractionDigits,
            ),
      pendingSpendable: decoded["pendingSpendable"] is String
          ? Amount.fromSerializedJsonString(
              decoded["pendingSpendable"] as String)
          : Amount(
              rawValue: BigInt.from(decoded["pendingSpendable"] as int),
              fractionDigits: fractionDigits,
            ),
    );
  }
}

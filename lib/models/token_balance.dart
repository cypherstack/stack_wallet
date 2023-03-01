import 'dart:convert';

import 'package:decimal/decimal.dart';
import 'package:stackwallet/models/balance.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/utilities/format.dart';

class TokenBalance extends Balance {
  TokenBalance({
    required this.contractAddress,
    required this.decimalPlaces,
    required super.total,
    required super.spendable,
    required super.blockedTotal,
    required super.pendingSpendable,
    super.coin = Coin.ethereum,
  });

  final String contractAddress;
  final int decimalPlaces;

  @override
  Decimal getTotal({bool includeBlocked = false}) =>
      Format.satoshisToEthTokenAmount(
        includeBlocked ? total : total - blockedTotal,
        decimalPlaces,
      );

  @override
  Decimal getSpendable() => Format.satoshisToEthTokenAmount(
        spendable,
        decimalPlaces,
      );

  @override
  Decimal getPending() => Format.satoshisToEthTokenAmount(
        pendingSpendable,
        decimalPlaces,
      );

  @override
  Decimal getBlocked() => Format.satoshisToEthTokenAmount(
        blockedTotal,
        decimalPlaces,
      );

  @override
  String toJsonIgnoreCoin() => jsonEncode({
        "contractAddress": contractAddress,
        "decimalPlaces": decimalPlaces,
        "total": total,
        "spendable": spendable,
        "blockedTotal": blockedTotal,
        "pendingSpendable": pendingSpendable,
      });

  factory TokenBalance.fromJson(
    String json,
  ) {
    final decoded = jsonDecode(json);
    return TokenBalance(
      contractAddress: decoded["contractAddress"] as String,
      decimalPlaces: decoded["decimalPlaces"] as int,
      total: decoded["total"] as int,
      spendable: decoded["spendable"] as int,
      blockedTotal: decoded["blockedTotal"] as int,
      pendingSpendable: decoded["pendingSpendable"] as int,
    );
  }
}

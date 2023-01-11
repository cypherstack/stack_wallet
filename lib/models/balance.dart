import 'package:decimal/decimal.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/utilities/format.dart';

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

  Decimal getTotal({bool includeBlocked = false}) => Format.satoshisToAmount(
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
}

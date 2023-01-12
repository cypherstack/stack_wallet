import 'package:stackwallet/hive/db.dart';
import 'package:stackwallet/models/balance.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';

mixin WalletCache {
  Balance getCachedBalance(String walletId, Coin coin) {
    final jsonString = DB.instance.get<dynamic>(
      boxName: walletId,
      key: DBKeys.cachedBalance,
    ) as String?;
    if (jsonString == null) {
      return Balance(
        coin: coin,
        total: 0,
        spendable: 0,
        blockedTotal: 0,
        pendingSpendable: 0,
      );
    }
    return Balance.fromJson(jsonString, coin);
  }

  Future<void> updateCachedBalance(String walletId, Balance balance) async {
    await DB.instance.put<dynamic>(
      boxName: walletId,
      key: DBKeys.cachedBalance,
      value: balance.toJsonIgnoreCoin(),
    );
  }
}

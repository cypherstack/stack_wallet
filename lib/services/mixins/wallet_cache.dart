import 'package:stackwallet/db/hive/db.dart';
import 'package:stackwallet/models/balance.dart';
import 'package:stackwallet/utilities/amount/amount.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';

mixin WalletCache {
  late final String _walletId;
  late final Coin _coin;

  void initCache(String walletId, Coin coin) {
    _walletId = walletId;
    _coin = coin;
  }

  // cached wallet id
  String? getCachedId() {
    return DB.instance.get<dynamic>(
      boxName: _walletId,
      key: DBKeys.id,
    ) as String?;
  }

  Future<void> updateCachedId(String? id) async {
    await DB.instance.put<dynamic>(
      boxName: _walletId,
      key: DBKeys.id,
      value: id,
    );
  }

  // cached Chain Height
  int getCachedChainHeight() {
    return DB.instance.get<dynamic>(
          boxName: _walletId,
          key: DBKeys.storedChainHeight,
        ) as int? ??
        0;
  }

  Future<void> updateCachedChainHeight(int height) async {
    await DB.instance.put<dynamic>(
      boxName: _walletId,
      key: DBKeys.storedChainHeight,
      value: height,
    );
  }

  // wallet favorite flag
  bool getCachedIsFavorite() {
    return DB.instance.get<dynamic>(
          boxName: _walletId,
          key: DBKeys.isFavorite,
        ) as bool? ??
        false;
  }

  Future<void> updateCachedIsFavorite(bool isFavorite) async {
    await DB.instance.put<dynamic>(
      boxName: _walletId,
      key: DBKeys.isFavorite,
      value: isFavorite,
    );
  }

  // main balance cache
  Balance getCachedBalance() {
    final jsonString = DB.instance.get<dynamic>(
      boxName: _walletId,
      key: DBKeys.cachedBalance,
    ) as String?;
    if (jsonString == null) {
      return Balance(
        total: Amount(rawValue: BigInt.zero, fractionDigits: _coin.decimals),
        spendable:
            Amount(rawValue: BigInt.zero, fractionDigits: _coin.decimals),
        blockedTotal:
            Amount(rawValue: BigInt.zero, fractionDigits: _coin.decimals),
        pendingSpendable:
            Amount(rawValue: BigInt.zero, fractionDigits: _coin.decimals),
      );
    }
    return Balance.fromJson(jsonString, _coin.decimals);
  }

  Future<void> updateCachedBalance(Balance balance) async {
    await DB.instance.put<dynamic>(
      boxName: _walletId,
      key: DBKeys.cachedBalance,
      value: balance.toJsonIgnoreCoin(),
    );
  }

  // secondary balance cache for coins such as firo
  Balance getCachedBalanceSecondary() {
    final jsonString = DB.instance.get<dynamic>(
      boxName: _walletId,
      key: DBKeys.cachedBalanceSecondary,
    ) as String?;
    if (jsonString == null) {
      return Balance(
        total: Amount(rawValue: BigInt.zero, fractionDigits: _coin.decimals),
        spendable:
            Amount(rawValue: BigInt.zero, fractionDigits: _coin.decimals),
        blockedTotal:
            Amount(rawValue: BigInt.zero, fractionDigits: _coin.decimals),
        pendingSpendable:
            Amount(rawValue: BigInt.zero, fractionDigits: _coin.decimals),
      );
    }
    return Balance.fromJson(jsonString, _coin.decimals);
  }

  Future<void> updateCachedBalanceSecondary(Balance balance) async {
    await DB.instance.put<dynamic>(
      boxName: _walletId,
      key: DBKeys.cachedBalanceSecondary,
      value: balance.toJsonIgnoreCoin(),
    );
  }

  // Ethereum specific
  List<String> getWalletTokenContractAddresses() {
    return DB.instance.get<dynamic>(
          boxName: _walletId,
          key: DBKeys.ethTokenContracts,
        ) as List<String>? ??
        [];
  }

  Future<void> updateWalletTokenContractAddresses(
      List<String> contractAddresses) async {
    await DB.instance.put<dynamic>(
      boxName: _walletId,
      key: DBKeys.ethTokenContracts,
      value: contractAddresses,
    );
  }
}

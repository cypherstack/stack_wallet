import 'package:stackwallet/db/hive/db.dart';
import 'package:stackwallet/models/isar/models/ethereum/eth_contract.dart';
import 'package:stackwallet/models/token_balance.dart';
import 'package:stackwallet/utilities/amount.dart';

abstract class TokenCacheKeys {
  static String tokenBalance(String contractAddress) {
    return "tokenBalanceCache_$contractAddress";
  }
}

mixin EthTokenCache {
  late final String _walletId;
  late final EthContract _token;

  void initCache(String walletId, EthContract token) {
    _walletId = walletId;
    _token = token;
  }

  // token balance cache
  TokenBalance getCachedBalance() {
    final jsonString = DB.instance.get<dynamic>(
      boxName: _walletId,
      key: TokenCacheKeys.tokenBalance(_token.address),
    ) as String?;
    if (jsonString == null) {
      return TokenBalance(
        contractAddress: _token.address,
        total: Amount(
          rawValue: BigInt.zero,
          fractionDigits: _token.decimals,
        ),
        spendable: Amount(
          rawValue: BigInt.zero,
          fractionDigits: _token.decimals,
        ),
        blockedTotal: Amount(
          rawValue: BigInt.zero,
          fractionDigits: _token.decimals,
        ),
        pendingSpendable: Amount(
          rawValue: BigInt.zero,
          fractionDigits: _token.decimals,
        ),
      );
    }
    return TokenBalance.fromJson(
      jsonString,
      _token.decimals,
    );
  }

  Future<void> updateCachedBalance(TokenBalance balance) async {
    await DB.instance.put<dynamic>(
      boxName: _walletId,
      key: TokenCacheKeys.tokenBalance(_token.address),
      value: balance.toJsonIgnoreCoin(),
    );
  }
}

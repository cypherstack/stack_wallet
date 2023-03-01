import 'package:stackwallet/hive/db.dart';
import 'package:stackwallet/models/ethereum/eth_token.dart';
import 'package:stackwallet/models/token_balance.dart';

abstract class _Keys {
  static String tokenBalance(String contractAddress) {
    return "tokenBalanceCache_$contractAddress";
  }
}

mixin EthTokenCache {
  late final String _walletId;
  late final EthContractInfo _token;

  void initCache(String walletId, EthContractInfo token) {
    _walletId = walletId;
    _token = token;
  }

  // token balance cache
  TokenBalance getCachedBalance() {
    final jsonString = DB.instance.get<dynamic>(
      boxName: _walletId,
      key: _Keys.tokenBalance(_token.contractAddress),
    ) as String?;
    if (jsonString == null) {
      return TokenBalance(
        contractAddress: _token.contractAddress,
        decimalPlaces: _token.decimals,
        total: 0,
        spendable: 0,
        blockedTotal: 0,
        pendingSpendable: 0,
      );
    }
    return TokenBalance.fromJson(
      jsonString,
    );
  }

  Future<void> updateCachedBalance(TokenBalance balance) async {
    await DB.instance.put<dynamic>(
      boxName: _walletId,
      key: _Keys.tokenBalance(_token.contractAddress),
      value: balance.toJsonIgnoreCoin(),
    );
  }
}

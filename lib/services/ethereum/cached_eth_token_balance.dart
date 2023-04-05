import 'package:stackwallet/models/isar/models/ethereum/eth_contract.dart';
import 'package:stackwallet/models/token_balance.dart';
import 'package:stackwallet/services/ethereum/ethereum_api.dart';
import 'package:stackwallet/services/mixins/eth_token_cache.dart';
import 'package:stackwallet/utilities/amount.dart';
import 'package:stackwallet/utilities/logger.dart';

class CachedEthTokenBalance with EthTokenCache {
  final String walletId;
  final EthContract token;

  CachedEthTokenBalance(this.walletId, this.token) {
    initCache(walletId, token);
  }

  Future<void> fetchAndUpdateCachedBalance(String address) async {
    final response = await EthereumAPI.getWalletTokenBalance(
      address: address,
      contractAddress: token.address,
    );

    if (response.value != null) {
      await updateCachedBalance(
        TokenBalance(
          contractAddress: token.address,
          total: Amount(
            rawValue: BigInt.from(response.value!),
            fractionDigits: token.decimals,
          ),
          spendable: Amount(
            rawValue: BigInt.from(response.value!),
            fractionDigits: token.decimals,
          ),
          blockedTotal: Amount(
            rawValue: BigInt.zero,
            fractionDigits: token.decimals,
          ),
          pendingSpendable: Amount(
            rawValue: BigInt.zero,
            fractionDigits: token.decimals,
          ),
        ),
      );
    } else {
      Logging.instance.log(
        "CachedEthTokenBalance.fetchAndUpdateCachedBalance failed: ${response.exception}",
        level: LogLevel.Warning,
      );
    }
  }
}

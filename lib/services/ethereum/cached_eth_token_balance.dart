import 'package:stackwallet/models/ethereum/eth_token.dart';
import 'package:stackwallet/models/token_balance.dart';
import 'package:stackwallet/services/ethereum/ethereum_api.dart';
import 'package:stackwallet/services/mixins/eth_token_cache.dart';
import 'package:stackwallet/utilities/logger.dart';

class CachedEthTokenBalance with EthTokenCache {
  final String walletId;
  final EthContractInfo token;

  CachedEthTokenBalance(this.walletId, this.token) {
    initCache(walletId, token);
  }

  Future<void> fetchAndUpdateCachedBalance(String address) async {
    final response = await EthereumAPI.getWalletTokenBalance(
      address: address,
      contractAddress: token.contractAddress,
    );

    if (response.value != null) {
      await updateCachedBalance(
        TokenBalance(
          contractAddress: token.contractAddress,
          decimalPlaces: token.decimals,
          total: response.value!,
          spendable: response.value!,
          blockedTotal: 0,
          pendingSpendable: 0,
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

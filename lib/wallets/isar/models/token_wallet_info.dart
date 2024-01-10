import 'package:isar/isar.dart';
import 'package:stackwallet/models/balance.dart';
import 'package:stackwallet/models/isar/models/isar_models.dart';
import 'package:stackwallet/utilities/amount/amount.dart';
import 'package:stackwallet/wallets/isar/isar_id_interface.dart';

part 'token_wallet_info.g.dart';

@Collection(accessor: "tokenWalletInfo", inheritance: false)
class TokenWalletInfo implements IsarId {
  @override
  Id id = Isar.autoIncrement;

  @Index(
    unique: true,
    replace: false,
    composite: [
      CompositeIndex("tokenAddress"),
    ],
  )
  final String walletId;

  final String tokenAddress;

  final int tokenFractionDigits;

  final String? cachedBalanceJsonString;

  TokenWalletInfo({
    required this.walletId,
    required this.tokenAddress,
    required this.tokenFractionDigits,
    this.cachedBalanceJsonString,
  });

  EthContract getContract(Isar isar) =>
      isar.ethContracts.where().addressEqualTo(tokenAddress).findFirstSync()!;

  // token balance cache
  Balance getCachedBalance() {
    if (cachedBalanceJsonString == null) {
      return Balance(
        total: Amount.zeroWith(
          fractionDigits: tokenFractionDigits,
        ),
        spendable: Amount.zeroWith(
          fractionDigits: tokenFractionDigits,
        ),
        blockedTotal: Amount.zeroWith(
          fractionDigits: tokenFractionDigits,
        ),
        pendingSpendable: Amount.zeroWith(
          fractionDigits: tokenFractionDigits,
        ),
      );
    }
    return Balance.fromJson(
      cachedBalanceJsonString!,
      tokenFractionDigits,
    );
  }

  Future<void> updateCachedBalance(
    Balance balance, {
    required Isar isar,
  }) async {
    // // ensure we are updating using the latest entry of this in the db
    final thisEntry = await isar.tokenWalletInfo
        .where()
        .walletIdEqualToTokenAddressNotEqualTo(walletId, tokenAddress)
        .findFirst();
    if (thisEntry == null) {
      throw Exception(
        "Attempted to update cached token balance before object was saved in db",
      );
    } else {
      await isar.writeTxn(() async {
        await isar.tokenWalletInfo.deleteByWalletIdTokenAddress(
          walletId,
          tokenAddress,
        );
        await isar.tokenWalletInfo.put(
          TokenWalletInfo(
            walletId: walletId,
            tokenAddress: tokenAddress,
            tokenFractionDigits: tokenFractionDigits,
            cachedBalanceJsonString: balance.toJsonIgnoreCoin(),
          ),
        );
      });
    }
  }
}

/*
 * This file is part of Stack Wallet.
 *
 * Copyright (c) 2025 Cypher Stack
 * All Rights Reserved.
 * The code is distributed under GPLv3 license, see LICENSE file for details.
 *
 */

import 'package:isar_community/isar.dart';

import '../../../models/balance.dart';
import '../../../models/isar/models/isar_models.dart';
import '../../../utilities/amount/amount.dart';
import '../isar_id_interface.dart';

part 'wallet_solana_token_info.g.dart';

@Collection(accessor: "walletSolanaTokenInfo", inheritance: false)
class WalletSolanaTokenInfo implements IsarId {
  @override
  Id id = Isar.autoIncrement;

  @Index(
    unique: true,
    replace: false,
    composite: [CompositeIndex("tokenAddress")],
  )
  final String walletId;

  final String tokenAddress; // Mint address.

  final int tokenFractionDigits;

  final String? cachedBalanceJsonString;

  WalletSolanaTokenInfo({
    required this.walletId,
    required this.tokenAddress,
    required this.tokenFractionDigits,
    this.cachedBalanceJsonString,
  });

  SolContract getToken(Isar isar) =>
      isar.solContracts.where().addressEqualTo(tokenAddress).findFirstSync()!;

  // Token balance cache.
  Balance getCachedBalance() {
    if (cachedBalanceJsonString == null) {
      final amount = Amount(
        rawValue: BigInt.zero,
        fractionDigits: tokenFractionDigits,
      );
      return Balance(
        total: amount,
        spendable: amount,
        blockedTotal: amount,
        pendingSpendable: amount,
      );
    }
    return Balance.fromJson(cachedBalanceJsonString!, tokenFractionDigits);
  }

  Future<void> updateCachedBalance(
    Balance balance, {
    required Isar isar,
  }) async {
    // Ensure we are updating using the latest entry of this in the db.
    final thisEntry =
        await isar.walletSolanaTokenInfo
            .where()
            .walletIdTokenAddressEqualTo(walletId, tokenAddress)
            .findFirst();
    if (thisEntry == null) {
      throw Exception(
        "Attempted to update cached token balance before object was saved in db",
      );
    } else {
      await isar.writeTxn(() async {
        await isar.walletSolanaTokenInfo.delete(thisEntry.id);
        await isar.walletSolanaTokenInfo.put(
          WalletSolanaTokenInfo(
            walletId: walletId,
            tokenAddress: tokenAddress,
            tokenFractionDigits: tokenFractionDigits,
            cachedBalanceJsonString: balance.toJsonIgnoreCoin(),
          )..id = thisEntry.id,
        );
      });
    }
  }
}

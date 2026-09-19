import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';

import '../../../../models/balance.dart';
import '../../../../models/isar/models/isar_models.dart';
import '../../../../providers/db/main_db_provider.dart';
import '../../../../utilities/logger.dart';
import '../util/watcher.dart';

/// Provider family for Solana token wallet info.
///
/// Watches the Isar database for changes to WalletSolanaTokenInfo.
/// Mirrors the pattern used for Ethereum token balances (TokenWalletInfo).
///
/// Example usage:
///   final info = ref.watch(
///     pSolanaTokenWalletInfo((walletId: 'wallet1', tokenMint: 'EPjFWaJUwYUoRwzwkH4H8gNB7zHW9tLT6NCKB8S4yh6h'))
///   );
final _wstwiProvider = ChangeNotifierProvider.family<
  Watcher,
  ({String walletId, String tokenMint})
>((ref, data) {
  final isar = ref.watch(mainDBProvider).isar;

  final collection = isar.walletSolanaTokenInfo;

  Logging.instance.i(
    "pSolanaTokenBalance: Looking up WalletSolanaTokenInfo for walletId=${data.walletId}, tokenMint=${data.tokenMint}",
  );

  WalletSolanaTokenInfo? initial = collection
      .where()
      .walletIdTokenAddressEqualTo(data.walletId, data.tokenMint)
      .findFirstSync();

  if (initial == null) {
    Logging.instance.i(
      "pSolanaTokenBalance: Creating new WalletSolanaTokenInfo entry",
    );

    // Create initial entry if not found.
    final solContract =
        isar.solContracts.getByAddressSync(data.tokenMint);

    initial = WalletSolanaTokenInfo(
      walletId: data.walletId,
      tokenAddress: data.tokenMint,
      tokenFractionDigits: solContract?.decimals ?? 6,
    );

    isar.writeTxnSync(() => isar.walletSolanaTokenInfo.putSync(initial!));

    // After insert, fetch the object again to get the assigned ID.
    initial = collection
        .where()
        .walletIdTokenAddressEqualTo(data.walletId, data.tokenMint)
        .findFirstSync()!;

    Logging.instance.i(
      "pSolanaTokenBalance: Created entry with ID=${initial.id}, balance=${initial.getCachedBalance().total}",
    );
  } else {
    Logging.instance.i(
      "pSolanaTokenBalance: Found existing entry with ID=${initial.id}, cachedBalance=${initial.getCachedBalance().total}",
    );
  }

  final watcher = Watcher(initial, collection: collection);

  ref.onDispose(() => watcher.dispose());

  return watcher;
});

/// Provider for Solana token wallet info from the database.
final pSolanaTokenWalletInfo = Provider.family<
  WalletSolanaTokenInfo,
  ({String walletId, String tokenMint})
>((ref, data) {
  return ref.watch(_wstwiProvider(data).select((value) => value.value))
      as WalletSolanaTokenInfo;
});

/// Provider for Solana token balance from the database.
///
/// This provider watches the Isar database and will automatically update
/// the UI whenever the balance changes in the database.
///
/// Example usage:
///   final balance = ref.watch(
///     pSolanaTokenBalance((walletId: 'wallet1', tokenMint: 'EPjFWaJUwYUoRwzwkH4H8gNB7zHW9tLT6NCKB8S4yh6h'))
///   );
final pSolanaTokenBalance = Provider.family<
  Balance,
  ({String walletId, String tokenMint})
>((ref, data) {
  final balance = ref.watch(
    _wstwiProvider(data).select(
      (value) => (value.value as WalletSolanaTokenInfo).getCachedBalance(),
    ),
  );

  Logging.instance.i(
    "pSolanaTokenBalance: Returning balance=${balance.total} for walletId=${data.walletId}, tokenMint=${data.tokenMint}",
  );

  return balance;
});

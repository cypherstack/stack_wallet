import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../electrumx_rpc/client_manager.dart';
import '../providers/global/active_wallet_provider.dart';
import '../providers/providers.dart';
import '../wallets/crypto_currency/crypto_currency.dart';
import 'enums/sync_type_enum.dart';

/// Captures providers while the view is alive, then notifies the wallets
/// still loaded when the returned callback runs.
Future<void> Function() nodeChangeNotifier(WidgetRef ref, CryptoCurrency coin) {
  final wallets = ref.read(pWallets);
  final prefs = ref.read(prefsChangeNotifierProvider);
  final activeWallet = ref.read(currentWalletIdProvider.notifier);

  return () async {
    // Retire the coin's previous connection even when its wallet was removed
    // and none of the loaded wallets ever used that connection.
    final (removed, _) = await ClientManager.sharedInstance.remove(
      cryptoCurrency: coin,
    );
    await removed?.close();
    for (final wallet in wallets.wallets.where((e) => e.info.coin == coin)) {
      final shouldRefresh = switch (prefs.syncType) {
        SyncingType.currentWalletOnly => activeWallet.state == wallet.walletId,
        SyncingType.selectedWalletsAtStartup =>
          prefs.walletIdsSyncOnStartup.contains(wallet.walletId),
        SyncingType.allWalletsOnStartup => true,
      };
      final update = wallet.updateNode();
      unawaited(shouldRefresh ? update.then((_) => wallet.refresh()) : update);
    }
  };
}

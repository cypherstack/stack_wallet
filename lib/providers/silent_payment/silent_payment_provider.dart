import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';

import '../../models/isar/models/silent_payments/silent_payment_config.dart';
import '../../models/isar/models/silent_payments/silent_payment_metadata.dart';
import '../../providers/db/main_db_provider.dart';
import '../../wallets/isar/providers/util/watcher.dart';
import '../../wallets/isar/providers/wallet_info_provider.dart';

/// Base provider that watches the SilentPaymentConfig object in the database
final _silentPaymentConfigProvider =
    ChangeNotifierProvider.family<Watcher, String>((ref, walletId) {
      final isar = ref.watch(mainDBProvider).isar;
      final collection = isar.silentPaymentConfig;

      // Try to find existing config
      var config = collection.where().walletIdEqualTo(walletId).findFirstSync();

      // If no config exists, create and save a new one
      if (config == null) {
        config = SilentPaymentConfig(walletId: walletId);
        isar.writeTxnSync(() {
          isar.silentPaymentConfig.putSync(config!);
        });
      }

      // Create a watcher for this config
      final watcher = Watcher(config, collection: collection);

      // Clean up when provider is disposed
      ref.onDispose(() => watcher.dispose());

      return watcher;
    });

/// Provider for the entire SilentPaymentConfig object
final pSilentPaymentConfig = Provider.family<SilentPaymentConfig, String>((
  ref,
  walletId,
) {
  return ref.watch(_silentPaymentConfigProvider(walletId)).value
      as SilentPaymentConfig;
});

/// Provider for just the enabled state
final pSilentPaymentEnabled = Provider.family<bool, String>((ref, walletId) {
  return ref.watch(
    _silentPaymentConfigProvider(
      walletId,
    ).select((value) => (value.value as SilentPaymentConfig).isEnabled),
  );
});

/// Provider for the last scanned height
final pSilentPaymentLastScannedHeight = Provider.family<int, String>((
  ref,
  walletId,
) {
  return ref.watch(
    _silentPaymentConfigProvider(
      walletId,
    ).select((value) => (value.value as SilentPaymentConfig).lastScannedHeight),
  );
});

/// Provider for the label map
final pSilentPaymentLabelMap = Provider.family<Map<String, String>?, String>((
  ref,
  walletId,
) {
  return ref.watch(
    _silentPaymentConfigProvider(
      walletId,
    ).select((value) => (value.value as SilentPaymentConfig).labelMap),
  );
});

/// Provider to determine if scanning is needed (compares with wallet height)
final pSilentPaymentScanNeeded = Provider.family<bool, String>((ref, walletId) {
  final config = ref.watch(pSilentPaymentConfig(walletId));

  // Import the wallet chain height provider where needed
  try {
    final walletHeight = ref.watch(pWalletChainHeight(walletId));
    return config.isEnabled && walletHeight > config.lastScannedHeight;
  } catch (_) {
    // Handle case where pWalletChainHeight isn't imported
    return false;
  }
});

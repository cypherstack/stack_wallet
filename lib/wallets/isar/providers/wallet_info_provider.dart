import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';

import '../../../models/balance.dart';
import '../../../providers/db/main_db_provider.dart';
import '../../crypto_currency/crypto_currency.dart';
import '../models/wallet_info.dart';
import 'util/watcher.dart';

final _wiProvider = ChangeNotifierProvider.family<Watcher, String>(
  (ref, walletId) {
    final collection = ref.watch(mainDBProvider).isar.walletInfo;

    final watcher = Watcher(
      collection.where().walletIdEqualTo(walletId).findFirstSync()!,
      collection: collection,
    );

    ref.onDispose(() => watcher.dispose());

    return watcher;
  },
);

final pWalletInfo = Provider.family<WalletInfo, String>(
  (ref, walletId) {
    return ref.watch(_wiProvider(walletId)).value as WalletInfo;
  },
);

final pWalletCoin = Provider.family<CryptoCurrency, String>(
  (ref, walletId) {
    return ref.watch(
      _wiProvider(walletId).select((value) => (value.value as WalletInfo).coin),
    );
  },
);

final pWalletBalance = Provider.family<Balance, String>(
  (ref, walletId) {
    return ref.watch(
      _wiProvider(walletId)
          .select((value) => (value.value as WalletInfo).cachedBalance),
    );
  },
);

final pWalletBalanceSecondary = Provider.family<Balance, String>(
  (ref, walletId) {
    return ref.watch(
      _wiProvider(walletId).select(
        (value) => (value.value as WalletInfo).cachedBalanceSecondary,
      ),
    );
  },
);

final pWalletBalanceTertiary = Provider.family<Balance, String>(
  (ref, walletId) {
    return ref.watch(
      _wiProvider(walletId)
          .select((value) => (value.value as WalletInfo).cachedBalanceTertiary),
    );
  },
);

final pWalletChainHeight = Provider.family<int, String>(
  (ref, walletId) {
    return ref.watch(
      _wiProvider(walletId)
          .select((value) => (value.value as WalletInfo).cachedChainHeight),
    );
  },
);

final pWalletIsFavourite = Provider.family<bool, String>(
  (ref, walletId) {
    return ref.watch(
      _wiProvider(walletId)
          .select((value) => (value.value as WalletInfo).isFavourite),
    );
  },
);

final pWalletName = Provider.family<String, String>(
  (ref, walletId) {
    return ref.watch(
      _wiProvider(walletId).select((value) => (value.value as WalletInfo).name),
    );
  },
);

final pWalletReceivingAddress = Provider.family<String, String>(
  (ref, walletId) {
    return ref.watch(
      _wiProvider(walletId).select(
        (value) => (value.value as WalletInfo).cachedReceivingAddress,
      ),
    );
  },
);

final pWalletTokenAddresses = Provider.family<List<String>, String>(
  (ref, walletId) {
    return ref.watch(
      _wiProvider(walletId).select(
        (value) => (value.value as WalletInfo).tokenContractAddresses,
      ),
    );
  },
);

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:stackwallet/models/balance.dart';
import 'package:stackwallet/providers/db/main_db_provider.dart';
import 'package:stackwallet/wallets/isar/models/token_wallet_info.dart';
import 'package:stackwallet/wallets/isar/providers/util/watcher.dart';

final _twiProvider = ChangeNotifierProvider.family<Watcher,
    ({String walletId, String contractAddress})>(
  (ref, data) {
    final collection = ref.watch(mainDBProvider).isar.tokenWalletInfo;

    final watcher = Watcher(
      collection
          .where()
          .walletIdTokenAddressEqualTo(data.walletId, data.contractAddress)
          .findFirstSync()!,
      collection: collection,
    );

    ref.onDispose(() => watcher.dispose());

    return watcher;
  },
);

final pTokenWalletInfo = Provider.family<TokenWalletInfo,
    ({String walletId, String contractAddress})>(
  (ref, data) {
    return ref.watch(_twiProvider(data)).value as TokenWalletInfo;
  },
);

final pTokenBalance =
    Provider.family<Balance, ({String walletId, String contractAddress})>(
  (ref, data) {
    return ref.watch(_twiProvider(data).select(
        (value) => (value.value as TokenWalletInfo).getCachedBalance()));
  },
);

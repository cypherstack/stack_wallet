import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import '../../../../models/balance.dart';
import '../../../../models/isar/models/isar_models.dart';
import '../../../../providers/db/main_db_provider.dart';
import '../../models/token_wallet_info.dart';
import '../util/watcher.dart';

final _twiProvider = ChangeNotifierProvider.family<Watcher,
    ({String walletId, String contractAddress})>(
  (ref, data) {
    final isar = ref.watch(mainDBProvider).isar;

    final collection = isar.tokenWalletInfo;

    TokenWalletInfo? initial = collection
        .where()
        .walletIdTokenAddressEqualTo(data.walletId, data.contractAddress)
        .findFirstSync();

    if (initial == null) {
      initial = TokenWalletInfo(
        walletId: data.walletId,
        tokenAddress: data.contractAddress,
        tokenFractionDigits: isar.ethContracts
                .getByAddressSync(data.contractAddress)
                ?.decimals ??
            2,
      );

      isar.writeTxnSync(() => isar.tokenWalletInfo.putSync(initial!));
    }

    final watcher = Watcher(
      initial,
      collection: collection,
    );

    ref.onDispose(() => watcher.dispose());

    return watcher;
  },
);

final pTokenWalletInfo = Provider.family<TokenWalletInfo,
    ({String walletId, String contractAddress})>(
  (ref, data) {
    return ref.watch(_twiProvider(data).select((value) => value.value))
        as TokenWalletInfo;
  },
);

final pTokenBalance =
    Provider.family<Balance, ({String walletId, String contractAddress})>(
  (ref, data) {
    return ref.watch(_twiProvider(data).select(
        (value) => (value.value as TokenWalletInfo).getCachedBalance()));
  },
);

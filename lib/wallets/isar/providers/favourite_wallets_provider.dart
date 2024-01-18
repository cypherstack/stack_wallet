import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:stackwallet/providers/db/main_db_provider.dart';
import 'package:stackwallet/wallets/isar/models/wallet_info.dart';

class _Watcher extends ChangeNotifier {
  final bool isFavourite;
  late final StreamSubscription<List<WalletInfo>> _streamSubscription;

  List<WalletInfo> _value;

  List<WalletInfo> get value => _value;

  _Watcher(this._value, this.isFavourite, Isar isar) {
    _streamSubscription = isar.walletInfo
        .filter()
        .isFavouriteEqualTo(isFavourite)
        .sortByFavouriteOrderIndex()
        .watch(fireImmediately: true)
        .listen((event) {
      _value = event;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _streamSubscription.cancel();
    super.dispose();
  }
}

final _wiProvider = ChangeNotifierProvider.family<_Watcher, bool>(
  (ref, isFavourite) {
    final isar = ref.watch(mainDBProvider).isar;

    final watcher = _Watcher(
      isar.walletInfo
          .filter()
          .isFavouriteEqualTo(isFavourite)
          .sortByFavouriteOrderIndex()
          .findAllSync(),
      isFavourite,
      isar,
    );

    ref.onDispose(() => watcher.dispose());

    return watcher;
  },
);

final pFavouriteWalletInfos = Provider.family<List<WalletInfo>, bool>(
  (ref, isFavourite) {
    return ref.watch(_wiProvider(isFavourite)).value;
  },
);

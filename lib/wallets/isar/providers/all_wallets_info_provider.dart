import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:stackwallet/providers/db/main_db_provider.dart';
import 'package:stackwallet/wallets/isar/models/wallet_info.dart';

final pAllWalletsInfo = Provider((ref) {
  if (_globalInstance == null) {
    final isar = ref.watch(mainDBProvider).isar;
    _globalInstance = _WalletInfoWatcher(
      isar.walletInfo.where().findAllSync(),
      isar,
    );
  }

  return _globalInstance!.value;
});

_WalletInfoWatcher? _globalInstance;

class _WalletInfoWatcher extends ChangeNotifier {
  late final StreamSubscription<void> _streamSubscription;

  List<WalletInfo> _value;

  List<WalletInfo> get value => _value;

  _WalletInfoWatcher(this._value, Isar isar) {
    _streamSubscription =
        isar.walletInfo.watchLazy(fireImmediately: true).listen((event) {
      isar.walletInfo.where().findAll().then((value) {
        _value = value;
        notifyListeners();
      });
    });
  }

  @override
  void dispose() {
    _streamSubscription.cancel();
    super.dispose();
  }
}

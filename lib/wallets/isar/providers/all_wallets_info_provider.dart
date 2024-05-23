import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import '../../../providers/db/main_db_provider.dart';
import '../../../app_config.dart';
import '../../crypto_currency/crypto_currency.dart';
import '../models/wallet_info.dart';

final pAllWalletsInfo = Provider((ref) {
  return ref.watch(_pAllWalletsInfo.select((value) => value.value));
});

final pAllWalletsInfoByCoin = Provider((ref) {
  final infos = ref.watch(pAllWalletsInfo);

  final Map<CryptoCurrency, ({CryptoCurrency coin, List<WalletInfo> wallets})>
      map = {};

  for (final info in infos) {
    if (map[info.coin] == null) {
      map[info.coin] = (coin: info.coin, wallets: []);
    }

    map[info.coin]!.wallets.add(info);
  }

  final List<({CryptoCurrency coin, List<WalletInfo> wallets})> results = [];
  for (final coin in AppConfig.coins) {
    if (map[coin] != null) {
      results.add(map[coin]!);
    }
  }

  return results;
});

_WalletInfoWatcher? _globalInstance;

final _pAllWalletsInfo = ChangeNotifierProvider((ref) {
  if (_globalInstance == null) {
    final isar = ref.watch(mainDBProvider).isar;
    _globalInstance = _WalletInfoWatcher(
      isar.walletInfo
          .where()
          .filter()
          .anyOf<String, CryptoCurrency>(
            AppConfig.coins.map((e) => e.identifier),
            (q, element) => q.coinNameMatches(element),
          )
          .findAllSync(),
      isar,
    );
  }

  return _globalInstance!;
});

class _WalletInfoWatcher extends ChangeNotifier {
  late final StreamSubscription<void> _streamSubscription;

  List<WalletInfo> _value;

  List<WalletInfo> get value => _value;

  _WalletInfoWatcher(this._value, Isar isar) {
    _streamSubscription =
        isar.walletInfo.watchLazy(fireImmediately: true).listen((event) {
      isar.walletInfo
          .where()
          .filter()
          .anyOf<String, CryptoCurrency>(
            AppConfig.coins.map((e) => e.identifier),
            (q, element) => q.coinNameMatches(element),
          )
          .findAll()
          .then((value) {
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

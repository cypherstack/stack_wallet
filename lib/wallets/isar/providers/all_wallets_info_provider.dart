import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';

import '../../../app_config.dart';
import '../../../providers/db/main_db_provider.dart';
import '../../../providers/global/duress_provider.dart';
import '../../crypto_currency/crypto_currency.dart';
import '../models/wallet_info.dart';

final pAllWalletsInfo = Provider((ref) {
  final duress = ref.watch(pDuress);

  final results = ref.watch(_pAllWalletsInfo.select((value) => value.value));

  if (duress) {
    return results.where((e) => e.isDuressVisible).toList();
  }

  return results;
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

final _pAllWalletsInfo = ChangeNotifierProvider((ref) {
  final isar = ref.watch(mainDBProvider).isar;

  return _WalletInfoWatcher(
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
});

class _WalletInfoWatcher extends ChangeNotifier {
  late final StreamSubscription<List<WalletInfo>> _streamSubscription;

  List<WalletInfo> _value;

  List<WalletInfo> get value => _value;

  _WalletInfoWatcher(this._value, Isar isar) {
    _streamSubscription = isar.walletInfo
        .where()
        .filter()
        .anyOf<String, CryptoCurrency>(
          AppConfig.coins.map((e) => e.identifier),
          (q, element) => q.coinNameMatches(element),
        )
        .watch(fireImmediately: true)
        .listen((value) {
          _value = value;
          notifyListeners();
        });
  }

  @override
  void dispose() {
    _streamSubscription.cancel();
    super.dispose();
  }
}

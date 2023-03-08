import 'dart:async';

import 'package:isar/isar.dart';
import 'package:stackwallet/db/main_db.dart';
import 'package:stackwallet/models/balance.dart';
import 'package:stackwallet/services/event_bus/events/global/updated_in_background_event.dart';
import 'package:stackwallet/services/event_bus/global_event_bus.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';

mixin CoinControlInterface {
  late final String _walletId;
  late final String _walletName;
  late final Coin _coin;
  late final MainDB _db;
  late final Future<int> Function() _getChainHeight;
  late final Future<void> Function(Balance) _refreshedBalanceCallback;

  void initCoinControlInterface({
    required String walletId,
    required String walletName,
    required Coin coin,
    required MainDB db,
    required Future<int> Function() getChainHeight,
    required Future<void> Function(Balance) refreshedBalanceCallback,
  }) {
    _walletId = walletId;
    _walletName = walletName;
    _coin = coin;
    _db = db;
    _getChainHeight = getChainHeight;
    _refreshedBalanceCallback = refreshedBalanceCallback;
  }

  Future<void> refreshBalance({bool notify = false}) async {
    final utxos = await _db.getUTXOs(_walletId).findAll();
    final currentChainHeight = await _getChainHeight();

    int satoshiBalanceTotal = 0;
    int satoshiBalancePending = 0;
    int satoshiBalanceSpendable = 0;
    int satoshiBalanceBlocked = 0;

    for (final utxo in utxos) {
      satoshiBalanceTotal += utxo.value;

      if (utxo.isBlocked) {
        satoshiBalanceBlocked += utxo.value;
      } else {
        if (utxo.isConfirmed(
          currentChainHeight,
          _coin.requiredConfirmations,
        )) {
          satoshiBalanceSpendable += utxo.value;
        } else {
          satoshiBalancePending += utxo.value;
        }
      }
    }

    final balance = Balance(
      coin: _coin,
      total: satoshiBalanceTotal,
      spendable: satoshiBalanceSpendable,
      blockedTotal: satoshiBalanceBlocked,
      pendingSpendable: satoshiBalancePending,
    );

    await _refreshedBalanceCallback(balance);

    if (notify) {
      GlobalEventBus.instance.fire(
        UpdatedInBackgroundEvent(
          "coin control refresh balance in $_walletId $_walletName!",
          _walletId,
        ),
      );
    }
  }
}

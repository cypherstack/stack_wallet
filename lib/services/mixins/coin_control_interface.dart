import 'dart:async';

import 'package:isar/isar.dart';
import 'package:stackwallet/db/isar/main_db.dart';
import 'package:stackwallet/models/balance.dart';
import 'package:stackwallet/services/event_bus/events/global/balance_refreshed_event.dart';
import 'package:stackwallet/services/event_bus/global_event_bus.dart';
import 'package:stackwallet/utilities/amount/amount.dart';
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

    Amount satoshiBalanceTotal = Amount(
      rawValue: BigInt.zero,
      fractionDigits: _coin.decimals,
    );
    Amount satoshiBalancePending = Amount(
      rawValue: BigInt.zero,
      fractionDigits: _coin.decimals,
    );
    Amount satoshiBalanceSpendable = Amount(
      rawValue: BigInt.zero,
      fractionDigits: _coin.decimals,
    );
    Amount satoshiBalanceBlocked = Amount(
      rawValue: BigInt.zero,
      fractionDigits: _coin.decimals,
    );

    for (final utxo in utxos) {
      final utxoAmount = Amount(
        rawValue: BigInt.from(utxo.value),
        fractionDigits: _coin.decimals,
      );

      satoshiBalanceTotal += utxoAmount;

      if (utxo.isBlocked) {
        satoshiBalanceBlocked += utxoAmount;
      } else {
        if (utxo.isConfirmed(
          currentChainHeight,
          _coin.requiredConfirmations,
        )) {
          satoshiBalanceSpendable += utxoAmount;
        } else {
          satoshiBalancePending += utxoAmount;
        }
      }
    }

    final balance = Balance(
      total: satoshiBalanceTotal,
      spendable: satoshiBalanceSpendable,
      blockedTotal: satoshiBalanceBlocked,
      pendingSpendable: satoshiBalancePending,
    );

    await _refreshedBalanceCallback(balance);

    if (notify) {
      GlobalEventBus.instance.fire(
        BalanceRefreshedEvent(
          _walletId,
        ),
      );
    }
  }
}

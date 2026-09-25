import 'dart:async';

import 'package:event_bus/event_bus.dart';

import '../../../../wallets/crypto_currency/crypto_currency.dart';

abstract class CryptoNotificationsEventBus {
  static final instance = EventBus();
  static int _listenerCount = 0;

  static bool get hasListeners => _listenerCount > 0;

  static void registerListener() => _listenerCount++;

  static void unregisterListener() {
    assert(_listenerCount > 0);
    if (_listenerCount > 0) {
      _listenerCount--;
    }
  }
}

class CryptoNotificationEvent {
  final String title;
  final String walletId;
  final String walletName;
  final DateTime date;
  final bool shouldWatchForUpdates;
  final CryptoCurrency coin;
  final String? txid;
  final int? confirmations;
  final int? requiredConfirmations;
  final String? changeNowId;
  final String? payload;
  final Completer<void> _deliveryCompleter = Completer<void>();

  Future<void> get delivered => _deliveryCompleter.future;

  CryptoNotificationEvent({
    required this.title,
    required this.walletId,
    required this.walletName,
    required this.date,
    required this.shouldWatchForUpdates,
    required this.coin,
    this.txid,
    this.confirmations,
    this.requiredConfirmations,
    this.changeNowId,
    this.payload,
  });

  void completeDelivery() {
    if (!_deliveryCompleter.isCompleted) {
      _deliveryCompleter.complete();
    }
  }

  void failDelivery(Object error, StackTrace stackTrace) {
    if (!_deliveryCompleter.isCompleted) {
      _deliveryCompleter.completeError(error, stackTrace);
    }
  }
}

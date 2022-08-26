import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:stackwallet/electrumx_rpc/electrumx.dart';
import 'package:stackwallet/hive/db.dart';
import 'package:stackwallet/models/exchange/change_now/exchange_transaction_status.dart';
import 'package:stackwallet/models/notification_model.dart';
import 'package:stackwallet/services/change_now/change_now.dart';
import 'package:stackwallet/services/node_service.dart';
import 'package:stackwallet/services/notifications_api.dart';
import 'package:stackwallet/services/trade_service.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/utilities/logger.dart';
import 'package:stackwallet/utilities/prefs.dart';

class NotificationsService extends ChangeNotifier {
  late NodeService nodeService;
  late TradesService tradesService;
  late Prefs prefs;

  NotificationsService._();
  static final NotificationsService _instance = NotificationsService._();
  static NotificationsService get instance => _instance;

  Future<void> init({
    required NodeService nodeService,
    required TradesService tradesService,
    required Prefs prefs,
  }) async {
    this.nodeService = nodeService;
    this.tradesService = tradesService;
    this.prefs = prefs;
  }

  // watched transactions
  List<NotificationModel> get _watchedTransactionNotifications {
    return DB.instance
        .values<NotificationModel>(boxName: DB.boxNameWatchedTransactions);
  }

  Future<void> _addWatchedTxNotification(NotificationModel notification) async {
    await DB.instance.put<NotificationModel>(
        boxName: DB.boxNameWatchedTransactions,
        key: notification.id,
        value: notification);
  }

  Future<void> _deleteWatchedTxNotification(
      NotificationModel notification) async {
    await DB.instance.delete<NotificationModel>(
        boxName: DB.boxNameWatchedTransactions, key: notification.id);
  }

  // watched trades
  List<NotificationModel> get _watchedChangeNowTradeNotifications {
    return DB.instance
        .values<NotificationModel>(boxName: DB.boxNameWatchedTrades);
  }

  Future<void> _addWatchedTradeNotification(
      NotificationModel notification) async {
    await DB.instance.put<NotificationModel>(
        boxName: DB.boxNameWatchedTrades,
        key: notification.id,
        value: notification);
  }

  Future<void> _deleteWatchedTradeNotification(
      NotificationModel notification) async {
    await DB.instance.delete<NotificationModel>(
        boxName: DB.boxNameWatchedTrades, key: notification.id);
  }

  static Timer? _timer;

  // todo: change this number?
  static Duration notificationRefreshInterval = const Duration(seconds: 60);

  void startCheckingWatchedNotifications() {
    stopCheckingWatchedTransactions();

    _timer = Timer.periodic(notificationRefreshInterval, (_) {
      Logging.instance
          .log("Periodic notifications update check", level: LogLevel.Info);
      _checkTrades();
      _checkTransactions();
    });
  }

  void stopCheckingWatchedTransactions() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void dispose() {
    stopCheckingWatchedTransactions();
    super.dispose();
  }

  void _checkTransactions() async {
    for (final notification in _watchedTransactionNotifications) {
      final Coin coin = coinFromPrettyName(notification.coinName);
      final txid = notification.txid!;

      final node = nodeService.getPrimaryNodeFor(coin: coin);
      if (node != null) {
        if (coin.isElectrumXCoin) {
          final eNode = ElectrumXNode(
            address: node.host,
            port: node.port,
            name: node.name,
            id: node.id,
            useSSL: node.useSSL,
          );
          final failovers = nodeService
              .failoverNodesFor(coin: coin)
              .map((e) => ElectrumXNode(
                    address: e.host,
                    port: e.port,
                    name: e.name,
                    id: e.id,
                    useSSL: e.useSSL,
                  ))
              .toList();

          final client = ElectrumX.from(
            node: eNode,
            failovers: failovers,
            prefs: prefs,
          );
          final tx = await client.getTransaction(txHash: txid);

          int confirmations = tx["confirmations"] as int? ?? 0;

          bool shouldWatchForUpdates = true;
          // check if the number of confirmations is greater than the number
          // required by the wallet to count the tx as confirmed and update the
          // flag on whether this notification should still be monitored
          if (confirmations >= coin.requiredConfirmations) {
            shouldWatchForUpdates = false;
            confirmations = coin.requiredConfirmations;
          }

          // grab confirms string to compare
          final String newConfirms =
              "($confirmations/${coin.requiredConfirmations})";
          final String oldConfirms =
              notification.title.substring(notification.title.lastIndexOf("("));

          // only update if they don't match
          if (oldConfirms != newConfirms) {
            final String newTitle =
                notification.title.replaceFirst(oldConfirms, newConfirms);

            final updatedNotification = notification.copyWith(
              title: newTitle,
              shouldWatchForUpdates: shouldWatchForUpdates,
            );

            // remove from watch list if shouldWatchForUpdates was changed
            if (!shouldWatchForUpdates) {
              await _deleteWatchedTxNotification(notification);
            }

            // replaces the current notification with the updated one
            add(updatedNotification, true);
          }
        } else {
          // TODO: check non electrumx coins
        }
      }
    }
  }

  void _checkTrades() async {
    for (final notification in _watchedChangeNowTradeNotifications) {
      final id = notification.changeNowId!;

      final result = await ChangeNow.getTransactionStatus(id: id);

      ChangeNowTransactionStatus? status = result.value?.status;

      // only update if status has changed
      if (status != null && status.name != notification.title) {
        bool shouldWatchForUpdates = true;
        // TODO: make sure we set shouldWatchForUpdates to correct value here
        switch (status) {
          case ChangeNowTransactionStatus.New:
          case ChangeNowTransactionStatus.Waiting:
          case ChangeNowTransactionStatus.Confirming:
          case ChangeNowTransactionStatus.Exchanging:
          case ChangeNowTransactionStatus.Verifying:
          case ChangeNowTransactionStatus.Sending:
            shouldWatchForUpdates = true;
            break;

          case ChangeNowTransactionStatus.Finished:
          case ChangeNowTransactionStatus.Failed:
          case ChangeNowTransactionStatus.Refunded:
            shouldWatchForUpdates = false;
            break;
        }

        final updatedNotification = notification.copyWith(
          title: status.name,
          shouldWatchForUpdates: shouldWatchForUpdates,
        );

        // remove from watch list if shouldWatchForUpdates was changed
        if (!shouldWatchForUpdates) {
          await _deleteWatchedTradeNotification(notification);
        }

        // replaces the current notification with the updated one
        add(updatedNotification, true);

        // update the trade in db
        if (result.value != null) {
          // fetch matching trade from db
          final trade = tradesService.trades
              .firstWhere((element) => element.id == result.value!.id);

          // update status
          final updatedTrade = trade.copyWith(
            statusObject: result.value!,
            statusString: result.value!.status.name,
          );

          // over write trade stored in db with updated version
          tradesService.add(trade: updatedTrade, shouldNotifyListeners: true);
        }
      }
    }
  }

  bool get hasUnreadNotifications {
    // final count = (_unreadCountBox.get("count") ?? 0) > 0;
    // debugPrint("NOTIF_COUNT: ${_unreadCountBox.get("count")}");
    return DB.instance
        .values<NotificationModel>(boxName: DB.boxNameNotifications)
        .where((element) => element.read == false)
        .isNotEmpty;
    // return count;
  }

  bool hasUnreadNotificationsFor(String walletId) {
    return DB.instance
        .values<NotificationModel>(boxName: DB.boxNameNotifications)
        .where(
            (element) => element.read == false && element.walletId == walletId)
        .isNotEmpty;
  }

  List<NotificationModel> get notifications {
    final list = DB.instance
        .values<NotificationModel>(boxName: DB.boxNameNotifications)
        .toList(growable: false)
        .reversed
        .toList(growable: false);
    return list;
  }

  Future<void> add(
    NotificationModel notification,
    bool shouldNotifyListeners,
  ) async {
    await DB.instance.put<NotificationModel>(
      boxName: DB.boxNameNotifications,
      key: notification.id,
      value: notification,
    );
    if (notification.shouldWatchForUpdates) {
      if (notification.txid != null) {
        _addWatchedTxNotification(notification);
      }
      if (notification.changeNowId != null) {
        _addWatchedTradeNotification(notification);
      }
    }
    if (shouldNotifyListeners) {
      notifyListeners();
    }
  }

  Future<void> delete(
    NotificationModel notification,
    bool shouldNotifyListeners,
  ) async {
    await DB.instance.delete<NotificationModel>(
        boxName: DB.boxNameNotifications, key: notification.id);

    await _deleteWatchedTradeNotification(notification);
    await _deleteWatchedTxNotification(notification);

    if (shouldNotifyListeners) {
      notifyListeners();
    }
  }

  Future<void> markAsRead(int id, bool shouldNotifyListeners) async {
    final model = DB.instance
        .get<NotificationModel>(boxName: DB.boxNameNotifications, key: id)!;
    await DB.instance.put<NotificationModel>(
      boxName: DB.boxNameNotifications,
      key: model.id,
      value: model.copyWith(read: true),
    );
    NotificationApi.clearNotification(id);
    if (shouldNotifyListeners) {
      notifyListeners();
    }
  }
}

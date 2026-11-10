import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/db/hive/db.dart';
import 'package:stackwallet/models/exchange/response_objects/trade.dart';
import 'package:stackwallet/models/notification_model.dart';
import 'package:stackwallet/services/exchange/exchange.dart';
import 'package:stackwallet/services/exchange/exchange_response.dart';
import 'package:stackwallet/services/notifications_service.dart';
import 'package:stackwallet/services/trade_service.dart';

import '../hive/hive_ce_test_utils.dart';

class _Exchange extends Fake implements Exchange {
  final requested = Completer<void>();
  final response = Completer<ExchangeResponse<Trade>>();

  @override
  Future<ExchangeResponse<Trade>> updateTrade(Trade trade) {
    requested.complete();
    return response.future;
  }
}

Trade _trade() => Trade(
  uuid: "uuid",
  tradeId: "tradeId",
  rateType: "fixed",
  direction: "direct",
  timestamp: DateTime.fromMillisecondsSinceEpoch(0),
  updatedAt: DateTime.fromMillisecondsSinceEpoch(0),
  payInCurrency: "zzz",
  payInAmount: "1",
  payInAddress: "payInAddress",
  payInNetwork: "zzz",
  payInExtraId: "",
  payInTxid: "",
  payOutCurrency: "zzz",
  payOutAmount: "1",
  payOutAddress: "payOutAddress",
  payOutNetwork: "zzz",
  payOutExtraId: "",
  payOutTxid: "",
  refundAddress: "refundAddress",
  refundExtraId: "",
  status: "finished",
  exchangeName: "ChangeNOW",
);

void main() {
  final service = NotificationsService.instance;
  late TradesService trades;
  late NotificationModel notification;

  setUp(() async {
    await setUpHiveCeTest();
    final hive = DB.instance.hive;
    if (!hive.isAdapterRegistered(Trade.typeId)) {
      hive.registerAdapter(TradeAdapter());
      hive.registerAdapter(NotificationModelAdapter());
    }
    await hive.openBox<Trade>(DB.boxNameTradesV2);
    await hive.openBox<NotificationModel>(DB.boxNameNotifications);
    await hive.openBox<NotificationModel>(DB.boxNameWatchedTrades);
    trades = TradesService();
    service.tradesService = trades;
    notification = NotificationModel(
      id: 1,
      title: "waiting",
      description: "trade",
      iconAssetName: "",
      date: DateTime.fromMillisecondsSinceEpoch(0),
      walletId: "",
      read: false,
      shouldWatchForUpdates: true,
      coinName: "",
      changeNowId: "tradeId",
    );
    await service.add(notification, false);
  });

  tearDown(() async {
    trades.dispose();
    await tearDownHiveCeTest();
  });

  test("removes watched trades that no longer exist", () async {
    await service.checkTrades(
      exchangeForName: (_) => throw StateError("unexpected request"),
    );
    expect(
      DB.instance.values<NotificationModel>(boxName: DB.boxNameWatchedTrades),
      isEmpty,
    );
  });

  test("ignores an update received after a trade was deleted", () async {
    await trades.add(trade: _trade(), shouldNotifyListeners: false);
    final exchange = _Exchange();
    final checking = service.checkTrades(exchangeForName: (_) => exchange);
    await exchange.requested.future;
    await trades.delete(trade: _trade(), shouldNotifyListeners: false);
    exchange.response.complete(ExchangeResponse(value: _trade()));
    await checking;

    expect(trades.trades, isEmpty);
    expect(service.notifications.single.title, "waiting");
    expect(
      DB.instance.values<NotificationModel>(boxName: DB.boxNameWatchedTrades),
      isEmpty,
    );
  });

  test(
    "updates an existing trade and stops watching terminal statuses",
    () async {
      await trades.add(trade: _trade(), shouldNotifyListeners: false);
      final exchange = _Exchange();
      final checking = service.checkTrades(exchangeForName: (_) => exchange);
      await exchange.requested.future;
      exchange.response.complete(
        ExchangeResponse(
          value: _trade().copyWith(status: "Refunded to sender"),
        ),
      );
      await checking;

      expect(trades.trades.single.status, "Refunded to sender");
      expect(service.notifications.single.title, "Refunded to sender");
      expect(
        DB.instance.values<NotificationModel>(boxName: DB.boxNameWatchedTrades),
        isEmpty,
      );
    },
  );

  test("deletion waits for a notification update to finish", () async {
    await trades.add(trade: _trade(), shouldNotifyListeners: false);
    await TradesService.notificationUpdateLock.acquire();
    final deleting = trades.delete(
      trade: _trade(),
      shouldNotifyListeners: false,
    );
    expect(trades.trades, hasLength(1));
    TradesService.notificationUpdateLock.release();
    await deleting;
    expect(trades.trades, isEmpty);
  });
}

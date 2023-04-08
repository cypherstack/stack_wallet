import 'package:flutter/cupertino.dart';
import 'package:stackwallet/db/hive/db.dart';
import 'package:stackwallet/models/exchange/response_objects/trade.dart';

class TradesService extends ChangeNotifier {
  List<Trade> get trades {
    final list = DB.instance.values<Trade>(boxName: DB.boxNameTradesV2);
    list.sort((a, b) =>
        b.timestamp.millisecondsSinceEpoch -
        a.timestamp.millisecondsSinceEpoch);
    return list;
  }

  Trade? get(String tradeId) {
    try {
      return DB.instance
          .values<Trade>(boxName: DB.boxNameTradesV2)
          .firstWhere((e) => e.tradeId == tradeId);
    } catch (_) {
      return null;
    }
  }

  Future<void> add({
    required Trade trade,
    required bool shouldNotifyListeners,
  }) async {
    await DB.instance
        .put<Trade>(boxName: DB.boxNameTradesV2, key: trade.uuid, value: trade);

    if (shouldNotifyListeners) {
      notifyListeners();
    }
  }

  Future<void> edit({
    required Trade trade,
    required bool shouldNotifyListeners,
  }) async {
    if (DB.instance.get<Trade>(boxName: DB.boxNameTradesV2, key: trade.uuid) ==
        null) {
      throw Exception("Attempted to edit a trade that does not exist in Hive!");
    }

    // add overwrites so this edit function is just a wrapper with an extra check
    await add(trade: trade, shouldNotifyListeners: shouldNotifyListeners);
  }

  Future<void> delete({
    required Trade trade,
    required bool shouldNotifyListeners,
  }) async {
    await deleteByUuid(
        uuid: trade.uuid, shouldNotifyListeners: shouldNotifyListeners);
  }

  Future<void> deleteByUuid({
    required String uuid,
    required bool shouldNotifyListeners,
  }) async {
    await DB.instance.delete<Trade>(boxName: DB.boxNameTradesV2, key: uuid);

    if (shouldNotifyListeners) {
      notifyListeners();
    }
  }
}

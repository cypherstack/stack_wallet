import 'package:flutter/cupertino.dart';
import 'package:stackwallet/hive/db.dart';
import 'package:stackwallet/models/exchange/change_now/exchange_transaction.dart';

class TradesService extends ChangeNotifier {
  List<ExchangeTransaction> get trades {
    final list =
        DB.instance.values<ExchangeTransaction>(boxName: DB.boxNameTrades);
    list.sort((a, b) =>
        b.date.millisecondsSinceEpoch - a.date.millisecondsSinceEpoch);
    return list;
  }

  Future<void> add({
    required ExchangeTransaction trade,
    required bool shouldNotifyListeners,
  }) async {
    await DB.instance.put<ExchangeTransaction>(
        boxName: DB.boxNameTrades, key: trade.uuid, value: trade);

    if (shouldNotifyListeners) {
      notifyListeners();
    }
  }

  Future<void> edit({
    required ExchangeTransaction trade,
    required bool shouldNotifyListeners,
  }) async {
    if (DB.instance.get<ExchangeTransaction>(
            boxName: DB.boxNameTrades, key: trade.uuid) ==
        null) {
      throw Exception("Attempted to edit a trade that does not exist in Hive!");
    }

    // add overwrites so this edit function is just a wrapper with an extra check
    await add(trade: trade, shouldNotifyListeners: shouldNotifyListeners);
  }

  Future<void> delete({
    required ExchangeTransaction trade,
    required bool shouldNotifyListeners,
  }) async {
    await deleteByUuid(
        uuid: trade.uuid, shouldNotifyListeners: shouldNotifyListeners);
  }

  Future<void> deleteByUuid({
    required String uuid,
    required bool shouldNotifyListeners,
  }) async {
    await DB.instance
        .delete<ExchangeTransaction>(boxName: DB.boxNameTrades, key: uuid);

    if (shouldNotifyListeners) {
      notifyListeners();
    }
  }
}

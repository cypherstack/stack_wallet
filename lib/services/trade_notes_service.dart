import 'package:flutter/material.dart';
import 'package:stackwallet/db/hive/db.dart';

class TradeNotesService extends ChangeNotifier {
  Map<String, String> get all {
    final Map<String, String> _all = {};
    for (final key in DB.instance.keys<String>(boxName: DB.boxNameTradeNotes)) {
      if (key is String) {
        _all[key] =
            DB.instance.get<String>(boxName: DB.boxNameTradeNotes, key: key) ??
                "";
      }
    }
    return _all;
  }

  String getNote({required String tradeId}) {
    return DB.instance
            .get<String>(boxName: DB.boxNameTradeNotes, key: tradeId) ??
        "";
  }

  Future<void> set({
    required String tradeId,
    required String note,
  }) async {
    await DB.instance
        .put<String>(boxName: DB.boxNameTradeNotes, key: tradeId, value: note);
    notifyListeners();
  }

  Future<void> delete({
    required String tradeId,
  }) async {
    await DB.instance
        .delete<String>(boxName: DB.boxNameTradeNotes, key: tradeId);
    notifyListeners();
  }
}

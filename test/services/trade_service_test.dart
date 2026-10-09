import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/db/hive/db.dart';
import 'package:stackwallet/models/exchange/response_objects/trade.dart';
import 'package:stackwallet/services/exchange/rosen/rosen_exchange.dart';
import 'package:stackwallet/services/trade_service.dart';

void main() {
  test('restoring an older bridge swap preserves its signed deposit', () async {
    final directory = await Directory.systemTemp.createTemp('rosen-restore-');
    final db = DB.instance;
    db.hive.init(directory.path);
    if (!db.hive.isAdapterRegistered(Trade.typeId)) {
      db.hive.registerAdapter(TradeAdapter());
    }
    final box = await db.hive.openBox<Trade>(DB.boxNameTradesV2);
    final service = TradesService();
    final backup = Trade(
      uuid: 'restore-test',
      tradeId: 'restore-test',
      rateType: 'estimated',
      direction: 'direct',
      timestamp: DateTime.utc(2026, 10, 9),
      updatedAt: DateTime.utc(2026, 10, 9),
      payInCurrency: 'FIRO',
      payInAmount: '1',
      payInAddress: 'lock',
      payInNetwork: 'firo',
      payInExtraId: '',
      payInTxid: '',
      payOutCurrency: 'rsFIRO',
      payOutAmount: '0.9',
      payOutAddress: 'recipient',
      payOutNetwork: 'eth',
      payOutExtraId: '',
      payOutTxid: '',
      refundAddress: '',
      refundExtraId: '',
      status: 'Waiting',
      exchangeName: RosenExchange.exchangeName,
      other: '{"request":"old quote"}',
    );
    final funded = backup.copyWith(
      payInTxid: 'signed-deposit',
      status: 'Verifying',
      payOutAmount: '0.8',
      other: '{"request":"reviewed quote","funding":{"raw":"signed bytes"}}',
    );
    try {
      await service.add(trade: funded, shouldNotifyListeners: false);
      await service.add(trade: backup, shouldNotifyListeners: false);
      final restored = service.get(backup.tradeId)!;
      expect(restored.payInTxid, funded.payInTxid);
      expect(restored.status, funded.status);
      expect(restored.payOutAmount, funded.payOutAmount);
      expect(restored.other, funded.other);

      // A newer backup may be the only surviving copy of a signed deposit.
      await box.clear();
      await service.add(trade: backup, shouldNotifyListeners: false);
      await service.add(trade: funded, shouldNotifyListeners: false);
      expect(service.get(backup.tradeId)!.toMap(), funded.toMap());
    } finally {
      service.dispose();
      await box.close();
      await directory.delete(recursive: true);
    }
  });
}

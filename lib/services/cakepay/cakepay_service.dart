import 'package:drift/drift.dart';

import '../../db/drift/shared_database.dart';
import '../../external_api_keys.dart';
import 'src/client.dart';

class CakePayService {
  static final instance = CakePayService._();
  CakePayService._();

  CakePayClient? _client;

  CakePayClient get client {
    return _client ??= CakePayClient(apiToken: kCakePayApiToken);
  }

  Future<void> addOrderId(String orderId) async {
    final db = SharedDrift.get();

    await db.transaction(() async {
      await db
          .into(db.cakepayOrders)
          .insert(
            CakepayOrdersCompanion.insert(orderId: orderId),
            mode: .insertOrIgnore,
          );
    });
  }

  /// Return locally-tracked order IDs (most recent first).
  Future<List<String>> getOrderIds() async {
    final db = SharedDrift.get();

    final rows =
        await (db.select(db.cakepayOrders)..orderBy([
              (t) => OrderingTerm(expression: t.rowId, mode: OrderingMode.desc),
            ]))
            .get();

    return rows.map((row) => row.orderId).toList();
  }
}

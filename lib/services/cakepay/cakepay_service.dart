import 'package:drift/drift.dart';
import 'package:mutex/mutex.dart';

import '../../db/drift/shared_db/shared_database.dart';
import '../../external_api_keys.dart';
import 'src/client.dart';

class CakePayService {
  static final instance = CakePayService._();
  CakePayService._();

  CakePayClient? _client;

  CakePayClient get client {
    return _client ??= CakePayClient(apiToken: kCakePayApiToken);
  }

  // TODO clean this up some day
  // simple in memory cache
  DateTime? _countryNamesUpdated;
  List<String> _countryNames = [];
  final _countryNamesMutex = Mutex();
  Future<List<String>> getCountryNames({bool refreshCache = false}) async {
    return _countryNamesMutex.protect(() async {
      final isFresh =
          _countryNamesUpdated != null &&
          _countryNamesUpdated!
              .add(const Duration(hours: 12))
              .isAfter(DateTime.now());

      if (!refreshCache && isFresh && _countryNames.isNotEmpty) {
        return _countryNames;
      }

      final response = await client.getAllCountries();

      if (response.hasError || response.value == null) {
        throw response.exception ?? Exception("Failed to fetch countries");
      }

      _countryNames =
          response.value!
              .where((e) => e.available)
              .map((e) => e.name)
              .toSet()
              .toList()
            ..sort();

      _countryNamesUpdated = DateTime.now();

      return _countryNames;
    });
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

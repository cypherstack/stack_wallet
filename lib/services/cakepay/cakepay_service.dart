import '../../db/hive/db.dart';
import '../../external_api_keys.dart';
import 'src/client.dart';

class CakePayService {
  static final instance = CakePayService._();
  CakePayService._();

  CakePayClient? _client;

  CakePayClient get client {
    return _client ??= CakePayClient(apiToken: kCakePayApiToken);
  }

  // Mirrors ShopInBit's local ticket storage pattern but uses lightweight
  // Hive prefs instead of a full Isar collection, since CakePay orders can
  // be fetched individually via getOrder() with the seller key.

  static const _kCakePayOrderIds = "cakePayOrderIds";

  /// Persist a newly-created order ID so the orders list view can find it
  /// later without requiring Knox user auth.
  void addOrderId(String orderId) {
    final ids = getOrderIds();
    if (!ids.contains(orderId)) {
      ids.insert(0, orderId);
      DB.instance.put<dynamic>(
        boxName: DB.boxNamePrefs,
        key: _kCakePayOrderIds,
        value: ids,
      );
    }
  }

  /// Return locally-tracked order IDs (most recent first).
  List<String> getOrderIds() {
    final raw = DB.instance.get<dynamic>(
      boxName: DB.boxNamePrefs,
      key: _kCakePayOrderIds,
    );
    if (raw is List) {
      return raw.cast<String>().toList();
    }
    return [];
  }
}

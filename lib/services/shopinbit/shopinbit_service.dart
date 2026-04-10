import '../../db/hive/db.dart';
import '../../external_api_keys.dart';
import '../../utilities/logger.dart';
import 'src/client.dart';

class ShopInBitService {
  static final instance = ShopInBitService._();
  ShopInBitService._();

  ShopInBitClient? _client;
  String? _customerKey;
  bool? _guidelinesAccepted;
  bool? _setupComplete;
  String? _displayName;

  ShopInBitClient get client {
    if (_client == null) {
      _client = ShopInBitClient(
        accessKey: kShopInBitAccessKey,
        partnerSecret: kShopInBitPartnerSecret,
        sandbox: true,
      );
      // Pre-load customer key for ticket detail API calls.
      loadCustomerKey();
    }
    return _client!;
  }

  String? get customerKey => _customerKey;

  String? loadCustomerKey() {
    if (_customerKey != null) return _customerKey;
    _customerKey =
        DB.instance.get<dynamic>(
              boxName: DB.boxNamePrefs,
              key: "shopInBitCustomerKey",
            )
            as String?;
    if (_customerKey != null) {
      client.externalCustomerKey = _customerKey;
    }
    return _customerKey;
  }

  Future<String> ensureCustomerKey() async {
    if (_customerKey != null) return _customerKey!;
    _customerKey =
        DB.instance.get<dynamic>(
              boxName: DB.boxNamePrefs,
              key: "shopInBitCustomerKey",
            )
            as String?;
    if (_customerKey != null) {
      Logging.instance.t("ShopInBitService: loaded customer key from DB");
      client.externalCustomerKey = _customerKey;
      return _customerKey!;
    }
    Logging.instance.i("ShopInBitService: generating new customer key");
    final resp = await client.generateKey();
    _customerKey = resp.valueOrThrow;
    client.externalCustomerKey = _customerKey;
    await DB.instance.put<dynamic>(
      boxName: DB.boxNamePrefs,
      key: "shopInBitCustomerKey",
      value: _customerKey,
    );
    Logging.instance.i("ShopInBitService: customer key stored");
    return _customerKey!;
  }

  Future<void> setCustomerKey(String key) async {
    _customerKey = key;
    client.externalCustomerKey = key;
    await DB.instance.put<dynamic>(
      boxName: DB.boxNamePrefs,
      key: "shopInBitCustomerKey",
      value: key,
    );
    Logging.instance.i("ShopInBitService: customer key manually set");
  }

  Future<void> clearCustomerKey() async {
    _customerKey = null;
    client.externalCustomerKey = null;
    await DB.instance.put<dynamic>(
      boxName: DB.boxNamePrefs,
      key: "shopInBitCustomerKey",
      value: null,
    );
    Logging.instance.i("ShopInBitService: customer key cleared");
  }

  bool loadGuidelinesAccepted() {
    if (_guidelinesAccepted != null) return _guidelinesAccepted!;
    _guidelinesAccepted =
        DB.instance.get<dynamic>(
              boxName: DB.boxNamePrefs,
              key: "shopInBitGuidelinesAccepted",
            )
            as bool? ??
            false;
    return _guidelinesAccepted!;
  }

  Future<void> setGuidelinesAccepted(bool accepted) async {
    _guidelinesAccepted = accepted;
    await DB.instance.put<dynamic>(
      boxName: DB.boxNamePrefs,
      key: "shopInBitGuidelinesAccepted",
      value: accepted,
    );
    Logging.instance.i(
      "ShopInBitService: guidelines accepted set to $accepted",
    );
  }

  bool loadSetupComplete() {
    if (_setupComplete != null) return _setupComplete!;
    _setupComplete =
        DB.instance.get<dynamic>(
              boxName: DB.boxNamePrefs,
              key: "shopInBitSetupComplete",
            )
            as bool? ??
            false;
    return _setupComplete!;
  }

  Future<void> setSetupComplete(bool complete) async {
    _setupComplete = complete;
    await DB.instance.put<dynamic>(
      boxName: DB.boxNamePrefs,
      key: "shopInBitSetupComplete",
      value: complete,
    );
    Logging.instance.i(
      "ShopInBitService: setup complete set to $complete",
    );
  }

  String? loadDisplayName() {
    if (_displayName != null) return _displayName;
    _displayName =
        DB.instance.get<dynamic>(
              boxName: DB.boxNamePrefs,
              key: "shopInBitDisplayName",
            )
            as String?;
    return _displayName;
  }

  Future<void> setDisplayName(String name) async {
    _displayName = name;
    await DB.instance.put<dynamic>(
      boxName: DB.boxNamePrefs,
      key: "shopInBitDisplayName",
      value: name,
    );
    Logging.instance.i("ShopInBitService: display name set");
  }
}

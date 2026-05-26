import '../../external_api_keys.dart';
import '../../utilities/flutter_secure_storage_interface.dart';
import '../../utilities/logger.dart';
import 'src/client.dart';

const _kShopinBitCustomerKeyKeySecureStore = "shopinBitSecStoreCustomerKeyKey";

class ShopInBitService {
  SecureStorageInterface? _secureStorageInterface;

  SecureStorageInterface get _secure {
    if (_secureStorageInterface == null) {
      throw Exception(
        "Did you forget to call ShopInBitService.ensureInitialized()?",
      );
    }
    return _secureStorageInterface!;
  }

  /// If secure storage was already set, this function will do nothing
  void ensureInitialized(SecureStorageInterface secureStore) {
    _secureStorageInterface ??= secureStore;
  }

  ShopInBitClient? _client;
  ShopInBitClient get client {
    _client ??= ShopInBitClient(
      accessKey: kShopInBitAccessKey,
      partnerSecret: kShopInBitPartnerSecret,
      sandbox: true,
    );
    return _client!;
  }

  Future<String?> loadCustomerKey() =>
      _secure.read(key: _kShopinBitCustomerKeyKeySecureStore);

  Future<String> ensureCustomerKey() async {
    final currentKey = await loadCustomerKey();

    if (currentKey != null) {
      Logging.instance.t("ShopInBitService: loaded customer key from DB");
      client.externalCustomerKey = currentKey;
      return currentKey;
    }
    Logging.instance.i("ShopInBitService: generating new customer key");
    final resp = await client.generateKey();
    final customerKey = resp.valueOrThrow;
    await setCustomerKey(customerKey);
    Logging.instance.i("ShopInBitService: customer key stored");
    return customerKey;
  }

  Future<void> setCustomerKey(String key) async {
    await _secure.write(key: _kShopinBitCustomerKeyKeySecureStore, value: key);
    client.externalCustomerKey = key;
    Logging.instance.i("ShopInBitService: customer key stored");
  }

  Future<void> clearCustomerKey() async {
    client.externalCustomerKey = null;
    await _secure.delete(key: _kShopinBitCustomerKeyKeySecureStore);
    Logging.instance.i("ShopInBitService: customer key cleared");
  }
}

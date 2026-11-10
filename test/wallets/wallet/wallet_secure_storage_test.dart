import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/utilities/flutter_secure_storage_interface.dart';
import 'package:stackwallet/wallets/wallet/wallet.dart';

void main() {
  test("deletes all wallet-owned recovery material", () async {
    const walletId = "wallet-id";
    final storage = FakeSecureStorage();
    final keys = Wallet.secureStorageKeys(walletId: walletId);

    for (final key in keys) {
      await storage.write(key: key, value: "secret");
    }

    await Wallet.deleteSecureStorageData(
      walletId: walletId,
      secureStorage: storage,
    );

    expect(await storage.keys, isEmpty);
    expect(keys, contains(Wallet.keysRestoreDataKey(walletId: walletId)));
  });
}

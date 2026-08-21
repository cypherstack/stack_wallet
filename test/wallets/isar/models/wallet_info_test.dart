import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/app_config.dart';
import 'package:stackwallet/wallets/isar/models/wallet_info.dart';

void main() {
  group("WalletInfo.isRestoredFromKeys", () {
    test("defaults to false", () {
      final info = WalletInfo.createNew(
        coin: AppConfig.coins.first,
        name: "wallet",
      );

      expect(info.isRestoredFromKeys, isFalse);
    });

    test("reads the persisted recovery type", () {
      final info = WalletInfo.createNew(
        coin: AppConfig.coins.first,
        name: "wallet",
        otherDataJsonString: jsonEncode({
          WalletInfoKeys.isRestoredFromKeysKey: true,
        }),
      );

      expect(info.isRestoredFromKeys, isTrue);
    });
  });
}

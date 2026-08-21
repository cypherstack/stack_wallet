import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/app_config.dart';
import 'package:stackwallet/wallets/isar/models/wallet_info.dart';

void main() {
  group("WalletInfo.recoveryType", () {
    test("defaults to mnemonic", () {
      final info = WalletInfo.createNew(
        coin: AppConfig.coins.first,
        name: "wallet",
      );

      expect(info.recoveryType, WalletRecoveryType.mnemonic);
    });

    test("reads the persisted recovery type", () {
      final info = WalletInfo.createNew(
        coin: AppConfig.coins.first,
        name: "wallet",
        otherDataJsonString: jsonEncode({
          WalletInfoKeys.recoveryTypeIndexKey:
              WalletRecoveryType.privateKeys.index,
        }),
      );

      expect(info.recoveryType, WalletRecoveryType.privateKeys);
    });

    test("migrates the former private-key flag", () {
      final info = WalletInfo.createNew(
        coin: AppConfig.coins.first,
        name: "wallet",
        otherDataJsonString: jsonEncode({
          WalletInfoKeys.isRestoredFromKeysKey: true,
        }),
      );

      expect(info.recoveryType, WalletRecoveryType.privateKeys);
    });
  });
}

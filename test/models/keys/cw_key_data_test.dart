import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/models/keys/cw_key_data.dart';

void main() {
  group("CWKeyData.hasError", () {
    test("is false for complete key data", () {
      final data = CWKeyData(
        walletId: "wallet-id",
        privateSpendKey: "private-spend",
        privateViewKey: "private-view",
        publicSpendKey: "public-spend",
        publicViewKey: "public-view",
      );

      expect(data.hasError, isFalse);
    });

    test("is true when key retrieval failed", () {
      final data = CWKeyData(
        walletId: "wallet-id",
        privateSpendKey: "ERROR",
        privateViewKey: "ERROR",
        publicSpendKey: "ERROR",
        publicViewKey: "ERROR",
      );

      expect(data.hasError, isTrue);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/models/keys/cw_key_data.dart';

void main() {
  test("stores complete key data in display order", () {
    final data = CWKeyData(
      walletId: "wallet-id",
      privateSpendKey: "private-spend",
      privateViewKey: "private-view",
      publicSpendKey: "public-spend",
      publicViewKey: "public-view",
    );

    expect(data.keys, [
      (label: "Public View Key", key: "public-view"),
      (label: "Private View Key", key: "private-view"),
      (label: "Public Spend Key", key: "public-spend"),
      (label: "Private Spend Key", key: "private-spend"),
    ]);
    expect(
      () => data.keys.add((label: "key", key: "value")),
      throwsUnsupportedError,
    );
  });
}

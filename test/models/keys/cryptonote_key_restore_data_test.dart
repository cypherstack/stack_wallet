import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/models/keys/cryptonote_key_restore_data.dart';

void main() {
  test("round trips through secure-storage encoding", () {
    const data = CryptonoteKeyRestoreData(
      address: "address",
      privateViewKey: "view-key",
      privateSpendKey: "spend-key",
    );

    final decoded = CryptonoteKeyRestoreData.fromJsonEncodedString(
      data.toJsonEncodedString(),
    );

    expect(decoded.address, data.address);
    expect(decoded.privateViewKey, data.privateViewKey);
    expect(decoded.privateSpendKey, data.privateSpendKey);
  });

  test("does not expose keys in diagnostics", () {
    const data = CryptonoteKeyRestoreData(
      address: "address",
      privateViewKey: "view-key",
      privateSpendKey: "spend-key",
    );

    expect(data.toString(), isNot(contains("view-key")));
    expect(data.toString(), isNot(contains("spend-key")));
  });
}

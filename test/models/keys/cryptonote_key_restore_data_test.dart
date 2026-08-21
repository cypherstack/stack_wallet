import 'dart:convert';

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

    expect(
      jsonDecode(data.toJsonEncodedString()),
      containsPair("version", CryptonoteKeyRestoreData.currentVersion),
    );
    expect(decoded.address, data.address);
    expect(decoded.privateViewKey, data.privateViewKey);
    expect(decoded.privateSpendKey, data.privateSpendKey);
  });

  test("reads legacy unversioned data", () {
    final decoded = CryptonoteKeyRestoreData.fromJsonEncodedString(
      jsonEncode({
        "address": "address",
        "privateViewKey": "view-key",
        "privateSpendKey": "spend-key",
      }),
    );

    expect(decoded.address, "address");
    expect(decoded.privateViewKey, "view-key");
    expect(decoded.privateSpendKey, "spend-key");
  });

  test("rejects unsupported versions and incomplete data", () {
    expect(
      () => CryptonoteKeyRestoreData.fromJsonEncodedString(
        jsonEncode({
          "version": CryptonoteKeyRestoreData.currentVersion + 1,
          "address": "address",
          "privateViewKey": "view-key",
          "privateSpendKey": "spend-key",
        }),
      ),
      throwsFormatException,
    );
    expect(
      () => CryptonoteKeyRestoreData.fromJsonEncodedString(
        jsonEncode({
          "version": CryptonoteKeyRestoreData.currentVersion,
          "address": "address",
          "privateViewKey": "",
          "privateSpendKey": "spend-key",
        }),
      ),
      throwsFormatException,
    );
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

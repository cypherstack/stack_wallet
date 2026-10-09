import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/models/keys/view_only_wallet_data.dart';
import 'package:stackwallet/pages/settings_views/global_settings_view/stack_backup_views/helpers/swb_view_only_recovery_data.dart';
import 'package:stackwallet/wallets/isar/models/wallet_info.dart';

void main() {
  const walletId = "wallet-id";
  const walletName = "Watching wallet";

  final encoded = CryptonoteViewOnlyWalletData(
    walletId: walletId,
    address: "address",
    privateViewKey: "view-key",
  ).toJsonEncodedString();

  test("recovers missing view-only metadata", () {
    final result = normalizeSWBViewOnlyRecoveryData(
      operation: "back up",
      walletName: walletName,
      walletId: walletId,
      otherData: const {"untouched": true},
      encodedData: encoded,
    );

    expect(result, isNotNull);
    expect(result!.encodedData, encoded);
    expect(result.otherData, {
      "untouched": true,
      WalletInfoKeys.isViewOnlyKey: true,
      WalletInfoKeys.viewOnlyTypeIndexKey: ViewOnlyWalletType.cryptonote.index,
    });
  });

  test("normalizes wallet records before restore mutation", () {
    final wallets = <dynamic>[
      <String, dynamic>{
        "name": walletName,
        "id": walletId,
        "otherDataJsonString": "invalid legacy metadata",
        "viewOnlyWalletDataKey": encoded,
      },
    ];

    normalizeSWBViewOnlyWalletBackups(wallets);

    final otherData =
        jsonDecode(wallets.single["otherDataJsonString"] as String)
            as Map<String, dynamic>;
    expect(otherData[WalletInfoKeys.isViewOnlyKey], isTrue);
    expect(
      otherData[WalletInfoKeys.viewOnlyTypeIndexKey],
      ViewOnlyWalletType.cryptonote.index,
    );
  });

  test("accepts matching view-only metadata", () {
    final result = normalizeSWBViewOnlyRecoveryData(
      operation: "restore",
      walletName: walletName,
      walletId: walletId,
      otherData: {
        WalletInfoKeys.isViewOnlyKey: true,
        WalletInfoKeys.viewOnlyTypeIndexKey:
            ViewOnlyWalletType.cryptonote.index,
      },
      encodedData: encoded,
    );

    expect(result, isNotNull);
  });

  test("ignores absent data for a seed wallet", () {
    final result = normalizeSWBViewOnlyRecoveryData(
      operation: "back up",
      walletName: walletName,
      walletId: walletId,
      otherData: const {},
      encodedData: null,
    );

    expect(result, isNull);
  });

  test("rejects missing recovery data for a declared view-only wallet", () {
    expect(
      () => normalizeSWBViewOnlyRecoveryData(
        operation: "back up",
        walletName: walletName,
        walletId: walletId,
        otherData: const {WalletInfoKeys.isViewOnlyKey: true},
        encodedData: null,
      ),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          "message",
          contains('Cannot back up view-only wallet "$walletName"'),
        ),
      ),
    );
  });

  test("rejects malformed and wrongly typed recovery data", () {
    for (final data in <Object>["not json", 7]) {
      expect(
        () => normalizeSWBViewOnlyRecoveryData(
          operation: "restore",
          walletName: walletName,
          walletId: walletId,
          otherData: const {},
          encodedData: data,
        ),
        throwsA(isA<FormatException>()),
      );
    }
  });

  test("rejects incomplete recovery data", () {
    final incomplete = CryptonoteViewOnlyWalletData(
      walletId: walletId,
      address: "address",
      privateViewKey: "",
    ).toJsonEncodedString();

    expect(
      () => normalizeSWBViewOnlyRecoveryData(
        operation: "restore",
        walletName: walletName,
        walletId: walletId,
        otherData: const {},
        encodedData: incomplete,
      ),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          "message",
          contains("recovery data is incomplete"),
        ),
      ),
    );
  });

  test("rejects conflicting recovery metadata", () {
    expect(
      () => normalizeSWBViewOnlyRecoveryData(
        operation: "restore",
        walletName: walletName,
        walletId: walletId,
        otherData: {
          WalletInfoKeys.isViewOnlyKey: true,
          WalletInfoKeys.viewOnlyTypeIndexKey:
              ViewOnlyWalletType.addressOnly.index,
        },
        encodedData: encoded,
      ),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          "message",
          contains("recovery metadata conflicts"),
        ),
      ),
    );
  });
}

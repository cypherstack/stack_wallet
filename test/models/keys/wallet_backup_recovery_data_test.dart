import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/models/keys/cryptonote_key_restore_data.dart';
import 'package:stackwallet/models/keys/wallet_backup_recovery_data.dart';

void main() {
  test("round trips Cryptonote key material through a wallet backup", () {
    const data = CryptonoteKeyRestoreData(
      address: "address",
      privateViewKey: "view-key",
      privateSpendKey: "spend-key",
    );
    final backup = <String, dynamic>{};

    writeCryptonoteKeyRestoreDataToBackup(backup, data);
    final restored = readCryptonoteKeyRestoreDataFromBackup(backup)!;

    expect(restored.address, data.address);
    expect(restored.privateViewKey, data.privateViewKey);
    expect(restored.privateSpendKey, data.privateSpendKey);
  });

  test("accepts backups without Cryptonote key material", () {
    expect(readCryptonoteKeyRestoreDataFromBackup({}), isNull);
  });

  test("rejects malformed Cryptonote backup material", () {
    expect(
      () => readCryptonoteKeyRestoreDataFromBackup({
        cryptonoteKeyRestoreDataBackupKey: <String, dynamic>{},
      }),
      throwsFormatException,
    );
  });

  test("rejects conflicting recovery material", () {
    final backup = <String, dynamic>{"mnemonic": "seed words"};
    writeCryptonoteKeyRestoreDataToBackup(
      backup,
      const CryptonoteKeyRestoreData(
        address: "address",
        privateViewKey: "view-key",
        privateSpendKey: "spend-key",
      ),
    );

    expect(
      () => readCryptonoteKeyRestoreDataFromBackup(backup),
      throwsFormatException,
    );
  });
}

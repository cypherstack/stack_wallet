import 'cryptonote_key_restore_data.dart';

const cryptonoteKeyRestoreDataBackupKey = "cryptonoteKeyRestoreData";

void writeCryptonoteKeyRestoreDataToBackup(
  Map<String, dynamic> walletBackup,
  CryptonoteKeyRestoreData data,
) {
  walletBackup[cryptonoteKeyRestoreDataBackupKey] = data.toJsonEncodedString();
}

CryptonoteKeyRestoreData? readCryptonoteKeyRestoreDataFromBackup(
  Map<String, dynamic> walletBackup,
) {
  final encoded = walletBackup[cryptonoteKeyRestoreDataBackupKey];
  if (encoded == null) {
    return null;
  }
  if (encoded is! String) {
    throw const FormatException("Invalid Cryptonote backup recovery data");
  }
  if (walletBackup["mnemonic"] != null ||
      walletBackup["privateKey"] != null ||
      walletBackup["viewOnlyWalletDataKey"] != null) {
    throw const FormatException("Conflicting wallet backup recovery data");
  }
  return CryptonoteKeyRestoreData.fromJsonEncodedString(encoded);
}

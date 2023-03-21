import 'package:hive/hive.dart';
import 'package:stack_wallet_backup/secure_storage.dart';
import 'package:stackduo/hive/db.dart';
import 'package:stackduo/utilities/logger.dart';

const String _kKeyBlobKey = "swbKeyBlobKeyStringID";
const String _kKeyBlobVersionKey = "swbKeyBlobVersionKeyStringID";

const int kLatestBlobVersion = 2;

String _getMessageFromException(Object exception) {
  if (exception is IncorrectPassphraseOrVersion) {
    return exception.errMsg();
  }
  if (exception is BadDecryption) {
    return exception.errMsg();
  }
  if (exception is InvalidLength) {
    return exception.errMsg();
  }
  if (exception is EncodingError) {
    return exception.errMsg();
  }
  if (exception is VersionError) {
    return exception.errMsg();
  }

  return exception.toString();
}

class DPS {
  StorageCryptoHandler? _handler;

  StorageCryptoHandler get handler {
    if (_handler == null) {
      throw Exception(
          "DPS: attempted to access handler without proper authentication");
    }
    return _handler!;
  }

  DPS();

  Future<void> initFromNew(String passphrase) async {
    if (_handler != null) {
      throw Exception("DPS: attempted to re initialize with new passphrase");
    }

    try {
      _handler = await StorageCryptoHandler.fromNewPassphrase(
        passphrase,
        kLatestBlobVersion,
      );

      final box = await Hive.openBox<String>(DB.boxNameDesktopData);
      await DB.instance.put<String>(
        boxName: DB.boxNameDesktopData,
        key: _kKeyBlobKey,
        value: await _handler!.getKeyBlob(),
      );
      await _updateStoredKeyBlobVersion(kLatestBlobVersion);
      await box.close();
    } catch (e, s) {
      Logging.instance.log(
        "${_getMessageFromException(e)}\n$s",
        level: LogLevel.Error,
      );
      rethrow;
    }
  }

  Future<void> initFromExisting(String passphrase) async {
    if (_handler != null) {
      throw Exception(
          "DPS: attempted to re initialize with existing passphrase");
    }

    final box = await Hive.openBox<String>(DB.boxNameDesktopData);
    final keyBlob = DB.instance.get<String>(
      boxName: DB.boxNameDesktopData,
      key: _kKeyBlobKey,
    );
    await box.close();

    if (keyBlob == null) {
      throw Exception(
          "DPS: failed to find keyBlob while attempting to initialize with existing passphrase");
    }

    try {
      final blobVersion = await _getStoredKeyBlobVersion();
      _handler = await StorageCryptoHandler.fromExisting(
        passphrase,
        keyBlob,
        blobVersion,
      );
      if (blobVersion < kLatestBlobVersion) {
        // update blob
        await _handler!.resetPassphrase(passphrase, kLatestBlobVersion);
        final box = await Hive.openBox<String>(DB.boxNameDesktopData);
        await DB.instance.put<String>(
          boxName: DB.boxNameDesktopData,
          key: _kKeyBlobKey,
          value: await _handler!.getKeyBlob(),
        );
        await _updateStoredKeyBlobVersion(kLatestBlobVersion);
        await box.close();
      }
    } catch (e, s) {
      Logging.instance.log(
        "${_getMessageFromException(e)}\n$s",
        level: LogLevel.Error,
      );
      throw Exception(_getMessageFromException(e));
    }
  }

  Future<bool> verifyPassphrase(String passphrase) async {
    final box = await Hive.openBox<String>(DB.boxNameDesktopData);
    final keyBlob = DB.instance.get<String>(
      boxName: DB.boxNameDesktopData,
      key: _kKeyBlobKey,
    );
    await box.close();

    if (keyBlob == null) {
      // no passphrase key blob found so any passphrase is technically bad
      return false;
    }

    try {
      final blobVersion = await _getStoredKeyBlobVersion();
      await StorageCryptoHandler.fromExisting(passphrase, keyBlob, blobVersion);
      // existing passphrase matches key blob
      return true;
    } catch (e, s) {
      Logging.instance.log(
        "${_getMessageFromException(e)}\n$s",
        level: LogLevel.Warning,
      );
      // password is wrong or some other error
      return false;
    }
  }

  Future<bool> changePassphrase(
    String passphraseOld,
    String passphraseNew,
  ) async {
    final box = await Hive.openBox<String>(DB.boxNameDesktopData);
    final keyBlob = DB.instance.get<String>(
      boxName: DB.boxNameDesktopData,
      key: _kKeyBlobKey,
    );
    await box.close();

    if (keyBlob == null) {
      // no passphrase key blob found so any passphrase is technically bad
      return false;
    }

    if (!(await verifyPassphrase(passphraseOld))) {
      return false;
    }

    final blobVersion = await _getStoredKeyBlobVersion();

    try {
      await _handler!.resetPassphrase(passphraseNew, blobVersion);

      final box = await Hive.openBox<String>(DB.boxNameDesktopData);
      await DB.instance.put<String>(
        boxName: DB.boxNameDesktopData,
        key: _kKeyBlobKey,
        value: await _handler!.getKeyBlob(),
      );
      await _updateStoredKeyBlobVersion(blobVersion);
      await box.close();

      // successfully updated passphrase
      return true;
    } catch (e, s) {
      Logging.instance.log(
        "${_getMessageFromException(e)}\n$s",
        level: LogLevel.Warning,
      );
      return false;
    }
  }

  Future<bool> hasPassword() async {
    final keyBlob = DB.instance.get<String>(
      boxName: DB.boxNameDesktopData,
      key: _kKeyBlobKey,
    );
    return keyBlob != null;
  }

  Future<int> _getStoredKeyBlobVersion() async {
    final box = await Hive.openBox<String>(DB.boxNameDesktopData);
    final keyBlobVersionString = DB.instance.get<String>(
      boxName: DB.boxNameDesktopData,
      key: _kKeyBlobVersionKey,
    );
    await box.close();
    return int.tryParse(keyBlobVersionString ?? "1") ?? 1;
  }

  Future<void> _updateStoredKeyBlobVersion(int version) async {
    await DB.instance.put<String>(
      boxName: DB.boxNameDesktopData,
      key: _kKeyBlobVersionKey,
      value: version.toString(),
    );
  }
}

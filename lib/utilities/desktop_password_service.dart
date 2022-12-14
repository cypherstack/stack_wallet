import 'package:hive/hive.dart';
import 'package:stack_wallet_backup/secure_storage.dart';
import 'package:stackwallet/hive/db.dart';
import 'package:stackwallet/utilities/logger.dart';

const String _kKeyBlobKey = "swbKeyBlobKeyStringID";

String _getMessageFromException(Object exception) {
  if (exception is IncorrectPassphrase) {
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
      _handler = await StorageCryptoHandler.fromNewPassphrase(passphrase);

      final box = await Hive.openBox<String>(DB.boxNameDesktopData);
      await DB.instance.put<String>(
        boxName: DB.boxNameDesktopData,
        key: _kKeyBlobKey,
        value: await _handler!.getKeyBlob(),
      );
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
      _handler = await StorageCryptoHandler.fromExisting(passphrase, keyBlob);
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
      await StorageCryptoHandler.fromExisting(passphrase, keyBlob);
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

    try {
      await _handler!.resetPassphrase(passphraseNew);

      final box = await Hive.openBox<String>(DB.boxNameDesktopData);
      await DB.instance.put<String>(
        boxName: DB.boxNameDesktopData,
        key: _kKeyBlobKey,
        value: await _handler!.getKeyBlob(),
      );
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
}

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:stack_wallet_backup/secure_storage.dart';
import 'package:epicmobile/utilities/flutter_secure_storage_interface.dart';
import 'package:epicmobile/utilities/logger.dart';

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
  final SecureStorageWrapper secureStorageWrapper;

  StorageCryptoHandler get handler {
    if (_handler == null) {
      throw Exception(
          "DPS: attempted to access handler without proper authentication");
    }
    return _handler!;
  }

  DPS({
    this.secureStorageWrapper = const SecureStorageWrapper(
      FlutterSecureStorage(),
    ),
  });

  Future<void> initFromNew(String passphrase) async {
    if (_handler != null) {
      throw Exception("DPS: attempted to re initialize with new passphrase");
    }

    try {
      _handler = await StorageCryptoHandler.fromNewPassphrase(passphrase);
      await secureStorageWrapper.write(
        key: _kKeyBlobKey,
        value: await _handler!.getKeyBlob(),
      );
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
    final keyBlob = await secureStorageWrapper.read(key: _kKeyBlobKey);

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
      rethrow;
    }
  }

  Future<bool> hasPassword() async {
    return (await secureStorageWrapper.read(key: _kKeyBlobKey)) != null;
  }
}

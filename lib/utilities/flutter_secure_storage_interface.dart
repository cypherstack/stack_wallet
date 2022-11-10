import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:isar/isar.dart';
import 'package:stack_wallet_backup/secure_storage.dart';
import 'package:stackwallet/models/isar/models/encrypted_string_value.dart';

abstract class SecureStorageInterface {
  dynamic get store;

  Future<void> write({
    required String key,
    required String? value,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  });

  Future<String?> read({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  });

  Future<void> delete({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  });
}

class DesktopSecureStore {
  final StorageCryptoHandler handler;
  late final Isar isar;

  DesktopSecureStore(this.handler);

  Future<void> init() async {
    Directory? appDirectory;
    if (Platform.isLinux) {
      appDirectory = Directory("${Platform.environment['HOME']}/.stackwallet");
      await appDirectory.create();
    }
    isar = await Isar.open(
      [EncryptedStringValueSchema],
      directory: appDirectory!.path,
      inspector: false,
      name: "desktopStore",
    );
  }

  Future<String?> read({
    required String key,
  }) async {
    final value =
        await isar.encryptedStringValues.filter().keyEqualTo(key).findFirst();

    // value does not exist;
    if (value == null) {
      return null;
    }

    return await handler.decryptValue(key, value.value);
  }

  Future<void> write({
    required String key,
    required String? value,
  }) async {
    if (value == null) {
      // here we assume that a value is to be deleted
      await isar.writeTxn(() async {
        await isar.encryptedStringValues.deleteByKey(key);
      });
    } else {
      // otherwise created encrypted object value
      final object = EncryptedStringValue();
      object.key = key;
      object.value = await handler.encryptValue(key, value);

      // store object value
      await isar.writeTxn(() async {
        await isar.encryptedStringValues.put(object);
      });
    }
  }

  Future<void> delete({
    required String key,
  }) async {
    await isar.writeTxn(() async {
      await isar.encryptedStringValues.deleteByKey(key);
    });
  }
}

/// all *Options params ignored on desktop
class SecureStorageWrapper implements SecureStorageInterface {
  final dynamic _store;
  final bool _isDesktop;

  @override
  dynamic get store => _store;

  const SecureStorageWrapper({
    required dynamic store,
    required bool isDesktop,
  })  : assert(isDesktop
            ? store is DesktopSecureStore
            : store is FlutterSecureStorage),
        _store = store,
        _isDesktop = isDesktop;

  @override
  Future<String?> read({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (_isDesktop) {
      return await (_store as DesktopSecureStore).read(key: key);
    } else {
      return await (_store as FlutterSecureStorage).read(
        key: key,
        iOptions: iOptions,
        aOptions: aOptions,
        lOptions: lOptions,
        webOptions: webOptions,
        mOptions: mOptions,
        wOptions: wOptions,
      );
    }
  }

  @override
  Future<void> write({
    required String key,
    required String? value,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (_isDesktop) {
      return await (_store as DesktopSecureStore).write(key: key, value: value);
    } else {
      return await (_store as FlutterSecureStorage).write(
        key: key,
        value: value,
        iOptions: iOptions,
        aOptions: aOptions,
        lOptions: lOptions,
        webOptions: webOptions,
        mOptions: mOptions,
        wOptions: wOptions,
      );
    }
  }

  @override
  Future<void> delete({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (_isDesktop) {
      return (_store as DesktopSecureStore).delete(key: key);
    } else {
      return await (_store as FlutterSecureStorage).delete(
        key: key,
        iOptions: iOptions,
        aOptions: aOptions,
        lOptions: lOptions,
        webOptions: webOptions,
        mOptions: mOptions,
        wOptions: wOptions,
      );
    }
  }
}

// Mock class for testing purposes
class FakeSecureStorage implements SecureStorageInterface {
  final Map<String, String?> _store = {};
  int _interactions = 0;
  int get interactions => _interactions;
  int _writes = 0;
  int get writes => _writes;
  int _reads = 0;
  int get reads => _reads;
  int _deletes = 0;
  int get deletes => _deletes;

  @override
  Future<String?> read({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    _interactions++;
    _reads++;
    return _store[key];
  }

  @override
  Future<void> write({
    required String key,
    required String? value,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    _interactions++;
    _writes++;
    _store[key] = value;
  }

  @override
  Future<void> delete({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    _interactions++;
    _deletes++;
    _store.remove(key);
  }

  @override
  dynamic get store => throw UnimplementedError();
}

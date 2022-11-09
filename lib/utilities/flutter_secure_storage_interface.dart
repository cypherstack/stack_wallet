import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:isar/isar.dart';
import 'package:stack_wallet_backup/secure_storage.dart';

abstract class FlutterSecureStorageInterface {
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

class DesktopPWStore {
  final StorageCryptoHandler handler;
  late final Isar isar;

  DesktopPWStore(this.handler);

  Future<void> init() async {}

  Future<String?> read({
    required String key,
  }) async {
    // final String encryptedString =

    return "";
  }

  Future<void> write({
    required String key,
    required String? value,
  }) async {
    return;
  }

  Future<void> delete({
    required String key,
  }) async {
    return;
  }
}

/// all *Options params ignored on desktop
class SecureStorageWrapper implements FlutterSecureStorageInterface {
  final dynamic _store;
  final bool _isDesktop;

  const SecureStorageWrapper({
    required dynamic store,
    required bool isDesktop,
  })  : assert(isDesktop
            ? store is DesktopPWStore
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
      return await (_store as DesktopPWStore).read(key: key);
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
      return await (_store as DesktopPWStore).write(key: key, value: value);
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
      return (_store as DesktopPWStore).delete(key: key);
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
class FakeSecureStorage implements FlutterSecureStorageInterface {
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
}

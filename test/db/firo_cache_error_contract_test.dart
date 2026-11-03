import 'dart:io';
import 'dart:isolate';

import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/db/sqlite/firo_cache.dart';
import 'package:stackwallet/utilities/stack_file_system.dart';
import 'package:stackwallet/wallets/crypto_currency/crypto_currency.dart';

Future<bool> _failsThroughFuture({required bool closed}) async {
  Directory? root;
  if (closed) {
    root = await Directory.systemTemp.createTemp('firo-close-error-');
    StackFileSystem.setDesktopOverrideDir(root.path);
    await FiroCacheCoordinator.init();
    await FiroCacheCoordinator.close();
  }
  try {
    final Future<void> result;
    try {
      result = FiroCacheCoordinator.clearSharedCache(
        CryptoCurrencyNetwork.main,
      );
    } catch (_) {
      return false;
    }
    try {
      await result;
    } catch (_) {
      return true;
    }
    return false;
  } finally {
    await root?.delete(recursive: true);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  for (final closed in [false, true]) {
    test('reset errors arrive through a Future closed=$closed', () async {
      expect(
        await Isolate.run(() => _failsThroughFuture(closed: closed)),
        isTrue,
      );
    });
  }
}

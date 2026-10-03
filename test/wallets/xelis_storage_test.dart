import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:flutter_test/flutter_test.dart';

import 'package:stackwallet/utilities/xelis_storage.dart';

void main() {
  late Directory root;
  setUp(() async {
    root = await Directory.systemTemp.createTemp('stack_xelis_path_test_');
  });
  tearDown(() async => root.delete(recursive: true));

  test(
    'resolves only the requested wallet and accepts absent native data',
    () async {
      final wallet = await Directory(path.join(root.path, 'wallet-123'))
          .create();
      expect(
        (await xelisWalletDirectory(root, 'wallet-123'))?.path,
        wallet.path,
      );
      expect(await xelisWalletDirectory(root, 'absent'), isNull);
    },
  );

  test(
    'rejects table storage, traversal and a file in place of a wallet',
    () async {
      for (final id in [
        'table',
        'TABLE',
        '..',
        '../other',
        'a/b',
        r'a\b',
        '',
      ]) {
        await expectLater(xelisWalletDirectory(root, id), throwsStateError);
      }
      await File(path.join(root.path, 'wallet-file')).writeAsString('fixture');
      await expectLater(
        xelisWalletDirectory(root, 'wallet-file'),
        throwsStateError,
      );
    },
  );
}

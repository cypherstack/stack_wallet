import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/utilities/flutter_secure_storage_interface.dart';
import 'package:stackwallet/wallets/wallet/intermediate/zcash_wallet_persistence.dart';

void main() {
  const deletionTestName =
      'deletes only one wallet Zcash files, temps, and encryption keys';
  test(deletionTestName, () async {
    final root = await Directory.systemTemp.createTemp(
      'zcash_wallet_persistence_',
    );
    addTearDown(() => root.delete(recursive: true));
    final zcashRoot = await Directory('${root.path}/zcash').create();
    const walletId = 'wallet-delete';
    const otherWalletId = 'wallet-keep';
    final deletedPaths = <String>[];
    for (final suffix in zcashWalletPersistenceSuffixes) {
      for (final temporary in [false, true]) {
        final path =
            '${zcashRoot.path}/$walletId.$suffix'
            '${temporary ? '.tmp' : ''}';
        await File(path).writeAsString('encrypted');
        deletedPaths.add(path);
      }
    }
    final retainedFile = await File('${zcashRoot.path}/$otherWalletId.state')
        .writeAsString('retain');
    final parametersDirectory = await Directory(
      '${zcashRoot.path}/proving-parameters',
    ).create();
    final retainedParameters = await File(
      '${parametersDirectory.path}/sapling-spend.params',
    ).writeAsString('retain');
    final secrets = FakeSecureStorage();
    for (final key in zcashWalletPersistenceKeys(walletId)) {
      await secrets.write(key: key, value: 'secret');
    }
    const unrelatedKey = 'unrelated-secret';
    await secrets.write(key: unrelatedKey, value: 'retain');

    await deleteZcashWalletPersistence(
      applicationRoot: root,
      walletId: walletId,
      secureStorage: secrets,
    );

    for (final path in deletedPaths) {
      expect(await File(path).exists(), isFalse, reason: path);
    }
    for (final key in zcashWalletPersistenceKeys(walletId)) {
      expect(await secrets.read(key: key), isNull, reason: key);
    }
    expect(await retainedFile.readAsString(), 'retain');
    expect(await retainedParameters.readAsString(), 'retain');
    expect(await secrets.read(key: unrelatedKey), 'retain');
  });

  test(
    'retains encryption keys when any persisted file cannot be deleted',
    () async {
      final root = await Directory.systemTemp.createTemp(
        'zcash_wallet_persistence_failure_',
      );
      addTearDown(() => root.delete(recursive: true));
      final zcashRoot = await Directory('${root.path}/zcash').create();
      const walletId = 'wallet-file-failure';
      await Directory('${zcashRoot.path}/$walletId.state').create();
      await File('${zcashRoot.path}/$walletId.pending')
          .writeAsString('encrypted');
      final secrets = FakeSecureStorage();
      for (final key in zcashWalletPersistenceKeys(walletId)) {
        await secrets.write(key: key, value: 'secret');
      }

      await expectLater(
        deleteZcashWalletPersistence(
          applicationRoot: root,
          walletId: walletId,
          secureStorage: secrets,
        ),
        throwsA(isA<FileSystemException>()),
      );

      for (final key in zcashWalletPersistenceKeys(walletId)) {
        expect(await secrets.read(key: key), 'secret', reason: key);
      }
    },
  );

  test('refuses a wallet id that could escape the Zcash directory', () async {
    final root = await Directory.systemTemp.createTemp(
      'zcash_wallet_persistence_traversal_',
    );
    addTearDown(() => root.delete(recursive: true));
    await Directory('${root.path}/zcash').create();
    final outside = await File('${root.path}/outside.state')
        .writeAsString('retain');
    const walletId = '../outside';
    final secrets = FakeSecureStorage();
    final stateKey = zcashWalletStateKey(walletId);
    await secrets.write(key: stateKey, value: 'retain');

    await expectLater(
      deleteZcashWalletPersistence(
        applicationRoot: root,
        walletId: walletId,
        secureStorage: secrets,
      ),
      throwsArgumentError,
    );

    expect(await outside.readAsString(), 'retain');
    expect(await secrets.read(key: stateKey), 'retain');
  });

  test('removes an exact symlink without following its target', () async {
    final root = await Directory.systemTemp.createTemp(
      'zcash_wallet_persistence_link_',
    );
    addTearDown(() => root.delete(recursive: true));
    final zcashRoot = await Directory('${root.path}/zcash').create();
    const walletId = 'wallet-link';
    final outside = await File('${root.path}/outside').writeAsString('retain');
    final link = await Link('${zcashRoot.path}/$walletId.state')
        .create(outside.path);
    final secrets = FakeSecureStorage();
    for (final key in zcashWalletPersistenceKeys(walletId)) {
      await secrets.write(key: key, value: 'secret');
    }

    await deleteZcashWalletPersistence(
      applicationRoot: root,
      walletId: walletId,
      secureStorage: secrets,
    );

    expect(await link.exists(), isFalse);
    expect(await outside.readAsString(), 'retain');
    for (final key in zcashWalletPersistenceKeys(walletId)) {
      expect(await secrets.read(key: key), isNull, reason: key);
    }
  });
}

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart' show Box;
import 'package:stack_wallet_backup/secure_storage.dart';
import 'package:stackwallet/db/hive/db.dart';
import 'package:stackwallet/utilities/desktop_password_service.dart';

const _blobKey = "swbKeyBlobKeyStringID";
const _versionKey = "swbKeyBlobVersionKeyStringID";

void main() {
  late Directory tempDirectory;

  setUp(() async {
    await DB.instance.hive.close();
    tempDirectory = await Directory.systemTemp.createTemp("dps_test_");
    DB.instance.hive.init(tempDirectory.path);
  });

  tearDown(() async {
    await DB.instance.hive.close();
    await tempDirectory.delete(recursive: true);
  });

  test("new password persists in the legacy-compatible format", () async {
    const passphrase = "correct horse battery staple";
    final service = DPS();
    await service.initFromNew(passphrase);

    final stored = await _readStoredCredentials();
    expect(stored.keys, {_blobKey, _versionKey});
    expect(stored.version, kLatestBlobVersion.toString());
    await StorageCryptoHandler.fromExisting(
      passphrase,
      stored.blob!,
      int.parse(stored.version!),
    );

    final restarted = DPS();
    await restarted.initFromExisting(passphrase);
    expect(await restarted.verifyPassphrase(passphrase), isTrue);
  });

  test("failed setup does not install an in-memory handler", () async {
    final service = DPS();
    final initialization = service.initFromNew("new password");
    final blockingBox = await _openIncompatibleBox();
    try {
      await expectLater(initialization, throwsA(anything));
      expect(() => service.handler, throwsException);
    } finally {
      await blockingBox.close();
    }

    await service.initFromNew("new password");
    expect(await service.verifyPassphrase("new password"), isTrue);
  });

  test("password change is atomic from the service's perspective", () async {
    const field = "wallet secret";
    const plaintext = "seed material";
    final service = DPS();
    await service.initFromNew("old password");
    final ciphertext = await service.handler.encryptValue(field, plaintext);
    final originalBlob = (await _readStoredCredentials()).blob!;
    expect(await _desktopDataFileContains(tempDirectory, originalBlob), isTrue);

    final failedChange = service.changePassphrase(
      "old password",
      "failed password",
    );
    final blockingBox = await _openIncompatibleBox();
    try {
      expect(await failedChange, isFalse);
    } finally {
      await blockingBox.close();
    }

    expect((await _readStoredCredentials()).blob, originalBlob);
    expect(await service.verifyPassphrase("old password"), isTrue);

    final compactionBlocker = Directory(
      _desktopDataPath(tempDirectory, "hivec"),
    );
    await compactionBlocker.create();
    try {
      expect(
        await service.changePassphrase("old password", "new password"),
        isTrue,
      );
    } finally {
      await compactionBlocker.delete();
    }
    final stored = await _readStoredCredentials();
    expect(stored.blob, isNot(originalBlob));
    expect(stored.version, kLatestBlobVersion.toString());
    expect(await _desktopDataFileContains(tempDirectory, originalBlob), isTrue);

    final restarted = DPS();
    expect(await restarted.verifyPassphrase("old password"), isFalse);
    await restarted.initFromExisting("new password");
    expect(await restarted.handler.decryptValue(field, ciphertext), plaintext);
    expect(
      await _desktopDataFileContains(tempDirectory, originalBlob),
      isFalse,
    );
  });

  test("failed automatic upgrade stays usable and retries", () async {
    const passphrase = "legacy password";
    const field = "wallet secret";
    const plaintext = "seed material";
    final oldHandler = await StorageCryptoHandler.fromNewPassphrase(
      passphrase,
      1,
    );
    final oldBlob = await oldHandler.getKeyBlob();
    final ciphertext = await oldHandler.encryptValue(field, plaintext);
    await _writeStoredCredentials(blob: oldBlob, version: 1);

    final firstLogin = DPS();
    final initialization = firstLogin.initFromExisting(passphrase);
    final blockingBox = await _openIncompatibleBox();
    try {
      await initialization;
      expect(
        await firstLogin.handler.decryptValue(field, ciphertext),
        plaintext,
      );
    } finally {
      await blockingBox.close();
    }

    var stored = await _readStoredCredentials();
    expect(stored.blob, oldBlob);
    expect(stored.version, "1");

    final retriedLogin = DPS();
    await retriedLogin.initFromExisting(passphrase);
    stored = await _readStoredCredentials();
    expect(stored.blob, isNot(oldBlob));
    expect(stored.version, kLatestBlobVersion.toString());
    expect(
      await retriedLogin.handler.decryptValue(field, ciphertext),
      plaintext,
    );
    expect(await _desktopDataFileContains(tempDirectory, oldBlob), isFalse);

    final restarted = DPS();
    await restarted.initFromExisting(passphrase);
    expect(await restarted.handler.decryptValue(field, ciphertext), plaintext);
  });

  test("interrupted upgrade states recover and finish at latest", () async {
    const passphrase = "legacy password";

    final latestHandler = await StorageCryptoHandler.fromNewPassphrase(
      passphrase,
      kLatestBlobVersion,
    );
    final latestBlob = await latestHandler.getKeyBlob();
    await _writeStoredCredentials(blob: latestBlob);
    await DPS().initFromExisting(passphrase);
    var stored = await _readStoredCredentials();
    expect(stored.blob, latestBlob);
    expect(stored.version, kLatestBlobVersion.toString());

    await DB.instance.hive.deleteBoxFromDisk(kBoxNameDesktopData);
    final oldHandler = await StorageCryptoHandler.fromNewPassphrase(
      passphrase,
      1,
    );
    final oldBlob = await oldHandler.getKeyBlob();
    await _writeStoredCredentials(blob: oldBlob, version: kLatestBlobVersion);
    await DPS().initFromExisting(passphrase);
    stored = await _readStoredCredentials();
    expect(stored.blob, isNot(oldBlob));
    expect(stored.version, kLatestBlobVersion.toString());
  });
}

Future<({String? blob, String? version, Set<dynamic> keys})>
_readStoredCredentials() async {
  final box = await DB.instance.hive.openBox<String>(kBoxNameDesktopData);
  final result = (
    blob: box.get(_blobKey),
    version: box.get(_versionKey),
    keys: box.keys.toSet(),
  );
  await box.close();
  return result;
}

Future<void> _writeStoredCredentials({
  required String blob,
  int? version,
}) async {
  final box = await DB.instance.hive.openBox<String>(kBoxNameDesktopData);
  await box.put(_blobKey, blob);
  if (version != null) {
    await box.put(_versionKey, version.toString());
  }
  await box.close();
}

Future<Box<Object?>> _openIncompatibleBox() async {
  final deadline = DateTime.now().add(const Duration(seconds: 5));
  while (true) {
    try {
      return await DB.instance.hive.openBox<Object?>(kBoxNameDesktopData);
    } catch (_) {
      if (DateTime.now().isAfter(deadline)) {
        rethrow;
      }
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
  }
}

String _desktopDataPath(Directory directory, String extension) =>
    "${directory.path}${Platform.pathSeparator}"
    "${kBoxNameDesktopData.toLowerCase()}.$extension";

Future<bool> _desktopDataFileContains(Directory directory, String value) async {
  final bytes = await File(_desktopDataPath(directory, "hive")).readAsBytes();
  return latin1.decode(bytes).contains(value);
}

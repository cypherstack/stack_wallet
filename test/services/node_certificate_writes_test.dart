import 'dart:async';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/db/hive/db.dart';
import 'package:stackwallet/models/node_form_data.dart';
import 'package:stackwallet/models/node_model.dart';
import 'package:stackwallet/services/node_service.dart';
import 'package:stackwallet/utilities/flutter_secure_storage_interface.dart';
import 'package:stackwallet/wallets/crypto_currency/crypto_currency.dart';

import '../hive/hive_ce_test_utils.dart';
import '../utilities/tls_test_server.dart';

class _PausedPassword extends FakeSecureStorage {
  final started = Completer<void>();
  final release = Completer<void>();
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
    started.complete();
    await release.future;
    await super.delete(key: key);
  }
}

void main() {
  final coin = Bitcoin(CryptoCurrencyNetwork.main);
  late NodeService service;
  late FakeSecureStorage storage;
  late NodeModel original;
  late String pem;
  NodeModel current() => service.getNodeById(id: original.id)!;
  NodeFormData approved(NodeModel node) =>
      NodeFormData.fromNode(node)..trustedCertificatePem = pem;

  setUp(() async {
    await setUpHiveCeTest();
    if (!DB.instance.hive.isAdapterRegistered(12)) {
      DB.instance.hive.registerAdapter(NodeModelAdapter());
    }
    final box = await DB.instance.hive.openBox<NodeModel>(DB.boxNameNodeModels);
    storage = FakeSecureStorage();
    service = NodeService(secureStorageInterface: storage);
    original = NodeModel(
      host: 'node.example',
      port: 50002,
      name: 'Node',
      id: 'n',
      useSSL: true,
      enabled: true,
      coinName: coin.identifier,
      isFailover: true,
      isDown: false,
      torEnabled: true,
      clearnetEnabled: true,
      isPrimary: false,
    );
    await box.put(original.id, original);
    pem = TlsElectrumServer.certificate('node_a');
  });
  tearDown(tearDownHiveCeTest);

  test('a certificate-only write keeps node metadata and never reads or changes credentials', () async {
    expect(identical(current(), current()), true);
    expect(
      await service.saveTrustedCertificate(original, approved(original)),
      true,
    );
    expect(current().trustedCertificatePem, pem);
    expect(current().name, original.name);
    expect(current().isPrimary, false);
    expect(storage.interactions, 0);
  });

  for (final change in [
    'forget empty',
    'forget approved',
    'replace',
    'endpoint',
    'delete',
  ]) {
    test('a late approval cannot undo $change', () async {
      if (change == 'forget approved') {
        await service.saveTrustedCertificate(original, approved(original));
        original = current();
      }
      final result = approved(original);
      switch (change) {
        case 'forget empty':
        case 'forget approved':
          await service.forgetTrustedCertificate(original);
        case 'replace':
          final replacement = approved(original)
            ..trustedCertificatePem = TlsElectrumServer.certificate('node_b');
          await service.saveTrustedCertificate(original, replacement);
        case 'endpoint':
          await DB.instance.put<NodeModel>(
            boxName: DB.boxNameNodeModels,
            key: original.id,
            value: original.copyWith(
              host: 'elsewhere.example',
              loginName: null,
              trusted: null,
            ),
          );
        case 'delete':
          await DB.instance.delete<NodeModel>(
            boxName: DB.boxNameNodeModels,
            key: original.id,
          );
      }
      final before = service.getNodeById(id: original.id);
      expect(await service.saveTrustedCertificate(original, result), false);
      expect(identical(service.getNodeById(id: original.id), before), true);
    });
  }

  test(
    'a queued approval checks the row after an earlier queued Forget',
    () async {
      await DB.instance.mutex.acquire();
      final forgotten = service.forgetTrustedCertificate(original);
      final late = service.saveTrustedCertificate(original, approved(original));
      DB.instance.mutex.release();
      expect(await forgotten, true);
      expect(await late, false);
      expect(current().trustedCertificatePem, null);
    },
  );

  test(
    'a Save waiting for the password cannot restore a forgotten certificate',
    () async {
      await service.saveTrustedCertificate(original, approved(original));
      final opened = current();
      final paused = _PausedPassword();
      final editor = NodeService(secureStorageInterface: paused);
      final saving = editor.saveEdit(
        opened.copyWith(name: 'Edited', loginName: null, trusted: null),
        null,
        true,
        opened: opened,
      );
      await paused.started.future;
      await service.forgetTrustedCertificate(opened);
      paused.release.complete();
      expect(await saving, true);
      expect(current().name, 'Edited');
      expect(current().trustedCertificatePem, null);
    },
  );

  test('an explicit staged Forget wins an approval made before Save', () async {
    await service.saveTrustedCertificate(original, approved(original));
    final edited = original.copyWith(
      loginName: null,
      trusted: null,
      clearTrustedCertificate: true,
    );
    expect(
      await service.saveEdit(
        edited,
        null,
        true,
        opened: original,
        forgetCertificate: true,
      ),
      true,
    );
    expect(current().trustedCertificatePem, null);
  });

  test(
    'a fresh test discards stale form trust and can approve after Forget',
    () async {
      await service.saveTrustedCertificate(original, approved(original));
      final form = NodeFormData.fromNode(current());
      await service.forgetTrustedCertificate(current());
      expect(service.prepareCertificateTest(form), true);
      expect(form.trustedCertificatePem, null);
      form.trustedCertificatePem = pem;
      final edit = current().copyWith(
        loginName: null,
        trusted: null,
        trustedCertificatePem: form.trustedCertificatePem,
      );
      expect(
        await service.saveEdit(edit, null, true, opened: form.source!),
        true,
      );
      expect(current().trustedCertificatePem, pem);
    },
  );

  test('a staged Forget survives preparing another test after an external approval', () async {
    final form = NodeFormData.fromNode(original)..forgetCertificate();
    await service.saveTrustedCertificate(original, approved(original));
    expect(service.prepareCertificateTest(form), true);
    expect(form.certificateForgotten, true);
    expect(form.trustedCertificatePem, null);
  });

  for (final flag in ['primary', 'enabled', 'failover']) {
    test(
      'updating $flag keeps the latest certificate and credentials',
      () async {
        await service.saveTrustedCertificate(original, approved(original));
        switch (flag) {
          case 'primary':
            await service.setPrimaryNodeFor(coin: coin, node: original);
          case 'enabled':
            await service.setEnabledState(original.id, false, true);
          case 'failover':
            await service.setFailover(original.id, false);
        }
        expect(current().trustedCertificatePem, pem);
        expect(storage.interactions, 0);
      },
    );
  }

  test('Connect stores its approval and primary flag together without touching credentials', () async {
    expect(
      await service.commitConnectionTest(
        node: original,
        formData: approved(original),
      ),
      true,
    );
    expect(current().trustedCertificatePem, pem);
    expect(current().isPrimary, true);
    expect(storage.interactions, 0);
  });

  for (final change in ['Forget', 'edit', 'delete']) {
    test('Connect cannot promote or restore trust after $change', () async {
      final result = approved(original);
      switch (change) {
        case 'Forget':
          await service.forgetTrustedCertificate(original);
        case 'edit':
          await DB.instance.put<NodeModel>(
            boxName: DB.boxNameNodeModels,
            key: original.id,
            value: original.copyWith(
              host: 'new.example',
              loginName: null,
              trusted: null,
            ),
          );
        case 'delete':
          await DB.instance.delete<NodeModel>(
            boxName: DB.boxNameNodeModels,
            key: original.id,
          );
      }
      expect(
        await service.commitConnectionTest(node: original, formData: result),
        false,
      );
      expect(service.getPrimaryNodeFor(currency: coin), null);
    });
  }

  test(
    'an edited endpoint keeps only the approval tested for that endpoint',
    () async {
      final form = approved(original)..host = 'new.example';
      expect(form.trustedCertificatePem, null);
      form.trustedCertificatePem = pem;
      final edited = original.copyWith(
        host: form.host,
        loginName: null,
        trusted: null,
        trustedCertificatePem: form.trustedCertificatePem,
      );
      expect(
        await service.saveEdit(edited, null, true, opened: original),
        true,
      );
      expect(current().host, 'new.example');
      expect(current().trustedCertificatePem, pem);
    },
  );
}

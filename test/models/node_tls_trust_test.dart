import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:stackwallet/models/node_form_data.dart';
import 'package:stackwallet/models/node_model.dart';

import '../utilities/tls_test_server.dart';

NodeModel tlsNode({String? certificatePem}) => NodeModel(
  host: '127.0.0.1',
  port: 50002,
  name: 'TLS node',
  id: 'tls-node',
  useSSL: true,
  enabled: true,
  coinName: 'bitcoin',
  isFailover: false,
  isDown: false,
  trusted: false,
  torEnabled: true,
  clearnetEnabled: true,
  isPrimary: false,
  trustedCertificatePem: certificatePem,
);

void main() {
  final pem = TlsElectrumServer.certificate('node_a');

  test(
    'backup round trip preserves TLS approval independently of daemon trust',
    () {
      final node = tlsNode(certificatePem: pem);
      final restored = NodeModel.fromStackBackup(node.toMap());
      expect(restored.trustedCertificatePem, pem);
      expect(restored.trusted, false);
      final legacy = node.toMap()..remove('trustedCertificatePem');
      expect(NodeModel.fromStackBackup(legacy).trustedCertificatePem, null);
    },
  );

  test(
    'node edits preserve approval for the same endpoint and can revoke it',
    () {
      final node = tlsNode(certificatePem: pem);
      expect(
        node
            .copyWith(name: 'Renamed', loginName: null, trusted: false)
            .trustedCertificatePem,
        pem,
      );
      expect(
        node
            .copyWith(
              loginName: null,
              trusted: false,
              clearTrustedCertificate: true,
            )
            .trustedCertificatePem,
        null,
      );
      expect(
        node
            .copyWith(host: 'another.example', loginName: null, trusted: false)
            .trustedCertificatePem,
        null,
      );
      expect(
        node
            .copyWith(port: 50003, loginName: null, trusted: false)
            .trustedCertificatePem,
        null,
      );
      expect(
        node
            .copyWith(useSSL: false, loginName: null, trusted: false)
            .trustedCertificatePem,
        null,
      );
    },
  );

  test('form edits clear approval only when the endpoint changes', () {
    final data = NodeFormData.fromNode(tlsNode(certificatePem: pem));
    data.name = 'Renamed';
    data.host = data.host;
    data.port = data.port;
    data.useSSL = data.useSSL;
    expect(data.trustedCertificatePem, pem);
    data.host = 'another.example';
    expect(data.trustedCertificatePem, null);
    data.trustedCertificatePem = pem;
    data.port = 50003;
    expect(data.trustedCertificatePem, null);
    data.trustedCertificatePem = pem;
    data.useSSL = false;
    expect(data.trustedCertificatePem, null);
  });

  test('restoring an edited endpoint restores its approval', () {
    final data = NodeFormData.fromNode(tlsNode(certificatePem: pem));
    data.host = 'another.example';
    expect(data.trustedCertificatePem, null);
    data.host = '127.0.0.1';
    expect(data.trustedCertificatePem, pem);
    data.port = 50003;
    data.port = 50002;
    data.useSSL = false;
    data.useSSL = true;
    expect(data.trustedCertificatePem, pem);
    expect(data.matchesEndpointOf(tlsNode()), true);
    data.trustedCertificatePem = null;
    data.host = 'another.example';
    data.host = '127.0.0.1';
    expect(data.trustedCertificatePem, null);
  });

  test(
    'manual Hive adapter persists approval across close and reopen',
    () async {
      final directory = await Directory.systemTemp.createTemp('node_tls_hive');
      Hive.init(directory.path);
      Hive.resetAdapters();
      Hive.registerAdapter(NodeModelAdapter());
      try {
        var box = await Hive.openBox<NodeModel>('nodes');
        await box.put('node', tlsNode(certificatePem: pem));
        await box.close();
        box = await Hive.openBox<NodeModel>('nodes');
        expect(box.get('node')!.trustedCertificatePem, pem);
        expect(box.get('node')!.trusted, false);
        await box.close();
      } finally {
        await Hive.close();
        Hive.resetAdapters();
        await directory.delete(recursive: true);
      }
    },
  );

  test('manual Hive adapter reads legacy nodes without migration', () async {
    final directory = await Directory.systemTemp.createTemp('node_tls_legacy');
    Hive.init(directory.path);
    Hive.registerAdapter(_LegacyNodeAdapter(), override: true);
    try {
      var box = await Hive.openBox<NodeModel>('nodes');
      await box.put('node', tlsNode());
      await box.close();
      Hive.resetAdapters();
      Hive.registerAdapter(NodeModelAdapter());
      box = await Hive.openBox<NodeModel>('nodes');
      expect(box.get('node')!.trustedCertificatePem, null);
      expect(box.get('node')!.host, '127.0.0.1');
      await box.close();
    } finally {
      await Hive.close();
      Hive.resetAdapters();
      await directory.delete(recursive: true);
    }
  });
}

/// The sixteen fields written before TLS trust was introduced.
class _LegacyNodeAdapter extends TypeAdapter<NodeModel> {
  @override
  int get typeId => 12;

  @override
  NodeModel read(BinaryReader reader) => NodeModelAdapter().read(reader);

  @override
  void write(BinaryWriter writer, NodeModel node) {
    final fields = [
      node.id,
      node.host,
      node.port,
      node.name,
      node.useSSL,
      node.loginName,
      node.enabled,
      node.coinName,
      node.isFailover,
      node.isDown,
      node.trusted,
      node.torEnabled,
      node.clearnetEnabled,
      node.forceNoTor,
      node.isPrimary,
      node.nodeApiSecret,
    ];
    writer.writeByte(fields.length);
    for (int i = 0; i < fields.length; i++) {
      writer
        ..writeByte(i)
        ..write(fields[i]);
    }
  }
}

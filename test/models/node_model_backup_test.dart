import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/models/node_model.dart';

void main() {
  test('keeps a PEM whose contents are not a certificate', () {
    // It cannot match any server certificate, so the node is simply not
    // approved until its certificate is reviewed again.
    for (final body in ['aGVsbG8=', 'MAA=']) {
      final pem =
          '-----BEGIN CERTIFICATE-----\n$body\n-----END CERTIFICATE-----\n';
      final node = NodeModel.fromStackBackup({
        'host': 'node.example.com',
        'port': 50002,
        'name': 'Node',
        'id': 'tls',
        'coinName': 'bitcoin',
        'trustedCertificatePem': pem,
      });
      expect(node.trustedCertificatePem, pem);
    }
  });

  test('restores a trusted certificate and drops a damaged one', () {
    final pem = File('test/fixtures/tls/expired.pem').readAsStringSync();
    final map = {
      'host': 'node.example.com',
      'port': 50002,
      'name': 'Node',
      'id': 'tls',
      'coinName': 'bitcoin',
      'trustedCertificatePem': pem,
    };
    expect(NodeModel.fromStackBackup(map).trustedCertificatePem, pem);
    for (final damaged in ['', 'not a certificate', 42, pem.substring(40)]) {
      map['trustedCertificatePem'] = damaged;
      expect(
        NodeModel.fromStackBackup(map).trustedCertificatePem,
        null,
        reason: '$damaged',
      );
    }
  });

  test('restores current and legacy node backup fields', () {
    final source = NodeModel(
      host: 'node.example.com',
      port: 50002,
      name: 'Node',
      id: 'current',
      useSSL: false,
      loginName: 'user',
      enabled: false,
      coinName: 'bitcoin',
      isFailover: true,
      isDown: false,
      trusted: false,
      torEnabled: false,
      clearnetEnabled: false,
      forceNoTor: true,
      isPrimary: false,
      nodeApiSecret: 'current-secret',
    );
    expect(NodeModel.fromStackBackup(source.toMap()).toMap(), source.toMap());

    final legacyMap = {
      ...source.toMap(),
      'id': 'legacy',
      'useSSL': 'false',
      'enabled': 'false',
      'isFailover': 'true',
      'trusted': 'true',
      'torEnabled': 'false',
      'plainEnabled': 'false',
      'forceNoTor': 'true',
      'nodeApiSecret': 'legacy-secret',
    };
    legacyMap.remove('clearEnabled');
    legacyMap.remove('isPrimary');
    final legacy = NodeModel.fromStackBackup(
      legacyMap,
      legacyPrimaryNodeIds: {'legacy'},
    );
    expect(
      (
        legacy.useSSL,
        legacy.enabled,
        legacy.isFailover,
        legacy.trusted,
        legacy.torEnabled,
        legacy.clearnetEnabled,
        legacy.forceNoTor,
        legacy.isPrimary,
        legacy.nodeApiSecret,
      ),
      (false, false, true, true, false, false, true, true, 'legacy-secret'),
    );
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/models/node_model.dart';

void main() {
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

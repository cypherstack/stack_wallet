import 'package:flutter_test/flutter_test.dart';

import 'memory_secrets.dart';

void main() {
  test('reads, records writes, and records deletes', () async {
    final secrets = MemorySecrets({'existing': 'value'});

    expect(await secrets.read(key: 'existing'), 'value');
    await secrets.write(key: 'new', value: 'secret');
    await secrets.delete(key: 'existing');

    expect(secrets.values, {'new': 'secret'});
    expect(secrets.writes, ['new']);
    expect(secrets.deletes, ['existing']);
  });

  test('runs the delete hook before injecting a failure', () async {
    final order = <String>[];
    final secrets = MemorySecrets({'blocked': 'value'})
      ..failingDeleteKey = 'blocked'
      ..beforeDelete = (key) async => order.add(key);

    await expectLater(
      secrets.delete(key: 'blocked'),
      throwsA(isA<StateError>()),
    );

    expect(order, ['blocked']);
    expect(secrets.values['blocked'], 'value');
    expect(secrets.deletes, isEmpty);
  });

  test('a failed write does not change storage or its audit trail', () async {
    final secrets = MemorySecrets()..failingKey = 'blocked';

    await expectLater(
      secrets.write(key: 'blocked', value: 'secret'),
      throwsA(isA<StateError>()),
    );

    expect(secrets.values.containsKey('blocked'), isFalse);
    expect(secrets.writes, isEmpty);
  });
}

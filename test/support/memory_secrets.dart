import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/utilities/flutter_secure_storage_interface.dart';

/// In-memory secure storage for wallet tests, with optional failure hooks.
class MemorySecrets extends Fake implements SecureStorageInterface {
  MemorySecrets([Map<String, String>? initial])
    : values = initial ?? {'xelis_wants_full_tables': 'false'};

  final Map<String, String> values;
  final List<String> writes = [];
  final List<String> deletes = [];
  String? failingKey;
  String? failingDeleteKey;
  Future<void> Function(String)? beforeDelete;

  @override
  dynamic noSuchMethod(Invocation invocation) {
    final key = invocation.namedArguments[#key] as String;
    switch (invocation.memberName) {
      case #delete:
        return () async {
          await beforeDelete?.call(key);
          if (key == failingDeleteKey) {
            throw StateError('fixture delete failure');
          }
          deletes.add(key);
          values.remove(key);
        }();
      case #read:
        return Future<String?>.value(values[key]);
      case #write:
        if (key == failingKey) {
          return Future<void>.error(StateError('fixture write failure'));
        }
        writes.add(key);
        values[key] = invocation.namedArguments[#value] as String;
        return Future<void>.value();
      default:
        return super.noSuchMethod(invocation);
    }
  }
}

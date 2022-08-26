import 'package:flutter_test/flutter_test.dart';
import 'package:hive_test/hive_test.dart';

void main() {
  setUp(() async {
    await setUpTestHive();
  });

  // no migration to test yet

  tearDown(() async {
    await tearDownTestHive();
  });
}

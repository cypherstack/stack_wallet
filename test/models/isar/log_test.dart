import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/models/isar/models/log.dart';
import 'package:stackwallet/utilities/logger.dart';

void main() {
  test("Log class", () {
    final log = Log()
      ..message = "hello"
      ..timestampInMillisUTC = 100000001
      ..logLevel = LogLevel.Fatal;

    expect(log.toString(), "[Fatal][1970-01-02 03:46:40.001Z]: hello");
    expect(log.id, -9223372036854775808);
  });
}

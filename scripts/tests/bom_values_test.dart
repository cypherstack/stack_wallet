// Tests for scripts/bom_values.sh --check and --get.
//
// Run with: dart scripts/tests/bom_values_test.dart
//
// Exercises the real shell script against temp BOM files, so it covers the
// sed/grep quoting and the x.y / x.y.z validation that the Dart side cannot.
import 'dart:io';

import 'package:test/test.dart';

const script = 'scripts/bom_values.sh';

void main() {
  late Directory root;

  setUp(() {
    root = Directory.systemTemp.createTempSync('bom_values_');
  });

  tearDown(() {
    root.deleteSync(recursive: true);
  });

  String writeBom(String body) {
    final file = File('${root.path}/stack-bom.toml');
    file.writeAsStringSync(body);
    return file.path;
  }

  ProcessResult run(String args) =>
      Process.runSync('bash', [script, ...args.split(' ')]);

  test('--check passes a well-formed BOM', () {
    final bom = writeBom('''
schema_version = "1"

[toolchain]
rust = "1.99.1"
dnssec_rust = "1.90.0"
flutter = "3.47.2"
flutter_min = "3.47.0"
dart_prefix = "3.10"
go = "1.27.4"
go_min = "1.27.0"

[macos]
xcode = "27.0"
xcode_dnix = "27.0"
''');
    final result = run('--check $bom');
    expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
    expect(result.stdout, contains('BOM values OK'));
  });

  test('--check rejects an invalid x.y.z version', () {
    final bom = writeBom('''
[toolchain]
rust = "1.99"
dnssec_rust = "1.90.0"
flutter = "3.47.2"
flutter_min = "3.47.0"
dart_prefix = "3.10"
go = "1.27.4"
go_min = "1.27.0"

[macos]
xcode = "27.0"
xcode_dnix = "27.0"
''');
    final result = run('--check $bom');
    expect(result.exitCode, 1, reason: '${result.stdout}\n${result.stderr}');
    expect(result.stderr, contains('Invalid'));
  });

  test('--check rejects a non x.y xcode value', () {
    final bom = writeBom('''
[toolchain]
rust = "1.99.1"
dnssec_rust = "1.90.0"
flutter = "3.47.2"
flutter_min = "3.47.0"
dart_prefix = "3.10"
go = "1.27.4"
go_min = "1.27.0"

[macos]
xcode = "27.0.1"
xcode_dnix = "27.0"
''');
    final result = run('--check $bom');
    expect(result.exitCode, 1, reason: '${result.stdout}\n${result.stderr}');
    expect(result.stderr, contains('Invalid'));
  });

  test('--check rejects a duplicate section', () {
    final bom = writeBom('''
[toolchain]
rust = "1.99.1"
dnssec_rust = "1.90.0"
flutter = "3.47.2"
flutter_min = "3.47.0"
dart_prefix = "3.10"
go = "1.27.4"
go_min = "1.27.0"

[macos]
xcode = "27.0"
xcode_dnix = "27.0"

[macos]
xcode = "28.0"
xcode_dnix = "28.0"
''');
    final result = run('--check $bom');
    expect(result.exitCode, 1, reason: '${result.stdout}\n${result.stderr}');
    expect(result.stderr, contains('Duplicate'));
  });

  test('--check rejects a missing key', () {
    final bom = writeBom('''
[toolchain]
rust = "1.99.1"
flutter = "3.47.2"
flutter_min = "3.47.0"
dart_prefix = "3.10"
go = "1.27.4"
go_min = "1.27.0"

[macos]
xcode = "27.0"
xcode_dnix = "27.0"
''');
    final result = run('--check $bom');
    expect(result.exitCode, 1, reason: '${result.stdout}\n${result.stderr}');
    expect(result.stderr, contains('Missing'));
  });

  test('--get returns a single value', () {
    final bom = writeBom('''
[toolchain]
rust = "1.99.1"
flutter = "3.47.2"
flutter_min = "3.47.0"
dart_prefix = "3.10"
go = "1.27.4"
go_min = "1.27.0"

[macos]
xcode = "27.0"
xcode_dnix = "27.0"
''');
    final result = run('--get rust $bom');
    expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
    expect(result.stdout.trim(), '1.99.1');
  });

  test('--get rejects an unknown key', () {
    final bom = writeBom('''
[toolchain]
rust = "1.99.1"
flutter = "3.47.2"
flutter_min = "3.47.0"
dart_prefix = "3.10"
go = "1.27.4"
go_min = "1.27.0"

[macos]
xcode = "27.0"
xcode_dnix = "27.0"
''');
    final result = run('--get bogus $bom');
    expect(result.exitCode, 2, reason: '${result.stdout}\n${result.stderr}');
  });
}

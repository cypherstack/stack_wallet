// Unit tests for the BOM/lock/pubspec parser helpers in tool/bom_parser.dart.
//
// Run with: dart scripts/tests/verify_bom_parser_test.dart
//
// These cover only the pure parsing and version logic, so they run without a
// Flutter/Dart toolchain or a real checkout. File-backed helpers take their
// text as an argument, which keeps the tests hermetic.
import 'dart:io';

import 'package:test/test.dart';

import '../../tool/bom_parser.dart';

Map<String, String> section(
  Map<String, Map<String, String>> bom,
  String name,
) =>
    bom[name] ?? {};

void main() {
  group('readBom', () {
    test('parses [section] headers and key = "value" lines', () {
      final bom = readBom('''
schema_version = "1"

[toolchain]
flutter = "3.47.2"
flutter_min = "3.47.0"
''');
      expect(section(bom, '')['schema_version'], '1');
      expect(section(bom, 'toolchain')['flutter'], '3.47.2');
      expect(section(bom, 'toolchain')['flutter_min'], '3.47.0');
    });

    test('accepts tab indentation and single quotes', () {
      final bom = readBom('[toolchain]\n\tflutter = \'3.47.2\'\n');
      expect(section(bom, 'toolchain')['flutter'], '3.47.2');
    });

    test('strips a trailing inline comment on a bare value', () {
      final bom = readBom('[toolchain]\nrust = "1.99.1" # pinned by nix\n');
      expect(section(bom, 'toolchain')['rust'], '1.99.1');
    });

    test('keeps "#" inside a quoted value', () {
      final bom = readBom('[x]\nkey = "a # b"\n');
      expect(section(bom, 'x')['key'], 'a # b');
    });

    test('returns an empty map for empty or comment-only input', () {
      expect(readBom(''), isEmpty);
      expect(readBom('# just a comment\n'), isEmpty);
    });

    test('throws FormatException on an unterminated string', () {
      expect(() => readBom('[x]\nkey = "oops\n'), throwsFormatException);
    });

    test('last assignment wins for a repeated key in a section', () {
      final bom = readBom('[x]\nkey = "first"\nkey = "second"\n');
      expect(section(bom, 'x')['key'], 'second');
    });
  });

  group('compareVersions', () {
    test('orders by numeric components', () {
      expect(compareVersions('3.47.0', '3.47.2'), lessThan(0));
      expect(compareVersions('3.48.0', '3.47.9'), greaterThan(0));
      expect(compareVersions('3.47.2', '3.47.2'), 0);
    });

    test('treats missing components as zero', () {
      expect(compareVersions('3.47', '3.47.0'), 0);
      expect(compareVersions('3.47.1', '3.47'), greaterThan(0));
    });

    test('compares only the first three numeric components', () {
      // The comparator is intentionally 3-component: the leading x.y.z wins,
      // and any suffix numbers beyond it are ignored (a tie).
      expect(compareVersions('2.4.5-rc.1', '2.4.5'), 0);
      expect(compareVersions('0.0.0-staging.3', '0.0.0-staging.5'), 0);
      expect(compareVersions('0.0.0-staging.12', '0.0.0-staging.9'), 0);
      // But a differing leading component still orders the versions.
      expect(compareVersions('2.0.0-staging.1', '1.9.9'), greaterThan(0));
    });
  });

  group('shortVersion', () {
    test('keeps short strings and truncates long ones at 7 chars', () {
      expect(shortVersion('3.47.2'), '3.47.2');
      expect(shortVersion('abc1234def'), 'abc1234');
    });
  });

  group('resolveOnPath', () {
    test('returns a path-containing name unchanged', () {
      expect(
        resolveOnPath('/opt/flutter/bin/flutter', environment: {'PATH': '/x'}),
        '/opt/flutter/bin/flutter',
      );
    });

    test('resolves a bare command found on PATH', () {
      final dir = Directory.systemTemp.createTempSync('resolve_path_');
      try {
        File('${dir.path}/mytool').writeAsStringSync('#!/bin/sh\n');
        final found = resolveOnPath('mytool',
            environment: {'PATH': '${dir.path}:/nonexistent'});
        expect(found, '${dir.path}/mytool');
      } finally {
        dir.deleteSync(recursive: true);
      }
    });

    test('returns the bare name when the command is not on PATH', () {
      expect(
        resolveOnPath('definitely-not-a-real-command-xyz',
            environment: {'PATH': '/nonexistent'}),
        'definitely-not-a-real-command-xyz',
      );
    });
  });

  group('requireSinglePluginsSection', () {
    test('accepts zero or one [plugins] table', () {
      expect(() => requireSinglePluginsSection('[toolchain]\nflutter = "1"\n'),
          returnsNormally);
      expect(() => requireSinglePluginsSection('[plugins]\na = "b"\n'),
          returnsNormally);
    });

    test('throws on a duplicate [plugins] table', () {
      expect(
        () => requireSinglePluginsSection(
          '[plugins]\na = "b"\n\n[plugins]\nc = "d"\n',
        ),
        throwsFormatException,
      );
    });
  });

  group('declaredPlugins', () {
    test('finds a pinned plugin under dependencies:', () {
      const pubspec = '''
name: app
dependencies:
  flutter:
    sdk: flutter
  tor_ffi_plugin:
    git:
      url: https://example.com
''';
      expect(declaredPlugins(pubspecText: pubspec), contains('tor_ffi_plugin'));
    });

    test('finds a pinned plugin under dependency_overrides:', () {
      const pubspec = '''
dependency_overrides:
  frostdart:
    path: ../frostdart
''';
      expect(declaredPlugins(pubspecText: pubspec), contains('frostdart'));
    });

    test('ignores the hooks: user_defines: block', () {
      const pubspec = '''
hooks:
  user_defines:
    tor_ffi_plugin:
      debug: true
''';
      expect(declaredPlugins(pubspecText: pubspec), isEmpty);
    });

    test('returns empty when no known plugin is declared', () {
      const pubspec = '''
dependencies:
  flutter:
    sdk: flutter
''';
      expect(declaredPlugins(pubspecText: pubspec), isEmpty);
    });
  });

  group('lockRefs', () {
    test('reads resolved-ref for a pinned plugin', () {
      const lock = '''
  tor_ffi_plugin:
    dependency: "direct main"
    git:
      url: https://example.com
      ref: abc
    resolved-ref: deadbeefdeadbeefdeadbeefdeadbeefdeadbeef
  other_pkg:
    dependency: "direct main"
    version: "1.0.0"
''';
      final refs = lockRefs(lockText: lock);
      expect(
        refs['tor_ffi_plugin'],
        'deadbeefdeadbeefdeadbeefdeadbeefdeadbeef',
      );
      expect(refs.containsKey('other_pkg'), isFalse);
    });

    test('returns empty when no plugin is present', () {
      expect(
        lockRefs(lockText: 'packages:\n  foo:\n    version: "1"\n'),
        isEmpty,
      );
    });

    test('reads a ref from a CRLF lockfile', () {
      // A trailing CR must not break the anchored `^  (\w+):$` header.
      const lock = 'plugins:\r\n  tor_ffi_plugin:\r\n'
          '    resolved-ref: "deadbeefdeadbeefdeadbeefdeadbeefdeadbeef"\r\n';
      expect(
        lockRefs(lockText: lock)['tor_ffi_plugin'],
        'deadbeefdeadbeefdeadbeefdeadbeefdeadbeef',
      );
    });
  });
}

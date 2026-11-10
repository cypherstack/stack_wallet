import 'dart:convert';

import 'package:test/test.dart';

import '../../tool/configure_native_assets.dart';
import '../../tool/native_build_options.dart';

const template = '''hooks:
  user_defines:
    tor_ffi_plugin:
      build: PLACEHOLDER_DNIX_BUILD_MODE
      wsl_distribution: PLACEHOLDER_DNIX_WSL_DISTRIBUTION
''';

void main() {
  test('default distribution omits the setting in both build modes', () {
    for (final mode in ['source', 'prebuilt']) {
      final rendered = configureNativeAssets(template, mode, null);
      expect(rendered, contains('build: $mode\n'));
      expect(rendered, isNot(contains('wsl_distribution:')));
      expect(rendered, isNot(contains('PLACEHOLDER')));
    }
  });

  test('distribution is normalized and safely quoted as one YAML value', () {
    const name = 'Ubuntu dev: "quoted" \\ # preserved';
    final rendered = configureNativeAssets(template, 'source', '  $name  ');
    final value = rendered
        .split('\n')
        .singleWhere((line) => line.contains('wsl_distribution:'))
        .split('wsl_distribution: ')
        .last;
    expect(jsonDecode(value), name);
    expect(validatedDistribution('  $name  '), name);
  });

  test(
    'prebuilt mode retains a requested distribution for later source use',
    () {
      final rendered = configureNativeAssets(
        template,
        'prebuilt',
        'Ubuntu-24.04',
      );
      expect(rendered, contains('build: prebuilt\n'));
      expect(rendered, contains('wsl_distribution: "Ubuntu-24.04"\n'));
    },
  );

  for (final invalid in [
    '',
    '   ',
    '-Ubuntu',
    '  -Ubuntu ',
    for (final control in [...List.generate(32, (i) => i), 127])
      'Ubuntu${String.fromCharCode(control)}',
  ]) {
    test('shared validation rejects invalid name ${invalid.codeUnits}', () {
      expect(() => validatedDistribution(invalid), throwsArgumentError);
      for (final mode in ['source', 'prebuilt']) {
        expect(
          () => configureNativeAssets(template, mode, invalid),
          throwsArgumentError,
        );
      }
    });
  }
}

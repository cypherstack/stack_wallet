import 'dart:io';

import 'package:stack_wallet_branding/adapter.dart';
import 'package:stack_wallet_branding/app_config.dart';
import 'package:test/test.dart';

void main() {
  for (final name in ['stack_wallet', 'stack_duo', 'campfire']) {
    test('validates the $name consumer manifest', () {
      validateBrand(StackWalletManifest.load('brands/$name.yaml'));
    });
  }
  test('rejects arbitrary code and unknown dependency markers', () {
    final text = File('brands/campfire.yaml').readAsStringSync();
    expect(
      () => validateBrand(
        StackWalletManifest.parse(text.replaceFirst('TOR, FIRO', 'TOR, FIOR')),
      ),
      throwsFormatException,
    );
    expect(
      () => validateBrand(
        StackWalletManifest.parse(
          text.replaceFirst(
            'Firo(CryptoCurrencyNetwork.main),',
            'runUntrustedCode(),',
          ),
        ),
      ),
      throwsFormatException,
    );
    expect(
      () => StackWalletManifest.parse('$text\nunknown_key: value\n'),
      throwsFormatException,
    );
  });
  test('rejects malformed and missing dependency blocks', () {
    expect(
      () => processDependencyBlocks(
        '# %%ENABLE_TOR%%\n#  dependency: 1\n# %%END_ENABLE_TOOR%%\n# unrelated: 2\n',
        {'TOR'},
      ),
      throwsFormatException,
    );
    expect(
      () => processDependencyBlocks('dependencies:\n', {'TOR'}),
      throwsFormatException,
    );
    expect(
      processDependencyBlocks(
        '# %%ENABLE_TOR%%\n#  dependency: 1\n# %%END_ENABLE_TOR%%\n',
        {'TOR'},
      ),
      contains('\n  dependency: 1\n'),
    );
    expect(
      processDependencyBlocks(
        '# %%ENABLE_NATIVE_PREBUILTS%%\n#hooks:\n# %%END_ENABLE_NATIVE_PREBUILTS%%\n',
        {'NATIVE_PREBUILTS'},
      ),
      contains('\nhooks:\n'),
    );
  });
  test('interface blocks require matching ends and cannot nest', () {
    expect(
      () => renderInterface('//ON\nreal\n//END_OFF\n', true),
      throwsFormatException,
    );
    expect(() => renderInterface('//ON\n//OFF\n', true), throwsFormatException);
    expect(
      renderInterface('//ON\nreal\n//END_ON\n//OFF\nstub\n//END_OFF\n', false),
      '// GENERATED CODE - DO NOT MODIFY BY HAND\n\nstub\n',
    );
  });
  test('generated Dart text is escaped and IDs preserve iOS special cases', () {
    final text = File('brands/campfire.yaml').readAsStringSync();
    final brand = StackWalletManifest.parse(
      text.replaceFirst('prefix: Campfire', r'''prefix: 'Camp "Fire" $5' '''),
    );
    expect(
      renderAppConfig(brand, 'a' * 40, ''),
      contains(r'const _prefix = "Camp \"Fire\" \$5";'),
    );
    expect(brand.appIdIos, 'com.cypherstack.campfirefirowallet');
  });
  test('prerelease versions are accepted', () {
    final root = Directory.systemTemp.createTempSync('adapter-version-');
    addTearDown(() => root.deleteSync(recursive: true));
    // Version validation passes; the empty project then fails on its inputs.
    expect(
      () => planStackWallet(
        projectRoot: root.path,
        brand: StackWalletManifest.load('brands/campfire.yaml'),
        version: '0.0.0-staging.12',
        buildNumber: '12',
        platforms: {'linux'},
        revision: 'a' * 40,
      ),
      throwsA(isNot(isA<FormatException>())),
    );
  });
  test(
    'invalid versions and mismatched build flavors fail before touching project',
    () {
      final brand = StackWalletManifest.load('brands/campfire.yaml');
      expect(
        () => planStackWallet(
          projectRoot: '/does-not-exist',
          brand: brand,
          version: 'not a version',
          buildNumber: '1',
          platforms: {'linux'},
        ),
        throwsFormatException,
      );
      expect(
        () => planStackWallet(
          projectRoot: '/does-not-exist',
          brand: brand,
          version: '2.4.0',
          buildNumber: '1',
          platforms: {'linux'},
          buildFlavor: 'stack_wallet',
        ),
        throwsFormatException,
      );
    },
  );
  test(
    'Windows preparation cannot be bypassed with an invalid hash or missing artifact',
    () {
      final root = Directory.systemTemp.createTempSync('adapter-test-');
      addTearDown(() => root.deleteSync(recursive: true));
      final brand = StackWalletManifest.load('brands/stack_wallet.yaml');
      expect(
        () => planStackWallet(
          projectRoot: root.path,
          brand: brand,
          version: '2.4.0',
          buildNumber: '1',
          platforms: {'windows'},
          revision: 'a' * 40,
          windowsMwebdSha256: 'abc123',
        ),
        throwsFormatException,
      );
      expect(
        () => planStackWallet(
          projectRoot: root.path,
          brand: brand,
          version: '2.4.0',
          buildNumber: '1',
          platforms: {'windows'},
          revision: 'a' * 40,
          windowsMwebdSha256: 'a' * 64,
        ),
        throwsStateError,
      );
      expect(root.listSync(), isEmpty);
    },
  );
  test('changed manifest identity cannot silently bypass native flavors', () {
    final root = Directory.systemTemp.createTempSync('adapter-identity-');
    addTearDown(() => root.deleteSync(recursive: true));
    final file = File(
      '${root.path}/scripts/app_config/templates/android/app/build.gradle',
    );
    file.parent.createSync(recursive: true);
    file.writeAsStringSync(
      'campfire { applicationId "com.cypherstack.campfire"\nmanifestPlaceholders = [appLabel: "Campfire"]\n}',
    );
    final text = File('brands/campfire.yaml').readAsStringSync();
    final brand = StackWalletManifest.parse(
      text.replaceFirst(
        'app_id: com.cypherstack.campfire',
        'app_id: com.example.changed',
      ),
    );
    expect(
      () => validateNativeFlavor(root.path, brand, 'android'),
      throwsStateError,
    );
  });
  test('declared coins cannot use disabled implementations', () {
    final text = File('brands/campfire.yaml').readAsStringSync();
    expect(
      () => validateBrand(
        StackWalletManifest.parse(
          text.replaceFirst('enable_coins: [TOR, FIRO]', 'enable_coins: [TOR]'),
        ),
      ),
      throwsFormatException,
    );
  });
}

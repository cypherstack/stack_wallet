import 'dart:io';

import 'package:stack_wallet_branding/manifest.dart';
import 'package:stack_wallet_branding/app_config.dart';
import 'package:test/test.dart';

void main() {
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
}

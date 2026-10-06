import 'package:flutter_test/flutter_test.dart';
import 'package:platform/platform.dart' as platform;
import 'package:stackwallet/utilities/util.dart';

void main() {
  setUp(() {
    final previousPlatform = Util.layoutPlatform;
    final previousWidth = Util.screenWidth;
    final previousIsIpad = Util.isIpad;
    addTearDown(() {
      Util.layoutPlatform = previousPlatform;
      Util.screenWidth = previousWidth;
      Util.isIpad = previousIsIpad;
    });
  });

  for (final (os, width, ipad, desktop) in <(String, double?, bool, bool)>[
    ('android', 390, false, false),
    ('android', 1000, false, false),
    ('ios', 390, false, false),
    ('ios', 1024, false, false),
    ('ios', 390, true, true),
    ('ios', 1024, true, true),
    ('macos', 390, false, true),
    ('windows', 390, false, true),
    ('linux', 799, false, false),
    ('linux', 800, false, true),
    ('linux', null, false, true),
  ]) {
    test('layout for $os at width $width with isIpad=$ipad', () {
      Util.layoutPlatform = platform.FakePlatform(operatingSystem: os);
      Util.screenWidth = width;
      Util.isIpad = ipad;

      expect(Util.isDesktop, desktop);
    });
  }
}

import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/utilities/util.dart';

void main() {
  test(
    'explicit layout overrides host, viewport width, and iPad detection',
    () {
      final previousLayout = Util.debugIsDesktopOverride;
      final previousWidth = Util.screenWidth;
      final previousIpad = Util.isIpad;
      addTearDown(() {
        Util.debugIsDesktopOverride = previousLayout;
        Util.screenWidth = previousWidth;
        Util.isIpad = previousIpad;
      });

      for (final width in [390.0, 1200.0]) {
        for (final ipad in [false, true]) {
          Util.screenWidth = width;
          Util.isIpad = ipad;
          Util.debugIsDesktopOverride = null;
          final detectedLayout = Util.isDesktop;

          Util.debugIsDesktopOverride = false;
          expect(Util.isDesktop, isFalse);
          Util.debugIsDesktopOverride = true;
          expect(Util.isDesktop, isTrue);

          Util.debugIsDesktopOverride = null;
          expect(Util.isDesktop, detectedLayout);
        }
      }
    },
  );
}

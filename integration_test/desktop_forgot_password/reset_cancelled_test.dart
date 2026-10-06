import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/app_config.dart';
import 'package:stackwallet/pages_desktop_specific/password/desktop_login_view.dart';
import 'package:stackwallet/widgets/custom_buttons/app_bar_icon_button.dart';

import 'harness.dart';

void main() {
  desktopTest('backing out of forgot password deletes nothing', (t) async {
    await t.launch();
    await t.waitFor(find.byType(DesktopLoginView));
    final before = t.files();

    await t.tapText('Forgot password?');
    await t.tapText('Create new ${AppConfig.prefix}');
    await t.tapText('Take me back!');
    await t.tap(find.byType(AppBarBackButton));
    await t.waitFor(find.byType(DesktopLoginView));

    expect(t.exited, isNull);
    expect(t.files(), before);
    t.expectUnchanged(seededFiles);
    await t.expectPasswordKept();
  });
}

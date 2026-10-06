import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/app_config.dart';

import 'harness.dart';

void main() {
  desktopTest('forgot password deletes all app data and quits', (t) async {
    await t.launch();
    await t.tapText('Forgot password?');
    expect(t.openDatabases(), isNotEmpty);
    await t.tapText('Create new ${AppConfig.prefix}');
    await t.tapText('Delete everything and quit');

    final exit = await t.waitForExit();
    expect(exit.code, 0);
    expect(exit.openDatabases, isEmpty);
    expect(exit.files, {
      '.instance.lock',
      'tor',
      'tor/state',
      'wallets',
      'wallets/backup.swb',
    });
    expect(find.textContaining('was reset and will now close'), findsOneWidget);
    t.expectUnchanged(seededKeep);
    t.expectLinkTargetKept();
    t.expectLogsInTestFolder();
  });
}

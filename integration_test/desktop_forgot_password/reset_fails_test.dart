import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/app_config.dart';

import 'harness.dart';

void main() {
  desktopTest('a failed reset quits and stays pending', (t) async {
    await t.launch();
    t.blockDelete('wallets/monero/test_wallet/test_wallet.keys');
    await t.tapText('Forgot password?');
    await t.tapText('Restore from ${AppConfig.prefix} backup');
    await t.tapText('Delete everything and quit');

    final exit = await t.waitForExit();
    expect(exit.code, 1);
    expect(exit.openDatabases, isEmpty);
    expect(
      exit.files,
      containsAll([
        '.reset-pending',
        'wallets/monero/test_wallet/test_wallet.keys',
      ]),
    );
    // The password and wallet keys go first, so the reset cannot be undone.
    expect(exit.files, isNot(contains('hive/desktopdata.hive')));
    expect(exit.files, isNot(contains('isar/desktopStore.isar')));
    expect(find.textContaining('Reset could not finish'), findsOneWidget);
    t.expectUnchanged(seededKeep);
  });
}

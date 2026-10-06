import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/pages/intro_view.dart';
import 'package:stackwallet/utilities/desktop_password_service.dart';

import 'harness.dart';

void main() {
  desktopTest('retrying an unfinished reset deletes the data', (t) async {
    await t.launch(unfinishedReset: true);
    await t.tapText('Retry deleting');
    await t.waitFor(find.byType(IntroView));

    expect(t.exited, isNull);
    final files = t.files();
    expect(files, isNot(contains('.reset-pending')));
    t.expectUnchanged(seededKeep);
    // The first-run screen opens a new, empty password box.
    expect(files.intersection(seededData), {'hive/desktopdata.hive'});
    expect(await DPS().hasPassword(), isFalse);
    // Logging starts after the reset deleted the settings.
    t.expectLogsInTestFolder();
  });
}

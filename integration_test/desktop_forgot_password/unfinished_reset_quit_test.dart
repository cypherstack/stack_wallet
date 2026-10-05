import 'package:flutter_test/flutter_test.dart';

import 'harness.dart';

void main() {
  desktopTest('quitting an unfinished reset keeps everything', (t) async {
    await t.launch(unfinishedReset: true);
    await t.waitFor(find.text('Unfinished reset'));
    final before = t.files();
    expect(before, contains('.reset-pending'));

    await t.tapText('Quit');

    final exit = await t.waitForExit();
    expect(exit.code, 0);
    expect(exit.files, before);
    t.expectUnchanged(seededFiles);
    await t.expectPasswordKept();
  });
}

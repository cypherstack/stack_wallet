import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/db/hive/db.dart';
import 'package:stackwallet/services/transaction_notification_tracker.dart';

import '../hive/hive_ce_test_utils.dart';

void main() {
  setUp(() async {
    await setUpHiveCeTest();
    // Only the prefs box, matching production: DB.init never opens a box named
    // after a walletId on installs created after the Isar migration.
    await DB.instance.hive.openBox<dynamic>(DB.boxNamePrefs);
  });

  tearDown(tearDownHiveCeTest);

  test(
    "initializes only wallets present during the one-time migration",
    () async {
      await TransactionNotificationTracker.initializeExistingWallets([
        "existing-1",
        "existing-2",
      ]);

      expect(
        TransactionNotificationTracker(walletId: "existing-1").isInitialized,
        isTrue,
      );
      expect(
        TransactionNotificationTracker(walletId: "existing-2").isInitialized,
        isTrue,
      );

      await TransactionNotificationTracker.initializeExistingWallets([
        "restored-later",
      ]);
      expect(
        TransactionNotificationTracker(
          walletId: "restored-later",
        ).isInitialized,
        isFalse,
      );
    },
  );

  test("bounds the delivered transaction ledger", () async {
    final tracker = TransactionNotificationTracker(walletId: "existing-1");

    for (var i = 0; i < 300; i++) {
      await tracker.recordDelivered("tx-$i");
    }

    expect(tracker.deliveredTxids, hasLength(256));
    expect(tracker.deliveredTxids, isNot(contains("tx-0")));
    expect(tracker.deliveredTxids, contains("tx-299"));
  });
}

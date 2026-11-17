import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:stackwallet/db/hive/db.dart';
import 'package:stackwallet/db/isar/main_db.dart';
import 'package:stackwallet/models/notification_model.dart';
import 'package:stackwallet/models/trade_wallet_lookup.dart';
import 'package:stackwallet/services/node_service.dart';
import 'package:stackwallet/services/wallets.dart';
import 'package:stackwallet/wallets/isar/models/wallet_info.dart';
import 'package:stackwallet/wallets/wallet/impl/grin_wallet.dart';
import 'package:stackwallet/wallets/wallet/wallet.dart';

import '../support/grin_fakes.dart';

/// What the wallets service does with a Grin wallet at startup and when a
/// wallet is removed.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory dataRoot;
  late Directory isarRoot;
  late Isar isar;
  late GrinHarness h;
  late Wallets service;

  setUpAll(() async => dataRoot = await setUpGrinTests());
  tearDownAll(() => dataRoot.delete(recursive: true));
  setUp(() async {
    isarRoot = await Directory.systemTemp.createTemp('stack_grin_isar_');
    isar = await openTestIsar(isarRoot);
    h = await GrinHarness.create();
    service = Wallets.sharedInstance
      ..mainDB = MainDB.instance
      ..nodeService = NodeService(secureStorageInterface: h.secrets);
    final hive = DB.instance.hive;
    hive.init(isarRoot.path);
    await hive.openBox<String>(DB.boxNameWalletsToDeleteOnStart);
    await hive.openBox<TradeWalletLookup>(DB.boxNameTradeLookup);
    await hive.openBox<NotificationModel>(DB.boxNameNotifications);
  });
  tearDown(() async {
    await h.dispose();
    await DB.instance.hive.close();
    await isar.close();
    await isarRoot.delete(recursive: true);
  });

  String passwordKey() => GrinWallet.passwordKey(h.walletId);
  List<String> toDeleteOnStart() =>
      DB.instance.values<String>(boxName: DB.boxNameWalletsToDeleteOnStart);
  Future<WalletInfo?> storedInfo() => isar.walletInfo.getByWalletId(h.walletId);

  test('a wallet that cannot be opened at startup is reported, not '
      'thrown', () async {
    h.backend.createError = grinError(15);
    expect(await Wallets.initAtStartup(h.wallet), isFalse);
    expect(h.wallet.isOpen, isFalse);

    expect(await Wallets.initAtStartup(h.wallet), isTrue);
    expect(h.wallet.isOpen, isTrue);
  });

  test('removing an unfinished wallet removes its files and '
      'password', () async {
    await h.wallet.init();
    expect(h.backend.wallets, isNotEmpty);
    expect(h.secrets.values.containsKey(passwordKey()), isTrue);

    await service.deleteUnfinishedWallet(h.walletId);

    expect(h.backend.wallets, isEmpty);
    expect(h.secrets.values.containsKey(passwordKey()), isFalse);
    expect(h.wallet.isOpen, isFalse);
    expect(await storedInfo(), isNull);
    expect(toDeleteOnStart(), isEmpty);
  });

  for (final code in [18, 15]) {
    final what = code == 18 ? 'is busy' : 'fails';
    test('an unfinished wallet whose delete $what is deleted at the next '
        'start', () async {
      await h.wallet.init();
      h.backend.deleteError = grinError(code);

      await service.deleteUnfinishedWallet(h.walletId);

      expect(await storedInfo(), isNull);
      expect(toDeleteOnStart(), [h.walletId]);
      expect(h.secrets.values.containsKey(passwordKey()), isTrue);

      h.backend.deleteError = null;
      final remaining = await GrinWallet.retryDeferredDeletes(
        walletIds: toDeleteOnStart(),
        secureStore: h.secrets,
        backend: h.backend,
      );
      expect(remaining, isEmpty);
      expect(h.backend.wallets, isEmpty);
      expect(h.secrets.values.containsKey(passwordKey()), isFalse);
    });
  }

  test('a wallet is removed although its files could not be '
      'deleted', () async {
    await h.wallet.init();
    final info = h.wallet.info;
    h.backend.deleteError = grinError(15);

    await service.deleteWallet(info, h.secrets);

    expect(await storedInfo(), isNull);
    expect(
      h.secrets.values.containsKey(Wallet.mnemonicKey(walletId: h.walletId)),
      isFalse,
    );
    expect(toDeleteOnStart(), [h.walletId]);
    // The password stays until the files are gone, so the retry at the
    // next start still has a wallet it can recognise.
    expect(h.secrets.values.containsKey(passwordKey()), isTrue);

    h.backend.deleteError = null;
    final remaining = await GrinWallet.retryDeferredDeletes(
      walletIds: toDeleteOnStart(),
      secureStore: h.secrets,
      backend: h.backend,
    );
    expect(remaining, isEmpty);
    expect(h.backend.wallets, isEmpty);
    expect(h.secrets.values.containsKey(passwordKey()), isFalse);
  });
}

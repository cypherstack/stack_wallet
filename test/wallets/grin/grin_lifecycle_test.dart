import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:grin_native/grin_native.dart';
import 'package:isar_community/isar.dart';
import 'package:path/path.dart' as p;
import 'package:stackwallet/models/isar/models/blockchain_data/address.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/v2/transaction_v2.dart';
import 'package:stackwallet/wallets/wallet/impl/grin_wallet.dart';
import 'package:stackwallet/wallets/wallet/supporting/grin/grin_errors.dart';
import 'package:stackwallet/wallets/wallet/supporting/grin_wallet_info_extension.dart';

import '../support/grin_fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory dataRoot;
  late Directory isarRoot;
  late Isar isar;
  late GrinHarness h;

  setUpAll(() async => dataRoot = await setUpGrinTests());
  tearDownAll(() => dataRoot.delete(recursive: true));
  setUp(() async {
    isarRoot = await Directory.systemTemp.createTemp('stack_grin_isar_');
    isar = await openTestIsar(isarRoot);
    h = await GrinHarness.create();
  });
  tearDown(() async {
    await h.dispose();
    await isar.close();
    await isarRoot.delete(recursive: true);
  });

  String passwordKey() => GrinWallet.passwordKey(h.walletId);

  test('a new wallet writes its password before create and starts at the '
      'tip', () async {
    String? storedAtCreate;
    h.backend.onCreate = (_) =>
        storedAtCreate = h.secrets.values[passwordKey()];

    await h.wallet.init();

    final create = h.backend.creates.single;
    expect(storedAtCreate, isNotNull);
    expect(create.password, storedAtCreate);
    expect(create.isNewWallet, isTrue);
    expect(create.mnemonic, testMnemonic);
    expect(h.backend.calls, ['create']);
    expect(h.backend.api.calls, isNot(contains(startsWith('scan'))));

    final data = h.wallet.info.grinData!;
    expect(data.pendingScanFrom, isNull);
    expect(h.wallet.info.restoreHeight, data.creationHeight);
    expect(data.creationHeight, greaterThan(3900000));

    final address = await h.wallet.getCurrentReceivingAddress();
    expect(address!.value, 'grin1ownaddress');
    expect(address.type, AddressType.mimbleWimble);
    expect(address.derivationIndex, 0);
  });

  test('the wallet directory is absolute although the data root is '
      'relative', () async {
    await h.wallet.init();
    final dir = h.backend.creates.single.config.walletDir;
    expect(p.isAbsolute(dir), isTrue);
    expect(p.basename(dir), h.walletId);
    expect(p.basename(p.dirname(dir)), 'grin');
    expect(p.equals(p.dirname(p.dirname(dir)), dataRoot.path), isTrue);
    if (Platform.isLinux || Platform.isMacOS) {
      final mode = (await Directory(dir).stat()).mode & 0x1ff;
      expect(mode, 0x1c0, reason: 'owner only');
      final parent = (await Directory(p.dirname(dir)).stat()).mode & 0x1ff;
      expect(parent, 0x1c0);
    }
  });

  test('an existing wallet is opened, not created', () async {
    await h.wallet.init();
    await h.wallet.exit();
    final reopened = h.newWallet();
    await reopened.init();
    expect(h.backend.calls, ['create', 'open']);
    expect(
      h.backend.opens.single.walletDir,
      h.backend.creates.single.config.walletDir,
    );
    await reopened.exit();
  });

  test('init is idempotent and coalesces', () async {
    await Future.wait([h.wallet.init(), h.wallet.init()]);
    await h.wallet.init();
    expect(h.backend.calls, ['create']);
  });

  test(
    'missing files of an existing wallet are not silently replaced',
    () async {
      await h.wallet.init();
      await h.wallet.exit();
      h.backend.wallets.clear();
      await expectLater(
        h.newWallet().init(),
        throwsA(isA<GrinWalletException>()),
      );
      expect(h.backend.calls, ['create', 'open']);
    },
  );

  test('a restore records the scan it owes before the wallet exists, and '
      'the next start finishes an interrupted one', () async {
    final r = await GrinHarness.create(restoreHeight: 1000);
    addTearDown(r.dispose);
    int? pendingAtCreate;
    r.backend.onCreate = (_) =>
        pendingAtCreate = r.wallet.info.grinData?.pendingScanFrom;
    r.backend.createError = grinError(15);

    await r.wallet.init(isRestore: true);
    await expectLater(r.wallet.recover(isRescan: false), throwsException);
    expect(pendingAtCreate, 1000);
    expect(r.wallet.info.grinData!.pendingScanFrom, 1000);
    expect(r.backend.wallets, isEmpty);
    expect(r.wallet.isOpen, isFalse);

    // The app starts again: the wallet is made from the phrase, not as a
    // new wallet, and its first refresh scans from the restore height.
    r.backend.scanBlocks = true;
    final next = r.newWallet();
    addTearDown(next.exit);
    await next.init();
    expect(r.backend.calls, ['create', 'open', 'create']);
    expect(r.backend.creates.last.isNewWallet, isFalse);
    expect(r.backend.creates.last.mnemonic, testMnemonic);
    expect(next.info.grinData!.pendingScanFrom, 1000);
    expect(r.backend.api.calls, isNot(contains(startsWith('scan'))));

    await next.refresh();
    await eventually(() => r.backend.api.calls.contains('scan:1000:false'));
    r.backend.api.finishScan();
    await eventually(() => next.info.grinData!.pendingScanFrom == null);
  });

  test('a rescan of a wallet whose files are gone rebuilds it, drops the '
      'stored history and scans from the restore height', () async {
    final r = await GrinHarness.create(restoreHeight: 1000);
    addTearDown(r.dispose);
    await r.wallet.init(isRestore: true);
    await r.wallet.recover(isRescan: false);
    await eventually(() => r.wallet.info.grinData!.pendingScanFrom == null);
    r.backend.api.transactions = GrinTxList(
      refreshedFromNode: true,
      transactions: [entryOf(id: 7, slateId: 'old-slate', debited: 5)],
    );
    await r.wallet.updateTransactions();
    expect(await isar.transactionV2s.count(), 1);
    await r.wallet.exit();
    r.backend.wallets.clear();

    r.backend.scanBlocks = true;
    final next = r.newWallet();
    addTearDown(next.exit);
    await next.recover(isRescan: true);
    expect(r.backend.calls, ['create', 'open', 'create']);
    expect(await isar.transactionV2s.count(), 0);
    expect(next.info.grinData!.pendingScanFrom, 1000);
    await eventually(() => r.backend.api.calls.contains('scan:1000:false'));
    r.backend.api.finishScan();
    await eventually(() => next.info.grinData!.pendingScanFrom == null);
  });

  test('a rescan that cannot open the wallet is still owed', () async {
    final r = await GrinHarness.create(restoreHeight: 1000);
    addTearDown(r.dispose);
    await r.wallet.init(isRestore: true);
    await r.wallet.recover(isRescan: false);
    await eventually(() => r.wallet.info.grinData!.pendingScanFrom == null);
    await r.wallet.exit();
    r.backend.wallets.clear();
    r.backend.createError = grinError(15);

    final next = r.newWallet();
    addTearDown(next.exit);
    await expectLater(next.recover(isRescan: true), throwsException);
    expect(next.info.grinData!.pendingScanFrom, 1000);
  });

  test('data left by an interrupted create is cleared once for a new '
      'wallet', () async {
    h.backend.createError = grinError(
      6,
      details: {'reason': 'leftover_wallet_data'},
    );
    await h.wallet.init();
    expect(h.backend.calls, ['create', 'delete', 'create']);
    expect(h.backend.creates.last.isNewWallet, isTrue);
    expect(h.wallet.isOpen, isTrue);
  });

  test('an existing wallet in the way of a new one is not deleted', () async {
    h.backend.createError = grinError(6);
    await expectLater(h.wallet.init(), throwsA(isA<GrinWalletException>()));
    expect(h.backend.calls, ['create']);
  });

  test('a close that fails is tried once more', () async {
    await h.wallet.init();
    final api = h.backend.api;
    api.closeError = grinError(15);
    await h.wallet.exit();
    expect(api.calls.where((c) => c == 'close'), hasLength(2));
    expect(api.calls.last, 'closed');
  });

  test('init with isRestore opens nothing', () async {
    await h.wallet.init(isRestore: true);
    expect(h.backend.calls, isEmpty);
    expect(h.wallet.isOpen, isFalse);
  });

  test('exit awaits close, and init after exit opens again', () async {
    await h.wallet.init();
    final api = h.backend.api;
    final gate = api.closeGate = Completer<void>();
    var exited = false;
    final exiting = h.wallet.exit().then((_) => exited = true);
    await pumpEventQueue();
    expect(api.calls, contains('close'));
    expect(exited, isFalse);
    gate.complete();
    await exiting;
    expect(api.calls.last, 'closed');
    expect(h.wallet.isOpen, isFalse);

    await h.wallet.refresh();
    expect(h.backend.calls, ['create'], reason: 'refresh never reopens');

    await h.wallet.init();
    expect(h.backend.calls, ['create', 'open']);
  });

  test('a second live instance is refused', () async {
    await h.wallet.init();
    await expectLater(
      h.newWallet().init(),
      throwsA(isA<GrinWalletException>()),
    );
  });

  test('delete closes the owner, removes the files, the empty directory and '
      'then the password', () async {
    await h.wallet.init();
    final api = h.backend.api;
    final dir = h.backend.creates.single.config.walletDir;
    final order = <String>[];
    h.secrets.beforeDelete = (key) async {
      order.add('secret:$key');
      expect(await Directory(dir).exists(), isFalse);
    };

    final deleted = await GrinWallet.deleteWalletFiles(
      walletId: h.walletId,
      secureStore: h.secrets,
    );

    expect(deleted, isTrue);
    expect(api.calls, containsAllInOrder(['cancelScan', 'close', 'closed']));
    expect(h.backend.deletes, [dir]);
    expect(order, ['secret:${passwordKey()}']);
    expect(h.secrets.values.containsKey(passwordKey()), isFalse);
  });

  test('a busy delete is reported, keeps the password and retries', () async {
    await h.wallet.init();
    h.backend.deleteError = grinError(18);
    final deleted = await GrinWallet.deleteWalletFiles(
      walletId: h.walletId,
      secureStore: h.secrets,
    );
    expect(deleted, isFalse);
    expect(h.secrets.values.containsKey(passwordKey()), isTrue);

    h.backend.deleteError = null;
    final remaining = await GrinWallet.retryDeferredDeletes(
      walletIds: [h.walletId, 'never-a-grin-wallet'],
      secureStore: h.secrets,
      backend: h.backend,
    );
    expect(remaining, isEmpty);
    expect(h.secrets.values.containsKey(passwordKey()), isFalse);
  });

  test('a restore being cancelled deletes the unregistered instance', () async {
    final restore = h.wallet;
    h.backend.scanBlocks = true;
    await restore.init(isRestore: true);
    await restore.recover(isRescan: false);
    await pumpEventQueue();
    final api = h.backend.api;
    api.cancelScannedHeight = 1500;
    expect(api.scanRunning, isTrue);

    final deleted = await GrinWallet.deleteWalletFiles(
      walletId: h.walletId,
      secureStore: h.secrets,
    );
    expect(deleted, isTrue);
    expect(api.calls, containsAllInOrder(['cancelScan', 'close']));
    expect(restore.info.grinData!.pendingScanFrom, 1501);
    expect(h.backend.wallets, isEmpty);
    expect(restore.isOpen, isFalse);
  });
}

import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:path/path.dart' as p;
import 'package:stackwallet/models/isar/models/blockchain_data/address.dart';
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
    expect(api.scanRunning, isTrue);

    final deleted = await GrinWallet.deleteWalletFiles(
      walletId: h.walletId,
      secureStore: h.secrets,
    );
    expect(deleted, isTrue);
    expect(api.calls, containsAllInOrder(['cancelScan', 'close']));
    expect(h.backend.wallets, isEmpty);
    expect(restore.isOpen, isFalse);
  });
}

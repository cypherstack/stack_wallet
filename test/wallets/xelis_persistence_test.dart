import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';

import 'package:stackwallet/db/isar/main_db.dart';
import 'package:stackwallet/db/hive/db.dart';
import 'package:stackwallet/models/notification_model.dart';
import 'package:stackwallet/models/trade_wallet_lookup.dart';
import 'package:stackwallet/services/wallets.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/address.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/transaction.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/v2/transaction_v2.dart';
import 'package:stackwallet/models/isar/models/address_label.dart';
import 'package:stackwallet/models/isar/models/transaction_note.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/utxo.dart';
import 'package:stackwallet/wallets/isar/models/spark_coin.dart';
import 'package:stackwallet/utilities/stack_file_system.dart';
import 'package:stackwallet/wallets/crypto_currency/crypto_currency.dart';
import 'package:stackwallet/wallets/isar/models/wallet_info.dart';
import 'package:stackwallet/wallets/wallet/impl/xelis_wallet.dart';
import 'package:stackwallet/wallets/wallet/wallet.dart';
import 'package:stackwallet/wl_gen/interfaces/lib_xelis_interface.dart';

import 'support/xelis_test_fakes.dart';
import '../support/isar_test_utils.dart';

class PersistenceNative extends Fake implements LibXelisInterface {
  BigInt balance = BigInt.zero;
  BigInt daemonTopoheight = BigInt.from(100);
  Object? balanceFailure;
  Object? historyFailure;
  int balanceReads = 0;
  Future<void> Function()? afterHistoryRead;
  List<TransactionEntryWrapper> history = [];
  int historyReads = 0;
  Completer<void>? historyStarted;
  Completer<void>? historyRelease;
  int creates = 0;
  int opens = 0;
  int closes = 0;
  Future<void> Function()? beforeClose;
  int rescans = 0;
  Completer<void>? rescanStarted;
  Completer<void>? rescanRelease;
  String address = 'own';
  String? createdPassword;
  String? restoredSeed;
  final fixtureSeed = List.filled(25, 'fixture-word').join(' ');
  @override
  dynamic noSuchMethod(Invocation invocation) {
    switch (invocation.memberName) {
      case #isOnline:
        return Future<bool>.value(false);
      case #hasTables:
        return Future<bool>.value(false);
      case #getDaemonInfo:
        return Future.value(
          XelisDaemonSnapshot(
            topoheight: daemonTopoheight,
            stableTopoheight: BigInt.from(76),
            prunedTopoheight: BigInt.from(12),
          ),
        );
      case #rescan:
        rescans++;
        rescanStarted?.complete();
        return rescanRelease?.future ?? Future<void>.value();
      case #getSeed:
        return Future<String>.value(fixtureSeed);
      case #closeWallet:
        closes++;
        return beforeClose?.call() ?? Future<void>.value();
      case #openXelisWallet:
        opens++;
        return Future<OpaqueXelisWallet>.value(
          const OpaqueXelisWallet(Object()),
        );
      case #createXelisWallet:
        creates++;
        createdPassword = invocation.namedArguments[#password] as String;
        restoredSeed = invocation.namedArguments[#seed] as String?;
        final directory = invocation.namedArguments[#directory] as String;
        final name = invocation.namedArguments[#name] as String;
        return Directory('$directory${Platform.pathSeparator}$name')
            .create(recursive: true)
            .then((_) => const OpaqueXelisWallet(Object()));
      default:
        return super.noSuchMethod(invocation);
    }
  }

  @override
  String get xelisAsset => 'xel';
  @override
  String getAddress(OpaqueXelisWallet wallet) => address;
  @override
  Future<BigInt> getXelisBalanceRaw(OpaqueXelisWallet wallet) async {
    balanceReads++;
    if (balanceFailure != null) throw balanceFailure!;
    return balance;
  }

  @override
  Future<List<TransactionEntryWrapper>> allHistory(
    OpaqueXelisWallet wallet, {
    BigInt? minTopoheight,
  }) async {
    historyReads++;
    if (!(historyStarted?.isCompleted ?? true)) historyStarted!.complete();
    await historyRelease?.future;
    if (historyFailure != null) throw historyFailure!;
    final snapshot = List<TransactionEntryWrapper>.of(history);
    await afterHistoryRead?.call();
    return snapshot;
  }
}

class PersistenceWallet extends XelisWallet {
  PersistenceWallet(PersistenceNative native, this.testWalletId)
    : super(CryptoCurrencyNetwork.test, native: native) {
    wallet = const OpaqueXelisWallet(Object());
    mainDB = MainDB.instance;
  }
  final String testWalletId;
  @override
  String get walletId => testWalletId;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory root;
  late Isar isar;
  late PersistenceNative native;
  late PersistenceWallet wallet;
  late Directory nativeRoot;
  var walletSequence = 0;
  setUpAll(() async {
    nativeRoot = await Directory.systemTemp.createTemp('stack_xelis_init_');
    StackFileSystem.setDesktopOverrideDir(nativeRoot.path);
    await initializeTestIsar();
  });
  tearDownAll(() => nativeRoot.delete(recursive: true));
  setUp(() async {
    root = await Directory.systemTemp.createTemp('stack_xelis_isar_');
    final testRoot = root;
    addTearDown(() => testRoot.delete(recursive: true));
    isar = await Isar.open(
      [
        WalletInfoSchema,
        TransactionV2Schema,
        AddressSchema,
        TransactionSchema,
        UTXOSchema,
        SparkCoinSchema,
        AddressLabelSchema,
        TransactionNoteSchema,
      ],
      directory: root.path,
      name: 'xelis-test',
      inspector: false,
    );
    final testIsar = isar;
    addTearDown(() => testIsar.close());
    await MainDB.instance.initMainDB(mock: isar);
    native = PersistenceNative();
    wallet = PersistenceWallet(native, 'persistence-test-${walletSequence++}');
    await MainDB.instance.putWalletInfo(
      WalletInfo(
        walletId: wallet.walletId,
        name: 'fixture',
        mainAddressType: AddressType.xelis,
        coinName: 'xelisTestNet',
      ),
    );
    await MainDB.instance.updateOrPutAddresses([
      Address(
        walletId: wallet.walletId,
        derivationIndex: 0,
        derivationPath: null,
        value: 'own',
        publicKey: [],
        type: AddressType.xelis,
        subType: AddressSubType.receiving,
      ),
    ]);
  });
  TransactionEntryWrapper entry(
    String hash, {
    int? height,
    String destination = 'other',
  }) => TransactionEntryWrapper(
    hash: hash,
    timestamp: DateTime.fromMillisecondsSinceEpoch(1000),
    topoheight: height == null ? null : BigInt.from(height),
    entryType: OutgoingEntryWrapper(
      nonce: BigInt.one,
      fee: BigInt.from(7),
      transfers: [
        (
          destination: destination,
          amount: BigInt.from(200),
          asset: 'xel',
          extraData: null,
        ),
      ],
    ),
  );

  test('concurrent refreshes share one history and balance update', () async {
    native.historyStarted = Completer<void>();
    native.historyRelease = Completer<void>();
    final first = wallet.refresh();
    await native.historyStarted!.future;
    final second = wallet.refresh();
    expect(native.historyReads, 1);
    native.historyRelease!.complete();
    await Future.wait([first, second]);
    expect(native.historyReads, 1);
  });

  test('ordinary blocks advance confirmations without HistorySynced', () async {
    await wallet.info.updateCachedChainHeight(newHeight: 99, isar: isar);
    native.balance = BigInt.from(1000);
    native.history = [entry('confirmed', height: 100)];
    await wallet.handleEvent(
      NewTransaction(native.history.single),
      isCurrent: () => true,
    );
    final tx = await isar.transactionV2s
        .where()
        .walletIdEqualTo(wallet.walletId)
        .findFirst();
    expect(tx!.getConfirmations(wallet.info.cachedChainHeight), 0);

    await wallet.handleEvent(
      NewTopoheight(BigInt.from(100)),
      isCurrent: () => true,
    );
    expect(tx.getConfirmations(wallet.info.cachedChainHeight), 1);

    native.daemonTopoheight = BigInt.from(101);
    await wallet.handleEvent(
      NewTopoheight(BigInt.from(101)),
      isCurrent: () => true,
    );
    expect(tx.getConfirmations(wallet.info.cachedChainHeight), 2);

    native.daemonTopoheight = BigInt.from(102);
    await wallet.handleEvent(
      NewTopoheight(BigInt.from(102)),
      isCurrent: () => false,
    );
    expect(tx.getConfirmations(wallet.info.cachedChainHeight), 2);
  });

  for (final destination in ['other', 'own']) {
    test(
      'full refresh reserves pending debit and fee to $destination',
      () async {
        native.balance = BigInt.from(1000);
        native.history = [entry('pending', destination: destination)];
        await wallet.refresh();
        expect(native.historyReads, 1);
        expect(native.balanceReads, 1);
        expect(wallet.info.cachedBalance.blockedTotal.raw, BigInt.from(207));
        expect(wallet.info.cachedBalance.spendable.raw, BigInt.from(793));
        native.history = [
          entry('pending', height: 10, destination: destination),
        ];
        native.balance = BigInt.from(destination == 'own' ? 993 : 793);
        await wallet.updateBalance();
        expect(native.historyReads, 2);
        expect(wallet.info.cachedBalance.blockedTotal.raw, BigInt.zero);
        expect(wallet.info.cachedBalance.spendable.raw, native.balance);
      },
    );
  }

  test(
    'confirmation during refresh is reconciled by the queued balance read',
    () async {
      native.balance = BigInt.from(1000);
      native.history = [entry('pending')];
      Future<void>? independentUpdate;
      native.afterHistoryRead = () async {
        native.afterHistoryRead = null;
        native.balance = BigInt.from(793);
        native.history = [entry('pending', height: 10)];
        // This update must wait for the snapshot write, then read fresh state.
        independentUpdate = wallet.updateBalance();
      };
      await wallet.refresh();
      await independentUpdate;
      expect(native.historyReads, 2);
      expect(wallet.info.cachedBalance.total.raw, BigInt.from(793));
      expect(wallet.info.cachedBalance.blockedTotal.raw, BigInt.zero);
      await wallet.refresh();
      expect((await isar.transactionV2s.where().findFirst())!.height, 10);
    },
  );

  test('full refresh reconciles disappeared transactions', () async {
    native.history = [entry('disappeared')];
    await wallet.refresh();
    expect(await isar.transactionV2s.count(), 1);
    native.history = [];
    await wallet.refresh();
    expect(await isar.transactionV2s.count(), 0);
    expect(wallet.info.cachedBalance.blockedTotal.raw, BigInt.zero);
  });

  for (final invalidateSession in [true, false]) {
    test('refresh drops snapshot after '
        '${invalidateSession ? 'session invalidation' : 'shutdown'}', () async {
      native.balance = BigInt.from(1000);
      native.history = [entry('stale')];
      native.historyStarted = Completer<void>();
      native.historyRelease = Completer<void>();
      final refreshing = wallet.refresh();
      await native.historyStarted!.future;
      Future<void>? closing;
      if (invalidateSession) {
        wallet.sessionGeneration++;
      } else {
        wallet.prefs = SessionPrefs();
        closing = wallet.exit();
      }
      native.historyRelease!.complete();
      await refreshing;
      await closing;
      expect(await isar.transactionV2s.count(), 0);
      expect(wallet.info.cachedBalance.total.raw, BigInt.zero);
    });
  }

  test(
    'history read failure preserves the previously stored balance',
    () async {
      native.balance = BigInt.from(1000);
      await wallet.updateBalance();
      native.balance = BigInt.zero;
      native.historyFailure = StateError('fixture history failure');
      await expectLater(wallet.updateBalance(), throwsStateError);
      expect(wallet.info.cachedBalance.total.raw, BigInt.from(1000));
    },
  );

  for (final failHistory in [false, true]) {
    test('failed full refresh preserves both persisted projections '
        '(history failure: $failHistory)', () async {
      native.balance = BigInt.from(1000);
      native.history = [entry('existing', height: 10)];
      await wallet.refresh();
      native.balance = BigInt.zero;
      native.history = [];
      final failure = StateError('fixture read failure');
      if (failHistory) {
        native.historyFailure = failure;
      } else {
        native.balanceFailure = failure;
      }
      await wallet.refresh();
      expect(wallet.info.cachedBalance.total.raw, BigInt.from(1000));
      expect((await isar.transactionV2s.where().findFirst())!.txid, 'existing');
    });
  }

  test('shutdown waits for an in-flight native rescan', () async {
    wallet.prefs = SessionPrefs();
    native.rescanStarted = Completer<void>();
    native.rescanRelease = Completer<void>();
    final rescanning = wallet.recover(isRescan: true);
    await native.rescanStarted!.future;
    final queuedRescan = wallet.recover(isRescan: true);
    final closing = wallet.exit();
    await Future<void>.delayed(Duration.zero);
    try {
      expect(native.closes, 0);
    } finally {
      native.rescanRelease!.complete();
      await Future.wait([rescanning, queuedRescan, closing]);
    }
    expect(native.closes, 1);
    expect(native.rescans, 1);
    expect(wallet.wallet, isNull);
  });

  for (final failSecrets in [false, true]) {
    final deletionAction = failSecrets
        ? 'propagates a secret failure after removing the wallet'
        : 'cleans the complete record';
    test('wallet service deletion $deletionAction', () async {
      final service = Wallets.sharedInstance..mainDB = MainDB.instance;
      final info = wallet.info;
      wallet.prefs = SessionPrefs();
      service.addWallet(wallet);
      final secrets = MemorySecrets();
      final passwordKey = Wallet.mnemonicPassphraseKey(
        walletId: wallet.walletId,
      );
      final seedKey = Wallet.mnemonicKey(walletId: wallet.walletId);
      secrets.values[seedKey] = 'fixture-seed';
      secrets.values[passwordKey] = 'fixture-password';
      wallet.secureStorageInterface = secrets;
      final xelisRoot = await StackFileSystem.applicationXelisDirectory();
      final nativeDirectory = await Directory(
        '${xelisRoot.path}/${wallet.walletId}',
      ).create();
      await File('${nativeDirectory.path}/storage-marker')
          .writeAsString('fixture');
      final tableDirectory = await Directory('${xelisRoot.path}/table')
          .create();
      final tableMarker = await File('${tableDirectory.path}/shared-table')
          .writeAsString('table');
      final otherDirectory = await Directory(
        '${xelisRoot.path}/other-${wallet.walletId}',
      ).create();
      final otherMarker = await File('${otherDirectory.path}/storage-marker')
          .writeAsString('other');
      native.beforeClose = () async {
        expect(() => service.getWallet(info.walletId), throwsException);
        expect(await nativeDirectory.exists(), isTrue);
      };
      secrets.beforeDelete = (_) async {
        expect(native.closes, 1);
        expect(await nativeDirectory.exists(), isFalse);
      };
      final hive = DB.instance.hive;
      hive.init(root.path);
      await hive.openBox<String>(DB.boxNameWalletsToDeleteOnStart);
      await hive.openBox<TradeWalletLookup>(DB.boxNameTradeLookup);
      await hive.openBox<NotificationModel>(DB.boxNameNotifications);
      addTearDown(hive.close);
      addTearDown(() async {
        secrets.failingDeleteKey = null;
        if (await isar.walletInfo.getByWalletId(info.walletId) != null) {
          await service.deleteWallet(info, secrets);
        }
      });
      if (failSecrets) {
        secrets.failingDeleteKey = passwordKey;
        await expectLater(
          service.deleteWallet(info, secrets),
          throwsStateError,
        );
        expect(() => service.getWallet(info.walletId), throwsException);
        expect(await isar.walletInfo.getByWalletId(info.walletId), isNotNull);
        expect(secrets.values[passwordKey], 'fixture-password');
        expect(await nativeDirectory.exists(), isFalse);
        expect(await tableMarker.readAsString(), 'table');
        expect(await otherMarker.readAsString(), 'other');
        return;
      }
      await service.deleteWallet(info, secrets);
      expect(() => service.getWallet(info.walletId), throwsException);
      expect(await isar.walletInfo.getByWalletId(info.walletId), isNull);
      expect(await isar.addresses.count(), 0);
      expect(secrets.values.containsKey(seedKey), isFalse);
      expect(secrets.values.containsKey(passwordKey), isFalse);
      expect(await tableMarker.readAsString(), 'table');
      expect(await otherMarker.readAsString(), 'other');
      expect(
        DB.instance.values<String>(boxName: DB.boxNameWalletsToDeleteOnStart),
        [info.walletId],
      );
    });
  }

  test('confirmed/pending/reorganized snapshots replace history '
      'but preserve addresses', () async {
    native.history = [entry('one')];
    await wallet.updateTransactions();
    final first = await isar.transactionV2s.where().findFirst();
    expect(first!.height, isNull);
    native.history = [entry('one', height: 10), entry('two', height: 10)];
    await wallet.updateTransactions();
    expect(await isar.transactionV2s.count(), 2);
    expect((await isar.transactionV2s.get(first.id))!.height, 10);
    native.history = [entry('one', height: 9)];
    await wallet.updateTransactions(isRescan: true);
    expect(await isar.transactionV2s.count(), 1);
    expect((await isar.transactionV2s.get(first.id))!.height, 9);
    expect(await isar.addresses.count(), 1);
  });

  test('pending debit is reserved '
      'and a later genuine zero replaces cached balance', () async {
    native.balance = BigInt.from(1000);
    native.history = [entry('pending')];
    await wallet.updateBalance();
    expect(wallet.info.cachedBalance.spendable.raw, BigInt.from(793));
    expect(wallet.info.cachedBalance.blockedTotal.raw, BigInt.from(207));
    native.history = [];
    native.balance = BigInt.zero;
    await wallet.updateBalance();
    expect(wallet.info.cachedBalance.total.raw, BigInt.zero);
    expect(wallet.info.cachedBalance.spendable.raw, BigInt.zero);
  });

  test(
    'storage read failure stays an error and never persists a fabricated zero',
    () async {
      native.balance = BigInt.from(1000);
      await wallet.updateBalance();
      final failure = StateError('fixture storage error');
      native.balanceFailure = failure;
      await expectLater(wallet.updateBalance(), throwsA(same(failure)));
      expect(wallet.info.cachedBalance.total.raw, BigInt.from(1000));
    },
  );

  test('a loaded record without native storage or seed '
      'never creates another identity', () async {
    wallet.wallet = null;
    wallet.secureStorageInterface = MemorySecrets();
    await expectLater(wallet.init(), throwsStateError);
    expect(native.creates, 0);
    expect(wallet.wallet, isNull);
  });

  test('interrupted seed persistence is repaired '
      'by reopening the created database', () async {
    wallet.wallet = null;
    final secrets = MemorySecrets();
    wallet.secureStorageInterface = secrets;
    wallet.allowNewWallet = true;
    final seedKey = Wallet.mnemonicKey(walletId: wallet.walletId);
    secrets.failingKey = seedKey;
    await expectLater(wallet.init(), throwsStateError);
    expect(wallet.wallet, isNull);
    expect(native.closes, 1);
    secrets.failingKey = null;
    await wallet.init();
    expect(native.creates, 1);
    expect(native.opens, 1);
    expect(secrets.values[seedKey], native.fixtureSeed);
    expect(wallet.info.cachedReceivingAddress, 'own');
  });

  test(
    'existing native storage without its password fails before opening',
    () async {
      wallet.wallet = null;
      final secrets = MemorySecrets();
      wallet.secureStorageInterface = secrets;
      final directory = await StackFileSystem.applicationXelisDirectory();
      await Directory('${directory.path}/${wallet.walletId}').create();
      await expectLater(wallet.init(), throwsStateError);
      expect(native.opens, 0);
      expect(native.creates, 0);
      expect(wallet.wallet, isNull);
      expect(
        secrets.values.containsKey(
          Wallet.mnemonicKey(walletId: wallet.walletId),
        ),
        isFalse,
      );
    },
  );

  test(
    'mismatched native identity closes without saving its recovery seed',
    () async {
      wallet.wallet = null;
      native.address = 'another-wallet';
      final secrets = MemorySecrets();
      wallet.secureStorageInterface = secrets;
      final passwordKey = Wallet.mnemonicPassphraseKey(
        walletId: wallet.walletId,
      );
      secrets.values[passwordKey] = 'fixture-password';
      final directory = await StackFileSystem.applicationXelisDirectory();
      await Directory('${directory.path}/${wallet.walletId}').create();
      await expectLater(wallet.init(), throwsStateError);
      expect(native.opens, 1);
      expect(native.closes, 1);
      expect(wallet.wallet, isNull);
      expect(secrets.values[passwordKey], 'fixture-password');
      expect(
        secrets.values.containsKey(
          Wallet.mnemonicKey(walletId: wallet.walletId),
        ),
        isFalse,
      );
      expect((await wallet.getCurrentReceivingAddress())!.value, 'own');
    },
  );

  for (final hasPassword in [false, true]) {
    test('seed restoration ${hasPassword ? 'preserves' : 'creates'} '
        'the native password', () async {
      wallet.wallet = null;
      final secrets = MemorySecrets();
      wallet.secureStorageInterface = secrets;
      final passwordKey = Wallet.mnemonicPassphraseKey(
        walletId: wallet.walletId,
      );
      secrets.values[Wallet.mnemonicKey(walletId: wallet.walletId)] =
          '  ${native.fixtureSeed.replaceAll(' ', '\n ')}  ';
      if (hasPassword) secrets.values[passwordKey] = 'fixture-password';
      await wallet.init(isRestore: true);
      expect(native.creates, 1);
      expect(native.opens, 0);
      expect(native.restoredSeed, native.fixtureSeed);
      expect(native.createdPassword, isNotEmpty);
      expect(native.createdPassword, secrets.values[passwordKey]);
      if (hasPassword) expect(native.createdPassword, 'fixture-password');
      expect(wallet.info.cachedReceivingAddress, 'own');
    });
  }

  test(
    'password persistence failure prevents native creation and permits retry',
    () async {
      wallet.wallet = null;
      wallet.allowNewWallet = true;
      final passwordKey = Wallet.mnemonicPassphraseKey(
        walletId: wallet.walletId,
      );
      final secrets = MemorySecrets()..failingKey = passwordKey;
      wallet.secureStorageInterface = secrets;
      await expectLater(wallet.init(), throwsStateError);
      expect(native.creates, 0);
      expect(wallet.wallet, isNull);
      secrets.failingKey = null;
      await wallet.init();
      expect(native.creates, 1);
      expect(native.createdPassword, secrets.values[passwordKey]);
    },
  );
}

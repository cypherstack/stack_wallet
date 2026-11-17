// Drives GrinWallet against the real grin-ffi library on its in-process test
// chain. Needs the library built with the test_utils user-define; run it
// with scripts/grin_e2e_test.sh (see docs/building.md, Grin).

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:event_bus/event_bus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grin_native/grin_native.dart';
import 'package:integration_test/integration_test.dart';
import 'package:isar_community/isar.dart';
import 'package:logger/logger.dart';
import 'package:path/path.dart' as p;
import 'package:stackwallet/db/hive/db.dart';
import 'package:stackwallet/db/isar/main_db.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/address.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/transaction.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/v2/transaction_v2.dart';
import 'package:stackwallet/models/node_model.dart';
import 'package:stackwallet/models/slatepack_models.dart';
import 'package:stackwallet/services/event_bus/events/global/wallet_sync_status_changed_event.dart';
import 'package:stackwallet/services/node_service.dart';
import 'package:stackwallet/utilities/logger.dart';
import 'package:stackwallet/utilities/amount/amount.dart';
import 'package:stackwallet/utilities/prefs.dart';
import 'package:stackwallet/utilities/stack_file_system.dart';
import 'package:stackwallet/wallets/crypto_currency/crypto_currency.dart';
import 'package:stackwallet/wallets/isar/models/wallet_info.dart';
import 'package:stackwallet/wallets/models/tx_data.dart';
import 'package:stackwallet/wallets/wallet/impl/grin_wallet.dart';
import 'package:stackwallet/wallets/wallet/supporting/grin_wallet_info_extension.dart';
import 'package:stackwallet/wallets/wallet/wallet.dart';

import '../../test/support/memory_secrets.dart';
import 'test_chain_backend.dart';

/// Coinbase reward on the test chain.
const int reward = 60;
final BigInt _nano = BigInt.from(1000000000);

Amount grin(int whole) =>
    Amount(rawValue: BigInt.from(whole) * _nano, fractionDigits: 9);
Amount nano(BigInt raw) => Amount(rawValue: raw, fractionDigits: 9);

/// GrinWallet with the test backend and a fixed wallet id. Tor is compiled
/// out so the transport is direct.
class E2eGrinWallet extends GrinWallet {
  E2eGrinWallet(this._id, TestChainBackend backend, EventBus bus)
    : super(CryptoCurrencyNetwork.main, backend: backend, eventBus: bus);

  final String _id;

  @override
  String get walletId => _id;

  @override
  bool get torFeatureEnabled => false;
}

late MemorySecrets secrets;
late NodeService nodes;
late Directory root;

/// One test chain and the wallets on it.
class Chain {
  Chain._(this.dir) : backend = TestChainBackend(dir);

  static int _sequence = 0;

  static Future<Chain> start() async {
    final dir = Directory(p.join(root.path, 'chains', 'c${_sequence++}'));
    await dir.create(recursive: true);
    final chain = Chain._(dir.path);
    addTearDown(chain.dispose);
    return chain;
  }

  final String dir;
  final TestChainBackend backend;
  final bus = EventBus();
  final List<E2eGrinWallet> _wallets = [];

  /// Sync status events GrinWallet fired itself, by wallet id.
  final Map<String, List<WalletSyncStatus>> statuses = {};
  StreamSubscription<WalletSyncStatusChangedEvent>? _sub;

  /// A wallet with its WalletInfo and mnemonic stored. Opened unless
  /// [restore] is set, in which case the caller recovers it.
  Future<E2eGrinWallet> wallet(
    String name, {
    String? mnemonic,
    int restoreHeight = 0,
    bool restore = false,
  }) async {
    _sub ??= bus.on<WalletSyncStatusChangedEvent>().listen(
      (e) => statuses.putIfAbsent(e.walletId, () => []).add(e.newStatus),
    );
    final walletId = 'e2e-$name-${_sequence++}';
    await MainDB.instance.putWalletInfo(
      WalletInfo(
        walletId: walletId,
        name: name,
        mainAddressType: AddressType.mimbleWimble,
        coinName: 'grin',
        restoreHeight: restoreHeight,
      ),
    );
    secrets.values[Wallet.mnemonicKey(walletId: walletId)] =
        mnemonic ?? await backend.generateMnemonic();
    secrets.values[Wallet.mnemonicPassphraseKey(walletId: walletId)] = '';
    final wallet = open(walletId);
    if (!restore) await wallet.init();
    return wallet;
  }

  /// A new instance for an existing wallet id, as a later app start makes.
  E2eGrinWallet open(String walletId) {
    final wallet = E2eGrinWallet(walletId, backend, bus)
      ..mainDB = MainDB.instance
      ..secureStorageInterface = secrets
      ..prefs = Prefs.instance
      ..nodeService = nodes;
    _wallets.add(wallet);
    return wallet;
  }

  Future<String> dirOf(GrinWallet wallet) =>
      GrinWallet.walletDirPath(wallet.walletId);

  Future<TestChainApi> api(GrinWallet wallet) async =>
      backend.apiFor(await dirOf(wallet));

  Future<int> mine(GrinWallet wallet, int blocks) async =>
      backend.mine(await dirOf(wallet), blocks);

  Future<void> dispose() async {
    for (final wallet in _wallets.reversed) {
      try {
        await wallet.exit();
      } catch (_) {}
    }
    await _sub?.cancel();
  }
}

/// Waits for a refresh a call started, then updates height, history and
/// balance with errors surfaced. The base refresh only logs them.
Future<void> sync(GrinWallet wallet) async {
  await wallet.refresh();
  await wallet.refreshMutex.protect(() async {
    await wallet.updateChainHeight();
    await wallet.updateTransactions();
    await wallet.updateBalance();
  });
}

Future<List<TransactionV2>> rows(GrinWallet wallet) => MainDB
    .instance
    .isar
    .transactionV2s
    .where()
    .walletIdEqualTo(wallet.walletId)
    .findAll();

Future<TransactionV2> row(GrinWallet wallet, String txid) async {
  final tx = await MainDB.instance.isar.transactionV2s
      .where()
      .txidWalletIdEqualTo(txid, wallet.walletId)
      .findFirst();
  expect(tx, isNotNull, reason: 'no row $txid in ${wallet.walletId}');
  return tx!;
}

Map<String, dynamic> otherData(TransactionV2 tx) =>
    Map<String, dynamic>.from(jsonDecode(tx.otherData!) as Map);

String label(GrinWallet wallet, TransactionV2 tx) => tx.statusLabel(
  currentChainHeight: wallet.info.cachedChainHeight,
  minConfirms: wallet.cryptoCurrency.minConfirms,
  minCoinbaseConfirms: wallet.cryptoCurrency.minCoinbaseConfirms,
);

Amount received(TransactionV2 tx) =>
    tx.getAmountReceivedInThisWallet(fractionDigits: 9);

Amount sent(TransactionV2 tx) =>
    tx.getAmountSentFromThisWallet(fractionDigits: 9, subtractFee: true);

Amount fee(TransactionV2 tx) => tx.getFee(fractionDigits: 9);

TxData sendTo(String address, Amount amount) => TxData(
  recipients: [
    TxRecipient(
      address: address,
      amount: amount,
      isChange: false,
      addressType: AddressType.mimbleWimble,
    ),
  ],
);

/// Polls [check] in real time.
Future<void> eventually(
  FutureOr<bool> Function() check, {
  required String reason,
  Duration timeout = const Duration(seconds: 90),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (!await check()) {
    if (DateTime.now().isAfter(deadline)) fail('timed out: $reason');
    await Future<void>.delayed(const Duration(milliseconds: 200));
  }
}

/// A funded sender at height 15 and an empty receiver. With 10
/// confirmations required, the coinbase outputs of heights 1 to 6 are
/// spendable.
Future<({Chain chain, E2eGrinWallet alice, E2eGrinWallet bob})>
fundedPair() async {
  final chain = await Chain.start();
  final alice = await chain.wallet('alice');
  final bob = await chain.wallet('bob');
  expect(await chain.mine(alice, 15), 15);
  await sync(alice);
  await sync(bob);
  expect(alice.info.cachedBalance.spendable, grin(6 * reward));
  return (chain: chain, alice: alice, bob: bob);
}

const _timeout = Timeout(Duration(minutes: 10));

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    if (!(Platform.isLinux || Platform.isMacOS || Platform.isWindows)) {
      fail('Run the Grin test chain suite on a desktop host.');
    }
    root = await Directory.systemTemp.createTemp('stack_grin_e2e_');
    StackFileSystem.setDesktopOverrideDir(root.path);
    // A device run has no FLUTTER_TEST, so the logger needs its isolate.
    final logs = Directory(p.join(root.path, 'logs'))..createSync();
    await Logging.instance.initialize(logs.path, level: Level.warning);
    await MainDB.instance.initMainDB();
    final hive = DB.instance.hive..init(p.join(root.path, 'hive'));
    hive.registerAdapter(NodeModelAdapter());
    await hive.openBox<dynamic>(DB.boxNamePrefs);
    await hive.openBox<NodeModel>(DB.boxNameNodeModels);
    await Prefs.instance.init();
    secrets = MemorySecrets({});
    nodes = NodeService(secureStorageInterface: secrets);
  });

  tearDownAll(() async {
    try {
      await MainDB.instance.isar.close();
      await DB.instance.hive.close();
    } finally {
      await root.delete(recursive: true);
    }
  });

  testWidgets('a new wallet needs no scan and sees coinbase it mined', (
    tester,
  ) async {
    final chain = await Chain.start();
    final alice = await chain.wallet('alice');
    final dir = await chain.dirOf(alice);

    // Created as new, so no genesis scan is pending.
    expect(chain.backend.calls, ['create:${alice.walletId}:new=true']);
    expect(alice.info.grinData?.pendingScanFrom, isNull);
    expect(alice.info.grinData?.creationHeight, greaterThan(0));
    final address = (await alice.getCurrentReceivingAddress())!;
    expect(address.value, startsWith('tgrin1'));
    expect(address.type, AddressType.mimbleWimble);
    expect(address.derivationIndex, 0);
    expect(alice.info.cachedReceivingAddress, address.value);
    expect(Directory(p.join(dir, 'wallet_data')).existsSync(), isTrue);
    expect(secrets.values[GrinWallet.passwordKey(alice.walletId)], isNotEmpty);

    expect(await chain.mine(alice, 12), 12);
    await alice.refresh();
    await sync(alice);

    expect(chain.backend.calls.where((c) => c.startsWith('scan')), isEmpty);
    expect(alice.isScanPending, isFalse);
    expect(alice.info.cachedChainHeight, 12);
    final balance = alice.info.cachedBalance;
    expect(balance.total, grin(12 * reward));
    // Heights 1 to 3 have 10 confirmations at 12.
    expect(balance.spendable, grin(3 * reward));
    expect(balance.pendingSpendable, grin(9 * reward));

    final txs = await rows(alice);
    expect(txs, hasLength(12));
    final heights = <int>{};
    for (final tx in txs) {
      expect(tx.txid, startsWith('grin_cb_'));
      expect(tx.type, TransactionType.incoming);
      expect(tx.isCoinbase(), isTrue);
      expect(received(tx), grin(reward));
      expect(fee(tx), grin(0));
      heights.add(tx.height!);
      final data = otherData(tx);
      expect(data[TxV2OdKeys.isGrinTransaction], isTrue);
      expect(data[TxV2OdKeys.slateId], isNull);
      expect(data[TxV2OdKeys.isCancelled], isFalse);
      expect(data[TxV2OdKeys.grinLogIds], hasLength(1));
      // Coinbase needs Stack's 1440 confirmations.
      expect(label(alice, tx), startsWith('Receiving ('));
      expect(label(alice, tx), endsWith('/1440)'));
    }
    expect(heights, {for (var h = 1; h <= 12; h++) h});
    expect((await chain.api(alice)).networkUpdates, isEmpty);
  }, timeout: _timeout);

  testWidgets('Slatepack S1, S2, S3 between two GrinWallets', (tester) async {
    final (:chain, :alice, :bob) = await fundedPair();
    final bobAddress = await bob.slatepackAddress();
    final aliceAddress = await alice.slatepackAddress();
    final before = alice.info.cachedBalance.spendable;

    final prepared = await alice.prepareSend(
      txData: sendTo(bobAddress, grin(50)),
    );
    expect(prepared.fee!.raw, greaterThan(BigInt.zero));
    expect(prepared.recipients!.single.amount, grin(50));
    final confirmed = await alice.confirmSend(txData: prepared);
    final slateId = confirmed.txid!;
    final s1 = confirmed.slatepack!;
    expect(s1, startsWith('BEGINSLATEPACK.'));
    expect(confirmed.fee, prepared.fee);

    await sync(alice);
    var a = await row(alice, slateId);
    expect(a.type, TransactionType.outgoing);
    expect(a.height, isNull);
    expect(label(alice, a), 'Sending (waiting for response)');
    var data = otherData(a);
    expect(data[TxV2OdKeys.slateId], slateId);
    expect(data[TxV2OdKeys.grinSlateState], 'S1');
    expect(data[TxV2OdKeys.counterpartyAddress], bobAddress);
    expect(data[TxV2OdKeys.grinHasPaymentProof], isTrue);
    expect(data[TxV2OdKeys.grinHasStoredTx], isFalse);
    expect(data[TxV2OdKeys.grinTtlCutoff], isNotNull);
    expect(fee(a), confirmed.fee);
    // The inputs are locked, and libwallet leaves locked outputs out.
    expect(alice.info.cachedBalance.spendable < before, isTrue);
    expect(await alice.pendingSlatepackFor(slateId), s1);

    final inspected = await bob.inspectSlatepack(s1);
    expect(inspected.state, SlateState.s1);
    expect(inspected.amount, grin(50));
    expect(inspected.senderAddress, aliceAddress);
    final s2 = await bob.receiveSlatepack(s1);
    expect(s2.state, SlateState.s2);
    expect(s2.slateId, slateId);

    await sync(bob);
    var b = await row(bob, slateId);
    expect(b.type, TransactionType.incoming);
    expect(label(bob, b), 'Receiving (waiting for sender to finalize)');
    expect(otherData(b)[TxV2OdKeys.grinSlateState], 'S2');
    expect(otherData(b)[TxV2OdKeys.counterpartyAddress], aliceAddress);
    expect(received(b), grin(50));
    expect(bob.info.cachedBalance.pendingSpendable, grin(50));
    expect(bob.info.cachedBalance.spendable, grin(0));

    final s3 = await alice.finalizeSlatepack(s2.slatepack!);
    expect(s3.posted, isTrue);
    expect(s3.kernelExcess, hasLength(66));
    // Posting mined height 16; ten more give it 11 confirmations.
    expect(await chain.mine(alice, 10), 26);

    await sync(alice);
    await sync(bob);
    a = await row(alice, slateId);
    data = otherData(a);
    expect(a.height, 16);
    expect(label(alice, a), 'Sent');
    expect(data[TxV2OdKeys.grinSlateState], 'S3');
    expect(data[TxV2OdKeys.grinKernelExcess], s3.kernelExcess);
    expect(data[TxV2OdKeys.grinHasStoredTx], isTrue);
    expect(a.hash, s3.kernelExcess);
    expect(sent(a), grin(50));
    expect(fee(a), confirmed.fee);

    b = await row(bob, slateId);
    expect(b.height, 16);
    expect(label(bob, b), 'Received');
    expect(otherData(b)[TxV2OdKeys.grinKernelExcess], s3.kernelExcess);
    expect(bob.info.cachedBalance.spendable, grin(50));
    expect(bob.info.cachedBalance.total, grin(50));
    expect((await chain.api(alice)).networkUpdates, isEmpty);
    expect((await chain.api(bob)).networkUpdates, isEmpty);
  }, timeout: _timeout);

  testWidgets('invoice I1, I2, I3 with the amount guard', (tester) async {
    final (:chain, :alice, :bob) = await fundedPair();
    final aliceAddress = await alice.slatepackAddress();
    final before = alice.info.cachedBalance.spendable;

    final i1 = await bob.issueInvoice(
      amount: grin(30),
      payerAddress: aliceAddress,
    );
    expect(i1.state, SlateState.i1);
    await sync(bob);
    var b = await row(bob, i1.slateId!);
    expect(b.type, TransactionType.incoming);
    expect(label(bob, b), 'Invoice issued (waiting for payer)');
    expect(otherData(b)[TxV2OdKeys.grinSlateState], 'I1');

    // An amount other than the invoice's is refused before the library is
    // asked to pay, and nothing is recorded or locked.
    final refused = await alice.processInvoice(
      i1.slatepack!,
      confirmedAmount: nano(grin(30).raw - BigInt.one),
    );
    expect(refused.success, isFalse);
    expect(refused.error, contains('does not match'));
    expect(
      chain.backend.calls.where((c) => c.startsWith('processInvoice')),
      isEmpty,
    );
    await sync(alice);
    expect(
      await MainDB.instance.isar.transactionV2s
          .where()
          .txidWalletIdEqualTo(i1.slateId!, alice.walletId)
          .findFirst(),
      isNull,
    );
    expect(alice.info.cachedBalance.spendable, before);

    final i2 = await alice.processInvoice(
      i1.slatepack!,
      confirmedAmount: grin(30),
    );
    expect(i2.state, SlateState.i2);
    expect(
      chain.backend.calls.where((c) => c.startsWith('processInvoice')),
      hasLength(1),
    );
    await sync(alice);
    var a = await row(alice, i1.slateId!);
    expect(a.type, TransactionType.outgoing);
    expect(label(alice, a), 'Paying invoice (waiting for invoicer)');
    expect(otherData(a)[TxV2OdKeys.grinSlateState], 'I2');
    expect(alice.info.cachedBalance.spendable < before, isTrue);

    final i3 = await bob.finalizeInvoice(i2.slatepack!);
    expect(i3.posted, isTrue);
    // Posting mined height 16, to Bob.
    expect(await chain.mine(alice, 10), 26);
    await sync(alice);
    await sync(bob);

    b = await row(bob, i1.slateId!);
    expect(b.height, 16);
    expect(label(bob, b), 'Received');
    expect(received(b), grin(30));
    expect(otherData(b)[TxV2OdKeys.grinKernelExcess], i3.kernelExcess);
    a = await row(alice, i1.slateId!);
    expect(a.height, 16);
    expect(label(alice, a), 'Sent');
    expect(sent(a), grin(30));
    expect(fee(a), i2.fee!);
    // Bob also got the block 16 coinbase and the fee.
    expect(bob.info.cachedBalance.total, grin(30 + reward) + i2.fee!);
  }, timeout: _timeout);

  testWidgets('cancelling an unfinalized send unlocks its inputs', (
    tester,
  ) async {
    final (:chain, :alice, :bob) = await fundedPair();
    final before = alice.info.cachedBalance;

    final slate = await alice.createSlatepack(
      amount: grin(10),
      recipientAddress: await bob.slatepackAddress(),
    );
    await sync(alice);
    expect(alice.info.cachedBalance.spendable < before.spendable, isTrue);
    expect(
      label(alice, await row(alice, slate.slateId!)),
      'Sending (waiting for response)',
    );

    expect(await alice.cancelPendingTransactionAndPost(slate.slateId!), '');
    await sync(alice);
    final tx = await row(alice, slate.slateId!);
    expect(tx.isCancelled, isTrue);
    expect(label(alice, tx), 'Cancelled');
    expect(tx.height, isNull);
    expect(alice.info.cachedBalance.spendable, before.spendable);
    expect(alice.info.cachedBalance.total, before.total);

    // A second cancel is reported, not thrown.
    expect(
      await alice.cancelPendingTransactionAndPost(slate.slateId!),
      isNotEmpty,
    );
  }, timeout: _timeout);

  testWidgets('repost broadcasts a finalized send that was not posted', (
    tester,
  ) async {
    final (:chain, :alice, :bob) = await fundedPair();
    final slate = await alice.createSlatepack(
      amount: grin(20),
      recipientAddress: await bob.slatepackAddress(),
    );

    // Nothing is stored to post yet.
    await sync(alice);
    await expectLater(alice.repost(slate.slateId!), throwsA(anything));
    expect(chain.backend.calls.where((c) => c.startsWith('repost')), isEmpty);

    final s2 = await bob.receiveSlatepack(slate.slatepack!);
    (await chain.api(alice)).skipNextBroadcast = true;
    final s3 = await alice.finalizeSlatepack(s2.slatepack!);
    expect(s3.posted, isFalse);
    await sync(alice);
    var tx = await row(alice, slate.slateId!);
    expect(otherData(tx)[TxV2OdKeys.grinHasStoredTx], isTrue);
    expect(tx.height, isNull);
    expect(alice.info.cachedChainHeight, 15);

    await alice.repost(slate.slateId!);
    expect(
      chain.backend.calls.where((c) => c.startsWith('repost')),
      hasLength(1),
    );
    // Posting mined height 16.
    expect(await chain.mine(alice, 10), 26);
    await sync(alice);
    await sync(bob);
    tx = await row(alice, slate.slateId!);
    expect(tx.height, 16);
    expect(label(alice, tx), 'Sent');
    expect(otherData(tx)[TxV2OdKeys.grinKernelExcess], s3.kernelExcess);
    expect(bob.info.cachedBalance.spendable, grin(20));
  }, timeout: _timeout);

  testWidgets('payment proof export and verify', (tester) async {
    final (:chain, :alice, :bob) = await fundedPair();
    final slate = await alice.createSlatepack(
      amount: grin(25),
      recipientAddress: await bob.slatepackAddress(),
    );
    final s2 = await bob.receiveSlatepack(slate.slatepack!);
    final s3 = await alice.finalizeSlatepack(s2.slatepack!);
    await chain.mine(alice, 1);
    await sync(alice);
    await sync(bob);

    final json = await alice.exportPaymentProof(slate.slateId!);
    final proof = GrinPaymentProof.fromJsonString(json);
    expect(proof.amount, grin(25).raw);
    expect(proof.excess, s3.kernelExcess);
    expect(proof.senderAddress, await alice.slatepackAddress());
    expect(proof.recipientAddress, await bob.slatepackAddress());

    final asSender = await alice.verifyPaymentProof(json);
    expect(asSender.isSender, isTrue);
    expect(asSender.isRecipient, isFalse);
    final asRecipient = await bob.verifyPaymentProof(json);
    expect(asRecipient.isSender, isFalse);
    expect(asRecipient.isRecipient, isTrue);

    final tampered = jsonEncode({...proof.toJson(), 'amount': '20'});
    await expectLater(bob.verifyPaymentProof(tampered), throwsA(anything));
    await expectLater(
      bob.verifyPaymentProof('not a proof'),
      throwsA(
        predicate((e) => e.toString().contains('not a Grin payment proof')),
      ),
    );
    // The receiving side keeps no proof.
    expect(
      otherData(await row(bob, slate.slateId!))[TxV2OdKeys.grinHasPaymentProof],
      isFalse,
    );
    await expectLater(
      bob.exportPaymentProof(slate.slateId!),
      throwsA(predicate((e) => e.toString().contains('no payment proof'))),
    );
  }, timeout: _timeout);

  testWidgets('restore from a mnemonic scans from the restore height and '
      'resumes a cancelled scan', (tester) async {
    final chain = await Chain.start();
    final miner = await chain.wallet('miner');
    final original = await chain.wallet('original');
    expect(await chain.mine(miner, 3), 3);
    // Heights 4 to 15 pay the original wallet.
    expect(await chain.mine(original, 12), 15);
    await sync(original);
    final mnemonic = await original.getMnemonic();
    final address = await original.slatepackAddress();

    final restored = await chain.wallet(
      'restored',
      mnemonic: mnemonic,
      restoreHeight: 4,
      restore: true,
    );
    await restored.init(isRestore: true);
    expect(
      chain.backend.calls.where((c) => c.contains(restored.walletId)),
      isEmpty,
    );

    chain.backend.cancelNextScan = true;
    await restored.recover(isRescan: false);
    expect(
      chain.backend.calls,
      contains('create:${restored.walletId}:new=false'),
    );
    expect((await restored.getCurrentReceivingAddress())!.value, address);

    // The scan job ends cancelled: the resume height is saved, no error is
    // reported and nothing is found yet.
    final api = await chain.api(restored);
    await eventually(
      () => api.scanStarts.length == 1 && !restored.refreshMutex.isLocked,
      reason: 'first scan',
    );
    expect(api.scanStarts, [4]);
    expect(restored.info.grinData?.pendingScanFrom, 4);
    expect(restored.isScanPending, isTrue);
    expect(
      chain.statuses[restored.walletId],
      isNot(contains(WalletSyncStatus.unableToSync)),
    );
    expect(await rows(restored), isEmpty);

    // Sends wait for the scan.
    await expectLater(
      restored.prepareSend(txData: sendTo(address, grin(1))),
      throwsA(predicate((e) => e.toString().contains('scanning'))),
    );

    // The next refresh resumes it and the funds appear.
    await restored.refresh();
    await eventually(
      () async =>
          restored.info.grinData?.pendingScanFrom == null &&
          restored.info.cachedBalance.total == grin(12 * reward),
      reason: 'resumed scan and refresh',
    );
    expect(api.scanStarts, [4, 4]);
    expect(restored.restoreProgress, 1);
    await sync(restored);
    expect(
      restored.info.cachedBalance.spendable,
      original.info.cachedBalance.spendable,
    );
    expect(
      restored.info.cachedBalance.total,
      original.info.cachedBalance.total,
    );
    final found = await rows(restored);
    expect(found, hasLength(12));
    expect(
      found.fold(grin(0), (sum, tx) => sum + received(tx)),
      grin(12 * reward),
    );
    expect(found.every((tx) => tx.type == TransactionType.incoming), isTrue);
    expect(
      chain.statuses[restored.walletId],
      contains(WalletSyncStatus.syncing),
    );
  }, timeout: _timeout);

  testWidgets('reopen with the stored password, then delete', (tester) async {
    final chain = await Chain.start();
    final first = await chain.wallet('doomed');
    final walletId = first.walletId;
    final dir = await chain.dirOf(first);
    final address = await first.slatepackAddress();
    await chain.mine(first, 2);
    await sync(first);
    await first.exit();
    expect(first.isOpen, isFalse);

    // A later start opens the same files with the stored password.
    final again = chain.open(walletId);
    await again.init();
    expect(chain.backend.calls, contains('open:$walletId'));
    expect(
      chain.backend.calls.where((c) => c.startsWith('create:$walletId')),
      hasLength(1),
    );
    expect(await again.getNativeReceivingAddress(), address);
    await sync(again);
    expect(again.info.cachedBalance.total, grin(2 * reward));
    final api = await chain.api(again);

    // Delete closes the live instance first.
    expect(
      await GrinWallet.deleteWalletFiles(
        walletId: walletId,
        secureStore: secrets,
        backend: chain.backend,
      ),
      isTrue,
    );
    expect(again.isOpen, isFalse);
    expect(api.isClosed, isTrue);
    expect(chain.backend.calls.last, 'delete:$walletId');
    expect(Directory(p.join(dir, 'wallet_data')).existsSync(), isFalse);
    expect(Directory(dir).existsSync(), isFalse);
    expect(
      secrets.values.containsKey(GrinWallet.passwordKey(walletId)),
      isFalse,
    );
    expect(secrets.deletes, contains(GrinWallet.passwordKey(walletId)));
    // Calls after the delete return quietly.
    await again.refresh();
  }, timeout: _timeout);
}

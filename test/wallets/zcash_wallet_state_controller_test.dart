import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/utilities/flutter_secure_storage_interface.dart';
import 'package:stackwallet/wallets/wallet/intermediate/zcash_wallet_state.dart';
import 'package:stackwallet/wallets/wallet/intermediate/zcash_wallet_state_controller.dart';
import 'package:zcash_flutter/zcash_flutter.dart' as zcash;

void main() {
  test('concurrent refresh callers share one serialized sync', () async {
    final directory = await Directory.systemTemp.createTemp(
      'zcash_controller_test_',
    );
    addTearDown(() => directory.delete(recursive: true));
    final executor = _UnusedScanExecutor();
    final sync = _GatedSyncSession();
    final controller = await ZcashWalletStateController.open(
      store: ZcashEncryptedWalletStateStore(
        path: '${directory.path}/wallet.state',
        walletId: 'wallet-1',
        network: 'main',
        accountFingerprint: 'account-a',
        secureStorage: FakeSecureStorage(),
      ),
      accountFingerprint: 'account-a',
      network: 'main',
      birthdayHeight: 100,
      loadBirthdayTreeState: (_) async => const zcash.TreeState(
        hash:
            '0000000000000000000000000000000000000000000000000000000000000000',
        height: 99,
        time: 1,
      ),
      scanExecutor: executor,
      openSync: (state, receivedExecutor) {
        expect(receivedExecutor, same(executor));
        return sync;
      },
    );

    final first = controller.refresh();
    final second = controller.refresh();
    final third = controller.refresh();
    await Future<void>.delayed(Duration.zero);
    expect(sync.calls, 1);
    sync.complete(const zcash.ZcashSyncCaughtUp(chainHeight: 125));

    final snapshots = await Future.wait([first, second, third]);
    expect(snapshots.map((e) => e.chainHeight), everyElement(125));
    expect(sync.calls, 1);
  });

  test('reorg fails closed without claiming caught-up state', () async {
    final directory = await Directory.systemTemp.createTemp(
      'zcash_controller_reorg_test_',
    );
    addTearDown(() => directory.delete(recursive: true));
    final store = ZcashEncryptedWalletStateStore(
      path: '${directory.path}/wallet.state',
      walletId: 'wallet-1',
      network: 'main',
      accountFingerprint: 'account-a',
      secureStorage: FakeSecureStorage(),
    );
    const recovery = zcash.ZcashReorgRecovery(
      forkHeight: 90,
      forkBlockHash:
          '0000000000000000000000000000000000000000000000000000000000000000',
      resumeHeight: 91,
      depth: 9,
    );
    const detection = zcash.ZcashChainReorgException(
      message: 'test reorg',
      height: 100,
      expectedPrevHash:
          '0000000000000000000000000000000000000000000000000000000000000000',
      servedPrevHash:
          '1111111111111111111111111111111111111111111111111111111111111111',
    );
    final controller = await ZcashWalletStateController.open(
      store: store,
      accountFingerprint: 'account-a',
      network: 'main',
      birthdayHeight: 100,
      loadBirthdayTreeState: (_) async => const zcash.TreeState(
        hash:
            '0000000000000000000000000000000000000000000000000000000000000000',
        height: 99,
        time: 1,
      ),
      scanExecutor: _UnusedScanExecutor(),
      openSync: (_, _) => _ImmediateSyncSession(
        zcash.ZcashSyncReorged(recovery: recovery, detection: detection),
      ),
    );

    await expectLater(
      controller.refresh(),
      throwsA(isA<ZcashReorgDetectedException>()),
    );

    expect(controller.snapshot.chainHeight, 99);
    expect((await store.load())?.observedChainHeight, 99);
  });

  test('maps pool balance and only known shielded history fields', () {
    const transaction =
        '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef';
    final scan = zcash.ZcashScanResult(
      scannedBlocks: 1,
      discoveredNotes: 2,
      totalValue: 12,
      scannedHeightRange: const zcash.CompactBlockScanRange(
        start: 100,
        end: 100,
      ),
      notes: const [
        zcash.ZcashScannedNote(
          height: 100,
          tx: transaction,
          output: 0,
          value: 5,
          pool: 'sapling',
          nullifier: '1111111111111111111111111111111111111111111111111111111111111111',
          recipient: 'zs-test',
          rseed: '00',
          witness: '00',
          blockHash: 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
        ),
        zcash.ZcashScannedNote(
          height: 100,
          tx: transaction,
          output: 1,
          value: 7,
          pool: 'orchard',
          nullifier: '2222222222222222222222222222222222222222222222222222222222222222',
          recipient: 'u-test',
          rho: '00',
          rseed: '00',
          witness: '00',
          noteVersion: 'v2',
          blockHash: 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
        ),
      ],
    );
    final state = zcash.ZcashWalletSyncState.atBirthday(
      cursor: zcash.ZcashLightwalletdSyncCursor.fromTreeState(
        const zcash.TreeState(
          hash: '0000000000000000000000000000000000000000000000000000000000000000',
          height: 99,
          time: 1,
        ),
      ),
      network: zcash.ZcashAddressNetwork.mainnet,
      accountFingerprint: 'account-a',
    );
    state.sapling.apply(scan, accountFingerprint: 'account-a');
    state.orchard.apply(scan, accountFingerprint: 'account-a');
    state.ironwood.apply(scan, accountFingerprint: 'account-a');
    final nativeBalance = zcash.ZcashAccountBalance.fromScan(scan: scan);
    final mapper = ZcashStackStateMapper(walletId: 'wallet-1');

    final balance = mapper.balance(nativeBalance);
    final transactions = mapper.transactions(state.history());

    expect(nativeBalance.byPool, {
      'sapling': 5,
      'orchard': 7,
      'ironwood': 0,
      'transparent': 0,
    });
    expect(balance.total.raw, BigInt.from(12));
    expect(balance.spendable.raw, BigInt.from(5));
    expect(balance.blockedTotal.raw, BigInt.from(7));
    expect(transactions, hasLength(1));
    expect(transactions.single.height, 100);
    expect(transactions.single.timestamp, 0);
    expect(
      transactions.single.blockHash,
      'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
    );
    final metadata =
        jsonDecode(transactions.single.otherData!) as Map<String, dynamic>;
    expect(metadata['zcashMetadataStatus'], 'partial');
    expect(metadata['zcashMissingFields'], [
      'timestamp',
      'fee',
      'memo',
      'transactionVersion',
    ]);
    expect(metadata, isNot(contains('onChainMemo')));
  });

  test(
    'native scan executor delegates raw FFI work across its boundary',
    () async {
      (String ufvk, String network, String envelope)? received;
      final executor = ZcashNativeIsolateScanExecutor(
        ufvk: 'secret-ufvk',
        network: 'main',
        worker: (request) async {
          received = request;
          return jsonEncode({
            'scanned_blocks': 0,
            'discovered_notes': 0,
            'total_value': 0,
            'notes': <Object>[],
            'spends': <Object>[],
          });
        },
      );
      final envelope = zcash.ScanInputEnvelope(blocks: const []);

      final result = await executor.scan(envelope);

      expect(received?.$1, 'secret-ufvk');
      expect(received?.$2, 'main');
      expect(received?.$3, envelope.encode());
      expect(result.scannedBlocks, 0);
    },
  );
}

class _GatedSyncSession implements ZcashSyncSession {
  final _completer = Completer<zcash.ZcashSyncOutcome>();
  var calls = 0;

  @override
  Future<zcash.ZcashSyncOutcome> syncToTip() {
    calls += 1;
    return _completer.future;
  }

  void complete(zcash.ZcashSyncOutcome outcome) => _completer.complete(outcome);
}

class _UnusedScanExecutor implements ZcashScanExecutor {
  @override
  Future<zcash.ZcashScanResult> scan(zcash.ScanInputEnvelope envelope) =>
      throw StateError('scan should not be reached by this fake sync');
}

class _ImmediateSyncSession implements ZcashSyncSession {
  const _ImmediateSyncSession(this.outcome);

  final zcash.ZcashSyncOutcome outcome;

  @override
  Future<zcash.ZcashSyncOutcome> syncToTip() async => outcome;
}

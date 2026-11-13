import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/v2/transaction_v2.dart';
import 'package:stackwallet/utilities/flutter_secure_storage_interface.dart';
import 'package:stackwallet/wallets/wallet/intermediate/zcash_wallet_state.dart';
import 'package:stackwallet/wallets/wallet/intermediate/zcash_wallet_state_controller.dart';
import 'package:stackwallet/wallets/wallet/intermediate/zcash_transparent_receiver_discovery.dart';
import 'package:zcash_flutter/zcash_flutter.dart' as zcash;

void main() {
  test('transparent discovery queries exactly birthday through '
      'caught-up tip', () async {
    final directory = await Directory.systemTemp.createTemp(
      'zcash_controller_transparent_range_',
    );
    addTearDown(() => directory.delete(recursive: true));
    final seed = zcash.nativeMnemonicToSeed(
      'abandon abandon abandon abandon abandon abandon abandon abandon '
      'abandon abandon abandon about',
    );
    final account = zcash.deriveNativeAccountMetadata(
      seedHex: seed.seedHex,
      network: zcash.ZcashNetwork.mainnet,
    );
    final viewingKeys = zcash.deriveNativeViewingKeys(
      seedHex: seed.seedHex,
      network: zcash.ZcashNetwork.mainnet,
    );
    final discovery = ZcashTransparentReceiverDiscovery(
      network: zcash.ZcashNetwork.mainnet,
      viewingKeys: viewingKeys,
    );
    final defaultAddress = viewingKeys.transparent.defaultExternalAddress;
    final ranges = <({int start, int end})>[];
    final controller = await ZcashWalletStateController.open(
      store: ZcashEncryptedWalletStateStore(
        path: '${directory.path}/wallet.state',
        walletId: 'wallet-range',
        network: 'main',
        accountFingerprint: account.fingerprint,
        secureStorage: FakeSecureStorage(),
      ),
      accountFingerprint: account.fingerprint,
      network: 'main',
      birthdayHeight: 100,
      loadBirthdayTreeState: (_) async => const zcash.TreeState(
        hash:
            '0000000000000000000000000000000000000000000000000000000000000000',
        height: 99,
        time: 1,
      ),
      scanExecutor: _UnusedScanExecutor(),
      openSync: (_, _) => const _ImmediateSyncSession(
        zcash.ZcashSyncCaughtUp(chainHeight: 150),
      ),
      accountMetadata: account,
      viewingKeys: viewingKeys,
      additionalTransparentReceivers: discovery.initialReceivers().where(
        (receiver) => receiver.address != defaultAddress,
      ),
      transparentDiscovery: discovery,
      transparentActivity: (addresses, start, end) async {
        ranges.add((start: start, end: end));
        return const {};
      },
      refreshTransparent: (state) async => zcash.ZcashTransparentRefresh(
        network: state.network,
        accountFingerprint: state.accountFingerprint,
        queriedAddresses: state.addresses,
        chainHeight: 150,
        chainTipHash: '22' * 32,
        canonicalBlockHashes: {150: '22' * 32},
        unspentOutputs: const [],
        observedSpends: const [],
      ),
    );

    await controller.refresh();

    expect(ranges, [(start: 100, end: 150)]);
  });

  test('registers the UA transparent child at its exact '
      'regtest index', () async {
    final directory = await Directory.systemTemp.createTemp(
      'zcash_controller_transparent_receiver_',
    );
    addTearDown(() => directory.delete(recursive: true));
    final seed = zcash.nativeMnemonicToSeed(
      'abandon abandon abandon abandon abandon abandon abandon abandon '
      'abandon abandon abandon about',
    );
    final account = zcash.deriveNativeAccountMetadata(
      seedHex: seed.seedHex,
      network: zcash.ZcashNetwork.regtest,
    );
    final viewingKeys = zcash.deriveNativeViewingKeys(
      seedHex: seed.seedHex,
      network: zcash.ZcashNetwork.regtest,
    );
    final address = await zcash.deriveAddress(
      seedHex: seed.seedHex,
      network: zcash.ZcashNetwork.regtest,
    );
    final store = ZcashEncryptedWalletStateStore(
      path: '${directory.path}/wallet.state',
      walletId: 'wallet-1',
      network: 'regtest',
      accountFingerprint: account.fingerprint,
      secureStorage: FakeSecureStorage(),
    );

    final controller = await ZcashWalletStateController.open(
      store: store,
      accountFingerprint: account.fingerprint,
      network: 'regtest',
      birthdayHeight: 100,
      loadBirthdayTreeState: (_) async => const zcash.TreeState(
        hash:
            '0000000000000000000000000000000000000000000000000000000000000000',
        height: 99,
        time: 1,
      ),
      scanExecutor: _UnusedScanExecutor(),
      openSync: (_, _) =>
          const _ImmediateSyncSession(zcash.ZcashSyncCaughtUp(chainHeight: 99)),
      accountMetadata: account,
      viewingKeys: viewingKeys,
      additionalTransparentReceivers: [
        zcash.ZcashTransparentReceiver(
          address: address.transparentAddress!,
          scope: zcash.ZcashTransparentReceiverScope.external,
          childIndex: address.nextValidIndex,
        ),
      ],
      refreshTransparent: (state) async {
        expect(state.addresses, contains(address.transparentAddress));
        return zcash.ZcashTransparentRefresh(
          network: state.network,
          accountFingerprint: state.accountFingerprint,
          queriedAddresses: state.addresses,
          chainHeight: 99,
          chainTipHash: '22' * 32,
          canonicalBlockHashes: {99: '22' * 32},
          unspentOutputs: [
            zcash.ZcashTransparentOutputObservation(
              address: address.transparentAddress!,
              protocolTxid: '11' * 32,
              outputIndex: 0,
              scriptHex: '51',
              valueZatoshis: 100000,
              minedHeight: 99,
              blockHash: '22' * 32,
              blockTime: 1700000000,
              isCoinbase: false,
            ),
          ],
          observedSpends: const [],
        );
      },
    );
    await controller.refresh();

    final transparent = (await store.load())!.syncState.transparent;
    expect(
      address.nextValidIndex,
      isNot(viewingKeys.transparent.defaultExternalIndex),
    );
    expect(
      transparent.receivers,
      contains(
        isA<zcash.ZcashTransparentReceiver>()
            .having(
              (receiver) => receiver.address,
              'address',
              address.transparentAddress,
            )
            .having(
              (receiver) => receiver.childIndex,
              'child',
              address.nextValidIndex,
            ),
      ),
    );
    expect(
      transparent.unspentOutputs.single.address,
      address.transparentAddress,
    );
    final key = zcash.deriveNativeTransparentSpendingKey(
      seedHex: seed.seedHex,
      network: zcash.ZcashNetwork.regtest,
      childIndex: address.nextValidIndex,
    );
    try {
      expect(key.address, address.transparentAddress);
      expect(
        key.address,
        transparent.coinSet.tracked.single.utxo.address,
        reason:
            'the synced UA receiver must have the exact spendable child key',
      );
    } finally {
      key.destroy();
    }
  });

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
      openSync: (_, _) => const _ImmediateSyncSession(
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
    const scan = zcash.ZcashScanResult(
      scannedBlocks: 1,
      discoveredNotes: 2,
      totalValue: 12,
      scannedHeightRange: zcash.CompactBlockScanRange(start: 100, end: 100),
      notes: [
        zcash.ZcashScannedNote(
          height: 100,
          tx: transaction,
          output: 0,
          value: 5,
          pool: 'sapling',
          nullifier:
              '11111111111111111111111111111111'
              '11111111111111111111111111111111',
          recipient: 'zs-test',
          rseed: '00',
          witness: '00',
          blockHash:
              'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa'
              'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
        ),
        zcash.ZcashScannedNote(
          height: 100,
          tx: transaction,
          output: 1,
          value: 7,
          pool: 'orchard',
          nullifier:
              '22222222222222222222222222222222'
              '22222222222222222222222222222222',
          recipient: 'u-test',
          rho: '00',
          rseed: '00',
          witness: '00',
          noteVersion: 'v2',
          blockHash:
              'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa'
              'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
        ),
      ],
    );
    final state = zcash.ZcashWalletSyncState.atBirthday(
      cursor: zcash.ZcashLightwalletdSyncCursor.fromTreeState(
        const zcash.TreeState(
          hash:
              '00000000000000000000000000000000'
              '00000000000000000000000000000000',
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
    const mapper = ZcashStackStateMapper(walletId: 'wallet-1');

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
    expect(metadata[TxV2OdKeys.metadataStatus], 'partial');
    expect(metadata[TxV2OdKeys.missingMetadata], [
      'timestamp',
      'fee',
      'memo',
      'transactionVersion',
    ]);
    expect(transactions.single.walletNetAmountRaw, BigInt.from(12));
    expect(transactions.single.assetPools, ['orchard', 'sapling']);
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

  test('unvalued spend does not claim a wallet net amount', () {
    const transaction =
        '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef';
    const scan = zcash.ZcashScanResult(
      scannedBlocks: 1,
      discoveredNotes: 0,
      totalValue: 0,
      scannedHeightRange: zcash.CompactBlockScanRange(start: 100, end: 100),
      notes: [],
      spends: [
        zcash.ZcashObservedSpend(
          height: 100,
          tx: transaction,
          pool: 'sapling',
          nullifier:
              '11111111111111111111111111111111'
              '11111111111111111111111111111111',
          index: 0,
        ),
      ],
    );
    final state = zcash.ZcashWalletSyncState.atBirthday(
      cursor: zcash.ZcashLightwalletdSyncCursor.fromTreeState(
        const zcash.TreeState(
          hash:
              '00000000000000000000000000000000'
              '00000000000000000000000000000000',
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

    final mapped = const ZcashStackStateMapper(walletId: 'wallet-1')
        .transactions(state.history())
        .single;

    expect(mapped.walletNetAmountRaw, isNull);
    expect(mapped.isMetadataMissing('walletNetAmount'), isTrue);
  });

  test(
    'inspection retains pool, note identity, spend, and change metadata',
    () {
      const nullifier =
          '11111111111111111111111111111111'
          '11111111111111111111111111111111';
      const receivedTx =
          '0123456789abcdef0123456789abcdef'
          '0123456789abcdef0123456789abcdef';
      const spendingTx =
          'abcdef0123456789abcdef0123456789'
          'abcdef0123456789abcdef0123456789';
      const scan = zcash.ZcashScanResult(
        scannedBlocks: 1,
        discoveredNotes: 1,
        totalValue: 70000,
        scannedHeightRange: zcash.CompactBlockScanRange(start: 100, end: 101),
        notes: [
          zcash.ZcashScannedNote(
            height: 100,
            tx: receivedTx,
            output: 2,
            value: 70000,
            pool: 'sapling',
            nullifier: nullifier,
            recipient: 'zregtestsapling1inspection',
            rseed: '00',
            isChange: true,
            witness: '00',
          ),
        ],
        spends: [
          zcash.ZcashObservedSpend(
            height: 101,
            tx: spendingTx,
            pool: 'sapling',
            nullifier: nullifier,
            index: 0,
          ),
        ],
      );
      final state = zcash.ZcashWalletSyncState.atBirthday(
        cursor: zcash.ZcashLightwalletdSyncCursor.origin(height: 100),
        network: zcash.ZcashAddressNetwork.regtest,
        accountFingerprint: 'account-a',
      );
      state.sapling.apply(scan, accountFingerprint: 'account-a');

      final inspection = const ZcashStackStateMapper(walletId: 'wallet-1')
          .inspection(state, chainHeight: 101);

      expect(inspection.chainHeight, 101);
      expect(inspection.balances['sapling'], BigInt.zero);
      expect(inspection.values, hasLength(1));
      expect(inspection.values.single.id, nullifier);
      expect(inspection.values.single.pool, 'sapling');
      expect(inspection.values.single.value, BigInt.from(70000));
      expect(inspection.values.single.isSpent, isTrue);
      expect(inspection.values.single.isChange, isTrue);
      expect(inspection.values.single.isSpendable, isFalse);
      expect(inspection.values.single.spendingProtocolTxid, spendingTx);
    },
  );

  test('inspection only marks complete unspent notes as spendable', () {
    const transaction =
        '0123456789abcdef0123456789abcdef'
        '0123456789abcdef0123456789abcdef';
    const saplingNullifier =
        '11111111111111111111111111111111'
        '11111111111111111111111111111111';
    const ironwoodNullifier =
        '22222222222222222222222222222222'
        '22222222222222222222222222222222';
    const incompleteNullifier =
        '33333333333333333333333333333333'
        '33333333333333333333333333333333';
    const orchardNullifier =
        '44444444444444444444444444444444'
        '44444444444444444444444444444444';
    const scan = zcash.ZcashScanResult(
      scannedBlocks: 1,
      discoveredNotes: 4,
      totalValue: 100000,
      scannedHeightRange: zcash.CompactBlockScanRange(start: 100, end: 100),
      notes: [
        zcash.ZcashScannedNote(
          height: 100,
          tx: transaction,
          output: 0,
          value: 10000,
          pool: 'sapling',
          nullifier: saplingNullifier,
          recipient: 'zregtestsapling1inspection',
          rseed: '00',
          witness: '00',
        ),
        zcash.ZcashScannedNote(
          height: 100,
          tx: transaction,
          output: 1,
          value: 20000,
          pool: 'ironwood',
          nullifier: ironwoodNullifier,
          recipient: 'uregtest1inspection',
          rseed: '00',
          rho: '00',
          noteVersion: 'v3',
          witness: '00',
        ),
        zcash.ZcashScannedNote(
          height: 100,
          tx: transaction,
          output: 2,
          value: 30000,
          pool: 'ironwood',
          nullifier: incompleteNullifier,
          recipient: 'uregtest1incomplete',
          rseed: '00',
          rho: '00',
          noteVersion: 'v3',
        ),
        zcash.ZcashScannedNote(
          height: 100,
          tx: transaction,
          output: 3,
          value: 40000,
          pool: 'orchard',
          nullifier: orchardNullifier,
          recipient: 'uregtest1orchard',
          rseed: '00',
          rho: '00',
          noteVersion: 'v2',
          witness: '00',
        ),
      ],
    );
    final state = zcash.ZcashWalletSyncState.atBirthday(
      cursor: zcash.ZcashLightwalletdSyncCursor.origin(height: 100),
      network: zcash.ZcashAddressNetwork.regtest,
      accountFingerprint: 'account-a',
    );
    state.sapling.apply(scan, accountFingerprint: 'account-a');
    state.orchard.apply(scan, accountFingerprint: 'account-a');
    state.ironwood.apply(scan, accountFingerprint: 'account-a');

    final values = const ZcashStackStateMapper(walletId: 'wallet-1')
        .inspection(state, chainHeight: 100)
        .values;

    expect(
      values.singleWhere((value) => value.id == saplingNullifier).isSpendable,
      isTrue,
    );
    expect(
      values.singleWhere((value) => value.id == ironwoodNullifier).isSpendable,
      isTrue,
    );
    expect(
      values
          .singleWhere((value) => value.id == incompleteNullifier)
          .isSpendable,
      isFalse,
    );
    expect(
      values.singleWhere((value) => value.id == orchardNullifier).isSpendable,
      isTrue,
    );
  });
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

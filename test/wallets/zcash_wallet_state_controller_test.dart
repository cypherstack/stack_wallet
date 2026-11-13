import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:fixnum/fixnum.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/v2/transaction_v2.dart';
import 'package:stackwallet/utilities/flutter_secure_storage_interface.dart';
import 'package:stackwallet/wallets/wallet/intermediate/zcash_account_session.dart';
import 'package:stackwallet/wallets/wallet/intermediate/zcash_wallet_state.dart';
import 'package:stackwallet/wallets/wallet/intermediate/zcash_wallet_state_controller.dart';
import 'package:stackwallet/wallets/wallet/intermediate/zcash_transparent_receiver_discovery.dart';
import 'package:zcash_flutter/zcash_flutter.dart' as zcash;

void main() {
  test('transparent history persists incremental frontiers and rewinds '
      'them after a reorg', () async {
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
    final store = ZcashEncryptedWalletStateStore(
      path: '${directory.path}/wallet.state',
      walletId: 'wallet-range',
      network: 'main',
      accountFingerprint: account.fingerprint,
      secureStorage: FakeSecureStorage(),
    );
    final sync = _MutableSyncSession(150);
    Future<ZcashWalletStateController>
    openController() => ZcashWalletStateController.open(
      store: store,
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
      openSync: (_, _) => sync,
      accountMetadata: account,
      viewingKeys: viewingKeys,
      additionalTransparentReceivers: discovery.initialReceivers().where(
        (receiver) => receiver.address != defaultAddress,
      ),
      transparentDiscovery: discovery,
      transparentActivity: (addresses, start, end) async {
        ranges.add((start: start, end: end));
        return ZcashTransparentActivityResult.empty;
      },
      refreshTransparent: (state) async => zcash.ZcashTransparentRefresh(
        network: state.network,
        accountFingerprint: state.accountFingerprint,
        queriedAddresses: state.addresses,
        chainHeight: sync.chainHeight,
        chainTipHash: sync.chainHeight == 150 ? '22' * 32 : '33' * 32,
        canonicalBlockHashes: {
          150: '22' * 32,
          if (sync.chainHeight != 150) sync.chainHeight: '33' * 32,
        },
        unspentOutputs: const [],
        observedSpends: const [],
      ),
    );
    final controller = await openController();

    await controller.refresh();
    await controller.refresh();
    sync.chainHeight = 152;
    await controller.refresh();
    final reopened = await openController();
    await reopened.refresh();

    sync.triggerReorg(
      const zcash.ZcashSyncReorged(
        recovery: zcash.ZcashReorgRecovery(
          forkHeight: 150,
          forkBlockHash:
              '22222222222222222222222222222222'
              '22222222222222222222222222222222',
          resumeHeight: 151,
          depth: 2,
        ),
        detection: zcash.ZcashChainReorgException(
          message: 'test reorg',
          height: 151,
          expectedPrevHash:
              '22222222222222222222222222222222'
              '22222222222222222222222222222222',
          servedPrevHash:
              '44444444444444444444444444444444'
              '44444444444444444444444444444444',
        ),
      ),
    );
    await reopened.refresh();
    expect(sync.resumeCalls, 1);

    expect(ranges, [
      (start: 100, end: 150),
      (start: 151, end: 152),
      (start: 151, end: 152),
    ]);
  });

  test('newly discovered receivers backfill from the birthday while known '
      'receivers stay incremental', () async {
    final directory = await Directory.systemTemp.createTemp(
      'zcash_controller_new_receiver_frontier_',
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
      gapLimit: 2,
      hardChildLimit: 6,
    );
    final defaultAddress = viewingKeys.transparent.defaultExternalAddress;
    final initial = discovery.initialReceivers();
    final newlyActive = initial.singleWhere(
      (receiver) =>
          receiver.scope == zcash.ZcashTransparentReceiverScope.external &&
          receiver.childIndex == 1,
    );
    final sync = _MutableSyncSession(150);
    final requests = <({List<String> addresses, int start, int end})>[];
    final controller = await ZcashWalletStateController.open(
      store: ZcashEncryptedWalletStateStore(
        path: '${directory.path}/wallet.state',
        walletId: 'wallet-new-receiver',
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
      openSync: (_, _) => sync,
      accountMetadata: account,
      viewingKeys: viewingKeys,
      additionalTransparentReceivers: initial.where(
        (receiver) => receiver.address != defaultAddress,
      ),
      transparentDiscovery: discovery,
      transparentActivity: (addresses, start, end) async {
        requests.add((addresses: addresses, start: start, end: end));
        return ZcashTransparentActivityResult(
          activeAddresses: end == 151 && start == 151
              ? {newlyActive.address}
              : const {},
        );
      },
      refreshTransparent: (state) async => zcash.ZcashTransparentRefresh(
        network: state.network,
        accountFingerprint: state.accountFingerprint,
        queriedAddresses: state.addresses,
        chainHeight: sync.chainHeight,
        chainTipHash: sync.chainHeight == 150 ? '22' * 32 : '33' * 32,
        canonicalBlockHashes: {
          150: '22' * 32,
          if (sync.chainHeight != 150) sync.chainHeight: '33' * 32,
        },
        unspentOutputs: const [],
        observedSpends: const [],
      ),
    );

    await controller.refresh();
    sync.chainHeight = 151;
    await controller.refresh();

    expect(requests.map((request) => (request.start, request.end)), [
      (100, 150),
      (151, 151),
      (100, 151),
    ]);
    expect(requests.last.addresses, hasLength(2));
    expect(requests.last.addresses, isNot(contains(newlyActive.address)));
  });

  test('reorg recovery rolls every pool back before resuming from the '
      'authenticated fork tree', () async {
    final directory = await Directory.systemTemp.createTemp(
      'zcash_controller_reorg_recovery_',
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
      gapLimit: 1,
      hardChildLimit: 2,
    );
    final defaultAddress = viewingKeys.transparent.defaultExternalAddress;
    final receivers = discovery.initialReceivers();
    final transparent =
        zcash.ZcashTransparentState.fromAccount(
          account: account,
          viewingKeys: viewingKeys,
          additionalReceivers: receivers.where(
            (receiver) => receiver.address != defaultAddress,
          ),
        )..applyRefresh(
          zcash.ZcashTransparentRefresh(
            network: zcash.ZcashAddressNetwork.mainnet,
            accountFingerprint: account.fingerprint,
            queriedAddresses: receivers
                .map((receiver) => receiver.address)
                .toList(),
            chainHeight: 152,
            chainTipHash: '99' * 32,
            canonicalBlockHashes: {150: '22' * 32, 152: '99' * 32},
            unspentOutputs: const [],
            observedSpends: const [],
          ),
        );
    final coverage = _coverage(100, 152);
    final state = zcash.ZcashWalletSyncState(
      cursor: zcash.ZcashLightwalletdSyncCursor(
        nextHeight: 153,
        priorBlockHash: '99' * 32,
        trail: zcash.ZcashChainTrail(
          checkpoints: [
            zcash.ZcashChainCheckpoint(height: 150, blockHash: '22' * 32),
            zcash.ZcashChainCheckpoint(height: 151, blockHash: '77' * 32),
            zcash.ZcashChainCheckpoint(height: 152, blockHash: '99' * 32),
          ],
        ),
      ),
      network: zcash.ZcashAddressNetwork.mainnet,
      accountFingerprint: account.fingerprint,
      sapling: zcash.SaplingNoteStore()
        ..apply(coverage, accountFingerprint: account.fingerprint),
      orchard: zcash.OrchardNoteStore()
        ..apply(coverage, accountFingerprint: account.fingerprint),
      ironwood: zcash.IronwoodNoteStore()
        ..apply(coverage, accountFingerprint: account.fingerprint),
      transparent: transparent,
    );
    final store = ZcashEncryptedWalletStateStore(
      path: '${directory.path}/wallet.state',
      walletId: 'wallet-reorg-recovery',
      network: 'main',
      accountFingerprint: account.fingerprint,
      secureStorage: FakeSecureStorage(),
    );
    await store.save(
      ZcashPersistedWalletState(
        syncState: state,
        observedChainHeight: 152,
        transparentHistoryFrontiers: {
          for (final receiver in receivers) receiver.address: 152,
        },
      ),
    );
    late _BackedRecoverySyncSession sync;
    final ranges = <({int start, int end})>[];
    final controller = await ZcashWalletStateController.open(
      store: store,
      accountFingerprint: account.fingerprint,
      network: 'main',
      birthdayHeight: 100,
      loadBirthdayTreeState: (height) async => _replacementTreeState(height),
      scanExecutor: _UnusedScanExecutor(),
      openSync: (opened, _) => sync = _BackedRecoverySyncSession(opened),
      accountMetadata: account,
      viewingKeys: viewingKeys,
      additionalTransparentReceivers: receivers.where(
        (receiver) => receiver.address != defaultAddress,
      ),
      transparentDiscovery: discovery,
      transparentActivity: (addresses, start, end) async {
        ranges.add((start: start, end: end));
        return ZcashTransparentActivityResult.empty;
      },
      refreshTransparent: (transparent) async => zcash.ZcashTransparentRefresh(
        network: transparent.network,
        accountFingerprint: transparent.accountFingerprint,
        queriedAddresses: transparent.addresses,
        chainHeight: 152,
        chainTipHash: '44' * 32,
        canonicalBlockHashes: {150: '22' * 32, 152: '44' * 32},
        unspentOutputs: const [],
        observedSpends: const [],
      ),
    );

    await controller.refresh();

    final persisted = (await store.load())!;
    expect(sync.resumeCalls, 1);
    expect(sync.sawRolledBackStores, isTrue);
    expect(persisted.syncState.sapling.coveredThrough, 152);
    expect(persisted.syncState.orchard.coveredThrough, 152);
    expect(persisted.syncState.ironwood.coveredThrough, 152);
    expect(
      persisted.syncState.transparent.refreshedThroughBlockHash,
      '44' * 32,
    );
    expect(persisted.observedChainHeight, 152);
    expect(persisted.transparentHistoryFrontiers.values, everyElement(152));
    expect(ranges, [(start: 151, end: 152)]);
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

  test(
    'failed pre-birthday reorg rescan preserves the durable checkpoint',
    () async {
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
      var treeStateLoads = 0;
      final controller = await ZcashWalletStateController.open(
        store: store,
        accountFingerprint: 'account-a',
        network: 'main',
        birthdayHeight: 100,
        loadBirthdayTreeState: (_) async {
          treeStateLoads++;
          if (treeStateLoads > 1) {
            throw StateError('birthday tree unavailable');
          }
          return const zcash.TreeState(
            hash:
                '00000000000000000000000000000000'
                '00000000000000000000000000000000',
            height: 99,
            time: 1,
          );
        },
        scanExecutor: _UnusedScanExecutor(),
        openSync: (_, _) => const _ThrowingSyncSession(
          zcash.ZcashReorgTooDeepException(
            message: 'fork predates retained trail',
            lowestHeightSearched: 100,
          ),
        ),
      );

      await expectLater(
        controller.refresh(),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            'birthday tree unavailable',
          ),
        ),
      );

      expect(controller.snapshot.chainHeight, 99);
      expect((await store.load())?.observedChainHeight, 99);
    },
  );

  test(
    'pre-birthday reorg reopens a fresh birthday sync and rescans',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'zcash_controller_deep_reorg_rescan_',
      );
      addTearDown(() => directory.delete(recursive: true));
      final store = ZcashEncryptedWalletStateStore(
        path: '${directory.path}/wallet.state',
        walletId: 'wallet-deep-reorg',
        network: 'main',
        accountFingerprint: 'account-a',
        secureStorage: FakeSecureStorage(),
      );
      var treeStateLoads = 0;
      var syncOpens = 0;
      final controller = await ZcashWalletStateController.open(
        store: store,
        accountFingerprint: 'account-a',
        network: 'main',
        birthdayHeight: 100,
        loadBirthdayTreeState: (_) async {
          treeStateLoads++;
          return const zcash.TreeState(
            hash:
                '00000000000000000000000000000000'
                '00000000000000000000000000000000',
            height: 99,
            time: 1,
          );
        },
        scanExecutor: _UnusedScanExecutor(),
        openSync: (_, _) {
          syncOpens++;
          return syncOpens == 1
              ? const _ThrowingSyncSession(
                  zcash.ZcashReorgTooDeepException(
                    message: 'fork predates retained trail',
                    lowestHeightSearched: 100,
                  ),
                )
              : const _ImmediateSyncSession(
                  zcash.ZcashSyncCaughtUp(chainHeight: 125),
                );
        },
      );

      final snapshot = await controller.refresh();

      expect(snapshot.chainHeight, 125);
      expect(treeStateLoads, 2);
      expect(syncOpens, 2);
      expect((await store.load())?.observedChainHeight, 125);
    },
  );

  test('repeated too-deep reorgs perform only one birthday restart', () async {
    final directory = await Directory.systemTemp.createTemp(
      'zcash_controller_repeated_deep_reorg_',
    );
    addTearDown(() => directory.delete(recursive: true));
    final store = ZcashEncryptedWalletStateStore(
      path: '${directory.path}/wallet.state',
      walletId: 'wallet-repeated-deep-reorg',
      network: 'main',
      accountFingerprint: 'account-a',
      secureStorage: FakeSecureStorage(),
    );
    var treeStateLoads = 0;
    var syncOpens = 0;
    final controller = await ZcashWalletStateController.open(
      store: store,
      accountFingerprint: 'account-a',
      network: 'main',
      birthdayHeight: 100,
      loadBirthdayTreeState: (_) async {
        treeStateLoads++;
        return const zcash.TreeState(
          hash:
              '00000000000000000000000000000000'
              '00000000000000000000000000000000',
          height: 99,
          time: 1,
        );
      },
      scanExecutor: _UnusedScanExecutor(),
      openSync: (_, _) {
        syncOpens++;
        return const _ThrowingSyncSession(
          zcash.ZcashReorgTooDeepException(
            message: 'server remains below the retained trail',
            lowestHeightSearched: 100,
          ),
        );
      },
    );

    await expectLater(
      controller.refresh(),
      throwsA(
        isA<ZcashRecoveryLimitException>().having(
          (error) => error.attempts,
          'attempts',
          1,
        ),
      ),
    );

    expect(treeStateLoads, 2);
    expect(syncOpens, 2);
    expect(controller.snapshot.chainHeight, 99);
    expect((await store.load())?.observedChainHeight, 99);
  });

  test(
    'repeated shallow reorgs stop at the per-refresh recovery limit',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'zcash_controller_repeated_shallow_reorg_',
      );
      addTearDown(() => directory.delete(recursive: true));
      final store = ZcashEncryptedWalletStateStore(
        path: '${directory.path}/wallet.state',
        walletId: 'wallet-repeated-shallow-reorg',
        network: 'main',
        accountFingerprint: 'account-a',
        secureStorage: FakeSecureStorage(),
      );
      var treeStateLoads = 0;
      var syncOpens = 0;
      late _RepeatingShallowSyncSession sync;
      final controller = await ZcashWalletStateController.open(
        store: store,
        accountFingerprint: 'account-a',
        network: 'main',
        birthdayHeight: 100,
        loadBirthdayTreeState: (_) async {
          treeStateLoads++;
          return const zcash.TreeState(
            hash:
                '00000000000000000000000000000000'
                '00000000000000000000000000000000',
            height: 99,
            time: 1,
          );
        },
        scanExecutor: _UnusedScanExecutor(),
        openSync: (_, _) {
          syncOpens++;
          return sync = _RepeatingShallowSyncSession();
        },
      );

      await expectLater(
        controller.refresh(),
        throwsA(
          isA<ZcashRecoveryLimitException>().having(
            (error) => error.attempts,
            'attempts',
            ZcashWalletStateController.maximumRecoveryCyclesPerRefresh,
          ),
        ),
      );

      expect(sync.syncCalls, 3);
      expect(sync.resumeCalls, 2);
      expect(sync.forkTreeLoads, 2);
      expect(treeStateLoads, 1);
      expect(syncOpens, 1);
      expect((await store.load())?.observedChainHeight, 99);
    },
  );

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

  test('restore infers same-pool change from a wallet-owned spend', () {
    final sourceNullifier = '11' * 32;
    final sendTxid = 'aa' * 32;
    final state = zcash.ZcashWalletSyncState.atBirthday(
      cursor: zcash.ZcashLightwalletdSyncCursor.origin(height: 131),
      network: zcash.ZcashAddressNetwork.regtest,
      accountFingerprint: 'account-a',
    );
    final scan = zcash.ZcashScanResult(
      scannedBlocks: 2,
      discoveredNotes: 4,
      totalValue: 1760000,
      scannedHeightRange: const zcash.CompactBlockScanRange(
        start: 120,
        end: 131,
      ),
      notes: [
        zcash.ZcashScannedNote(
          height: 120,
          tx: '22' * 32,
          output: 0,
          value: 1000000,
          pool: 'ironwood',
          nullifier: sourceNullifier,
        ),
        zcash.ZcashScannedNote(
          height: 131,
          tx: sendTxid,
          output: 4,
          value: 710000,
          pool: 'ironwood',
          nullifier: '33' * 32,
          isChange: false,
        ),
        zcash.ZcashScannedNote(
          height: 131,
          tx: 'bb' * 32,
          output: 0,
          value: 20000,
          pool: 'ironwood',
          nullifier: '44' * 32,
          isChange: false,
        ),
        zcash.ZcashScannedNote(
          height: 131,
          tx: sendTxid,
          output: 0,
          value: 30000,
          pool: 'sapling',
          nullifier: '55' * 32,
          isChange: false,
        ),
      ],
      spends: [
        zcash.ZcashObservedSpend(
          height: 131,
          tx: sendTxid,
          pool: 'ironwood',
          nullifier: sourceNullifier,
          index: 0,
        ),
      ],
    );
    state.ironwood.apply(scan, accountFingerprint: 'account-a');
    state.sapling.apply(scan, accountFingerprint: 'account-a');

    final values = const ZcashStackStateMapper(walletId: 'wallet-1')
        .inspection(state, chainHeight: 131)
        .values;

    expect(
      values.singleWhere((value) => value.id == '33' * 32).isChange,
      isTrue,
    );
    expect(
      values.singleWhere((value) => value.id == '44' * 32).isChange,
      isFalse,
    );
    expect(
      values.singleWhere((value) => value.id == '55' * 32).isChange,
      isFalse,
    );
  });

  test('independent destination receipt is not inferred as change', () {
    final receiveTxid = 'aa' * 32;
    final state = zcash.ZcashWalletSyncState.atBirthday(
      cursor: zcash.ZcashLightwalletdSyncCursor.origin(height: 131),
      network: zcash.ZcashAddressNetwork.regtest,
      accountFingerprint: 'account-b',
    );
    final scan = zcash.ZcashScanResult(
      scannedBlocks: 1,
      discoveredNotes: 1,
      totalValue: 80000,
      scannedHeightRange: const zcash.CompactBlockScanRange(
        start: 131,
        end: 131,
      ),
      notes: [
        zcash.ZcashScannedNote(
          height: 131,
          tx: receiveTxid,
          output: 3,
          value: 80000,
          pool: 'ironwood',
          nullifier: '44' * 32,
          isChange: false,
        ),
      ],
    );
    state.ironwood.apply(scan, accountFingerprint: 'account-b');

    final receipt = const ZcashStackStateMapper(walletId: 'wallet-2')
        .inspection(state, chainHeight: 131)
        .values
        .single;

    expect(receipt.isChange, isFalse);
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

class _ThrowingSyncSession implements ZcashSyncSession {
  const _ThrowingSyncSession(this.error);

  final Object error;

  @override
  Future<zcash.ZcashSyncOutcome> syncToTip() => Future.error(error);
}

class _MutableSyncSession implements ZcashReorgRecoverableSyncSession {
  _MutableSyncSession(this.chainHeight);

  int chainHeight;
  zcash.ZcashSyncReorged? _reorg;
  var resumeCalls = 0;

  void triggerReorg(zcash.ZcashSyncReorged outcome) => _reorg = outcome;

  @override
  Future<zcash.ZcashSyncOutcome> syncToTip() async {
    return _reorg ?? zcash.ZcashSyncCaughtUp(chainHeight: chainHeight);
  }

  @override
  Future<void> resumeFrom(zcash.ZcashReorgRecovery recovery) async {
    expect(recovery, same(_reorg?.recovery));
    resumeCalls++;
    _reorg = null;
  }
}

class _RepeatingShallowSyncSession implements ZcashReorgRecoverableSyncSession {
  var syncCalls = 0;
  var resumeCalls = 0;
  var forkTreeLoads = 0;

  static const recovery = zcash.ZcashReorgRecovery(
    forkHeight: 99,
    forkBlockHash:
        '0000000000000000000000000000000000000000000000000000000000000000',
    resumeHeight: 100,
    depth: 1,
  );

  @override
  Future<zcash.ZcashSyncOutcome> syncToTip() async {
    syncCalls++;
    return const zcash.ZcashSyncReorged(
      recovery: recovery,
      detection: zcash.ZcashChainReorgException(
        message: 'server keeps changing the shallow fork',
        height: 100,
        expectedPrevHash:
            '0000000000000000000000000000000000000000000000000000000000000000',
        servedPrevHash:
            '1111111111111111111111111111111111111111111111111111111111111111',
      ),
    );
  }

  @override
  Future<void> resumeFrom(zcash.ZcashReorgRecovery received) async {
    resumeCalls++;
    forkTreeLoads++;
    expect(received, same(recovery));
  }
}

zcash.ZcashScanResult _coverage(int start, int end) => zcash.ZcashScanResult(
  scannedBlocks: end - start + 1,
  discoveredNotes: 0,
  totalValue: 0,
  scannedHeightRange: zcash.CompactBlockScanRange(start: start, end: end),
  notes: const [],
);

String _replacementHash(int height) => switch (height) {
  150 => '22' * 32,
  151 => '33' * 32,
  152 => '44' * 32,
  _ => height.toRadixString(16).padLeft(64, '0'),
};

List<int> _hexBytes(String value) => [
  for (var index = 0; index < value.length; index += 2)
    int.parse(value.substring(index, index + 2), radix: 16),
];

zcash.TreeState _replacementTreeState(int height) => zcash.TreeState(
  hash: zcash.reverseTxidByteOrder(_replacementHash(height)),
  height: height,
  time: 1700000000 + height,
);

zcash.CompactBlock _replacementBlock(int height) => zcash.CompactBlock(
  height: Int64(height),
  hash: _hexBytes(_replacementHash(height)),
  prevHash: _hexBytes(_replacementHash(height - 1)),
  time: 1700000000 + height,
);

class _BackedRecoverySyncSession implements ZcashReorgRecoverableSyncSession {
  _BackedRecoverySyncSession(this.state) {
    sync = state.syncThrough(
      chainTip: () async => 152,
      fetchRange: (start, end) async => zcash.ZcashLightwalletdScanSource([
        for (var height = start; height <= end; height++)
          _replacementBlock(height),
      ]),
      fetchTreeState: (height) async => _replacementTreeState(height),
      scan: (envelope) async {
        final range = envelope.range!;
        return _coverage(range.start, range.end);
      },
      servedBlockHashAt: (height) async => _replacementHash(height),
      network: 'main',
    );
  }

  final zcash.ZcashWalletSyncState state;
  late final zcash.ZcashChainSync sync;
  var resumed = false;
  var resumeCalls = 0;
  var sawRolledBackStores = false;

  static const recovery = zcash.ZcashReorgRecovery(
    forkHeight: 150,
    forkBlockHash:
        '2222222222222222222222222222222222222222222222222222222222222222',
    resumeHeight: 151,
    depth: 2,
  );

  @override
  Future<zcash.ZcashSyncOutcome> syncToTip() {
    if (resumed) return sync.syncToTip();
    return Future.value(
      const zcash.ZcashSyncReorged(
        recovery: recovery,
        detection: zcash.ZcashChainReorgException(
          message: 'test replacement chain',
          height: 151,
          expectedPrevHash:
              '99999999999999999999999999999999'
              '99999999999999999999999999999999',
          servedPrevHash:
              '22222222222222222222222222222222'
              '22222222222222222222222222222222',
        ),
      ),
    );
  }

  @override
  Future<void> resumeFrom(zcash.ZcashReorgRecovery received) async {
    resumeCalls++;
    sawRolledBackStores =
        received.forkHeight == recovery.forkHeight &&
        state.sapling.coveredThrough == recovery.forkHeight &&
        state.orchard.coveredThrough == recovery.forkHeight &&
        state.ironwood.coveredThrough == recovery.forkHeight &&
        state.transparent.refreshedThroughHeight == recovery.forkHeight &&
        state.transparent.refreshedThroughBlockHash == recovery.forkBlockHash;
    if (!sawRolledBackStores) {
      throw StateError(
        'controller resumed before every wallet store rolled back',
      );
    }
    sync.resumeFrom(
      recovery: received,
      treeState: _replacementTreeState(received.forkHeight),
    );
    resumed = true;
  }
}

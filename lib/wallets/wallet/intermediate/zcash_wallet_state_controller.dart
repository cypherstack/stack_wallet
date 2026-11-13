import 'dart:convert';
import 'dart:isolate';

import 'package:zcash_flutter/zcash_flutter.dart' as zcash;

import '../../../models/balance.dart';
import '../../../models/isar/models/blockchain_data/transaction.dart';
import '../../../models/isar/models/blockchain_data/v2/input_v2.dart';
import '../../../models/isar/models/blockchain_data/v2/output_v2.dart';
import '../../../models/isar/models/blockchain_data/v2/transaction_v2.dart';
import '../../../utilities/amount/amount.dart';
import 'zcash_transparent_receiver_discovery.dart';
import 'zcash_wallet_state.dart';

abstract interface class ZcashScanExecutor {
  Future<zcash.ZcashScanResult> scan(zcash.ScanInputEnvelope envelope);
}

typedef ZcashNativeScanRequest = (String ufvk, String network, String envelope);
typedef ZcashNativeScanWorker = Future<String> Function(
  ZcashNativeScanRequest request,
);

/// Runs the synchronous native compact-block scanner outside Flutter's owner
/// isolate. Only strings cross the isolate boundary; native bindings are
/// opened in the worker and the result is parsed back on the owner isolate.
class ZcashNativeIsolateScanExecutor implements ZcashScanExecutor {
  const ZcashNativeIsolateScanExecutor({
    required this.ufvk,
    required this.network,
    this.worker = _runNativeScanIsolate,
  });

  final String ufvk;
  final String network;
  final ZcashNativeScanWorker worker;

  @override
  Future<zcash.ZcashScanResult> scan(zcash.ScanInputEnvelope envelope) async {
    final raw = await worker((ufvk, network, envelope.encode()));
    return zcash.ZcashScanResult.fromRawJson(
      raw,
      context: 'scan_compact_blocks/stack_wallet_isolate',
      redactSensitive: [ufvk],
    );
  }
}

Future<String> _runNativeScanIsolate(ZcashNativeScanRequest request) =>
    Isolate.run(() => _scanNativeRaw(request));

String _scanNativeRaw(ZcashNativeScanRequest request) => zcash
    .ZcashFfiBindings
    .instance
    .scanCompactBlocksRaw(request.$1, request.$2, request.$3);

abstract interface class ZcashSyncSession {
  Future<zcash.ZcashSyncOutcome> syncToTip();
}

typedef ZcashSyncSessionFactory = ZcashSyncSession Function(
  zcash.ZcashWalletSyncState state,
  ZcashScanExecutor scanExecutor,
);

typedef ZcashTransparentRefreshCallback =
    Future<zcash.ZcashTransparentRefresh> Function(
      zcash.ZcashTransparentState state,
    );

typedef ZcashTransparentActivityCallback = Future<Set<String>> Function(
  List<String> addresses,
  int startHeight,
  int chainHeight,
);

class ZcashReorgDetectedException implements Exception {
  const ZcashReorgDetectedException(this.outcome);

  final zcash.ZcashSyncReorged outcome;

  @override
  String toString() =>
      'ZcashReorgDetectedException: chain reorganized; persisted state was not '
      'advanced';
}

class ZcashWalletSnapshot {
  const ZcashWalletSnapshot({
    required this.chainHeight,
    required this.balance,
    required this.history,
  });

  final int chainHeight;
  final zcash.ZcashAccountBalance balance;
  final zcash.ZcashTransactionHistory history;
}

/// Immutable note-level state used by typed integration adapters and support
/// diagnostics. It contains no viewing or spending key material.
class ZcashWalletValueInspection {
  const ZcashWalletValueInspection({
    required this.id,
    required this.protocolTxid,
    required this.outputIndex,
    required this.pool,
    required this.value,
    required this.isSpent,
    required this.isChange,
    required this.isSpendable,
    this.spendingProtocolTxid,
  });

  final String id;
  final String protocolTxid;
  final int outputIndex;
  final String pool;
  final BigInt value;
  final bool isSpent;
  final bool isChange;
  final bool isSpendable;
  final String? spendingProtocolTxid;

  String get txid => zcash.reverseTxidByteOrder(protocolTxid);
}

/// A synchronized, immutable view of shielded values grouped by actual pool.
class ZcashWalletStateInspection {
  ZcashWalletStateInspection({
    required this.chainHeight,
    required Map<String, BigInt> balances,
    required Iterable<ZcashWalletValueInspection> values,
  }) : balances = Map.unmodifiable(balances),
       values = List.unmodifiable(values);

  final int chainHeight;
  final Map<String, BigInt> balances;
  final List<ZcashWalletValueInspection> values;
}

class ZcashStackStateMapper {
  const ZcashStackStateMapper({required this.walletId});

  static const _fractionDigits = 8;
  static const unknownTimestampSentinel = 0;
  static const unknownVersionSentinel = -1;

  final String walletId;

  ZcashWalletStateInspection inspection(
    zcash.ZcashWalletSyncState state, {
    required int chainHeight,
  }) {
    final notes = <zcash.ZcashScannedNote>[
      ...state.sapling.notes,
      ...state.orchard.notes,
      ...state.ironwood.notes,
    ];
    final spends = <zcash.ZcashObservedSpend>[
      ...state.sapling.spends,
      ...state.orchard.spends,
      ...state.ironwood.spends,
    ];
    final spendsByPoolAndNullifier =
        <(String, String), zcash.ZcashObservedSpend>{
          for (final spend in spends) (spend.pool, spend.nullifier): spend,
        };

    bool isSpent(zcash.ZcashScannedNote note) =>
        note.nullifier != null &&
        spendsByPoolAndNullifier.containsKey((note.pool, note.nullifier!));

    bool isSpendable(zcash.ZcashScannedNote note) {
      if (isSpent(note) || note.nullifier == null) return false;
      return switch (note.pool) {
        'sapling' =>
          note.recipient != null && note.rseed != null && note.witness != null,
        'orchard' =>
          note.recipient != null &&
              note.rseed != null &&
              note.rho != null &&
              note.noteVersion == 'v2' &&
              note.witness != null,
        'ironwood' =>
          note.recipient != null &&
              note.rseed != null &&
              note.rho != null &&
              note.noteVersion == 'v3' &&
              note.witness != null,
        _ => false,
      };
    }

    final values = <ZcashWalletValueInspection>[
      for (final note in notes)
        ZcashWalletValueInspection(
          id: note.nullifier ?? '${note.pool}:${note.tx}:${note.output}',
          protocolTxid: note.tx,
          outputIndex: note.output,
          pool: note.pool,
          value: BigInt.from(note.value),
          isSpent: isSpent(note),
          isChange: note.isChange ?? false,
          isSpendable: isSpendable(note),
          spendingProtocolTxid: note.nullifier == null
              ? null
              : spendsByPoolAndNullifier[(note.pool, note.nullifier!)]?.tx,
        ),
    ];
    final balances = <String, BigInt>{
      for (final pool in ['transparent', 'sapling', 'orchard', 'ironwood'])
        pool: BigInt.zero,
    };
    for (final value in values) {
      if (!value.isSpent) {
        balances[value.pool] =
            (balances[value.pool] ?? BigInt.zero) + value.value;
      }
    }
    return ZcashWalletStateInspection(
      chainHeight: chainHeight,
      balances: balances,
      values: values,
    );
  }

  Balance balance(zcash.ZcashAccountBalance native) {
    Amount amount(int value) =>
        Amount(rawValue: BigInt.from(value), fractionDigits: _fractionDigits);

    return Balance(
      total: amount(native.totalZatoshis),
      spendable: amount(native.spendableZatoshis),
      blockedTotal: amount(native.totalZatoshis - native.spendableZatoshis),
      pendingSpendable: Amount.zeroWith(fractionDigits: _fractionDigits),
    );
  }

  List<TransactionV2> transactions(zcash.ZcashTransactionHistory history) => [
    for (final entry in history.entries) _transaction(entry),
  ];

  TransactionV2 _transaction(zcash.ZcashHistoryEntry entry) {
    final inputs = <InputV2>[
      if (entry.spentZatoshis > 0)
        InputV2.isarCantDoRequiredInDefaultConstructor(
          scriptSigHex: null,
          scriptSigAsm: null,
          sequence: null,
          outpoint: null,
          addresses: const [],
          valueStringSats: entry.spentZatoshis.toString(),
          witness: null,
          innerRedeemScriptAsm: null,
          coinbase: null,
          walletOwns: true,
        ),
    ];
    final outputs = <OutputV2>[
      if (entry.receivedZatoshis > 0)
        OutputV2.isarCantDoRequiredInDefaultConstructor(
          scriptPubKeyHex: '',
          valueStringSats: entry.receivedZatoshis.toString(),
          addresses: const [],
          walletOwns: true,
        ),
    ];
    return TransactionV2(
      walletId: walletId,
      blockHash: entry.blockHash,
      hash: entry.txid,
      txid: entry.txid,
      timestamp: entry.timestamp ?? unknownTimestampSentinel,
      height: entry.height,
      inputs: inputs,
      outputs: outputs,
      version: unknownVersionSentinel,
      type: entry.isOutgoing
          ? TransactionType.outgoing
          : TransactionType.incoming,
      subType: TransactionSubType.none,
      otherData: jsonEncode({
        TxV2OdKeys.metadataStatus: TxV2OdKeys.metadataStatusPartial,
        TxV2OdKeys.missingMetadata: [
          if (entry.timestamp == null) 'timestamp',
          if (entry.blockHash == null) 'blockHash',
          if (entry.feeZatoshis == null) 'fee',
          'memo',
          'transactionVersion',
          if (entry.unvaluedSpends > 0) 'walletNetAmount',
        ],
        if (entry.unvaluedSpends == 0)
          TxV2OdKeys.walletNetAmountRaw: entry.netZatoshis.toString(),
        if (entry.feeZatoshis case final fee?)
          TxV2OdKeys.overrideFee: Amount(
            rawValue: BigInt.from(fee),
            fractionDigits: _fractionDigits,
          ).toJsonString(),
        TxV2OdKeys.assetPools: entry.pools.toList()..sort(),
        'zcashReceivedZatoshis': entry.receivedZatoshis,
        'zcashSpentZatoshis': entry.spentZatoshis,
        'zcashUnvaluedSpends': entry.unvaluedSpends,
      }),
    );
  }
}

class ZcashWalletStateController {
  ZcashWalletStateController._(
    this._store,
    this._state,
    this._sync,
    this._observedChainHeight,
    this._refreshTransparent,
    this._transparentActivity,
    this._transparentDiscovery,
    this._accountMetadata,
    this._viewingKeys,
    this._birthdayHeight,
  );

  final ZcashEncryptedWalletStateStore _store;
  final zcash.ZcashWalletSyncState _state;
  final ZcashSyncSession _sync;
  int _observedChainHeight;
  final ZcashTransparentRefreshCallback? _refreshTransparent;
  final ZcashTransparentActivityCallback? _transparentActivity;
  final ZcashTransparentReceiverDiscovery? _transparentDiscovery;
  final zcash.ZcashAccountMetadata? _accountMetadata;
  final zcash.ZcashViewingKeys? _viewingKeys;
  final int _birthdayHeight;
  Future<ZcashWalletSnapshot>? _refreshInFlight;

  static Future<ZcashWalletStateController> open({
    required ZcashEncryptedWalletStateStore store,
    required String accountFingerprint,
    required String network,
    required int birthdayHeight,
    required Future<zcash.TreeState> Function(int height) loadBirthdayTreeState,
    required ZcashScanExecutor scanExecutor,
    required ZcashSyncSessionFactory openSync,
    zcash.ZcashAccountMetadata? accountMetadata,
    zcash.ZcashViewingKeys? viewingKeys,
    Iterable<zcash.ZcashTransparentReceiver> additionalTransparentReceivers =
        const [],
    ZcashTransparentRefreshCallback? refreshTransparent,
    ZcashTransparentActivityCallback? transparentActivity,
    ZcashTransparentReceiverDiscovery? transparentDiscovery,
  }) async {
    if (birthdayHeight < 1) {
      throw ArgumentError.value(
        birthdayHeight,
        'birthdayHeight',
        'must leave a preceding tree-state height',
      );
    }
    if ((accountMetadata == null) != (viewingKeys == null)) {
      throw ArgumentError(
        'accountMetadata and viewingKeys must be supplied together',
      );
    }
    if (transparentDiscovery != null &&
        (accountMetadata == null ||
            viewingKeys == null ||
            transparentActivity == null)) {
      throw ArgumentError(
        'transparent discovery requires account viewing material and an '
        'activity source',
      );
    }
    if (store.accountFingerprint != accountFingerprint ||
        store.network != network) {
      throw const ZcashStatePersistenceException(
        'wallet-state store context does not match the requested account',
      );
    }

    var persisted = await store.load();
    if (persisted == null) {
      final treeState = await loadBirthdayTreeState(birthdayHeight - 1);
      if (treeState.height != birthdayHeight - 1) {
        throw StateError(
          'birthday tree state height ${treeState.height} does not precede '
          'restore height $birthdayHeight',
        );
      }
      final state = zcash.ZcashWalletSyncState.atBirthday(
        cursor: zcash.ZcashLightwalletdSyncCursor.fromTreeState(treeState),
        network: zcash.ZcashAddressNetwork.fromJson(network),
        accountFingerprint: accountFingerprint,
        transparent: accountMetadata == null || viewingKeys == null
            ? null
            : zcash.ZcashTransparentState.fromAccount(
                account: accountMetadata,
                viewingKeys: viewingKeys,
                additionalReceivers: additionalTransparentReceivers,
              ),
      );
      persisted = ZcashPersistedWalletState(
        syncState: state,
        observedChainHeight: treeState.height,
      );
      await store.save(persisted);
    }
    if (persisted.syncState.accountFingerprint != accountFingerprint) {
      throw const ZcashStatePersistenceException(
        'wallet state belongs to a different account',
      );
    }
    if (persisted.syncState.cursor.nextHeight < birthdayHeight) {
      throw const ZcashStatePersistenceException(
        'wallet state precedes the validated restore height',
      );
    }
    if (accountMetadata != null && viewingKeys != null) {
      if (accountMetadata.fingerprint != accountFingerprint) {
        throw const ZcashStatePersistenceException(
          'native account metadata does not match the wallet fingerprint',
        );
      }
      persisted.syncState.transparent.registerAccountReceivers(
        account: accountMetadata,
        viewingKeys: viewingKeys,
        additionalReceivers: additionalTransparentReceivers,
      );
      await store.save(persisted);
    }
    final sync = openSync(persisted.syncState, scanExecutor);
    return ZcashWalletStateController._(
      store,
      persisted.syncState,
      sync,
      persisted.observedChainHeight,
      refreshTransparent,
      transparentActivity,
      transparentDiscovery,
      accountMetadata,
      viewingKeys,
      birthdayHeight,
    );
  }

  ZcashWalletSnapshot get snapshot => ZcashWalletSnapshot(
    chainHeight: _observedChainHeight,
    balance: _state.balance(),
    history: _state.history(),
  );

  ZcashWalletStateInspection get inspection =>
      const ZcashStackStateMapper(walletId: '')
          .inspection(_state, chainHeight: _observedChainHeight);

  Future<ZcashWalletSnapshot> refresh() {
    final active = _refreshInFlight;
    if (active != null) return active;
    final future = _refresh();
    _refreshInFlight = future;
    future.whenComplete(() {
      if (identical(_refreshInFlight, future)) _refreshInFlight = null;
    }).ignore();
    return future;
  }

  Future<ZcashWalletSnapshot> _refresh() async {
    final outcome = await _sync.syncToTip();
    late final int caughtUpHeight;
    switch (outcome) {
      case zcash.ZcashSyncCaughtUp(:final chainHeight):
        final scannedThrough = _state.cursor.nextHeight - 1;
        if (chainHeight < scannedThrough) {
          throw StateError(
            'lightwalletd tip $chainHeight is behind persisted scan position '
            '$scannedThrough',
          );
        }
        caughtUpHeight = chainHeight;
      case zcash.ZcashSyncReorged():
        throw ZcashReorgDetectedException(outcome);
      case zcash.ZcashSyncAdvanced():
        throw StateError('syncToTip returned before reaching a terminal state');
    }
    final refreshTransparent = _refreshTransparent;
    if (_state.transparent.addresses.isNotEmpty) {
      if (refreshTransparent == null) {
        throw StateError(
          'transparent receivers require lightwalletd transparent refresh',
        );
      }
      await _discoverTransparentReceivers(caughtUpHeight);
      final refresh = await refreshTransparent(_state.transparent);
      if (refresh.chainHeight != caughtUpHeight) {
        throw StateError(
          'shielded sync reached $caughtUpHeight while transparent refresh '
          'reached ${refresh.chainHeight}',
        );
      }
      _state.transparent.applyRefresh(refresh);
    }
    _observedChainHeight = caughtUpHeight;
    await _store.save(
      ZcashPersistedWalletState(
        syncState: _state,
        observedChainHeight: _observedChainHeight,
      ),
    );
    return snapshot;
  }

  Future<void> _discoverTransparentReceivers(int chainHeight) async {
    final discover = _transparentDiscovery;
    final activity = _transparentActivity;
    final account = _accountMetadata;
    final viewingKeys = _viewingKeys;
    if (discover == null ||
        activity == null ||
        account == null ||
        viewingKeys == null) {
      return;
    }

    final knownByAddress = {
      for (final receiver in _state.transparent.receivers)
        receiver.address: receiver,
    };
    // A just-created wallet can be initialized while the served tip is still
    // the block immediately preceding its birthday. Keep the range valid in
    // that transient state; ordinary restores query birthday..tip exactly.
    final activityStartHeight = _birthdayHeight <= chainHeight
        ? _birthdayHeight
        : chainHeight;
    final activeAddresses = await activity(
      knownByAddress.keys.toList(growable: false),
      activityStartHeight,
      chainHeight,
    );
    _validateTransparentActivity(activeAddresses, knownByAddress.keys.toSet());

    while (true) {
      final additions = <zcash.ZcashTransparentReceiver>[];
      for (final scope in zcash.ZcashTransparentReceiverScope.values) {
        final scoped =
            knownByAddress.values
                .where((receiver) => receiver.scope == scope)
                .toList()
              ..sort((a, b) => a.childIndex.compareTo(b.childIndex));
        var contiguousThrough = -1;
        for (final receiver in scoped) {
          if (receiver.childIndex != contiguousThrough + 1) break;
          contiguousThrough = receiver.childIndex;
        }
        final activeChildren = scoped
            .where((receiver) => activeAddresses.contains(receiver.address))
            .map((receiver) => receiver.childIndex);
        final highestActive = activeChildren.isEmpty
            ? -1
            : activeChildren.reduce((a, b) => a > b ? a : b);
        final requestedThrough =
            (highestActive < 0
                    ? discover.gapLimit - 1
                    : highestActive + discover.gapLimit)
                .clamp(0, discover.hardChildLimit - 1);
        if (requestedThrough > contiguousThrough) {
          additions.addAll(
            discover.deriveRange(
              scope,
              contiguousThrough + 1,
              requestedThrough + 1,
            ),
          );
        }
      }
      if (additions.isEmpty) return;

      _state.transparent.registerAccountReceivers(
        account: account,
        viewingKeys: viewingKeys,
        additionalReceivers: additions,
      );
      for (final receiver in additions) {
        knownByAddress[receiver.address] = receiver;
      }
      await _store.save(
        ZcashPersistedWalletState(
          syncState: _state,
          observedChainHeight: _observedChainHeight,
        ),
      );
      final newlyActive = await activity(
        additions.map((receiver) => receiver.address).toList(growable: false),
        activityStartHeight,
        chainHeight,
      );
      _validateTransparentActivity(
        newlyActive,
        additions.map((receiver) => receiver.address).toSet(),
      );
      activeAddresses.addAll(newlyActive);
    }
  }

  static void _validateTransparentActivity(
    Set<String> active,
    Set<String> queried,
  ) {
    if (active.difference(queried).isNotEmpty) {
      throw StateError(
        'lightwalletd returned activity for an unqueried transparent address',
      );
    }
  }
}

abstract interface class ZcashSyncDataSource {
  Future<int> getTipHeight();

  Future<zcash.ZcashLightwalletdScanSource> getBlockRange(int start, int end);

  Future<zcash.TreeState> getTreeState(int height);

  Future<String?> getBlockHash(int height);
}

ZcashSyncSession openZcashSyncSession({
  required zcash.ZcashWalletSyncState state,
  required ZcashSyncDataSource source,
  required ZcashScanExecutor scanExecutor,
  required String network,
  int rangeSize = 100,
}) => _ZcashChainSyncSession(
  state.syncThrough(
    chainTip: source.getTipHeight,
    fetchRange: source.getBlockRange,
    fetchTreeState: source.getTreeState,
    servedBlockHashAt: source.getBlockHash,
    scan: scanExecutor.scan,
    network: network,
    rangeSize: rangeSize,
  ),
);

class _ZcashChainSyncSession implements ZcashSyncSession {
  const _ZcashChainSyncSession(this._sync);

  final zcash.ZcashChainSync _sync;

  @override
  Future<zcash.ZcashSyncOutcome> syncToTip() => _sync.syncToTip();
}

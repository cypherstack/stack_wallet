import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:isar_community/isar.dart';
import 'package:mutex/mutex.dart';
import 'package:path/path.dart' as path;
import 'package:zcash_flutter/zcash_flutter.dart' as zcash;

import '../../../models/isar/models/blockchain_data/address.dart';
import '../../../models/isar/models/blockchain_data/v2/transaction_v2.dart';
import '../../../models/paymint/fee_object_model.dart';
import '../../../utilities/amount/amount.dart';
import '../../../utilities/stack_file_system.dart';
import '../../crypto_currency/crypto_currency.dart';
import '../../models/tx_data.dart';
import '../intermediate/bip39_wallet.dart';
import '../intermediate/zcash_account_session.dart';
import '../intermediate/zcash_pending_send_store.dart';
import '../intermediate/zcash_send.dart';
import '../intermediate/zcash_transparent_shielding.dart';
import '../intermediate/zcash_wallet_state.dart';
import '../intermediate/zcash_wallet_state_controller.dart';

typedef ZcashAccountSessionFactory = ZcashAccountSession Function(
  CryptoCurrencyNetwork network,
);

class ZcashWallet extends Bip39Wallet<Zcash> {
  ZcashWallet(CryptoCurrencyNetwork network) : super(Zcash(network));

  ZcashAccountSessionFactory _accountSessionFactory = (network) =>
      ZcashAccountSession(network: network);
  ZcashAccountSession? _accountSession;
  ZcashWalletStateController? _stateController;
  ZcashEncryptedWalletStateStore? _stateStore;
  ZcashPendingSendStore? _pendingSendStore;
  ZcashTransparentShieldingStore? _transparentShieldingStore;
  ZcashScanExecutor? _scanExecutor;
  ZcashWalletSendService _sendService =
      const ZcashProductionWalletSendService();
  final _sendMutex = Mutex();
  ZcashPreparedWalletSend? _preparedSend;
  int? _regtestNu63ActivationHeight;
  String? _ufvk;
  String? _accountFingerprint;
  String? _legacyAccountFingerprint;
  zcash.ZcashAccountMetadata? _accountMetadata;
  zcash.ZcashViewingKeys? _viewingKeys;
  String? _unifiedAddress;
  List<zcash.ZcashTransparentReceiver> _additionalTransparentReceivers =
      const [];

  @override
  int get isarTransactionVersion => 2;

  int get accountSessionGeneration => _accountSession?.generation ?? 0;

  void configureAccountSessionFactory(ZcashAccountSessionFactory factory) {
    if (_accountSession != null) {
      throw StateError('The Zcash account session is already initialized');
    }
    _accountSessionFactory = factory;
  }

  void configureSendService(ZcashWalletSendService service) {
    if (_stateController != null || _preparedSend != null) {
      throw StateError('The Zcash send service is already in use');
    }
    _sendService = service;
  }

  void configureRegtestConsensus({required int nu63ActivationHeight}) {
    if (cryptoCurrency.network != CryptoCurrencyNetwork.regtest) {
      throw StateError('Custom Zcash activation heights are regtest-only');
    }
    if (nu63ActivationHeight < 2) {
      throw ArgumentError.value(
        nu63ActivationHeight,
        'nu63ActivationHeight',
        'must stage NU6.3 above genesis',
      );
    }
    if (_stateController != null || _preparedSend != null) {
      throw StateError('Configure Zcash regtest consensus before sync or send');
    }
    _regtestNu63ActivationHeight = nu63ActivationHeight;
  }

  ZcashWalletStateInspection get synchronizedStateInspection {
    _requireRegtestInspection();
    return _requireStateController().inspection;
  }

  ZcashPreparedWalletSend preparedSendFor(TxData txData) {
    _requireRegtestInspection();
    final prepared = _preparedSend;
    if (prepared == null || !_matchesPrepared(txData, prepared)) {
      throw StateError('No exact Zcash prepared send matches this artifact');
    }
    return prepared;
  }

  void _requireRegtestInspection() {
    if (cryptoCurrency.network != CryptoCurrencyNetwork.regtest) {
      throw StateError('Zcash note inspection is regtest-only');
    }
  }

  @override
  FilterOperation? get changeAddressFilterOperation => null;

  @override
  FilterOperation get receivingAddressFilterOperation =>
      FilterGroup.and(standardReceivingAddressFilters);

  @override
  Future<void> init({bool? isRestore}) async {
    zcash.requireProductionWalletNativeCapabilities(zcash.nativeCapabilities());
    final seed = zcash.nativeMnemonicToSeed(
      await getMnemonic(),
      passphrase: await getMnemonicPassphrase(),
    );
    final derived = await zcash.deriveAddress(
      seedHex: seed.seedHex,
      network: cryptoCurrency.nativeNetwork,
    );
    final metadata = zcash.deriveNativeAccountMetadata(
      seedHex: seed.seedHex,
      network: cryptoCurrency.nativeNetwork,
    );
    final viewingKeys = zcash.deriveNativeViewingKeys(
      seedHex: seed.seedHex,
      network: cryptoCurrency.nativeNetwork,
    );
    _ufvk = metadata.ufvk;
    _legacyAccountFingerprint = sha256
        .convert(
          utf8.encode(
            '${cryptoCurrency.nativeNetwork.ffiLabel}|${metadata.ufvk}',
          ),
        )
        .toString();
    _accountFingerprint = metadata.fingerprint;
    _accountMetadata = metadata;
    _viewingKeys = viewingKeys;
    _unifiedAddress = derived.ua;
    final transparentAddress = derived.transparentAddress;
    if (metadata.hasTransparent && transparentAddress == null) {
      throw StateError('Zcash account has no transparent UA receiver');
    }
    if (transparentAddress case final address?) {
      final key = zcash.deriveNativeTransparentSpendingKey(
        seedHex: seed.seedHex,
        network: cryptoCurrency.nativeNetwork,
        childIndex: derived.nextValidIndex,
      );
      try {
        if (key.address != address) {
          throw StateError(
            'Zcash UA transparent receiver does not match its signing key',
          );
        }
      } finally {
        key.destroy();
      }
      final defaultAddress = viewingKeys.transparent.defaultExternalAddress;
      _additionalTransparentReceivers = defaultAddress == address
          ? const []
          : [
              zcash.ZcashTransparentReceiver(
                address: address,
                scope: zcash.ZcashTransparentReceiverScope.external,
                childIndex: derived.nextValidIndex,
              ),
            ];
    }
    final existing = await getCurrentReceivingAddress();
    final cached = info.cachedReceivingAddress;
    if ((existing != null && existing.value != derived.ua) ||
        (cached.isNotEmpty && cached != derived.ua)) {
      throw StateError('Zcash wallet address does not match the saved wallet');
    }
    final receiverRows = _receiverRows(derived);
    final persisted = await mainDB.getAddresses(walletId).findAll();
    for (final expected in receiverRows) {
      final sameSlot = persisted.where(
        (address) =>
            address.type == expected.type &&
            address.subType == expected.subType &&
            address.derivationIndex == expected.derivationIndex,
      );
      if (sameSlot.isNotEmpty &&
          sameSlot.every((address) => address.value != expected.value)) {
        throw StateError(
          'Zcash wallet receiver does not match the saved wallet',
        );
      }
    }
    await mainDB.updateOrPutAddresses(receiverRows);
    try {
      if (nodeService.getPrimaryNodeFor(currency: cryptoCurrency) != null) {
        await updateNode();
      }
      await super.init();
    } catch (_) {
      if (_accountSession != null) await _closeAccountSession();
      rethrow;
    }
  }

  @override
  Future<void> checkSaveInitialReceivingAddress() async {}

  @override
  Future<TxData> prepareSend({required TxData txData}) =>
      _sendMutex.protect(() async {
        final recipients = txData.recipients;
        if (recipients == null || recipients.length != 1) {
          throw UnsupportedError(
            'Zcash currently requires exactly one recipient; multi-recipient '
            'ZIP-321 needs a backend multi-output reservation artifact',
          );
        }
        final requested = recipients.single;
        if (requested.isChange ||
            requested.amount.fractionDigits != cryptoCurrency.fractionDigits ||
            requested.amount.raw <= BigInt.zero ||
            requested.amount.raw > BigInt.from(zcash.maxMoneyZatoshis)) {
          throw ArgumentError('Invalid Zcash recipient amount');
        }
        final resolved = _resolveStackPayment(
          address: requested.address,
          amount: requested.amount.raw,
          memo: txData.memo,
        );
        final session = _requireAccountSession();
        final syncClient = session.syncClient;
        final stateStore = _stateStore;
        final pendingStore = _pendingSendStore;
        final scanExecutor = _scanExecutor;
        if (syncClient == null ||
            stateStore == null ||
            pendingStore == null ||
            scanExecutor == null) {
          throw StateError('Zcash send requires an initialized sync session');
        }
        final snapshot = await _requireStateController().refresh();
        await _reconcileTransparentShielding();
        final persisted = await stateStore.load();
        if (persisted == null ||
            persisted.observedChainHeight != snapshot.chainHeight) {
          throw StateError('Zcash sync state is unavailable or not current');
        }
        final saplingChange = await _saplingChangeAddress();
        final ironwoodChange = await _ironwoodChangeAddress();
        final seed = zcash.nativeMnemonicToSeed(
          await getMnemonic(),
          passphrase: await getMnemonicPassphrase(),
        );
        final root = await StackFileSystem.applicationRootDirectory();
        await _releaseCurrentPrepared();
        final pending = await pendingStore.load();
        final prepared = await _sendService.prepare(
          ZcashSendPreparationRequest(
            network: cryptoCurrency.network,
            sessionGeneration: session.generation,
            state: persisted.syncState,
            pendingSends: pending,
            syncClient: syncClient,
            scanExecutor: scanExecutor,
            seedHex: seed.seedHex,
            saplingChangeAddress: saplingChange,
            ironwoodChangeAddress: ironwoodChange,
            recipient: resolved.address,
            amountZatoshis: resolved.amount.toInt(),
            memo: resolved.memo,
            targetHeight: snapshot.chainHeight + 1,
            expiryHeight: snapshot.chainHeight + 41,
            resolveSaplingProvingParameters: () =>
                zcash.SaplingProvingParameterCache(
                  cacheRoot: Directory(
                    path.join(root.path, 'zcash', 'sapling-params'),
                  ),
                ).resolve(),
            regtestNu63ActivationHeight: _regtestNu63ActivationHeight,
          ),
        );
        // This is the durability boundary: no prepared transaction is exposed
        // to review until its selected nullifiers are committed on disk.
        await pendingStore.save(pending);
        _preparedSend = prepared;
        return txData.copyWith(
          raw: prepared.transactionHex,
          txid: prepared.txid,
          fee: _amount(prepared.feeZatoshis),
          memo: txData.memo,
          recipients: [
            requested.copyWith(
              address: prepared.encodedRecipient,
              amount: _amount(prepared.amountZatoshis),
            ),
          ],
          vExtraData: _preparedDigest(prepared),
        );
      });

  /// Sweeps every mature, unreserved transparent output into this wallet's
  /// Ironwood receiver. This is intentionally a wallet-maintenance operation,
  /// not a generic transparent send or coin-control surface.
  Future<TxData> prepareTransparentShielding() => _sendMutex.protect(() async {
    final session = _requireAccountSession();
    final syncClient = session.syncClient;
    final stateStore = _stateStore;
    final shieldingStore = _transparentShieldingStore;
    final destination = _unifiedAddress;
    if (syncClient == null ||
        stateStore == null ||
        shieldingStore == null ||
        destination == null) {
      throw StateError('Zcash shielding requires an initialized sync session');
    }
    final snapshot = await _requireStateController().refresh();
    final persisted = await stateStore.load();
    if (persisted == null ||
        persisted.observedChainHeight != snapshot.chainHeight) {
      throw StateError('Zcash transparent state is unavailable or not current');
    }
    await _releaseCurrentPrepared();
    final reservedOutpoints = await shieldingStore.update((shielding) {
      shielding.reconcile(persisted.syncState.transparent);
      return shielding.reservedOutpoints;
    });

    final transparent = persisted.syncState.transparent;
    final availableOutputs = transparent.unspentOutputs.where((output) {
      final outpoint = '${output.utxo.txid}:${output.outputIndex}';
      return !reservedOutpoints.contains(outpoint);
    }).toList();
    final coins = zcash.TransparentCoinSet.fromUtxos(
      utxos: availableOutputs.map((output) => output.utxo),
      chainHeight: snapshot.chainHeight,
      coinbaseOutpoints: {
        for (final output in availableOutputs)
          if (output.isCoinbase) '${output.utxo.txid}:${output.outputIndex}',
      },
    );
    final treeState = await syncClient.getTreeState(snapshot.chainHeight);
    final anchor = treeState.ironwood?.finalState;
    if (anchor == null || anchor.isEmpty) {
      throw StateError('Zcash shielding requires the current Ironwood anchor');
    }
    final seed = zcash.nativeMnemonicToSeed(
      await getMnemonic(),
      passphrase: await getMnemonicPassphrase(),
    );
    final receivers = {
      for (final receiver in transparent.receivers) receiver.address: receiver,
    };
    final keys = <String, zcash.ZcashTransparentSpendingKey>{};
    try {
      final prepared = zcash.prepareNativeShieldingSend(
        network: cryptoCurrency.nativeNetwork,
        destination: zcash.ShieldingDestination.ironwood,
        coins: coins,
        toAddress: destination,
        targetHeight: snapshot.chainHeight + 1,
        signingKeyForCoin: (coin) {
          final receiver = receivers[coin.utxo.address];
          if (receiver == null) {
            throw StateError('transparent UTXO has no registered receiver');
          }
          final key = keys.putIfAbsent(receiver.address, () {
            final derived = zcash.deriveNativeTransparentSpendingKey(
              seedHex: seed.seedHex,
              network: cryptoCurrency.nativeNetwork,
              childIndex: receiver.childIndex,
              scope:
                  receiver.scope == zcash.ZcashTransparentReceiverScope.external
                  ? zcash.ZcashTransparentKeyScope.external
                  : zcash.ZcashTransparentKeyScope.internal,
            );
            if (derived.address != receiver.address ||
                derived.address != coin.utxo.address) {
              derived.destroy();
              throw StateError(
                'derived transparent key does not own the selected UTXO',
              );
            }
            return derived;
          });
          return key.secretKeyHex;
        },
        ironwoodAnchor: zcash.IronwoodAnchorSource.tree(anchor),
        seedHex: seed.seedHex,
        regtestNu63ActivationHeight: _regtestNu63ActivationHeight,
        allowExperimentalBuild: true,
      );
      final artifact = ZcashPreparedTransparentShielding(
        prepared: prepared,
        targetHeight: snapshot.chainHeight + 1,
        sessionGeneration: session.generation,
        encodedRecipient: destination,
        selectedReceiverAddress: destination,
      );
      await shieldingStore.update((shielding) {
        shielding.addPrepared(
          prepared,
          destinationAddress: destination,
          createdHeight: snapshot.chainHeight,
        );
      });
      _preparedSend = artifact;
      return _txDataForPrepared(artifact, isChange: true);
    } finally {
      for (final key in keys.values) {
        key.destroy();
      }
    }
  });

  /// Rehydrates an exact prepared or indeterminate shielding artifact after
  /// process restart. No key material is persisted; only the signed public
  /// transaction and its authenticated input reservation are restored.
  Future<TxData?> recoverPreparedTransparentShielding() =>
      _sendMutex.protect(() async {
        if (_preparedSend != null) {
          throw StateError('another Zcash transaction is already prepared');
        }
        final stateStore = _stateStore;
        final shieldingStore = _transparentShieldingStore;
        final session = _requireAccountSession();
        if (stateStore == null || shieldingStore == null) {
          throw StateError('Zcash shielding state is not initialized');
        }
        final persisted = await stateStore.load();
        if (persisted == null) return null;
        final resumable = await shieldingStore.update((state) {
          state.recoverInterruptedSubmissions();
          state.reconcile(persisted.syncState.transparent);
          return state.records
              .where(
                (record) =>
                    record.broadcastState ==
                        ZcashShieldingBroadcastState.prepared ||
                    record.broadcastState ==
                        ZcashShieldingBroadcastState.indeterminate,
              )
              .toList(growable: false);
        });
        if (resumable.isEmpty) return null;
        if (resumable.length != 1) {
          throw StateError(
            'multiple transparent shielding transactions need reconciliation',
          );
        }
        final record = resumable.single;
        final tracked = persisted.syncState.transparent.coinSet.tracked;
        final selected = [
          for (final coin in tracked)
            if (record.selectedOutpoints.contains(coin.outpoint)) coin,
        ];
        if (selected.length != record.selectedOutpoints.length) {
          throw StateError(
            'reserved transparent inputs are missing from canonical state',
          );
        }
        final input = selected.fold(0, (sum, coin) => sum + coin.satoshis);
        final change = input - record.shieldedZatoshis - record.feeZatoshis;
        if (change != 0) {
          throw StateError(
            'persisted shielding sweep does not conserve its exact values',
          );
        }
        final prepared = zcash.ShieldingPreparedSend(
          destination: zcash.ShieldingDestination.ironwood,
          selection: zcash.TransparentInputSelection(
            coins: List.unmodifiable(selected),
            amountZatoshis: record.shieldedZatoshis,
            feeZatoshis: record.feeZatoshis,
            changeZatoshis: change,
            spendsCoinbase: zcash.TransparentCoinSet.requiresFullShielding(
              selected,
            ),
          ),
          transactionHex: record.transactionHex,
          txid: record.txid,
          feeZatoshis: record.feeZatoshis,
          shieldedZatoshis: record.shieldedZatoshis,
        );
        await shieldingStore.update((state) {
          state.requireBroadcastable(prepared);
        });
        final artifact = ZcashPreparedTransparentShielding(
          prepared: prepared,
          targetHeight: record.createdHeight + 1,
          sessionGeneration: session.generation,
          encodedRecipient: record.destinationAddress,
          selectedReceiverAddress: record.destinationAddress,
        );
        _preparedSend = artifact;
        return _txDataForPrepared(artifact, isChange: true);
      });

  @override
  Future<TxData> confirmSend({required TxData txData}) => _sendMutex.protect(
    () async {
      final prepared = _preparedSend;
      if (prepared == null || !_matchesPrepared(txData, prepared)) {
        throw StateError(
          'Zcash confirmation must use the exact prepared transaction artifact',
        );
      }
      final session = _requireAccountSession();
      if (session.generation != prepared.sessionGeneration) {
        throw StateError(
          'The Zcash node changed after preparation; prepare again',
        );
      }
      if (prepared case ZcashPreparedTransparentShielding()) {
        await _broadcastTransparentShielding(prepared, session);
        _preparedSend = null;
        return txData;
      }
      final store = _pendingSendStore!;
      final pending = await store.load();
      try {
        await _sendService.broadcast(
          prepared: prepared,
          pendingSends: pending,
          chainHeight: info.cachedChainHeight,
          persist: () => store.save(pending),
          submit: session.submitTransactionHex,
        );
      } finally {
        await store.save(pending);
      }
      _preparedSend = null;
      return txData;
    },
  );

  @override
  Future<void> cancelSend({required TxData txData}) =>
      _sendMutex.protect(() async {
        final prepared = _preparedSend;
        if (prepared == null || !_matchesPrepared(txData, prepared)) return;
        await _releaseCurrentPrepared();
      });

  @override
  Future<void> recover({required bool isRescan}) => _sendMutex.protect(
    () => refreshMutex.protect(() async {
      if (isRescan) {
        final store = _stateStore;
        if (store == null) {
          throw StateError(
            'Zcash rescan requires an initialized sync checkpoint',
          );
        }
        await _releaseCurrentPrepared();

        // Reset only the encrypted chain checkpoint. Receiver rows, wallet
        // identity, and durable broadcast reservations must survive a rescan.
        await store.reset();
        _stateController = null;
        _stateStore = null;
        _scanExecutor = null;
        await _initializeStateController(_requireAccountSession());
      }

      final snapshot = await _requireStateController().refresh();
      final mapper = ZcashStackStateMapper(walletId: walletId);
      final transactions = mapper.transactions(snapshot.history);
      if (isRescan) {
        // The caught-up snapshot is the complete history derived from the
        // birthday. Replace it atomically, without deleting receive addresses.
        await mainDB.isar.writeTxn(() async {
          await mainDB.isar.transactionV2s
              .where()
              .walletIdEqualTo(walletId)
              .deleteAll();
          await mainDB.isar.transactionV2s.putAll(transactions);
        });
      } else {
        await mainDB.updateOrPutTransactionV2s(transactions);
      }
      await info.updateBalance(
        newBalance: mapper.balance(snapshot.balance),
        isar: mainDB.isar,
      );
      await info.updateCachedChainHeight(
        newHeight: snapshot.chainHeight,
        isar: mainDB.isar,
      );
    }),
  );

  @override
  Future<void> updateNode() async {
    final node = nodeService.getPrimaryNodeFor(currency: cryptoCurrency);
    if (node == null) {
      throw StateError(
        'Zcash requires an explicitly configured primary lightwalletd node',
      );
    }
    final session = _accountSession ??= _accountSessionFactory(
      cryptoCurrency.network,
    );
    await session.replaceNode(node);
    _stateController = null;
    await _initializeStateController(session);
  }

  @override
  Future<void> updateTransactions() async {
    final snapshot = await _requireStateController().refresh();
    await _reconcileTransparentShielding();
    await mainDB.updateOrPutTransactionV2s(
      ZcashStackStateMapper(walletId: walletId).transactions(snapshot.history),
    );
  }

  @override
  Future<void> updateBalance() async {
    final snapshot = await _requireStateController().refresh();
    await _reconcileTransparentShielding();
    await info.updateBalance(
      newBalance: ZcashStackStateMapper(walletId: walletId)
          .balance(snapshot.balance),
      isar: mainDB.isar,
    );
  }

  @override
  // Transparent outputs remain in the authenticated Zcash state. Mirroring
  // them into Stack's generic UTXO rows would expose coin-control toggles that
  // the shielded send planner does not honor, so report no generic UTXO work.
  Future<bool> updateUTXOs() async => false;

  @override
  Future<void> updateChainHeight() async {
    final snapshot = await _requireStateController().refresh();
    await _reconcileTransparentShielding();
    await info.updateCachedChainHeight(
      newHeight: snapshot.chainHeight,
      isar: mainDB.isar,
    );
  }

  @override
  Future<Amount> estimateFeeFor(Amount amount, BigInt feeRate) async =>
      _amount(10000);

  @override
  Future<FeeObject> get fees async => FeeObject(
    numberOfBlocksFast: 1,
    numberOfBlocksAverage: 1,
    numberOfBlocksSlow: 1,
    fast: BigInt.from(10000),
    medium: BigInt.from(10000),
    slow: BigInt.from(10000),
  );

  @override
  Future<bool> pingCheck() async => await _accountSession?.ping() ?? false;

  @override
  Future<void> exit() async {
    try {
      await _sendMutex.protect(() async {
        try {
          await _releaseCurrentPrepared();
        } finally {
          await _closeAccountSession();
        }
      });
    } finally {
      await super.exit();
    }
  }

  Future<void> _closeAccountSession() async {
    _stateController = null;
    _stateStore = null;
    _pendingSendStore = null;
    _transparentShieldingStore = null;
    _scanExecutor = null;
    _preparedSend = null;
    final session = _accountSession;
    _accountSession = null;
    _legacyAccountFingerprint = null;
    _accountMetadata = null;
    _viewingKeys = null;
    _unifiedAddress = null;
    _additionalTransparentReceivers = const [];
    await session?.close();
  }

  ZcashWalletStateController _requireStateController() {
    final controller = _stateController;
    if (controller == null) {
      throw StateError(
        'Zcash sync requires an explicit lightwalletd node and a validated '
        'positive restore height',
      );
    }
    return controller;
  }

  Future<void> _initializeStateController(ZcashAccountSession session) async {
    final client = session.syncClient;
    if (client == null) return;
    final ufvk = _ufvk;
    final fingerprint = _accountFingerprint;
    final legacyFingerprint = _legacyAccountFingerprint;
    final accountMetadata = _accountMetadata;
    final viewingKeys = _viewingKeys;
    if (ufvk == null ||
        fingerprint == null ||
        accountMetadata == null ||
        viewingKeys == null) {
      throw StateError('Zcash account identity is not initialized');
    }
    final birthdayHeight = info.restoreHeight;
    if (birthdayHeight < 1) {
      throw StateError(
        'Zcash requires a validated positive restore height before syncing',
      );
    }
    final root = await StackFileSystem.applicationRootDirectory();
    final network = cryptoCurrency.nativeNetwork.ffiLabel;
    final source = _ZcashSessionSyncDataSource(client);
    final scanExecutor = ZcashNativeIsolateScanExecutor(
      ufvk: ufvk,
      network: network,
    );
    final statePath = path.join(root.path, 'zcash', '$walletId.state');
    final pendingPath = path.join(root.path, 'zcash', '$walletId.pending');
    final shieldingPath = path.join(root.path, 'zcash', '$walletId.shielding');
    final stateStore = ZcashEncryptedWalletStateStore(
      path: statePath,
      walletId: walletId,
      network: network,
      accountFingerprint: fingerprint,
      secureStorage: secureStorageInterface,
    );
    final pendingStore = ZcashEncryptedPendingSendStore(
      path: pendingPath,
      walletId: walletId,
      network: network,
      accountFingerprint: fingerprint,
      secureStorage: secureStorageInterface,
    );
    final shieldingStore = ZcashEncryptedTransparentShieldingStore(
      path: shieldingPath,
      walletId: walletId,
      network: network,
      accountFingerprint: fingerprint,
      secureStorage: secureStorageInterface,
    );
    if (legacyFingerprint != null && legacyFingerprint != fingerprint) {
      await _migrateLegacyState(
        target: stateStore,
        path: statePath,
        network: network,
        legacyFingerprint: legacyFingerprint,
        canonicalFingerprint: fingerprint,
      );
      await _migrateLegacyPendingSends(
        target: pendingStore,
        path: pendingPath,
        network: network,
        legacyFingerprint: legacyFingerprint,
      );
    }
    _stateController = await ZcashWalletStateController.open(
      store: stateStore,
      accountFingerprint: fingerprint,
      network: network,
      birthdayHeight: birthdayHeight,
      loadBirthdayTreeState: source.getTreeState,
      scanExecutor: scanExecutor,
      openSync: (state, executor) => openZcashSyncSession(
        state: state,
        source: source,
        scanExecutor: executor,
        network: network,
      ),
      accountMetadata: accountMetadata,
      viewingKeys: viewingKeys,
      additionalTransparentReceivers: _additionalTransparentReceivers,
      refreshTransparent: client is ZcashLightwalletdTransparentClient
          ? (state) => (client as ZcashLightwalletdTransparentClient)
                .getTransparentRefresh(
                  state,
                  maxRangeSize: 1000,
                  maxUtxos: 10000,
                )
          : null,
    );
    _stateStore = stateStore;
    _scanExecutor = scanExecutor;
    _pendingSendStore = pendingStore;
    _transparentShieldingStore = shieldingStore;
  }

  Future<void> _migrateLegacyState({
    required ZcashEncryptedWalletStateStore target,
    required String path,
    required String network,
    required String legacyFingerprint,
    required String canonicalFingerprint,
  }) async {
    try {
      await target.load();
      return;
    } on ZcashStatePersistenceException catch (canonicalError) {
      final legacy = ZcashEncryptedWalletStateStore(
        path: path,
        walletId: walletId,
        network: network,
        accountFingerprint: legacyFingerprint,
        secureStorage: secureStorageInterface,
      );
      try {
        final persisted = await legacy.load();
        if (persisted == null) rethrow;
        await target.save(
          persisted.rebindAccountFingerprint(
            from: legacyFingerprint,
            to: canonicalFingerprint,
          ),
        );
      } on ZcashStatePersistenceException {
        throw canonicalError;
      }
    }
  }

  Future<void> _migrateLegacyPendingSends({
    required ZcashEncryptedPendingSendStore target,
    required String path,
    required String network,
    required String legacyFingerprint,
  }) async {
    try {
      await target.load();
      return;
    } on ZcashStatePersistenceException catch (canonicalError) {
      final legacy = ZcashEncryptedPendingSendStore(
        path: path,
        walletId: walletId,
        network: network,
        accountFingerprint: legacyFingerprint,
        secureStorage: secureStorageInterface,
      );
      try {
        await target.save(await legacy.load());
      } on ZcashStatePersistenceException {
        throw canonicalError;
      }
    }
  }

  Amount _amount(int zatoshis) => Amount(
    rawValue: BigInt.from(zatoshis),
    fractionDigits: cryptoCurrency.fractionDigits,
  );

  ZcashAccountSession _requireAccountSession() =>
      _accountSession ??
      (throw StateError('Zcash requires an initialized account session'));

  Future<String> _saplingChangeAddress() async {
    final rows = await mainDB.getAddresses(walletId).findAll();
    final matches = rows.where((row) => row.type == AddressType.zcashSapling);
    if (matches.length != 1) {
      throw StateError(
        'Zcash wallet has no unambiguous Sapling change receiver',
      );
    }
    return matches.single.value;
  }

  Future<String> _ironwoodChangeAddress() async {
    final rows = await mainDB.getAddresses(walletId).findAll();
    final matches = rows.where((row) => row.type == AddressType.zcashUnified);
    if (matches.length != 1) {
      throw StateError(
        'Zcash wallet has no unambiguous Unified Address for Ironwood change',
      );
    }
    return matches.single.value;
  }

  Future<void> _reconcileTransparentShielding() async {
    final stateStore = _stateStore;
    final shieldingStore = _transparentShieldingStore;
    if (stateStore == null || shieldingStore == null) return;
    final persisted = await stateStore.load();
    if (persisted == null) return;
    await shieldingStore.update((shielding) {
      shielding.reconcile(persisted.syncState.transparent);
    });
  }

  TxData _txDataForPrepared(
    ZcashPreparedWalletSend prepared, {
    required bool isChange,
  }) => TxData(
    raw: prepared.transactionHex,
    txid: prepared.txid,
    fee: _amount(prepared.feeZatoshis),
    recipients: [
      TxRecipient(
        address: prepared.encodedRecipient,
        amount: _amount(prepared.amountZatoshis),
        isChange: isChange,
        addressType: AddressType.zcashUnified,
      ),
    ],
    vExtraData: _preparedDigest(prepared),
  );

  Future<void> _broadcastTransparentShielding(
    ZcashPreparedTransparentShielding prepared,
    ZcashAccountSession session,
  ) async {
    final store = _transparentShieldingStore;
    if (store == null) {
      throw StateError('transparent shielding state is not initialized');
    }
    await store.update((state) {
      state.requireBroadcastable(prepared.prepared);
      state.markSubmitting(prepared.txid);
    });
    try {
      await session.submitTransactionHex(prepared.transactionHex);
      await store.update((state) {
        state.markAcknowledged(prepared.txid);
      });
    } on ZcashBroadcastRejectedException {
      await store.update((state) {
        state.releaseRejected(prepared.txid);
      });
      rethrow;
    } on Object {
      await store.update((state) {
        state.markIndeterminate(prepared.txid);
      });
      rethrow;
    }
  }

  Future<void> _releaseCurrentPrepared() async {
    final prepared = _preparedSend;
    if (prepared == null) return;
    if (prepared case ZcashPreparedTransparentShielding()) {
      final store = _transparentShieldingStore;
      if (store != null) {
        await store.update((state) {
          final matches = state.records.where(
            (record) =>
                record.txid.toLowerCase() == prepared.txid.toLowerCase(),
          );
          if (matches.length == 1 &&
              matches.single.broadcastState ==
                  ZcashShieldingBroadcastState.prepared) {
            state.releaseRejected(prepared.txid);
          }
        });
      }
      _preparedSend = null;
      return;
    }
    final store = _pendingSendStore;
    if (store != null) {
      await _releaseUnbroadcastPrepared(
        store: store,
        pending: await store.load(),
      );
    }
  }

  Future<void> _releaseUnbroadcastPrepared({
    required ZcashPendingSendStore store,
    required zcash.IronwoodPendingSendState pending,
  }) async {
    final prepared = _preparedSend;
    if (prepared == null) return;
    final records = pending.records.where(
      (record) => record.txid.toLowerCase() == prepared.txid.toLowerCase(),
    );
    if (records.length == 1 &&
        records.single.broadcastState ==
            zcash.IronwoodPendingBroadcastState.prepared) {
      pending.releaseRejected(prepared.txid);
      await store.save(pending);
    }
    _preparedSend = null;
  }

  ({String address, BigInt amount, Uint8List? memo}) _resolveStackPayment({
    required String address,
    required BigInt amount,
    required String? memo,
  }) {
    final stackMemo = memo == null || memo.isEmpty
        ? null
        : Uint8List.fromList(utf8.encode(memo));
    if (!address.toLowerCase().startsWith('zcash:')) {
      return (address: address, amount: amount, memo: stackMemo);
    }
    final request = zcash.parseZcashUri(address);
    if (request == null) throw ArgumentError('Invalid ZIP-321 payment request');
    if (request.payments.length != 1) {
      throw UnsupportedError(
        'Multi-recipient ZIP-321 requires backend multi-output reservations',
      );
    }
    final payment = request.payments.single;
    if (payment.amountZatoshis != null && payment.amountZatoshis != amount) {
      throw ArgumentError(
        'ZIP-321 amount conflicts with the Stack send amount',
      );
    }
    if (payment.memo != null &&
        stackMemo != null &&
        !_bytesEqual(payment.memo!, stackMemo)) {
      throw ArgumentError('ZIP-321 memo conflicts with the Stack send memo');
    }
    return (
      address: payment.address,
      amount: payment.amountZatoshis ?? amount,
      memo: payment.memo ?? stackMemo,
    );
  }

  Uint8List _preparedDigest(ZcashPreparedWalletSend prepared) =>
      Uint8List.fromList(
        sha256
            .convert(
              utf8.encode(
                '${prepared.txid}|${prepared.transactionHex}|'
                '${prepared.encodedRecipient}|${prepared.amountZatoshis}|'
                '${prepared.feeZatoshis}',
              ),
            )
            .bytes,
      );

  bool _matchesPrepared(TxData txData, ZcashPreparedWalletSend prepared) =>
      txData.txid == prepared.txid &&
      txData.raw == prepared.transactionHex &&
      txData.fee?.raw == BigInt.from(prepared.feeZatoshis) &&
      txData.recipients?.length == 1 &&
      txData.recipients!.single.address == prepared.encodedRecipient &&
      txData.recipients!.single.amount.raw ==
          BigInt.from(prepared.amountZatoshis) &&
      _bytesEqual(txData.vExtraData, _preparedDigest(prepared));

  List<Address> _receiverRows(zcash.UnifiedAddressSet derived) {
    final values = <(String, AddressType)>[
      (derived.ua, AddressType.zcashUnified),
      if (derived.saplingAddress case final address?)
        (address, AddressType.zcashSapling),
      if (derived.transparentAddress case final address?)
        (
          address,
          cryptoCurrency.getAddressType(address) ??
              (throw StateError(
                'Derived Zcash transparent receiver has no address type',
              )),
        ),
    ];
    return [
      for (final (value, type) in values)
        Address(
          walletId: walletId,
          value: value,
          publicKey: const [],
          derivationIndex: 0,
          derivationPath: null,
          type: type,
          subType: AddressSubType.receiving,
        ),
    ];
  }
}

class _ZcashSessionSyncDataSource implements ZcashSyncDataSource {
  const _ZcashSessionSyncDataSource(this.client);

  final ZcashLightwalletdSyncClient client;

  @override
  Future<String?> getBlockHash(int height) => client.getBlockHash(height);

  @override
  Future<zcash.ZcashLightwalletdScanSource> getBlockRange(int start, int end) =>
      client.getBlockRange(start, end);

  @override
  Future<int> getTipHeight() => client.getTipHeight();

  @override
  Future<zcash.TreeState> getTreeState(int height) =>
      client.getTreeState(height);
}

bool _bytesEqual(List<int>? left, List<int>? right) {
  if (identical(left, right)) return true;
  if (left == null || right == null || left.length != right.length) {
    return false;
  }
  for (var i = 0; i < left.length; i++) {
    if (left[i] != right[i]) return false;
  }
  return true;
}

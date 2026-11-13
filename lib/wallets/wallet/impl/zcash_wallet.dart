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
import '../intermediate/zcash_transparent_receiver_discovery.dart';
import '../intermediate/zcash_wallet_state.dart';
import '../intermediate/zcash_wallet_state_controller.dart';
import '../intermediate/zcash_zip318_migration.dart';
import '../intermediate/zcash_zip318_migration_store.dart';
import '../wallet_mixin_interfaces/recoverable_prepared_send_interface.dart';

typedef ZcashAccountSessionFactory = ZcashAccountSession Function(
  CryptoCurrencyNetwork network,
);

class ZcashWallet extends Bip39Wallet<Zcash>
    implements RecoverablePreparedSendWallet {
  ZcashWallet(CryptoCurrencyNetwork network) : super(Zcash(network));

  ZcashAccountSessionFactory _accountSessionFactory = (network) =>
      ZcashAccountSession(network: network);
  ZcashAccountSession? _accountSession;
  ZcashWalletStateController? _stateController;
  ZcashEncryptedWalletStateStore? _stateStore;
  ZcashPendingSendStore? _pendingSendStore;
  ZcashTransparentShieldingStore? _transparentShieldingStore;
  ZcashZip318MigrationStore? _zip318MigrationStore;
  ZcashScanExecutor? _scanExecutor;
  ZcashWalletSendService _sendService =
      const ZcashProductionWalletSendService();
  ZcashZip318MigrationService _zip318MigrationService =
      ZcashProductionZip318MigrationService();
  static final _zip318BroadcastSession = zcash.Zip318BroadcastSession();
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
  ZcashTransparentReceiverDiscovery? _transparentReceiverDiscovery;

  @override
  int get isarTransactionVersion => 2;

  @override
  bool get supportsMultiRecipient => true;

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

  void configureZip318MigrationService(ZcashZip318MigrationService service) {
    if (_stateController != null || _preparedSend != null) {
      throw StateError('The Zcash ZIP 318 service is already in use');
    }
    _zip318MigrationService = service;
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
    if (info.restoreHeight < 1 && isRestore != false) {
      throw StateError(
        'Restoring Zcash requires an explicit positive block height; '
        'a missing birthday must not skip wallet history',
      );
    }
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
    final transparentDiscovery = ZcashTransparentReceiverDiscovery(
      network: cryptoCurrency.nativeNetwork,
      viewingKeys: viewingKeys,
    );
    _transparentReceiverDiscovery = transparentDiscovery;
    _unifiedAddress = derived.ua;
    final transparentAddress = derived.transparentAddress;
    if (metadata.hasTransparent && transparentAddress == null) {
      throw StateError('Zcash account has no transparent UA receiver');
    }
    if (transparentAddress case final address?) {
      final externalViewingKey = viewingKeys.transparent.externalIvk;
      if (externalViewingKey == null || externalViewingKey.isEmpty) {
        throw StateError('Zcash account has no external transparent IVK');
      }
      final derivedAddress = zcash.deriveNativeTransparentAddressFromViewingKey(
        viewingKeyHex: externalViewingKey,
        network: cryptoCurrency.nativeNetwork,
        childIndex: derived.nextValidIndex,
        scope: zcash.ZcashTransparentKeyScope.external,
      );
      if (derivedAddress != address) {
        throw StateError(
          'Zcash UA transparent receiver does not match its viewing key',
        );
      }
      final defaultAddress = viewingKeys.transparent.defaultExternalAddress;
      final receivers = <String, zcash.ZcashTransparentReceiver>{
        for (final receiver in transparentDiscovery.initialReceivers())
          if (receiver.address != defaultAddress) receiver.address: receiver,
      };
      if (address != defaultAddress) {
        receivers[address] = zcash.ZcashTransparentReceiver(
          address: address,
          scope: zcash.ZcashTransparentReceiverScope.external,
          childIndex: derived.nextValidIndex,
        );
      }
      _additionalTransparentReceivers = receivers.values.toList();
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
      ZcashSessionReadiness? readiness;
      if (nodeService.getPrimaryNodeFor(currency: cryptoCurrency) != null) {
        readiness = await _replaceConfiguredNode();
      }
      if (info.restoreHeight < 1) {
        readiness ??= await _replaceConfiguredNode();
        if (readiness.tipHeight >= ZcashAccountSession.maximumBlockHeight) {
          throw StateError(
            'The Zcash lightwalletd tip cannot produce a bounded wallet '
            'birthday',
          );
        }
        await info.updateRestoreHeight(
          newRestoreHeight: readiness.tipHeight + 1,
          isar: mainDB.isar,
        );
      }
      if (readiness != null) {
        _validateBirthdayAgainst(readiness);
        await _initializeStateController(_requireAccountSession());
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
  Future<TxData> prepareSend({required TxData txData}) => _sendMutex.protect(
    () async {
      final recipients = txData.recipients;
      if (recipients == null || recipients.isEmpty) {
        throw ArgumentError('Zcash requires at least one recipient');
      }
      var total = BigInt.zero;
      final resolved = <({String address, BigInt amount, Uint8List? memo})>[];
      for (final requested in recipients) {
        if (requested.isChange ||
            requested.amount.fractionDigits != cryptoCurrency.fractionDigits ||
            requested.amount.raw <= BigInt.zero ||
            requested.amount.raw > BigInt.from(zcash.maxMoneyZatoshis)) {
          throw ArgumentError('Invalid Zcash recipient amount');
        }
        total += requested.amount.raw;
        if (total > BigInt.from(zcash.maxMoneyZatoshis)) {
          throw ArgumentError('Zcash recipient total exceeds MAX_MONEY');
        }
        resolved.add(
          _resolveStackPayment(
            address: requested.address,
            amount: requested.amount.raw,
            memo: recipients.length == 1 ? txData.memo : null,
            memoBytes: requested.memoBytes,
          ),
        );
      }
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
          recipient: resolved.first.address,
          amountZatoshis: resolved.first.amount.toInt(),
          memo: resolved.first.memo,
          payments: [
            for (final payment in resolved)
              ZcashSendPayment(
                recipient: payment.address,
                amountZatoshis: payment.amount.toInt(),
                memo: payment.memo,
              ),
          ],
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
      final outputs = _preparedPaymentOutputs(prepared);
      if (outputs.length != recipients.length) {
        throw StateError('Prepared Zcash output count changed unexpectedly');
      }
      return txData.copyWith(
        raw: prepared.transactionHex,
        txid: prepared.txid,
        fee: _amount(prepared.feeZatoshis),
        memo: txData.memo,
        recipients: [
          for (var index = 0; index < outputs.length; index++)
            recipients[index].copyWith(
              address: outputs[index].encodedRecipient,
              amount: _amount(outputs[index].amountZatoshis),
              memoBytes: outputs[index].memo,
            ),
        ],
        vExtraData: _preparedDigest(prepared),
      );
    },
  );

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

  /// Rehydrates the exact signed ordinary-send artifact and its ordered
  /// outputs after process restart. The durable reservation remains the
  /// authority; no transaction is rebuilt and no key material is persisted.
  @override
  Future<TxData?> recoverPreparedSend() => _sendMutex.protect(() async {
    if (_preparedSend != null) {
      throw StateError('another Zcash transaction is already prepared');
    }
    final stateStore = _stateStore;
    final pendingStore = _pendingSendStore;
    final session = _requireAccountSession();
    if (stateStore == null || pendingStore == null) {
      throw StateError('Zcash send state is not initialized');
    }
    final snapshot = await _requireStateController().refresh();
    final persisted = await stateStore.load();
    if (persisted == null) return null;
    final pending = await pendingStore.load();
    pending.recoverInterruptedSubmissions();
    await pendingStore.save(pending);
    final resumable = pending.records
        .where(
          (record) =>
              !record.isConfirmed &&
              !record.isExpiredAt(snapshot.chainHeight) &&
              (record.broadcastState ==
                      zcash.IronwoodPendingBroadcastState.prepared ||
                  record.broadcastState ==
                      zcash.IronwoodPendingBroadcastState.indeterminate),
        )
        .toList(growable: false);
    if (resumable.isEmpty) return null;
    if (resumable.length != 1) {
      throw StateError('multiple Zcash sends need reconciliation');
    }
    final record = resumable.single;
    final sourceNotes =
        record.sourcePool == zcash.ShieldedPendingSourcePool.ironwood
        ? persisted.syncState.ironwood.notes
        : persisted.syncState.sapling.notes;
    final notes = [
      for (final note in sourceNotes)
        if (note.nullifier != null &&
            record.selectedNullifiers.contains(note.nullifier))
          note,
    ];
    if (notes.length != record.selectedNullifiers.length) {
      throw StateError(
        'reserved Zcash inputs are missing from canonical wallet state',
      );
    }
    final artifact = ZcashRecoveredPreparedSend(
      record: record,
      notes: notes,
      sessionGeneration: session.generation,
    );
    _preparedSend = artifact;
    return _txDataForPrepared(artifact, isChange: false);
  });

  /// Prepares one due ZIP 318 Orchard-to-Ironwood migration through the same
  /// exact-artifact review and confirmation boundary as an ordinary send.
  Future<TxData> prepareOrchardMigration({
    required TxData txData,
    required zcash.Zip318ScheduledTransfer scheduledTransfer,
    required zcash.Zip318Parameters parameters,
    required zcash.Zip318ConsentChecklist consent,
  }) => _sendMutex.protect(() async {
    final recipients = txData.recipients;
    if (recipients == null || recipients.length != 1) {
      throw UnsupportedError('ZIP 318 requires exactly one migration output');
    }
    final requested = recipients.single;
    if (requested.isChange ||
        requested.amount.fractionDigits != cryptoCurrency.fractionDigits ||
        requested.amount.raw !=
            BigInt.from(scheduledTransfer.denominationZatoshis) ||
        txData.memo?.isNotEmpty == true) {
      throw ArgumentError('ZIP 318 review does not match its schedule');
    }
    final session = _requireAccountSession();
    final syncClient = session.syncClient;
    final stateStore = _stateStore;
    final migrationStore = _zip318MigrationStore;
    if (syncClient == null || stateStore == null || migrationStore == null) {
      throw StateError('ZIP 318 requires an initialized sync session');
    }
    final snapshot = await _requireStateController().refresh();
    final persisted = await stateStore.load();
    if (persisted == null ||
        persisted.observedChainHeight != snapshot.chainHeight) {
      throw StateError('Zcash sync state is unavailable or not current');
    }
    await _releaseCurrentPrepared();
    final pending = await migrationStore.load();
    final seed = zcash.nativeMnemonicToSeed(
      await getMnemonic(),
      passphrase: await getMnemonicPassphrase(),
    );
    final ufvk = _ufvk;
    if (ufvk == null) throw StateError('Zcash account identity is unavailable');
    final prepared = await _zip318MigrationService.prepare(
      ZcashZip318PreparationRequest(
        network: cryptoCurrency.network,
        sessionGeneration: session.generation,
        orchardNotes: persisted.syncState.orchard.notes,
        orchardSpends: persisted.syncState.orchard.spends,
        reservedNullifiers: pending.reservedNullifiersAt(snapshot.chainHeight),
        observedTipHeight: snapshot.chainHeight,
        scheduledTransfer: scheduledTransfer,
        recipientAddress: requested.address,
        ufvk: ufvk,
        seedHex: seed.seedHex,
        parameters: parameters,
        consent: consent,
        fetchTreeState: syncClient.getTreeState,
      ),
    );
    pending.addPrepared(prepared, createdHeight: snapshot.chainHeight);
    await migrationStore.save(pending);
    _preparedSend = prepared;
    return txData.copyWith(
      raw: prepared.transactionHex,
      txid: prepared.txid,
      fee: _amount(prepared.feeZatoshis),
      recipients: [
        requested.copyWith(
          address: prepared.encodedRecipient,
          amount: _amount(prepared.amountZatoshis),
        ),
      ],
      vExtraData: _preparedDigest(prepared),
    );
  });

  @override
  Future<TxData> confirmSend({
    required TxData txData,
  }) => _sendMutex.protect(() async {
    final prepared = _preparedSend;
    if (prepared == null || !_matchesPrepared(txData, prepared)) {
      throw StateError(
        'Zcash confirmation must use the exact prepared transaction artifact',
      );
    }
    final session = _requireAccountSession();
    _requirePreparedSession(prepared, session);
    // Revalidate expiry against a freshly synchronized tip. A prepared
    // artifact can cross its consensus expiry boundary while the review UI
    // is open or while a recovered send is waiting after restart.
    final chainHeight = (await _requireStateController().refresh()).chainHeight;
    // updateNode intentionally remains usable during a potentially long scan.
    // Recheck after that await, and again in each submit callback, so bytes
    // can never cross an endpoint-generation boundary.
    _requirePreparedSession(prepared, session);
    if (prepared case ZcashPreparedTransparentShielding()) {
      await _broadcastTransparentShielding(prepared, session);
      _preparedSend = null;
      return txData;
    }
    if (prepared case final ZcashPreparedZip318Migration migration) {
      final store = _zip318MigrationStore!;
      final pending = await store.load();
      try {
        await _zip318MigrationService.broadcast(
          prepared: migration,
          pending: pending,
          session: _zip318BroadcastSession,
          chainHeight: chainHeight,
          persist: () => store.save(pending),
          submit: (transactionHex) async {
            _requirePreparedSession(prepared, session);
            await session.submitTransactionHex(transactionHex);
            return migration.txid;
          },
        );
      } finally {
        await store.save(pending);
      }
    } else {
      final store = _pendingSendStore!;
      final pending = await store.load();
      try {
        await _sendService.broadcast(
          prepared: prepared,
          pendingSends: pending,
          chainHeight: chainHeight,
          persist: () => store.save(pending),
          submit: (transactionHex) {
            _requirePreparedSession(prepared, session);
            return session.submitTransactionHex(transactionHex);
          },
        );
      } finally {
        await store.save(pending);
      }
    }
    _preparedSend = null;
    return txData;
  });

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

        final persisted = await store.load();
        if (persisted != null) {
          final defaultAddress =
              _viewingKeys?.transparent.defaultExternalAddress;
          final retained = <String, zcash.ZcashTransparentReceiver>{
            for (final receiver in _additionalTransparentReceivers)
              receiver.address: receiver,
            for (final receiver in persisted.syncState.transparent.receivers)
              if (receiver.address != defaultAddress)
                receiver.address: receiver,
          };
          _additionalTransparentReceivers = retained.values.toList();
        }

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
      final transactions = mapper.transactions(
        snapshot.history,
        pendingSends: await _pendingSendStore?.load(),
      );
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
    try {
      final readiness = await _replaceConfiguredNode();
      _validateBirthdayAgainst(readiness);
      await _initializeStateController(_requireAccountSession());
    } catch (_) {
      await _closeAccountSession();
      rethrow;
    }
  }

  Future<ZcashSessionReadiness> _replaceConfiguredNode() async {
    final node = nodeService.getPrimaryNodeFor(currency: cryptoCurrency);
    if (node == null) {
      throw StateError(
        'Zcash requires an explicitly configured primary lightwalletd node',
      );
    }
    final session = _accountSession ??= _accountSessionFactory(
      cryptoCurrency.network,
    );
    final readiness = await session.replaceNode(node);
    _stateController = null;
    return readiness;
  }

  void _validateBirthdayAgainst(ZcashSessionReadiness readiness) {
    final birthdayHeight = info.restoreHeight;
    if (birthdayHeight < 1 ||
        birthdayHeight > ZcashAccountSession.maximumBlockHeight) {
      throw StateError(
        'Zcash restore height must be between 1 and '
        '${ZcashAccountSession.maximumBlockHeight}',
      );
    }
    if (birthdayHeight > readiness.tipHeight + 1) {
      throw StateError(
        'Zcash restore height $birthdayHeight is above the validated '
        'lightwalletd tip ${readiness.tipHeight}',
      );
    }
  }

  @override
  Future<void> updateTransactions() async {
    final snapshot = await _requireStateController().refresh();
    await _reconcileTransparentShielding();
    await mainDB.updateOrPutTransactionV2s(
      ZcashStackStateMapper(walletId: walletId).transactions(
        snapshot.history,
        pendingSends: await _pendingSendStore?.load(),
      ),
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
    _zip318MigrationStore = null;
    _scanExecutor = null;
    _preparedSend = null;
    final session = _accountSession;
    _accountSession = null;
    _legacyAccountFingerprint = null;
    _accountMetadata = null;
    _viewingKeys = null;
    _unifiedAddress = null;
    _additionalTransparentReceivers = const [];
    _transparentReceiverDiscovery = null;
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
      transparentDiscovery: _transparentReceiverDiscovery,
      transparentActivity: client is ZcashLightwalletdTransparentClient
          ? (addresses, startHeight, chainHeight) =>
                (client as ZcashLightwalletdTransparentClient)
                    .getTransparentAddressActivity(
                      addresses,
                      startHeight: startHeight,
                      chainHeight: chainHeight,
                    )
          : null,
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
    _zip318MigrationStore = ZcashEncryptedZip318MigrationStore(
      path: path.join(root.path, 'zcash', '$walletId.zip318'),
      walletId: walletId,
      network: network,
      accountFingerprint: fingerprint,
      secureStorage: secureStorageInterface,
    );
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
      for (final output in prepared.paymentOutputs)
        TxRecipient(
          address: output.encodedRecipient,
          amount: _amount(output.amountZatoshis),
          isChange: isChange,
          addressType:
              cryptoCurrency.getAddressType(output.encodedRecipient) ??
              AddressType.zcashUnified,
          memoBytes: output.memo,
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
      _requirePreparedSession(prepared, session);
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

  void _requirePreparedSession(
    ZcashPreparedWalletSend prepared,
    ZcashAccountSession session,
  ) {
    final active = _requireAccountSession();
    if (!identical(active, session) ||
        active.generation != prepared.sessionGeneration) {
      throw StateError(
        'The Zcash node changed after preparation; prepare again',
      );
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
    if (prepared case ZcashPreparedZip318Migration()) {
      final store = _zip318MigrationStore;
      if (store != null) {
        await _releaseUnbroadcastZip318(
          store: store,
          pending: await store.load(),
        );
      }
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

  Future<void> _releaseUnbroadcastZip318({
    required ZcashZip318MigrationStore store,
    required ZcashZip318PendingState pending,
  }) async {
    final prepared = _preparedSend;
    if (prepared is! ZcashPreparedZip318Migration) return;
    pending.releasePrepared(prepared.txid);
    await store.save(pending);
    _preparedSend = null;
  }

  ({String address, BigInt amount, Uint8List? memo}) _resolveStackPayment({
    required String address,
    required BigInt amount,
    required String? memo,
    Uint8List? memoBytes,
  }) {
    final stackMemo = memo == null || memo.isEmpty
        ? null
        : Uint8List.fromList(utf8.encode(memo));
    if (memoBytes != null &&
        stackMemo != null &&
        !_bytesEqual(memoBytes, stackMemo)) {
      throw ArgumentError('Recipient memo conflicts with the Stack send memo');
    }
    final suppliedMemo = memoBytes ?? stackMemo;
    if (suppliedMemo != null && suppliedMemo.length > 512) {
      throw ArgumentError('Zcash memo exceeds 512 bytes');
    }
    if (!address.toLowerCase().startsWith('zcash:')) {
      return (address: address, amount: amount, memo: suppliedMemo);
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
        suppliedMemo != null &&
        !_bytesEqual(payment.memo!, suppliedMemo)) {
      throw ArgumentError('ZIP-321 memo conflicts with the Stack send memo');
    }
    return (
      address: payment.address,
      amount: payment.amountZatoshis ?? amount,
      memo: payment.memo ?? suppliedMemo,
    );
  }

  List<({String encodedRecipient, int amountZatoshis, Uint8List? memo})>
  _preparedPaymentOutputs(ZcashPreparedWalletSend prepared) =>
      prepared.paymentOutputs;

  Uint8List _preparedDigest(ZcashPreparedWalletSend prepared) {
    final outputCommitment = _preparedPaymentOutputs(prepared)
        .map(
          (output) =>
              '${output.encodedRecipient}:${output.amountZatoshis}:'
              '${output.memo == null ? '' : base64Url.encode(output.memo!)}',
        )
        .join('|');
    return Uint8List.fromList(
      sha256
          .convert(
            utf8.encode(
              '${prepared.txid}|${prepared.transactionHex}|'
              '$outputCommitment|'
              '${prepared.feeZatoshis}',
            ),
          )
          .bytes,
    );
  }

  bool _matchesPrepared(TxData txData, ZcashPreparedWalletSend prepared) {
    final recipients = txData.recipients;
    final outputs = _preparedPaymentOutputs(prepared);
    if (txData.txid != prepared.txid ||
        txData.raw != prepared.transactionHex ||
        txData.fee?.raw != BigInt.from(prepared.feeZatoshis) ||
        recipients == null ||
        recipients.length != outputs.length ||
        !_bytesEqual(txData.vExtraData, _preparedDigest(prepared))) {
      return false;
    }
    for (var index = 0; index < outputs.length; index++) {
      if (recipients[index].address != outputs[index].encodedRecipient ||
          recipients[index].amount.raw !=
              BigInt.from(outputs[index].amountZatoshis) ||
          !_bytesEqual(recipients[index].memoBytes, outputs[index].memo)) {
        return false;
      }
    }
    return true;
  }

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

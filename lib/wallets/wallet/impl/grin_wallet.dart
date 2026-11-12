import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:event_bus/event_bus.dart';
import 'package:grin/grin.dart';
import 'package:isar_community/isar.dart';
import 'package:meta/meta.dart';
import 'package:mutex/mutex.dart';
import 'package:path/path.dart' as p;
import 'package:stack_wallet_backup/generate_password.dart';

import '../../../app_config.dart';
import '../../../exceptions/wallet/node_tor_mismatch_config_exception.dart';
import '../../../models/balance.dart';
import '../../../models/isar/models/blockchain_data/address.dart';
import '../../../models/isar/models/blockchain_data/transaction.dart';
import '../../../models/isar/models/blockchain_data/v2/transaction_v2.dart';
import '../../../models/node_model.dart';
import '../../../models/paymint/fee_object_model.dart';
import '../../../models/slatepack_models.dart';
import '../../../services/event_bus/events/global/blocks_remaining_event.dart';
import '../../../services/event_bus/events/global/node_connection_status_changed_event.dart';
import '../../../services/event_bus/events/global/refresh_percent_changed_event.dart';
import '../../../services/event_bus/events/global/tor_connection_status_changed_event.dart';
import '../../../services/event_bus/events/global/tor_status_changed_event.dart';
import '../../../services/event_bus/events/global/wallet_sync_status_changed_event.dart';
import '../../../services/event_bus/global_event_bus.dart';
import '../../../services/tor_service.dart';
import '../../../utilities/amount/amount.dart';
import '../../../utilities/enums/slatepack_method.dart';
import '../../../utilities/flutter_secure_storage_interface.dart';
import '../../../utilities/logger.dart';
import '../../../utilities/owner_only_directory.dart';
import '../../../utilities/stack_file_system.dart';
import '../../../utilities/tor_plain_net_option_enum.dart';
import '../../../wl_gen/interfaces/libgrin_interface.dart';
import '../../crypto_currency/crypto_currency.dart';
import '../../models/tx_data.dart';
import '../intermediate/bip39_wallet.dart';
import '../supporting/grin/grin_errors.dart';
import '../supporting/grin/grin_node_url.dart';
import '../supporting/grin/grin_scan_pause_observer.dart';
import '../supporting/grin/grin_transport.dart';
import '../supporting/grin/grin_tx_mapping.dart';
import '../supporting/grin_wallet_info_extension.dart';
import '../wallet_mixin_interfaces/slatepack_interface.dart';

/// The Stack balance for a Grin balance.
///
/// libwallet leaves locked outputs out of its total, so they are not
/// counted here either.
Balance grinBalanceToStack(GrinBalance balance, int fractionDigits) {
  Amount amount(BigInt raw) =>
      Amount(rawValue: raw, fractionDigits: fractionDigits);
  final pending =
      balance.amountAwaitingConfirmation +
      balance.amountImmature +
      balance.amountAwaitingFinalization;
  return Balance(
    total: amount(balance.amountCurrentlySpendable + pending),
    spendable: amount(balance.amountCurrentlySpendable),
    blockedTotal: amount(BigInt.zero),
    pendingSpendable: amount(pending),
  );
}

typedef _AppliedNetwork = ({
  String nodeUrl,
  String? apiSecret,
  GrinTransport transport,
});

class GrinWallet extends Bip39Wallet<Grin> with SlatepackInterface<Grin> {
  GrinWallet(
    CryptoCurrencyNetwork network, {
    GrinWalletBackend? backend,
    TorService? torService,
    EventBus? eventBus,
  }) : _backendOverride = backend,
       _torServiceOverride = torService,
       _eventBusOverride = eventBus,
       super(Grin(network, addressBackend: backend));

  // ========== Static =========================================================

  /// The live instance for each wallet id, registered or not. A restore or a
  /// new wallet is not in [Wallets] yet, and delete must still reach it.
  static final Map<String, GrinWallet> _owners = {};

  /// Serializes open, create, close and delete per wallet id.
  static final Map<String, Mutex> _dirLocks = {};
  static Mutex _dirLock(String walletId) =>
      _dirLocks.putIfAbsent(walletId, Mutex.new);

  /// Secure storage key of the generated seed file password.
  static String passwordKey(String walletId) =>
      "${walletId}_grinWalletPassword";

  /// Blocks until an unfinished send or invoice payment expires, about a day.
  static const int slatepackTtlBlocks = 1440;

  static const _torConnectWait = Duration(seconds: 60);

  static void _checkWalletId(String walletId) {
    if (walletId.isEmpty ||
        walletId.contains("/") ||
        walletId.contains(r"\") ||
        walletId.contains("..")) {
      throw GrinWalletException("Invalid wallet id.");
    }
  }

  /// The absolute directory of [walletId]'s Grin wallet. Nothing is created.
  static Future<String> walletDirPath(String walletId) async {
    _checkWalletId(walletId);
    final root = await StackFileSystem.applicationGrinDirectoryPath();
    final dir = p.normalize(p.join(root, walletId));
    if (!p.isAbsolute(dir)) {
      throw GrinWalletException("The Grin wallet directory is not absolute.");
    }
    return dir;
  }

  /// Deletes the native wallet of [walletId] and its password.
  ///
  /// Closes the live instance first, registered or not. Returns false when
  /// the library reports the directory busy; nothing is deleted then and the
  /// caller should try again later.
  static Future<bool> deleteWalletFiles({
    required String walletId,
    required SecureStorageInterface secureStore,
    GrinWalletBackend? backend,
  }) {
    return _dirLock(walletId).protect(() async {
      final owner = _owners[walletId];
      if (owner != null) {
        owner.shouldAutoSync = false;
        await owner._closeUnlocked();
      }

      final dir = await walletDirPath(walletId);
      if (await Directory(dir).exists()) {
        final lib = backend ?? owner?.backend ?? libGrin.backend;
        try {
          await lib.delete(walletDir: dir);
        } on GrinWalletBusyException {
          Logging.instance.w("Grin delete of $walletId deferred: busy");
          return false;
        } catch (e) {
          throw _failStatic("delete", e);
        }
        try {
          // Only an empty directory goes; never recursive.
          await Directory(dir).delete();
        } on FileSystemException {
          Logging.instance.w("Grin wallet directory of $walletId not empty");
        }
      }

      await secureStore.delete(key: passwordKey(walletId));
      return true;
    });
  }

  /// Retries the native part of deletes that were busy. [walletIds] are the
  /// ids deleted in earlier runs; returns the ones still not deleted.
  static Future<List<String>> retryDeferredDeletes({
    required Iterable<String> walletIds,
    required SecureStorageInterface secureStore,
    GrinWalletBackend? backend,
  }) async {
    final remaining = <String>[];
    for (final walletId in walletIds) {
      final String dir;
      try {
        dir = await walletDirPath(walletId);
      } catch (_) {
        continue;
      }
      try {
        if (!await Directory(dir).exists()) continue;
        final deleted = await deleteWalletFiles(
          walletId: walletId,
          secureStore: secureStore,
          backend: backend,
        );
        if (!deleted) remaining.add(walletId);
      } catch (e) {
        Logging.instance.w(
          "Grin deferred delete of $walletId failed: ${describeGrinError(e)}",
        );
        remaining.add(walletId);
      }
    }
    return remaining;
  }

  static Exception _failStatic(String operation, Object error) {
    Logging.instance.w("Grin $operation failed: ${describeGrinError(error)}");
    return sanitizeGrinError(error);
  }

  // ========== Fields =========================================================

  final GrinWalletBackend? _backendOverride;
  final TorService? _torServiceOverride;
  final EventBus? _eventBusOverride;

  GrinWalletBackend get backend => _backendOverride ?? libGrin.backend;
  EventBus get _bus => _eventBusOverride ?? GlobalEventBus.instance;
  TorService get _tor => _torServiceOverride ?? TorService.sharedInstance;

  GrinWalletApi? _api;
  Future<void>? _initializing;
  Future<void>? _closing;
  Future<void>? _scanJob;

  /// Set by [_stopScanJob]. A job that has not handed its scan to the
  /// library yet ends without starting it.
  bool _scanStopRequested = false;
  bool _exited = false;

  _AppliedNetwork? _applied;
  final _transportMutex = Mutex();
  Completer<void>? _torConnecting;
  StreamSubscription<TorConnectionStatusChangedEvent>? _torStatusSub;
  StreamSubscription<TorPreferenceChangedEvent>? _torPrefSub;

  /// The last node refresh could not reach the node.
  bool _offline = false;

  /// Armored Slatepacks by txid from the last history read.
  Map<String, String> _slatepacks = const {};

  double highestPercent = 0;

  GrinScanPauseObserver? _pauseObserver;

  /// Whether going to the background cancels a running scan. Mobile only.
  @visibleForTesting
  bool get cancelScanOnPause => Platform.isAndroid || Platform.isIOS;

  /// Cancels a running scan; it resumes on the next refresh.
  void cancelRunningScan() {
    if (_scanJob == null) return;
    _api?.cancelScan();
  }

  /// Whether the Tor feature is compiled in.
  @visibleForTesting
  bool get torFeatureEnabled => AppConfig.hasFeature(AppFeature.tor);

  /// Whether a native wallet is open.
  bool get isOpen => _api != null;

  bool get _scanPending => info.grinData?.pendingScanFrom != null;

  /// Whether a scan has to finish before node refreshes, fee estimates,
  /// cancels and sends.
  bool get isScanPending => _scanPending;

  // ========== Lifecycle ======================================================

  @override
  int get isarTransactionVersion => 2;

  @override
  FilterOperation? get changeAddressFilterOperation =>
      FilterGroup.and(standardChangeAddressFilters);

  @override
  FilterOperation? get receivingAddressFilterOperation =>
      FilterGroup.and(standardReceivingAddressFilters);

  /// Opens the native wallet, creating it the first time.
  ///
  /// Safe to call again on the same instance. Startup calls it for every
  /// wallet, so it never starts a scan. With [isRestore] nothing is opened:
  /// [recover] creates the wallet.
  @override
  Future<void> init({bool? isRestore}) async {
    final closing = _closing;
    if (closing != null) await closing;

    if (isRestore != true) {
      final pending = _initializing;
      if (pending != null) {
        await pending;
      } else if (_api == null) {
        final opening = _open();
        _initializing = opening;
        try {
          await opening;
        } finally {
          if (identical(_initializing, opening)) _initializing = null;
        }
      }
    }

    await super.init();
  }

  Future<void> _open() {
    return _dirLock(walletId).protect(() async {
      if (_api != null) return;
      _claimOwnership();
      try {
        final dir = await _ensureWalletDir();
        final existing = info.grinData;
        final stored = await secureStorageInterface.read(
          key: passwordKey(walletId),
        );

        GrinWalletApi api;
        if (stored != null) {
          try {
            api = await backend.open(
              config: _buildConfig(dir),
              password: stored,
            );
          } on GrinWalletNotFoundException {
            if (existing == null) {
              api = await _createNew(dir, stored);
            } else if (existing.pendingScanFrom != null) {
              // A restore or rescan stopped before the wallet was created.
              // The scan it still owes rebuilds everything.
              api = await _recreate(dir);
            } else {
              throw GrinWalletException(
                "The Grin wallet files are missing. Restore this wallet from "
                "its recovery phrase.",
              );
            }
          }
        } else {
          if (existing != null) {
            throw GrinWalletException(
              "The Grin wallet password is missing. Restore this wallet from "
              "its recovery phrase.",
            );
          }
          final password = generatePassword();
          await secureStorageInterface.write(
            key: passwordKey(walletId),
            value: password,
          );
          api = await _createNew(dir, password);
        }
        _api = api;
      } catch (e) {
        await _releaseOwnership();
        throw _fail("open", e);
      }
    });
  }

  /// A wallet Stack just made: its first refresh must not scan from genesis.
  Future<GrinWalletApi> _createNew(String dir, String password) async {
    final api = await _createClearingLeftovers(
      dir: dir,
      mnemonic: await getMnemonic(),
      password: password,
      isNewWallet: true,
    );
    // A couple of days back, so a backup restored later cannot miss funds.
    final creationHeight = cryptoCurrency.heightFromDate(
      DateTime.now().subtract(const Duration(days: 2)),
    );
    await info.updateGrinData(
      grinData: GrinWalletData(creationHeight: creationHeight),
      isar: mainDB.isar,
    );
    await info.updateRestoreHeight(
      newRestoreHeight: creationHeight,
      isar: mainDB.isar,
    );
    return api;
  }

  void _claimOwnership() {
    final owner = _owners[walletId];
    if (owner != null && !identical(owner, this) && owner._isLive) {
      throw GrinWalletException(
        "This Grin wallet is already open. Close it and try again.",
      );
    }
    _owners[walletId] = this;
    _exited = false;
    _subscribeTor();
    if (cancelScanOnPause) {
      _pauseObserver ??= GrinScanPauseObserver(
        cancelScan: cancelRunningScan,
        resumeScan: () => unawaited(_resumeAfterPause()),
      );
    }
  }

  bool get _isLive => _api != null || _scanJob != null;

  Future<void> _releaseOwnership() async {
    if (identical(_owners[walletId], this)) _owners.remove(walletId);
    _pauseObserver?.dispose();
    _pauseObserver = null;
    await _cancelTorSubscriptions();
  }

  Future<String> _ensureWalletDir() async {
    await StackFileSystem.applicationGrinDirectory();
    final dir = await walletDirPath(walletId);
    final link = await FileSystemEntity.isLink(dir);
    if (link) {
      throw GrinWalletException("The Grin wallet directory is a link.");
    }
    await createOwnerOnlyDirectory(dir);
    return dir;
  }

  GrinWalletConfig _buildConfig(String dir) {
    if (!p.isAbsolute(dir)) {
      throw GrinWalletException("The Grin wallet directory is not absolute.");
    }
    final network = _resolveNetwork();
    _applied = network;
    final transport = network.transport;
    return GrinWalletConfig(
      walletDir: dir,
      network: cryptoCurrency.grinNetwork,
      nodeUrl: network.nodeUrl,
      nodeApiSecret: network.apiSecret,
      socksProxy: transport is GrinProxy ? transport.address : null,
      networkEnabled: transport is GrinDirect || transport is GrinProxy,
    );
  }

  /// Closes the native wallet. A later [init] opens it again; nothing else
  /// does.
  @override
  Future<void> exit() async {
    final closing = _closing ??= _dirLock(walletId).protect(_closeUnlocked);
    try {
      await closing;
    } finally {
      if (identical(_closing, closing)) _closing = null;
    }
    await super.exit();
  }

  Future<void> _closeUnlocked() async {
    _exited = true;
    await _releaseOwnership();
    final api = _api;
    _api = null;
    _applied = null;
    _slatepacks = const {};
    _releaseTorWaiters();
    if (api == null) return;
    try {
      api.cancelScan();
      await api.close();
    } catch (e) {
      Logging.instance.w("Grin close failed: ${describeGrinError(e)}");
      // An open handle keeps the directory busy until the app restarts, so
      // try once more.
      try {
        await api.close();
      } catch (e) {
        Logging.instance.w("Grin close failed again: ${describeGrinError(e)}");
      }
    }
  }

  // ========== Recovery and scanning ==========================================

  @override
  Future<void> recover({required bool isRescan}) async {
    try {
      if (isRescan) {
        await _rescan();
      } else {
        await _restore();
      }
    } catch (e) {
      throw _fail(isRescan ? "rescan" : "restore", e);
    }
    unawaited(_runScanJob());
  }

  /// A new wallet id from a mnemonic: create, then scan from the restore
  /// height.
  Future<void> _restore() async {
    await refreshMutex.protect(() async {
      await _dirLock(walletId).protect(() async {
        if (_api != null) {
          throw GrinWalletException("This Grin wallet is already open.");
        }
        _claimOwnership();
        try {
          final dir = await _ensureWalletDir();
          // Saved before the wallet exists. If anything from here on is
          // interrupted, the next start still knows a scan is owed; a
          // wallet created without that would be scanned from the first
          // block by its first refresh.
          final height = info.restoreHeight;
          await info.updateGrinData(
            grinData: GrinWalletData(
              creationHeight: height,
              pendingScanFrom: height,
            ),
            isar: mainDB.isar,
          );
          _api = await _createFromMnemonic(dir);
        } catch (e) {
          await _releaseOwnership();
          rethrow;
        }
      });
      await _storeAddress();
      highestPercent = 0;
    });
  }

  /// Keeps the history and scans again from the restore height. Creates the
  /// wallet from the mnemonic first if its files are missing.
  Future<void> _rescan() async {
    await _stopScanJob();

    await refreshMutex.protect(() async {
      // First, so a rescan that fails or is interrupted below is still owed.
      await _markScanFromRestoreHeight();
      if (_api == null) {
        final closing = _closing;
        if (closing != null) await closing;
        await _dirLock(walletId).protect(() async {
          if (_api != null) return;
          _claimOwnership();
          try {
            final dir = await _ensureWalletDir();
            final stored = await secureStorageInterface.read(
              key: passwordKey(walletId),
            );
            if (stored != null) {
              try {
                _api = await backend.open(
                  config: _buildConfig(dir),
                  password: stored,
                );
                return;
              } on GrinWalletNotFoundException {
                // Rebuilt from the mnemonic below.
              }
            }
            _api = await _recreate(dir);
          } catch (e) {
            await _releaseOwnership();
            rethrow;
          }
        });
        await _storeAddress();
      }
      highestPercent = 0;
    });
  }

  /// Cancels the running scan job, if any, and waits for it to end.
  ///
  /// The library can only cancel a scan it has been given. A job that is
  /// still waiting for its turn or for the network has not called it yet,
  /// so the request is also kept for the job to see.
  Future<void> _stopScanJob() async {
    final running = _scanJob;
    if (running == null) return;
    _scanStopRequested = true;
    _api?.cancelScan();
    await running;
  }

  Future<void> _markScanFromRestoreHeight() async {
    final height = info.restoreHeight;
    await info.updateGrinData(
      grinData: (info.grinData ?? GrinWalletData(creationHeight: height))
          .withPendingScanFrom(height),
      isar: mainDB.isar,
    );
  }

  /// Builds the native wallet again from the mnemonic when its files are
  /// gone. The new wallet numbers its log from zero, so the stored history,
  /// which refers to the old log, is dropped; the scan from the restore
  /// height finds the funds again.
  Future<GrinWalletApi> _recreate(String dir) async {
    await _markScanFromRestoreHeight();
    final api = await _createFromMnemonic(dir);
    _slatepacks = const {};
    await mainDB.isar.writeTxn(() async {
      await mainDB.isar.transactionV2s
          .where()
          .walletIdEqualTo(walletId)
          .deleteAll();
    });
    return api;
  }

  /// Writes the password (reusing a stored one), then creates the wallet
  /// from the stored mnemonic. Leftover data of an interrupted create or
  /// delete is cleared once.
  Future<GrinWalletApi> _createFromMnemonic(String dir) async {
    var password = await secureStorageInterface.read(
      key: passwordKey(walletId),
    );
    if (password == null) {
      password = generatePassword();
      await secureStorageInterface.write(
        key: passwordKey(walletId),
        value: password,
      );
    }
    return _createClearingLeftovers(
      dir: dir,
      mnemonic: await getMnemonic(),
      password: password,
      isNewWallet: false,
    );
  }

  /// Creates the native wallet. Data left by an interrupted create or
  /// delete, which holds no seed, is cleared once and the create repeated.
  Future<GrinWalletApi> _createClearingLeftovers({
    required String dir,
    required String mnemonic,
    required String password,
    required bool isNewWallet,
  }) async {
    Future<GrinWalletApi> create() => backend.create(
      config: _buildConfig(dir),
      mnemonic: mnemonic,
      password: password,
      isNewWallet: isNewWallet,
    );
    try {
      return await create();
    } on GrinWalletExistsException catch (e) {
      if (e.details?["reason"] != "leftover_wallet_data") rethrow;
      await backend.delete(walletDir: dir);
      return await create();
    }
  }

  Future<void> _setPendingScanFrom(int? height) async {
    try {
      final current = info.grinData;
      await info.updateGrinData(
        grinData: (current ?? GrinWalletData(creationHeight: height ?? 0))
            .withPendingScanFrom(height),
        isar: mainDB.isar,
      );
    } catch (e) {
      // The wallet may be gone after a delete.
      Logging.instance.w("Grin scan state not saved: ${describeGrinError(e)}");
    }
  }

  Future<void> _runScanJob() {
    if (_pauseObserver?.isPaused ?? false) return Future<void>.value();
    final running = _scanJob;
    if (running != null) return running;
    late final Future<void> job;
    _scanStopRequested = false;
    job = _scan().whenComplete(() {
      if (identical(_scanJob, job)) _scanJob = null;
      if (!_exited) ensurePeriodicRefreshTimer();
    });
    _scanJob = job;
    return job;
  }

  Future<void> _scan() async {
    var succeeded = false;
    await refreshMutex.protect(() async {
      final api = _api;
      final from = info.grinData?.pendingScanFrom;
      if (api == null || _exited || from == null) return;

      _fireSyncStatus(WalletSyncStatus.syncing);
      final timer = Timer.periodic(
        const Duration(seconds: 1),
        (_) => _reportScanProgress(api),
      );
      try {
        await _requireNetwork();
        // Stopped before it started: nothing was scanned.
        if (_scanStopRequested) return;
        if (_pauseObserver?.isPaused ?? false) return;
        await api.scan(startHeight: from);
        await _setPendingScanFrom(null);
        succeeded = true;
      } on GrinCancelledException catch (e) {
        await _saveScanProgress(e, from);
      } catch (e) {
        // The batches before the failure are saved, so a scan over a poor
        // connection still gets further each time.
        if (e is GrinException) await _saveScanProgress(e, from);
        Logging.instance.w("Grin scan failed: ${describeGrinError(e)}");
        _fireSyncStatus(WalletSyncStatus.unableToSync);
      } finally {
        timer.cancel();
      }
    });
    if (succeeded && !_exited) {
      highestPercent = 1;
      await refresh();
    }
  }

  Future<void> _resumeAfterPause() async {
    final running = _scanJob;
    if (running != null) await running;
    if (!_exited && _api != null && _scanPending) await refresh();
  }

  /// Moves the resume height past what the ended scan says it saved.
  ///
  /// An error without a height (a scan cancelled before it started, or one
  /// that failed before it read the chain tip) saved nothing, and the
  /// resume height stays. The wallet's last scanned height is no stand-in:
  /// a refresh moves it to the tip, which would end a rescan early.
  Future<void> _saveScanProgress(GrinException ended, int from) async {
    final scanned = ended.scannedHeight;
    if (scanned == null || scanned < from) return;
    await _setPendingScanFrom(scanned + 1);
  }

  void _reportScanProgress(GrinWalletApi api) {
    try {
      final progress = api.scanProgress();
      if (!progress.isScanning || progress.tipHeight <= 0) return;
      final percent = (progress.progressPct / 100).clamp(0.0, 1.0);
      highestPercent = math.max(highestPercent, percent);
      if (doNotFireRefreshEvents) return;
      _bus.fire(RefreshPercentChangedEvent(highestPercent, walletId));
      _bus.fire(
        BlocksRemainingEvent(
          math.max(progress.tipHeight - progress.scannedHeight, 0),
          walletId,
        ),
      );
    } catch (_) {
      // Closed under us; the scan ends with it.
    }
  }

  @override
  double get restoreProgress => highestPercent;

  void _fireSyncStatus(WalletSyncStatus status) {
    if (doNotFireRefreshEvents) return;
    _bus.fire(WalletSyncStatusChangedEvent(status, walletId, cryptoCurrency));
  }

  void _fireDisconnected() {
    if (doNotFireRefreshEvents) return;
    _bus.fire(
      NodeConnectionStatusChangedEvent(
        NodeConnectionStatus.disconnected,
        walletId,
        cryptoCurrency,
      ),
    );
    _fireSyncStatus(WalletSyncStatus.unableToSync);
  }

  /// Starts the pending scan if there is one, otherwise a normal refresh.
  /// A scan is not awaited: it can take hours, and startup awaits refresh.
  @override
  Future<void> refresh() async {
    if (_api == null || _exited) return;
    if (_scanPending) {
      unawaited(_runScanJob());
      return;
    }
    return super.refresh();
  }

  // ========== Transport ======================================================

  NodeModel get _node => getCurrentNode();

  GrinTransport _resolveTransport(NodeModel node) {
    final torFeature = torFeatureEnabled;
    return resolveGrinTransport(
      torFeature: torFeature,
      useTor: prefs.useTor,
      torStatus: torFeature ? _tor.status : TorConnectionStatus.disconnected,
      killSwitch: prefs.torKillSwitch,
      nodeNetOption: TorPlainNetworkOption.fromNodeData(
        node.torEnabled,
        node.clearnetEnabled,
      ),
      nodeIsOnion: isOnionHost(node.host),
      proxyAddress: () => grinProxyAddress(_tor),
    );
  }

  _AppliedNetwork _resolveNetwork() {
    final node = _node;
    var transport = _resolveTransport(node);
    String url;
    try {
      url = grinNodeUrl(host: node.host, port: node.port, useSSL: node.useSSL);
    } on GrinNodeUrlException {
      final fallback = cryptoCurrency.defaultNode(isPrimary: true);
      url = grinNodeUrl(
        host: fallback.host,
        port: fallback.port,
        useSSL: fallback.useSSL,
      );
      transport = const GrinBlocked(GrinBlockedReason.invalidNode);
    }
    return (nodeUrl: url, apiSecret: node.nodeApiSecret, transport: transport);
  }

  void _subscribeTor() {
    _torStatusSub ??= _bus.on<TorConnectionStatusChangedEvent>().listen((
      event,
    ) {
      switch (event.newStatus) {
        case TorConnectionStatus.connecting:
          _torConnecting ??= Completer<void>();
        case TorConnectionStatus.connected:
        case TorConnectionStatus.disconnected:
          _releaseTorWaiters();
          unawaited(_applyTransport());
      }
    });
    _torPrefSub ??= _bus.on<TorPreferenceChangedEvent>().listen(
      (_) => unawaited(_applyTransport()),
    );
  }

  void _releaseTorWaiters() {
    final waiter = _torConnecting;
    _torConnecting = null;
    if (waiter != null && !waiter.isCompleted) waiter.complete();
  }

  Future<void> _cancelTorSubscriptions() async {
    final status = _torStatusSub;
    final pref = _torPrefSub;
    _torStatusSub = null;
    _torPrefSub = null;
    await status?.cancel();
    await pref?.cancel();
  }

  /// Hands the current transport to the library when it changed.
  ///
  /// Read at apply time, never from the event, because Tor events arrive
  /// before the preference they belong to. A running scan is cancelled first
  /// so the change does not wait a whole batch; it resumes on the next
  /// refresh.
  Future<void> _applyTransport({bool refreshAfter = true}) async {
    Future<void>? cancelledScan;
    final changed = await _transportMutex.protect(() async {
      final api = _api;
      if (api == null || _exited) return false;
      final network = _resolveNetwork();
      final transport = network.transport;
      if (transport is GrinHold) return false;
      if (network == _applied) return false;

      if (_scanJob != null) {
        cancelledScan = _scanJob;
        api.cancelScan();
      }
      await api.updateNetwork(
        nodeUrl: network.nodeUrl,
        apiSecret: network.apiSecret,
        socksProxy: transport is GrinProxy ? transport.address : null,
        networkEnabled: transport is! GrinBlocked,
      );
      _applied = network;
      return true;
    });
    if (!changed) return;

    if (_applied?.transport is GrinBlocked) {
      _fireDisconnected();
    } else if (refreshAfter && shouldAutoSync) {
      // The next scan needs the resume height saved by the finishing job.
      // Calls from that job use refreshAfter: false.
      if (cancelledScan != null) await cancelledScan;
      unawaited(refresh());
    }
  }

  /// The transport for a node call, after waiting out a Tor connect. Throws
  /// when the network is blocked.
  Future<GrinTransport> _usableTransport() async {
    var transport = _resolveNetwork().transport;
    if (transport is GrinHold) {
      final waiter = _torConnecting ??= Completer<void>();
      await waiter.future.timeout(_torConnectWait, onTimeout: () {});
      transport = _resolveNetwork().transport;
    }
    return switch (transport) {
      GrinHold() => throw GrinWalletException("Tor is still connecting."),
      GrinBlocked(:final reason) => throw _blockedException(reason),
      GrinDirect() || GrinProxy() => transport,
    };
  }

  Exception _blockedException(GrinBlockedReason reason) => switch (reason) {
    GrinBlockedReason.torOnlyNodeTorOff => NodeTorMismatchConfigException(
      message: "TOR off but node set to TOR only",
    ),
    GrinBlockedReason.clearnetNodeTorOn => NodeTorMismatchConfigException(
      message: "TOR enabled but node set to clearnet only",
    ),
    GrinBlockedReason.torDown => GrinWalletException("Tor is not connected."),
    GrinBlockedReason.invalidNode => GrinWalletException(
      "The Grin node address is not valid.",
    ),
  };

  /// The open wallet with the current transport applied, for a call that
  /// reaches the node.
  Future<GrinWalletApi> _requireNetwork() async {
    _requireApi();
    await _usableTransport();
    await _applyTransport(refreshAfter: false);
    final transport = _applied?.transport;
    if (transport is GrinBlocked) throw _blockedException(transport.reason);
    return _requireApi();
  }

  GrinWalletApi _requireApi() {
    final api = _api;
    if (api == null || _exited) {
      throw GrinWalletException("The Grin wallet is not open.");
    }
    return api;
  }

  void _refuseWhileScanning() {
    if (_scanPending) {
      throw GrinWalletException(
        "Wait for the Grin wallet to finish scanning and try again.",
      );
    }
  }

  /// [message] replaces the fixed text for a library error and keeps its
  /// type, code and slate id.
  Exception _fail(String operation, Object error, {String? message}) {
    final ex = _failStatic(operation, error);
    if (message == null || ex is! GrinWalletException) return ex;
    return GrinWalletException(
      message,
      type: ex.type,
      code: ex.code,
      slateId: ex.slateId,
    );
  }

  // ========== Sync ===========================================================

  @override
  Future<void> updateNode() async {
    if (_api == null || _exited) return;
    try {
      await _applyTransport();
    } catch (e) {
      throw _fail("updateNode", e);
    }
  }

  @override
  Future<void> updateChainHeight() async {
    if (_exited) return;
    try {
      final transport = await _usableTransport();
      final network = _resolveNetwork();
      final nodeInfo = await backend.testNodeConnection(
        nodeUrl: network.nodeUrl,
        apiSecret: network.apiSecret,
        socksProxy: transport is GrinProxy ? transport.address : null,
      );
      await info.updateCachedChainHeight(
        newHeight: nodeInfo.height,
        isar: mainDB.isar,
      );
    } catch (e) {
      throw _fail("updateChainHeight", e);
    }
  }

  @override
  Future<bool> pingCheck() async {
    try {
      final network = _resolveNetwork();
      final transport = network.transport;
      if (transport is! GrinDirect && transport is! GrinProxy) return false;
      await backend.testNodeConnection(
        nodeUrl: network.nodeUrl,
        apiSecret: network.apiSecret,
        socksProxy: transport is GrinProxy ? transport.address : null,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> updateTransactions() async {
    final current = _api;
    if (current == null || _exited) return;
    try {
      final fromNode = !_scanPending;
      final api = fromNode ? await _requireNetwork() : current;
      final list = await api.getTransactions(refreshFromNode: fromNode);
      if (fromNode) _offline = !list.refreshedFromNode;
      await _storeTransactions(list);
    } catch (e) {
      throw _fail("updateTransactions", e);
    }
  }

  Future<void> _storeTransactions(GrinTxList list) async {
    _slatepacks = {
      for (final entry in list.transactions)
        if (entry.armoredSlatepack != null)
          grinTxid(entry): entry.armoredSlatepack!,
    };

    final txids = {for (final entry in list.transactions) grinTxid(entry)};
    final stored = await mainDB.isar.transactionV2s
        .where()
        .walletIdEqualTo(walletId)
        .findAll();
    final storedHeights = {
      for (final tx in stored)
        if (txids.contains(tx.txid)) tx.txid: tx.height,
    };

    final transactions = mapGrinTransactions(
      entries: list.transactions,
      walletId: walletId,
      ownAddress: (await getCurrentReceivingAddress())?.value,
      storedHeights: storedHeights,
      chainHeight: info.cachedChainHeight,
      fractionDigits: cryptoCurrency.fractionDigits,
    );
    await mainDB.updateOrPutTransactionV2s(transactions);
  }

  @override
  Future<void> updateBalance() async {
    final api = _api;
    if (api == null || _exited) return;
    try {
      final balance = await api.getBalance(
        refreshFromNode: false,
        minimumConfirmations: cryptoCurrency.minConfirms,
      );
      _amountLocked = _amount(balance.amountLocked);
      await info.updateBalance(
        newBalance: grinBalanceToStack(balance, cryptoCurrency.fractionDigits),
        isar: mainDB.isar,
      );
    } catch (e) {
      throw _fail("updateBalance", e);
    }
    if (_offline) throw GrinWalletException("Could not reach the Grin node.");
  }

  @override
  Future<bool> updateUTXOs() async => false;

  @override
  Future<void> checkSaveInitialReceivingAddress() async {
    if (_api == null) return;
    if (await getCurrentReceivingAddress() != null) return;
    await _storeAddress();
  }

  /// Only the index 0 address receives, so it is the only one stored.
  Future<void> _storeAddress() async {
    final api = _requireApi();
    final address = await api.getAddress(index: 0);
    await mainDB.updateOrPutAddresses([
      Address(
        walletId: walletId,
        value: address.slatepackAddress,
        publicKey: [],
        derivationIndex: 0,
        derivationPath: null,
        type: AddressType.mimbleWimble,
        subType: AddressSubType.receiving,
      ),
    ]);
  }

  // ========== Sending ========================================================

  /// Methods a Grin send can use.
  @override
  List<SlatepackMethod> get supportedMethods => const [
    SlatepackMethod.slatepack,
    SlatepackMethod.http,
  ];

  /// Slate V4 has no message.
  @override
  bool get supportsOnChainNote => false;

  @override
  bool get supportsInvoices => true;

  BigInt _nano(Amount amount) {
    if (amount.fractionDigits != cryptoCurrency.fractionDigits) {
      throw GrinWalletException("Amount has the wrong precision.");
    }
    return amount.raw;
  }

  Amount _amount(BigInt nanogrin) =>
      Amount(rawValue: nanogrin, fractionDigits: cryptoCurrency.fractionDigits);

  SlatepackMethod _methodFor(TxData txData, String address) {
    final explicit = txData.slatepackMethod;
    if (explicit != null) return explicit;
    final kind = cryptoCurrency.addressKind(address);
    return kind == GrinAddressKind.onion || kind == GrinAddressKind.http
        ? SlatepackMethod.http
        : SlatepackMethod.slatepack;
  }

  bool get _torWanted => torFeatureEnabled && prefs.useTor;

  /// Throws unless an HTTP send to [address] is allowed now.
  void _checkHttpPolicy(
    String address, {
    required bool clearnetAcknowledged,
    required bool plaintextAcknowledged,
  }) {
    final kind = cryptoCurrency.addressKind(address);
    final refusal = grinHttpSendRefusal(
      transport: _applied?.transport ?? _resolveNetwork().transport,
      torWanted: _torWanted,
      kind: kind,
      isPlainHttp: _isPlainHttp(address, kind),
      clearnetAcknowledged: clearnetAcknowledged,
      plaintextAcknowledged: plaintextAcknowledged,
    );
    if (refusal == null) return;
    throw GrinWalletException(_refusalMessage(refusal));
  }

  static String _refusalMessage(GrinSendRefusal refusal) => switch (refusal) {
    GrinSendRefusal.blocked =>
      "The Grin wallet's network is blocked. Check the node and Tor "
          "settings.",
    GrinSendRefusal.torRequired =>
      "Sending to this address needs Tor. Turn Tor on and try again.",
    GrinSendRefusal.torDown =>
      "Tor is not connected. Nothing was sent or locked.",
    GrinSendRefusal.clearnetNotAcknowledged =>
      "Sending without Tor shows your IP address to the recipient.",
    GrinSendRefusal.plaintextNotAcknowledged =>
      "This address uses unencrypted http://.",
    GrinSendRefusal.unsupportedTarget =>
      "This is not an address a Grin wallet can send to.",
  };

  bool _isPlainHttp(String address, GrinAddressKind? kind) =>
      kind == GrinAddressKind.http &&
      address.trim().toLowerCase().startsWith("http://");

  /// What the confirm screen must ask or refuse before an HTTP send.
  @override
  SlatepackHttpPolicy httpSendPolicy(String address) {
    final kind = cryptoCurrency.addressKind(address);
    // Resolved now: the applied transport can lag a Tor change.
    final transport = _resolveNetwork().transport;
    final plain = _isPlainHttp(address, kind);
    GrinSendRefusal? check({required bool clearnet, required bool plaintext}) =>
        grinHttpSendRefusal(
          transport: transport,
          torWanted: _torWanted,
          kind: kind,
          isPlainHttp: plain,
          clearnetAcknowledged: clearnet,
          plaintextAcknowledged: plaintext,
        );

    final hard = check(clearnet: true, plaintext: true);
    if (hard != null) {
      return SlatepackHttpPolicy(blockedReason: _refusalMessage(hard));
    }
    return SlatepackHttpPolicy(
      needsClearnetAck:
          check(clearnet: false, plaintext: true) ==
          GrinSendRefusal.clearnetNotAcknowledged,
      needsPlaintextAck: plain,
    );
  }

  @override
  Future<TxData> prepareSend({required TxData txData}) async {
    try {
      _refuseWhileScanning();
      final recipients = txData.recipients;
      if (recipients == null || recipients.length != 1) {
        throw GrinWalletException("A Grin send has exactly one recipient.");
      }
      final recipient = recipients.single;
      final address = recipient.address.trim();
      final method = _methodFor(txData, address);
      switch (method) {
        case SlatepackMethod.relay:
          throw GrinWalletException("Grin has no relay.");
        case SlatepackMethod.http:
          _checkHttpPolicy(
            address,
            clearnetAcknowledged: true,
            plaintextAcknowledged: true,
          );
        case SlatepackMethod.slatepack:
          if (address.isNotEmpty &&
              cryptoCurrency.addressKind(address) !=
                  GrinAddressKind.slatepack) {
            throw GrinWalletException(
              "A Slatepack can only be encrypted to a Grin address.",
            );
          }
      }

      final sendAll =
          txData.subtractFeeFromAmount ||
          recipient.amount == info.cachedBalance.spendable;
      final amount = _nano(recipient.amount);
      if (amount <= BigInt.zero) {
        throw GrinWalletException("The amount must be more than zero.");
      }

      final api = await _requireNetwork();
      final estimate = await api.estimateFee(
        amount: amount,
        minimumConfirmations: cryptoCurrency.minConfirms,
        selectionStrategyIsAll: sendAll,
        amountIncludesFee: sendAll,
      );

      return txData.copyWith(
        recipients: [recipient.copyWith(amount: _amount(estimate.amount))],
        fee: _amount(estimate.fee),
        otherData: slatepackMethodOtherData(method),
        subtractFeeFromAmount: sendAll,
      );
    } catch (e) {
      throw _fail("prepareSend", e);
    }
  }

  @override
  Future<TxData> confirmSend({required TxData txData}) async {
    try {
      _refuseWhileScanning();
      final recipient = txData.recipients!.single;
      final address = recipient.address.trim();
      final method = _methodFor(txData, address);
      final sendAll = txData.subtractFeeFromAmount;
      final fee = txData.fee;
      // A send-all was estimated with the fee taken out of the amount.
      final amount = sendAll && fee != null
          ? _nano(recipient.amount + fee)
          : _nano(recipient.amount);

      switch (method) {
        case SlatepackMethod.relay:
          throw GrinWalletException("Grin has no relay.");

        case SlatepackMethod.slatepack:
          final slatepack = await _initSend(
            amount: amount,
            recipientAddress: address.isEmpty ? null : address,
            sendAll: sendAll,
          );
          unawaited(refresh());
          return txData.copyWith(
            txid: slatepack.slateId,
            slatepack: slatepack.armoredSlatepack,
            fee: _amount(slatepack.fee),
          );

        case SlatepackMethod.http:
          final api = await _requireNetwork();
          _checkHttpPolicy(
            address,
            clearnetAcknowledged: txData.grinClearnetAcknowledged,
            plaintextAcknowledged: txData.grinPlaintextAcknowledged,
          );
          final GrinSendResult result;
          try {
            result = await api.sendHttp(
              GrinHttpSendArgs(
                amount: amount,
                recipientUrlOrAddress: address,
                minimumConfirmations: cryptoCurrency.minConfirms,
                selectionStrategyIsAll: sendAll,
                amountIncludesFee: sendAll,
                ttlBlocks: slatepackTtlBlocks,
                post: true,
              ),
            );
          } on GrinSlateException catch (e) {
            throw _fail("sendHttp", e, message: _badAnswer);
          } on GrinTransactionException catch (e) {
            throw _fail("sendHttp", e, message: _badAnswer);
          }
          unawaited(refresh());
          return txData.copyWith(
            txid: result.slateId,
            fee: _amount(result.fee),
          );
      }
    } catch (e) {
      throw _fail("confirmSend", e);
    }
  }

  static const _badAnswer =
      "The recipient's answer failed checks. Nothing was sent or locked.";

  Future<GrinSlatepack> _initSend({
    required BigInt amount,
    required String? recipientAddress,
    required bool sendAll,
  }) async {
    _refuseWhileScanning();
    final api = await _requireNetwork();
    return await api.initSend(
      GrinSendArgs(
        amount: amount,
        minimumConfirmations: cryptoCurrency.minConfirms,
        selectionStrategyIsAll: sendAll,
        amountIncludesFee: sendAll,
        recipientAddress: recipientAddress,
        ttlBlocks: slatepackTtlBlocks,
      ),
    );
  }

  @override
  Future<Amount> estimateFeeFor(Amount amount, BigInt feeRate) async {
    if (amount.raw <= BigInt.zero) return _amount(BigInt.zero);
    try {
      _refuseWhileScanning();
      final api = await _requireNetwork();
      final estimate = await api.estimateFee(
        amount: _nano(amount),
        minimumConfirmations: cryptoCurrency.minConfirms,
      );
      return _amount(estimate.fee);
    } catch (e) {
      throw _fail("estimateFee", e);
    }
  }

  @override
  Future<FeeObject> get fees async => FeeObject(
    numberOfBlocksFast: 10,
    numberOfBlocksAverage: 10,
    numberOfBlocksSlow: 10,
    fast: BigInt.one,
    medium: BigInt.one,
    slow: BigInt.one,
  );

  @override
  Future<TxData> updateSentCachedTxData({required TxData txData}) async =>
      txData;

  // ========== Slatepacks =====================================================

  /// The address counterparties send to.
  @override
  Future<String> slatepackAddress() async {
    final stored = await getCurrentReceivingAddress();
    if (stored != null) return stored.value;
    try {
      return (await _requireApi().getAddress()).slatepackAddress;
    } catch (e) {
      throw _fail("slatepackAddress", e);
    }
  }

  /// The index 0 address as the native wallet derives it, not the stored
  /// copy.
  Future<String> getNativeReceivingAddress() async {
    try {
      return (await _requireApi().getAddress()).slatepackAddress;
    } catch (e) {
      throw _fail("getNativeReceivingAddress", e);
    }
  }

  @override
  bool get supportsSlatepackRecipient => true;

  @override
  String? get directSendAddressHint =>
      "${cryptoCurrency.network == CryptoCurrencyNetwork.main ? "grin1" : "tgrin1"}"
      " address, onion or http(s) URL";

  @override
  bool get receiveQrIsRawAddress => true;

  @override
  String? get receiveAddressNote =>
      "Grin is received by Slatepack, or directly by your own listener. "
      "Only this address receives; this wallet does not make new ones.";

  @override
  Amount? get amountLocked => _amountLocked;
  Amount? _amountLocked;

  SlateState _state(GrinSlateState state) =>
      SlateState.fromCode(state.wireName);

  SlatepackResult _result(GrinSlatepack slatepack) => SlatepackResult(
    success: true,
    slatepack: slatepack.armoredSlatepack,
    wasEncrypted: slatepack.isEncrypted,
    recipientAddress: slatepack.recipients.isEmpty
        ? null
        : slatepack.recipients.first,
    state: _state(slatepack.state),
    slateId: slatepack.slateId,
    amount: _amount(slatepack.amount),
    fee: _amount(slatepack.fee),
  );

  FinalizeResult _finalized(GrinFinalizeResult result) => FinalizeResult(
    success: true,
    slateId: result.slateId,
    posted: result.posted,
    kernelExcess: result.kernelExcess,
  );

  /// A finalize that failed. A node error that names the slate means the
  /// transaction was finalized and stored but not accepted: success, not
  /// posted, so the screens offer repost.
  FinalizeResult _finalizeFailure(
    String operation,
    Object error, {
    required String notFoundMessage,
  }) {
    final ex = error is GrinNotFoundException
        ? _fail(operation, error, message: notFoundMessage)
        : _fail(operation, error);
    if (ex is GrinWalletException && ex.finalizedNotBroadcast) {
      return FinalizeResult(
        success: true,
        error: ex.message,
        slateId: ex.slateId,
        posted: false,
      );
    }
    return FinalizeResult(success: false, error: ex.toString());
  }

  /// Reads a Slatepack without changing anything. During a scan, a plain
  /// one is read without the wallet so it does not wait for the batch.
  @override
  Future<SlateInspection> inspectSlatepack(String armored) async {
    final GrinSlateInfo info;
    try {
      info = await _decode(armored);
    } catch (e) {
      throw _fail("inspectSlatepack", e);
    }
    final state = _state(info.state);
    // S2 and I2 carry amount 0; the local transaction has the real one.
    final hasAmount = state != SlateState.s2 && state != SlateState.i2;
    return SlateInspection(
      state: state,
      slateId: info.slateId,
      amount: hasAmount ? _amount(info.amount) : null,
      // An I1 carries fee 0: the payer sets it.
      fee: info.fee > BigInt.zero ? _amount(info.fee) : null,
      senderAddress: info.sender,
      recipientAddress: info.recipients.isEmpty ? null : info.recipients.first,
      isEncrypted: info.isEncrypted,
      ttlCutoffHeight: info.ttlCutoffHeight,
    );
  }

  Future<GrinSlateInfo> _decode(String armored) async {
    if (_scanJob != null) {
      try {
        return await backend.decodeSlatepackWithoutWallet(
          armored,
          cryptoCurrency.grinNetwork,
        );
      } on GrinSlateException {
        // Encrypted; only the wallet can read it.
      }
    }
    return await _requireApi().decodeSlatepack(armored);
  }

  /// Amount, fee and direction of the stored transaction for [slateId]. An
  /// invoice this wallet issued is a receive; a payment of someone's
  /// invoice is a send.
  @override
  Future<({Amount amount, Amount fee, bool isSend})?> localTxForSlate(
    String slateId,
  ) async {
    var tx = await _storedTx(slateId);
    if (tx == null) {
      // The slate may have been made a moment ago, before a refresh stored
      // its transaction. Not during a scan, which the read would wait for.
      if (_scanJob != null) return null;
      try {
        await updateTransactions();
      } catch (e) {
        Logging.instance.w(
          "Grin history refresh failed: ${describeGrinError(e)}",
        );
      }
      tx = await _storedTx(slateId);
      if (tx == null) return null;
    }
    final fractionDigits = cryptoCurrency.fractionDigits;
    final incoming = tx.type == TransactionType.incoming;
    final amount = incoming
        ? tx.getAmountReceivedInThisWallet(fractionDigits: fractionDigits)
        : tx.getAmountSentFromThisWallet(
            fractionDigits: fractionDigits,
            subtractFee: true,
          );
    return (
      amount: amount,
      fee: tx.getFee(fractionDigits: fractionDigits),
      isSend: !incoming,
    );
  }

  /// Starts a Slatepack send and returns the S1. Locks the inputs. With a
  /// recipient address the S1 is encrypted to it and asks for a payment
  /// proof. Grin slates have no message.
  @override
  Future<SlatepackResult> createSlatepack({
    required Amount amount,
    String? recipientAddress,
    String? message,
    bool sendAll = false,
  }) async {
    try {
      final address = recipientAddress?.trim();
      if (address != null &&
          address.isNotEmpty &&
          cryptoCurrency.addressKind(address) != GrinAddressKind.slatepack) {
        throw GrinWalletException(
          "A Slatepack can only be encrypted to a Grin address.",
        );
      }
      final result = await _initSend(
        amount: _nano(amount),
        recipientAddress: (address?.isEmpty ?? true) ? null : address,
        sendAll: sendAll,
      );
      unawaited(refresh());
      return _result(result);
    } catch (e) {
      return SlatepackResult(
        success: false,
        error: _fail("createSlatepack", e).toString(),
      );
    }
  }

  /// Answers an S1 and returns the S2.
  @override
  Future<SlatepackResult> receiveSlatepack(String s1) async {
    try {
      final result = await _requireApi().receiveSlatepack(s1);
      unawaited(refresh());
      return _result(result);
    } catch (e) {
      return SlatepackResult(
        success: false,
        error: _fail("receiveSlatepack", e).toString(),
      );
    }
  }

  /// Finalizes a send from its S2 and broadcasts it.
  @override
  Future<FinalizeResult> finalizeSlatepack(String s2) async {
    try {
      final api = await _requireNetwork();
      final result = await api.finalizeSlatepack(s2);
      unawaited(refresh());
      return _finalized(result);
    } catch (e) {
      if (e is GrinNodeException) unawaited(refresh());
      return _finalizeFailure(
        "finalizeSlatepack",
        e,
        notFoundMessage: "This is not a pending send from this wallet.",
      );
    }
  }

  /// Requests a payment and returns the I1. Locks nothing.
  @override
  Future<SlatepackResult> issueInvoice({
    required Amount amount,
    String? payerAddress,
  }) async {
    try {
      final payer = payerAddress?.trim();
      if (payer != null &&
          payer.isNotEmpty &&
          cryptoCurrency.addressKind(payer) != GrinAddressKind.slatepack) {
        throw GrinWalletException(
          "An invoice can only be encrypted to a Grin address.",
        );
      }
      final nano = _nano(amount);
      if (nano <= BigInt.zero) {
        throw GrinWalletException("The amount must be more than zero.");
      }
      final result = await _requireApi().issueInvoice(
        GrinInvoiceArgs(
          amount: nano,
          recipientAddress: (payer?.isEmpty ?? true) ? null : payer,
        ),
      );
      unawaited(refresh());
      return _result(result);
    } catch (e) {
      return SlatepackResult(
        success: false,
        error: _fail("issueInvoice", e).toString(),
      );
    }
  }

  /// Pays an I1 for exactly [confirmedAmount], the amount the user agreed
  /// to, and returns the I2. Locks the inputs. The I1 is decoded again and
  /// anything but an I1 for that amount is refused before the library is
  /// asked to pay; the library checks the amount once more.
  @override
  Future<SlatepackResult> processInvoice(
    String i1, {
    required Amount confirmedAmount,
  }) async {
    try {
      _refuseWhileScanning();
      final expected = _nano(confirmedAmount);
      final api = await _requireNetwork();
      final decoded = await api.decodeSlatepack(i1);
      if (decoded.state != GrinSlateState.i1) {
        throw GrinWalletException("This Slatepack is not an invoice.");
      }
      if (decoded.amount != expected) {
        throw GrinWalletException(
          "The invoice amount does not match the amount you confirmed.",
        );
      }
      final result = await api.processInvoice(
        i1,
        GrinProcessInvoiceArgs(
          minimumConfirmations: cryptoCurrency.minConfirms,
          ttlBlocks: slatepackTtlBlocks,
          expectedAmount: expected,
        ),
      );
      unawaited(refresh());
      return _result(result);
    } catch (e) {
      return SlatepackResult(
        success: false,
        error: _fail("processInvoice", e).toString(),
      );
    }
  }

  /// Finalizes an invoice from its I2 and broadcasts it.
  @override
  Future<FinalizeResult> finalizeInvoice(String i2) async {
    try {
      final api = await _requireNetwork();
      final result = await api.finalizeInvoice(i2);
      unawaited(refresh());
      return _finalized(result);
    } catch (e) {
      if (e is GrinNodeException) unawaited(refresh());
      return _finalizeFailure(
        "finalizeInvoice",
        e,
        notFoundMessage: "This is not an invoice issued by this wallet.",
      );
    }
  }

  /// Cancels the unconfirmed transaction [slateId]. Returns "" or a message
  /// to show.
  @override
  Future<String> cancelPendingTransactionAndPost(String slateId) async {
    try {
      _refuseWhileScanning();
      final api = await _requireNetwork();
      final logIds = _logIds(await _storedTx(slateId));
      if (logIds.isEmpty) {
        await api.cancelTransaction(slateId: slateId);
      } else {
        var cancelled = 0;
        for (final id in logIds) {
          try {
            await api.cancelTransaction(txId: id);
            cancelled++;
          } on GrinTransactionException {
            // A self-send's other half may already be cancelled.
            if (id == logIds.last && cancelled == 0) rethrow;
          }
        }
      }
      unawaited(refresh());
      return "";
    } catch (e) {
      return _fail("cancel", e).toString();
    }
  }

  /// The latest Slatepack of [txid], if the wallet kept one.
  @override
  Future<String?> pendingSlatepackFor(String txid) async {
    final cached = _slatepacks[txid];
    if (cached != null) return cached;
    try {
      final list = await _requireApi().getTransactions(refreshFromNode: false);
      _slatepacks = {
        for (final entry in list.transactions)
          if (entry.armoredSlatepack != null)
            grinTxid(entry): entry.armoredSlatepack!,
      };
      return _slatepacks[txid];
    } catch (e) {
      throw _fail("pendingSlatepackFor", e);
    }
  }

  @override
  bool get supportsRepost => true;

  @override
  Future<bool> canRepost(String txid) async {
    final tx = await _storedTx(txid);
    return tx != null && (slatepackTxInfo(tx)?.canRepost ?? false);
  }

  /// Broadcasts the stored finalized transaction [txid] again.
  @override
  Future<void> repost(String txid) async {
    try {
      final tx = await _storedTx(txid);
      if (tx == null || !_otherDataFlag(tx, TxV2OdKeys.grinHasStoredTx)) {
        throw GrinWalletException("No finalized transaction is stored.");
      }
      final api = await _requireNetwork();
      final logIds = _logIds(tx);
      await api.repost(
        txId: logIds.isEmpty ? null : logIds.first,
        slateId: tx.slateId,
      );
      unawaited(refresh());
    } catch (e) {
      throw _fail(
        "repost",
        e,
        message: e is GrinNotFoundException
            ? "This transaction is not finalized, or is already confirmed."
            : null,
      );
    }
  }

  @override
  bool get supportsPaymentProofs => true;

  /// The payment proof of [txid] as JSON.
  @override
  Future<String> exportPaymentProof(String txid) async {
    try {
      final tx = await _storedTx(txid);
      if (tx == null || !_otherDataFlag(tx, TxV2OdKeys.grinHasPaymentProof)) {
        throw GrinWalletException("This transaction has no payment proof.");
      }
      final logIds = _logIds(tx);
      final proof = await _requireApi().exportPaymentProof(
        txId: logIds.isEmpty ? null : logIds.first,
        slateId: tx.slateId,
      );
      return proof.toJsonString();
    } catch (e) {
      throw _fail(
        "exportPaymentProof",
        e,
        message: e is GrinNotFoundException
            ? "The payment proof is not available until the transaction is "
                  "finalized."
            : null,
      );
    }
  }

  /// Checks a payment proof against the chain through the wallet's node.
  @override
  Future<PaymentProofCheck> verifyPaymentProof(String proofJson) async {
    try {
      final GrinPaymentProof proof;
      try {
        proof = GrinPaymentProof.fromJsonString(proofJson.trim());
      } on FormatException {
        throw GrinWalletException("This is not a Grin payment proof.");
      }
      final api = await _requireNetwork();
      final check = await api.verifyPaymentProof(proof);
      return PaymentProofCheck(
        amount: _amount(proof.amount),
        kernelExcess: proof.excess,
        senderAddress: proof.senderAddress,
        recipientAddress: proof.recipientAddress,
        isSender: check.isSender,
        isRecipient: check.isRecipient,
      );
    } catch (e) {
      throw _fail(
        "verifyPaymentProof",
        e,
        message: switch (e) {
          GrinTransactionException() =>
            "The proof did not verify: a signature is wrong or the kernel is "
                "not on the chain.",
          GrinJsonException() =>
            "This is not a valid Grin payment proof for this network.",
          _ => null,
        },
      );
    }
  }

  @override
  SlatepackTxInfo? slatepackTxInfo(TransactionV2 tx) {
    if (!tx.isGrinTransaction) return null;
    final data = tx.otherData == null
        ? const <String, dynamic>{}
        : _decodeOtherData(tx.otherData!);
    final state = SlateState.fromCode(
      data[TxV2OdKeys.grinSlateState] as String?,
    );
    final stored = data[TxV2OdKeys.grinHasStoredTx] == true;
    final open = !tx.isCancelled && !tx.isReverted;
    final unconfirmed = tx.height == null || tx.height! <= 0;
    final finalized = stored && open && unconfirmed;
    return SlatepackTxInfo(
      state: state,
      slateId: tx.slateId,
      kernelExcess: data[TxV2OdKeys.grinKernelExcess] as String?,
      counterpartyAddress: data[TxV2OdKeys.counterpartyAddress] as String?,
      ttlCutoffHeight: data[TxV2OdKeys.grinTtlCutoff] as int?,
      finalizedAwaitingConfirmation: finalized,
      canRepost: finalized,
      canShowSlatepack:
          open &&
          unconfirmed &&
          !stored &&
          (state == SlateState.s1 ||
              state == SlateState.s2 ||
              state == SlateState.i1 ||
              state == SlateState.i2),
      hasPaymentProof: data[TxV2OdKeys.grinHasPaymentProof] == true,
    );
  }

  Future<TransactionV2?> _storedTx(String txid) => mainDB.isar.transactionV2s
      .where()
      .txidWalletIdEqualTo(txid, walletId)
      .findFirst();

  List<int> _logIds(TransactionV2? tx) {
    final data = tx?.otherData;
    if (data == null) return const [];
    final ids = _decodeOtherData(data)[TxV2OdKeys.grinLogIds];
    return ids is List ? ids.whereType<int>().toList() : const [];
  }

  bool _otherDataFlag(TransactionV2 tx, String key) {
    final data = tx.otherData;
    return data != null && _decodeOtherData(data)[key] == true;
  }

  Map<String, dynamic> _decodeOtherData(String data) {
    try {
      return Map<String, dynamic>.from(jsonDecode(data) as Map);
    } catch (_) {
      return const {};
    }
  }
}

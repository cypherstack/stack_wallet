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
import '../../../services/event_bus/events/global/blocks_remaining_event.dart';
import '../../../services/event_bus/events/global/node_connection_status_changed_event.dart';
import '../../../services/event_bus/events/global/refresh_percent_changed_event.dart';
import '../../../services/event_bus/events/global/tor_connection_status_changed_event.dart';
import '../../../services/event_bus/events/global/tor_status_changed_event.dart';
import '../../../services/event_bus/events/global/wallet_sync_status_changed_event.dart';
import '../../../services/event_bus/global_event_bus.dart';
import '../../../services/tor_service.dart';
import '../../../utilities/amount/amount.dart';
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
import '../supporting/grin/grin_transport.dart';
import '../supporting/grin/grin_tx_mapping.dart';
import '../supporting/grin_wallet_info_extension.dart';

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

class GrinWallet extends Bip39Wallet<Grin> {
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
            if (existing != null) {
              throw GrinWalletException(
                "The Grin wallet files are missing. Restore this wallet from "
                "its recovery phrase.",
              );
            }
            api = await _createNew(dir, stored);
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
    final api = await backend.create(
      config: _buildConfig(dir),
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
  }

  bool get _isLive => _api != null || _scanJob != null;

  Future<void> _releaseOwnership() async {
    if (identical(_owners[walletId], this)) _owners.remove(walletId);
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
          _api = await _createFromMnemonic(await _ensureWalletDir());
        } catch (e) {
          await _releaseOwnership();
          rethrow;
        }
      });
      await _storeAddress();
      final height = info.restoreHeight;
      await info.updateGrinData(
        grinData: GrinWalletData(
          creationHeight: height,
          pendingScanFrom: height,
        ),
        isar: mainDB.isar,
      );
      highestPercent = 0;
    });
  }

  /// Keeps the history and scans again from the restore height. Creates the
  /// wallet from the mnemonic first if its files are missing.
  Future<void> _rescan() async {
    _api?.cancelScan();
    final running = _scanJob;
    if (running != null) await running;

    await refreshMutex.protect(() async {
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
            _api = await _createFromMnemonic(dir);
          } catch (e) {
            await _releaseOwnership();
            rethrow;
          }
        });
        await _storeAddress();
      }
      final height = info.restoreHeight;
      await info.updateGrinData(
        grinData: (info.grinData ?? GrinWalletData(creationHeight: height))
            .withPendingScanFrom(height),
        isar: mainDB.isar,
      );
      highestPercent = 0;
    });
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
    final mnemonic = await getMnemonic();
    try {
      return await backend.create(
        config: _buildConfig(dir),
        mnemonic: mnemonic,
        password: password,
      );
    } on GrinWalletExistsException catch (e) {
      if (e.details?["reason"] != "leftover_wallet_data") rethrow;
      await backend.delete(walletDir: dir);
      return await backend.create(
        config: _buildConfig(dir),
        mnemonic: mnemonic,
        password: password,
      );
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
    final running = _scanJob;
    if (running != null) return running;
    final job = _scan();
    _scanJob = job;
    return job.whenComplete(() {
      if (identical(_scanJob, job)) _scanJob = null;
    });
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
        await api.scan(startHeight: from);
        await _setPendingScanFrom(null);
        succeeded = true;
      } on GrinCancelledException catch (e) {
        await _setPendingScanFrom(await _resumeHeight(api, e, from));
      } catch (e) {
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

  Future<int> _resumeHeight(
    GrinWalletApi api,
    GrinCancelledException cancelled,
    int from,
  ) async {
    final scanned = cancelled.details?["scanned_height"];
    if (scanned is int) return math.max(scanned + 1, 0);
    try {
      return await api.lastScannedHeight() + 1;
    } catch (_) {
      return from;
    }
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

  /// Runs the pending scan if there is one, otherwise a normal refresh.
  @override
  Future<void> refresh() async {
    if (_api == null || _exited) return;
    if (_scanPending) return _runScanJob();
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
    final changed = await _transportMutex.protect(() async {
      final api = _api;
      if (api == null || _exited) return false;
      final network = _resolveNetwork();
      final transport = network.transport;
      if (transport is GrinHold) return false;
      if (network == _applied) return false;

      if (_scanJob != null) api.cancelScan();
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

  Exception _fail(String operation, Object error) =>
      _failStatic(operation, error);

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
  List<SlatepackMethod> get supportedMethods => const [
    SlatepackMethod.slatepack,
    SlatepackMethod.http,
  ];

  /// Slate V4 has no message.
  bool get supportsOnChainNote => false;

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
      isPlainHttp:
          kind == GrinAddressKind.http &&
          address.trim().toLowerCase().startsWith("http://"),
      clearnetAcknowledged: clearnetAcknowledged,
      plaintextAcknowledged: plaintextAcknowledged,
    );
    if (refusal == null) return;
    throw GrinWalletException(switch (refusal) {
      GrinSendRefusal.blocked => "The Grin wallet's network is blocked.",
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
    });
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
        slatepackMethod: method,
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
          final result = await api.sendHttp(
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

  /// Reads a Slatepack without changing anything. During a scan, a plain
  /// one is read without the wallet so it does not wait for the batch.
  Future<GrinSlateInfo> inspectSlatepack(String armored) async {
    try {
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
    } catch (e) {
      throw _fail("inspectSlatepack", e);
    }
  }

  /// Amount and fee of the stored transaction for [slateId].
  Future<({Amount amount, Amount fee})?> localTxForSlate(String slateId) async {
    final tx = await _storedTx(slateId);
    if (tx == null) return null;
    final fractionDigits = cryptoCurrency.fractionDigits;
    final amount = tx.type == TransactionType.incoming
        ? tx.getAmountReceivedInThisWallet(fractionDigits: fractionDigits)
        : tx.getAmountSentFromThisWallet(
            fractionDigits: fractionDigits,
            subtractFee: true,
          );
    return (amount: amount, fee: tx.getFee(fractionDigits: fractionDigits));
  }

  /// Starts a Slatepack send and returns the S1. Locks the inputs.
  Future<GrinSlatepack> createSlatepack({
    required Amount amount,
    String? recipientAddress,
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
      return result;
    } catch (e) {
      throw _fail("createSlatepack", e);
    }
  }

  /// Answers an S1 and returns the S2.
  Future<GrinSlatepack> receiveSlatepack(String s1) async {
    try {
      final result = await _requireApi().receiveSlatepack(s1);
      unawaited(refresh());
      return result;
    } catch (e) {
      throw _fail("receiveSlatepack", e);
    }
  }

  /// Finalizes a send from its S2 and broadcasts it.
  Future<GrinFinalizeResult> finalizeSlatepack(String s2) async {
    try {
      final api = await _requireNetwork();
      final result = await api.finalizeSlatepack(s2);
      unawaited(refresh());
      return result;
    } catch (e) {
      throw _fail("finalizeSlatepack", e);
    }
  }

  /// Requests a payment and returns the I1.
  Future<GrinSlatepack> issueInvoice({
    required Amount amount,
    String? payerAddress,
  }) async {
    try {
      final result = await _requireApi().issueInvoice(
        GrinInvoiceArgs(amount: _nano(amount), recipientAddress: payerAddress),
      );
      unawaited(refresh());
      return result;
    } catch (e) {
      throw _fail("issueInvoice", e);
    }
  }

  /// Pays an I1 for exactly [confirmedAmount], the amount the user agreed
  /// to, and returns the I2. Locks the inputs.
  Future<GrinSlatepack> processInvoice(
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
      return result;
    } catch (e) {
      throw _fail("processInvoice", e);
    }
  }

  /// Finalizes an invoice from its I2 and broadcasts it.
  Future<GrinFinalizeResult> finalizeInvoice(String i2) async {
    try {
      final api = await _requireNetwork();
      final result = await api.finalizeInvoice(i2);
      unawaited(refresh());
      return result;
    } catch (e) {
      throw _fail("finalizeInvoice", e);
    }
  }

  /// Cancels the unconfirmed transaction [slateId]. Returns "" or a message
  /// to show.
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

  /// Broadcasts the stored finalized transaction [txid] again.
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
      throw _fail("repost", e);
    }
  }

  /// The payment proof of [txid] as JSON.
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
      throw _fail("exportPaymentProof", e);
    }
  }

  /// Checks a payment proof against the chain through the wallet's node.
  Future<GrinPaymentProofVerification> verifyPaymentProof(
    String proofJson,
  ) async {
    try {
      final GrinPaymentProof proof;
      try {
        proof = GrinPaymentProof.fromJsonString(proofJson);
      } on FormatException {
        throw GrinWalletException("This is not a Grin payment proof.");
      }
      final api = await _requireNetwork();
      return await api.verifyPaymentProof(proof);
    } catch (e) {
      throw _fail("verifyPaymentProof", e);
    }
  }

  Future<TransactionV2?> _storedTx(String txid) => mainDB.isar.transactionV2s
      .where()
      .txidWalletIdEqualTo(txid, walletId)
      .findFirst();

  List<int> _logIds(TransactionV2? tx) {
    final data = tx?.otherData;
    if (data == null) return const [];
    final ids = _decode(data)[TxV2OdKeys.grinLogIds];
    return ids is List ? ids.whereType<int>().toList() : const [];
  }

  bool _otherDataFlag(TransactionV2 tx, String key) {
    final data = tx.otherData;
    return data != null && _decode(data)[key] == true;
  }

  Map<String, dynamic> _decode(String data) {
    try {
      return Map<String, dynamic>.from(jsonDecode(data) as Map);
    } catch (_) {
      return const {};
    }
  }
}

import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:isar_community/isar.dart';
import 'package:mutex/mutex.dart';

import '../../../models/isar/models/blockchain_data/address.dart';
import '../../../utilities/logger.dart';
import '../../../utilities/stack_file_system.dart';
import '../../../utilities/xelis_storage.dart';
import '../../../wl_gen/interfaces/lib_xelis_interface.dart';
import '../../crypto_currency/intermediate/electrum_currency.dart';
import '../wallet_mixin_interfaces/mnemonic_interface.dart';
import 'external_wallet.dart';
import 'xelis_event_batcher.dart';

abstract class LibXelisWallet<T extends ElectrumCurrency>
    extends ExternalWallet<T>
    with MnemonicInterface {
  LibXelisWallet(super.currency, {LibXelisInterface? native})
    : _native = native;

  final LibXelisInterface? _native;
  LibXelisInterface get xelis => _native ?? libXelis;

  static const String _kHasFullTablesKey = 'xelis_has_full_tables';
  static const String _kGeneratingTablesKey = 'xelis_generating_tables';
  static const String _kWantsFullTablesKey = 'xelis_wants_full_tables';
  static final _tableGenerationMutex = Mutex();
  static Future<void>? _tableGenerationFuture;

  BigInt pruningHeight = BigInt.zero;

  OpaqueXelisWallet? wallet;

  void checkInitialized() {
    if (wallet == null) {
      throw StateError('libXelisWallet not initialized');
    }
  }

  Timer? timer;

  final _connectionMutex = Mutex();
  XelisEventSubscription? _runtimeEvents;
  XelisEventSubscription? _businessEvents;
  bool _businessEventsFailed = false;
  Future<void> _eventWork = Future.value();
  XelisEventBatcher<Event>? _businessBatcher;
  XelisEventBatcher<Event>? _runtimeBatcher;
  Timer? _reconnectTimer;
  int _connectionGeneration = 0;
  int sessionGeneration = 0;
  int _retryAttempt = 0;

  bool isCurrentSession(OpaqueXelisWallet handle, int generation) =>
      !exitInProgress &&
      identical(wallet, handle) &&
      sessionGeneration == generation;

  Future<String> getPrecomputedTablesPath() async {
    if (kIsWeb) {
      return "";
    } else {
      final appDir = await StackFileSystem.applicationXelisTableDirectory();
      return "${appDir.path}${Platform.pathSeparator}";
    }
  }

  Future<XelisTableState> getTableState() async {
    final hasFullTables = await xelis.hasTables(
      precomputedTablesPath: await getPrecomputedTablesPath(),
      stack_l1Low: false,
    );
    final isGenerating = _tableGenerationFuture != null;
    final wantsFull =
        await secureStorageInterface.read(key: _kWantsFullTablesKey) != 'false';

    return XelisTableState(
      isGenerating: isGenerating,
      currentSize: hasFullTables ? XelisTableSize.full : XelisTableSize.low,
      desiredSize: wantsFull ? XelisTableSize.full : XelisTableSize.low,
    );
  }

  Future<void> setTableState(XelisTableState state) async {
    await secureStorageInterface.write(
      key: _kHasFullTablesKey,
      value: state.currentSize == XelisTableSize.full ? 'true' : 'false',
    );
    await secureStorageInterface.write(
      key: _kGeneratingTablesKey,
      value: state.isGenerating ? 'true' : 'false',
    );
    await secureStorageInterface.write(
      key: _kWantsFullTablesKey,
      value: state.desiredSize == XelisTableSize.full ? 'true' : 'false',
    );
  }

  Future<void> handleEvent(Event event, {required bool Function() isCurrent});
  Future<void> handleNewTopoHeight(BigInt height);
  Future<void> handleNewTransaction(TransactionEntryWrapper tx);
  Future<void> handleBalanceChanged(BalanceChanged event);
  Future<void> handleRescan(BigInt startTopoheight) async {}
  Future<void> handleOnline() async {}
  Future<void> handleOffline() async {}
  Future<void> handleHistorySynced(BigInt topoheight) async {}
  Future<void> handleNewAsset(NewAsset asset) async {}

  @override
  Future<void> refresh({int? topoheight});

  Future<void> connect() async {
    _reconnectTimer?.cancel();
    _businessBatcher?.reset();
    _runtimeBatcher?.reset();
    final requestedGeneration = ++_connectionGeneration;
    await _connectionMutex
        .protect(() async {
          // Drain the old connection before starting its replacement.
          // The generation invalidates the old connection's callbacks.
          await _eventWork;
          checkInitialized();
          final handle = wallet!;
          final session = sessionGeneration;
          bool current() =>
              isCurrentSession(handle, session) &&
              requestedGeneration == _connectionGeneration;
          if (!current()) return;
          await _runtimeEvents?.cancel();
          _runtimeEvents = null;
          if (!current()) return;
          await xelis.offlineMode(handle);
          if (!current()) return;
          if (_businessEventsFailed) {
            final failed = _businessEvents;
            _businessEvents = null;
            await failed?.cancel();
            if (!current()) return;
          }
          if (_businessEvents == null) {
            final events = await xelis.subscribeBusinessEvents(handle);
            if (!current()) {
              await events.cancel();
              return;
            }
            _businessEvents = events;
            _businessEventsFailed = false;
            _listen(
              events,
              () =>
                  isCurrentSession(handle, session) &&
                  identical(_businessEvents, events),
              isRuntime: false,
            );
          }
          final events = await xelis.subscribeRuntimeEvents(handle);
          if (!current()) {
            await events.cancel();
            return;
          }
          _runtimeEvents = events;
          _listen(events, current, isRuntime: true);
          final node = getCurrentNode();
          await xelis.onlineMode(
            handle,
            daemonAddress: xelisDaemonOrigin(
              host: node.host,
              port: node.port,
              useSSL: node.useSSL,
            ),
          );
          if (current()) {
            _retryAttempt = 0;
            unawaited(refresh());
          }
        })
        .catchError((Object error, StackTrace stack) {
          // Subscriptions and offline transitions can fail before onlineMode.
          // Only the latest connection may schedule recovery for this session.
          if (requestedGeneration == _connectionGeneration &&
              !exitInProgress &&
              wallet != null) {
            scheduleReconnect();
          }
          Error.throwWithStackTrace(error, stack);
        });
  }

  void _listen(
    XelisEventSubscription events,
    bool Function() current, {
    required bool isRuntime,
  }) {
    Future<void> enqueue(Event event) {
      return _eventWork = _eventWork
          .then((_) async {
            if (current()) await handleEvent(event, isCurrent: current);
          })
          .catchError((Object error, StackTrace stack) {
            if (current()) {
              Logging.instance.e(
                'Xelis event handling failed',
                error: error,
                stackTrace: stack,
              );
              unawaited(refresh());
            }
          });
    }

    // XWF reads authoritative snapshots. Coalesce bursts before adding work
    // to the serialized queue, preserving staging's bounded refresh cadence.
    NewTopoheight? latestHeight;
    BalanceChanged? latestBalance;
    final batcher = XelisEventBatcher<Event>(
      flushInterval: const Duration(milliseconds: 500),
      flush: (batch) async {
        final height = latestHeight;
        final balance = latestBalance;
        latestHeight = null;
        latestBalance = null;
        if (!current()) return;
        if (batch.topoheightChanged && height != null) {
          await enqueue(height);
        }
        if (batch.transactions.isNotEmpty) {
          await enqueue(batch.transactions.last);
        } else if (batch.balanceChanged && balance != null) {
          await enqueue(balance);
        }
      },
    );
    if (isRuntime) {
      _runtimeBatcher = batcher;
    } else {
      _businessBatcher = batcher;
    }
    events.events.listen(
      (event) {
        if (!current()) return;
        switch (event) {
          case NewTopoheight():
            latestHeight = event;
            batcher.queueTopoheightChanged();
            return;
          case NewTransaction():
            batcher.queueTransaction(event);
            return;
          case BalanceChanged(:final asset):
            if (asset == xelis.xelisAsset) {
              latestBalance = event;
              batcher.queueBalanceChanged();
            }
            return;
          case Rescan() || HistorySynced() || XelisStateInvalidated():
            _runtimeBatcher?.reset();
            _businessBatcher?.reset();
          default:
            break;
        }
        unawaited(enqueue(event));
      },
      onError: (Object error, StackTrace stack) {
        if (!current()) return;
        Logging.instance.e(
          'Xelis event stream failed',
          error: error,
          stackTrace: stack,
        );
        recoverEventChannel(isRuntime: isRuntime);
      },
      onDone: () {
        if (!current()) return;
        recoverEventChannel(isRuntime: isRuntime);
      },
    );
  }

  void recoverEventChannel({required bool isRuntime}) {
    if (!isRuntime) _businessEventsFailed = true;
    scheduleReconnect();
  }

  void scheduleReconnect() {
    if (exitInProgress || wallet == null || _reconnectTimer?.isActive == true) {
      return;
    }
    final handle = wallet!;
    final session = sessionGeneration;
    final seconds = 1 << (_retryAttempt++).clamp(0, 5);
    _reconnectTimer = Timer(Duration(seconds: seconds), () async {
      if (!isCurrentSession(handle, session)) return;
      try {
        await connect();
      } catch (error, stack) {
        Logging.instance.e(
          'Xelis reconnect failed',
          error: error,
          stackTrace: stack,
        );
        if (isCurrentSession(handle, session)) scheduleReconnect();
      }
    });
  }

  List<FilterOperation> get standardReceivingAddressFilters => [
    FilterCondition.equalTo(property: r"type", value: info.mainAddressType),
    const FilterCondition.equalTo(
      property: r"subType",
      value: AddressSubType.receiving,
    ),
  ];

  List<FilterOperation> get standardChangeAddressFilters => [
    FilterCondition.equalTo(property: r"type", value: info.mainAddressType),
    const FilterCondition.equalTo(
      property: r"subType",
      value: AddressSubType.change,
    ),
  ];

  static Future<bool> checkWalletExists(String walletId) async {
    final xelisDir = await StackFileSystem.applicationXelisDirectory();
    // Opening must reject the same aliases and unexpected files as deletion.
    return await xelisWalletDirectory(xelisDir, walletId) != null;
  }

  @override
  Future<void> open() async {
    while (exitInProgress) {
      await Future<void>.delayed(const Duration(milliseconds: 500));
    }

    try {
      await init();
      await connect();
    } catch (e) {
      // Logging.instance.log(
      //   "Failed to start sync: $e",
      //   level: LogLevel.Error,
      // );
      rethrow;
    }
    unawaited(refresh());
  }

  bool exitInProgress = false;

  /// Called after session invalidation, before releasing the native handle.
  Future<void> drainSessionOperations() async {}

  @override
  Future<void> exit() async {
    if (exitInProgress) {
      while (exitInProgress) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }
      return;
    }
    exitInProgress = true;
    ++sessionGeneration;
    ++_connectionGeneration;
    _reconnectTimer?.cancel();
    _businessBatcher?.reset();
    _businessBatcher = null;
    _runtimeBatcher?.reset();
    _runtimeBatcher = null;
    Object? firstError;
    StackTrace? firstStack;
    Future<void> attempt(Future<void> Function() operation) async {
      try {
        await operation();
      } catch (error, stack) {
        firstError ??= error;
        firstStack ??= stack;
      }
    }

    try {
      await drainSessionOperations();
      await _connectionMutex.protect(() async {
        timer?.cancel();
        timer = null;
        final runtime = _runtimeEvents;
        final business = _businessEvents;
        _runtimeEvents = null;
        _businessEvents = null;
        if (runtime != null) await attempt(runtime.cancel);
        if (business != null) await attempt(business.cancel);
      });
      await _eventWork;
      await refreshMutex.protect(() async {
        final handle = wallet;
        wallet = null;
        if (handle != null) await attempt(() => xelis.closeWallet(handle));
      });
    } finally {
      try {
        await attempt(() => super.exit());
      } finally {
        exitInProgress = false;
      }
    }
    if (firstError != null) Error.throwWithStackTrace(firstError!, firstStack!);
  }

  void invalidSeedLengthCheck(int length) {
    if (!(length == 25)) {
      throw Exception("Invalid Xelis mnemonic length found: $length");
    }
  }
}

extension XelisTableManagement on LibXelisWallet {
  Future<bool> isTableUpgradeAvailable() async {
    if (kIsWeb) return false;
    final state = await getTableState();
    return state.currentSize != state.desiredSize;
  }

  Future<void> updateTablesToDesiredSize() {
    if (kIsWeb) return Future<void>.value();
    final running = LibXelisWallet._tableGenerationFuture;
    if (running != null) return running;
    final operation = LibXelisWallet._tableGenerationMutex.protect(() async {
      final state = await getTableState();
      if (state.currentSize == state.desiredSize) return;
      // Actual table presence is authoritative. Do not overwrite a preference
      // changed by another wallet while generation was in flight.
      await xelis.updateTables(
        precomputedTablesPath: await getPrecomputedTablesPath(),
        stack_l1Low: state.desiredSize.isLow,
      );
    });
    final shared = operation.whenComplete(() {
      LibXelisWallet._tableGenerationFuture = null;
    });
    LibXelisWallet._tableGenerationFuture = shared;
    return shared;
  }
}

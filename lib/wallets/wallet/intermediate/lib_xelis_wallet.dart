import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:isar_community/isar.dart';
import 'package:mutex/mutex.dart';

import '../../../models/isar/models/blockchain_data/address.dart';
import '../../../utilities/logger.dart';
import '../../../utilities/stack_file_system.dart';
import '../../../wl_gen/interfaces/lib_xelis_interface.dart';
import '../../crypto_currency/intermediate/electrum_currency.dart';
import '../wallet_mixin_interfaces/mnemonic_interface.dart';
import 'external_wallet.dart';

abstract class LibXelisWallet<T extends ElectrumCurrency>
    extends ExternalWallet<T>
    with MnemonicInterface {
  LibXelisWallet(super.currency);

  static const String _kHasFullTablesKey = 'xelis_has_full_tables';
  static const String _kGeneratingTablesKey = 'xelis_generating_tables';
  static const String _kWantsFullTablesKey = 'xelis_wants_full_tables';
  static final _tableGenerationMutex = Mutex();
  static Completer<void>? _tableGenerationCompleter;

  int pruningHeight = 0;

  OpaqueXelisWallet? wallet;

  void checkInitialized() {
    if (wallet == null) {
      throw StateError('libXelisWallet not initialized');
    }
  }

  final syncMutex = Mutex();
  Timer? timer;

  StreamSubscription<void>? _eventSubscription;

  Future<String> getPrecomputedTablesPath() async {
    if (kIsWeb) {
      return "";
    } else {
      final appDir = await StackFileSystem.applicationXelisTableDirectory();
      return "${appDir.path}${Platform.pathSeparator}";
    }
  }

  Future<XelisTableState> getTableState() async {
    final hasFullTables =
        await secureStorageInterface.read(key: _kHasFullTablesKey) == 'true';
    final isGenerating =
        await secureStorageInterface.read(key: _kGeneratingTablesKey) == 'true';
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

  Future<void> handleEvent(Event event) async {}
  Future<void> handleNewTopoHeight(int height);
  Future<void> handleNewTransaction(TransactionEntryWrapper tx);
  Future<void> handleBalanceChanged(BalanceChanged event);
  Future<void> handleRescan(int startTopoheight) async {}
  Future<void> handleOnline() async {}
  Future<void> handleOffline() async {}
  Future<void> handleHistorySynced(int topoheight) async {}
  Future<void> handleNewAsset(NewAsset asset) async {}

  @override
  Future<void> refresh({int? topoheight});

  Future<void> connect() async {
    final node = getCurrentNode();
    try {
      checkInitialized();
      _eventSubscription = libXelis.eventsStream(wallet!).listen(handleEvent);

      Logging.instance.i("Connecting to node: ${node.host}:${node.port}");
      await libXelis.onlineMode(
        wallet!,
        daemonAddress: "${node.host}:${node.port}",
      );
      await super.refresh();
    } catch (e, s) {
      Logging.instance.e(
        "rethrowing error connecting to node: $node",
        error: e,
        stackTrace: s,
      );
      rethrow;
    }
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
    final walletDir = Directory(
      "${xelisDir.path}${Platform.pathSeparator}$walletId",
    );
    // TODO: should we check for certain files within the dir?
    return await walletDir.exists();
  }

  @override
  Future<void> open() async {
    while (exitInProgress) {
      await Future<void>.delayed(const Duration(milliseconds: 500));
    }

    try {
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

  @override
  Future<void> exit() async {
    exitInProgress = true;
    try {
      await refreshMutex.protect(() async {
        timer?.cancel();
        timer = null;

        await _eventSubscription?.cancel();
        _eventSubscription = null;

        if (wallet != null) {
          await libXelis.offlineMode(wallet!);
        }
        await super.exit();
      });
    } finally {
      exitInProgress = false;
    }
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

  Future<void> updateTablesToDesiredSize() async {
    if (kIsWeb) return;

    await Future<void>.delayed(const Duration(seconds: 1));
    if (LibXelisWallet._tableGenerationCompleter != null) {
      try {
        await LibXelisWallet._tableGenerationCompleter!.future;
        return;
      } catch (_) {
        // Previous generation failed, we'll try again
      }
    }

    await LibXelisWallet._tableGenerationMutex.protect(() async {
      // Check again after acquiring mutex
      if (LibXelisWallet._tableGenerationCompleter != null) {
        try {
          await LibXelisWallet._tableGenerationCompleter!.future;
          return;
        } catch (_) {
          // Previous generation failed, we'll try again
        }
      }

      final state = await getTableState();
      if (state.currentSize == state.desiredSize) return;

      LibXelisWallet._tableGenerationCompleter = Completer<void>();
      await setTableState(state.copyWith(isGenerating: true));

      try {
        Logging.instance.i("Xelis: Generating large tables in background");

        final tablePath = await getPrecomputedTablesPath();
        await libXelis.updateTables(
          precomputedTablesPath: tablePath,
          l1Low: state.desiredSize.isLow,
        );

        await setTableState(
          XelisTableState(
            isGenerating: false,
            currentSize: state.desiredSize,
            desiredSize: state.desiredSize,
          ),
        );

        Logging.instance.i("Xelis: Table upgrade done");
        LibXelisWallet._tableGenerationCompleter!.complete();
      } catch (e) {
        // Logging.instance.log(
        //   "Failed to update tables: $e\n$s",
        //   level: LogLevel.Error,
        // );
        await setTableState(state.copyWith(isGenerating: false));

        LibXelisWallet._tableGenerationCompleter!.completeError(e);
      } finally {
        if (!LibXelisWallet._tableGenerationCompleter!.isCompleted) {
          LibXelisWallet._tableGenerationCompleter!.completeError(
            Exception('Table generation abandoned'),
          );
        }
        LibXelisWallet._tableGenerationCompleter = null;
      }
    });
  }
}

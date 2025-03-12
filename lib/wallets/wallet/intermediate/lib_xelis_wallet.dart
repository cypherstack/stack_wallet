import 'package:isar/isar.dart';
import '../../../models/isar/models/blockchain_data/address.dart';
import '../../crypto_currency/intermediate/electrum_currency.dart';
import '../wallet.dart';
import '../wallet_mixin_interfaces/mnemonic_interface.dart';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:json_annotation/json_annotation.dart';

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:decimal/decimal.dart';
import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';

import 'package:xelis_flutter/src/api/network.dart' as x_network;
import 'package:xelis_flutter/src/api/wallet.dart' as x_wallet;
import 'package:xelis_dart_sdk/xelis_dart_sdk.dart' as xelis_sdk;

import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

import '../../../utilities/stack_file_system.dart';
import '../../../models/isar/models/blockchain_data/transaction.dart';
import '../../../models/isar/models/blockchain_data/v2/input_v2.dart';
import '../../../models/isar/models/blockchain_data/v2/output_v2.dart';
import '../../../models/isar/models/blockchain_data/v2/transaction_v2.dart';

import '../../../models/node_model.dart';
import '../../../models/paymint/fee_object_model.dart';
import '../../../models/balance.dart';
import '../../../utilities/amount/amount.dart';
import '../../../utilities/logger.dart';
import '../../crypto_currency/crypto_currency.dart';
import '../../models/tx_data.dart';

import 'package:isar/isar.dart';
import 'package:mutex/mutex.dart';
import 'package:stack_wallet_backup/generate_password.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'external_wallet.dart';

enum XelisTableSize {
  low,
  full;

  bool get isLow => this == XelisTableSize.low;
  
  static XelisTableSize get platformDefault {
    if (kIsWeb) {
      return XelisTableSize.low;
    }
    return XelisTableSize.full;
  }
}

class XelisTableState {
  final bool isGenerating;
  final XelisTableSize currentSize;
  final XelisTableSize _desiredSize;

  XelisTableSize get desiredSize {
    if (kIsWeb) {
      return XelisTableSize.low;
    }
    return _desiredSize;
  }

  const XelisTableState({
    this.isGenerating = false,
    this.currentSize = XelisTableSize.low,
    XelisTableSize desiredSize = XelisTableSize.full,
  }) : _desiredSize = desiredSize;

  XelisTableState copyWith({
    bool? isGenerating,
    XelisTableSize? currentSize,
    XelisTableSize? desiredSize,
  }) {
    return XelisTableState(
      isGenerating: isGenerating ?? this.isGenerating,
      currentSize: currentSize ?? this.currentSize,
      desiredSize: kIsWeb ? XelisTableSize.low : (desiredSize ?? this._desiredSize),
    );
  }

  factory XelisTableState.fromJson(Map<String, dynamic> json) {
    return XelisTableState(
      isGenerating: json['isGenerating'] as bool,
      currentSize: XelisTableSize.values[json['currentSize'] as int],
      desiredSize: XelisTableSize.values[json['desiredSize'] as int],
    );
  }

  Map<String, dynamic> toJson() => {
    'isGenerating': isGenerating,
    'currentSize': currentSize.index,
    'desiredSize': _desiredSize.index,
  };
}

extension XelisNetworkConversion on CryptoCurrencyNetwork {
  x_network.Network get xelisNetwork {
    switch (this) {
      case CryptoCurrencyNetwork.main:
        return x_network.Network.mainnet;
      case CryptoCurrencyNetwork.test:
        return x_network.Network.testnet;
      default:
        throw ArgumentError('Unsupported network type for Xelis: $this');
    }
  }
}

extension CryptoCurrencyNetworkConversion on x_network.Network {
  CryptoCurrencyNetwork get cryptoCurrencyNetwork {
    switch (this) {
      case x_network.Network.mainnet:
        return CryptoCurrencyNetwork.main;
      case x_network.Network.testnet:
        return CryptoCurrencyNetwork.test;
      default:
        throw ArgumentError('Unsupported Xelis network type: $this');
    }
  }
}

sealed class Event {
  const Event();
}

final class NewTopoheight extends Event {
  final int height;
  const NewTopoheight(this.height);
}

final class NewAsset extends Event {
  final xelis_sdk.AssetData asset;
  const NewAsset(this.asset);
}

final class NewTransaction extends Event {
  final xelis_sdk.TransactionEntry transaction;
  const NewTransaction(this.transaction);
}

final class BalanceChanged extends Event {
  final xelis_sdk.BalanceChangedEvent event;
  const BalanceChanged(this.event);
}

final class Rescan extends Event {
  final int startTopoheight;
  const Rescan(this.startTopoheight);
}

final class Online extends Event {
  const Online();
}

final class Offline extends Event {
  const Offline();
}

final class HistorySynced extends Event {
  final int topoheight;
  const HistorySynced(this.topoheight);
}

abstract class LibXelisWallet<T extends ElectrumCurrency> extends ExternalWallet<T>
    with MnemonicInterface {
  LibXelisWallet(super.currency);

  static const String _kHasFullTablesKey = 'xelis_has_full_tables';
  static const String _kGeneratingTablesKey = 'xelis_generating_tables';
  static const String _kWantsFullTablesKey = 'xelis_wants_full_tables';
  static bool _isAnyWalletGeneratingTables = false;
  static final _initMutex = Mutex();
  static final _tableGenerationMutex = Mutex();
  static Completer<void>? _tableGenerationCompleter;

  x_wallet.XelisWallet? libXelisWallet;

  x_wallet.XelisWallet? get wallet => libXelisWallet;
  set wallet(x_wallet.XelisWallet? newWallet) {
    if (newWallet == null && libXelisWallet != null) {
      throw StateError('Cannot set wallet to null after initialization');
    }
    libXelisWallet = newWallet;
  }

  void checkInitialized() {
    if (libXelisWallet == null) {
      throw StateError('libXelisWallet not initialized');
    }
  }

  final syncMutex = Mutex();
  NodeModel? _xelisNode;
  Timer? timer;
  String? tablePath;

  StreamSubscription<void>? _eventSubscription;

  Future<String> getPrecomputedTablesPath() async {
    if (kIsWeb) {
      return "";
    } else {
      final appDir = await getApplicationSupportDirectory();
      return "${appDir.path}/";
    }
  }

  Future<XelisTableState> getTableState() async {
    final hasFullTables = await secureStorageInterface.read(key: _kHasFullTablesKey) == 'true';
    final isGenerating = await secureStorageInterface.read(key: _kGeneratingTablesKey) == 'true';
    final wantsFull = await secureStorageInterface.read(key: _kWantsFullTablesKey) != 'false';

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

  Stream<Event> convertRawEvents() async* {
    checkInitialized();
    final rawEventStream = libXelisWallet!.eventsStream();

    await for (final rawData in rawEventStream) {
      final json = jsonDecode(rawData);
      try {
        final eventType = xelis_sdk.WalletEvent.fromStr(json['event'] as String);
        switch (eventType) {
          case xelis_sdk.WalletEvent.newTopoHeight:
            yield NewTopoheight(json['data']['topoheight'] as int);
          case xelis_sdk.WalletEvent.newAsset:
            yield NewAsset(
                xelis_sdk.AssetData.fromJson(json['data'] as Map<String, dynamic>));
          case xelis_sdk.WalletEvent.newTransaction:
            yield NewTransaction(
                xelis_sdk.TransactionEntry.fromJson(
                    json['data'] as Map<String, dynamic>));
          case xelis_sdk.WalletEvent.balanceChanged:
            yield BalanceChanged(
                xelis_sdk.BalanceChangedEvent.fromJson(
                    json['data'] as Map<String, dynamic>));
          case xelis_sdk.WalletEvent.rescan:
            yield Rescan(json['data']['start_topoheight'] as int);
          case xelis_sdk.WalletEvent.online:
            yield const Online();
          case xelis_sdk.WalletEvent.offline:
            yield const Offline();
          case xelis_sdk.WalletEvent.historySynced:
            yield HistorySynced(json['data']['topoheight'] as int);
        }
      } catch (e, s) {
        Logging.instance.log(
          "Error processing wallet event: $e\n$s",
          level: LogLevel.Error,
        );
        continue;
      }
    }
  }

  Future<void> handleEvent(Event event) async {}
  Future<void> handleNewTopoHeight(int height);
  Future<void> handleNewTransaction(xelis_sdk.TransactionEntry tx);
  Future<void> handleBalanceChanged(xelis_sdk.BalanceChangedEvent event);
  Future<void> handleRescan(int startTopoheight) async {}
  Future<void> handleOnline() async {}
  Future<void> handleOffline() async {}
  Future<void> handleHistorySynced(int topoheight) async {}
  Future<void> handleNewAsset(xelis_sdk.AssetData asset) async {}

  Future<void> refresh({int? topoheight});

  Future<void> connect() async {
    try {
      _eventSubscription =
        convertRawEvents().listen(handleEvent);

      final node = getCurrentNode();
      Logging.instance.log(
        "Connecting to node: ${node.host}:${node.port}",
        level: LogLevel.Info,
      );
      await libXelisWallet!.onlineMode(
        daemonAddress: "${node.host}:${node.port}"
      );
      await super.refresh();
    } catch (e, s) {
      Logging.instance.log(
        "Error connecting to node: $e\n$s",
        level: LogLevel.Error,
      );
      rethrow;
    }
  }

  List<FilterOperation> get standardReceivingAddressFilters => [
        FilterCondition.equalTo(
          property: r"type",
          value: info.mainAddressType,
        ),
        const FilterCondition.equalTo(
          property: r"subType",
          value: AddressSubType.receiving,
        ),
      ];

  List<FilterOperation> get standardChangeAddressFilters => [
        FilterCondition.equalTo(
          property: r"type",
          value: info.mainAddressType,
        ),
        const FilterCondition.equalTo(
          property: r"subType",
          value: AddressSubType.change,
        ),
      ];

  @override
  Future<void> open() async {
    bool wasNull = false;

    if (libXelisWallet == null) {
      wasNull = true;
      final tablePath = await getPrecomputedTablesPath();
      final tableState = await getTableState();
      final appDir = await getApplicationDocumentsDirectory();
      final String name = walletId;
      final String directory = appDir.path;
      final password = await secureStorageInterface.read(
        key: Wallet.mnemonicPassphraseKey(walletId: info.walletId),
      );

      await LibXelisWallet._initMutex.protect(() async {
        try {
          final needsCreation = await secureStorageInterface.read(
            key: '_${walletId}_needs_creation',
          );

          final needsRestoration = await secureStorageInterface.read(
            key: '_${walletId}_needs_restoration',
          );

          libXelisWallet = await syncMutex.protect(() async {
            if (needsCreation == 'true') {
              debugPrint("Xelis: creating new wallet");
              final wallet = await x_wallet.createXelisWallet(
                name: name,
                directory: directory,
                password: password!,
                network: cryptoCurrency.network.xelisNetwork,
                precomputedTablesPath: tablePath,
                l1Low: tableState.currentSize.isLow
              );

              final mnemonic = await wallet.getSeed();
              await secureStorageInterface.write(
                key: Wallet.mnemonicKey(walletId: walletId),
                value: mnemonic.trim(),
              );
              
              await secureStorageInterface.delete(
                key: '_${walletId}_needs_creation',
              );

              return wallet;
            } else if (needsRestoration == 'true') {
              final mnemonic = await getMnemonic();
              final seedLength = mnemonic.trim().split(" ").length;

              invalidSeedLengthCheck(seedLength);

              debugPrint("Xelis: recovering wallet");
              final wallet = await x_wallet.createXelisWallet(
                name: name,
                directory: directory,
                password: password!,
                seed: mnemonic.trim(),
                network: cryptoCurrency.network.xelisNetwork,
                precomputedTablesPath: tablePath,
                l1Low: tableState.currentSize.isLow
              );

              await secureStorageInterface.write(
                key: Wallet.mnemonicKey(walletId: walletId),
                value: mnemonic.trim(),
              );
              
              await secureStorageInterface.delete(
                key: '_${walletId}_needs_restoration',
              );

              return wallet;
            } else {
              debugPrint("Xelis: opening existing wallet");
              return await x_wallet.openXelisWallet(
                name: name,
                directory: directory,
                password: password!,
                network: cryptoCurrency.network.xelisNetwork,
                precomputedTablesPath: tablePath,
                l1Low: tableState.currentSize.isLow,
              );
            }
          });
        } catch (e, s) {
          Logging.instance.log(
            "Failed to open/create wallet: $e\n$s",
            level: LogLevel.Error,
          );
          rethrow;
        }
      });
    
      debugPrint("Checking for upgradability");
      if (await isTableUpgradeAvailable()) {
        debugPrint("Generating large tables in background");
        unawaited(updateTablesToDesiredSize());
      }
    }

    final newReceivingAddress = await getCurrentReceivingAddress() ??
      Address(
        walletId: walletId,
        derivationIndex: 0,
        derivationPath: null,
        value: libXelisWallet!.getAddressStr(),
        publicKey: [],
        type: AddressType.xelis,
        subType: AddressSubType.receiving,
      );
    await mainDB.updateOrPutAddresses([newReceivingAddress]);

    if (info.cachedReceivingAddress != newReceivingAddress.value) {
      await info.updateReceivingAddress(
        newAddress: newReceivingAddress.value,
        isar: mainDB.isar,
      );
    }

    if (wasNull) {
      try {
        await connect();
      } catch (e) {
        Logging.instance.log(
          "Failed to start sync: $e",
          level: LogLevel.Error,
        );
        rethrow;
      }
    }

    unawaited(refresh());
  }

  @override
  Future<void> exit() async {
    await refreshMutex.protect(() async {
      timer?.cancel();
      timer = null;

      await _eventSubscription?.cancel();
      _eventSubscription = null;

      await libXelisWallet?.offlineMode();
      libXelisWallet?.dispose();
      libXelisWallet = null;
      
      await super.exit();
    });
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
    
    await Future.delayed(const Duration(seconds: 1));
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
        final tablePath = await getPrecomputedTablesPath();
        await x_wallet.updateTables(
          precomputedTablesPath: tablePath,
          l1Low: state.desiredSize.isLow,
        );

        await setTableState(XelisTableState(
          isGenerating: false,
          currentSize: state.desiredSize,
          desiredSize: state.desiredSize,
        ));

        debugPrint("Table upgrade done");
        LibXelisWallet._tableGenerationCompleter!.complete();
      } catch (e, s) {
        Logging.instance.log(
          "Failed to update tables: $e\n$s",
          level: LogLevel.Error,
        );
        await setTableState(state.copyWith(isGenerating: false));
        
        LibXelisWallet._tableGenerationCompleter!.completeError(e);
      } finally {
        if (!LibXelisWallet._tableGenerationCompleter!.isCompleted) {
          LibXelisWallet._tableGenerationCompleter!.completeError(
            Exception('Table generation abandoned')
          );
        }
        LibXelisWallet._tableGenerationCompleter = null;
      }
    });
  }
}
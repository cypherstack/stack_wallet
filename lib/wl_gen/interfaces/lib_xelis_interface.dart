import 'package:flutter/foundation.dart';

import '../../providers/progress_report/xelis_table_progress_provider.dart';
import '../../utilities/dynamic_object.dart';
import '../../wallets/crypto_currency/crypto_currency.dart';
import 'xelis_types.dart';

export '../generated/lib_xelis_interface_impl.dart';
export 'xelis_types.dart';

abstract class LibXelisInterface {
  const LibXelisInterface();

  String get xelisAsset;

  Future<void> initRustLib();

  Future<void> setupRustLogger();

  void startListeningToRustLogs();

  Stream<XelisTableProgressState> createProgressReportStream();

  bool isAddressValid({
    required String address,
    required CryptoCurrencyNetwork network,
  });

  bool validateSeedWord(String word);

  Future<XelisEventSubscription> subscribeRuntimeEvents(
    OpaqueXelisWallet wallet,
  );
  Future<XelisEventSubscription> subscribeBusinessEvents(
    OpaqueXelisWallet wallet,
  );

  Future<void> closeWallet(OpaqueXelisWallet wallet);

  Future<void> onlineMode(
    OpaqueXelisWallet wallet, {
    required String daemonAddress,
  });
  Future<void> offlineMode(OpaqueXelisWallet wallet);

  Future<void> updateTables({
    required String precomputedTablesPath,
    required bool stack_l1Low,
  });

  Future<bool> hasTables({
    required String precomputedTablesPath,
    required bool stack_l1Low,
  });

  Future<String> getSeed(OpaqueXelisWallet wallet);

  Future<OpaqueXelisWallet> createXelisWallet(
    String walletId, {
    required String name,
    required String directory,
    required String password,
    required CryptoCurrencyNetwork network,
    String? seed,
    String? privateKey,
    String? precomputedTablesPath,
    bool? stack_l1Low,
  });

  Future<OpaqueXelisWallet> openXelisWallet(
    String walletId, {
    required String name,
    required String directory,
    required String password,
    required CryptoCurrencyNetwork network,
    String? precomputedTablesPath,
    bool? stack_l1Low,
  });

  String getAddress(OpaqueXelisWallet wallet);

  Future<XelisDaemonSnapshot> getDaemonInfo(OpaqueXelisWallet wallet);

  Future<bool> isOnline(OpaqueXelisWallet wallet);
  Future<bool> isSyncing(OpaqueXelisWallet wallet);

  Future<void> rescan(OpaqueXelisWallet wallet, {required BigInt topoheight});

  Future<List<TransactionEntryWrapper>> allHistory(
    OpaqueXelisWallet wallet, {
    BigInt? minTopoheight,
  });

  Future<XelisBroadcastOutcome> broadcastTransaction(
    OpaqueXelisWallet wallet, {
    required XelisPreparedTransaction transaction,
  });

  Future<BigInt> estimateFees(
    OpaqueXelisWallet wallet, {
    required List<XelisTransfer> transfers,
  });

  Future<XelisPreparedTransaction> prepareTransfers(
    OpaqueXelisWallet wallet, {
    required List<XelisTransfer> transfers,
  });

  Future<XelisPreparedTransaction> prepareTransferAll(
    OpaqueXelisWallet wallet, {
    required String destination,
  });

  Future<void> discardPreparedTransaction(
    OpaqueXelisWallet wallet, {
    required XelisPreparedTransaction transaction,
  });

  Future<BigInt> getXelisBalanceRaw(OpaqueXelisWallet wallet);

  Future<bool> testDaemonConnection(
    String endPoint,
    bool useSSL,
    CryptoCurrencyNetwork network,
  );
}

final class XelisEventSubscription {
  const XelisEventSubscription({required this.events, required this.cancel});

  final Stream<Event> events;
  final Future<void> Function() cancel;
}

// =============================================================================
// ============== stupid =======================================================

final class OpaqueXelisWallet {
  final Object _value;
  const OpaqueXelisWallet(this._value);
  T get<T>() => _value as T;
}

class TransactionEntryWrapper {
  final Object _value;

  final EntryWrapper entryType;

  final String hash;
  final DateTime? timestamp;
  final BigInt? topoheight;

  TransactionEntryWrapper(
    this._value, {
    required this.entryType,
    required this.hash,
    required this.timestamp,
    required this.topoheight,
  });

  T getValue<T>() => _value is T
      ? _value as T
      : throw Exception(
          "Type mismatch: ${_value.runtimeType} is not ${T.runtimeType}",
        );
}

sealed class EntryWrapper {
  const EntryWrapper();
}

class CoinbaseEntryWrapper extends EntryWrapper {
  final BigInt reward;
  const CoinbaseEntryWrapper({required this.reward});
}

class BurnEntryWrapper extends EntryWrapper {
  final BigInt amount;
  final BigInt fee;
  final String asset;

  const BurnEntryWrapper({
    required this.amount,
    required this.fee,
    required this.asset,
  });
}

class IncomingEntryWrapper extends EntryWrapper {
  final String from;
  final List<({BigInt amount, String asset, Map<String, dynamic>? extraData})>
  transfers;

  const IncomingEntryWrapper({required this.from, required this.transfers});
}

class OutgoingEntryWrapper extends EntryWrapper {
  final BigInt nonce;
  final BigInt fee;
  final List<
    ({
      String destination,
      BigInt amount,
      String asset,
      Map<String, dynamic>? extraData,
    })
  >
  transfers;

  const OutgoingEntryWrapper({
    required this.nonce,
    required this.fee,
    required this.transfers,
  });
}

class UnknownEntryWrapper extends EntryWrapper {}

/// Passive history of non-transfer actions. Only exact XEL movements and fees
/// are projected; this does not enable these actions in Stack's send UI.
class XelisActionEntryWrapper extends EntryWrapper {
  const XelisActionEntryWrapper({
    required this.kind,
    required this.spent,
    required this.received,
    required this.fee,
    this.nonce,
  });

  final String kind;
  final BigInt spent;
  final BigInt received;
  final BigInt fee;
  final BigInt? nonce;
}

// =============================================================================

// =============================================================================
// ============== moved from lib_xelis_wallet.dart =============================
enum XelisTableSize {
  low,
  full;

  // TODO: add more granular table size management interface
  // for now, just patching the old system into the new FFI API
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
      desiredSize: kIsWeb ? XelisTableSize.low : (desiredSize ?? _desiredSize),
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

sealed class Event {
  const Event();
}

final class NewTopoheight extends Event {
  final BigInt height;

  const NewTopoheight(this.height);
}

final class NewAsset extends Event {
  // final xelis_sdk.AssetData asset;
  final String name;
  final int decimals;

  // if used in later, this will probably need to be deconstructed in order
  // to keep conditional import of xelis working
  final DynamicObject? maxSupply;

  NewAsset(this.name, this.decimals, this.maxSupply);
}

final class NewTransaction extends Event {
  // final xelis_sdk.TransactionEntry transaction;
  final TransactionEntryWrapper transaction;
  const NewTransaction(this.transaction);
}

final class BalanceChanged extends Event {
  // final xelis_sdk.BalanceChangedEvent event;
  final String asset;
  final BigInt balance;

  const BalanceChanged(this.asset, this.balance);
}

final class Rescan extends Event {
  final BigInt startTopoheight;

  const Rescan(this.startTopoheight);
}

final class Online extends Event {
  const Online();
}

final class Offline extends Event {
  const Offline();
}

final class HistorySynced extends Event {
  final BigInt topoheight;
  const HistorySynced(this.topoheight);
}

final class XelisStateInvalidated extends Event {
  const XelisStateInvalidated({this.failure});
  final Object? failure;
}

final class XelisSyncIssue extends Event {
  const XelisSyncIssue(this.failure);
  final Object failure;
}

final class XelisChannelClosed extends Event {
  const XelisChannelClosed(this.failure, {required this.isRuntime});
  final Object failure;
  final bool isRuntime;
}

// =============================================================================

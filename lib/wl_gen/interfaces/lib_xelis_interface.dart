import 'package:flutter/foundation.dart';

import '../../providers/progress_report/xelis_table_progress_provider.dart';
import '../../wallets/crypto_currency/crypto_currency.dart';

export '../generated/lib_xelis_interface_impl.dart';

abstract class LibXelisInterface {
  String get xelisAsset;

  bool walletInstanceExists(String walletId);

  Future<void> initRustLib();

  Future<void> setupRustLogger();

  void startListeningToRustLogs();

  Stream<XelisTableProgressState> createProgressReportStream();

  bool isAddressValid({required String address});

  bool validateSeedWord(String word);

  Stream<Event> eventsStream(String walletId);

  Future<void> onlineMode(String walletId, {required String daemonAddress});
  Future<void> offlineMode(String walletId);

  Future<void> updateTables({
    required String precomputedTablesPath,
    required bool l1Low,
  });

  Future<String> getSeed(String walletId);

  Future<void> createXelisWallet(
    String walletId, {
    required String name,
    required String directory,
    required String password,
    required CryptoCurrencyNetwork network,
    String? seed,
    String? privateKey,
    String? precomputedTablesPath,
    bool? l1Low,
  });

  Future<void> openXelisWallet(
    String walletId, {
    required String name,
    required String directory,
    required String password,
    required CryptoCurrencyNetwork network,
    String? precomputedTablesPath,
    bool? l1Low,
  });

  String getAddress(String walletId);

  Future<String> getDaemonInfo(String walletId);

  Future<bool> isOnline(String walletId);

  Future<void> rescan(String walletId, {required BigInt topoheight});

  Future<List<TransactionEntryWrapper>> allHistory(String walletId);

  Future<void> broadcastTransaction(String walletId, {required String txHash});

  Future<String> estimateFees(
    String walletId, {
    required List<WrappedTransfer> transfers,
  });

  Future<String> createTransfersTransaction(
    String walletId, {
    required List<WrappedTransfer> transfers,
  });

  Future<String> formatCoin(
    String walletId, {
    required BigInt atomicAmount,
    String? assetHash,
  });

  Future<int> getAssetDecimals(String walletId, {required String asset});

  Future<BigInt> getXelisBalanceRaw(String walletId);

  Future<bool> hasXelisBalance(String walletId);
}

// =============================================================================
// ============== stupid =======================================================
class WrappedTransfer {
  final double floatAmount;
  final String strAddress;
  final String assetHash;
  final String? extraData;

  const WrappedTransfer({
    required this.floatAmount,
    required this.strAddress,
    required this.assetHash,
    this.extraData,
  });

  @override
  int get hashCode =>
      floatAmount.hashCode ^
      strAddress.hashCode ^
      assetHash.hashCode ^
      extraData.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WrappedTransfer &&
          runtimeType == other.runtimeType &&
          floatAmount == other.floatAmount &&
          strAddress == other.strAddress &&
          assetHash == other.assetHash &&
          extraData == other.extraData;
}

class TransactionEntryWrapper {
  final Object _value;

  final EntryWrapper entryType;

  final String hash;
  final DateTime? timestamp;
  final int topoheight;

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
  final int reward;
  const CoinbaseEntryWrapper({required this.reward});
}

class BurnEntryWrapper extends EntryWrapper {
  final int amount;
  final int fee;
  final String asset;

  const BurnEntryWrapper({
    required this.amount,
    required this.fee,
    required this.asset,
  });
}

class IncomingEntryWrapper extends EntryWrapper {
  final String from;
  final List<({int amount, String asset, Map<String, dynamic>? extraData})>
  transfers;

  const IncomingEntryWrapper({required this.from, required this.transfers});
}

class OutgoingEntryWrapper extends EntryWrapper {
  final int nonce;
  final int fee;
  final List<
    ({
      String destination,
      int amount,
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

// =============================================================================

// =============================================================================
// ============== moved from lib_xelis_wallet.dart =============================
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
  final int height;

  const NewTopoheight(this.height);
}

final class NewAsset extends Event {
  // final xelis_sdk.AssetData asset;
  final String name;
  final int decimals;
  final int? maxSupply;

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
  final int balance;

  const BalanceChanged(this.asset, this.balance);
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

// =============================================================================

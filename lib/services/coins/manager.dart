import 'dart:async';

import 'package:decimal/decimal.dart';
import 'package:epicpay/models/models.dart';
import 'package:epicpay/services/coins/coin_service.dart';
import 'package:epicpay/services/event_bus/events/global/node_connection_status_changed_event.dart';
import 'package:epicpay/services/event_bus/events/global/updated_in_background_event.dart';
import 'package:epicpay/services/event_bus/global_event_bus.dart';
import 'package:epicpay/utilities/enums/coin_enum.dart';
import 'package:epicpay/utilities/logger.dart';
import 'package:event_bus/event_bus.dart';
import 'package:flutter/material.dart';

class Manager with ChangeNotifier {
  final CoinServiceAPI _currentWallet;
  StreamSubscription<dynamic>? _backgroundRefreshListener;
  StreamSubscription<dynamic>? _nodeStatusListener;

  /// optional eventbus parameter for testing only
  Manager(this._currentWallet, [EventBus? globalEventBusForTesting]) {
    final bus = globalEventBusForTesting ?? GlobalEventBus.instance;
    _backgroundRefreshListener = bus.on<UpdatedInBackgroundEvent>().listen(
      (event) async {
        if (event.walletId == walletId) {
          notifyListeners();
          Logging.instance.log(
              "UpdatedInBackgroundEvent activated notifyListeners() in Manager instance $hashCode $walletName with: ${event.message}",
              level: LogLevel.Info);
        }
      },
    );

    _nodeStatusListener = bus.on<NodeConnectionStatusChangedEvent>().listen(
      (event) async {
        if (event.walletId == walletId) {
          notifyListeners();
          Logging.instance.log(
              "NodeConnectionStatusChangedEvent activated notifyListeners() in Manager instance $hashCode $walletName with: ${event.newStatus}",
              level: LogLevel.Info);
        }
      },
    );
  }

  bool _isActiveWallet = false;
  bool get isActiveWallet => _isActiveWallet;
  set isActiveWallet(bool isActive) {
    if (_isActiveWallet != isActive) {
      _isActiveWallet = isActive;
      _currentWallet.onIsActiveWalletChanged?.call(isActive);
      debugPrint(
          "wallet ID: ${_currentWallet.walletId} is active set to: $isActive");
    } else {
      debugPrint("wallet ID: ${_currentWallet.walletId} is still: $isActive");
    }
  }

  Future<void> updateNode(bool shouldRefresh) async {
    await _currentWallet.updateNode(shouldRefresh);
  }
  // Function(bool isActive)? onIsActiveWalletChanged;

  CoinServiceAPI get wallet => _currentWallet;

  bool get hasBackgroundRefreshListener => _backgroundRefreshListener != null;

  Coin get coin => _currentWallet.coin;

  bool get isRefreshing => _currentWallet.isRefreshing;

  bool get shouldAutoSync => _currentWallet.shouldAutoSync;
  set shouldAutoSync(bool shouldAutoSync) =>
      _currentWallet.shouldAutoSync = shouldAutoSync;

  bool get isFavorite => _currentWallet.isFavorite;

  set isFavorite(bool markFavorite) {
    _currentWallet.isFavorite = markFavorite;
    notifyListeners();
  }

  @override
  dispose() async {
    await exitCurrentWallet();
    super.dispose();
  }

  Future<Map<String, dynamic>> prepareSend({
    required String address,
    required int satoshiAmount,
    Map<String, dynamic>? args,
  }) async {
    try {
      final txInfo = await _currentWallet.prepareSend(
        address: address,
        satoshiAmount: satoshiAmount,
        args: args,
      );
      // notifyListeners();
      return txInfo;
    } catch (e) {
      // rethrow to pass error in alert
      rethrow;
    }
  }

  Future<String> confirmSend({required Map<String, dynamic> txData}) async {
    try {
      final txid = await _currentWallet.confirmSend(txData: txData);

      txData["txid"] = txid;
      await _currentWallet.updateSentCachedTxData(txData);

      notifyListeners();
      return txid;
    } catch (e) {
      // rethrow to pass error in alert
      rethrow;
    }
  }

  /// create and submit tx to network
  ///
  /// Returns the txid of the sent tx
  /// will throw exceptions on failure
  Future<String> send({
    required String toAddress,
    required int amount,
    Map<String, String> args = const {},
  }) async {
    try {
      final txid = await _currentWallet.send(
        toAddress: toAddress,
        amount: amount,
        args: args,
      );
      notifyListeners();
      return txid;
    } catch (e, s) {
      Logging.instance.log("$e\n $s", level: LogLevel.Error);
      // rethrow to pass error in alert
      rethrow;
    }
  }

  Future<FeeObject> get fees => _currentWallet.fees;
  Future<int> get maxFee => _currentWallet.maxFee;

  Future<String> get currentReceivingAddress =>
      _currentWallet.currentReceivingAddress;
  // Future<String> get currentLegacyReceivingAddress =>
  //     _currentWallet.currentLegacyReceivingAddress;

  Future<Decimal> get availableBalance async {
    _cachedAvailableBalance = await _currentWallet.availableBalance;
    return _cachedAvailableBalance;
  }

  Decimal _cachedAvailableBalance = Decimal.zero;
  Decimal get cachedAvailableBalance => _cachedAvailableBalance;

  Future<Decimal> get pendingBalance => _currentWallet.pendingBalance;
  Future<Decimal> get balanceMinusMaxFee => _currentWallet.balanceMinusMaxFee;

  Future<Decimal> get totalBalance async {
    _cachedTotalBalance = await _currentWallet.totalBalance;
    return _cachedTotalBalance;
  }

  Decimal _cachedTotalBalance = Decimal.zero;
  Decimal get cachedTotalBalance => _cachedTotalBalance;

  // Future<Decimal> get fiatBalance async {
  //   final balance = await _currentWallet.availableBalance;
  //   final price = await _currentWallet.basePrice;
  //   return balance * price;
  // }
  //
  // Future<Decimal> get fiatTotalBalance async {
  //   final balance = await _currentWallet.totalBalance;
  //   final price = await _currentWallet.basePrice;
  //   return balance * price;
  // }

  Future<List<String>> get allOwnAddresses => _currentWallet.allOwnAddresses;

  Future<TransactionData> get transactionData => _currentWallet.transactionData;
  Future<List<UtxoObject>> get unspentOutputs => _currentWallet.unspentOutputs;

  Future<void> refresh() async {
    await _currentWallet.refresh();
    notifyListeners();
  }

  // setter for updating on rename
  set walletName(String newName) {
    if (newName != _currentWallet.walletName) {
      _currentWallet.walletName = newName;
      notifyListeners();
    }
  }

  String get walletName => _currentWallet.walletName;
  String get walletId => _currentWallet.walletId;

  bool validateAddress(String address) =>
      _currentWallet.validateAddress(address);

  Future<List<String>> get mnemonic => _currentWallet.mnemonic;

  Future<bool> testNetworkConnection() =>
      _currentWallet.testNetworkConnection();

  Future<void> initializeNew() => _currentWallet.initializeNew();
  Future<void> initializeExisting() => _currentWallet.initializeExisting();
  Future<void> recoverFromMnemonic({
    required String mnemonic,
    required int maxUnusedAddressGap,
    required int maxNumberOfIndexesToCheck,
    required int height,
  }) async {
    try {
      await _currentWallet.recoverFromMnemonic(
        mnemonic: mnemonic,
        maxUnusedAddressGap: maxUnusedAddressGap,
        maxNumberOfIndexesToCheck: maxNumberOfIndexesToCheck,
        height: height,
      );
    } catch (e, s) {
      Logging.instance.log("e: $e, S: $s", level: LogLevel.Error);
      rethrow;
    }
  }

  int get txCount => _currentWallet.txCount;

  // Future<bool> initializeWallet() async {
  //   final success = await _currentWallet.initializeWallet();
  //   return success;
  // }

  Future<void> exitCurrentWallet() async {
    final name = _currentWallet.walletName;
    final id = _currentWallet.walletId;
    await _backgroundRefreshListener?.cancel();
    _backgroundRefreshListener = null;
    await _nodeStatusListener?.cancel();
    _nodeStatusListener = null;
    await _currentWallet.exit();
    Logging.instance.log("manager.exitCurrentWallet completed for $id $name",
        level: LogLevel.Info);
  }

  Future<void> fullRescan(
      int maxUnusedAddressGap, int maxNumberOfIndexesToCheck) async {
    try {
      await _currentWallet.fullRescan(
          maxUnusedAddressGap, maxNumberOfIndexesToCheck);
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> isOwnAddress(String address) async {
    final allOwnAddresses = await this.allOwnAddresses;
    return allOwnAddresses.contains(address);
  }

  bool get isConnected => _currentWallet.isConnected;

  Future<int> estimateFeeFor(int satoshiAmount, int feeRate) async {
    return _currentWallet.estimateFeeFor(satoshiAmount, feeRate);
  }

  Future<bool> generateNewAddress() async {
    final success = await _currentWallet.generateNewAddress();
    if (success) {
      notifyListeners();
    }
    return success;
  }
}

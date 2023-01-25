import 'dart:async';

import 'package:decimal/decimal.dart';
import 'package:event_bus/event_bus.dart';
import 'package:flutter/material.dart';
import 'package:stackwallet/models/models.dart';
import 'package:stackwallet/services/coins/coin_service.dart';
import 'package:stackwallet/services/event_bus/events/global/node_connection_status_changed_event.dart';
import 'package:stackwallet/services/event_bus/events/global/updated_in_background_event.dart';
import 'package:stackwallet/services/event_bus/global_event_bus.dart';
import 'package:stackwallet/services/tokens/token_service.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/utilities/logger.dart';

class TokenManager with ChangeNotifier {
  final TokenServiceAPI _currentToken;
  StreamSubscription<dynamic>? _backgroundRefreshListener;

  /// optional eventbus parameter for testing only
  TokenManager(this._currentToken, [EventBus? globalEventBusForTesting]) {
    final bus = globalEventBusForTesting ?? GlobalEventBus.instance;
    _backgroundRefreshListener = bus.on<UpdatedInBackgroundEvent>().listen(
      (event) async {
        // if (event.walletId == walletId) {
        //   notifyListeners();
        //   Logging.instance.log(
        //       "UpdatedInBackgroundEvent activated notifyListeners() in Manager instance $hashCode $walletName with: ${event.message}",
        //       level: LogLevel.Info);
        // }
      },
    );
  }

  TokenServiceAPI get token => _currentToken;

  bool get hasBackgroundRefreshListener => _backgroundRefreshListener != null;

  bool get isRefreshing => _currentToken.isRefreshing;

  bool get shouldAutoSync => _currentToken.shouldAutoSync;
  set shouldAutoSync(bool shouldAutoSync) =>
      _currentToken.shouldAutoSync = shouldAutoSync;

  Future<Map<String, dynamic>> prepareSend({
    required String address,
    required int satoshiAmount,
    Map<String, dynamic>? args,
  }) async {
    try {
      final txInfo = await _currentToken.prepareSend(
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
      final txid = await _currentToken.confirmSend(txData: txData);

      txData["txid"] = txid;
      await _currentToken.updateSentCachedTxData(txData);

      notifyListeners();
      return txid;
    } catch (e) {
      // rethrow to pass error in alert
      rethrow;
    }
  }

  Future<FeeObject> get fees => _currentToken.fees;
  Future<int> get maxFee => _currentToken.maxFee;

  Future<String> get currentReceivingAddress =>
      _currentToken.currentReceivingAddress;
  // Future<String> get currentLegacyReceivingAddress =>
  //     _currentWallet.currentLegacyReceivingAddress;

  Future<Decimal> get availableBalance async {
    _cachedAvailableBalance = await _currentToken.availableBalance;
    return _cachedAvailableBalance;
  }

  Decimal _cachedAvailableBalance = Decimal.zero;
  Decimal get cachedAvailableBalance => _cachedAvailableBalance;

  Future<Decimal> get pendingBalance => _currentToken.pendingBalance;
  Future<Decimal> get balanceMinusMaxFee => _currentToken.balanceMinusMaxFee;

  Future<Decimal> get totalBalance async {
    _cachedTotalBalance = await _currentToken.totalBalance;
    return _cachedTotalBalance;
  }

  Decimal _cachedTotalBalance = Decimal.zero;
  Decimal get cachedTotalBalance => _cachedTotalBalance;

  Future<List<String>> get allOwnAddresses => _currentToken.allOwnAddresses;

  Future<TransactionData> get transactionData => _currentToken.transactionData;

  Future<void> refresh() async {
    await _currentToken.refresh();
    notifyListeners();
  }

  bool validateAddress(String address) =>
      _currentToken.validateAddress(address);

  Future<void> initializeNew() => _currentToken.initializeNew();
  Future<void> initializeExisting() => _currentToken.initializeExisting();

  Future<bool> isOwnAddress(String address) async {
    final allOwnAddresses = await this.allOwnAddresses;
    return allOwnAddresses.contains(address);
  }

  bool get isConnected => _currentToken.isConnected;

  Future<int> estimateFeeFor(int satoshiAmount, int feeRate) async {
    return _currentToken.estimateFeeFor(satoshiAmount, feeRate);
  }
}

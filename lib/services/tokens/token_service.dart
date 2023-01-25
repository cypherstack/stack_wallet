import 'package:decimal/decimal.dart';
import 'package:stackwallet/models/models.dart';
import 'package:stackwallet/services/tokens/ethereum/ethereum_token.dart';
import 'package:stackwallet/services/transaction_notification_tracker.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/utilities/flutter_secure_storage_interface.dart';
import 'package:stackwallet/utilities/prefs.dart';

abstract class TokenServiceAPI {
  TokenServiceAPI();

  factory TokenServiceAPI.from(
    String contractAddress,
    String walletId,
    SecureStorageInterface secureStorageInterface,
    TransactionNotificationTracker tracker,
    Prefs prefs,
  ) {
    return EthereumToken(
      contractAddress: contractAddress,
      walletId: walletId,
      secureStore: secureStorageInterface,
      tracker: tracker,
    );
  }

  Coin get coin;
  bool get isRefreshing;
  bool get shouldAutoSync;
  set shouldAutoSync(bool shouldAutoSync);

  Future<Map<String, dynamic>> prepareSend({
    required String address,
    required int satoshiAmount,
    Map<String, dynamic>? args,
  });

  Future<String> confirmSend({required Map<String, dynamic> txData});

  Future<FeeObject> get fees;
  Future<int> get maxFee;

  Future<String> get currentReceivingAddress;
  // Future<String> get currentLegacyReceivingAddress;

  Future<Decimal> get availableBalance;
  Future<Decimal> get pendingBalance;
  Future<Decimal> get totalBalance;
  Future<Decimal> get balanceMinusMaxFee;

  Future<List<String>> get allOwnAddresses;

  Future<TransactionData> get transactionData;

  Future<void> refresh();

  // String get walletName;
  // String get walletId;

  bool validateAddress(String address);

  Future<void> initializeNew();
  Future<void> initializeExisting();

  // void Function(bool isActive)? onIsActiveWalletChanged;

  bool get isConnected;

  Future<int> estimateFeeFor(int satoshiAmount, int feeRate);

  // used for electrumx coins
  Future<void> updateSentCachedTxData(Map<String, dynamic> txData);
}

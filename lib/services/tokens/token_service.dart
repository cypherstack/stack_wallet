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
    Map<dynamic, dynamic> tokenData,
    Future<List<String>> walletMnemonic,
    SecureStorageInterface secureStorageInterface,
    TransactionNotificationTracker tracker,
    Prefs prefs,
  ) {
    return EthereumToken(
      tokenData: tokenData,
      walletMnemonic: walletMnemonic,
      secureStore: secureStorageInterface,
      // tracker: tracker,
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

  Future<Decimal> get availableBalance;
  Future<Decimal> get totalBalance;

  Future<List<String>> get allOwnAddresses;

  Future<TransactionData> get transactionData;

  Future<void> refresh();

  bool validateAddress(String address);

  Future<void> initializeNew();
  Future<void> initializeExisting();

  Future<int> estimateFeeFor(int satoshiAmount, int feeRate);

  Future<bool> isValidToken(String contractAddress);
}

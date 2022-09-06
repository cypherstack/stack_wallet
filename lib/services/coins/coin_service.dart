import 'package:decimal/decimal.dart';
import 'package:stackwallet/electrumx_rpc/cached_electrumx.dart';
import 'package:stackwallet/electrumx_rpc/electrumx.dart';
import 'package:stackwallet/models/models.dart';
import 'package:stackwallet/models/node_model.dart';
import 'package:stackwallet/services/coins/bitcoin/bitcoin_wallet.dart';
import 'package:stackwallet/services/coins/dogecoin/dogecoin_wallet.dart';
import 'package:stackwallet/services/coins/epiccash/epiccash_wallet.dart';
import 'package:stackwallet/services/coins/firo/firo_wallet.dart';
import 'package:stackwallet/services/coins/monero/monero_wallet.dart';
import 'package:stackwallet/services/coins/bitcoincash/bitcoincash_wallet.dart';
import 'package:stackwallet/services/transaction_notification_tracker.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/utilities/prefs.dart';

abstract class CoinServiceAPI {
  CoinServiceAPI();

  factory CoinServiceAPI.from(
    Coin coin,
    String walletId,
    String walletName,
    NodeModel node,
    TransactionNotificationTracker tracker,
    Prefs prefs,
    List<NodeModel> failovers,
  ) {
    final electrumxNode = ElectrumXNode(
      address: node.host,
      port: node.port,
      name: node.name,
      id: node.id,
      useSSL: node.useSSL,
    );
    final client = ElectrumX.from(
      node: electrumxNode,
      failovers: failovers
          .map((e) => ElectrumXNode(
                address: e.host,
                port: e.port,
                name: e.name,
                id: e.id,
                useSSL: e.useSSL,
              ))
          .toList(),
      prefs: prefs,
    );
    final cachedClient = CachedElectrumX.from(
      node: electrumxNode,
      failovers: failovers
          .map((e) => ElectrumXNode(
                address: e.host,
                port: e.port,
                name: e.name,
                id: e.id,
                useSSL: e.useSSL,
              ))
          .toList(),
      prefs: prefs,
    );
    switch (coin) {
      case Coin.firo:
        return FiroWallet(
          walletId: walletId,
          walletName: walletName,
          coin: coin,
          client: client,
          cachedClient: cachedClient,
          tracker: tracker,
        );
      case Coin.firoTestNet:
        return FiroWallet(
          walletId: walletId,
          walletName: walletName,
          coin: coin,
          client: client,
          cachedClient: cachedClient,
          tracker: tracker,
        );

      case Coin.bitcoin:
        return BitcoinWallet(
          walletId: walletId,
          walletName: walletName,
          coin: coin,
          client: client,
          cachedClient: cachedClient,
          tracker: tracker,
        );

      case Coin.bitcoinTestNet:
        return BitcoinWallet(
          walletId: walletId,
          walletName: walletName,
          coin: coin,
          client: client,
          cachedClient: cachedClient,
          tracker: tracker,
        );

      case Coin.dogecoin:
        return DogecoinWallet(
          walletId: walletId,
          walletName: walletName,
          coin: coin,
          client: client,
          cachedClient: cachedClient,
          tracker: tracker,
        );

      case Coin.epicCash:
        return EpicCashWallet(
          walletId: walletId,
          walletName: walletName,
          coin: coin,
          // tracker: tracker,
        );

      case Coin.monero:
        return MoneroWallet(
          walletId: walletId,
          walletName: walletName,
          coin: coin,
          // tracker: tracker,
        );

      case Coin.dogecoinTestNet:
        return DogecoinWallet(
          walletId: walletId,
          walletName: walletName,
          coin: coin,
          client: client,
          cachedClient: cachedClient,
          tracker: tracker,
        );

      case Coin.bitcoincash:
        return BitcoinCashWallet(
          walletId: walletId,
          walletName: walletName,
          coin: coin,
          client: client,
          cachedClient: cachedClient,
          tracker: tracker,
        );
    }
  }

  Coin get coin;
  bool get isRefreshing;
  bool get shouldAutoSync;
  set shouldAutoSync(bool shouldAutoSync);
  bool get isFavorite;
  set isFavorite(bool markFavorite);

  Future<Map<String, dynamic>> prepareSend({
    required String address,
    required int satoshiAmount,
    Map<String, dynamic>? args,
  });

  Future<String> confirmSend({required Map<String, dynamic> txData});

  /// create and submit tx to network
  ///
  /// Returns the txid of the sent tx
  /// will throw exceptions on failure
  Future<String> send(
      {required String toAddress,
      required int amount,
      Map<String, String> args});

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
  Future<List<UtxoObject>> get unspentOutputs;

  Future<void> refresh();

  Future<void> updateNode(bool shouldRefresh);

  // setter for updating on rename
  set walletName(String newName);

  String get walletName;
  String get walletId;

  bool validateAddress(String address);

  Future<List<String>> get mnemonic;

  Future<bool> testNetworkConnection();

  Future<void> recoverFromMnemonic({
    required String mnemonic,
    required int maxUnusedAddressGap,
    required int maxNumberOfIndexesToCheck,
    required int height,
  });

  Future<void> initializeNew();
  Future<void> initializeExisting();

  Future<void> exit();
  bool get hasCalledExit;

  Future<void> fullRescan(
      int maxUnusedAddressGap, int maxNumberOfIndexesToCheck);

  void Function(bool isActive)? onIsActiveWalletChanged;

  bool get isConnected;

  Future<int> estimateFeeFor(int satoshiAmount, int feeRate);
}

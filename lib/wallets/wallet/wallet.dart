import 'dart:async';

import 'package:isar/isar.dart';
import 'package:meta/meta.dart';
import 'package:mutex/mutex.dart';
import 'package:stackwallet/db/isar/main_db.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/address.dart';
import 'package:stackwallet/models/node_model.dart';
import 'package:stackwallet/models/paymint/fee_object_model.dart';
import 'package:stackwallet/services/event_bus/events/global/node_connection_status_changed_event.dart';
import 'package:stackwallet/services/event_bus/events/global/refresh_percent_changed_event.dart';
import 'package:stackwallet/services/event_bus/events/global/wallet_sync_status_changed_event.dart';
import 'package:stackwallet/services/event_bus/global_event_bus.dart';
import 'package:stackwallet/services/node_service.dart';
import 'package:stackwallet/utilities/amount/amount.dart';
import 'package:stackwallet/utilities/constants.dart';
import 'package:stackwallet/utilities/default_nodes.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/utilities/flutter_secure_storage_interface.dart';
import 'package:stackwallet/utilities/logger.dart';
import 'package:stackwallet/utilities/prefs.dart';
import 'package:stackwallet/wallets/crypto_currency/coins/bitcoin.dart';
import 'package:stackwallet/wallets/crypto_currency/coins/bitcoincash.dart';
import 'package:stackwallet/wallets/crypto_currency/coins/epiccash.dart';
import 'package:stackwallet/wallets/crypto_currency/coins/wownero.dart';
import 'package:stackwallet/wallets/crypto_currency/crypto_currency.dart';
import 'package:stackwallet/wallets/isar/models/wallet_info.dart';
import 'package:stackwallet/wallets/models/tx_data.dart';
import 'package:stackwallet/wallets/wallet/impl/bitcoin_wallet.dart';
import 'package:stackwallet/wallets/wallet/impl/bitcoincash_wallet.dart';
import 'package:stackwallet/wallets/wallet/impl/epiccash_wallet.dart';
import 'package:stackwallet/wallets/wallet/impl/wownero_wallet.dart';
import 'package:stackwallet/wallets/wallet/mixins/electrumx_mixin.dart';
import 'package:stackwallet/wallets/wallet/mixins/multi_address.dart';

abstract class Wallet<T extends CryptoCurrency> {
  // default to Transaction class. For TransactionV2 set to 2
  int get isarTransactionVersion => 1;

  Wallet(this.cryptoCurrency);

  //============================================================================
  // ========== Properties =====================================================

  final T cryptoCurrency;

  late final MainDB mainDB;
  late final SecureStorageInterface secureStorageInterface;
  late final NodeService nodeService;
  late final Prefs prefs;

  final refreshMutex = Mutex();

  WalletInfo get info => _walletInfo;
  bool get isConnected => _isConnected;

  bool get shouldAutoSync => _shouldAutoSync;
  set shouldAutoSync(bool shouldAutoSync) {
    if (_shouldAutoSync != shouldAutoSync) {
      _shouldAutoSync = shouldAutoSync;
      if (!shouldAutoSync) {
        _periodicRefreshTimer?.cancel();
        _periodicRefreshTimer = null;
        _stopNetworkAlivePinging();
      } else {
        _startNetworkAlivePinging();
        refresh();
      }
    }
  }

  // ===== private properties ===========================================

  late WalletInfo _walletInfo;
  late final Stream<WalletInfo?> _walletInfoStream;

  Timer? _periodicRefreshTimer;
  Timer? _networkAliveTimer;

  bool _shouldAutoSync = false;

  bool _isConnected = false;

  void xmrAndWowSyncSpecificFunctionThatShouldBeGottenRidOfInTheFuture(
      bool flag) {
    _isConnected = flag;
  }

  //============================================================================
  // ========== Wallet Info Convenience Getters ================================

  String get walletId => info.walletId;
  WalletType get walletType => info.walletType;

  /// Attempt to fetch the most recent chain height.
  /// On failure return the last cached height.
  Future<int> get chainHeight async {
    try {
      // attempt updating the walletInfo's cached height
      await updateChainHeight();
    } catch (e, s) {
      // do nothing on failure (besides logging)
      Logging.instance.log("$e\n$s", level: LogLevel.Warning);
    }

    // return regardless of whether it was updated or not as we want a
    // number even if it isn't the most recent
    return info.cachedChainHeight;
  }

  //============================================================================
  // ========== Static Main ====================================================

  /// Create a new wallet and save [walletInfo] to db.
  static Future<Wallet> create({
    required WalletInfo walletInfo,
    required MainDB mainDB,
    required SecureStorageInterface secureStorageInterface,
    required NodeService nodeService,
    required Prefs prefs,
    String? mnemonic,
    String? mnemonicPassphrase,
    String? privateKey,
  }) async {
    final Wallet wallet = await _construct(
      walletInfo: walletInfo,
      mainDB: mainDB,
      secureStorageInterface: secureStorageInterface,
      nodeService: nodeService,
      prefs: prefs,
    );

    switch (walletInfo.walletType) {
      case WalletType.bip39:
      case WalletType.bip39HD:
        await secureStorageInterface.write(
          key: mnemonicKey(walletId: walletInfo.walletId),
          value: mnemonic,
        );
        await secureStorageInterface.write(
          key: mnemonicPassphraseKey(walletId: walletInfo.walletId),
          value: mnemonicPassphrase,
        );
        break;

      case WalletType.cryptonote:
        break;

      case WalletType.privateKeyBased:
        break;
    }

    // Store in db after wallet creation
    await wallet.mainDB.isar.walletInfo.put(wallet.info);

    return wallet;
  }

  /// Load an existing wallet via [WalletInfo] using [walletId].
  static Future<Wallet> load({
    required String walletId,
    required MainDB mainDB,
    required SecureStorageInterface secureStorageInterface,
    required NodeService nodeService,
    required Prefs prefs,
  }) async {
    final walletInfo = await mainDB.isar.walletInfo
        .where()
        .walletIdEqualTo(walletId)
        .findFirst();

    if (walletInfo == null) {
      throw Exception(
        "WalletInfo not found for $walletId when trying to call Wallet.load()",
      );
    }

    return await _construct(
      walletInfo: walletInfo,
      mainDB: mainDB,
      secureStorageInterface: secureStorageInterface,
      nodeService: nodeService,
      prefs: prefs,
    );
  }

  //============================================================================
  // ========== Static Util ====================================================

  // secure storage key
  static String mnemonicKey({
    required String walletId,
  }) =>
      "${walletId}_mnemonic";

  // secure storage key
  static String mnemonicPassphraseKey({
    required String walletId,
  }) =>
      "${walletId}_mnemonicPassphrase";

  // secure storage key
  static String privateKeyKey({
    required String walletId,
  }) =>
      "${walletId}_privateKey";

  //============================================================================
  // ========== Private ========================================================

  /// Construct wallet instance by [WalletType] from [walletInfo]
  static Future<Wallet> _construct({
    required WalletInfo walletInfo,
    required MainDB mainDB,
    required SecureStorageInterface secureStorageInterface,
    required NodeService nodeService,
    required Prefs prefs,
  }) async {
    final Wallet wallet = _loadWallet(
      walletInfo: walletInfo,
    );

    wallet.prefs = prefs;
    wallet.nodeService = nodeService;

    if (wallet is ElectrumXMixin) {
      // initialize electrumx instance
      await wallet.updateNode();
    }

    return wallet
      ..secureStorageInterface = secureStorageInterface
      ..mainDB = mainDB
      .._walletInfo = walletInfo
      .._watchWalletInfo();
  }

  static Wallet _loadWallet({
    required WalletInfo walletInfo,
  }) {
    switch (walletInfo.coin) {
      case Coin.bitcoin:
        return BitcoinWallet(
          Bitcoin(CryptoCurrencyNetwork.main),
        );

      case Coin.bitcoinTestNet:
        return BitcoinWallet(
          Bitcoin(CryptoCurrencyNetwork.test),
        );

      case Coin.bitcoincash:
        return BitcoincashWallet(
          Bitcoincash(CryptoCurrencyNetwork.main),
        );

      case Coin.bitcoincashTestnet:
        return BitcoincashWallet(
          Bitcoincash(CryptoCurrencyNetwork.test),
        );

      case Coin.epicCash:
        return EpiccashWallet(
          Epiccash(CryptoCurrencyNetwork.main),
        );

      case Coin.wownero:
        return WowneroWallet(
          Wownero(CryptoCurrencyNetwork.main),
        );

      default:
        // should never hit in reality
        throw Exception("Unknown crypto currency: ${walletInfo.coin}");
    }
  }

  // listen to changes in db and updated wallet info property as required
  void _watchWalletInfo() {
    _walletInfoStream = mainDB.isar.walletInfo.watchObject(_walletInfo.id);
    _walletInfoStream.forEach((element) {
      if (element != null) {
        _walletInfo = element;
      }
    });
  }

  void _startNetworkAlivePinging() {
    // call once on start right away
    _periodicPingCheck();

    // then periodically check
    _networkAliveTimer = Timer.periodic(
      Constants.networkAliveTimerDuration,
      (_) async {
        _periodicPingCheck();
      },
    );
  }

  void _periodicPingCheck() async {
    bool hasNetwork = await pingCheck();

    if (_isConnected != hasNetwork) {
      NodeConnectionStatus status = hasNetwork
          ? NodeConnectionStatus.connected
          : NodeConnectionStatus.disconnected;
      GlobalEventBus.instance.fire(
        NodeConnectionStatusChangedEvent(
          status,
          walletId,
          cryptoCurrency.coin,
        ),
      );

      _isConnected = hasNetwork;
      if (hasNetwork) {
        unawaited(refresh());
      }
    }
  }

  void _stopNetworkAlivePinging() {
    _networkAliveTimer?.cancel();
    _networkAliveTimer = null;
  }

  //============================================================================
  // ========== Must override ==================================================

  /// Create and sign a transaction in preparation to submit to network
  Future<TxData> prepareSend({required TxData txData});

  /// Broadcast transaction to network. On success update local wallet state to
  /// reflect updated balance, transactions, utxos, etc.
  Future<TxData> confirmSend({required TxData txData});

  /// Recover a wallet by scanning the blockchain. If called on a new wallet a
  /// normal recovery should occur. When called on an existing wallet and
  /// [isRescan] is false then it should throw. Otherwise this function should
  /// delete all locally stored blockchain data and refetch it.
  Future<void> recover({required bool isRescan});

  Future<void> updateNode();

  Future<void> updateTransactions();
  Future<void> updateUTXOs();
  Future<void> updateBalance();

  /// updates the wallet info's cachedChainHeight
  Future<void> updateChainHeight();

  Future<Amount> estimateFeeFor(Amount amount, int feeRate);

  Future<FeeObject> get fees;

  Future<bool> pingCheck();

  //===========================================

  NodeModel getCurrentNode() {
    final node = nodeService.getPrimaryNodeFor(coin: cryptoCurrency.coin) ??
        DefaultNodes.getNodeFor(cryptoCurrency.coin);

    return node;
  }

  // Should fire events
  Future<void> refresh() async {
    // Awaiting this lock could be dangerous.
    // Since refresh is periodic (generally)
    if (refreshMutex.isLocked) {
      return;
    }

    try {
      // this acquire should be almost instant due to above check.
      // Slight possibility of race but should be irrelevant
      await refreshMutex.acquire();

      GlobalEventBus.instance.fire(
        WalletSyncStatusChangedEvent(
          WalletSyncStatus.syncing,
          walletId,
          cryptoCurrency.coin,
        ),
      );

      GlobalEventBus.instance.fire(RefreshPercentChangedEvent(0.0, walletId));
      await updateChainHeight();

      GlobalEventBus.instance.fire(RefreshPercentChangedEvent(0.1, walletId));

      // if (currentHeight != storedHeight) {
      GlobalEventBus.instance.fire(RefreshPercentChangedEvent(0.2, walletId));

      GlobalEventBus.instance.fire(RefreshPercentChangedEvent(0.3, walletId));
      // await _checkCurrentReceivingAddressesForTransactions();

      final fetchFuture = updateTransactions();
      final utxosRefreshFuture = updateUTXOs();

      GlobalEventBus.instance.fire(RefreshPercentChangedEvent(0.50, walletId));

      // final feeObj = _getFees();
      GlobalEventBus.instance.fire(RefreshPercentChangedEvent(0.60, walletId));

      await utxosRefreshFuture;
      GlobalEventBus.instance.fire(RefreshPercentChangedEvent(0.70, walletId));
      // _feeObject = Future(() => feeObj);

      await fetchFuture;
      GlobalEventBus.instance.fire(RefreshPercentChangedEvent(0.80, walletId));

      if (this is MultiAddress) {
        await (this as MultiAddress).checkReceivingAddressForTransactions();
      }
      // await getAllTxsToWatch();
      GlobalEventBus.instance.fire(RefreshPercentChangedEvent(0.90, walletId));

      await updateBalance();

      GlobalEventBus.instance.fire(RefreshPercentChangedEvent(1.0, walletId));
      GlobalEventBus.instance.fire(
        WalletSyncStatusChangedEvent(
          WalletSyncStatus.synced,
          walletId,
          cryptoCurrency.coin,
        ),
      );

      if (shouldAutoSync) {
        _periodicRefreshTimer ??=
            Timer.periodic(const Duration(seconds: 150), (timer) async {
          // chain height check currently broken
          // if ((await chainHeight) != (await storedChainHeight)) {

          // TODO: [prio=med] some kind of quick check if wallet needs to refresh to replace the old refreshIfThereIsNewData call
          // if (await refreshIfThereIsNewData()) {
          unawaited(refresh());

          // }
          // }
        });
      }
    } catch (error, strace) {
      GlobalEventBus.instance.fire(
        NodeConnectionStatusChangedEvent(
          NodeConnectionStatus.disconnected,
          walletId,
          cryptoCurrency.coin,
        ),
      );
      GlobalEventBus.instance.fire(
        WalletSyncStatusChangedEvent(
          WalletSyncStatus.unableToSync,
          walletId,
          cryptoCurrency.coin,
        ),
      );
      Logging.instance.log(
        "Caught exception in refreshWalletData(): $error\n$strace",
        level: LogLevel.Error,
      );
    } finally {
      refreshMutex.release();
    }
  }

  Future<void> exit() async {
    // TODO:
  }

  @mustCallSuper
  Future<void> init() async {
    final address = await getCurrentReceivingAddress();
    await info.updateReceivingAddress(
      newAddress: address!.value,
      isar: mainDB.isar,
    );

    // TODO: make sure subclasses override this if they require some set up
    // especially xmr/wow/epiccash
  }

  // ===========================================================================

  Future<Address?> getCurrentReceivingAddress() async =>
      await mainDB.isar.addresses
          .where()
          .walletIdEqualTo(walletId)
          .filter()
          .typeEqualTo(info.mainAddressType)
          .subTypeEqualTo(AddressSubType.receiving)
          .sortByDerivationIndexDesc()
          .findFirst();
}
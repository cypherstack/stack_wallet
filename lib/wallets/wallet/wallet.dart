import 'dart:async';

import 'package:isar/isar.dart';
import 'package:meta/meta.dart';
import 'package:mutex/mutex.dart';
import 'package:stackwallet/db/isar/main_db.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/address.dart';
import 'package:stackwallet/models/isar/models/ethereum/eth_contract.dart';
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
import 'package:stackwallet/utilities/enums/sync_type_enum.dart';
import 'package:stackwallet/utilities/flutter_secure_storage_interface.dart';
import 'package:stackwallet/utilities/logger.dart';
import 'package:stackwallet/utilities/paynym_is_api.dart';
import 'package:stackwallet/utilities/prefs.dart';
import 'package:stackwallet/wallets/crypto_currency/crypto_currency.dart';
import 'package:stackwallet/wallets/isar/models/wallet_info.dart';
import 'package:stackwallet/wallets/models/tx_data.dart';
import 'package:stackwallet/wallets/wallet/impl/banano_wallet.dart';
import 'package:stackwallet/wallets/wallet/impl/bitcoin_wallet.dart';
import 'package:stackwallet/wallets/wallet/impl/bitcoincash_wallet.dart';
import 'package:stackwallet/wallets/wallet/impl/dogecoin_wallet.dart';
import 'package:stackwallet/wallets/wallet/impl/ecash_wallet.dart';
import 'package:stackwallet/wallets/wallet/impl/epiccash_wallet.dart';
import 'package:stackwallet/wallets/wallet/impl/ethereum_wallet.dart';
import 'package:stackwallet/wallets/wallet/impl/firo_wallet.dart';
import 'package:stackwallet/wallets/wallet/impl/litecoin_wallet.dart';
import 'package:stackwallet/wallets/wallet/impl/monero_wallet.dart';
import 'package:stackwallet/wallets/wallet/impl/namecoin_wallet.dart';
import 'package:stackwallet/wallets/wallet/impl/nano_wallet.dart';
import 'package:stackwallet/wallets/wallet/impl/particl_wallet.dart';
import 'package:stackwallet/wallets/wallet/impl/stellar_wallet.dart';
import 'package:stackwallet/wallets/wallet/impl/sub_wallets/eth_token_wallet.dart';
import 'package:stackwallet/wallets/wallet/impl/tezos_wallet.dart';
import 'package:stackwallet/wallets/wallet/impl/wownero_wallet.dart';
import 'package:stackwallet/wallets/wallet/intermediate/cryptonote_wallet.dart';
import 'package:stackwallet/wallets/wallet/wallet_mixin_interfaces/electrumx_interface.dart';
import 'package:stackwallet/wallets/wallet/wallet_mixin_interfaces/lelantus_interface.dart';
import 'package:stackwallet/wallets/wallet/wallet_mixin_interfaces/mnemonic_interface.dart';
import 'package:stackwallet/wallets/wallet/wallet_mixin_interfaces/multi_address_interface.dart';
import 'package:stackwallet/wallets/wallet/wallet_mixin_interfaces/paynym_interface.dart';
import 'package:stackwallet/wallets/wallet/wallet_mixin_interfaces/private_key_interface.dart';
import 'package:stackwallet/wallets/wallet/wallet_mixin_interfaces/spark_interface.dart';

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

  late final String _walletId;
  WalletInfo get info =>
      mainDB.isar.walletInfo.where().walletIdEqualTo(walletId).findFirstSync()!;
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

  String get walletId => _walletId;

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

    if (wallet is MnemonicInterface) {
      if (wallet is CryptonoteWallet) {
        // currently a special case due to the xmr/wow libraries handling their
        // own mnemonic generation on new wallet creation
        // if its a restore we must set them
        if (mnemonic != null) {
          if ((await secureStorageInterface.read(
                key: mnemonicKey(walletId: walletInfo.walletId),
              )) ==
              null) {
            await secureStorageInterface.write(
              key: mnemonicKey(walletId: walletInfo.walletId),
              value: mnemonic,
            );
          }

          if (mnemonicPassphrase != null) {
            if ((await secureStorageInterface.read(
                  key: mnemonicPassphraseKey(walletId: walletInfo.walletId),
                )) ==
                null) {
              await secureStorageInterface.write(
                key: mnemonicPassphraseKey(walletId: walletInfo.walletId),
                value: mnemonicPassphrase,
              );
            }
          }
        }
      } else {
        await secureStorageInterface.write(
          key: mnemonicKey(walletId: walletInfo.walletId),
          value: mnemonic!,
        );
        await secureStorageInterface.write(
          key: mnemonicPassphraseKey(walletId: walletInfo.walletId),
          value: mnemonicPassphrase!,
        );
      }
    }

    // TODO [prio=low] handle eth differently?
    // This would need to be changed if we actually end up allowing eth wallets
    // to be created with a private key instead of mnemonic only
    if (wallet is PrivateKeyInterface && wallet is! EthereumWallet) {
      await secureStorageInterface.write(
        key: privateKeyKey(walletId: walletInfo.walletId),
        value: privateKey!,
      );
    }

    // Store in db after wallet creation
    await wallet.mainDB.isar.writeTxn(() async {
      await wallet.mainDB.isar.walletInfo.put(walletInfo);
    });

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

  // TODO: [prio=low] refactor to more generalized token rather than eth specific
  static Wallet loadTokenWallet({
    required EthereumWallet ethWallet,
    required EthContract contract,
  }) {
    final Wallet wallet = EthTokenWallet(
      ethWallet,
      contract,
    );

    wallet.prefs = ethWallet.prefs;
    wallet.nodeService = ethWallet.nodeService;
    wallet.secureStorageInterface = ethWallet.secureStorageInterface;
    wallet.mainDB = ethWallet.mainDB;

    return wallet.._walletId = ethWallet.info.walletId;
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

    if (wallet is ElectrumXInterface) {
      // initialize electrumx instance
      await wallet.updateNode();
    }

    return wallet
      ..secureStorageInterface = secureStorageInterface
      ..mainDB = mainDB
      .._walletId = walletInfo.walletId;
  }

  static Wallet _loadWallet({
    required WalletInfo walletInfo,
  }) {
    switch (walletInfo.coin) {
      case Coin.banano:
        return BananoWallet(CryptoCurrencyNetwork.main);

      case Coin.bitcoin:
        return BitcoinWallet(CryptoCurrencyNetwork.main);
      case Coin.bitcoinTestNet:
        return BitcoinWallet(CryptoCurrencyNetwork.test);

      case Coin.bitcoincash:
        return BitcoincashWallet(CryptoCurrencyNetwork.main);
      case Coin.bitcoincashTestnet:
        return BitcoincashWallet(CryptoCurrencyNetwork.test);

      case Coin.dogecoin:
        return DogecoinWallet(CryptoCurrencyNetwork.main);
      case Coin.dogecoinTestNet:
        return DogecoinWallet(CryptoCurrencyNetwork.test);

      case Coin.eCash:
        return EcashWallet(CryptoCurrencyNetwork.main);

      case Coin.epicCash:
        return EpiccashWallet(CryptoCurrencyNetwork.main);

      case Coin.ethereum:
        return EthereumWallet(CryptoCurrencyNetwork.main);

      case Coin.firo:
        return FiroWallet(CryptoCurrencyNetwork.main);
      case Coin.firoTestNet:
        return FiroWallet(CryptoCurrencyNetwork.test);

      case Coin.litecoin:
        return LitecoinWallet(CryptoCurrencyNetwork.main);
      case Coin.litecoinTestNet:
        return LitecoinWallet(CryptoCurrencyNetwork.test);

      case Coin.monero:
        return MoneroWallet(CryptoCurrencyNetwork.main);

      case Coin.namecoin:
        return NamecoinWallet(CryptoCurrencyNetwork.main);

      case Coin.nano:
        return NanoWallet(CryptoCurrencyNetwork.main);

      case Coin.particl:
        return ParticlWallet(CryptoCurrencyNetwork.main);

      case Coin.stellar:
        return StellarWallet(CryptoCurrencyNetwork.main);
      case Coin.stellarTestnet:
        return StellarWallet(CryptoCurrencyNetwork.test);

      case Coin.tezos:
        return TezosWallet(CryptoCurrencyNetwork.main);

      case Coin.wownero:
        return WowneroWallet(CryptoCurrencyNetwork.main);

      default:
        // should never hit in reality
        throw Exception("Unknown crypto currency: ${walletInfo.coin}");
    }
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
  Future<void> updateBalance();

  /// returns true if new utxos were added to local db
  Future<bool> updateUTXOs();

  /// updates the wallet info's cachedChainHeight
  Future<void> updateChainHeight();

  Future<Amount> estimateFeeFor(Amount amount, int feeRate);

  Future<FeeObject> get fees;

  Future<bool> pingCheck();

  Future<void> checkSaveInitialReceivingAddress();

  //===========================================
  /// add transaction to local db temporarily. Used for quickly updating ui
  /// before refresh can fetch data from server
  Future<TxData> updateSentCachedTxData({required TxData txData}) async {
    if (txData.tempTx != null) {
      await mainDB.updateOrPutTransactionV2s([txData.tempTx!]);
    }
    return txData;
  }

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

      // add some small buffer before making calls.
      // this can probably be removed in the future but was added as a
      // debugging feature
      await Future<void>.delayed(const Duration(milliseconds: 300));

      // TODO: [prio=low] handle this differently. Extra modification of this file for coin specific functionality should be avoided.
      final Set<String> codesToCheck = {};
      if (this is PaynymInterface) {
        // isSegwit does not matter here at all
        final myCode =
            await (this as PaynymInterface).getPaymentCode(isSegwit: false);

        final nym = await PaynymIsApi().nym(myCode.toString());
        if (nym.value != null) {
          for (final follower in nym.value!.followers) {
            codesToCheck.add(follower.code);
          }
          for (final following in nym.value!.following) {
            codesToCheck.add(following.code);
          }
        }
      }

      GlobalEventBus.instance.fire(RefreshPercentChangedEvent(0.0, walletId));
      await updateChainHeight();

      GlobalEventBus.instance.fire(RefreshPercentChangedEvent(0.1, walletId));

      // TODO: [prio=low] handle this differently. Extra modification of this file for coin specific functionality should be avoided.
      if (this is MultiAddressInterface) {
        await (this as MultiAddressInterface)
            .checkReceivingAddressForTransactions();
      }

      GlobalEventBus.instance.fire(RefreshPercentChangedEvent(0.2, walletId));

      // TODO: [prio=low] handle this differently. Extra modification of this file for coin specific functionality should be avoided.
      if (this is MultiAddressInterface) {
        await (this as MultiAddressInterface)
            .checkChangeAddressForTransactions();
      }
      GlobalEventBus.instance.fire(RefreshPercentChangedEvent(0.3, walletId));
      if (this is SparkInterface) {
        // this should be called before updateTransactions()
        await (this as SparkInterface).refreshSparkData();
      }

      GlobalEventBus.instance.fire(RefreshPercentChangedEvent(0.50, walletId));
      final fetchFuture = updateTransactions();
      final utxosRefreshFuture = updateUTXOs();
      // if (currentHeight != storedHeight) {
      GlobalEventBus.instance.fire(RefreshPercentChangedEvent(0.60, walletId));

      await utxosRefreshFuture;
      GlobalEventBus.instance.fire(RefreshPercentChangedEvent(0.70, walletId));

      await fetchFuture;

      // TODO: [prio=low] handle this differently. Extra modification of this file for coin specific functionality should be avoided.
      if (this is PaynymInterface && codesToCheck.isNotEmpty) {
        await (this as PaynymInterface)
            .checkForNotificationTransactionsTo(codesToCheck);
        // check utxos again for notification outputs
        await updateUTXOs();
      }
      GlobalEventBus.instance.fire(RefreshPercentChangedEvent(0.80, walletId));

      // await getAllTxsToWatch();

      // TODO: [prio=low] handle this differently. Extra modification of this file for coin specific functionality should be avoided.
      if (this is LelantusInterface) {
        await (this as LelantusInterface).refreshLelantusData();
      }
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
    _periodicRefreshTimer?.cancel();
    _networkAliveTimer?.cancel();

    // If the syncing pref is currentWalletOnly or selectedWalletsAtStartup (and
    // this wallet isn't in walletIdsSyncOnStartup), then we close subscriptions.

    switch (prefs.syncType) {
      case SyncingType.currentWalletOnly:
      // Close the subscription for this coin's chain height.
      // NOTE: This does not work now that the subscription is shared
      // await  (await ChainHeightServiceManager.getService(cryptoCurrency.coin))
      //     ?.cancelListen();
      case SyncingType.selectedWalletsAtStartup:
        // Close the subscription if this wallet is not in the list to be synced.
        if (!prefs.walletIdsSyncOnStartup.contains(walletId)) {
          // Check if there's another wallet of this coin on the sync list.
          List<String> walletIds = [];
          for (final id in prefs.walletIdsSyncOnStartup) {
            final wallet = mainDB.isar.walletInfo
                .where()
                .walletIdEqualTo(id)
                .findFirstSync()!;

            if (wallet.coin == cryptoCurrency.coin) {
              walletIds.add(id);
            }
          }
          // TODO [prio=low]: use a query instead of iterating thru wallets.

          // If there are no other wallets of this coin, then close the sub.
          if (walletIds.isEmpty) {
            // NOTE: This does not work now that the subscription is shared
            // await (await ChainHeightServiceManager.getService(
            //         cryptoCurrency.coin))
            //     ?.cancelListen();
          }
        }
      case SyncingType.allWalletsOnStartup:
        // Do nothing.
        break;
    }
  }

  @mustCallSuper
  Future<void> init() async {
    await checkSaveInitialReceivingAddress();
    final address = await getCurrentReceivingAddress();
    if (address != null) {
      await info.updateReceivingAddress(
        newAddress: address.value,
        isar: mainDB.isar,
      );
    }
  }

  // ===========================================================================

  FilterOperation? get transactionFilterOperation => null;

  FilterOperation? get receivingAddressFilterOperation;
  FilterOperation? get changeAddressFilterOperation;

  Future<Address?> getCurrentReceivingAddress() async {
    return await _addressQuery(receivingAddressFilterOperation);
  }

  Future<Address?> getCurrentChangeAddress() async {
    return await _addressQuery(changeAddressFilterOperation);
  }

  Future<Address?> _addressQuery(FilterOperation? filterOperation) async {
    return await mainDB.isar.addresses
        .buildQuery<Address>(
          whereClauses: [
            IndexWhereClause.equalTo(
              indexName: r"walletId",
              value: [walletId],
            ),
          ],
          filter: filterOperation,
          sortBy: [
            const SortProperty(
              property: r"derivationIndex",
              sort: Sort.desc,
            ),
          ],
        )
        .findFirst();
  }
}

import 'dart:async';

import 'package:isar/isar.dart';
import 'package:meta/meta.dart';
import 'package:mutex/mutex.dart';

import '../../db/isar/main_db.dart';
import '../../models/isar/models/blockchain_data/address.dart';
import '../../models/isar/models/ethereum/eth_contract.dart';
import '../../models/keys/view_only_wallet_data.dart';
import '../../models/node_model.dart';
import '../../models/paymint/fee_object_model.dart';
import '../../services/event_bus/events/global/node_connection_status_changed_event.dart';
import '../../services/event_bus/events/global/refresh_percent_changed_event.dart';
import '../../services/event_bus/events/global/wallet_sync_status_changed_event.dart';
import '../../services/event_bus/global_event_bus.dart';
import '../../services/node_service.dart';
import '../../utilities/amount/amount.dart';
import '../../utilities/constants.dart';
import '../../utilities/enums/sync_type_enum.dart';
import '../../utilities/flutter_secure_storage_interface.dart';
import '../../utilities/logger.dart';
import '../../utilities/paynym_is_api.dart';
import '../../utilities/prefs.dart';
import '../crypto_currency/coins/bip48_bitcoin.dart';
import '../crypto_currency/crypto_currency.dart';
import '../isar/models/wallet_info.dart';
import '../models/tx_data.dart';
import 'impl/banano_wallet.dart';
import 'impl/bip48_bitcoin_wallet.dart';
import 'impl/bitcoin_frost_wallet.dart';
import 'impl/bitcoin_wallet.dart';
import 'impl/bitcoincash_wallet.dart';
import 'impl/cardano_wallet.dart';
import 'impl/dash_wallet.dart';
import 'impl/dogecoin_wallet.dart';
import 'impl/ecash_wallet.dart';
import 'impl/epiccash_wallet.dart';
import 'impl/ethereum_wallet.dart';
import 'impl/firo_wallet.dart';
import 'impl/litecoin_wallet.dart';
import 'impl/monero_wallet.dart';
import 'impl/namecoin_wallet.dart';
import 'impl/nano_wallet.dart';
import 'impl/particl_wallet.dart';
import 'impl/peercoin_wallet.dart';
import 'impl/solana_wallet.dart';
import 'impl/stellar_wallet.dart';
import 'impl/sub_wallets/eth_token_wallet.dart';
import 'impl/tezos_wallet.dart';
import 'impl/wownero_wallet.dart';
import 'intermediate/cryptonote_wallet.dart';
import 'wallet_mixin_interfaces/electrumx_interface.dart';
import 'wallet_mixin_interfaces/lelantus_interface.dart';
import 'wallet_mixin_interfaces/mnemonic_interface.dart';
import 'wallet_mixin_interfaces/multi_address_interface.dart';
import 'wallet_mixin_interfaces/paynym_interface.dart';
import 'wallet_mixin_interfaces/private_key_interface.dart';
import 'wallet_mixin_interfaces/spark_interface.dart';
import 'wallet_mixin_interfaces/view_only_option_interface.dart';

abstract class Wallet<T extends CryptoCurrency> {
  // default to Transaction class. For TransactionV2 set to 2
  int get isarTransactionVersion => 1;

  // whether the wallet currently supports multiple recipients per tx
  bool get supportsMultiRecipient => false;

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
    bool flag,
  ) {
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
    ViewOnlyWalletData? viewOnlyData,
  }) async {
    // TODO: rework soon?
    if (walletInfo.isViewOnly && viewOnlyData == null) {
      throw Exception("Missing view key while creating view only wallet!");
    }

    final Wallet wallet = await _construct(
      walletInfo: walletInfo,
      mainDB: mainDB,
      secureStorageInterface: secureStorageInterface,
      nodeService: nodeService,
      prefs: prefs,
    );

    if (wallet is ViewOnlyOptionInterface && walletInfo.isViewOnly) {
      await secureStorageInterface.write(
        key: getViewOnlyWalletDataSecStoreKey(walletId: walletInfo.walletId),
        value: viewOnlyData!.toJsonEncodedString(),
      );
    } else if (wallet is MnemonicInterface) {
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

  // secure storage key
  static String getViewOnlyWalletDataSecStoreKey({
    required String walletId,
  }) =>
      "${walletId}_viewOnlyWalletData";

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

    if (wallet is ElectrumXInterface || wallet is BitcoinFrostWallet) {
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
    final net = walletInfo.coin.network;
    switch (walletInfo.coin.runtimeType) {
      case const (Banano):
        return BananoWallet(net);

      case const (BIP48Bitcoin):
        return BIP48BitcoinWallet(net);

      case const (Bitcoin):
        return BitcoinWallet(net);

      case const (BitcoinFrost):
        return BitcoinFrostWallet(net);

      case const (Bitcoincash):
        return BitcoincashWallet(net);

      case const (Cardano):
        return CardanoWallet(net);

      case const (Dash):
        return DashWallet(net);

      case const (Dogecoin):
        return DogecoinWallet(net);

      case const (Ecash):
        return EcashWallet(net);

      case const (Epiccash):
        return EpiccashWallet(net);

      case const (Ethereum):
        return EthereumWallet(net);

      case const (Firo):
        return FiroWallet(net);

      case const (Litecoin):
        return LitecoinWallet(net);

      case const (Monero):
        return MoneroWallet(net);

      case const (Namecoin):
        return NamecoinWallet(net);

      case const (Nano):
        return NanoWallet(net);

      case const (Particl):
        return ParticlWallet(net);

      case const (Peercoin):
        return PeercoinWallet(net);

      case const (Solana):
        return SolanaWallet(net);

      case const (Stellar):
        return StellarWallet(net);

      case const (Tezos):
        return TezosWallet(net);

      case const (Wownero):
        return WowneroWallet(net);

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
    if (refreshMutex.isLocked) {
      // should be active calls happening so no need to make extra work
      return;
    }

    final bool hasNetwork = await pingCheck();

    if (_isConnected != hasNetwork) {
      final NodeConnectionStatus status = hasNetwork
          ? NodeConnectionStatus.connected
          : NodeConnectionStatus.disconnected;
      GlobalEventBus.instance.fire(
        NodeConnectionStatusChangedEvent(
          status,
          walletId,
          cryptoCurrency,
        ),
      );

      _isConnected = hasNetwork;

      if (status == NodeConnectionStatus.disconnected) {
        GlobalEventBus.instance.fire(
          WalletSyncStatusChangedEvent(
            WalletSyncStatus.unableToSync,
            walletId,
            cryptoCurrency,
          ),
        );
      }

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
    final node = nodeService.getPrimaryNodeFor(currency: cryptoCurrency) ??
        cryptoCurrency.defaultNode;

    return node;
  }

  // Should fire events
  Future<void> refresh() async {
    final refreshCompleter = Completer<void>();
    final future = refreshCompleter.future.then(
      (_) {
        GlobalEventBus.instance.fire(
          WalletSyncStatusChangedEvent(
            WalletSyncStatus.synced,
            walletId,
            cryptoCurrency,
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
      },
      onError: (Object error, StackTrace strace) {
        GlobalEventBus.instance.fire(
          NodeConnectionStatusChangedEvent(
            NodeConnectionStatus.disconnected,
            walletId,
            cryptoCurrency,
          ),
        );
        GlobalEventBus.instance.fire(
          WalletSyncStatusChangedEvent(
            WalletSyncStatus.unableToSync,
            walletId,
            cryptoCurrency,
          ),
        );
        Logging.instance.log(
          "Caught exception in refreshWalletData(): $error\n$strace",
          level: LogLevel.Error,
        );
      },
    );

    unawaited(_refresh(refreshCompleter));

    return future;
  }

  void _fireRefreshPercentChange(double percent) {
    if (this is ElectrumXInterface) {
      (this as ElectrumXInterface?)?.refreshingPercent = percent;
    }
    GlobalEventBus.instance.fire(RefreshPercentChangedEvent(percent, walletId));
  }

  // Should fire events
  Future<void> _refresh(Completer<void> completer) async {
    // Awaiting this lock could be dangerous.
    // Since refresh is periodic (generally)
    if (refreshMutex.isLocked) {
      return;
    }
    final start = DateTime.now();

    final viewOnly = this is ViewOnlyOptionInterface &&
        (this as ViewOnlyOptionInterface).isViewOnly;

    try {
      // this acquire should be almost instant due to above check.
      // Slight possibility of race but should be irrelevant
      await refreshMutex.acquire();

      GlobalEventBus.instance.fire(
        WalletSyncStatusChangedEvent(
          WalletSyncStatus.syncing,
          walletId,
          cryptoCurrency,
        ),
      );

      // add some small buffer before making calls.
      // this can probably be removed in the future but was added as a
      // debugging feature
      await Future<void>.delayed(const Duration(milliseconds: 300));

      // TODO: [prio=low] handle this differently. Extra modification of this file for coin specific functionality should be avoided.
      final Set<String> codesToCheck = {};
      if (this is PaynymInterface && !viewOnly) {
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

      _fireRefreshPercentChange(0);
      await updateChainHeight();

      if (this is BitcoinFrostWallet) {
        await (this as BitcoinFrostWallet).lookAhead();
      }

      _fireRefreshPercentChange(0.1);

      // TODO: [prio=low] handle this differently. Extra modification of this file for coin specific functionality should be avoided.
      if (this is MultiAddressInterface) {
        if (info.otherData[WalletInfoKeys.reuseAddress] != true) {
          await (this as MultiAddressInterface)
              .checkReceivingAddressForTransactions();
        }
      }

      _fireRefreshPercentChange(0.2);

      // TODO: [prio=low] handle this differently. Extra modification of this file for coin specific functionality should be avoided.
      if (this is MultiAddressInterface) {
        if (info.otherData[WalletInfoKeys.reuseAddress] != true) {
          await (this as MultiAddressInterface)
              .checkChangeAddressForTransactions();
        }
      }
      _fireRefreshPercentChange(0.3);
      if (this is SparkInterface && !viewOnly) {
        // this should be called before updateTransactions()
        await (this as SparkInterface).refreshSparkData((0.3, 0.6));
      }

      final fetchFuture = updateTransactions();

      _fireRefreshPercentChange(0.6);
      final utxosRefreshFuture = updateUTXOs();
      // if (currentHeight != storedHeight) {
      _fireRefreshPercentChange(0.65);

      await utxosRefreshFuture;
      _fireRefreshPercentChange(0.70);

      await fetchFuture;

      // TODO: [prio=low] handle this differently. Extra modification of this file for coin specific functionality should be avoided.
      if (!viewOnly && this is PaynymInterface && codesToCheck.isNotEmpty) {
        await (this as PaynymInterface)
            .checkForNotificationTransactionsTo(codesToCheck);
        // check utxos again for notification outputs
        await updateUTXOs();
      }
      _fireRefreshPercentChange(0.80);

      // await getAllTxsToWatch();

      // TODO: [prio=low] handle this differently. Extra modification of this file for coin specific functionality should be avoided.
      if (this is LelantusInterface && !viewOnly) {
        if (info.otherData[WalletInfoKeys.enableLelantusScanning] as bool? ??
            false) {
          await (this as LelantusInterface).refreshLelantusData();
        }
      }
      _fireRefreshPercentChange(0.90);

      await updateBalance();

      _fireRefreshPercentChange(1.0);

      completer.complete();
    } catch (error, strace) {
      completer.completeError(error, strace);
    } finally {
      refreshMutex.release();
      if (!completer.isCompleted) {
        completer.completeError(
          "finally block hit before completer completed",
          StackTrace.current,
        );
      }

      Logging.instance.log(
        "Refresh for "
        "${info.name}: ${DateTime.now().difference(start)}",
        level: LogLevel.Info,
      );
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
      // await  (await ChainHeightServiceManager.getService(cryptoCurrency))
      //     ?.cancelListen();
      case SyncingType.selectedWalletsAtStartup:
        // Close the subscription if this wallet is not in the list to be synced.
        if (!prefs.walletIdsSyncOnStartup.contains(walletId)) {
          // Check if there's another wallet of this coin on the sync list.
          final List<String> walletIds = [];
          for (final id in prefs.walletIdsSyncOnStartup) {
            final wallet = mainDB.isar.walletInfo
                .where()
                .walletIdEqualTo(id)
                .findFirstSync()!;

            if (wallet.coin == cryptoCurrency) {
              walletIds.add(id);
            }
          }
          // TODO [prio=low]: use a query instead of iterating thru wallets.

          // If there are no other wallets of this coin, then close the sub.
          if (walletIds.isEmpty) {
            // NOTE: This does not work now that the subscription is shared
            // await (await ChainHeightServiceManager.getService(
            //         cryptoCurrency))
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

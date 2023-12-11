import 'dart:async';

import 'package:isar/isar.dart';
import 'package:stackwallet/db/isar/main_db.dart';
import 'package:stackwallet/models/balance.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/address.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/transaction.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/utxo.dart';
import 'package:stackwallet/models/node_model.dart';
import 'package:stackwallet/models/paymint/fee_object_model.dart';
import 'package:stackwallet/services/coins/coin_service.dart';
import 'package:stackwallet/services/coins/tezos/api/tezos_api.dart';
import 'package:stackwallet/services/coins/tezos/api/tezos_rpc_api.dart';
import 'package:stackwallet/services/event_bus/events/global/node_connection_status_changed_event.dart';
import 'package:stackwallet/services/event_bus/events/global/updated_in_background_event.dart';
import 'package:stackwallet/services/event_bus/events/global/wallet_sync_status_changed_event.dart';
import 'package:stackwallet/services/event_bus/global_event_bus.dart';
import 'package:stackwallet/services/mixins/wallet_cache.dart';
import 'package:stackwallet/services/mixins/wallet_db.dart';
import 'package:stackwallet/services/node_service.dart';
import 'package:stackwallet/services/transaction_notification_tracker.dart';
import 'package:stackwallet/utilities/amount/amount.dart';
import 'package:stackwallet/utilities/constants.dart';
import 'package:stackwallet/utilities/default_nodes.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/utilities/flutter_secure_storage_interface.dart';
import 'package:stackwallet/utilities/logger.dart';
import 'package:stackwallet/utilities/prefs.dart';
import 'package:tezart/tezart.dart' as tezart;
import 'package:tuple/tuple.dart';

const int MINIMUM_CONFIRMATIONS = 1;
const int _gasLimit = 10200;

class TezosWallet extends CoinServiceAPI with WalletCache, WalletDB {
  TezosWallet({
    required String walletId,
    required String walletName,
    required Coin coin,
    required SecureStorageInterface secureStore,
    required TransactionNotificationTracker tracker,
    MainDB? mockableOverride,
  }) {
    txTracker = tracker;
    _walletId = walletId;
    _walletName = walletName;
    _coin = coin;
    _secureStore = secureStore;
    initCache(walletId, coin);
    initWalletDB(mockableOverride: mockableOverride);
  }

  NodeModel? _xtzNode;

  NodeModel getCurrentNode() {
    return _xtzNode ??
        NodeService(secureStorageInterface: _secureStore)
            .getPrimaryNodeFor(coin: Coin.tezos) ??
        DefaultNodes.getNodeFor(Coin.tezos);
  }

  Future<tezart.Keystore> getKeystore() async {
    return tezart.Keystore.fromMnemonic((await mnemonicString).toString());
  }

  @override
  String get walletId => _walletId;
  late String _walletId;

  @override
  String get walletName => _walletName;
  late String _walletName;

  @override
  set walletName(String name) => _walletName = name;

  @override
  set isFavorite(bool markFavorite) {
    _isFavorite = markFavorite;
    updateCachedIsFavorite(markFavorite);
  }

  @override
  bool get isFavorite => _isFavorite ??= getCachedIsFavorite();
  bool? _isFavorite;

  @override
  Coin get coin => _coin;
  late Coin _coin;

  late SecureStorageInterface _secureStore;
  late final TransactionNotificationTracker txTracker;
  final _prefs = Prefs.instance;

  Timer? timer;
  bool _shouldAutoSync = false;
  Timer? _networkAliveTimer;

  @override
  bool get shouldAutoSync => _shouldAutoSync;

  @override
  set shouldAutoSync(bool shouldAutoSync) {
    if (_shouldAutoSync != shouldAutoSync) {
      _shouldAutoSync = shouldAutoSync;
      if (!shouldAutoSync) {
        timer?.cancel();
        timer = null;
        stopNetworkAlivePinging();
      } else {
        startNetworkAlivePinging();
        refresh();
      }
    }
  }

  void startNetworkAlivePinging() {
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

  void stopNetworkAlivePinging() {
    _networkAliveTimer?.cancel();
    _networkAliveTimer = null;
  }

  void _periodicPingCheck() async {
    bool hasNetwork = await testNetworkConnection();

    if (_isConnected != hasNetwork) {
      NodeConnectionStatus status = hasNetwork
          ? NodeConnectionStatus.connected
          : NodeConnectionStatus.disconnected;

      GlobalEventBus.instance.fire(
        NodeConnectionStatusChangedEvent(
          status,
          walletId,
          coin,
        ),
      );

      _isConnected = hasNetwork;
      if (hasNetwork) {
        unawaited(refresh());
      }
    }
  }

  @override
  Balance get balance => _balance ??= getCachedBalance();
  Balance? _balance;

  Future<tezart.OperationsList> _buildSendTransaction({
    required Amount amount,
    required String address,
    required int counter,
  }) async {
    try {
      final sourceKeyStore = await getKeystore();
      final server = (_xtzNode ?? getCurrentNode()).host;
      final tezartClient = tezart.TezartClient(
        server,
      );

      final opList = await tezartClient.transferOperation(
        source: sourceKeyStore,
        destination: address,
        amount: amount.raw.toInt(),
      );

      for (final op in opList.operations) {
        op.counter = counter;
        counter++;
      }

      return opList;
    } catch (e, s) {
      Logging.instance.log(
        "Error in _buildSendTransaction() in tezos_wallet.dart: $e\n$s",
        level: LogLevel.Error,
      );
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>> prepareSend({
    required String address,
    required Amount amount,
    Map<String, dynamic>? args,
  }) async {
    try {
      if (amount.decimals != coin.decimals) {
        throw Exception("Amount decimals do not match coin decimals!");
      }

      if (amount > balance.spendable) {
        throw Exception("Insufficient available balance");
      }

      final myAddress = await currentReceivingAddress;
      final account = await TezosAPI.getAccount(
        myAddress,
      );

      final opList = await _buildSendTransaction(
        amount: amount,
        address: address,
        counter: account.counter + 1,
      );

      await opList.computeLimits();
      await opList.computeFees();
      await opList.simulate();

      Map<String, dynamic> txData = {
        "fee": Amount(
          rawValue: opList.operations
              .map(
                (e) => BigInt.from(e.fee),
              )
              .fold(
                BigInt.zero,
                (p, e) => p + e,
              ),
          fractionDigits: coin.decimals,
        ).raw.toInt(),
        "address": address,
        "recipientAmt": amount,
        "tezosOperationsList": opList,
      };
      return txData;
    } catch (e, s) {
      Logging.instance.log(
        "Error in prepareSend() in tezos_wallet.dart: $e\n$s",
        level: LogLevel.Error,
      );

      if (e
          .toString()
          .contains("(_operationResult['errors']): Must not be null")) {
        throw Exception("Probably insufficient balance");
      } else if (e.toString().contains(
            "The simulation of the operation: \"transaction\" failed with error(s) :"
            " contract.balance_too_low, tez.subtraction_underflow.",
          )) {
        throw Exception("Insufficient balance to pay fees");
      }

      rethrow;
    }
  }

  @override
  Future<String> confirmSend({required Map<String, dynamic> txData}) async {
    try {
      final opList = txData["tezosOperationsList"] as tezart.OperationsList;
      await opList.inject();
      await opList.monitor();
      return opList.result.id!;
    } catch (e, s) {
      Logging.instance.log("ConfirmSend: $e\n$s", level: LogLevel.Error);
      rethrow;
    }
  }

  @override
  Future<String> get currentReceivingAddress async {
    var mneString = await mnemonicString;
    if (mneString == null) {
      throw Exception("No mnemonic found!");
    }
    return Future.value((tezart.Keystore.fromMnemonic(mneString)).address);
  }

  @override
  Future<Amount> estimateFeeFor(Amount amount, int feeRate) async {
    return Amount(
      rawValue: BigInt.from(0),
      fractionDigits: coin.decimals,
    );
  }

  @override
  Future<void> exit() {
    _hasCalledExit = true;
    return Future.value();
  }

  @override
  Future<FeeObject> get fees async {
    int feePerTx = 0;
    return FeeObject(
      numberOfBlocksFast: 10,
      numberOfBlocksAverage: 10,
      numberOfBlocksSlow: 10,
      fast: feePerTx,
      medium: feePerTx,
      slow: feePerTx,
    );
  }

  @override
  Future<bool> generateNewAddress() {
    // TODO: implement generateNewAddress
    throw UnimplementedError();
  }

  @override
  bool get hasCalledExit => _hasCalledExit;
  bool _hasCalledExit = false;

  @override
  Future<void> initializeExisting() async {
    await _prefs.init();
  }

  @override
  Future<void> initializeNew(
    ({String mnemonicPassphrase, int wordCount})? data,
  ) async {
    if ((await mnemonicString) != null || (await mnemonicPassphrase) != null) {
      throw Exception(
          "Attempted to overwrite mnemonic on generate new wallet!");
    }

    await _prefs.init();

    var newKeystore = tezart.Keystore.random();
    await _secureStore.write(
      key: '${_walletId}_mnemonic',
      value: newKeystore.mnemonic,
    );
    await _secureStore.write(
      key: '${_walletId}_mnemonicPassphrase',
      value: "",
    );

    final address = Address(
      walletId: walletId,
      value: newKeystore.address,
      publicKey: [],
      derivationIndex: 0,
      derivationPath: null,
      type: AddressType.unknown,
      subType: AddressSubType.receiving,
    );

    await db.putAddress(address);

    await Future.wait([
      updateCachedId(walletId),
      updateCachedIsFavorite(false),
    ]);
  }

  @override
  bool get isConnected => _isConnected;
  bool _isConnected = false;

  @override
  bool get isRefreshing => refreshMutex;
  bool refreshMutex = false;

  @override
  // TODO: implement maxFee
  Future<int> get maxFee => throw UnimplementedError();

  @override
  Future<List<String>> get mnemonic async {
    final mnemonic = await mnemonicString;
    final mnemonicPassphrase = await this.mnemonicPassphrase;
    if (mnemonic == null) {
      throw Exception("No mnemonic found!");
    }
    if (mnemonicPassphrase == null) {
      throw Exception("No mnemonic passphrase found!");
    }
    return mnemonic.split(" ");
  }

  @override
  Future<String?> get mnemonicPassphrase =>
      _secureStore.read(key: '${_walletId}_mnemonicPassphrase');

  @override
  Future<String?> get mnemonicString =>
      _secureStore.read(key: '${_walletId}_mnemonic');

  Future<void> _recoverWalletFromSeedPhrase({
    required String mnemonic,
    required String mnemonicPassphrase,
    bool isRescan = false,
  }) async {
    final keystore = tezart.Keystore.fromMnemonic(
      mnemonic,
      password: mnemonicPassphrase,
    );

    final address = Address(
      walletId: walletId,
      value: keystore.address,
      publicKey: [],
      derivationIndex: 0,
      derivationPath: null,
      type: AddressType.unknown,
      subType: AddressSubType.receiving,
    );

    if (isRescan) {
      await db.updateOrPutAddresses([address]);
    } else {
      await db.putAddress(address);
    }
  }

  bool longMutex = false;
  @override
  Future<void> fullRescan(
    int maxUnusedAddressGap,
    int maxNumberOfIndexesToCheck,
  ) async {
    try {
      Logging.instance.log("Starting full rescan!", level: LogLevel.Info);
      longMutex = true;
      GlobalEventBus.instance.fire(
        WalletSyncStatusChangedEvent(
          WalletSyncStatus.syncing,
          walletId,
          coin,
        ),
      );

      final _mnemonic = await mnemonicString;
      final _mnemonicPassphrase = await mnemonicPassphrase;

      await db.deleteWalletBlockchainData(walletId);

      await _recoverWalletFromSeedPhrase(
        mnemonic: _mnemonic!,
        mnemonicPassphrase: _mnemonicPassphrase!,
        isRescan: true,
      );

      await refresh();
      Logging.instance.log("Full rescan complete!", level: LogLevel.Info);
      GlobalEventBus.instance.fire(
        WalletSyncStatusChangedEvent(
          WalletSyncStatus.synced,
          walletId,
          coin,
        ),
      );
    } catch (e, s) {
      GlobalEventBus.instance.fire(
        WalletSyncStatusChangedEvent(
          WalletSyncStatus.unableToSync,
          walletId,
          coin,
        ),
      );

      Logging.instance.log(
        "Exception rethrown from fullRescan(): $e\n$s",
        level: LogLevel.Error,
      );
      rethrow;
    } finally {
      longMutex = false;
    }
  }

  @override
  Future<void> recoverFromMnemonic({
    required String mnemonic,
    String? mnemonicPassphrase,
    required int maxUnusedAddressGap,
    required int maxNumberOfIndexesToCheck,
    required int height,
  }) async {
    longMutex = true;
    try {
      if ((await mnemonicString) != null ||
          (await this.mnemonicPassphrase) != null) {
        throw Exception("Attempted to overwrite mnemonic on restore!");
      }
      await _secureStore.write(
          key: '${_walletId}_mnemonic', value: mnemonic.trim());
      await _secureStore.write(
        key: '${_walletId}_mnemonicPassphrase',
        value: mnemonicPassphrase ?? "",
      );

      await _recoverWalletFromSeedPhrase(
        mnemonic: mnemonic,
        mnemonicPassphrase: mnemonicPassphrase ?? "",
        isRescan: false,
      );

      await Future.wait([
        updateCachedId(walletId),
        updateCachedIsFavorite(false),
      ]);

      await refresh();
    } catch (e, s) {
      Logging.instance.log(
          "Exception rethrown from recoverFromMnemonic(): $e\n$s",
          level: LogLevel.Error);

      rethrow;
    } finally {
      longMutex = false;
    }
  }

  Future<void> updateBalance() async {
    try {
      final node = getCurrentNode();
      final bal = await TezosRpcAPI.getBalance(
        address: await currentReceivingAddress,
        nodeInfo: (
          host: node.host,
          port: node.port,
        ),
      );
      Amount balanceInAmount =
          Amount(rawValue: bal ?? BigInt.zero, fractionDigits: coin.decimals);
      _balance = Balance(
        total: balanceInAmount,
        spendable: balanceInAmount,
        blockedTotal:
            Amount(rawValue: BigInt.parse("0"), fractionDigits: coin.decimals),
        pendingSpendable:
            Amount(rawValue: BigInt.parse("0"), fractionDigits: coin.decimals),
      );
      await updateCachedBalance(_balance!);
    } catch (e, s) {
      Logging.instance
          .log("ERROR GETTING BALANCE ${e.toString()}", level: LogLevel.Error);
    }
  }

  Future<void> updateTransactions() async {
    final txns = await TezosAPI.getTransactions(await currentReceivingAddress);
    List<Tuple2<Transaction, Address>> txs = [];
    for (var tx in txns) {
      if (tx.type == "transaction") {
        TransactionType txType;
        final String myAddress = await currentReceivingAddress;
        final String senderAddress = tx.senderAddress;
        final String targetAddress = tx.receiverAddress;
        if (senderAddress == myAddress && targetAddress == myAddress) {
          txType = TransactionType.sentToSelf;
        } else if (senderAddress == myAddress) {
          txType = TransactionType.outgoing;
        } else if (targetAddress == myAddress) {
          txType = TransactionType.incoming;
        } else {
          txType = TransactionType.unknown;
        }

        var theTx = Transaction(
          walletId: walletId,
          txid: tx.hash,
          timestamp: tx.timestamp,
          type: txType,
          subType: TransactionSubType.none,
          amount: tx.amountInMicroTez,
          amountString: Amount(
                  rawValue: BigInt.from(tx.amountInMicroTez),
                  fractionDigits: coin.decimals)
              .toJsonString(),
          fee: tx.feeInMicroTez,
          height: tx.height,
          isCancelled: false,
          isLelantus: false,
          slateId: "",
          otherData: "",
          inputs: [],
          outputs: [],
          nonce: 0,
          numberOfMessages: null,
        );
        final AddressSubType subType;
        switch (txType) {
          case TransactionType.incoming:
          case TransactionType.sentToSelf:
            subType = AddressSubType.receiving;
            break;
          case TransactionType.outgoing:
          case TransactionType.unknown:
            subType = AddressSubType.unknown;
            break;
        }
        final theAddress = Address(
          walletId: walletId,
          value: targetAddress,
          publicKey: [],
          derivationIndex: 0,
          derivationPath: null,
          type: AddressType.unknown,
          subType: subType,
        );
        txs.add(Tuple2(theTx, theAddress));
      }
    }
    Logging.instance.log("Transactions: $txs", level: LogLevel.Info);
    await db.addNewTransactionData(txs, walletId);
  }

  Future<void> updateChainHeight() async {
    try {
      final node = getCurrentNode();
      final int intHeight = (await TezosRpcAPI.getChainHeight(
        nodeInfo: (
          host: node.host,
          port: node.port,
        ),
      ))!;
      Logging.instance.log("Chain height: $intHeight", level: LogLevel.Info);
      await updateCachedChainHeight(intHeight);
    } catch (e, s) {
      Logging.instance
          .log("GET CHAIN HEIGHT ERROR ${e.toString()}", level: LogLevel.Error);
    }
  }

  @override
  Future<void> refresh() async {
    if (refreshMutex) {
      Logging.instance.log(
        "$walletId $walletName refreshMutex denied",
        level: LogLevel.Info,
      );
      return;
    } else {
      refreshMutex = true;
    }

    try {
      GlobalEventBus.instance.fire(
        WalletSyncStatusChangedEvent(
          WalletSyncStatus.syncing,
          walletId,
          coin,
        ),
      );

      await updateChainHeight();
      await updateBalance();
      await updateTransactions();
      GlobalEventBus.instance.fire(
        WalletSyncStatusChangedEvent(
          WalletSyncStatus.synced,
          walletId,
          coin,
        ),
      );

      if (shouldAutoSync) {
        timer ??= Timer.periodic(const Duration(seconds: 30), (timer) async {
          Logging.instance.log(
              "Periodic refresh check for $walletId $walletName in object instance: $hashCode",
              level: LogLevel.Info);

          await refresh();
          GlobalEventBus.instance.fire(
            UpdatedInBackgroundEvent(
              "New data found in $walletId $walletName in background!",
              walletId,
            ),
          );
        });
      }
    } catch (e, s) {
      Logging.instance.log(
        "Failed to refresh stellar wallet $walletId: '$walletName': $e\n$s",
        level: LogLevel.Warning,
      );
      GlobalEventBus.instance.fire(
        WalletSyncStatusChangedEvent(
          WalletSyncStatus.unableToSync,
          walletId,
          coin,
        ),
      );
    }

    refreshMutex = false;
  }

  @override
  int get storedChainHeight => getCachedChainHeight();

  @override
  Future<bool> testNetworkConnection() async {
    try {
      final node = getCurrentNode();
      return await TezosRpcAPI.testNetworkConnection(
        nodeInfo: (
          host: node.host,
          port: node.port,
        ),
      );
    } catch (e) {
      return false;
    }
  }

  @override
  Future<List<Transaction>> get transactions =>
      db.getTransactions(walletId).findAll();

  @override
  Future<void> updateNode(bool shouldRefresh) async {
    _xtzNode = NodeService(secureStorageInterface: _secureStore)
            .getPrimaryNodeFor(coin: coin) ??
        DefaultNodes.getNodeFor(coin);

    if (shouldRefresh) {
      await refresh();
    }
  }

  @override
  Future<void> updateSentCachedTxData(Map<String, dynamic> txData) async {
    // do nothing
  }

  @override
  // TODO: implement utxos
  Future<List<UTXO>> get utxos => throw UnimplementedError();

  @override
  bool validateAddress(String address) {
    return RegExp(r"^tz[1-9A-HJ-NP-Za-km-z]{34}$").hasMatch(address);
  }
}

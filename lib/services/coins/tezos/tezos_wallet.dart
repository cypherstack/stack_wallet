import 'dart:async';
import 'dart:convert';

import 'package:decimal/decimal.dart';
import 'package:http/http.dart';
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
import 'package:stackwallet/services/coins/tezos/api/tezos_transaction.dart';
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
import 'package:stackwallet/utilities/enums/fee_rate_type_enum.dart';
import 'package:stackwallet/utilities/flutter_secure_storage_interface.dart';
import 'package:stackwallet/utilities/logger.dart';
import 'package:stackwallet/utilities/prefs.dart';
import 'package:tezart/tezart.dart';
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

  TezosAPI tezosAPI = TezosAPI();

  NodeModel getCurrentNode() {
    return _xtzNode ??
        NodeService(secureStorageInterface: _secureStore)
            .getPrimaryNodeFor(coin: Coin.tezos) ??
        DefaultNodes.getNodeFor(Coin.tezos);
  }

  Future<Keystore> getKeystore() async {
    return Keystore.fromMnemonic((await mnemonicString).toString());
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

  @override
  Future<Map<String, dynamic>> prepareSend(
      {required String address,
      required Amount amount,
      Map<String, dynamic>? args}) async {
    try {
      if (amount.decimals != coin.decimals) {
        throw Exception("Amount decimals do not match coin decimals!");
      }
      var fee = int.parse((await estimateFeeFor(
              amount, (args!["feeRate"] as FeeRateType).index))
          .raw
          .toString());
      Map<String, dynamic> txData = {
        "fee": fee,
        "address": address,
        "recipientAmt": amount,
      };
      return Future.value(txData);
    } catch (e) {
      return Future.error(e);
    }
  }

  @override
  Future<String> confirmSend({required Map<String, dynamic> txData}) async {
    try {
      final amount = txData["recipientAmt"] as Amount;
      final amountInMicroTez = amount.decimal * Decimal.fromInt(1000000);
      final microtezToInt = int.parse(amountInMicroTez.toString());

      final int feeInMicroTez = int.parse(txData["fee"].toString());
      final String destinationAddress = txData["address"] as String;
      final secretKey =
          Keystore.fromMnemonic((await mnemonicString)!).secretKey;

      Logging.instance.log(secretKey, level: LogLevel.Info);
      final sourceKeyStore = Keystore.fromSecretKey(secretKey);
      final client = TezartClient(getCurrentNode().host);

      int? sendAmount = microtezToInt;
      int gasLimit = _gasLimit;
      int thisFee = feeInMicroTez;

      if (balance.spendable == txData["recipientAmt"] as Amount) {
        //Fee guides for emptying a tz account
        // https://github.com/TezTech/eztz/blob/master/PROTO_004_FEES.md
        thisFee = thisFee + 32;
        sendAmount = microtezToInt - thisFee;
        gasLimit = _gasLimit + 320;
      }

      final operation = await client.transferOperation(
          source: sourceKeyStore,
          destination: destinationAddress,
          amount: sendAmount,
          customFee: feeInMicroTez,
          customGasLimit: gasLimit);
      await operation.executeAndMonitor();
      return operation.result.id as String;
    } catch (e) {
      Logging.instance.log(e.toString(), level: LogLevel.Error);
      return Future.error(e);
    }
  }

  @override
  Future<String> get currentReceivingAddress async {
    var mneString = await mnemonicString;
    if (mneString == null) {
      throw Exception("No mnemonic found!");
    }
    return Future.value((Keystore.fromMnemonic(mneString)).address);
  }

  @override
  Future<Amount> estimateFeeFor(Amount amount, int feeRate) async {
    int? feePerTx = await tezosAPI.getFeeEstimationFromLastDays(1);
    feePerTx ??= 0;
    return Amount(
      rawValue: BigInt.from(feePerTx),
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
    int? feePerTx = await tezosAPI.getFeeEstimationFromLastDays(1);
    feePerTx ??= 0;
    Logging.instance.log("feePerTx:$feePerTx", level: LogLevel.Info);
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

    var newKeystore = Keystore.random();
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
    final keystore = Keystore.fromMnemonic(
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
      String balanceCall =
          "${getCurrentNode().host}:${getCurrentNode().port}/chains/main/blocks/head/context/contracts/${await currentReceivingAddress}/balance";
      var response =
          await get(Uri.parse(balanceCall)).then((value) => value.body);
      var balance = response.substring(1, response.length - 2);
      Amount balanceInAmount = Amount(
          rawValue: BigInt.parse(balance), fractionDigits: coin.decimals);
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
    List<TezosOperation>? txs =
        await tezosAPI.getTransactions(await currentReceivingAddress);
    Logging.instance.log("Transactions: $txs", level: LogLevel.Info);
    if (txs == null) {
      return;
    } else if (txs.isEmpty) {
      return;
    }
    List<Tuple2<Transaction, Address>> transactions = [];
    for (var theTx in txs) {
      var txType = TransactionType.unknown;
      var selfAddress = await currentReceivingAddress;
      if (selfAddress == theTx.senderAddress) {
        txType = TransactionType.outgoing;
      } else if (selfAddress == theTx.receiverAddress) {
        txType = TransactionType.incoming;
      } else if (selfAddress == theTx.receiverAddress &&
          selfAddress == theTx.senderAddress) {
        txType = TransactionType.sentToSelf;
      }
      var transaction = Transaction(
        walletId: walletId,
        txid: theTx.hash,
        timestamp: theTx.timestamp,
        type: txType,
        subType: TransactionSubType.none,
        amount: theTx.amountInMicroTez,
        amountString: Amount(
          rawValue: BigInt.parse(theTx.amountInMicroTez.toString()),
          fractionDigits: coin.decimals,
        ).toJsonString(),
        fee: theTx.feeInMicroTez,
        height: theTx.height,
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
        value: theTx.receiverAddress,
        publicKey: [],
        derivationIndex: 0,
        derivationPath: null,
        type: AddressType.unknown,
        subType: subType,
      );
      transactions.add(Tuple2(transaction, theAddress));
    }
    await db.addNewTransactionData(transactions, walletId);
  }

  Future<void> updateChainHeight() async {
    try {
      var api =
          "${getCurrentNode().host}:${getCurrentNode().port}/chains/main/blocks/head/header/shell";
      var jsonParsedResponse =
          jsonDecode(await get(Uri.parse(api)).then((value) => value.body));
      final int intHeight = int.parse(jsonParsedResponse["level"].toString());
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
        "Failed to refresh tezos wallet $walletId: '$walletName': $e\n$s",
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
      await get(Uri.parse(
          "${getCurrentNode().host}:${getCurrentNode().port}/chains/main/blocks/head/header/shell"));
      return true;
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
    final transaction = Transaction(
      walletId: walletId,
      txid: txData["txid"] as String,
      timestamp: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      type: TransactionType.outgoing,
      subType: TransactionSubType.none,
      // precision may be lost here hence the following amountString
      amount: (txData["recipientAmt"] as Amount).raw.toInt(),
      amountString: (txData["recipientAmt"] as Amount).toJsonString(),
      fee: txData["fee"] as int,
      height: null,
      isCancelled: false,
      isLelantus: false,
      otherData: null,
      slateId: null,
      nonce: null,
      inputs: [],
      outputs: [],
      numberOfMessages: null,
    );

    final address = txData["address"] is String
        ? await db.getAddress(walletId, txData["address"] as String)
        : null;

    await db.addNewTransactionData(
      [
        Tuple2(transaction, address),
      ],
      walletId,
    );
  }

  @override
  // TODO: implement utxos
  Future<List<UTXO>> get utxos => throw UnimplementedError();

  @override
  bool validateAddress(String address) {
    return RegExp(r"^tz[1-9A-HJ-NP-Za-km-z]{34}$").hasMatch(address);
  }
}

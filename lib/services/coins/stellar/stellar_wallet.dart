import 'dart:async';
import 'dart:io';

import 'package:decimal/decimal.dart';
import 'package:http/http.dart' as http;
import 'package:isar/isar.dart';
import 'package:stackwallet/models/balance.dart' as SWBalance;
import 'package:stackwallet/models/isar/models/blockchain_data/transaction.dart' as SWTransaction;
import 'package:stackwallet/models/isar/models/blockchain_data/address.dart' as SWAddress;
import 'package:stackwallet/models/isar/models/blockchain_data/utxo.dart';
import 'package:stackwallet/models/paymint/fee_object_model.dart';
import 'package:stackwallet/pages/wallet_view/sub_widgets/wallet_balance_toggle_sheet.dart';
import 'package:stackwallet/services/coins/coin_service.dart';
import 'package:stackwallet/services/mixins/coin_control_interface.dart';
import 'package:stackwallet/utilities/amount/amount.dart';
import 'package:stackwallet/utilities/enums/fee_rate_type_enum.dart';
import 'package:tuple/tuple.dart';

import '../../../db/isar/main_db.dart';
import '../../../models/node_model.dart';
import '../../../utilities/constants.dart';
import '../../../utilities/default_nodes.dart';
import '../../../utilities/enums/coin_enum.dart';
import '../../../utilities/flutter_secure_storage_interface.dart';
import '../../../utilities/logger.dart';
import '../../../utilities/prefs.dart';
import '../../event_bus/events/global/node_connection_status_changed_event.dart';
import '../../event_bus/events/global/updated_in_background_event.dart';
import '../../event_bus/events/global/wallet_sync_status_changed_event.dart';
import '../../event_bus/global_event_bus.dart';
import '../../mixins/wallet_cache.dart';
import '../../mixins/wallet_db.dart';
import '../../node_service.dart';
import '../../transaction_notification_tracker.dart';

import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

const int MINIMUM_CONFIRMATIONS = 1;

class StellarWallet extends CoinServiceAPI
    with WalletCache, WalletDB, CoinControlInterface {

  StellarWallet({
    required String walletId,
    required String walletName,
    required Coin coin,
    required TransactionNotificationTracker tracker,
    required SecureStorageInterface secureStore,
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

  late final TransactionNotificationTracker txTracker;
  late SecureStorageInterface _secureStore;

  final StellarSDK stellarSdk = StellarSDK.PUBLIC;

  @override
  bool get isFavorite => _isFavorite ??= getCachedIsFavorite();
  bool? _isFavorite;

  @override
  set isFavorite(bool isFavorite) {
    _isFavorite = isFavorite;
    updateCachedIsFavorite(isFavorite);
  }

  @override
  bool get shouldAutoSync => _shouldAutoSync;
  bool _shouldAutoSync = true;

  Timer? timer;

  final _prefs = Prefs.instance;

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

  Timer? _networkAliveTimer;

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
  String get walletName => _walletName;
  late String _walletName;

  @override
  set walletName(String name) => _walletName = name;

  @override
  SWBalance.Balance get balance => _balance ??= getCachedBalance();
  SWBalance.Balance? _balance;

  @override
  Coin get coin => _coin;
  late Coin _coin;

  @override
  Future<String> confirmSend({required Map<String, dynamic> txData}) {
    // TODO: implement confirmSend
    throw UnimplementedError();
  }

  Future<SWAddress.Address?> get _currentReceivingAddress =>
      db.getAddresses(walletId)
      .filter()
      .typeEqualTo(SWAddress.AddressType.unknown)
      .and()
      .subTypeEqualTo(SWAddress.AddressSubType.unknown)
      .sortByDerivationIndexDesc()
      .findFirst();

  @override
  Future<String> get currentReceivingAddress async =>
      (await _currentReceivingAddress)?.value ?? await getAddressSW();

  Future<int> getBaseFee() async {
    final nodeURI = Uri.parse("${getCurrentNode().host}:${getCurrentNode().port}");
    final httpClient = http.Client();
    FeeStatsResponse fsp = await FeeStatsRequestBuilder(httpClient, nodeURI).execute();
    return int.parse(fsp.lastLedgerBaseFee);
  }

  @override
  Future<Amount> estimateFeeFor(Amount amount, int feeRate) async {
    var baseFee = await getBaseFee();
    int fee = 100;
    switch (feeRate) {
      case 0:
        fee = baseFee * 10;
      case 1:
      case 2:
        fee = baseFee * 50;
      case 3:
        fee = baseFee * 100;
      case 4:
        fee = baseFee * 200;
      default:
        fee = baseFee * 50;
    }
    return Amount(rawValue: BigInt.from(fee), fractionDigits: coin.decimals);
  }

  @override
  Future<void> exit() {
    // TODO: implement exit
    throw UnimplementedError();
  }

  NodeModel? _xlmNode;

  NodeModel getCurrentNode() {
    if (_xlmNode != null) {
      return _xlmNode!;
    } else if (NodeService(secureStorageInterface: _secureStore).getPrimaryNodeFor(coin: coin) != null) {
      return NodeService(secureStorageInterface: _secureStore).getPrimaryNodeFor(coin: coin)!;
    } else {
      return DefaultNodes.getNodeFor(coin);
    }
  }

  @override
  Future<FeeObject> get fees async {
    final nodeURI = Uri.parse("${getCurrentNode().host}:${getCurrentNode().port}");
    final httpClient = http.Client();
    FeeStatsResponse fsp = await FeeStatsRequestBuilder(httpClient, nodeURI).execute();
    return FeeObject(
        numberOfBlocksFast: 0,
        numberOfBlocksAverage: 0,
        numberOfBlocksSlow: 0,
        fast: int.parse(fsp.lastLedgerBaseFee) * 100,
        medium: int.parse(fsp.lastLedgerBaseFee) * 50,
        slow: int.parse(fsp.lastLedgerBaseFee) * 10
    );
  }

  @override
  Future<void> fullRescan(int maxUnusedAddressGap, int maxNumberOfIndexesToCheck) async {
    await _prefs.init();
    await updateTransactions();
    await updateChainHeight();
    await updateBalance();
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
  Future<void> initializeNew() async {
    if ((await mnemonicString) != null || (await mnemonicPassphrase) != null) {
      throw Exception(
          "Attempted to overwrite mnemonic on generate new wallet!");
    }

    await _prefs.init();

    String mnemonic = await Wallet.generate24WordsMnemonic();
    final mnemonicArray = mnemonic.split(" ");
    await _secureStore.write(
        key: '${_walletId}_mnemonic',
        value: mnemonicArray.join(" ")
    );
    await _secureStore.write(
        key: '${_walletId}_mnemonicPassphrase',
        value: ""
    );

    Wallet wallet = await Wallet.from(mnemonic);
    KeyPair keyPair = await wallet.getKeyPair(index: 0);
    String address = keyPair.accountId;

    final swAddress = SWAddress.Address(
        walletId: walletId,
        value: address,
        publicKey: keyPair.publicKey,
        derivationIndex: 0,
        derivationPath: null,
        type: SWAddress.AddressType.unknown, // TODO: set type
        subType: SWAddress.AddressSubType.unknown
    );
    
    await db.putAddress(swAddress);
    
    await Future.wait([
      updateCachedId(walletId),
      updateCachedIsFavorite(false)
    ]);
  }

  Future<String> getAddressSW() async {
    var mnemonic = await _secureStore.read(
        key: '${_walletId}_mnemonic'
    );
    var wallet = await Wallet.from(mnemonic!);
    var keyPair = await wallet.getKeyPair(index: 0);
    return Future.value(keyPair.accountId);
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
  Future<List<String>> get mnemonic => mnemonicString.then((value) => value!.split(" "));

  @override
  Future<String?> get mnemonicPassphrase => _secureStore.read(key: '${_walletId}_mnemonicPassphrase');

  @override
  Future<String?> get mnemonicString => _secureStore.read(key: '${_walletId}_mnemonic');

  @override
  Future<Map<String, dynamic>> prepareSend({required String address, required Amount amount, Map<String, dynamic>? args}) async {
    try {
      final feeRate = args?["feeRate"];
      var fee = 1000;
      if (feeRate is FeeRateType) {
        final theFees = await fees;
        switch (feeRate) {
          case FeeRateType.fast:
            fee = theFees.fast;
          case FeeRateType.slow:
            fee = theFees.slow;
          case FeeRateType.average:
          default:
            fee = theFees.medium;
        }
      }
      Map<String, dynamic> txData = {
        "fee": fee,
        "address": address,
        "recipientAmt": amount,
      };

      Logging.instance.log("prepare send: $txData", level: LogLevel.Info);
      return txData;
    } catch (e, s) {
      Logging.instance.log("Error getting fees $e - $s", level: LogLevel.Error);
      rethrow;
    }
  }

  @override
  Future<void> recoverFromMnemonic({required String mnemonic, String? mnemonicPassphrase, required int maxUnusedAddressGap, required int maxNumberOfIndexesToCheck, required int height}) async {
    if ((await mnemonicString) != null ||
        (await this.mnemonicPassphrase) != null) {
      throw Exception("Attempted to overwrite mnemonic on restore!");
    }

    var wallet = await Wallet.from(mnemonic);
    var keyPair = await wallet.getKeyPair(index: 0);
    var address = keyPair.accountId;

    await _secureStore.write(
        key: '${_walletId}_mnemonic', value: mnemonic.trim());
    await _secureStore.write(
      key: '${_walletId}_mnemonicPassphrase',
      value: mnemonicPassphrase ?? "",
    );

    final swAddress = SWAddress.Address(
        walletId: walletId,
        value: address,
        publicKey: keyPair.publicKey,
        derivationIndex: 0,
        derivationPath: null,
        type: SWAddress.AddressType.unknown, // TODO: set type
        subType: SWAddress.AddressSubType.unknown
    );

    await db.putAddress(swAddress);

    await Future.wait([
      updateCachedId(walletId),
      updateCachedIsFavorite(false)
    ]);
  }

  Future<void> updateChainHeight() async {
    final height = await stellarSdk.ledgers
        .order(RequestBuilderOrder.DESC)
        .limit(1)
        .execute()
        .then((value) => value.records!.first.sequence);
    await updateCachedChainHeight(height);
  }

  Future<void> updateTransactions() async {
    List<Tuple2<SWTransaction.Transaction, SWAddress.Address?>> transactionList = [];
    Page<OperationResponse> payments = await stellarSdk.payments.forAccount(await getAddressSW()).order(RequestBuilderOrder.DESC).execute();
    for (OperationResponse response in payments.records!) {
      if (response is PaymentOperationResponse) {
        var por = response;
        SWTransaction.TransactionType type;
        if (por.sourceAccount == await getAddressSW()) {
          type = SWTransaction.TransactionType.outgoing;
        } else {
          type = SWTransaction.TransactionType.incoming;
        }
        final amount = Amount(
            rawValue: BigInt.parse(float.parse(por.amount!).toStringAsFixed(7).replaceAll(".", "")),
            fractionDigits: 7,
        );
        int fee = 0;
        int height = 0;
        var transaction = por.transaction;
        if (transaction != null) {
          fee = transaction.feeCharged!;
          height = transaction.ledger;
        }
        var theTransaction = SWTransaction.Transaction(
          walletId: walletId,
          txid: por.transactionHash!,
          timestamp: DateTime.parse(por.createdAt!).millisecondsSinceEpoch ~/ 1000,
          type: type,
          subType: SWTransaction.TransactionSubType.none,
          amount: 0,
          amountString: amount.toJsonString(),
          fee: fee,
          height: height,
          isCancelled: false,
          isLelantus: false,
          slateId: "",
          otherData: "",
          inputs: [],
          outputs: [],
          nonce: 0,
          numberOfMessages: null,
        );
        SWAddress.Address? receivingAddress = await _currentReceivingAddress;
        SWAddress.Address address = type == SWTransaction.TransactionType.incoming
            ? receivingAddress!
            : SWAddress.Address(
          walletId: walletId,
          value: por.sourceAccount!,
          publicKey: KeyPair.fromAccountId(por.sourceAccount!).publicKey,
          derivationIndex: 0,
          derivationPath: null,
          type: SWAddress.AddressType.unknown, // TODO: set type
          subType: SWAddress.AddressSubType.unknown
        );
        Tuple2<SWTransaction.Transaction, SWAddress.Address> tuple = Tuple2(theTransaction, address);
        transactionList.add(tuple);
      } else if (response is CreateAccountOperationResponse) {
        var caor = response;
        SWTransaction.TransactionType type;
        if (caor.sourceAccount == await getAddressSW()) {
          type = SWTransaction.TransactionType.outgoing;
        } else {
          type = SWTransaction.TransactionType.incoming;
        }
        final amount = Amount(
            rawValue: BigInt.parse(float.parse(caor.startingBalance!).toStringAsFixed(7).replaceAll(".", "")),
            fractionDigits: 7,
        );
        int fee = 0;
        int height = 0;
        var transaction = caor.transaction;
        if (transaction != null) {
          fee = transaction.feeCharged!;
          height = transaction.ledger;
        }
        var theTransaction = SWTransaction.Transaction(
          walletId: walletId,
          txid: caor.transactionHash!,
          timestamp: DateTime.parse(caor.createdAt!).millisecondsSinceEpoch ~/ 1000,
          type: type,
          subType: SWTransaction.TransactionSubType.none,
          amount: 0,
          amountString: amount.toJsonString(),
          fee: fee,
          height: height,
          isCancelled: false,
          isLelantus: false,
          slateId: "",
          otherData: "",
          inputs: [],
          outputs: [],
          nonce: 0,
          numberOfMessages: null,
        );
        SWAddress.Address? receivingAddress = await _currentReceivingAddress;
        SWAddress.Address address = type == SWTransaction.TransactionType.incoming
            ? receivingAddress!
            : SWAddress.Address(
            walletId: walletId,
            value: caor.sourceAccount!,
            publicKey: KeyPair.fromAccountId(caor.sourceAccount!).publicKey,
            derivationIndex: 0,
            derivationPath: null,
            type: SWAddress.AddressType.unknown, // TODO: set type
            subType: SWAddress.AddressSubType.unknown
        );
        Tuple2<SWTransaction.Transaction, SWAddress.Address> tuple = Tuple2(theTransaction, address);
        transactionList.add(tuple);
      }
    }
    await db.addNewTransactionData(transactionList, walletId);
  }

  Future<void> updateBalance() async {
    AccountResponse accountResponse = await stellarSdk.accounts.account(await getAddressSW());
    for (Balance balance in accountResponse.balances) {
      switch (balance.assetType) {
        case Asset.TYPE_NATIVE:
          _balance = SWBalance.Balance(
            total: Amount(
              rawValue: BigInt.from(float.parse(balance.balance) * 10000000 - 10000000), // Minus 1 XLM for account activation fee
              fractionDigits: 7,
            ),
            spendable: Amount(
              rawValue: BigInt.from(float.parse(balance.balance) * 10000000 - 10000000), // Minus 1 XLM for account activation fee
              fractionDigits: 7,
            ),
            blockedTotal: Amount(
              rawValue: BigInt.from(0),
              fractionDigits: 7,
            ),
            pendingSpendable: Amount(
              rawValue: BigInt.from(0),
              fractionDigits: 7,
            ),
          );
          Logging.instance.log(_balance, level: LogLevel.Info);
          await updateCachedBalance(_balance!);
      }
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
      await _prefs.init();

      GlobalEventBus.instance.fire(
        WalletSyncStatusChangedEvent(
          WalletSyncStatus.syncing,
          walletId,
          coin,
        ),
      );

      await updateChainHeight();
      await updateTransactions();
      await updateBalance();

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
  Future<bool> testNetworkConnection() {
    // TODO: implement testNetworkConnection
    throw UnimplementedError();
  }

  @override
  Future<List<SWTransaction.Transaction>> get transactions => db.getTransactions(walletId).findAll();

  @override
  Future<void> updateNode(bool shouldRefresh) async {
    _xlmNode = NodeService(secureStorageInterface: _secureStore)
        .getPrimaryNodeFor(coin: coin) ??
        DefaultNodes.getNodeFor(coin);

    if (shouldRefresh) {
      unawaited(refresh());
    }
  }

  @override
  Future<void> updateSentCachedTxData(Map<String, dynamic> txData) {
    // TODO: implement updateSentCachedTxData
    throw UnimplementedError();
  }

  @override
  // TODO: implement utxos
  Future<List<UTXO>> get utxos => throw UnimplementedError();

  @override
  bool validateAddress(String address) {
    return RegExp(r"^[G][A-Z0-9]{55}$").hasMatch(address);
  }

  @override
  String get walletId => _walletId;
  late String _walletId;
}
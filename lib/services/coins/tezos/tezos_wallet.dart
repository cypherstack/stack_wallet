import 'dart:async';

import 'package:http/http.dart';
import 'package:stackwallet/models/balance.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/address.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/transaction.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/utxo.dart';
import 'package:stackwallet/models/paymint/fee_object_model.dart';
import 'package:stackwallet/services/coins/coin_service.dart';
import 'package:stackwallet/services/node_service.dart';
import 'package:stackwallet/utilities/amount/amount.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/utilities/default_nodes.dart';

import 'package:tezart/tezart.dart';

import '../../../db/isar/main_db.dart';
import '../../../models/node_model.dart';
import '../../../utilities/flutter_secure_storage_interface.dart';
import '../../../utilities/logger.dart';
import '../../../utilities/prefs.dart';
import '../../mixins/wallet_cache.dart';
import '../../mixins/wallet_db.dart';
import '../../transaction_notification_tracker.dart';

const int MINIMUM_CONFIRMATIONS = 1;

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
    return _xtzNode ?? NodeService(secureStorageInterface: _secureStore).getPrimaryNodeFor(coin: Coin.tezos) ?? DefaultNodes.getNodeFor(Coin.tezos);
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

  @override
  bool get shouldAutoSync => _shouldAutoSync;

  @override
  set shouldAutoSync(bool shouldAutoSync) {
    if (_shouldAutoSync != shouldAutoSync) {
      _shouldAutoSync = shouldAutoSync;
      if (!shouldAutoSync) {
        timer?.cancel();
        timer = null;
      } else {
        refresh();
      }
    }
  }

  @override
  Balance get balance => _balance ??= getCachedBalance();
  Balance? _balance;

  @override
  Future<String> confirmSend({required Map<String, dynamic> txData}) {
    // TODO: implement confirmSend,
    // NOTE FROM DETHERMINAL: I couldnt write this function because I dont have any tezos to test with
    throw UnimplementedError();
  }

  @override
  Future<String> get currentReceivingAddress async {
    var mneString = await mnemonicString;
    if (mneString == null) {
      throw Exception("No mnemonic found!");
    }
    return Future.value(Keystore.fromMnemonic(mneString).address);
  }

  @override
  Future<Amount> estimateFeeFor(Amount amount, int feeRate) {
    // TODO: implement estimateFeeFor
    throw UnimplementedError();
  }

  @override
  Future<void> exit() {
    _hasCalledExit = true;
    return Future.value();
  }

  @override
  // TODO: implement fees
  Future<FeeObject> get fees => throw UnimplementedError();

  @override
  Future<void> fullRescan(int maxUnusedAddressGap, int maxNumberOfIndexesToCheck) {
    // TODO: implement fullRescan
    throw UnimplementedError();
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
        publicKey: [], // TODO: Add public key
        derivationIndex: 0,
        derivationPath: null,
        type: AddressType.unknown,
        subType: AddressSubType.unknown,
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
  Future<String?> get mnemonicPassphrase => _secureStore.read(key: '${_walletId}_mnemonicPassphrase');

  @override
  Future<String?> get mnemonicString => _secureStore.read(key: '${_walletId}_mnemonic');

  @override
  Future<Map<String, dynamic>> prepareSend({required String address, required Amount amount, Map<String, dynamic>? args}) {
    // TODO: implement prepareSend
    // NOTE FROM DETHERMINAL: I couldnt write this function because I dont have any tezos to test with
    throw UnimplementedError();
  }

  @override
  Future<void> recoverFromMnemonic({required String mnemonic, String? mnemonicPassphrase, required int maxUnusedAddressGap, required int maxNumberOfIndexesToCheck, required int height}) async {
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

    final address = Address(
        walletId: walletId,
        value: Keystore.fromMnemonic(mnemonic).address,
        publicKey: [], // TODO: Add public key
        derivationIndex: 0,
        derivationPath: null,
        type: AddressType.unknown,
        subType: AddressSubType.unknown,
    );

    await db.putAddress(address);

    await Future.wait([
      updateCachedId(walletId),
      updateCachedIsFavorite(false),
    ]);
  }

  Future<void> updateBalance() async {
    var api = "https://api.mainnet.tzkt.io/v1/accounts/${await currentReceivingAddress}/balance"; // TODO: Can we use current node instead of this?
    var theBalance = await get(Uri.parse(api)).then((value) => value.body);
    Logging.instance.log("Balance for ${await currentReceivingAddress}: $theBalance", level: LogLevel.Info);
    var balanceInAmount = Amount(rawValue: BigInt.parse(theBalance.toString()), fractionDigits: 6);
    _balance = Balance(
      total: balanceInAmount,
      spendable: balanceInAmount,
      blockedTotal: Amount(rawValue: BigInt.parse("0"), fractionDigits: 6),
      pendingSpendable: Amount(rawValue: BigInt.parse("0"), fractionDigits: 6),
    );
    await updateCachedBalance(_balance!);
  }

  @override
  Future<void> refresh() {
    updateBalance();
    return Future.value();
  }

  @override
  int get storedChainHeight => getCachedChainHeight();

  @override
  Future<bool> testNetworkConnection() {
    // TODO: implement testNetworkConnection
    throw UnimplementedError();
  }

  @override
  // TODO: implement transactions
  Future<List<Transaction>> get transactions async {
    // TODO: Maybe we can use this -> https://api.tzkt.io/#operation/Accounts_GetBalanceHistory
  }

  @override
  Future<void> updateNode(bool shouldRefresh) async {
    _xtzNode = NodeService(secureStorageInterface: _secureStore).getPrimaryNodeFor(coin: coin) ?? DefaultNodes.getNodeFor(coin);

    if (shouldRefresh) {
      await refresh();
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
    return RegExp(r"^tz[1-9A-HJ-NP-Za-km-z]{34}$").hasMatch(address);
  }
}

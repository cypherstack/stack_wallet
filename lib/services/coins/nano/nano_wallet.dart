import 'dart:convert';

import 'package:isar/isar.dart';
import 'package:nanodart/nanodart.dart';
import 'package:http/http.dart' as http;

import 'package:stackwallet/models/balance.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/transaction.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/utxo.dart';
import 'package:stackwallet/models/paymint/fee_object_model.dart';
import 'package:stackwallet/services/coins/coin_service.dart';
import 'package:stackwallet/services/mixins/coin_control_interface.dart';
import 'package:stackwallet/services/mixins/wallet_cache.dart';
import 'package:stackwallet/services/mixins/wallet_db.dart';
import 'package:stackwallet/utilities/amount/amount.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';

import '../../../db/isar/main_db.dart';
import '../../../models/isar/models/blockchain_data/address.dart';
import '../../../models/node_model.dart';
import '../../../utilities/default_nodes.dart';
import '../../../utilities/flutter_secure_storage_interface.dart';
import '../../../utilities/prefs.dart';
import '../../node_service.dart';
import '../../transaction_notification_tracker.dart';

import 'dart:async';

import 'package:stackwallet/models/isar/models/isar_models.dart';

const int MINIMUM_CONFIRMATIONS = 1;

class NanoWallet extends CoinServiceAPI with WalletCache, WalletDB, CoinControlInterface {
  NanoWallet({
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

  NodeModel? _xnoNode;

  @override
  Future<String?> get mnemonicPassphrase => _secureStore.read(
    key: '${_walletId}_mnemonicPassphrase',
  );

  @override
  Future<String?> get mnemonicString =>
      _secureStore.read(key: '${_walletId}_mnemonic');

  Future<String> getSeedFromMnemonic() async {
    var mnemonic = await mnemonicString;
    return NanoMnemomics.mnemonicListToSeed(mnemonic!.split(" "));
  }

  Future<String> getPrivateKeyFromMnemonic() async {
    var mnemonic = await mnemonicString;
    var seed = NanoMnemomics.mnemonicListToSeed(mnemonic!.split(" "));
    return NanoKeys.seedToPrivate(seed, 0);
  }

  Future<String> getAddressFromMnemonic() async {
    var mnemonic = await mnemonicString;
    var seed = NanoMnemomics.mnemonicListToSeed(mnemonic!.split(' '));
    var address = NanoAccounts.createAccount(NanoAccountType.NANO, NanoKeys.createPublicKey(NanoKeys.seedToPrivate(seed, 0)));
    return address;
  }

  Future<String> getPublicKeyFromMnemonic() async {
    var mnemonic = await mnemonicString;
    if (mnemonic == null) {
      return "";
    } else {
      var seed = NanoMnemomics.mnemonicListToSeed(mnemonic.split(" "));
      return NanoKeys.createPublicKey(NanoKeys.seedToPrivate(seed, 0));
    }
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

  bool _shouldAutoSync = false;

  @override
  bool get shouldAutoSync => _shouldAutoSync;

  @override
  set shouldAutoSync(bool shouldAutoSync) => _shouldAutoSync = shouldAutoSync;

  @override
  Balance get balance => _balance ??= getCachedBalance();
  Balance? _balance;

  @override
  Future<String> confirmSend({required Map<String, dynamic> txData}) {
    // TODO: implement confirmSend
    throw UnimplementedError();
  }

  @override
  Future<String> get currentReceivingAddress => getAddressFromMnemonic();

  @override
  Future<Amount> estimateFeeFor(Amount amount, int feeRate) {
    // TODO: implement estimateFeeFor
    throw UnimplementedError();
  }

  @override
  Future<void> exit() async {
    _hasCalledExit = true;
  }

  @override
  // TODO: implement fees
  Future<FeeObject> get fees => throw UnimplementedError();

  Future<void> updateBalance() async {
    final body = jsonEncode({
      "action": "account_balance",
      "account": await getAddressFromMnemonic(),
    });
    final headers = {
      "Content-Type": "application/json",
    };
    final response = await http.post(Uri.parse(getCurrentNode().host), headers: headers, body: body);
    final data = jsonDecode(response.body);
    _balance = Balance(
      total: Amount(rawValue: (BigInt.parse(data["balance"].toString()) + BigInt.parse(data["receivable"].toString())) ~/ BigInt.from(10).pow(23), fractionDigits: 7),
      spendable: Amount(rawValue: BigInt.parse(data["balance"].toString()) ~/ BigInt.from(10).pow(23), fractionDigits: 7),
      blockedTotal: Amount(rawValue: BigInt.parse("0"), fractionDigits: 30),
      pendingSpendable: Amount(rawValue: BigInt.parse(data["receivable"].toString()) ~/ BigInt.from(10).pow(23), fractionDigits: 7),
    );
    await updateCachedBalance(_balance!);
  }

  Future<void> confirmAllReceivable() async {
    // TODO: Implement this function
  }

  Future<void> updateTransactions() async {
    await confirmAllReceivable();
    final response = await http.post(Uri.parse(getCurrentNode().host), headers: {"Content-Type": "application/json"}, body: jsonEncode({"action": "account_history", "account": await getAddressFromMnemonic(), "count": "-1"}));
    final data = await jsonDecode(response.body);
    final transactions = data["history"] as List<dynamic>;
    if (transactions.isEmpty) {
      return;
    } else {
      List<Transaction> transactionList = [];
      for (var tx in transactions) {
        var typeString = tx["type"].toString();
        TransactionType type = TransactionType.unknown;
        if (typeString == "send") {
          type = TransactionType.outgoing;
        } else if (typeString == "receive") {
          type = TransactionType.incoming;
        }
        var intAmount = int.parse((BigInt.parse(tx["amount"].toString()) ~/ BigInt.from(10).pow(23)).toString());
        var strAmount = jsonEncode({
          "raw": intAmount.toString(),
          "fractionDigits": 7,
        });
        var transaction = Transaction(
            walletId: walletId,
            txid: tx["hash"].toString(),
            timestamp: int.parse(tx["local_timestamp"].toString()),
            type: type,
            subType: TransactionSubType.none,
            amount: intAmount,
            amountString: strAmount,
            fee: 0, // TODO: Use real fee?
            height: int.parse(tx["height"].toString()),
            isCancelled: false,
            isLelantus: false,
            slateId: "",
            otherData: "",
            inputs: [],
            outputs: [],
            nonce: 0
        );
        transactionList.add(transaction);
      }
      await db.putTransactions(transactionList);
      return;
    }
  }

  @override
  Future<void> fullRescan(int maxUnusedAddressGap, int maxNumberOfIndexesToCheck) async {
    await _prefs.init();
    await updateBalance();
    await updateTransactions();
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

    String seed = NanoSeeds.generateSeed();
    final mnemonic = NanoMnemomics.seedToMnemonic(seed);
    await _secureStore.write(
        key: '${_walletId}_mnemonic',
        value: mnemonic.join(' '),
    );
    await _secureStore.write(
      key: '${_walletId}_mnemonicPassphrase',
      value: "",
    );
    String privateKey = NanoKeys.seedToPrivate(seed, 0);
    String publicKey = NanoKeys.createPublicKey(privateKey);
    String publicAddress = NanoAccounts.createAccount(NanoAccountType.NANO, publicKey);

    final address = Address(
      walletId: walletId,
      value: publicAddress,
      publicKey: [], // TODO: add public key
      derivationIndex: 0,
      derivationPath: DerivationPath(),
      type: AddressType.unknown,
      subType: AddressSubType.receiving,
    );

    await db.putAddress(address);

    await Future.wait([
      updateCachedId(walletId),
      updateCachedIsFavorite(false)
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
  Future<List<String>> get mnemonic => _getMnemonicList();

  Future<List<String>> _getMnemonicList() async {
    final _mnemonicString = await mnemonicString;
    if (_mnemonicString == null) {
      return [];
    }
    final List<String> data = _mnemonicString.split(' ');
    return data;
  }

  @override
  Future<Map<String, dynamic>> prepareSend({required String address, required Amount amount, Map<String, dynamic>? args}) {
    // TODO: implement prepareSend
    throw UnimplementedError();
  }

  @override
  Future<void> recoverFromMnemonic({required String mnemonic, String? mnemonicPassphrase, required int maxUnusedAddressGap, required int maxNumberOfIndexesToCheck, required int height}) async {
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
      
      String seed = NanoMnemomics.mnemonicListToSeed(mnemonic.split(" "));
      String privateKey = NanoKeys.seedToPrivate(seed, 0);
      String publicKey = NanoKeys.createPublicKey(privateKey);
      String publicAddress = NanoAccounts.createAccount(NanoAccountType.NANO, publicKey);

      final address = Address(
        walletId: walletId,
        value: publicAddress,
        publicKey: [], // TODO: add public key
        derivationIndex: 0,
        derivationPath: DerivationPath()..value = "0/0", // TODO: Check if this is true
        type: AddressType.unknown,
        subType: AddressSubType.receiving,
      );

      await db.putAddress(address);

      await Future.wait([
        updateCachedId(walletId),
        updateCachedIsFavorite(false)
      ]);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> refresh() async {
    await _prefs.init();
    await updateBalance();
    await updateTransactions();
  }

  @override
  int get storedChainHeight => getCachedChainHeight();

  NodeModel getCurrentNode() {
    return _xnoNode ??
        NodeService(secureStorageInterface: _secureStore)
            .getPrimaryNodeFor(coin: coin) ??
        DefaultNodes.getNodeFor(coin);
  }
  
  @override
  Future<bool> testNetworkConnection() {
    http.get(Uri.parse("${getCurrentNode().host}?action=version")).then((response) {
      if (response.statusCode == 200) {
        return true;
      }
    });
    return Future.value(false);
  }

  @override
  Future<List<Transaction>> get transactions => db.getTransactions(walletId).findAll();

  @override
  Future<void> updateNode(bool shouldRefresh) async {
    _xnoNode = NodeService(secureStorageInterface: _secureStore)
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
    return NanoAccounts.isValid(NanoAccountType.NANO, address);
  }
}
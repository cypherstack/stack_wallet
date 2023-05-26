import 'dart:convert';

import 'package:isar/isar.dart';
import 'package:nanodart/nanodart.dart';
import 'package:http/http.dart' as http;

import 'package:stackwallet/models/balance.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/transaction.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/utxo.dart';
import 'package:stackwallet/models/paymint/fee_object_model.dart';
import 'package:stackwallet/services/coins/coin_service.dart';
import 'package:stackwallet/services/event_bus/events/global/wallet_sync_status_changed_event.dart';
import 'package:stackwallet/services/event_bus/global_event_bus.dart';
import 'package:stackwallet/services/mixins/coin_control_interface.dart';
import 'package:stackwallet/services/mixins/wallet_cache.dart';
import 'package:stackwallet/services/mixins/wallet_db.dart';
import 'package:stackwallet/utilities/amount/amount.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/utilities/enums/log_level_enum.dart';
import 'package:stackwallet/utilities/logger.dart';
import 'package:tuple/tuple.dart';

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
const String DEFAULT_REPRESENTATIVE =
    "nano_38713x95zyjsqzx6nm1dsom1jmm668owkeb9913ax6nfgj15az3nu8xkx579";

class NanoWallet extends CoinServiceAPI
    with WalletCache, WalletDB, CoinControlInterface {
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
    var address = NanoAccounts.createAccount(NanoAccountType.NANO,
        NanoKeys.createPublicKey(NanoKeys.seedToPrivate(seed, 0)));
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

  Future<String?> requestWork(String hash) async {
    return http
        .post(
      Uri.parse("https://rpc.nano.to"), // this should be a
      headers: {'Content-type': 'application/json'},
      body: json.encode(
        {
          "action": "work_generate",
          "hash": hash,
        },
      ),
    )
        .then((http.Response response) {
      if (response.statusCode == 200) {
        final Map<String, dynamic> decoded =
            json.decode(response.body) as Map<String, dynamic>;
        if (decoded.containsKey("error")) {
          throw Exception("Received error ${decoded["error"]}");
        }
        return decoded["work"] as String?;
      } else {
        throw Exception("Received error ${response.statusCode}");
      }
    });
  }

  @override
  Future<String> confirmSend({required Map<String, dynamic> txData}) async {
    try {
      // our address:
      final String publicAddress = await getAddressFromMnemonic();

      // first get the account balance:
      final balanceBody = jsonEncode({
        "action": "account_balance",
        "account": publicAddress,
      });
      final headers = {
        "Content-Type": "application/json",
      };
      final balanceResponse = await http.post(
        Uri.parse(getCurrentNode().host),
        headers: headers,
        body: balanceBody,
      );
      final balanceData = jsonDecode(balanceResponse.body);

      final BigInt currentBalance =
          BigInt.parse(balanceData["balance"].toString());
      final BigInt txAmount = txData["recipientAmt"].raw as BigInt;
      final BigInt balanceAfterTx = currentBalance - txAmount;

      // get the account info (we need the frontier and representative):
      final infoBody = jsonEncode({
        "action": "account_info",
        "representative": "true",
        "account": publicAddress,
      });
      final infoResponse = await http.post(
        Uri.parse(getCurrentNode().host),
        headers: headers,
        body: infoBody,
      );

      final String frontier =
          jsonDecode(infoResponse.body)["frontier"].toString();
      final String representative =
          jsonDecode(infoResponse.body)["representative"].toString();
      // link = destination address:
      final String link =
          NanoAccounts.extractPublicKey(txData["address"].toString());
      final String linkAsAccount = txData["address"].toString();

      // construct the send block:
      Map<String, String> sendBlock = {
        "type": "state",
        "account": publicAddress,
        "previous": frontier,
        "representative": representative,
        "balance": balanceAfterTx.toString(),
        "link": link,
      };

      // sign the send block:
      final String hash = NanoBlocks.computeStateHash(
        NanoAccountType.NANO,
        sendBlock["account"]!,
        sendBlock["previous"]!,
        sendBlock["representative"]!,
        BigInt.parse(sendBlock["balance"]!),
        sendBlock["link"]!,
      );
      final String privateKey = await getPrivateKeyFromMnemonic();
      final String signature = NanoSignatures.signBlock(hash, privateKey);

      // get PoW for the send block:
      final String? work = await requestWork(frontier);
      if (work == null) {
        throw Exception("Failed to get PoW for send block");
      }

      sendBlock["link_as_account"] = linkAsAccount;
      sendBlock["signature"] = signature;
      sendBlock["work"] = work;

      final processBody = jsonEncode({
        "action": "process",
        "json_block": "true",
        "subtype": "send",
        "block": sendBlock,
      });
      final processResponse = await http.post(
        Uri.parse(getCurrentNode().host),
        headers: headers,
        body: processBody,
      );

      final Map<String, dynamic> decoded =
          json.decode(processResponse.body) as Map<String, dynamic>;
      if (decoded.containsKey("error")) {
        throw Exception("Received error ${decoded["error"]}");
      }

      // return the hash of the transaction:
      return decoded["hash"].toString();
    } catch (e, s) {
      Logging.instance
          .log("Error sending transaction $e - $s", level: LogLevel.Error);
      rethrow;
    }
  }

  @override
  Future<String> get currentReceivingAddress => getAddressFromMnemonic();

  @override
  Future<Amount> estimateFeeFor(Amount amount, int feeRate) {
    // fees are always 0 :)
    return Future.value(
        Amount(rawValue: BigInt.from(0), fractionDigits: coin.decimals));
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
    final response = await http.post(Uri.parse(getCurrentNode().host),
        headers: headers, body: body);
    final data = jsonDecode(response.body);
    _balance = Balance(
      total: Amount(
          rawValue: (BigInt.parse(data["balance"].toString()) +
              BigInt.parse(data["receivable"].toString())),
          fractionDigits: coin.decimals),
      spendable: Amount(
          rawValue: BigInt.parse(data["balance"].toString()),
          fractionDigits: coin.decimals),
      blockedTotal:
          Amount(rawValue: BigInt.parse("0"), fractionDigits: coin.decimals),
      pendingSpendable: Amount(
          rawValue: BigInt.parse(data["receivable"].toString()),
          fractionDigits: coin.decimals),
    );
    await updateCachedBalance(_balance!);
  }

  Future<void> receiveBlock(
      String blockHash, String source, String amountRaw) async {
    // TODO: the opening block of an account is a special case
    bool openBlock = false;

    final headers = {
      "Content-Type": "application/json",
    };

    // our address:
    final String publicAddress = await getAddressFromMnemonic();

    // first check if the account is open:
    // get the account info (we need the frontier and representative):
    final infoBody = jsonEncode({
      "action": "account_info",
      "representative": "true",
      "account": publicAddress,
    });
    final infoResponse = await http.post(
      Uri.parse(getCurrentNode().host),
      headers: headers,
      body: infoBody,
    );
    final infoData = jsonDecode(infoResponse.body);

    if (infoData["error"] != null) {
      // account is not open yet, we need to create an open block:
      openBlock = true;
    }

    // first get the account balance:
    final balanceBody = jsonEncode({
      "action": "account_balance",
      "account": publicAddress,
    });

    final balanceResponse = await http.post(
      Uri.parse(getCurrentNode().host),
      headers: headers,
      body: balanceBody,
    );

    final balanceData = jsonDecode(balanceResponse.body);
    final BigInt currentBalance =
        BigInt.parse(balanceData["balance"].toString());
    final BigInt txAmount = BigInt.parse(amountRaw);
    final BigInt balanceAfterTx = currentBalance + txAmount;

    String frontier = infoData["frontier"].toString();
    String representative = infoData["representative"].toString();

    if (openBlock) {
      // we don't have a representative set yet:
      representative = DEFAULT_REPRESENTATIVE;
    }

    // link = send block hash:
    final String link = blockHash;
    // this "linkAsAccount" is meaningless:
    final String linkAsAccount =
        NanoAccounts.createAccount(NanoAccountType.NANO, blockHash);

    // construct the receive block:
    Map<String, String> receiveBlock = {
      "type": "state",
      "account": publicAddress,
      "previous": openBlock
          ? "0000000000000000000000000000000000000000000000000000000000000000"
          : frontier,
      "representative": representative,
      "balance": balanceAfterTx.toString(),
      "link": link,
      "link_as_account": linkAsAccount,
    };

    // sign the receive block:
    final String hash = NanoBlocks.computeStateHash(
      NanoAccountType.NANO,
      receiveBlock["account"]!,
      receiveBlock["previous"]!,
      receiveBlock["representative"]!,
      BigInt.parse(receiveBlock["balance"]!),
      receiveBlock["link"]!,
    );
    final String privateKey = await getPrivateKeyFromMnemonic();
    final String signature = NanoSignatures.signBlock(hash, privateKey);

    // get PoW for the receive block:
    String? work;
    if (openBlock) {
      work = await requestWork(NanoAccounts.extractPublicKey(publicAddress));
    } else {
      work = await requestWork(frontier);
    }
    if (work == null) {
      throw Exception("Failed to get PoW for receive block");
    }
    receiveBlock["link_as_account"] = linkAsAccount;
    receiveBlock["signature"] = signature;
    receiveBlock["work"] = work;

    // process the receive block:

    final processBody = jsonEncode({
      "action": "process",
      "json_block": "true",
      "subtype": "receive",
      "block": receiveBlock,
    });
    final processResponse = await http.post(
      Uri.parse(getCurrentNode().host),
      headers: headers,
      body: processBody,
    );

    final Map<String, dynamic> decoded =
        json.decode(processResponse.body) as Map<String, dynamic>;
    if (decoded.containsKey("error")) {
      throw Exception("Received error ${decoded["error"]}");
    }
  }

  Future<void> confirmAllReceivable() async {
    final receivableResponse = await http.post(Uri.parse(getCurrentNode().host),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "action": "receivable",
          "source": "true",
          "account": await getAddressFromMnemonic(),
          "count": "-1",
        }));

    final receivableData = await jsonDecode(receivableResponse.body);
    if (receivableData["blocks"] == "") {
      return;
    }
    final blocks = receivableData["blocks"] as Map<String, dynamic>;
    // confirm all receivable blocks:
    for (final blockHash in blocks.keys) {
      final block = blocks[blockHash];
      final String amountRaw = block["amount"] as String;
      final String source = block["source"] as String;
      await receiveBlock(blockHash, source, amountRaw);
      // a bit of a hack:
      await Future<void>.delayed(const Duration(seconds: 1));
    }
  }

  Future<void> updateTransactions() async {
    await confirmAllReceivable();
    final String publicAddress = await getAddressFromMnemonic();
    final response = await http.post(Uri.parse(getCurrentNode().host),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "action": "account_history",
          "account": publicAddress,
          "count": "-1",
        }));
    final data = await jsonDecode(response.body);
    final transactions = data["history"] as List<dynamic>;
    if (transactions.isEmpty) {
      return;
    } else {
      List<Tuple2<Transaction, Address?>> transactionList = [];
      for (var tx in transactions) {
        var typeString = tx["type"].toString();
        TransactionType transactionType = TransactionType.unknown;
        if (typeString == "send") {
          transactionType = TransactionType.outgoing;
        } else if (typeString == "receive") {
          transactionType = TransactionType.incoming;
        }
        final amount = Amount(
          rawValue: BigInt.parse(tx["amount"].toString()),
          fractionDigits: coin.decimals,
        );

        var transaction = Transaction(
          walletId: walletId,
          txid: tx["hash"].toString(),
          timestamp: int.parse(tx["local_timestamp"].toString()),
          type: transactionType,
          subType: TransactionSubType.none,
          amount: 0,
          amountString: amount.toJsonString(),
          fee: 0,
          height: int.parse(tx["height"].toString()),
          isCancelled: false,
          isLelantus: false,
          slateId: "",
          otherData: "",
          inputs: [],
          outputs: [],
          nonce: 0,
        );

        Address address = Address(
          walletId: walletId,
          publicKey: [],
          value: transactionType == TransactionType.incoming
              ? publicAddress
              : tx["account"].toString(),
          derivationIndex: 0,
          derivationPath: null,
          type: transactionType == TransactionType.incoming
              ? AddressType.nonWallet
              : AddressType.nano,
          subType: transactionType == TransactionType.incoming
              ? AddressSubType.receiving
              : AddressSubType.nonWallet,
        );
        Tuple2<Transaction, Address> tuple = Tuple2(transaction, address);
        transactionList.add(tuple);
      }

      await db.addNewTransactionData(transactionList, walletId);

      return;
    }
  }

  @override
  Future<void> fullRescan(
      int maxUnusedAddressGap, int maxNumberOfIndexesToCheck) async {
    await _prefs.init();
    await updateTransactions();
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
    String publicAddress =
        NanoAccounts.createAccount(NanoAccountType.NANO, publicKey);

    final address = Address(
      walletId: walletId,
      value: publicAddress,
      publicKey: [], // TODO: add public key
      derivationIndex: 0,
      derivationPath: null,
      type: AddressType.unknown,
      subType: AddressSubType.receiving,
    );

    await db.putAddress(address);

    await Future.wait(
        [updateCachedId(walletId), updateCachedIsFavorite(false)]);
  }

  @override
  bool get isConnected => _isConnected;

  bool _isConnected = false;

  @override
  bool get isRefreshing => refreshMutex;

  bool refreshMutex = false;

  @override
  Future<int> get maxFee => Future.value(0);

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
  Future<Map<String, dynamic>> prepareSend({
    required String address,
    required Amount amount,
    Map<String, dynamic>? args,
  }) async {
    try {
      int satAmount = amount.raw.toInt();
      int realfee = 0;

      if (balance.spendable == amount) {
        satAmount = balance.spendable.raw.toInt() - realfee;
      }

      Map<String, dynamic> txData = {
        "fee": realfee,
        "addresss": address,
        "recipientAmt": Amount(
          rawValue: BigInt.from(satAmount),
          fractionDigits: coin.decimals,
        ),
      };

      Logging.instance.log("prepare send: $txData", level: LogLevel.Info);
      return txData;
    } catch (e, s) {
      Logging.instance.log("Error getting fees $e - $s", level: LogLevel.Error);
      rethrow;
    }
  }

  @override
  Future<void> recoverFromMnemonic(
      {required String mnemonic,
      String? mnemonicPassphrase,
      required int maxUnusedAddressGap,
      required int maxNumberOfIndexesToCheck,
      required int height}) async {
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
      String publicAddress =
          NanoAccounts.createAccount(NanoAccountType.NANO, publicKey);

      final address = Address(
        walletId: walletId,
        value: publicAddress,
        publicKey: [], // TODO: add public key
        derivationIndex: 0,
        derivationPath: null,
        type: AddressType.unknown,
        subType: AddressSubType.receiving,
      );

      await db.putAddress(address);

      await Future.wait(
          [updateCachedId(walletId), updateCachedIsFavorite(false)]);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> refresh() async {
    await _prefs.init();

    GlobalEventBus.instance.fire(
      WalletSyncStatusChangedEvent(
        WalletSyncStatus.syncing,
        walletId,
        coin,
      ),
    );

    try {
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
    } catch (e) {
      GlobalEventBus.instance.fire(
        WalletSyncStatusChangedEvent(
          WalletSyncStatus.unableToSync,
          walletId,
          coin,
        ),
      );
    }
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
    http
        .get(Uri.parse("${getCurrentNode().host}?action=version"))
        .then((response) {
      if (response.statusCode == 200) {
        return true;
      }
    });
    return Future.value(false);
  }

  @override
  Future<List<Transaction>> get transactions =>
      db.getTransactions(walletId).findAll();

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

  Future<void> updateChainHeight() async {
    final String publicAddress = await getAddressFromMnemonic();
    // first get the account balance:
    final infoBody = jsonEncode({
      "action": "account_info",
      "account": publicAddress,
    });
    final headers = {
      "Content-Type": "application/json",
    };
    final infoResponse = await http.post(
      Uri.parse(getCurrentNode().host),
      headers: headers,
      body: infoBody,
    );
    final infoData = jsonDecode(infoResponse.body);

    final int height = int.parse(infoData["confirmation_height"].toString());
    await updateCachedChainHeight(height);
  }
}

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:decimal/decimal.dart';
import 'package:epicpay/hive/db.dart';
import 'package:epicpay/models/node_model.dart';
import 'package:epicpay/models/paymint/fee_object_model.dart';
import 'package:epicpay/models/paymint/transactions_model.dart';
import 'package:epicpay/models/paymint/utxo_model.dart';
import 'package:epicpay/pages/settings_views/network_settings_view/manage_nodes_views/add_edit_node_view.dart';
import 'package:epicpay/services/coins/coin_service.dart';
import 'package:epicpay/services/event_bus/events/global/blocks_remaining_event.dart';
import 'package:epicpay/services/event_bus/events/global/node_connection_status_changed_event.dart';
import 'package:epicpay/services/event_bus/events/global/refresh_percent_changed_event.dart';
import 'package:epicpay/services/event_bus/events/global/updated_in_background_event.dart';
import 'package:epicpay/services/event_bus/events/global/wallet_sync_status_changed_event.dart';
import 'package:epicpay/services/event_bus/global_event_bus.dart';
import 'package:epicpay/services/node_service.dart';
import 'package:epicpay/services/price.dart';
import 'package:epicpay/utilities/constants.dart';
import 'package:epicpay/utilities/default_nodes.dart';
import 'package:epicpay/utilities/enums/coin_enum.dart';
import 'package:epicpay/utilities/flutter_secure_storage_interface.dart';
import 'package:epicpay/utilities/logger.dart';
import 'package:epicpay/utilities/prefs.dart';
import 'package:epicpay/utilities/test_epic_node_connection.dart';
// import 'package:epicpay/utilities/test_epic_box_connection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_libepiccash/epic_cash.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart';
import 'package:mutex/mutex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:stack_wallet_backup/generate_password.dart';
import 'package:tuple/tuple.dart';

const int MINIMUM_CONFIRMATIONS = 10;

const String GENESIS_HASH_MAINNET = "";
const String GENESIS_HASH_TESTNET = "";

class BadEpicHttpAddressException implements Exception {
  final String? message;

  BadEpicHttpAddressException({this.message});

  @override
  String toString() {
    return "BadEpicHttpAddressException: $message";
  }
}

// isolate

Map<ReceivePort, Isolate> isolates = {};

Future<ReceivePort> getIsolate(Map<String, dynamic> arguments,
    {String name = ""}) async {
  ReceivePort receivePort =
      ReceivePort(); //port for isolate to receive messages.
  arguments['sendPort'] = receivePort.sendPort;
  Logging.instance.log("starting isolate ${arguments['function']} name: $name",
      level: LogLevel.Info);
  Isolate isolate = await Isolate.spawn(executeNative, arguments);
  isolates[receivePort] = isolate;
  return receivePort;
}

Future<void> executeNative(Map<String, dynamic> arguments) async {
  await Logging.instance.initInIsolate();
  final SendPort sendPort = arguments['sendPort'] as SendPort;
  final function = arguments['function'] as String;
  try {
    if (function == "scanOutPuts") {
      final wallet = arguments['wallet'] as String?;
      final startHeight = arguments['startHeight'] as int?;
      final numberOfBlocks = arguments['numberOfBlocks'] as int?;
      Map<String, dynamic> result = {};
      if (!(wallet == null || startHeight == null || numberOfBlocks == null)) {
        var outputs = await scanOutPuts(wallet, startHeight, numberOfBlocks);
        result['outputs'] = outputs;
        sendPort.send(result);
        return;
      }
    } else if (function == "getWalletInfo") {
      final wallet = arguments['wallet'] as String?;
      final refreshFromNode = arguments['refreshFromNode'] as int?;
      final minimumConfirmations = arguments['minimumConfirmations'] as int?;
      Map<String, dynamic> result = {};
      if (!(wallet == null ||
          refreshFromNode == null ||
          minimumConfirmations == null)) {
        var res =
            await getWalletInfo(wallet, refreshFromNode, minimumConfirmations);
        result['result'] = res;
        sendPort.send(result);
        return;
      }
    } else if (function == "getTransactions") {
      final wallet = arguments['wallet'] as String?;
      final refreshFromNode = arguments['refreshFromNode'] as int?;
      Map<String, dynamic> result = {};
      if (!(wallet == null || refreshFromNode == null)) {
        var res = await getTransactions(wallet, refreshFromNode);
        result['result'] = res;
        sendPort.send(result);
        return;
      }
    } else if (function == "startSync") {
      final wallet = arguments['wallet'] as String?;
      const int refreshFromNode = 1;
      Map<String, dynamic> result = {};
      if (!(wallet == null)) {
        var res = await getWalletInfo(wallet, refreshFromNode, 10);
        result['result'] = res;
        sendPort.send(result);
        return;
      }
    } else if (function == "getTransactionFees") {
      final wallet = arguments['wallet'] as String?;
      final amount = arguments['amount'] as int?;
      final minimumConfirmations = arguments['minimumConfirmations'] as int?;
      Map<String, dynamic> result = {};
      if (!(wallet == null || amount == null || minimumConfirmations == null)) {
        var res =
            await getTransactionFees(wallet, amount, minimumConfirmations);
        result['result'] = res;
        sendPort.send(result);
        return;
      }
    } else if (function == "createTransaction") {
      final wallet = arguments['wallet'] as String?;
      final amount = arguments['amount'] as int?;
      final address = arguments['address'] as String?;
      final secretKeyIndex = arguments['secretKeyIndex'] as int?;
      final epicboxConfig = arguments['epicboxConfig'] as String?;
      final minimumConfirmations = arguments['minimumConfirmations'] as int?;

      Map<String, dynamic> result = {};
      if (!(wallet == null ||
          amount == null ||
          address == null ||
          secretKeyIndex == null ||
          epicboxConfig == null ||
          minimumConfirmations == null)) {
        var res = await createTransaction(wallet, amount, address,
            secretKeyIndex, epicboxConfig, minimumConfirmations);
        result['result'] = res;
        sendPort.send(result);
        return;
      }
    } else if (function == "txHttpSend") {
      final wallet = arguments['wallet'] as String?;
      final selectionStrategyIsAll =
          arguments['selectionStrategyIsAll'] as int?;
      final minimumConfirmations = arguments['minimumConfirmations'] as int?;
      final message = arguments['message'] as String?;
      final amount = arguments['amount'] as int?;
      final address = arguments['address'] as String?;

      Map<String, dynamic> result = {};

      if (!(wallet == null ||
          selectionStrategyIsAll == null ||
          minimumConfirmations == null ||
          message == null ||
          amount == null ||
          address == null)) {
        var res = await txHttpSend(wallet, selectionStrategyIsAll,
            minimumConfirmations, message, amount, address);
        result['result'] = res;
        sendPort.send(result);
        return;
      }
    } else if (function == "listenForSlates") {
      final wallet = arguments['wallet'] as String?;
      final epicboxConfig = arguments['epicboxConfig'] as String?;

      Map<String, dynamic> result = {};
      if (!(wallet == null || epicboxConfig == null)) {
        var res = await epicboxListen(wallet, epicboxConfig);
        result['result'] = res;
        sendPort.send(result);
        return;
      }
    }
    Logging.instance.log(
        "Error Arguments for $function not formatted correctly",
        level: LogLevel.Fatal);
    sendPort.send("Error Arguments for $function not formatted correctly");
  } catch (e, s) {
    Logging.instance.log(
        "An error was thrown in this isolate $function: $e\n$s",
        level: LogLevel.Error);
    sendPort
        .send("Error An error was thrown in this isolate $function: $e\n$s");
  } finally {
    await Logging.instance.isar?.close();
  }
}

void stop(ReceivePort port) {
  Isolate? isolate = isolates.remove(port);
  if (isolate != null) {
    isolate.kill(priority: Isolate.immediate);
    isolate = null;
  }
}

// Keep Wrapper functions outside of the class to avoid memory leaks and errors about receive ports and illegal arguments.
// TODO: Can get rid of this wrapper and call it in a full isolate instead of compute() if we want more control over this
Future<String> _cancelTransactionWrapper(Tuple2<String, String> data) async {
  // assuming this returns an empty string on success
  // or an error message string on failure
  return cancelTransaction(data.item1, data.item2);
}

Future<String> _deleteWalletWrapper(String wallet) async {
  return deleteWallet(wallet);
}

Future<String> deleteEpicWallet({
  required String walletId,
  required FlutterSecureStorageInterface secureStore,
}) async {
  String? config = await secureStore.read(key: '${walletId}_config');
  if (Platform.isIOS) {
    Directory appDir = (await getApplicationDocumentsDirectory());
    if (Platform.isIOS) {
      appDir = (await getLibraryDirectory());
    }
    if (Platform.isLinux) {
      appDir = Directory("${appDir.path}/.epicmobile");
    }
    final path = "${appDir.path}/epicpay/epiccash";
    final String name = walletId;

    final walletDir = '$path/$name';
    var editConfig = jsonDecode(config as String);

    editConfig["wallet_dir"] = walletDir;
    config = jsonEncode(editConfig);
  }

  final wallet = await secureStore.read(key: '${walletId}_wallet');

  return compute(_deleteWalletWrapper, wallet!);
}

Future<String> _initWalletWrapper(
    Tuple4<String, String, String, String> data) async {
  final String initWalletStr =
      initWallet(data.item1, data.item2, data.item3, data.item4);
  return initWalletStr;
}

Future<String> _initGetAddressInfoWrapper(
    Tuple3<String, int, String> data) async {
  String walletAddress = getAddressInfo(data.item1, data.item2, data.item3);
  return walletAddress;
}

Future<String> _walletMnemonicWrapper(int throwaway) async {
  final String mnemonic = walletMnemonic();
  return mnemonic;
}

Future<String> _recoverWrapper(
    Tuple4<String, String, String, String> data) async {
  return recoverWallet(data.item1, data.item2, data.item3, data.item4);
}

Future<int> _getChainHeightWrapper(String config) async {
  try {
    final int chainHeight = getChainHeight(config);
    return chainHeight;
  } catch (_) {
    rethrow;
  }
}

class EpicCashWallet extends CoinServiceAPI {
  static const integrationTestFlag =
      bool.fromEnvironment("IS_INTEGRATION_TEST");
  final m = Mutex();
  final syncMutex = Mutex();

  final _prefs = Prefs.instance;

  NodeModel? _epicNode;

  EpicCashWallet(
      {required String walletId,
      required String walletName,
      required Coin coin,
      PriceAPI? priceAPI,
      FlutterSecureStorageInterface? secureStore}) {
    _walletId = walletId;
    _walletName = walletName;
    _coin = coin;

    _priceAPI = priceAPI ?? PriceAPI(Client());
    _secureStore =
        secureStore ?? const SecureStorageWrapper(FlutterSecureStorage());

    Logging.instance.log("$walletName isolate length: ${isolates.length}",
        level: LogLevel.Info);
    for (final isolate in isolates.values) {
      isolate.kill(priority: Isolate.immediate);
    }
    isolates.clear();
  }

  @override
  Future<void> updateNode(bool shouldRefresh) async {
    _epicNode = NodeService().getPrimaryNodeFor(coin: coin) ??
        DefaultNodes.getNodeFor(coin);
    // TODO notify ui/ fire event for node changed?

    String stringConfig = await getConfig();
    await _secureStore.write(key: '${_walletId}_config', value: stringConfig);

    if (shouldRefresh) {
      unawaited(refresh());
    }
  }

  @override
  set isFavorite(bool markFavorite) {
    DB.instance.put<dynamic>(
        boxName: walletId, key: "isFavorite", value: markFavorite);
  }

  @override
  bool get isFavorite {
    try {
      return DB.instance.get<dynamic>(boxName: walletId, key: "isFavorite")
          as bool;
    } catch (e, s) {
      Logging.instance.log(
          "isFavorite fetch failed (returning false by default): $e\n$s",
          level: LogLevel.Error);
      return false;
    }
  }

  @override
  Future<List<String>> get allOwnAddresses =>
      _allOwnAddresses ??= _fetchAllOwnAddresses();
  Future<List<String>>? _allOwnAddresses;

  Future<List<String>> _fetchAllOwnAddresses() async {
    List<String> addresses = [];
    final ownAddress = await _getCurrentAddressForChain(0);
    addresses.add(ownAddress);
    return addresses;
  }

  late ReceivePort receivePort;

  Future<String> startSync() async {
    Logging.instance.log("request start sync", level: LogLevel.Info);
    final wallet = await _secureStore.read(key: '${_walletId}_wallet');

    if (!syncMutex.isLocked) {
      await syncMutex.protect(() async {
        Logging.instance.log("sync started", level: LogLevel.Info);
        ReceivePort receivePort = await getIsolate({
          "function": "startSync",
          "wallet": wallet!,
        }, name: walletName);
        this.receivePort = receivePort;

        var message = await receivePort.first;
        if (message is String) {
          Logging.instance
              .log("this is a string $message", level: LogLevel.Error);
          stop(receivePort);
          throw Exception("startSync isolate failed");
        }
        stop(receivePort);
        Logging.instance
            .log('Closing startSync!\n  $message', level: LogLevel.Info);
        Logging.instance.log("sync ended", level: LogLevel.Info);
      });
    } else {
      Logging.instance.log("request start sync denied", level: LogLevel.Info);
    }
    return "";
  }

  Future<String> allWalletBalances() async {
    final wallet = await _secureStore.read(key: '${_walletId}_wallet');
    const refreshFromNode = 0;

    dynamic message;
    await m.protect(() async {
      ReceivePort receivePort = await getIsolate({
        "function": "getWalletInfo",
        "wallet": wallet!,
        "refreshFromNode": refreshFromNode,
        "minimumConfirmations": MINIMUM_CONFIRMATIONS,
      }, name: walletName);

      message = await receivePort.first;
      if (message is String) {
        Logging.instance
            .log("this is a string $message", level: LogLevel.Error);
        stop(receivePort);
        throw Exception("getWalletInfo isolate failed");
      }
      stop(receivePort);
      Logging.instance
          .log('Closing getWalletInfo!\n  $message', level: LogLevel.Info);
    });

    // return message;
    final String walletBalances = message['result'] as String;
    return walletBalances;
  }

  @override
  Future<Decimal> get availableBalance async {
    String walletBalances = await allWalletBalances();
    var jsonBalances = json.decode(walletBalances);
    final double spendable =
        jsonBalances['amount_currently_spendable'] as double;
    return Decimal.parse(spendable.toString());
  }

  @override
  // TODO: implement balanceMinusMaxFee
  Future<Decimal> get balanceMinusMaxFee => throw UnimplementedError();

  Timer? timer;
  late Coin _coin;

  @override
  Coin get coin => _coin;

  late FlutterSecureStorageInterface _secureStore;

  late PriceAPI _priceAPI;

  Future<String> cancelPendingTransactionAndPost(String txSlateId) async {
    String? result;
    try {
      result = await cancelPendingTransaction(txSlateId);
      Logging.instance.log("result?: $result", level: LogLevel.Info);
    } catch (e, s) {
      Logging.instance.log("$e, $s", level: LogLevel.Error);
    }
    return result!;
  }

  /// returns an empty String on success, error message on failure
  Future<String> cancelPendingTransaction(String tx_slate_id) async {
    final String wallet =
        (await _secureStore.read(key: '${_walletId}_wallet'))!;

    String? result;
    await m.protect(() async {
      result = await compute(
        _cancelTransactionWrapper,
        Tuple2(
          wallet,
          tx_slate_id,
        ),
      );
    });
    return result!;
  }

  @override
  Future<String> confirmSend({required Map<String, dynamic> txData}) async {
    try {
      final wallet = await _secureStore.read(key: '${_walletId}_wallet');
      final epicboxConfig = await getEpicBoxConfig();

      // TODO determine whether it is worth sending change to a change address.
      dynamic message;

      String receiverAddress = txData['addresss'] as String;
      await m.protect(() async {
        if (receiverAddress.startsWith("http://") ||
            receiverAddress.startsWith("https://")) {
          const int selectionStrategyIsAll = 0;
          ReceivePort receivePort = await getIsolate({
            "function": "txHttpSend",
            "wallet": wallet!,
            "selectionStrategyIsAll": selectionStrategyIsAll,
            "minimumConfirmations": MINIMUM_CONFIRMATIONS,
            "message": "",
            "amount": txData['recipientAmt'],
            "address": txData['addresss']
          }, name: walletName);

          message = await receivePort.first;
          if (message is String) {
            stop(receivePort);
            throw Exception("txHttpSend isolate failed");
          }
          stop(receivePort);
          Logging.instance
              .log('Closing txHttpSend!\n  $message', level: LogLevel.Info);
        } else {
          ReceivePort receivePort = await getIsolate({
            "function": "createTransaction",
            "wallet": wallet!,
            "amount": txData['recipientAmt'],
            "address": txData['addresss'],
            "secretKeyIndex": 0,
            "epicboxConfig": epicboxConfig!,
            "minimumConfirmations": MINIMUM_CONFIRMATIONS,
          }, name: walletName);

          message = await receivePort.first;
          if (message is String) {
            Logging.instance
                .log("this is a string $message", level: LogLevel.Error);
            stop(receivePort);
            throw Exception("createTransaction isolate failed");
          }
          stop(receivePort);
          Logging.instance.log('Closing createTransaction!\n  $message',
              level: LogLevel.Info);
        }
      });

      // return message;
      final String sendTx = message['result'] as String;
      if (sendTx.contains("Error")) {
        throw BadEpicHttpAddressException(message: sendTx);
      }

      await putSendToAddresses(sendTx);

      Logging.instance.log("CONFIRM_RESULT_IS $sendTx", level: LogLevel.Info);

      final decodeData = json.decode(sendTx);

      if (decodeData[0] == "transaction_failed") {
        String errorMessage = decodeData[1] as String;
        throw Exception("Transaction failed with error code $errorMessage");
      } else {
        final txCreateResult = decodeData[0];
        // //TODO: second problem
        final transaction = json.decode(txCreateResult as String);

        Logger.print("TX_IS $transaction");
        final tx = transaction[0];
        final txLogEntry = json.decode(tx as String);
        final txLogEntryFirst = txLogEntry[0];
        Logger.print("TX_LOG_ENTRY_IS $txLogEntryFirst");
        final wallet = await Hive.openBox<dynamic>(_walletId);
        final slateToAddresses =
            (await wallet.get("slate_to_address")) as Map? ?? {};
        final slateId = txLogEntryFirst['tx_slate_id'] as String;
        slateToAddresses[slateId] = txData['addresss'];
        await wallet.put('slate_to_address', slateToAddresses);
        final slatesToCommits = await getSlatesToCommits();
        String? commitId = slatesToCommits[slateId]?['commitId'] as String?;
        Logging.instance.log("sent commitId: $commitId", level: LogLevel.Info);
        return commitId!;
        // return txLogEntryFirst['tx_slate_id'] as String;
      }
    } catch (e, s) {
      Logging.instance.log("Error sending $e - $s", level: LogLevel.Error);
      rethrow;
    }
  }

  /// Returns the latest receiving/change (external/internal) address for the wallet depending on [chain]
  /// and
  /// [chain] - Use 0 for receiving (external), 1 for change (internal). Should not be any other value!
  Future<String> _getCurrentAddressForChain(
    int chain,
  ) async {
    final wallet = await _secureStore.read(key: '${_walletId}_wallet');

    final epicboxConfig = await getEpicBoxConfig();

    String? walletAddress;
    await m.protect(() async {
      walletAddress = await compute(
        _initGetAddressInfoWrapper,
        Tuple3(wallet!, chain, epicboxConfig!),
      );
    });
    Logging.instance
        .log("WALLET_ADDRESS_IS $walletAddress", level: LogLevel.Info);
    return walletAddress!;
  }

  @override
  Future<String> get currentReceivingAddress =>
      _currentReceivingAddress ??= _getCurrentAddressForChain(0);
  Future<String>? _currentReceivingAddress;

  @override
  Future<void> exit() async {
    _hasCalledExit = true;
    timer?.cancel();
    timer = null;
    stopNetworkAlivePinging();
    for (final isolate in isolates.values) {
      isolate.kill(priority: Isolate.immediate);
    }
    isolates.clear();
    Logging.instance.log("EpicCash_wallet exit finished", level: LogLevel.Info);
  }

  bool _hasCalledExit = false;

  @override
  bool get hasCalledExit => _hasCalledExit;

  Future<FeeObject> _getFees() async {
    // TODO: implement _getFees
    return FeeObject(
        numberOfBlocksFast: 10,
        numberOfBlocksAverage: 10,
        numberOfBlocksSlow: 10,
        fast: 1,
        medium: 1,
        slow: 1);
  }

  @override
  Future<FeeObject> get fees => _feeObject ??= _getFees();
  Future<FeeObject>? _feeObject;

  @override
  Future<void> fullRescan(
    int maxUnusedAddressGap,
    int maxNumberOfIndexesToCheck,
  ) async {
    refreshMutex = true;
    try {
      GlobalEventBus.instance.fire(
        WalletSyncStatusChangedEvent(
          WalletSyncStatus.syncing,
          walletId,
          coin,
        ),
      );

      await DB.instance.put<dynamic>(
          boxName: walletId,
          key: "lastScannedBlock",
          value: await getRestoreHeight());

      if (!await startScans()) {
        refreshMutex = false;
        GlobalEventBus.instance.fire(
          NodeConnectionStatusChangedEvent(
            NodeConnectionStatus.disconnected,
            walletId,
            coin,
          ),
        );
        GlobalEventBus.instance.fire(
          WalletSyncStatusChangedEvent(
            WalletSyncStatus.unableToSync,
            walletId,
            coin,
          ),
        );
        return;
      }
      GlobalEventBus.instance.fire(
        WalletSyncStatusChangedEvent(
          WalletSyncStatus.synced,
          walletId,
          coin,
        ),
      );
    } catch (e, s) {
      refreshMutex = false;
      Logging.instance
          .log("$e, $s", level: LogLevel.Error, printFullLength: true);
    }
    refreshMutex = false;
    return;
  }

  @override
  Future<void> initializeExisting() async {
    Logging.instance.log("Opening existing ${coin.prettyName} wallet",
        level: LogLevel.Info);

    final config = await getRealConfig();
    final password = await _secureStore.read(key: '${_walletId}_password');

    final walletOpen = openWallet(config, password!);
    await _secureStore.write(key: '${_walletId}_wallet', value: walletOpen);

    if ((DB.instance.get<dynamic>(boxName: walletId, key: "id")) == null) {
      throw Exception(
          "Attempted to initialize an existing wallet using an unknown wallet ID!");
    }
    await _prefs.init();
    await updateNode(false);
    final data =
        DB.instance.get<dynamic>(boxName: walletId, key: "latest_tx_model")
            as TransactionData?;
    if (data != null) {
      _transactionData = Future(() => data);
      txCount = data.getAllTransactions().length;
    }
    //Open Epicbox listener in the background
    await listenForSlates();
    // TODO: is there anything else that should be set up here whenever this wallet is first loaded again?
  }

  Timer? t;
  int _txCount = 0;

  set txCount(int value) {
    if (_txCount != value) {
      _txCount = value;
      GlobalEventBus.instance.fire(
        UpdatedInBackgroundEvent(
          "tx count changed",
          walletId,
        ),
      );
    }
  }

  @override
  int get txCount => _txCount;

  Future<void> storeEpicboxInfo() async {
    final wallet = await _secureStore.read(key: '${_walletId}_wallet');
    int index = 0;

    Logging.instance.log("This index is $index", level: LogLevel.Info);
    final epicboxConfig = await getEpicBoxConfig();

    String? walletAddress;
    await m.protect(() async {
      walletAddress = await compute(
        _initGetAddressInfoWrapper,
        Tuple3(wallet!, index, epicboxConfig!),
      );
    });
    Logging.instance
        .log("WALLET_ADDRESS_IS $walletAddress", level: LogLevel.Info);
    Logging.instance
        .log("Wallet address is $walletAddress", level: LogLevel.Info);
    String addressInfo = walletAddress!;
    await _secureStore.write(
        key: '${_walletId}_address_info', value: addressInfo);
  }

  // TODO: make more robust estimate of date maybe using https://explorer.epic.tech/api-index
  int calculateRestoreHeightFrom({required DateTime date}) {
    int secondsSinceEpoch = date.millisecondsSinceEpoch ~/ 1000;
    const int epicCashFirstBlock = 1565370278;
    const double overestimateSecondsPerBlock = 61;
    int chosenSeconds = secondsSinceEpoch - epicCashFirstBlock;
    int approximateHeight = chosenSeconds ~/ overestimateSecondsPerBlock;
    debugPrint(
        "approximate height: $approximateHeight chosen_seconds: $chosenSeconds");
    int height = approximateHeight;
    if (height < 0) {
      height = 0;
    }
    return height;
  }

  @override
  Future<void> initializeNew() async {
    await _prefs.init();
    await updateNode(false);
    final mnemonic = await _getMnemonicList();
    final String mnemonicString = mnemonic.join(" ");

    final String password = generatePassword();
    String stringConfig = await getConfig();
    String epicboxConfig = await getEpicBoxConfig();

    await _secureStore.write(
        key: '${_walletId}_mnemonic', value: mnemonicString);
    await _secureStore.write(key: '${_walletId}_config', value: stringConfig);
    await _secureStore.write(key: '${_walletId}_password', value: password);
    await _secureStore.write(
        key: '${_walletId}_epicboxConfig', value: epicboxConfig);

    String name = _walletId;

    await m.protect(() async {
      await compute(
        _initWalletWrapper,
        Tuple4(
          stringConfig,
          mnemonicString,
          password,
          name,
        ),
      );
    });

    //Open wallet
    final walletOpen = openWallet(stringConfig, password);
    await _secureStore.write(key: '${_walletId}_wallet', value: walletOpen);

    //Store Epic box address info
    await storeEpicboxInfo();

    // subtract a couple days to ensure we have a buffer for SWB
    final bufferedCreateHeight = calculateRestoreHeightFrom(
        date: DateTime.now().subtract(const Duration(days: 2)));

    await DB.instance.put<dynamic>(
        boxName: walletId, key: "restoreHeight", value: bufferedCreateHeight);

    await DB.instance
        .put<dynamic>(boxName: walletId, key: "id", value: _walletId);
    await DB.instance.put<dynamic>(
        boxName: walletId, key: 'receivingAddresses', value: ["0"]);
    await DB.instance
        .put<dynamic>(boxName: walletId, key: "receivingIndex", value: 0);
    await DB.instance
        .put<dynamic>(boxName: walletId, key: "changeIndex", value: 0);
    await DB.instance.put<dynamic>(
      boxName: walletId,
      key: 'blocked_tx_hashes',
      value: ["0xdefault"],
    ); // A list of transaction hashes to represent frozen utxos in wallet
    // initialize address book entries
    await DB.instance.put<dynamic>(
        boxName: walletId,
        key: 'addressBookEntries',
        value: <String, String>{});
    await DB.instance
        .put<dynamic>(boxName: walletId, key: "isFavorite", value: false);

    //Open Epicbox listener in the background
    await listenForSlates();
  }

  bool refreshMutex = false;

  @override
  bool get isRefreshing => refreshMutex;

  @override
  // TODO: implement maxFee
  Future<int> get maxFee => throw UnimplementedError();

  Future<List<String>> _getMnemonicList() async {
    if ((await _secureStore.read(key: '${_walletId}_mnemonic')) != null) {
      final mnemonicString =
          await _secureStore.read(key: '${_walletId}_mnemonic');
      final List<String> data = mnemonicString!.split(' ');
      return data;
    } else {
      String? mnemonicString;
      await m.protect(() async {
        mnemonicString = await compute(
          _walletMnemonicWrapper,
          0,
        );
      });
      await _secureStore.write(
          key: '${_walletId}_mnemonic', value: mnemonicString);
      final List<String> data = mnemonicString!.split(' ');
      return data;
    }
  }

  @override
  Future<List<String>> get mnemonic => _getMnemonicList();

  @override
  Future<Decimal> get pendingBalance async {
    String walletBalances = await allWalletBalances();
    final jsonBalances = json.decode(walletBalances);
    final double pending =
        jsonBalances['amount_awaiting_confirmation'] as double;
    return Decimal.parse(pending.toString());
  }

  @override
  Future<Map<String, dynamic>> prepareSend(
      {required String address,
      required int satoshiAmount,
      Map<String, dynamic>? args}) async {
    try {
      int realfee = await nativeFee(satoshiAmount);

      Map<String, dynamic> txData = {
        "fee": realfee,
        "addresss": address,
        "recipientAmt": satoshiAmount,
      };

      Logging.instance.log("prepare send: $txData", level: LogLevel.Info);
      return txData;
    } catch (e, s) {
      Logging.instance.log("Error getting fees $e - $s", level: LogLevel.Error);
      rethrow;
    }
  }

  Future<int> nativeFee(int satoshiAmount,
      {bool ifErrorEstimateFee = false}) async {
    final wallet = await _secureStore.read(key: '${_walletId}_wallet');

    try {
      String? transactionFees;
      await m.protect(() async {
        ReceivePort receivePort = await getIsolate({
          "function": "getTransactionFees",
          "wallet": wallet!,
          "amount": satoshiAmount,
          "minimumConfirmations": MINIMUM_CONFIRMATIONS,
        }, name: walletName);

        var message = await receivePort.first;
        if (message is String) {
          Logging.instance
              .log("this is a string $message", level: LogLevel.Error);
          stop(receivePort);
          throw Exception("getTransactionFees isolate failed");
        }
        stop(receivePort);
        Logging.instance.log('Closing getTransactionFees!\n  $message',
            level: LogLevel.Info);
        // return message;
        transactionFees = message['result'] as String;
      });
      // debugPrint(transactionFees);
      dynamic decodeData;
      try {
        decodeData = json.decode(transactionFees!);
      } catch (e) {
        if (ifErrorEstimateFee) {
          //Error Not enough funds. Required: 0.56500000, Available: 0.56200000
          if (transactionFees!.contains("Required")) {
            var splits = transactionFees!.split(" ");
            Decimal required = Decimal.zero;
            Decimal available = Decimal.zero;
            for (int i = 0; i < splits.length; i++) {
              var word = splits[i];
              if (word == "Required:") {
                required = Decimal.parse(splits[i + 1].replaceAll(",", ""));
              } else if (word == "Available:") {
                available = Decimal.parse(splits[i + 1].replaceAll(",", ""));
              }
            }
            int largestSatoshiFee =
                ((required - available) * Decimal.fromInt(100000000))
                    .toBigInt()
                    .toInt();
            Logging.instance.log("largestSatoshiFee $largestSatoshiFee",
                level: LogLevel.Info);
            return largestSatoshiFee;
          }
        }
        rethrow;
      }

      //TODO: first problem
      int realfee = 0;
      try {
        var txObject = decodeData[0];
        realfee =
            (Decimal.parse(txObject["fee"].toString())).toBigInt().toInt();
      } catch (e, s) {
        debugPrint("$e $s");
      }

      return realfee;
    } catch (e, s) {
      Logging.instance.log("Error getting fees $e - $s", level: LogLevel.Error);
      rethrow;
    }
  }

  Future<String> currentWalletDirPath() async {
    Directory appDir = (await getApplicationDocumentsDirectory());
    if (Platform.isIOS) {
      appDir = (await getLibraryDirectory());
    }
    if (Platform.isLinux) {
      appDir = Directory("${appDir.path}/.epicmobile");
    }
    final path = "${appDir.path}/epicpay/epiccash";
    final String name = _walletId.trim();
    return '$path/$name';
  }

  Future<String> getConfig() async {
    if (_epicNode == null) {
      await updateNode(false);
    }
    final NodeModel node = _epicNode!;

    final String nodeAddress = node.host;
    int port = node.port;

    Uri uri = Uri.parse(nodeAddress);
    uri = uri.replace(port: port);

    final String nodeApiAddress = uri.toString();
    final walletDir = await currentWalletDirPath();

    final Map<String, dynamic> config = {};
    config["wallet_dir"] = walletDir;
    config["check_node_api_http_addr"] = nodeApiAddress;
    config["chain"] = "mainnet";
    config["account"] = "default";
    config["api_listen_port"] = port;
    config["api_listen_interface"] =
        nodeApiAddress.replaceFirst(uri.scheme, "");
    String stringConfig = json.encode(config);
    return stringConfig;
  }

  Future<String> getEpicBoxConfig() async {
    final storedConfig =
        await _secureStore.read(key: '${_walletId}_epicboxConfig');
    if (storedConfig != null) {
      final decoded = json.decode(storedConfig!);
      final domain = decoded["domain"] ?? "empty";
      if (domain != "empty") {
        //If we have the old invalid config - update
        await _secureStore.write(
            key: '${_walletId}_epicboxConfig',
            value: DefaultNodes.defaultEpicBoxConfig);
      }
      return await _secureStore.read(key: '${_walletId}_epicboxConfig') ??
          DefaultNodes.defaultEpicBoxConfig;
    }
    return DefaultNodes.defaultEpicBoxConfig;
  }

  Future<String> getRealConfig() async {
    String? config = await _secureStore.read(key: '${_walletId}_config');
    if (Platform.isIOS) {
      final walletDir = await currentWalletDirPath();
      var editConfig = jsonDecode(config as String);

      editConfig["wallet_dir"] = walletDir;
      config = jsonEncode(editConfig);
    }
    return config!;
  }

  Future<void> updateEpicboxConfig(String host, int port) async {
    String stringConfig = jsonEncode({
      "epicbox_domain": host,
      "epicbox_port": port,
      "epicbox_protocol_unsecure": false,
      "epicbox_address_index": 0,
    });
    await _secureStore.write(
        key: '${_walletId}_epicboxConfig', value: stringConfig);
    // TODO: refresh anything that needs to be refreshed/updated due to epicbox info changed
  }

  Future<bool> startScans() async {
    try {
      final wallet = await _secureStore.read(key: '${_walletId}_wallet');

      var restoreHeight =
          DB.instance.get<dynamic>(boxName: walletId, key: "restoreHeight");
      var chainHeight = await this.chainHeight;
      if (!DB.instance.containsKey<dynamic>(
              boxName: walletId, key: 'lastScannedBlock') ||
          DB.instance
                  .get<dynamic>(boxName: walletId, key: 'lastScannedBlock') ==
              null) {
        await DB.instance.put<dynamic>(
            boxName: walletId,
            key: "lastScannedBlock",
            value: await getRestoreHeight());
      }
      int lastScannedBlock = DB.instance
          .get<dynamic>(boxName: walletId, key: 'lastScannedBlock') as int;
      const MAX_PER_LOOP = 10000;
      await getSyncPercent;
      for (; lastScannedBlock < chainHeight;) {
        chainHeight = await this.chainHeight;
        lastScannedBlock = DB.instance
            .get<dynamic>(boxName: walletId, key: 'lastScannedBlock') as int;
        Logging.instance.log(
            "chainHeight: $chainHeight, restoreHeight: $restoreHeight, lastScannedBlock: $lastScannedBlock",
            level: LogLevel.Info);
        int? nextScannedBlock;
        await m.protect(() async {
          ReceivePort receivePort = await getIsolate({
            "function": "scanOutPuts",
            "wallet": wallet!,
            "startHeight": lastScannedBlock,
            "numberOfBlocks": MAX_PER_LOOP,
          }, name: walletName);

          var message = await receivePort.first;
          if (message is String) {
            Logging.instance
                .log("this is a string $message", level: LogLevel.Error);
            stop(receivePort);
            throw Exception("scanOutPuts isolate failed");
          }
          nextScannedBlock = int.parse(message['outputs'] as String);
          stop(receivePort);
          Logging.instance
              .log('Closing scanOutPuts!\n  $message', level: LogLevel.Info);
        });
        await DB.instance.put<dynamic>(
            boxName: walletId,
            key: "lastScannedBlock",
            value: nextScannedBlock!);
        await getSyncPercent;
      }
      Logging.instance.log("successfully at the tip", level: LogLevel.Info);
      return true;
    } catch (e, s) {
      Logging.instance.log("$e, $s", level: LogLevel.Warning);
      return false;
    }
  }

  Future<double> get getSyncPercent async {
    int lastScannedBlock = DB.instance
            .get<dynamic>(boxName: walletId, key: 'lastScannedBlock') as int? ??
        0;
    final _chainHeight = await chainHeight;
    double restorePercent = lastScannedBlock / _chainHeight;
    GlobalEventBus.instance
        .fire(RefreshPercentChangedEvent(highestPercent, walletId));
    if (restorePercent > highestPercent) {
      highestPercent = restorePercent;
    }

    final int blocksRemaining = _chainHeight - lastScannedBlock;
    GlobalEventBus.instance
        .fire(BlocksRemainingEvent(blocksRemaining, walletId));

    return restorePercent < 0 ? 0.0 : restorePercent;
  }

  double highestPercent = 0;

  @override
  Future<void> recoverFromMnemonic(
      {required String mnemonic,
      required int maxUnusedAddressGap,
      required int maxNumberOfIndexesToCheck,
      required int height}) async {
    try {
      await _prefs.init();
      await updateNode(false);
      final String password = generatePassword();

      String stringConfig = await getConfig();
      String epicboxConfig = await getEpicBoxConfig();
      final String name = _walletName.trim();

      await _secureStore.write(key: '${_walletId}_mnemonic', value: mnemonic);
      await _secureStore.write(key: '${_walletId}_config', value: stringConfig);
      await _secureStore.write(key: '${_walletId}_password', value: password);
      await _secureStore.write(
          key: '${_walletId}_epicboxConfig', value: epicboxConfig);

      await compute(
        _recoverWrapper,
        Tuple4(
          stringConfig,
          password,
          mnemonic,
          name,
        ),
      );

      await DB.instance
          .put<dynamic>(boxName: walletId, key: "restoreHeight", value: height);

      await DB.instance
          .put<dynamic>(boxName: walletId, key: "id", value: _walletId);
      await DB.instance.put<dynamic>(
          boxName: walletId, key: 'receivingAddresses', value: ["0"]);
      await DB.instance
          .put<dynamic>(boxName: walletId, key: "receivingIndex", value: 0);
      if (height >= 0) {
        await DB.instance.put<dynamic>(
            boxName: walletId, key: "restoreHeight", value: height);
      }
      await DB.instance
          .put<dynamic>(boxName: walletId, key: "changeIndex", value: 0);
      await DB.instance.put<dynamic>(
        boxName: walletId,
        key: 'blocked_tx_hashes',
        value: ["0xdefault"],
      ); // A list of transaction hashes to represent frozen utxos in wallet
      // initialize address book entries
      await DB.instance.put<dynamic>(
          boxName: walletId,
          key: 'addressBookEntries',
          value: <String, String>{});
      await DB.instance
          .put<dynamic>(boxName: walletId, key: "isFavorite", value: false);

      //Open Wallet
      final walletOpen = openWallet(stringConfig, password);
      await _secureStore.write(key: '${_walletId}_wallet', value: walletOpen);

      //Store Epic box address info
      await storeEpicboxInfo();

      //Open Epicbox listener in the background
      await listenForSlates();
    } catch (e, s) {
      Logging.instance
          .log("Error recovering wallet $e\n$s", level: LogLevel.Error);
      rethrow;
    }
  }

  Future<int> getRestoreHeight() async {
    if (DB.instance
        .containsKey<dynamic>(boxName: walletId, key: "restoreHeight")) {
      return (DB.instance.get<dynamic>(boxName: walletId, key: "restoreHeight"))
          as int;
    }
    return (DB.instance.get<dynamic>(boxName: walletId, key: "creationHeight"))
        as int;
  }

  Future<int> get chainHeight async {
    final config = await getRealConfig();
    int? latestHeight;
    try {
      await m.protect(() async {
        latestHeight = await compute(
          _getChainHeightWrapper,
          config,
        );
      });
    } catch (e, s) {
      Logging.instance.log("$e $s", level: LogLevel.Error);
    }
    return latestHeight!;
  }

  int get storedChainHeight {
    return DB.instance.get<dynamic>(boxName: walletId, key: "storedChainHeight")
            as int? ??
        0;
  }

  Future<void> updateStoredChainHeight({required int newHeight}) async {
    await DB.instance.put<dynamic>(
        boxName: walletId, key: "storedChainHeight", value: newHeight);
  }

  bool _shouldAutoSync = true;

  @override
  bool get shouldAutoSync => _shouldAutoSync;

  @override
  set shouldAutoSync(bool shouldAutoSync) {
    if (_shouldAutoSync != shouldAutoSync) {
      _shouldAutoSync = shouldAutoSync;
      if (!shouldAutoSync) {
        Logging.instance.log("Should autosync", level: LogLevel.Info);
        timer?.cancel();
        timer = null;
        stopNetworkAlivePinging();
      } else {
        startNetworkAlivePinging();
        refresh();
      }
    }
  }

  Future<int> setCurrentIndex() async {
    try {
      final int receivingIndex = DB.instance
          .get<dynamic>(boxName: walletId, key: "receivingIndex") as int;
      // TODO: go through pendingarray and processed array and choose the index
      //  of the last one that has not been processed, or the index after the one most recently processed;
      return receivingIndex;
    } catch (e, s) {
      Logging.instance.log("$e $s", level: LogLevel.Error);
      return 0;
    }
  }

  Future<Map<dynamic, dynamic>> removeBadAndRepeats(
      Map<dynamic, dynamic> pendingAndProcessedSlates) async {
    var clone = <dynamic, Map<dynamic, dynamic>>{};
    for (var indexPair in pendingAndProcessedSlates.entries) {
      clone[indexPair.key] = <dynamic, dynamic>{};
      for (var pendingProcessed
          in (indexPair.value as Map<dynamic, dynamic>).entries) {
        if (pendingProcessed.value is String &&
                (pendingProcessed.value as String)
                    .contains("has already been received") ||
            (pendingProcessed.value as String)
                .contains("Error Wallet store error: DB Not Found Error")) {
        } else if (pendingProcessed.value is String &&
            pendingProcessed.value as String == "[]") {
        } else {
          clone[indexPair.key]?[pendingProcessed.key] = pendingProcessed.value;
        }
      }
    }
    return clone;
  }

  Future<Map<dynamic, dynamic>> getSlatesToCommits() async {
    try {
      var slatesToCommits =
          DB.instance.get<dynamic>(boxName: walletId, key: "slatesToCommits");
      if (slatesToCommits == null) {
        slatesToCommits = <dynamic, dynamic>{};
      } else {
        slatesToCommits = slatesToCommits as Map<dynamic, dynamic>;
      }
      return slatesToCommits as Map<dynamic, dynamic>;
    } catch (e, s) {
      Logging.instance.log("$e $s", level: LogLevel.Error);
      return {};
    }
  }

  Future<bool> putSendToAddresses(String slateMessage) async {
    try {
      var slatesToCommits = await getSlatesToCommits();
      final slate0 = jsonDecode(slateMessage);
      final slate = jsonDecode(slate0[0] as String);
      final part1 = jsonDecode(slate[0] as String);
      final part2 = jsonDecode(slate[1] as String);
      final slateId = part1[0]['tx_slate_id'];
      final commitId = part2['tx']['body']['outputs'][0]['commit'];

      final toFromInfoString = jsonDecode(slateMessage);
      final toFromInfo = jsonDecode(toFromInfoString[1] as String);
      final from = toFromInfo['from'];
      final to = toFromInfo['to'];
      slatesToCommits[slateId] = {
        "commitId": commitId,
        "from": from,
        "to": to,
      };
      await DB.instance.put<dynamic>(
          boxName: walletId, key: "slatesToCommits", value: slatesToCommits);
      return true;
    } catch (e, s) {
      Logging.instance.log("$e $s", level: LogLevel.Error);
      return false;
    }
  }

  Future<bool> putSlatesToCommits(String slateMessage, String encoded) async {
    try {
      var slatesToCommits = await getSlatesToCommits();
      final slate = jsonDecode(slateMessage);
      final part1 = jsonDecode(slate[0] as String);
      final part2 = jsonDecode(slate[1] as String);
      final slateId = part1[0]['tx_slate_id'];
      if (slatesToCommits[slateId] != null &&
          (slatesToCommits[slateId] as Map).isNotEmpty) {
        // This happens when the sender receives the response.
        return true;
      }
      final commitId = part2['tx']['body']['outputs'][0]['commit'];

      final toFromInfoString = jsonDecode(encoded);
      final toFromInfo = jsonDecode(toFromInfoString[0] as String);
      final from = toFromInfo['from'];
      final to = toFromInfo['to'];
      slatesToCommits[slateId] = {
        "commitId": commitId,
        "from": from,
        "to": to,
      };
      await DB.instance.put<dynamic>(
          boxName: walletId, key: "slatesToCommits", value: slatesToCommits);
      return true;
    } catch (e, s) {
      Logging.instance.log("$e $s", level: LogLevel.Error);
      return false;
    }
  }

  Future<void> listenForSlates() async {
    final wallet = await _secureStore.read(key: '${_walletId}_wallet');
    final epicboxConfig = await getEpicBoxConfig();

    await m.protect(() async {
      Logging.instance.log("CALLING LISTEN FOR SLATES", level: LogLevel.Info);
      ReceivePort receivePort = await getIsolate({
        "function": "listenForSlates",
        "wallet": wallet,
        "epicboxConfig": epicboxConfig,
      }, name: walletName);

      var result = await receivePort.first;
      if (result is String) {
        Logging.instance
            .log("this is a message $result", level: LogLevel.Error);
        stop(receivePort);
        throw Exception("subscribeRequest isolate failed");
      }
      stop(receivePort);
    });
  }

  /// Refreshes display data for the wallet
  @override
  Future<void> refresh() async {
    Logging.instance
        .log("$walletId $walletName Calling refresh", level: LogLevel.Info);
    if (refreshMutex) {
      Logging.instance.log("$walletId $walletName refreshMutex denied",
          level: LogLevel.Info);
      return;
    } else {
      refreshMutex = true;
    }

    try {
      _isConnected = true;
      GlobalEventBus.instance.fire(
        WalletSyncStatusChangedEvent(
          WalletSyncStatus.syncing,
          walletId,
          coin,
        ),
      );

      if (!DB.instance
          .containsKey<dynamic>(boxName: walletId, key: "creationHeight")) {
        await DB.instance.put<dynamic>(
            boxName: walletId, key: "creationHeight", value: await chainHeight);
      }

      final int curAdd = await setCurrentIndex();
      _currentReceivingAddress = _getCurrentAddressForChain(curAdd);

      if (!await startScans()) {
        refreshMutex = false;
        _isConnected = false;
        GlobalEventBus.instance.fire(
          NodeConnectionStatusChangedEvent(
            NodeConnectionStatus.disconnected,
            walletId,
            coin,
          ),
        );
        GlobalEventBus.instance.fire(
          WalletSyncStatusChangedEvent(
            WalletSyncStatus.unableToSync,
            walletId,
            coin,
          ),
        );
        return;
      }

      startSync();

      GlobalEventBus.instance.fire(RefreshPercentChangedEvent(0.0, walletId));

      GlobalEventBus.instance.fire(RefreshPercentChangedEvent(0.1, walletId));

      final currentHeight = await chainHeight;
      const storedHeight = 1; //await storedChainHeight;

      Logging.instance.log("chain height in refresh function: $currentHeight",
          level: LogLevel.Info);
      Logging.instance.log("cached height in refresh function: $storedHeight",
          level: LogLevel.Info);

      // TODO: implement refresh
      // TODO: check if it needs a refresh and if so get all of the most recent data.
      if (currentHeight != storedHeight) {
        if (currentHeight != -1) {
          // -1 failed to fetch current height
          unawaited(updateStoredChainHeight(newHeight: currentHeight));
        }

        final newTxData = await _fetchTransactionData();
        GlobalEventBus.instance
            .fire(RefreshPercentChangedEvent(0.50, walletId));

        _transactionData = Future(() => newTxData);
        txCount = newTxData.getAllTransactions().length;

        GlobalEventBus.instance.fire(UpdatedInBackgroundEvent(
            "New data found in $walletName in background!", walletId));
      }

      GlobalEventBus.instance.fire(RefreshPercentChangedEvent(1.0, walletId));
      GlobalEventBus.instance.fire(
        WalletSyncStatusChangedEvent(
          WalletSyncStatus.synced,
          walletId,
          coin,
        ),
      );
      refreshMutex = false;
      if (shouldAutoSync) {
        timer ??= Timer.periodic(const Duration(seconds: 60), (timer) async {
          Logging.instance.log(
              "Periodic refresh check for $walletId $walletName in object instance: $hashCode",
              level: LogLevel.Info);
          // chain height check currently broken
          // if ((await chainHeight) != (await storedChainHeight)) {
          if (await refreshIfThereIsNewData()) {
            await refresh();
            GlobalEventBus.instance.fire(UpdatedInBackgroundEvent(
                "New data found in $walletId $walletName in background!",
                walletId));
          }
          // }
        });
      }
    } catch (error, strace) {
      refreshMutex = false;
      _isConnected = false;
      GlobalEventBus.instance.fire(
        NodeConnectionStatusChangedEvent(
          NodeConnectionStatus.disconnected,
          walletId,
          coin,
        ),
      );
      GlobalEventBus.instance.fire(
        WalletSyncStatusChangedEvent(
          WalletSyncStatus.unableToSync,
          walletId,
          coin,
        ),
      );
      Logging.instance.log(
          "Caught exception in refreshWalletData(): $error\n$strace",
          level: LogLevel.Warning);
    }
  }

  Future<bool> refreshIfThereIsNewData() async {
    if (_hasCalledExit) return false;
    // TODO returning true here signals this class to call refresh() after which it will fire an event that notifies the UI that new data has been fetched/found for this wallet
    return true;
    // TODO: do a quick check to see if there is any new data that would require a refresh
  }

  @override
  Future<String> send(
      {required String toAddress,
      required int amount,
      Map<String, String> args = const {}}) {
    // TODO: implement send
    throw UnimplementedError();
  }

  @override
  Future<bool> testNetworkConnection() async {
    try {
      // force unwrap optional as we want connection test to fail if wallet
      // wasn't initialized or epicbox node was set to null
      return await testEpicNodeConnection(
            NodeFormData()
              ..host = _epicNode!.host
              ..useSSL = _epicNode!.useSSL
              ..port = _epicNode!.port,
          ) !=
          null;
    } catch (e, s) {
      Logging.instance.log("$e\n$s", level: LogLevel.Warning);
      return false;
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

  void _periodicPingCheck() async {
    bool hasNetwork = await testNetworkConnection();
    _isConnected = hasNetwork;
    if (_isConnected != hasNetwork) {
      NodeConnectionStatus status = hasNetwork
          ? NodeConnectionStatus.connected
          : NodeConnectionStatus.disconnected;
      GlobalEventBus.instance
          .fire(NodeConnectionStatusChangedEvent(status, walletId, coin));
    }
  }

  void stopNetworkAlivePinging() {
    _networkAliveTimer?.cancel();
    _networkAliveTimer = null;
  }

  bool _isConnected = true;

  @override
  bool get isConnected => _isConnected;

  @override
  Future<Decimal> get totalBalance async {
    String walletBalances = await allWalletBalances();
    var jsonBalances = json.decode(walletBalances);
    double total = jsonBalances['total'] as double;
    double awaiting = jsonBalances['amount_awaiting_finalization'] as double;
    total = total + awaiting;
    return Decimal.parse(total.toString());
  }

  Future<TransactionData> _fetchTransactionData() async {
    final currentChainHeight = await chainHeight;
    final wallet = await _secureStore.read(key: '${_walletId}_wallet');
    const refreshFromNode = 0;

    dynamic message;
    await m.protect(() async {
      ReceivePort receivePort = await getIsolate({
        "function": "getTransactions",
        "wallet": wallet!,
        "refreshFromNode": refreshFromNode,
      }, name: walletName);

      message = await receivePort.first;
      if (message is String) {
        Logging.instance
            .log("this is a string $message", level: LogLevel.Error);
        stop(receivePort);
        throw Exception("getTransactions isolate failed");
      }
      stop(receivePort);
      Logging.instance
          .log('Closing getTransactions!\n $message', level: LogLevel.Info);
    });
    // return message;
    final String transactions = message['result'] as String;
    final jsonTransactions = json.decode(transactions) as List;
    // for (var el in jsonTransactions) {
    //   Logging.instance.log("gettran: $el",
    //       normalLength: false, addToDebugMessagesDB: true);
    // }

    final priceData =
        await _priceAPI.getPricesAnd24hChange(baseCurrency: _prefs.currency);
    Decimal currentPrice = priceData[coin]?.item1 ?? Decimal.zero;
    final List<Map<String, dynamic>> midSortedArray = [];

    int latestTxnBlockHeight =
        DB.instance.get<dynamic>(boxName: walletId, key: "storedTxnDataHeight")
                as int? ??
            0;
    final slatesToCommits = await getSlatesToCommits();
    final cachedTransactions =
        DB.instance.get<dynamic>(boxName: walletId, key: 'latest_tx_model')
            as TransactionData?;
    var cachedMap = cachedTransactions?.getAllTransactions();
    for (var tx in jsonTransactions) {
      Logging.instance.log("tx: $tx", level: LogLevel.Info);
      final txHeight = tx["kernel_lookup_min_height"] as int? ?? 0;
      // TODO: does "confirmed" mean finalized? If so please remove this todo
      final isConfirmed = tx["confirmed"] as bool;
      // TODO: since we are now caching tx history in hive are we losing anything by skipping here?
      // TODO: we can skip this filtering if it causes issues as the cache is later merged with updated data anyways
      // this would just make processing and updating cache more efficient
      if (txHeight > 0 &&
          txHeight < latestTxnBlockHeight - MINIMUM_CONFIRMATIONS &&
          isConfirmed) {
        continue;
      }
      // Logging.instance.log("Transactions listed below");
      // Logging.instance.log(jsonTransactions);
      int amt = 0;
      if (tx["tx_type"] == "TxReceived" ||
          tx["tx_type"] == "TxReceivedCancelled") {
        amt = int.parse(tx['amount_credited'] as String);
      } else {
        int debit = int.parse(tx['amount_debited'] as String);
        int credit = int.parse(tx['amount_credited'] as String);
        int fee = int.parse((tx['fee'] ?? "0") as String);
        amt = debit - credit - fee;
      }
      final String worthNow =
          (currentPrice * Decimal.parse(amt.toString())).toStringAsFixed(2);

      DateTime dt = DateTime.parse(tx["creation_ts"] as String);

      Map<String, dynamic> midSortedTx = {};
      midSortedTx["txType"] = (tx["tx_type"] == "TxReceived" ||
              tx["tx_type"] == "TxReceivedCancelled")
          ? "Received"
          : "Sent";
      String? slateId = tx['tx_slate_id'] as String?;
      String? address = slatesToCommits[slateId]
                  ?[midSortedTx["txType"] == "TxReceived" ? "from" : "to"]
              as String? ??
          "";
      String? commitId = slatesToCommits[slateId]?['commitId'] as String?;
      Logging.instance.log(
          "commitId: $commitId, slateId: $slateId, id: ${tx["id"]}",
          level: LogLevel.Info);

      bool isCancelled = tx["tx_type"] == "TxSentCancelled" ||
          tx["tx_type"] == "TxReceivedCancelled";

      midSortedTx["slateId"] = slateId;
      midSortedTx["isCancelled"] = isCancelled;
      midSortedTx["txid"] = commitId ?? tx["id"].toString();
      midSortedTx["confirmed_status"] = isConfirmed;
      midSortedTx["timestamp"] = (dt.millisecondsSinceEpoch ~/ 1000);
      midSortedTx["amount"] = amt;
      midSortedTx["worthNow"] = worthNow;
      midSortedTx["worthAtBlockTimestamp"] = worthNow;
      midSortedTx["fees"] =
          (tx["fee"] == null) ? 0 : int.parse(tx["fee"] as String);
      midSortedTx["address"] =
          ""; // for this when you send a transaction you will just need to save in a hashmap in hive with the key being the txid, and the value being the address it was sent to. then you can look this value up right here in your hashmap.
      midSortedTx["address"] = address;
      midSortedTx["height"] = txHeight;
      int confirmations = 0;
      try {
        confirmations = currentChainHeight - txHeight;
      } catch (e, s) {
        debugPrint("$e $s");
      }
      midSortedTx["confirmations"] = confirmations;

      midSortedTx["inputSize"] = tx["num_inputs"];
      midSortedTx["outputSize"] = tx["num_outputs"];
      midSortedTx["aliens"] = <dynamic>[];
      midSortedTx["inputs"] = <dynamic>[];
      midSortedTx["outputs"] = <dynamic>[];
      midSortedTx["tx_slate_id"] = tx["tx_slate_id"];
      midSortedTx["key_id"] = tx["parent_key_id"];
      midSortedTx["otherData"] = tx["id"].toString();

      if (txHeight >= latestTxnBlockHeight) {
        latestTxnBlockHeight = txHeight;
      }

      midSortedArray.add(midSortedTx);
      cachedMap?.remove(tx["id"].toString());
      cachedMap?.remove(commitId);
      Logging.instance.log("cmap: $cachedMap", level: LogLevel.Info);
    }

    midSortedArray
        .sort((a, b) => (b["timestamp"] as int) - (a["timestamp"] as int));

    final Map<String, dynamic> result = {"dateTimeChunks": <dynamic>[]};
    final dateArray = <dynamic>[];

    for (int i = 0; i < midSortedArray.length; i++) {
      final txObject = midSortedArray[i];
      final date = extractDateFromTimestamp(txObject["timestamp"] as int);

      final txTimeArray = [txObject["timestamp"], date];

      if (dateArray.contains(txTimeArray[1])) {
        result["dateTimeChunks"].forEach((dynamic chunk) {
          if (extractDateFromTimestamp(chunk["timestamp"] as int) ==
              txTimeArray[1]) {
            if (chunk["transactions"] == null) {
              chunk["transactions"] = <Map<String, dynamic>>[];
            }
            chunk["transactions"].add(txObject);
          }
        });
      } else {
        dateArray.add(txTimeArray[1]);

        final chunk = {
          "timestamp": txTimeArray[0],
          "transactions": [txObject],
        };

        // result["dateTimeChunks"].
        result["dateTimeChunks"].add(chunk);
      }
    }
    final transactionsMap =
        TransactionData.fromJson(result).getAllTransactions();
    if (cachedMap != null) {
      transactionsMap.addAll(cachedMap);
    }

    final txModel = TransactionData.fromMap(transactionsMap);

    await DB.instance.put<dynamic>(
        boxName: walletId,
        key: 'storedTxnDataHeight',
        value: latestTxnBlockHeight);
    await DB.instance.put<dynamic>(
        boxName: walletId, key: 'latest_tx_model', value: txModel);

    return txModel;
  }

  @override
  Future<TransactionData> get transactionData =>
      _transactionData ??= _fetchTransactionData();
  Future<TransactionData>? _transactionData;

  // not used in epic
  TransactionData? cachedTxData;

  @override
  Future<void> updateSentCachedTxData(Map<String, dynamic> txData) async {
    // not used in epic
  }

  @override
  Future<List<UtxoObject>> get unspentOutputs => throw UnimplementedError();

  @override
  bool validateAddress(String address) {
    if (address.startsWith("http://") || address.startsWith("https://")) {
      if (Uri.tryParse(address) != null) {
        return true;
      }
    }

    String validate = validateSendAddress(address);
    if (int.parse(validate) == 1) {
      return true;
    } else {
      return false;
    }
  }

  @override
  String get walletId => _walletId;
  late String _walletId;

  @override
  String get walletName => _walletName;
  late String _walletName;

  @override
  set walletName(String newName) => _walletName = newName;

  @override
  void Function(bool)? get onIsActiveWalletChanged => (isActive) async {
        timer?.cancel();
        timer = null;
        if (isActive) {
          unawaited(startSync());
        } else {
          for (final isolate in isolates.values) {
            isolate.kill(priority: Isolate.immediate);
          }
          isolates.clear();
        }
        this.isActive = isActive;
      };

  bool isActive = false;

  @override
  Future<int> estimateFeeFor(int satoshiAmount, int feeRate) async {
    int currentFee = await nativeFee(satoshiAmount, ifErrorEstimateFee: true);
    // TODO: implement this
    return currentFee;
  }

  // not used in epic currently
  @override
  Future<bool> generateNewAddress() async {
    try {
      // await incrementAddressIndexForChain(
      //     0); // First increment the receiving index
      // final newReceivingIndex =
      // DB.instance.get<dynamic>(boxName: walletId, key: 'receivingIndex')
      // as int; // Check the new receiving index
      // final newReceivingAddress = await _generateAddressForChain(0,
      //     newReceivingIndex); // Use new index to derive a new receiving address
      // await addToAddressesArrayForChain(newReceivingAddress,
      //     0); // Add that new receiving address to the array of receiving addresses
      // _currentReceivingAddress = Future(() =>
      // newReceivingAddress); // Set the new receiving address that the service

      return true;
    } catch (e, s) {
      Logging.instance.log(
          "Exception rethrown from generateNewAddress(): $e\n$s",
          level: LogLevel.Error);
      return false;
    }
  }
}

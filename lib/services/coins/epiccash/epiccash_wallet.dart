import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:decimal/decimal.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_libepiccash/epic_cash.dart';
import 'package:http/http.dart';
import 'package:isar/isar.dart';
import 'package:mutex/mutex.dart';
import 'package:stack_wallet_backup/generate_password.dart';
import 'package:stackwallet/db/main_db.dart';
import 'package:stackwallet/models/balance.dart';
import 'package:stackwallet/models/isar/models/isar_models.dart' as isar_models;
import 'package:stackwallet/models/node_model.dart';
import 'package:stackwallet/models/paymint/fee_object_model.dart';
import 'package:stackwallet/pages/settings_views/global_settings_view/manage_nodes_views/add_edit_node_view.dart';
import 'package:stackwallet/services/coins/coin_service.dart';
import 'package:stackwallet/services/event_bus/events/global/blocks_remaining_event.dart';
import 'package:stackwallet/services/event_bus/events/global/node_connection_status_changed_event.dart';
import 'package:stackwallet/services/event_bus/events/global/refresh_percent_changed_event.dart';
import 'package:stackwallet/services/event_bus/events/global/updated_in_background_event.dart';
import 'package:stackwallet/services/event_bus/events/global/wallet_sync_status_changed_event.dart';
import 'package:stackwallet/services/event_bus/global_event_bus.dart';
import 'package:stackwallet/services/mixins/epic_cash_hive.dart';
import 'package:stackwallet/services/mixins/wallet_cache.dart';
import 'package:stackwallet/services/mixins/wallet_db.dart';
import 'package:stackwallet/services/node_service.dart';
import 'package:stackwallet/utilities/constants.dart';
import 'package:stackwallet/utilities/default_nodes.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/utilities/flutter_secure_storage_interface.dart';
import 'package:stackwallet/utilities/format.dart';
import 'package:stackwallet/utilities/logger.dart';
import 'package:stackwallet/utilities/prefs.dart';
import 'package:stackwallet/utilities/stack_file_system.dart';
import 'package:stackwallet/utilities/test_epic_box_connection.dart';
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
    } else if (function == "getPendingSlates") {
      final wallet = arguments['wallet'] as String?;
      final secretKeyIndex = arguments['secretKeyIndex'] as int?;
      final slates = arguments['slates'] as String;
      Map<String, dynamic> result = {};

      if (!(wallet == null || secretKeyIndex == null)) {
        Logging.instance
            .log("SECRET_KEY_INDEX_IS $secretKeyIndex", level: LogLevel.Info);
        result['result'] =
            await getPendingSlates(wallet, secretKeyIndex, slates);
        sendPort.send(result);
        return;
      }
    } else if (function == "subscribeRequest") {
      final wallet = arguments['wallet'] as String?;
      final secretKeyIndex = arguments['secretKeyIndex'] as int?;
      final epicboxConfig = arguments['epicboxConfig'] as String?;
      Map<String, dynamic> result = {};

      if (!(wallet == null ||
          secretKeyIndex == null ||
          epicboxConfig == null)) {
        Logging.instance
            .log("SECRET_KEY_INDEX_IS $secretKeyIndex", level: LogLevel.Info);
        result['result'] =
            await getSubscribeRequest(wallet, secretKeyIndex, epicboxConfig);
        sendPort.send(result);
        return;
      }
    } else if (function == "processSlates") {
      final wallet = arguments['wallet'] as String?;
      final slates = arguments['slates'];
      Map<String, dynamic> result = {};

      if (!(wallet == null || slates == null)) {
        result['result'] = await processSlates(wallet, slates.toString());
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
  required SecureStorageInterface secureStore,
}) async {
  // is this even needed for anything?
  // String? config = await secureStore.read(key: '${walletId}_config');
  // // TODO: why double check for iOS?
  // if (Platform.isIOS) {
  //   Directory appDir = await StackFileSystem.applicationRootDirectory();
  //   // todo why double check for ios?
  //   // if (Platform.isIOS) {
  //   //   appDir = (await getLibraryDirectory());
  //   // }
  //   // if (Platform.isLinux) {
  //   //   appDir = Directory("${appDir.path}/.stackwallet");
  //   // }
  //   final path = "${appDir.path}/epiccash";
  //   final String name = walletId;
  //
  //   final walletDir = '$path/$name';
  //   var editConfig = jsonDecode(config as String);
  //
  //   editConfig["wallet_dir"] = walletDir;
  //   config = jsonEncode(editConfig);
  // }

  final wallet = await secureStore.read(key: '${walletId}_wallet');

  if (wallet == null) {
    return "Tried to delete non existent epic wallet file with walletId=$walletId";
  } else {
    try {
      return compute(_deleteWalletWrapper, wallet);
    } catch (e, s) {
      Logging.instance.log("$e\n$s", level: LogLevel.Error);
      return "deleteEpicWallet($walletId) failed...";
    }
  }
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
  final int chainHeight = getChainHeight(config);
  return chainHeight;
}

const String EPICPOST_ADDRESS = 'https://epicpost.stackwallet.com';

Future<bool> postSlate(String receiveAddress, String slate) async {
  Logging.instance.log("postSlate", level: LogLevel.Info);
  final Client client = Client();
  try {
    final uri = Uri.parse("$EPICPOST_ADDRESS/postSlate");

    final epicpost = await client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "jsonrpc": "2.0",
        "id": "0",
        'receivingAddress': receiveAddress,
        'slate': slate
      }),
    );

    // TODO: should the following be removed for security reasons in production?
    Logging.instance.log(epicpost.statusCode.toString(), level: LogLevel.Info);
    Logging.instance.log(epicpost.body.toString(), level: LogLevel.Info);
    final response = jsonDecode(epicpost.body.toString());
    if (response['status'] == 'success') {
      return true;
    } else {
      return false;
    }
  } catch (e, s) {
    Logging.instance.log("$e $s", level: LogLevel.Error);
    return false;
  }
}

Future<dynamic> getSlates(String receiveAddress, String signature) async {
  Logging.instance.log("getslates", level: LogLevel.Info);
  final Client client = Client();
  try {
    final uri = Uri.parse("$EPICPOST_ADDRESS/getSlates");

    final epicpost = await client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "jsonrpc": "2.0",
        "id": "0",
        'receivingAddress': receiveAddress,
        'signature': signature,
      }),
    );

    // TODO: should the following be removed for security reasons in production?
    Logging.instance.log(epicpost.statusCode.toString(), level: LogLevel.Info);
    Logging.instance.log(epicpost.body.toString(), level: LogLevel.Info);
    final response = jsonDecode(epicpost.body.toString());
    if (response['status'] == 'success') {
      return response['slates'];
    } else {
      return response['error'];
    }
  } catch (e, s) {
    Logging.instance.log("$e $s", level: LogLevel.Error);
    return 'Error $e $s';
  }
}

Future<bool> postCancel(String receiveAddress, String slateId,
    String? signature, String sendersAddress) async {
  Logging.instance.log("postCancel", level: LogLevel.Info);
  final Client client = Client();
  try {
    final uri = Uri.parse("$EPICPOST_ADDRESS/postCancel");

    final body = jsonEncode({
      "jsonrpc": "2.0",
      "id": "0",
      'receivingAddress': receiveAddress,
      "signature": signature,
      'slate': slateId,
      "sendersAddress": sendersAddress,
    });
    final epicPost = await client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: body,
    );
    // TODO: should the following be removed for security reasons in production?
    Logging.instance.log(epicPost.statusCode.toString(), level: LogLevel.Info);
    Logging.instance.log(epicPost.body.toString(), level: LogLevel.Info);
    final response = jsonDecode(epicPost.body.toString());
    if (response['status'] == 'success') {
      return true;
    } else {
      return false;
    }
  } catch (e, s) {
    Logging.instance.log("$e $s", level: LogLevel.Error);
    return false;
  }
}

Future<dynamic> getCancels(String receiveAddress, String signature) async {
  Logging.instance.log("getCancels", level: LogLevel.Info);
  final Client client = Client();
  try {
    final uri = Uri.parse("$EPICPOST_ADDRESS/getCancels");

    final epicpost = await client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "jsonrpc": "2.0",
        "id": "0",
        'receivingAddress': receiveAddress,
        'signature': signature,
      }),
    );
    // TODO: should the following be removed for security reasons in production?
    Logging.instance.log(epicpost.statusCode.toString(), level: LogLevel.Info);
    Logging.instance.log(epicpost.body.toString(), level: LogLevel.Info);
    final response = jsonDecode(epicpost.body.toString());
    if (response['status'] == 'success') {
      return response['canceled_slates'];
    } else {
      return response['error'];
    }
  } catch (e, s) {
    Logging.instance.log("$e $s", level: LogLevel.Error);
    return 'Error $e $s';
  }
}

Future<dynamic> deleteCancels(
    String receiveAddress, String signature, String slate) async {
  Logging.instance.log("deleteCancels", level: LogLevel.Info);
  final Client client = Client();
  try {
    final uri = Uri.parse("$EPICPOST_ADDRESS/deleteCancels");

    final epicpost = await client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "jsonrpc": "2.0",
        "id": "0",
        'receivingAddress': receiveAddress,
        'signature': signature,
        'slate': slate,
      }),
    );
    // TODO: should the following be removed for security reasons in production?
    Logging.instance.log(epicpost.statusCode.toString(), level: LogLevel.Info);
    Logging.instance.log(epicpost.body.toString(), level: LogLevel.Info);
    final response = jsonDecode(epicpost.body.toString());
    if (response['status'] == 'success') {
      return true;
    } else {
      return false;
    }
  } catch (e, s) {
    Logging.instance.log("$e $s", level: LogLevel.Error);
    return 'Error $e $s';
  }
}

Future<dynamic> deleteSlate(
    String receiveAddress, String signature, String slate) async {
  Logging.instance.log("deleteSlate", level: LogLevel.Info);
  final Client client = Client();
  try {
    final uri = Uri.parse("$EPICPOST_ADDRESS/deleteSlate");

    final epicpost = await client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "jsonrpc": "2.0",
        "id": "0",
        'receivingAddress': receiveAddress,
        'signature': signature,
        'slate': slate,
      }),
    );
    // TODO: should the following be removed for security reasons in production?
    Logging.instance.log(epicpost.statusCode.toString(), level: LogLevel.Info);
    Logging.instance.log(epicpost.body.toString(), level: LogLevel.Info);
    final response = jsonDecode(epicpost.body.toString());
    if (response['status'] == 'success') {
      return true;
    } else {
      return false;
    }
  } catch (e, s) {
    Logging.instance.log("$e $s", level: LogLevel.Info);
    return 'Error $e $s';
  }
}

class EpicCashWallet extends CoinServiceAPI
    with WalletCache, WalletDB, EpicCashHive {
  EpicCashWallet({
    required String walletId,
    required String walletName,
    required Coin coin,
    required SecureStorageInterface secureStore,
    MainDB? mockableOverride,
  }) {
    _walletId = walletId;
    _walletName = walletName;
    _coin = coin;
    _secureStore = secureStore;
    initCache(walletId, coin);
    initEpicCashHive(walletId);
    initWalletDB(mockableOverride: mockableOverride);

    Logging.instance.log("$walletName isolate length: ${isolates.length}",
        level: LogLevel.Info);
    for (final isolate in isolates.values) {
      isolate.kill(priority: Isolate.immediate);
    }
    isolates.clear();
  }

  static const integrationTestFlag =
      bool.fromEnvironment("IS_INTEGRATION_TEST");
  final m = Mutex();
  final syncMutex = Mutex();

  final _prefs = Prefs.instance;

  NodeModel? _epicNode;

  @override
  Future<void> updateNode(bool shouldRefresh) async {
    _epicNode = NodeService(secureStorageInterface: _secureStore)
            .getPrimaryNodeFor(coin: coin) ??
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
    _isFavorite = markFavorite;
    updateCachedIsFavorite(markFavorite);
  }

  @override
  bool get isFavorite => _isFavorite ??= getCachedIsFavorite();

  bool? _isFavorite;

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

  Timer? timer;
  late final Coin _coin;

  @override
  Coin get coin => _coin;

  late SecureStorageInterface _secureStore;

  Future<String> cancelPendingTransactionAndPost(String txSlateId) async {
    final wallet = await _secureStore.read(key: '${_walletId}_wallet');
    final int? receivingIndex = epicGetReceivingIndex();
    final epicboxConfig =
        await _secureStore.read(key: '${_walletId}_epicboxConfig');

    final slatesToCommits = await getSlatesToCommits();
    final receiveAddress = slatesToCommits[txSlateId]['to'] as String;
    final sendersAddress = slatesToCommits[txSlateId]['from'] as String;

    int? currentReceivingIndex;
    for (int i = 0; i <= receivingIndex!; i++) {
      final indexesAddress = await _getReceivingAddressForIndex(i);
      if (indexesAddress.value == sendersAddress) {
        currentReceivingIndex = i;
        break;
      }
    }

    dynamic subscribeRequest;
    await m.protect(() async {
      ReceivePort receivePort = await getIsolate({
        "function": "subscribeRequest",
        "wallet": wallet,
        "secretKeyIndex": currentReceivingIndex!,
        "epicboxConfig": epicboxConfig,
      }, name: walletName);

      var result = await receivePort.first;
      if (result is String) {
        Logging.instance.log("this is a message $result", level: LogLevel.Info);
        stop(receivePort);
        throw Exception("subscribeRequest isolate failed");
      }
      subscribeRequest = jsonDecode(result['result'] as String);
      stop(receivePort);
      Logging.instance.log('Closing subscribeRequest! $subscribeRequest',
          level: LogLevel.Info);
    });
    // TODO, once server adds signature, give this signature to the getSlates method.
    String? signature = subscribeRequest['signature'] as String?;
    String? result;
    try {
      result = await cancelPendingTransaction(txSlateId);
      Logging.instance.log("result?: $result", level: LogLevel.Info);
      if (!(result.toLowerCase().contains("error"))) {
        await postCancel(receiveAddress, txSlateId, signature, sendersAddress);
      }
    } catch (e, s) {
      Logging.instance.log("$e, $s", level: LogLevel.Error);
    }
    return result!;
  }

//
  /// returns an empty String on success, error message on failure
  Future<String> cancelPendingTransaction(String txSlateId) async {
    final String wallet =
        (await _secureStore.read(key: '${_walletId}_wallet'))!;

    String? result;
    await m.protect(() async {
      result = await compute(
        _cancelTransactionWrapper,
        Tuple2(
          wallet,
          txSlateId,
        ),
      );
    });
    return result!;
  }

  @override
  Future<String> confirmSend({required Map<String, dynamic> txData}) async {
    try {
      final wallet = await _secureStore.read(key: '${_walletId}_wallet');
      final epicboxConfig =
          await _secureStore.read(key: '${_walletId}_epicboxConfig');

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
            Logging.instance
                .log("this is a string $message", level: LogLevel.Error);
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
        //If it's HTTP send no need to post to epicbox
        if (!(receiverAddress.startsWith("http://") ||
            receiverAddress.startsWith("https://"))) {
          final postSlateRequest = decodeData[1];
          final postToServer = await postSlate(
              txData['addresss'] as String, postSlateRequest as String);
          Logging.instance
              .log("POST_SLATE_IS $postToServer", level: LogLevel.Info);
        }

        final txCreateResult = decodeData[0];
        // //TODO: second problem
        final transaction = json.decode(txCreateResult as String);

        Logger.print("TX_IS $transaction");
        final tx = transaction[0];
        final txLogEntry = json.decode(tx as String);
        final txLogEntryFirst = txLogEntry[0];
        Logger.print("TX_LOG_ENTRY_IS $txLogEntryFirst");
        final slateToAddresses = epicGetSlatesToAddresses();
        final slateId = txLogEntryFirst['tx_slate_id'] as String;
        slateToAddresses[slateId] = txData['addresss'];
        await epicUpdateSlatesToAddresses(slateToAddresses);

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

  Future<isar_models.Address> _getReceivingAddressForIndex(
    int index,
  ) async {
    isar_models.Address? address = await db
        .getAddresses(walletId)
        .filter()
        .subTypeEqualTo(isar_models.AddressSubType.receiving)
        .and()
        .typeEqualTo(isar_models.AddressType.mimbleWimble)
        .and()
        .derivationIndexEqualTo(index)
        .findFirst();

    if (address == null) {
      final wallet = await _secureStore.read(key: '${_walletId}_wallet');
      final epicboxConfig =
          await _secureStore.read(key: '${_walletId}_epicboxConfig');

      String? walletAddress;
      await m.protect(() async {
        walletAddress = await compute(
          _initGetAddressInfoWrapper,
          Tuple3(wallet!, index, epicboxConfig!),
        );
      });
      Logging.instance
          .log("WALLET_ADDRESS_IS $walletAddress", level: LogLevel.Info);

      address = isar_models.Address(
        walletId: walletId,
        value: walletAddress!,
        derivationIndex: index,
        derivationPath: null,
        type: isar_models.AddressType.mimbleWimble,
        subType: isar_models.AddressSubType.receiving,
        publicKey: [], // ??
      );

      await db.updateOrPutAddresses([address]);
    }

    return address;
  }

  @override
  Future<String> get currentReceivingAddress async =>
      (await _currentReceivingAddress)?.value ??
      (await _getReceivingAddressForIndex(0)).value;

  Future<isar_models.Address?> get _currentReceivingAddress => db
      .getAddresses(walletId)
      .filter()
      .subTypeEqualTo(isar_models.AddressSubType.receiving)
      .and()
      .typeEqualTo(isar_models.AddressType.mimbleWimble)
      .sortByDerivationIndexDesc()
      .findFirst();

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

      // clear blockchain info
      await db.deleteWalletBlockchainData(walletId);

      await epicUpdateLastScannedBlock(await getRestoreHeight());

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
      await refresh();
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

    if (getCachedId() == null) {
      //todo: check if print needed
      // debugPrint("Exception was thrown");
      throw Exception(
          "Attempted to initialize an existing wallet using an unknown wallet ID!");
    }
    await _prefs.init();
    await updateNode(false);
    await _refreshBalance();
    // TODO: is there anything else that should be set up here whenever this wallet is first loaded again?
  }

  Future<void> storeEpicboxInfo() async {
    final wallet = await _secureStore.read(key: '${_walletId}_wallet');
    int index = 0;

    Logging.instance.log("This index is $index", level: LogLevel.Info);
    final epicboxConfig =
        await _secureStore.read(key: '${_walletId}_epicboxConfig');
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
    //todo: check if print needed
    // debugPrint(
    //     "approximate height: $approximateHeight chosen_seconds: $chosenSeconds");
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

    await Future.wait([
      epicUpdateRestoreHeight(bufferedCreateHeight),
      updateCachedIsFavorite(false),
      updateCachedId(walletId),
      epicUpdateReceivingIndex(0),
      epicUpdateChangeIndex(0),
    ]);

    final initialReceivingAddress = await _getReceivingAddressForIndex(0);

    await db.putAddress(initialReceivingAddress);
  }

  bool refreshMutex = false;

  @override
  bool get isRefreshing => refreshMutex;

  @override
  // unused for epic
  Future<int> get maxFee => throw UnimplementedError();

  Future<List<String>> _getMnemonicList() async {
    String? _mnemonicString = await mnemonicString;
    if (_mnemonicString != null) {
      final List<String> data = _mnemonicString.split(' ');
      return data;
    } else {
      await m.protect(() async {
        _mnemonicString = await compute(
          _walletMnemonicWrapper,
          0,
        );
      });
      await _secureStore.write(
          key: '${_walletId}_mnemonic', value: _mnemonicString);
      final List<String> data = _mnemonicString!.split(' ');
      return data;
    }
  }

  @override
  Future<List<String>> get mnemonic => _getMnemonicList();

  @override
  Future<String?> get mnemonicString =>
      _secureStore.read(key: '${_walletId}_mnemonic');

  @override
  Future<String?> get mnemonicPassphrase => _secureStore.read(
        key: '${_walletId}_mnemonicPassphrase',
      );

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
      debugPrint(transactionFees);
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
        //todo: come back to this
        debugPrint("$e $s");
      }

      return realfee;
    } catch (e, s) {
      Logging.instance.log("Error getting fees $e - $s", level: LogLevel.Error);
      rethrow;
    }
  }

  Future<String> currentWalletDirPath() async {
    Directory appDir = await StackFileSystem.applicationRootDirectory();

    final path = "${appDir.path}/epiccash";
    final String name = _walletId.trim();
    return '$path/$name';
  }

  Future<String> getConfig() async {
    if (_epicNode == null) {
      await updateNode(false);
    }
    final NodeModel node = _epicNode!;
    final String nodeAddress = node.host;
    final int port = node.port;

    final uri = Uri.parse(nodeAddress).replace(port: port);

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
    return await _secureStore.read(key: '${_walletId}_epicboxConfig') ??
        DefaultNodes.defaultEpicBoxConfig;
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
      "domain": host,
      "port": port,
    });
    await _secureStore.write(
        key: '${_walletId}_epicboxConfig', value: stringConfig);
    // TODO: refresh anything that needs to be refreshed/updated due to epicbox info changed
  }

  Future<bool> startScans() async {
    try {
      final wallet = await _secureStore.read(key: '${_walletId}_wallet');

      var restoreHeight = epicGetRestoreHeight();
      var chainHeight = await this.chainHeight;
      if (epicGetLastScannedBlock() == null) {
        await epicUpdateLastScannedBlock(await getRestoreHeight());
      }
      int lastScannedBlock = epicGetLastScannedBlock()!;
      const MAX_PER_LOOP = 10000;
      await getSyncPercent;
      for (; lastScannedBlock < chainHeight;) {
        chainHeight = await this.chainHeight;
        lastScannedBlock = epicGetLastScannedBlock()!;
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
        await epicUpdateLastScannedBlock(nextScannedBlock!);
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
    int lastScannedBlock = epicGetLastScannedBlock() ?? 0;
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
  Future<void> recoverFromMnemonic({
    required String mnemonic,
    String? mnemonicPassphrase, // unused in epic
    required int maxUnusedAddressGap,
    required int maxNumberOfIndexesToCheck,
    required int height,
  }) async {
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

      await Future.wait([
        epicUpdateRestoreHeight(height),
        updateCachedId(walletId),
        epicUpdateReceivingIndex(0),
        epicUpdateChangeIndex(0),
        updateCachedIsFavorite(false),
      ]);

      //Open Wallet
      final walletOpen = openWallet(stringConfig, password);
      await _secureStore.write(key: '${_walletId}_wallet', value: walletOpen);

      //Store Epic box address info
      await storeEpicboxInfo();
    } catch (e, s) {
      Logging.instance
          .log("Error recovering wallet $e\n$s", level: LogLevel.Error);
      rethrow;
    }
  }

  Future<int> getRestoreHeight() async {
    return epicGetRestoreHeight() ?? epicGetCreationHeight()!;
  }

  Future<int> get chainHeight async {
    try {
      final config = await getRealConfig();
      int? latestHeight;
      await m.protect(() async {
        latestHeight = await compute(
          _getChainHeightWrapper,
          config,
        );
      });

      await updateCachedChainHeight(latestHeight!);
      if (latestHeight! > storedChainHeight) {
        GlobalEventBus.instance.fire(
          UpdatedInBackgroundEvent(
            "Updated current chain height in $walletId $walletName!",
            walletId,
          ),
        );
      }
      return latestHeight!;
    } catch (e, s) {
      Logging.instance.log("Exception caught in chainHeight: $e\n$s",
          level: LogLevel.Error);
      return storedChainHeight;
    }
  }

  @override
  int get storedChainHeight => getCachedChainHeight();

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
      final int receivingIndex = epicGetReceivingIndex()!;
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
      var slatesToCommits = epicGetSlatesToCommits();
      if (slatesToCommits == null) {
        slatesToCommits = <dynamic, dynamic>{};
      } else {
        slatesToCommits = slatesToCommits;
      }
      return slatesToCommits;
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
      await epicUpdateSlatesToCommits(slatesToCommits);
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
      await epicUpdateSlatesToCommits(slatesToCommits);
      return true;
    } catch (e, s) {
      Logging.instance.log("$e $s", level: LogLevel.Error);
      return false;
    }
  }

  Future<bool> processAllSlates() async {
    final int? receivingIndex = epicGetReceivingIndex();
    for (int currentReceivingIndex = 0;
        receivingIndex != null && currentReceivingIndex <= receivingIndex;
        currentReceivingIndex++) {
      final currentAddress =
          await _getReceivingAddressForIndex(currentReceivingIndex);
      final wallet = await _secureStore.read(key: '${_walletId}_wallet');
      final epicboxConfig =
          await _secureStore.read(key: '${_walletId}_epicboxConfig');
      dynamic subscribeRequest;
      await m.protect(() async {
        ReceivePort receivePort = await getIsolate({
          "function": "subscribeRequest",
          "wallet": wallet,
          "secretKeyIndex": currentReceivingIndex,
          "epicboxConfig": epicboxConfig,
        }, name: walletName);

        var result = await receivePort.first;
        if (result is String) {
          Logging.instance
              .log("this is a message $result", level: LogLevel.Error);
          stop(receivePort);
          throw Exception("subscribeRequest isolate failed");
        }
        subscribeRequest = jsonDecode(result['result'] as String);
        stop(receivePort);
        Logging.instance.log('Closing subscribeRequest! $subscribeRequest',
            level: LogLevel.Info);
      });
      // TODO, once server adds signature, give this signature to the getSlates method.
      Logging.instance
          .log(subscribeRequest['signature'], level: LogLevel.Info); //
      final unprocessedSlates = await getSlates(
          currentAddress.value, subscribeRequest['signature'] as String);
      if (unprocessedSlates == null || unprocessedSlates is! List) {
        Logging.instance.log(
            "index $currentReceivingIndex at ${await currentReceivingAddress} does not have any slates",
            level: LogLevel.Info);
        continue;
      }
      for (var slate in unprocessedSlates) {
        final encoded = jsonEncode([slate]);
        Logging.instance
            .log("Received Slates is $encoded", level: LogLevel.Info);

        //Decrypt Slates
        dynamic slates;
        dynamic response;
        await m.protect(() async {
          ReceivePort receivePort = await getIsolate({
            "function": "getPendingSlates",
            "wallet": wallet!,
            "secretKeyIndex": currentReceivingIndex,
            "slates": encoded,
          }, name: walletName);

          var result = await receivePort.first;
          if (result is String) {
            Logging.instance
                .log("this is a message $slates", level: LogLevel.Info);
            stop(receivePort);
            throw Exception("getPendingSlates isolate failed");
          }
          slates = result['result'];
          stop(receivePort);
        });

        var decoded = jsonDecode(slates as String);

        for (var decodedSlate in decoded as List) {
          //Process slates
          var decodedResponse = json.decode(decodedSlate as String);
          String slateMessage = decodedResponse[0] as String;
          await putSlatesToCommits(slateMessage, encoded);
          String slateSender = decodedResponse[1] as String;
          Logging.instance.log("SLATE_MESSAGE $slateMessage",
              printFullLength: true, level: LogLevel.Info);
          Logging.instance
              .log("SLATE_SENDER $slateSender", level: LogLevel.Info);
          await m.protect(() async {
            ReceivePort receivePort = await getIsolate({
              "function": "processSlates",
              "wallet": wallet!,
              "slates": slateMessage
            }, name: walletName);

            var message = await receivePort.first;
            if (message is String) {
              Logging.instance.log("this is PROCESS_SLATES message $message",
                  level: LogLevel.Error);
              stop(receivePort);
              throw Exception("processSlates isolate failed");
            }

            try {
              final String response = message['result'] as String;
              if (response == "") {
                Logging.instance.log("response: ${response.runtimeType}",
                    level: LogLevel.Info);
                await deleteSlate(currentAddress.value,
                    subscribeRequest['signature'] as String, slate as String);
              }

              if (response
                  .contains("Error Wallet store error: DB Not Found Error")) {
                //Already processed - to be deleted
                Logging.instance
                    .log("DELETING_PROCESSED_SLATE", level: LogLevel.Info);
                final slateDelete = await deleteSlate(currentAddress.value,
                    subscribeRequest['signature'] as String, slate as String);
                Logging.instance.log("DELETE_SLATE_RESPONSE $slateDelete",
                    level: LogLevel.Info);
              } else {
                var decodedResponse = json.decode(response);
                final processStatus = json.decode(decodedResponse[0] as String);
                String slateStatus = processStatus['status'] as String;
                if (slateStatus == "PendingProcessing") {
                  //Encrypt slate
                  String encryptedSlate = await getEncryptedSlate(
                      wallet,
                      slateSender,
                      currentReceivingIndex,
                      epicboxConfig!,
                      decodedResponse[1] as String);

                  final postSlateToServer =
                      await postSlate(slateSender, encryptedSlate);

                  await deleteSlate(currentAddress.value,
                      subscribeRequest['signature'] as String, slate as String);
                  Logging.instance.log("POST_SLATE_RESPONSE $postSlateToServer",
                      level: LogLevel.Info);
                } else {
                  //Finalise Slate
                  final processSlate =
                      json.decode(decodedResponse[1] as String);
                  Logging.instance.log(
                      "PROCESSED_SLATE_TO_FINALIZE $processSlate",
                      level: LogLevel.Info);
                  final tx = json.decode(processSlate[0] as String);
                  Logging.instance.log("TX_IS $tx", level: LogLevel.Info);
                  String txSlateId = tx[0]['tx_slate_id'] as String;
                  Logging.instance
                      .log("TX_SLATE_ID_IS $txSlateId", level: LogLevel.Info);
                  final postToNode = await postSlateToNode(wallet, txSlateId);
                  await deleteSlate(currentAddress.value,
                      subscribeRequest['signature'] as String, slate as String);
                  Logging.instance.log("POST_SLATE_RESPONSE $postToNode",
                      level: LogLevel.Info);
                  //Post Slate to Node
                  Logging.instance.log("Finalise slate", level: LogLevel.Info);
                }
              }
            } catch (e, s) {
              Logging.instance.log("$e\n$s", level: LogLevel.Info);
              return false;
            }
            stop(receivePort);
            Logging.instance
                .log('Closing processSlates! $response', level: LogLevel.Info);
          });
        }
      }
    }
    return true;
  }

  Future<bool> processAllCancels() async {
    Logging.instance.log("processAllCancels", level: LogLevel.Info);
    final wallet = await _secureStore.read(key: '${_walletId}_wallet');
    final epicboxConfig =
        await _secureStore.read(key: '${_walletId}_epicboxConfig');
    final int? receivingIndex = epicGetReceivingIndex();

    for (int currentReceivingIndex = 0;
        receivingIndex != null && currentReceivingIndex <= receivingIndex;
        currentReceivingIndex++) {
      final receiveAddress =
          await _getReceivingAddressForIndex(currentReceivingIndex);

      dynamic subscribeRequest;
      await m.protect(() async {
        ReceivePort receivePort = await getIsolate({
          "function": "subscribeRequest",
          "wallet": wallet!,
          "secretKeyIndex": currentReceivingIndex,
          "epicboxConfig": epicboxConfig,
        }, name: walletName);

        var result = await receivePort.first;
        if (result is String) {
          Logging.instance
              .log("this is a message $result", level: LogLevel.Info);
          stop(receivePort);
          throw Exception("subscribeRequest isolate failed");
        }
        subscribeRequest = jsonDecode(result['result'] as String);
        stop(receivePort);
        Logging.instance.log('Closing subscribeRequest! $subscribeRequest',
            level: LogLevel.Info);
      });
      String? signature = subscribeRequest['signature'] as String?;
      final cancels = await getCancels(receiveAddress.value, signature!);

      final slatesToCommits = await getSlatesToCommits();
      for (final cancel in cancels as List<dynamic>) {
        final txSlateId = cancel.keys.first as String;
        if (slatesToCommits[txSlateId] == null) {
          continue;
        }
        final cancelRequestSender = ((cancel as Map).values.first) as String;
        final receiveAddressFromMap =
            slatesToCommits[txSlateId]['to'] as String;
        final sendersAddressFromMap =
            slatesToCommits[txSlateId]['from'] as String;
        final commitId = slatesToCommits[txSlateId]['commitId'] as String;

        if (sendersAddressFromMap != cancelRequestSender) {
          Logging.instance.log("this was not signed by the correct address",
              level: LogLevel.Error);
          continue;
        }

        try {
          await cancelPendingTransaction(txSlateId);
          final tx = await db
              .getTransactions(walletId)
              .filter()
              .txidEqualTo(commitId)
              .findFirst();
          if ((tx?.isCancelled ?? false) == true) {
            await deleteCancels(receiveAddressFromMap, signature, txSlateId);
          }
        } catch (e, s) {
          Logging.instance.log("$e, $s", level: LogLevel.Error);
          return false;
        }
      }
      continue;
    }
    return true;
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
      GlobalEventBus.instance.fire(
        WalletSyncStatusChangedEvent(
          WalletSyncStatus.syncing,
          walletId,
          coin,
        ),
      );

      if (epicGetCreationHeight() == null) {
        await epicUpdateCreationHeight(await chainHeight);
      }

      final int curAdd = await setCurrentIndex();
      await _getReceivingAddressForIndex(curAdd);

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

      await processAllSlates();
      await processAllCancels();

      unawaited(startSync());

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
        await _refreshTransactions();
        GlobalEventBus.instance
            .fire(RefreshPercentChangedEvent(0.50, walletId));

        GlobalEventBus.instance.fire(UpdatedInBackgroundEvent(
            "New data found in $walletName in background!", walletId));
      }

      await _refreshBalance();

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

  bool _isConnected = false;

  @override
  bool get isConnected => _isConnected;

  Future<void> _refreshTransactions() async {
    // final currentChainHeight = await chainHeight;
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

    final List<Tuple2<isar_models.Transaction, isar_models.Address?>> txnsData =
        [];

    // int latestTxnBlockHeight =
    //     DB.instance.get<dynamic>(boxName: walletId, key: "storedTxnDataHeight")
    //             as int? ??
    //         0;
    final slatesToCommits = await getSlatesToCommits();

    for (var tx in jsonTransactions) {
      Logging.instance.log("tx: $tx", level: LogLevel.Info);
      // // TODO: does "confirmed" mean finalized? If so please remove this todo
      final isConfirmed = tx["confirmed"] as bool;
      // // TODO: since we are now caching tx history in hive are we losing anything by skipping here?
      // // TODO: we can skip this filtering if it causes issues as the cache is later merged with updated data anyways
      // // this would just make processing and updating cache more efficient
      // if (txHeight > 0 &&
      //     txHeight < latestTxnBlockHeight - MINIMUM_CONFIRMATIONS &&
      //     isConfirmed) {
      //   continue;
      // }
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

      DateTime dt = DateTime.parse(tx["creation_ts"] as String);

      String? slateId = tx['tx_slate_id'] as String?;
      String address = slatesToCommits[slateId]
              ?[tx["tx_type"] == "TxReceived" ? "from" : "to"] as String? ??
          "";
      String? commitId = slatesToCommits[slateId]?['commitId'] as String?;

      int? height;

      if (isConfirmed) {
        height = tx["kernel_lookup_min_height"] as int? ?? 1;
      } else {
        height = null;
      }

      final txn = isar_models.Transaction(
        walletId: walletId,
        txid: commitId ?? tx["id"].toString(),
        timestamp: (dt.millisecondsSinceEpoch ~/ 1000),
        type: (tx["tx_type"] == "TxReceived" ||
                tx["tx_type"] == "TxReceivedCancelled")
            ? isar_models.TransactionType.incoming
            : isar_models.TransactionType.outgoing,
        subType: isar_models.TransactionSubType.none,
        amount: amt,
        fee: (tx["fee"] == null) ? 0 : int.parse(tx["fee"] as String),
        height: height,
        isCancelled: tx["tx_type"] == "TxSentCancelled" ||
            tx["tx_type"] == "TxReceivedCancelled",
        isLelantus: false,
        slateId: slateId,
        otherData: tx["id"].toString(),
        inputs: [],
        outputs: [],
      );

      // txn.address =
      //     ""; // for this when you send a transaction you will just need to save in a hashmap in hive with the key being the txid, and the value being the address it was sent to. then you can look this value up right here in your hashmap.
      isar_models.Address? transactionAddress = await db
          .getAddresses(walletId)
          .filter()
          .valueEqualTo(address)
          .findFirst();
      //
      // midSortedTx["inputSize"] = tx["num_inputs"];
      // midSortedTx["outputSize"] = tx["num_outputs"];
      // midSortedTx["aliens"] = <dynamic>[];
      // midSortedTx["inputs"] = <dynamic>[];
      // midSortedTx["outputs"] = <dynamic>[];

      // key id not used afaik?
      // midSortedTx["key_id"] = tx["parent_key_id"];

      // if (txHeight >= latestTxnBlockHeight) {
      //   latestTxnBlockHeight = txHeight;
      // }

      txnsData.add(Tuple2(txn, transactionAddress));
      // cachedMap?.remove(tx["id"].toString());
      // cachedMap?.remove(commitId);
      // Logging.instance.log("cmap: $cachedMap", level: LogLevel.Info);
    }

    await db.addNewTransactionData(txnsData, walletId);

    // quick hack to notify manager to call notifyListeners if
    // transactions changed
    if (txnsData.isNotEmpty) {
      GlobalEventBus.instance.fire(
        UpdatedInBackgroundEvent(
          "Transactions updated/added for: $walletId $walletName  ",
          walletId,
        ),
      );
    }

    // midSortedArray
    //     .sort((a, b) => (b["timestamp"] as int) - (a["timestamp"] as int));
    //
    // final Map<String, dynamic> result = {"dateTimeChunks": <dynamic>[]};
    // final dateArray = <dynamic>[];
    //
    // for (int i = 0; i < midSortedArray.length; i++) {
    //   final txObject = midSortedArray[i];
    //   final date = extractDateFromTimestamp(txObject["timestamp"] as int);
    //
    //   final txTimeArray = [txObject["timestamp"], date];
    //
    //   if (dateArray.contains(txTimeArray[1])) {
    //     result["dateTimeChunks"].forEach((dynamic chunk) {
    //       if (extractDateFromTimestamp(chunk["timestamp"] as int) ==
    //           txTimeArray[1]) {
    //         if (chunk["transactions"] == null) {
    //           chunk["transactions"] = <Map<String, dynamic>>[];
    //         }
    //         chunk["transactions"].add(txObject);
    //       }
    //     });
    //   } else {
    //     dateArray.add(txTimeArray[1]);
    //
    //     final chunk = {
    //       "timestamp": txTimeArray[0],
    //       "transactions": [txObject],
    //     };
    //
    //     // result["dateTimeChunks"].
    //     result["dateTimeChunks"].add(chunk);
    //   }
    // }
    // final transactionsMap =
    //     TransactionData.fromJson(result).getAllTransactions();
    // if (cachedMap != null) {
    //   transactionsMap.addAll(cachedMap);
    // }
    //
    // final txModel = TransactionData.fromMap(transactionsMap);
    //
    // await DB.instance.put<dynamic>(
    //     boxName: walletId,
    //     key: 'storedTxnDataHeight',
    //     value: latestTxnBlockHeight);
    // await DB.instance.put<dynamic>(
    //     boxName: walletId, key: 'latest_tx_model', value: txModel);
    //
    // return txModel;
  }

  @override
  Future<void> updateSentCachedTxData(Map<String, dynamic> txData) async {
    // not used in epic
  }

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
  late final String _walletId;

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
    return currentFee;
  }

  // not used in epic currently
  @override
  Future<bool> generateNewAddress() async {
    try {
      return true;
    } catch (e, s) {
      Logging.instance.log(
          "Exception rethrown from generateNewAddress(): $e\n$s",
          level: LogLevel.Error);
      return false;
    }
  }

  Future<void> _refreshBalance() async {
    String walletBalances = await allWalletBalances();
    var jsonBalances = json.decode(walletBalances);

    final spendable =
        (jsonBalances['amount_currently_spendable'] as double).toString();

    final pending =
        (jsonBalances['amount_awaiting_confirmation'] as double).toString();

    final total = (jsonBalances['total'] as double).toString();
    final awaiting =
        (jsonBalances['amount_awaiting_finalization'] as double).toString();

    _balance = Balance(
      coin: coin,
      total: Format.decimalAmountToSatoshis(
        Decimal.parse(total) + Decimal.parse(awaiting),
        coin,
      ),
      spendable: Format.decimalAmountToSatoshis(
        Decimal.parse(spendable),
        coin,
      ),
      blockedTotal: 0,
      pendingSpendable: Format.decimalAmountToSatoshis(
        Decimal.parse(pending),
        coin,
      ),
    );

    await updateCachedBalance(_balance!);
  }

  @override
  Balance get balance => _balance ??= getCachedBalance();
  Balance? _balance;

  @override
  Future<List<isar_models.UTXO>> get utxos => throw UnimplementedError();

  @override
  Future<List<isar_models.Transaction>> get transactions =>
      db.getTransactions(walletId).findAll();
}

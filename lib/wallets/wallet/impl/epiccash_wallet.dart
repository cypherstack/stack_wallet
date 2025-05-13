import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:decimal/decimal.dart';
import 'package:flutter_libepiccash/lib.dart' as epiccash;
import 'package:flutter_libepiccash/models/transaction.dart' as epic_models;
import 'package:isar/isar.dart';
import 'package:mutex/mutex.dart';
import 'package:stack_wallet_backup/generate_password.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../../exceptions/wallet/node_tor_mismatch_config_exception.dart';
import '../../../models/balance.dart';
import '../../../models/epicbox_config_model.dart';
import '../../../models/isar/models/blockchain_data/address.dart';
import '../../../models/isar/models/blockchain_data/transaction.dart';
import '../../../models/isar/models/blockchain_data/v2/input_v2.dart';
import '../../../models/isar/models/blockchain_data/v2/output_v2.dart';
import '../../../models/isar/models/blockchain_data/v2/transaction_v2.dart';
import '../../../models/node_model.dart';
import '../../../models/paymint/fee_object_model.dart';
import '../../../pages/settings_views/global_settings_view/manage_nodes_views/add_edit_node_view.dart';
import '../../../services/event_bus/events/global/blocks_remaining_event.dart';
import '../../../services/event_bus/events/global/node_connection_status_changed_event.dart';
import '../../../services/event_bus/events/global/refresh_percent_changed_event.dart';
import '../../../services/event_bus/events/global/wallet_sync_status_changed_event.dart';
import '../../../services/event_bus/global_event_bus.dart';
import '../../../utilities/amount/amount.dart';
import '../../../utilities/default_epicboxes.dart';
import '../../../utilities/flutter_secure_storage_interface.dart';
import '../../../utilities/logger.dart';
import '../../../utilities/stack_file_system.dart';
import '../../../utilities/test_epic_box_connection.dart';
import '../../../utilities/tor_plain_net_option_enum.dart';
import '../../crypto_currency/crypto_currency.dart';
import '../../models/tx_data.dart';
import '../intermediate/bip39_wallet.dart';
import '../supporting/epiccash_wallet_info_extension.dart';

//
// refactor of https://github.com/cypherstack/stack_wallet/blob/1d9fb4cd069f22492ece690ac788e05b8f8b1209/lib/services/coins/epiccash/epiccash_wallet.dart
//
class EpiccashWallet extends Bip39Wallet {
  EpiccashWallet(CryptoCurrencyNetwork network) : super(Epiccash(network));

  final syncMutex = Mutex();
  NodeModel? _epicNode;
  Timer? timer;

  double highestPercent = 0;
  Future<double> get getSyncPercent async {
    final int lastScannedBlock = info.epicData?.lastScannedBlock ?? 0;
    final _chainHeight = await chainHeight;
    final double restorePercent = lastScannedBlock / _chainHeight;
    GlobalEventBus.instance.fire(
      RefreshPercentChangedEvent(highestPercent, walletId),
    );
    if (restorePercent > highestPercent) {
      highestPercent = restorePercent;
    }

    final int blocksRemaining = _chainHeight - lastScannedBlock;
    GlobalEventBus.instance.fire(
      BlocksRemainingEvent(blocksRemaining, walletId),
    );

    return restorePercent < 0 ? 0.0 : restorePercent;
  }

  Future<void> updateEpicboxConfig(String host, int port) async {
    final String stringConfig = jsonEncode({
      "epicbox_domain": host,
      "epicbox_port": port,
      "epicbox_protocol_unsecure": false,
      "epicbox_address_index": 0,
    });
    await secureStorageInterface.write(
      key: '${walletId}_epicboxConfig',
      value: stringConfig,
    );
    // TODO: refresh anything that needs to be refreshed/updated due to epicbox info changed
  }

  /// returns an empty String on success, error message on failure
  Future<String> cancelPendingTransactionAndPost(String txSlateId) async {
    try {
      _hackedCheckTorNodePrefs();
      final String wallet =
          (await secureStorageInterface.read(key: '${walletId}_wallet'))!;

      final result = await epiccash.LibEpiccash.cancelTransaction(
        wallet: wallet,
        transactionId: txSlateId,
      );
      Logging.instance.d("cancel $txSlateId result: $result");
      return result;
    } catch (e, s) {
      Logging.instance.e("", error: e, stackTrace: s);
      return e.toString();
    }
  }

  Future<EpicBoxConfigModel> getEpicBoxConfig() async {
    final EpicBoxConfigModel _epicBoxConfig = EpicBoxConfigModel.fromServer(
      DefaultEpicBoxes.defaultEpicBoxServer,
    );

    //Get the default Epicbox server and check if it's conected
    // bool isEpicboxConnected = await _testEpicboxServer(
    //     DefaultEpicBoxes.defaultEpicBoxServer.host, DefaultEpicBoxes.defaultEpicBoxServer.port ?? 443);

    // if (isEpicboxConnected) {
    //Use default server for as Epicbox config

    // }
    // else {
    //   //Use Europe config
    //   _epicBoxConfig = EpicBoxConfigModel.fromServer(DefaultEpicBoxes.europe);
    // }
    //   // example of selecting another random server from the default list
    //   // alternative servers: copy list of all default EB servers but remove the default default
    //   // List<EpicBoxServerModel> alternativeServers = DefaultEpicBoxes.all;
    //   // alternativeServers.removeWhere((opt) => opt.name == DefaultEpicBoxes.defaultEpicBoxServer.name);
    //   // alternativeServers.shuffle(); // randomize which server is used
    //   // _epicBoxConfig = EpicBoxConfigModel.fromServer(alternativeServers.first);
    //
    //   // TODO test this connection before returning it
    // }

    return _epicBoxConfig;
  }

  // ================= Private =================================================

  Future<String> _getConfig() async {
    if (_epicNode == null) {
      await updateNode();
    }
    final NodeModel node = _epicNode!;
    final String nodeAddress = node.host;
    final int port = node.port;

    final uri = Uri.parse(nodeAddress).replace(port: port);

    final String nodeApiAddress = uri.toString();

    final walletDir = await _currentWalletDirPath();

    final Map<String, dynamic> config = {};
    config["wallet_dir"] = walletDir;
    config["check_node_api_http_addr"] = nodeApiAddress;
    config["chain"] = "mainnet";
    config["account"] = "default";
    config["api_listen_port"] = port;
    config["api_listen_interface"] = nodeApiAddress.replaceFirst(
      uri.scheme,
      "",
    );
    final String stringConfig = jsonEncode(config);
    return stringConfig;
  }

  Future<String> _currentWalletDirPath() async {
    final Directory appDir = await StackFileSystem.applicationRootDirectory();

    final path = "${appDir.path}/epiccash";
    final String name = walletId.trim();
    return '$path/$name';
  }

  Future<int> _nativeFee(
    int satoshiAmount, {
    bool ifErrorEstimateFee = false,
  }) async {
    final wallet = await secureStorageInterface.read(key: '${walletId}_wallet');
    try {
      _hackedCheckTorNodePrefs();
      final available = info.cachedBalance.spendable.raw.toInt();

      final transactionFees = await epiccash.LibEpiccash.getTransactionFees(
        wallet: wallet!,
        amount: satoshiAmount,
        minimumConfirmations: cryptoCurrency.minConfirms,
        available: available,
      );

      int realFee = 0;
      try {
        realFee =
            (Decimal.parse(transactionFees.fee.toString())).toBigInt().toInt();
      } catch (e, s) {
        //todo: come back to this
        Logging.instance.e("Error getting fees", error: e, stackTrace: s);
      }
      return realFee;
    } catch (e, s) {
      Logging.instance.e("Error getting fees $e - $s", error: e, stackTrace: s);
      rethrow;
    }
  }

  Future<void> _startSync() async {
    _hackedCheckTorNodePrefs();
    Logging.instance.d("request start sync");
    final wallet = await secureStorageInterface.read(key: '${walletId}_wallet');
    const int refreshFromNode = 1;
    if (!syncMutex.isLocked) {
      await syncMutex.protect(() async {
        // How does getWalletBalances start syncing????
        await epiccash.LibEpiccash.getWalletBalances(
          wallet: wallet!,
          refreshFromNode: refreshFromNode,
          minimumConfirmations: 10,
        );
      });
    } else {
      Logging.instance.d("request start sync denied");
    }
  }

  Future<
    ({
      double awaitingFinalization,
      double pending,
      double spendable,
      double total,
    })
  >
  _allWalletBalances() async {
    _hackedCheckTorNodePrefs();
    final wallet = await secureStorageInterface.read(key: '${walletId}_wallet');
    const refreshFromNode = 0;
    return await epiccash.LibEpiccash.getWalletBalances(
      wallet: wallet!,
      refreshFromNode: refreshFromNode,
      minimumConfirmations: cryptoCurrency.minConfirms,
    );
  }

  Future<bool> _testEpicboxServer(EpicBoxConfigModel epicboxConfig) async {
    _hackedCheckTorNodePrefs();
    final host = epicboxConfig.host;
    final port = epicboxConfig.port ?? 443;
    WebSocketChannel? channel;
    try {
      final uri = Uri.parse('wss://$host:$port');

      channel = WebSocketChannel.connect(uri);

      await channel.ready;

      final response = await channel.stream.first.timeout(
        const Duration(seconds: 2),
      );

      return response is String && response.contains("Challenge");
    } catch (e, s) {
      Logging.instance.w(
        "_testEpicBoxConnection failed on \"$host:$port\"",
        error: e,
        stackTrace: s,
      );
      return false;
    } finally {
      await channel?.sink.close();
    }
  }

  Future<bool> _putSendToAddresses(
    ({String slateId, String commitId}) slateData,
    Map<String, String> txAddressInfo,
  ) async {
    try {
      final slatesToCommits = info.epicData?.slatesToCommits ?? {};
      final from = txAddressInfo['from'];
      final to = txAddressInfo['to'];
      slatesToCommits[slateData.slateId] = {
        "commitId": slateData.commitId,
        "from": from,
        "to": to,
      };
      await info.updateExtraEpiccashWalletInfo(
        epicData: info.epicData!.copyWith(slatesToCommits: slatesToCommits),
        isar: mainDB.isar,
      );
      return true;
    } catch (e, s) {
      Logging.instance.e("ERROR STORING ADDRESS", error: e, stackTrace: s);
      return false;
    }
  }

  Future<int> _getCurrentIndex() async {
    try {
      final int receivingIndex = info.epicData!.receivingIndex;
      // TODO: go through pendingarray and processed array and choose the index
      //  of the last one that has not been processed, or the index after the one most recently processed;
      return receivingIndex;
    } catch (e, s) {
      Logging.instance.e("$e $s", error: e, stackTrace: s);
      return 0;
    }
  }

  /// Only index 0 is currently used in stack wallet.
  Future<Address> _generateAndStoreReceivingAddressForIndex(int index) async {
    // Since only 0 is a valid index in stack wallet at this time, lets just
    // throw is not zero
    if (index != 0) {
      throw Exception("Invalid/unexpected address index used");
    }

    final epicBoxConfig = await getEpicBoxConfig();
    final address = await thisWalletAddress(index, epicBoxConfig);

    if (info.cachedReceivingAddress != address.value) {
      await info.updateReceivingAddress(
        newAddress: address.value,
        isar: mainDB.isar,
      );
    }
    return address;
  }

  Future<Address> thisWalletAddress(
    int index,
    EpicBoxConfigModel epicboxConfig,
  ) async {
    final wallet = await secureStorageInterface.read(key: '${walletId}_wallet');

    final walletAddress = await epiccash.LibEpiccash.getAddressInfo(
      wallet: wallet!,
      index: index,
      epicboxConfig: epicboxConfig.toString(),
    );

    Logging.instance.d("WALLET_ADDRESS_IS $walletAddress");

    final address = Address(
      walletId: walletId,
      value: walletAddress,
      derivationIndex: index,
      derivationPath: null,
      type: AddressType.mimbleWimble,
      subType: AddressSubType.receiving,
      publicKey: [], // ??
    );
    await mainDB.updateOrPutAddresses([address]);
    return address;
  }

  Future<void> _startScans() async {
    try {
      //First stop the current listener
      epiccash.LibEpiccash.stopEpicboxListener();
      final wallet = await secureStorageInterface.read(
        key: '${walletId}_wallet',
      );

      // max number of blocks to scan per loop iteration
      const scanChunkSize = 10000;

      // force firing of scan progress event
      await getSyncPercent;

      // fetch current chain height and last scanned block (should be the
      // restore height if full rescan or a wallet restore)
      int chainHeight = await this.chainHeight;
      int lastScannedBlock = info.epicData!.lastScannedBlock;

      // loop while scanning in chain in chunks (of blocks?)
      while (lastScannedBlock < chainHeight) {
        Logging.instance.d(
          "chainHeight: $chainHeight, lastScannedBlock: $lastScannedBlock",
        );

        final int nextScannedBlock = await epiccash.LibEpiccash.scanOutputs(
          wallet: wallet!,
          startHeight: lastScannedBlock,
          numberOfBlocks: scanChunkSize,
        );

        // update local cache
        await info.updateExtraEpiccashWalletInfo(
          epicData: info.epicData!.copyWith(lastScannedBlock: nextScannedBlock),
          isar: mainDB.isar,
        );

        // force firing of scan progress event
        await getSyncPercent;

        // update while loop condition variables
        chainHeight = await this.chainHeight;
        lastScannedBlock = nextScannedBlock;
      }

      Logging.instance.d("_startScans successfully at the tip");
      //Once scanner completes restart listener
      await _listenToEpicbox();
    } catch (e, s) {
      Logging.instance.e("_startScans failed: ", error: e, stackTrace: s);
      rethrow;
    }
  }

  Future<void> _listenToEpicbox() async {
    Logging.instance.d("STARTING WALLET LISTENER ....");
    final wallet = await secureStorageInterface.read(key: '${walletId}_wallet');
    final EpicBoxConfigModel epicboxConfig = await getEpicBoxConfig();
    epiccash.LibEpiccash.startEpicboxListener(
      wallet: wallet!,
      epicboxConfig: epicboxConfig.toString(),
    );
  }

  // As opposed to fake config?
  Future<String> _getRealConfig() async {
    String? config = await secureStorageInterface.read(
      key: '${walletId}_config',
    );
    if (Platform.isIOS) {
      final walletDir = await _currentWalletDirPath();
      final editConfig = jsonDecode(config as String);

      editConfig["wallet_dir"] = walletDir;
      config = jsonEncode(editConfig);
    }
    return config!;
  }

  // TODO: make more robust estimate of date maybe using https://explorer.epic.tech/api-index
  int _calculateRestoreHeightFrom({required DateTime date}) {
    final int secondsSinceEpoch = date.millisecondsSinceEpoch ~/ 1000;
    const int epicCashFirstBlock = 1565370278;
    const double overestimateSecondsPerBlock = 61;
    final int chosenSeconds = secondsSinceEpoch - epicCashFirstBlock;
    final int approximateHeight = chosenSeconds ~/ overestimateSecondsPerBlock;
    int height = approximateHeight;
    if (height < 0) {
      height = 0;
    }
    return height;
  }

  // ============== Overrides ==================================================

  @override
  int get isarTransactionVersion => 2;

  @override
  FilterOperation? get changeAddressFilterOperation =>
      FilterGroup.and(standardChangeAddressFilters);

  @override
  FilterOperation? get receivingAddressFilterOperation =>
      FilterGroup.and(standardReceivingAddressFilters);

  @override
  Future<void> checkSaveInitialReceivingAddress() async {
    // epiccash seems ok with nothing here?
  }

  @override
  Future<void> init({bool? isRestore}) async {
    if (isRestore != true) {
      String? encodedWallet = await secureStorageInterface.read(
        key: "${walletId}_wallet",
      );

      // check if should create a new wallet
      if (encodedWallet == null) {
        await updateNode();
        final mnemonicString = await getMnemonic();

        final String password = generatePassword();
        final String stringConfig = await _getConfig();
        final EpicBoxConfigModel epicboxConfig = await getEpicBoxConfig();

        await secureStorageInterface.write(
          key: '${walletId}_config',
          value: stringConfig,
        );
        await secureStorageInterface.write(
          key: '${walletId}_password',
          value: password,
        );
        await secureStorageInterface.write(
          key: '${walletId}_epicboxConfig',
          value: epicboxConfig.toString(),
        );

        final String name = walletId;

        await epiccash.LibEpiccash.initializeNewWallet(
          config: stringConfig,
          mnemonic: mnemonicString,
          password: password,
          name: name,
        );

        //Open wallet
        encodedWallet = await epiccash.LibEpiccash.openWallet(
          config: stringConfig,
          password: password,
        );
        await secureStorageInterface.write(
          key: '${walletId}_wallet',
          value: encodedWallet,
        );

        //Store Epic box address info
        await _generateAndStoreReceivingAddressForIndex(0);

        // subtract a couple days to ensure we have a buffer for SWB
        final bufferedCreateHeight = _calculateRestoreHeightFrom(
          date: DateTime.now().subtract(const Duration(days: 2)),
        );

        final epicData = ExtraEpiccashWalletInfo(
          receivingIndex: 0,
          changeIndex: 0,
          slatesToAddresses: {},
          slatesToCommits: {},
          lastScannedBlock: bufferedCreateHeight,
          restoreHeight: bufferedCreateHeight,
          creationHeight: bufferedCreateHeight,
        );

        await info.updateExtraEpiccashWalletInfo(
          epicData: epicData,
          isar: mainDB.isar,
        );
      } else {
        try {
          Logging.instance.d(
            "initializeExisting() ${cryptoCurrency.prettyName} wallet",
          );

          final config = await _getRealConfig();
          final password = await secureStorageInterface.read(
            key: '${walletId}_password',
          );

          final walletOpen = await epiccash.LibEpiccash.openWallet(
            config: config,
            password: password!,
          );
          await secureStorageInterface.write(
            key: '${walletId}_wallet',
            value: walletOpen,
          );

          await updateNode();
        } catch (e, s) {
          // do nothing, still allow user into wallet
          Logging.instance.w(
            "$runtimeType init() failed: ",
            error: e,
            stackTrace: s,
          );
        }
      }
    }

    return await super.init();
  }

  @override
  Future<TxData> confirmSend({required TxData txData}) async {
    try {
      _hackedCheckTorNodePrefs();
      final wallet = await secureStorageInterface.read(
        key: '${walletId}_wallet',
      );
      final EpicBoxConfigModel epicboxConfig = await getEpicBoxConfig();

      // TODO determine whether it is worth sending change to a change address.

      final String receiverAddress = txData.recipients!.first.address;

      if (!receiverAddress.startsWith("http://") ||
          !receiverAddress.startsWith("https://")) {
        final bool isEpicboxConnected = await _testEpicboxServer(epicboxConfig);
        if (!isEpicboxConnected) {
          throw Exception("Failed to send TX : Unable to reach epicbox server");
        }
      }

      ({String commitId, String slateId}) transaction;

      if (receiverAddress.startsWith("http://") ||
          receiverAddress.startsWith("https://")) {
        transaction = await epiccash.LibEpiccash.txHttpSend(
          wallet: wallet!,
          selectionStrategyIsAll: 0,
          minimumConfirmations: cryptoCurrency.minConfirms,
          message: txData.noteOnChain ?? "",
          amount: txData.recipients!.first.amount.raw.toInt(),
          address: txData.recipients!.first.address,
        );
      } else {
        transaction = await epiccash.LibEpiccash.createTransaction(
          wallet: wallet!,
          amount: txData.recipients!.first.amount.raw.toInt(),
          address: txData.recipients!.first.address,
          secretKeyIndex: 0,
          epicboxConfig: epicboxConfig.toString(),
          minimumConfirmations: cryptoCurrency.minConfirms,
          note: txData.noteOnChain!,
        );
      }

      final Map<String, String> txAddressInfo = {};
      txAddressInfo['from'] = (await getCurrentReceivingAddress())!.value;
      txAddressInfo['to'] = txData.recipients!.first.address;
      await _putSendToAddresses(transaction, txAddressInfo);

      return txData.copyWith(txid: transaction.slateId);
    } catch (e, s) {
      Logging.instance.e("Epic cash confirmSend: ", error: e, stackTrace: s);
      rethrow;
    }
  }

  @override
  Future<TxData> prepareSend({required TxData txData}) async {
    try {
      _hackedCheckTorNodePrefs();
      if (txData.recipients?.length != 1) {
        throw Exception("Epic cash prepare send requires a single recipient!");
      }

      ({String address, Amount amount, bool isChange}) recipient =
          txData.recipients!.first;

      final int realFee = await _nativeFee(recipient.amount.raw.toInt());
      final feeAmount = Amount(
        rawValue: BigInt.from(realFee),
        fractionDigits: cryptoCurrency.fractionDigits,
      );

      if (feeAmount > info.cachedBalance.spendable) {
        throw Exception(
          "Epic cash prepare send fee is greater than available balance!",
        );
      }

      if (info.cachedBalance.spendable == recipient.amount) {
        recipient = (
          address: recipient.address,
          amount: recipient.amount - feeAmount,
          isChange: recipient.isChange,
        );
      }

      return txData.copyWith(recipients: [recipient], fee: feeAmount);
    } catch (e, s) {
      Logging.instance.e("Epic cash prepareSend", error: e, stackTrace: s);
      rethrow;
    }
  }

  @override
  Future<void> recover({required bool isRescan}) async {
    try {
      _hackedCheckTorNodePrefs();
      await refreshMutex.protect(() async {
        if (isRescan) {
          // clear blockchain info
          await mainDB.deleteWalletBlockchainData(walletId);

          await info.updateExtraEpiccashWalletInfo(
            epicData: info.epicData!.copyWith(
              lastScannedBlock: info.epicData!.restoreHeight,
            ),
            isar: mainDB.isar,
          );

          unawaited(refresh(doScan: true));
        } else {
          await updateNode();
          final String password = generatePassword();

          final String stringConfig = await _getConfig();
          final EpicBoxConfigModel epicboxConfig = await getEpicBoxConfig();

          await secureStorageInterface.write(
            key: '${walletId}_config',
            value: stringConfig,
          );
          await secureStorageInterface.write(
            key: '${walletId}_password',
            value: password,
          );

          await secureStorageInterface.write(
            key: '${walletId}_epicboxConfig',
            value: epicboxConfig.toString(),
          );

          await epiccash.LibEpiccash.recoverWallet(
            config: stringConfig,
            password: password,
            mnemonic: await getMnemonic(),
            name: info.walletId,
          );

          final epicData = ExtraEpiccashWalletInfo(
            receivingIndex: 0,
            changeIndex: 0,
            slatesToAddresses: {},
            slatesToCommits: {},
            lastScannedBlock: info.restoreHeight,
            restoreHeight: info.restoreHeight,
            creationHeight: info.epicData?.creationHeight ?? info.restoreHeight,
          );

          await info.updateExtraEpiccashWalletInfo(
            epicData: epicData,
            isar: mainDB.isar,
          );

          //Open Wallet
          final walletOpen = await epiccash.LibEpiccash.openWallet(
            config: stringConfig,
            password: password,
          );
          await secureStorageInterface.write(
            key: '${walletId}_wallet',
            value: walletOpen,
          );

          await _generateAndStoreReceivingAddressForIndex(
            epicData.receivingIndex,
          );
        }
        unawaited(refresh(doScan: false));
      });
    } catch (e, s) {
      Logging.instance.e(
        "Exception rethrown from electrumx_mixin recover(): ",
        error: e,
        stackTrace: s,
      );

      rethrow;
    }
  }

  @override
  Future<void> refresh({bool doScan = true}) async {
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
          cryptoCurrency,
        ),
      );
      _hackedCheckTorNodePrefs();

      // if (info.epicData?.creationHeight == null) {
      //   await info.updateExtraEpiccashWalletInfo(epicData: inf, isar: isar)
      //   await epicUpdateCreationHeight(await chainHeight);
      // }

      // this will always be zero????
      final int curAdd = await _getCurrentIndex();
      await _generateAndStoreReceivingAddressForIndex(curAdd);

      if (doScan) {
        await _startScans();

        unawaited(_startSync());
      }

      GlobalEventBus.instance.fire(RefreshPercentChangedEvent(0.0, walletId));
      await updateChainHeight();

      GlobalEventBus.instance.fire(RefreshPercentChangedEvent(0.1, walletId));

      //  if (this is MultiAddressInterface) {
      //   await (this as MultiAddressInterface)
      //       .checkReceivingAddressForTransactions();
      // }

      GlobalEventBus.instance.fire(RefreshPercentChangedEvent(0.2, walletId));

      // // TODO: [prio=low] handle this differently. Extra modification of this file for coin specific functionality should be avoided.
      // if (this is MultiAddressInterface) {
      //   await (this as MultiAddressInterface)
      //       .checkChangeAddressForTransactions();
      // }
      GlobalEventBus.instance.fire(RefreshPercentChangedEvent(0.3, walletId));

      GlobalEventBus.instance.fire(RefreshPercentChangedEvent(0.50, walletId));
      final fetchFuture = updateTransactions();
      // if (currentHeight != storedHeight) {
      GlobalEventBus.instance.fire(RefreshPercentChangedEvent(0.60, walletId));

      GlobalEventBus.instance.fire(RefreshPercentChangedEvent(0.70, walletId));

      await fetchFuture;
      GlobalEventBus.instance.fire(RefreshPercentChangedEvent(0.80, walletId));

      // await getAllTxsToWatch();

      GlobalEventBus.instance.fire(RefreshPercentChangedEvent(0.90, walletId));

      await updateBalance();

      GlobalEventBus.instance.fire(RefreshPercentChangedEvent(1.0, walletId));
      GlobalEventBus.instance.fire(
        WalletSyncStatusChangedEvent(
          WalletSyncStatus.synced,
          walletId,
          cryptoCurrency,
        ),
      );

      if (shouldAutoSync) {
        timer ??= Timer.periodic(const Duration(seconds: 150), (timer) async {
          // chain height check currently broken
          // if ((await chainHeight) != (await storedChainHeight)) {

          // TODO: [prio=med] some kind of quick check if wallet needs to refresh to replace the old refreshIfThereIsNewData call
          // if (await refreshIfThereIsNewData()) {
          unawaited(refresh());

          // }
          // }
        });
      }
    } catch (e, s) {
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
      Logging.instance.e(
        "Caught exception in refreshWalletData()",
        error: e,
        stackTrace: s,
      );
    } finally {
      refreshMutex.release();
    }
  }

  @override
  Future<void> updateBalance() async {
    try {
      _hackedCheckTorNodePrefs();
      final balances = await _allWalletBalances();
      final balance = Balance(
        total: Amount.fromDecimal(
          Decimal.parse(balances.total.toString()) +
              Decimal.parse(balances.awaitingFinalization.toString()),
          fractionDigits: cryptoCurrency.fractionDigits,
        ),
        spendable: Amount.fromDecimal(
          Decimal.parse(balances.spendable.toString()),
          fractionDigits: cryptoCurrency.fractionDigits,
        ),
        blockedTotal: Amount.zeroWith(
          fractionDigits: cryptoCurrency.fractionDigits,
        ),
        pendingSpendable: Amount.fromDecimal(
          Decimal.parse(balances.pending.toString()),
          fractionDigits: cryptoCurrency.fractionDigits,
        ),
      );

      await info.updateBalance(newBalance: balance, isar: mainDB.isar);
    } catch (e, s) {
      Logging.instance.w(
        "Epic cash wallet failed to update balance: ",
        error: e,
        stackTrace: s,
      );
    }
  }

  @override
  Future<void> updateTransactions() async {
    try {
      _hackedCheckTorNodePrefs();
      final wallet = await secureStorageInterface.read(
        key: '${walletId}_wallet',
      );
      const refreshFromNode = 1;

      final myAddresses =
          await mainDB
              .getAddresses(walletId)
              .filter()
              .typeEqualTo(AddressType.mimbleWimble)
              .and()
              .subTypeEqualTo(AddressSubType.receiving)
              .and()
              .valueIsNotEmpty()
              .valueProperty()
              .findAll();
      final myAddressesSet = myAddresses.toSet();

      final transactions = await epiccash.LibEpiccash.getTransactions(
        wallet: wallet!,
        refreshFromNode: refreshFromNode,
      );

      final List<TransactionV2> txns = [];

      final slatesToCommits = info.epicData?.slatesToCommits ?? {};

      for (final tx in transactions) {
        final isIncoming =
            tx.txType == epic_models.TransactionType.TxReceived ||
            tx.txType == epic_models.TransactionType.TxReceivedCancelled;
        final slateId = tx.txSlateId;
        final commitId = slatesToCommits[slateId]?['commitId'] as String?;
        final numberOfMessages = tx.messages?.messages.length;
        final onChainNote = tx.messages?.messages[0].message;
        final addressFrom = slatesToCommits[slateId]?["from"] as String?;
        final addressTo = slatesToCommits[slateId]?["to"] as String?;

        final credit = int.parse(tx.amountCredited);
        final debit = int.parse(tx.amountDebited);
        final fee = int.tryParse(tx.fee ?? "0") ?? 0;

        // hack epic tx data into inputs and outputs
        final List<OutputV2> outputs = [];
        final List<InputV2> inputs = [];
        final addressFromIsMine = myAddressesSet.contains(addressFrom);
        final addressToIsMine = myAddressesSet.contains(addressTo);

        OutputV2 output = OutputV2.isarCantDoRequiredInDefaultConstructor(
          scriptPubKeyHex: "00",
          valueStringSats: credit.toString(),
          addresses: [if (addressFrom != null) addressFrom],
          walletOwns: true,
        );
        final InputV2 input = InputV2.isarCantDoRequiredInDefaultConstructor(
          scriptSigHex: null,
          scriptSigAsm: null,
          sequence: null,
          outpoint: null,
          addresses: [if (addressTo != null) addressTo],
          valueStringSats: debit.toString(),
          witness: null,
          innerRedeemScriptAsm: null,
          coinbase: null,
          walletOwns: true,
        );

        final TransactionType txType;
        if (isIncoming) {
          if (addressToIsMine && addressFromIsMine) {
            txType = TransactionType.sentToSelf;
          } else {
            txType = TransactionType.incoming;
          }
          output = output.copyWith(
            addresses: [
              myAddressesSet
                  .first, // Must be changed if we ever do more than a single wallet address!!!
            ],
            walletOwns: true,
          );
        } else {
          txType = TransactionType.outgoing;
        }

        outputs.add(output);
        inputs.add(input);

        final otherData = {
          "isEpiccashTransaction": true,
          "numberOfMessages": numberOfMessages,
          "slateId": slateId,
          "onChainNote": onChainNote,
          "isCancelled":
              tx.txType == epic_models.TransactionType.TxSentCancelled ||
              tx.txType == epic_models.TransactionType.TxReceivedCancelled,
          "overrideFee":
              Amount(
                rawValue: BigInt.from(fee),
                fractionDigits: cryptoCurrency.fractionDigits,
              ).toJsonString(),
        };

        final txn = TransactionV2(
          walletId: walletId,
          blockHash: null,
          hash: commitId ?? tx.id.toString(),
          txid: commitId ?? tx.id.toString(),
          timestamp:
              DateTime.parse(tx.creationTs).millisecondsSinceEpoch ~/ 1000,
          height: tx.confirmed ? tx.kernelLookupMinHeight ?? 1 : null,
          inputs: List.unmodifiable(inputs),
          outputs: List.unmodifiable(outputs),
          version: 0,
          type: txType,
          subType: TransactionSubType.none,
          otherData: jsonEncode(otherData),
        );

        txns.add(txn);
      }

      await mainDB.isar.writeTxn(() async {
        await mainDB.isar.transactionV2s
            .where()
            .walletIdEqualTo(walletId)
            .deleteAll();
        await mainDB.isar.transactionV2s.putAll(txns);
      });
    } catch (e, s) {
      Logging.instance.e(
        "${cryptoCurrency.runtimeType} ${cryptoCurrency.network} net wallet"
        " \"${info.name}\"_${info.walletId} updateTransactions() failed",
        error: e,
        stackTrace: s,
      );
    }
  }

  @override
  Future<bool> updateUTXOs() async {
    // not used for epiccash
    return false;
  }

  @override
  Future<void> updateNode() async {
    _epicNode = getCurrentNode();

    // TODO: [prio=low] move this out of secure storage if secure storage not needed
    final String stringConfig = await _getConfig();
    await secureStorageInterface.write(
      key: '${walletId}_config',
      value: stringConfig,
    );

    // unawaited(refresh());
  }

  @override
  Future<bool> pingCheck() async {
    try {
      final node = nodeService.getPrimaryNodeFor(currency: cryptoCurrency);

      // force unwrap optional as we want connection test to fail if wallet
      // wasn't initialized or epicbox node was set to null
      return await testEpicNodeConnection(
            NodeFormData()
              ..host = node!.host
              ..useSSL = node.useSSL
              ..port = node.port
              ..netOption = TorPlainNetworkOption.fromNodeData(
                node.torEnabled,
                node.clearnetEnabled,
              ),
          ) !=
          null;
    } catch (e, s) {
      Logging.instance.e("", error: e, stackTrace: s);
      return false;
    }
  }

  @override
  Future<void> updateChainHeight() async {
    _hackedCheckTorNodePrefs();
    final config = await _getRealConfig();
    final latestHeight = await epiccash.LibEpiccash.getChainHeight(
      config: config,
    );
    await info.updateCachedChainHeight(
      newHeight: latestHeight,
      isar: mainDB.isar,
    );
  }

  @override
  Future<Amount> estimateFeeFor(Amount amount, BigInt feeRate) async {
    _hackedCheckTorNodePrefs();
    // setting ifErrorEstimateFee doesn't do anything as its not used in the nativeFee function?????
    final int currentFee = await _nativeFee(
      amount.raw.toInt(),
      ifErrorEstimateFee: true,
    );
    return Amount(
      rawValue: BigInt.from(currentFee),
      fractionDigits: cryptoCurrency.fractionDigits,
    );
  }

  @override
  Future<FeeObject> get fees async {
    // this wasn't done before the refactor either so...
    // TODO: implement _getFees
    return FeeObject(
      numberOfBlocksFast: 10,
      numberOfBlocksAverage: 10,
      numberOfBlocksSlow: 10,
      fast: BigInt.one,
      medium: BigInt.one,
      slow: BigInt.one,
    );
  }

  @override
  Future<TxData> updateSentCachedTxData({required TxData txData}) async {
    // TODO: [prio=low] Was not used before refactor so maybe not required(?)
    return txData;
  }

  @override
  Future<void> exit() async {
    epiccash.LibEpiccash.stopEpicboxListener();
    timer?.cancel();
    timer = null;
    await super.exit();
    Logging.instance.d("EpicCash_wallet exit finished");
  }

  void _hackedCheckTorNodePrefs() {
    final node = nodeService.getPrimaryNodeFor(currency: cryptoCurrency)!;
    final netOption = TorPlainNetworkOption.fromNodeData(
      node.torEnabled,
      node.clearnetEnabled,
    );

    if (prefs.useTor) {
      if (netOption == TorPlainNetworkOption.clear) {
        throw NodeTorMismatchConfigException(
          message: "TOR enabled but node set to clearnet only",
        );
      }
    } else {
      if (netOption == TorPlainNetworkOption.tor) {
        throw NodeTorMismatchConfigException(
          message: "TOR off but node set to TOR only",
        );
      }
    }
  }
}

Future<String> deleteEpicWallet({
  required String walletId,
  required SecureStorageInterface secureStore,
}) async {
  final wallet = await secureStore.read(key: '${walletId}_wallet');
  String? config = await secureStore.read(key: '${walletId}_config');
  if (Platform.isIOS) {
    final Directory appDir = await StackFileSystem.applicationRootDirectory();

    final path = "${appDir.path}/epiccash";
    final String name = walletId.trim();
    final walletDir = '$path/$name';

    final editConfig = jsonDecode(config as String);

    editConfig["wallet_dir"] = walletDir;
    config = jsonEncode(editConfig);
  }

  if (wallet == null) {
    return "Tried to delete non existent epic wallet file with walletId=$walletId";
  } else {
    try {
      return epiccash.LibEpiccash.deleteWallet(wallet: wallet, config: config!);
    } catch (e, s) {
      Logging.instance.e("$e\n$s", error: e, stackTrace: s);
      return "deleteEpicWallet($walletId) failed...";
    }
  }
}

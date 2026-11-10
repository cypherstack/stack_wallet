import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:decimal/decimal.dart';
import 'package:flutter/foundation.dart';
import 'package:isar_community/isar.dart';
import 'package:mutex/mutex.dart';
import 'package:stack_wallet_backup/generate_password.dart';

import '../../../models/isar/models/blockchain_data/address.dart';
import '../../../models/isar/models/blockchain_data/transaction.dart';
import '../../../models/isar/models/blockchain_data/v2/input_v2.dart';
import '../../../models/isar/models/blockchain_data/v2/output_v2.dart';
import '../../../models/isar/models/blockchain_data/v2/transaction_v2.dart';
import '../../../models/mwcmqs_config_model.dart';
import '../../../models/node_model.dart';
import '../../../models/slatepack_models.dart';
import '../../../pages/settings_views/global_settings_view/manage_nodes_views/add_edit_node_view.dart';
import '../../../utilities/amount/amount.dart';
import '../../../utilities/default_mwcmqs.dart';
import '../../../utilities/enums/slatepack_method.dart';
import '../../../utilities/flutter_secure_storage_interface.dart';
import '../../../utilities/logger.dart';
import '../../../utilities/stack_file_system.dart';
import '../../../utilities/test_mwcmqs_connection.dart';
import '../../../wl_gen/interfaces/libmwc_interface.dart';
import '../../crypto_currency/crypto_currency.dart';
import '../../isar/models/wallet_info.dart';
import '../../models/tx_data.dart';
import '../intermediate/mimblewimble_wallet.dart';
import '../supporting/mimblewimble_wallet_info_extension.dart';
import '../wallet_mixin_interfaces/slatepack_interface.dart';

class MimblewimblecoinWallet extends MimblewimbleWallet {
  MimblewimblecoinWallet(CryptoCurrencyNetwork network)
    : super(Mimblewimblecoin(network));

  final Mutex _walletOpenMutex = Mutex();
  NodeModel? _mimblewimblecoinNode;

  static bool _mwcLogsInitialized = false;

  // Process-scoped Rust pointer; do not persist.
  String? _walletHandle;

  @override
  String get walletInfoDataKey => WalletInfoKeys.mimblewimblecoinData;

  @override
  String get walletDirName => "mimblewimblecoin";

  @override
  int get firstBlockTimestamp => 1573462801;

  @override
  Future<void> updateRelayConfig(String host, int port) async {
    final String stringConfig = jsonEncode(<String, dynamic>{
      "mwcmqs_domain": host,
      "mwcmqs_port": port,
    });
    await secureStorageInterface.write(
      key: '${walletId}_mwcmqsConfig',
      value: stringConfig,
    );

    try {
      if (_walletHandle != null) {
        await stopSlatepackListener();
        await startSlatepackListener();
        Logging.instance.i(
          'Restarted MWCMQS listener with new config: $host:$port',
        );
      }
    } catch (e, s) {
      Logging.instance.e(
        'Failed to restart MWCMQS listener after config update: $e\n$s',
      );
    }
  }

  Future<String> _ensureWalletOpen() async {
    return await _walletOpenMutex.protect(() async {
      final String? cached = _walletHandle;
      if (cached != null && cached.isNotEmpty) return cached;

      final String config = await _getRealConfig();
      if (!_mwcLogsInitialized) {
        try {
          await libMwc.initLogs(config: config);
          _mwcLogsInitialized = true;
        } catch (e, s) {
          Logging.instance.w("libMwc.initLogs failed: $e\n$s");
        }
      }
      final String? password = await secureStorageInterface.read(
        key: '${walletId}_password',
      );
      if (password == null) {
        throw Exception('Wallet password not found');
      }
      final String opened = await libMwc
          .openWallet(config: config, password: password)
          .timeout(
            const Duration(seconds: 60),
            onTimeout: () => throw TimeoutException('openWallet timed out'),
          );
      _walletHandle = opened;
      return opened;
    });
  }

  @override
  Future<String> cancelPendingTransactionAndPost(String txSlateId) async {
    try {
      final String wallet = await _ensureWalletOpen();

      final String result = await libMwc.cancelTransaction(
        wallet: wallet,
        transactionId: txSlateId,
      );
      Logging.instance.i("cancel $txSlateId result: $result");
      return result;
    } catch (e, s) {
      Logging.instance.e("$e, $s");
      return e.toString();
    }
  }

  @override
  Future<MwcMqsConfigModel> getRelayConfig() async {
    // Check if there's a custom MWCMQS config stored.
    final String? customConfigJson = await secureStorageInterface.read(
      key: '${walletId}_mwcmqsConfig',
    );

    if (customConfigJson != null) {
      try {
        final Map<String, dynamic> customConfig =
            jsonDecode(customConfigJson) as Map<String, dynamic>;
        final String? host = customConfig['mwcmqs_domain'] as String?;
        final int? port = customConfig['mwcmqs_port'] as int?;

        if (host != null && port != null) {
          return MwcMqsConfigModel(host: host, port: port);
        }
      } catch (e) {
        Logging.instance.w('Failed to parse custom MWCMQS config: $e');
      }
    }

    // Fall back to default server.
    return MwcMqsConfigModel.fromServer(DefaultMwcMqs.defaultMwcMqsServer);
  }

  // ================= Slatepack Operations ===================================

  /// Encrypts to [recipientAddress] when one is given. [sendAll] is
  /// ignored; prepareSend already took the fee off the amount.
  @override
  Future<SlatepackResult> createSlatepack({
    required Amount amount,
    String? recipientAddress,
    String? message,
    bool sendAll = false,
  }) async {
    try {
      final String handle = await _ensureWalletOpen();
      final String? recipient =
          recipientAddress == null || recipientAddress.isEmpty
          ? null
          : recipientAddress;

      // Generate S1 slate JSON.
      final String s1Json = await libMwc.txInit(
        wallet: handle,
        amount: amount.raw.toInt(),
        minimumConfirmations: cryptoCurrency.minConfirms,
        selectionStrategyIsAll: false,
        message: message ?? '',
      );

      // Encode to slatepack.
      final encoded = await libMwc.encodeSlatepack(
        slateJson: s1Json,
        recipientAddress: recipient,
        encrypt: recipient != null,
        wallet: handle,
      );

      final info = inspectSlateJsonString(s1Json);
      return SlatepackResult(
        success: true,
        slatepack: encoded.slatepack,
        slateJson: s1Json,
        wasEncrypted: encoded.wasEncrypted,
        recipientAddress: encoded.recipientAddress,
        state: SlateState.s1,
        slateId: info?.slateId,
        amount: info?.amount ?? amount,
        fee: info?.fee,
      );
    } catch (e, s) {
      Logging.instance.e('Failed to create slatepack: $e\n$s');
      return SlatepackResult(success: false, error: e.toString());
    }
  }

  @override
  void checkSlatepackFormat(String slatepack) {
    if (!isSlatepack(slatepack)) {
      throw Exception("Invalid slatepack format");
    }
  }

  @override
  Future<SlatepackDecodeResult> decodeSlatepack(String slatepack) async {
    try {
      final String? handle = _walletHandle;
      final result = handle != null
          ? await libMwc.decodeSlatepackWithWallet(
              wallet: handle,
              slatepack: slatepack,
            )
          : await libMwc.decodeSlatepack(slatepack: slatepack);

      return SlatepackDecodeResult(
        success: true,
        slateJson: result.slateJson,
        wasEncrypted: result.wasEncrypted,
        senderAddress: result.senderAddress,
        recipientAddress: result.recipientAddress,
      );
    } catch (e, s) {
      Logging.instance.e('Failed to decode slatepack: $e\n$s');
      return SlatepackDecodeResult(success: false, error: e.toString());
    }
  }

  @override
  Future<SlatepackResult> receiveSlatepack(String slatepack) async {
    try {
      final String handle = await _ensureWalletOpen();

      // Decode to get slate JSON and sender address.
      final decoded = await libMwc.decodeSlatepackWithWallet(
        wallet: handle,
        slatepack: slatepack,
      );

      // Receive and get updated slate JSON.
      final received = await libMwc.txReceiveDetailed(
        wallet: handle,
        slateJson: decoded.slateJson,
      );

      // Encode response back to sender if address available.
      final encoded = await libMwc.encodeSlatepack(
        slateJson: received.slateJson,
        recipientAddress: decoded.senderAddress,
        encrypt: decoded.senderAddress != null,
        wallet: handle,
      );

      final info = inspectSlateJsonString(received.slateJson);
      return SlatepackResult(
        success: true,
        slatepack: encoded.slatepack,
        slateJson: received.slateJson,
        wasEncrypted: encoded.wasEncrypted,
        recipientAddress: decoded.senderAddress,
        state: SlateState.s2,
        slateId: received.slateId,
        amount: info?.amount,
        fee: info?.fee,
      );
    } catch (e, s) {
      Logging.instance.e('Failed to receive slatepack: $e\n$s');
      return SlatepackResult(success: false, error: e.toString());
    }
  }

  @override
  Future<FinalizeResult> finalizeSlatepack(String slatepack) async {
    try {
      final String handle = await _ensureWalletOpen();

      // Decode to get slate JSON.
      final decoded = await libMwc.decodeSlatepackWithWallet(
        wallet: handle,
        slatepack: slatepack,
      );

      // Finalize transaction.
      final finalized = await libMwc.txFinalize(
        wallet: handle,
        slateJson: decoded.slateJson,
      );

      return FinalizeResult(
        success: true,
        slateId: finalized.slateId,
        commitId: finalized.commitId,
        posted: true,
      );
    } catch (e, s) {
      Logging.instance.e('Failed to finalize slatepack: $e\n$s');
      return FinalizeResult(success: false, error: e.toString());
    }
  }

  /// Start MWCMQS listener for automatic transaction processing.
  Future<void> startSlatepackListener() async {
    try {
      final String wallet = await _ensureWalletOpen();
      final MwcMqsConfigModel mwcmqsConfig = await getRelayConfig();
      libMwc.startMwcMqsListener(
        wallet: wallet,
        mwcmqsConfig: mwcmqsConfig.toString(),
      );
    } catch (e, s) {
      Logging.instance.e('Failed to start slatepack listener: $e\n$s');
      rethrow;
    }
  }

  /// Stop MWCMQS listener.
  Future<void> stopSlatepackListener() async {
    try {
      libMwc.stopMwcMqsListener();
    } catch (e, s) {
      Logging.instance.e('Failed to stop slatepack listener: $e\n$s');
    }
  }

  /// Validate MWC address.
  bool validateMwcAddress(String address) {
    return libMwc.validateSendAddress(address: address);
  }

  bool isSlatepack(String data) {
    return data.trim().startsWith('BEGINSLATE') &&
        (data.trim().endsWith('ENDSLATEPACK') ||
            data.trim().endsWith('ENDSLATEPACK.') ||
            data.trim().endsWith('ENDSLATE_BIN') ||
            data.trim().endsWith('ENDSLATE_BIN.'));
  }

  /// Detect if an address is MWCMQS format.
  bool isMwcmqsAddress(String address) {
    return address.startsWith('mwcmqs://');
  }

  // ================= Private =================================================

  Future<void> _ensureApiSecret(String walletDir) async {
    final File file = File('$walletDir/.api_secret');
    final String? secret = _mimblewimblecoinNode?.nodeApiSecret;
    if (secret != null) {
      await Directory(walletDir).create(recursive: true);
      await file.writeAsString(secret);
    } else if (await file.exists()) {
      await file.delete();
    }
  }

  Future<String> _getConfig() async {
    if (_mimblewimblecoinNode == null) {
      await updateNode();
    }
    final NodeModel node = _mimblewimblecoinNode!;
    final String nodeAddress = node.host;
    final int port = node.port;

    final Uri uri = Uri.parse(nodeAddress).replace(port: port);

    final String nodeApiAddress = uri.toString();
    final String walletDir = await currentWalletDirPath();

    final Map<String, dynamic> config = <String, dynamic>{};
    config["wallet_dir"] = walletDir;
    config["check_node_api_http_addr"] = nodeApiAddress;
    config["chain"] = "mainnet";
    config["account"] = "default";
    final String stringConfig = jsonEncode(config);
    return stringConfig;
  }

  @override
  Future<int> nativeFee(int satoshiAmount) async {
    final String wallet = await _ensureWalletOpen();
    try {
      final int available = info.cachedBalance.spendable.raw.toInt();
      final transactionFees = await libMwc.getTransactionFees(
        wallet: wallet,
        amount: satoshiAmount,
        minimumConfirmations: cryptoCurrency.minConfirms,
        available: available,
      );

      int realFee = 0;
      try {
        realFee = (Decimal.parse(transactionFees.fee.toString()))
            .toBigInt()
            .toInt();
      } catch (e, s) {
        //todo: come back to this
        debugPrint("$e $s");
      }
      return realFee;
    } catch (e, s) {
      Logging.instance.e("Error getting fees $e - $s");
      rethrow;
    }
  }

  @override
  Future<
    ({
      double awaitingFinalization,
      double pending,
      double spendable,
      double total,
    })
  >
  fetchWalletBalances({
    required int refreshFromNode,
    required int minimumConfirmations,
  }) async {
    final String wallet = await _ensureWalletOpen();
    return await libMwc.getWalletBalances(
      wallet: wallet,
      refreshFromNode: refreshFromNode,
      minimumConfirmations: minimumConfirmations,
    );
  }

  @override
  Future<int> fetchChainHeight() async {
    final String config = await _getRealConfig();
    return libMwc.getChainHeight(config: config);
  }

  Future<Address> _generateAndStoreReceivingAddressForIndex(int index) async {
    Address? address = await getCurrentReceivingAddress();

    if (address == null) {
      final MwcMqsConfigModel mwcmqsConfig = await getRelayConfig();
      address = await thisWalletAddress(index, mwcmqsConfig);
    }

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
    MwcMqsConfigModel mwcmqsConfig,
  ) async {
    final String wallet = await _ensureWalletOpen();

    final String walletAddress = await libMwc.getAddressInfo(
      wallet: wallet,
      index: index,
    );

    Logging.instance.i("WALLET_ADDRESS_IS $walletAddress");

    final Address address = Address(
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

  @override
  Future<int> scanOutputs({
    required int startHeight,
    required int numberOfBlocks,
  }) async {
    final String wallet = await _ensureWalletOpen();
    return libMwc.scanOutputs(
      wallet: wallet,
      startHeight: startHeight,
      numberOfBlocks: numberOfBlocks,
    );
  }

  @override
  Future<void> pauseListenerForScan({required bool needsScanning}) async {
    //First stop the current listener
    libMwc.stopMwcMqsListener();
    await _ensureWalletOpen();
  }

  @override
  Future<void> resumeListenerAfterScan() async {
    //Once scanner completes restart listener
    await _listenToMwcmqs();
  }

  Future<void> _listenToMwcmqs() async {
    Logging.instance.i("STARTING WALLET LISTENER ....");
    final String wallet = await _ensureWalletOpen();
    final MwcMqsConfigModel mwcmqsConfig = await getRelayConfig();
    libMwc.startMwcMqsListener(
      wallet: wallet,
      mwcmqsConfig: mwcmqsConfig.toString(),
    );
  }

  // As opposed to fake config?
  Future<String> _getRealConfig() async {
    String? config = await secureStorageInterface.read(
      key: '${walletId}_config',
    );
    if (Platform.isIOS) {
      final String walletDir = await currentWalletDirPath();
      final dynamic editConfig = jsonDecode(config as String);

      editConfig["wallet_dir"] = walletDir;
      config = jsonEncode(editConfig);
    }
    return config!;
  }

  // ============== Overrides ==================================================

  @override
  Future<void> prepareRefresh() async {
    // this will always be zero????
    final int curAdd = await getCurrentIndex();
    await _generateAndStoreReceivingAddressForIndex(curAdd);
  }

  @override
  Future<void> init({bool? isRestore}) async {
    if (isRestore != true) {
      // Password presence is the durable "wallet provisioned" marker; the
      // old wallet-handle marker was process-scoped.
      final String? existingPassword = await secureStorageInterface.read(
        key: '${walletId}_password',
      );

      if (existingPassword == null) {
        await updateNode();
        final String mnemonicString = await getMnemonic();

        final String password = generatePassword();
        final String stringConfig = await _getConfig();
        final MwcMqsConfigModel mwcmqsConfig = await getRelayConfig();
        await secureStorageInterface.write(
          key: '${walletId}_config',
          value: stringConfig,
        );
        await secureStorageInterface.write(
          key: '${walletId}_password',
          value: password,
        );
        await secureStorageInterface.write(
          key: '${walletId}_mwcmqsConfig',
          value: mwcmqsConfig.toString(),
        );

        final String name = walletId;

        await libMwc.initializeNewWallet(
          config: stringConfig,
          mnemonic: mnemonicString,
          password: password,
          name: name,
        );

        //Open wallet
        await _ensureWalletOpen();
        //Store MwcMqs address info
        await _generateAndStoreReceivingAddressForIndex(0);

        // subtract a couple days to ensure we have a buffer for SWB
        final int bufferedCreateHeight = calculateRestoreHeightFrom(
          date: DateTime.now().subtract(const Duration(days: 2)),
        );

        final ExtraMimblewimbleWalletInfo mimblewimblecoinData =
            ExtraMimblewimbleWalletInfo(
              receivingIndex: 0,
              changeIndex: 0,
              slatesToAddresses: {},
              slatesToCommits: {},
              lastScannedBlock: bufferedCreateHeight,
              restoreHeight: bufferedCreateHeight,
              creationHeight: bufferedCreateHeight,
            );

        await updateMimblewimbleData(mimblewimblecoinData);
      } else {
        try {
          await _ensureWalletOpen();

          await updateNode();
        } catch (e, s) {
          // do nothing, still allow user into wallet
          Logging.instance.e("$runtimeType init() failed: $e\n$s");
        }
      }
    }

    return await super.init();
  }

  @override
  Future<TxData> confirmSend({required TxData txData}) async {
    try {
      final String wallet = await _ensureWalletOpen();
      final MwcMqsConfigModel mwcmqsConfig = await getRelayConfig();

      // TODO determine whether it is worth sending change to a change address.

      final String receiverAddress = txData.recipients!.first.address;

      ({String commitId, String slateId}) transaction;

      if (receiverAddress.startsWith("http://") ||
          receiverAddress.startsWith("https://")) {
        transaction = await libMwc.txHttpSend(
          wallet: wallet,
          selectionStrategyIsAll: 0,
          minimumConfirmations: cryptoCurrency.minConfirms,
          message: txData.noteOnChain ?? "",
          amount: txData.recipients!.first.amount.raw.toInt(),
          address: txData.recipients!.first.address,
        );
      } else if (receiverAddress.startsWith("mwcmqs://")) {
        transaction = await libMwc.createTransaction(
          wallet: wallet,
          amount: txData.recipients!.first.amount.raw.toInt(),
          address: txData.recipients!.first.address,
          secretKeyIndex: 0,
          mwcmqsConfig: mwcmqsConfig.toString(),
          minimumConfirmations: cryptoCurrency.minConfirms,
          note: txData.noteOnChain!,
        );
      } else {
        throw Exception(
          "Unsupported address format: $receiverAddress. Please use a valid address.",
        );
      }

      final Map<String, String> txAddressInfo = <String, String>{};
      txAddressInfo['from'] = (await getCurrentReceivingAddress())!.value;
      txAddressInfo['to'] = txData.recipients!.first.address;
      await putSendToAddresses(transaction, txAddressInfo);

      return txData.copyWith(txid: transaction.slateId);
    } catch (e, s) {
      Logging.instance.e("Mimblewimblecoin confirmSend: $e\n$s");
      rethrow;
    }
  }

  @override
  Future<TxData> prepareSend({required TxData txData}) async {
    try {
      if (txData.recipients?.length != 1) {
        throw Exception(
          "Mimblewimblecoin prepare send requires a single recipient!",
        );
      }

      TxRecipient recipient = txData.recipients!.first;
      final String receiverAddress = recipient.address;

      // For regular address-based sends, calculate fee
      final int realFee = await nativeFee(recipient.amount.raw.toInt());
      final Amount feeAmount = Amount(
        rawValue: BigInt.from(realFee),
        fractionDigits: cryptoCurrency.fractionDigits,
      );

      if (feeAmount > info.cachedBalance.spendable) {
        throw Exception(
          "Mimblewimblecoin prepare send fee is greater than available balance!",
        );
      }

      if (info.cachedBalance.spendable == recipient.amount) {
        recipient = TxRecipient(
          address: recipient.address,
          amount: recipient.amount - feeAmount,
          isChange: recipient.isChange,
          addressType: AddressType.mimbleWimble,
        );
      }

      // A plain MWC address means a slatepack encrypted to it.
      final SlatepackMethod? method;
      if (txData.isSlatepackSend || receiverAddress.isEmpty) {
        method = SlatepackMethod.slatepack;
      } else if (isMwcmqsAddress(receiverAddress)) {
        method = SlatepackMethod.relay;
      } else if (isHttpAddress(receiverAddress)) {
        method = SlatepackMethod.http;
      } else if (validateMwcAddress(receiverAddress)) {
        method = SlatepackMethod.slatepack;
      } else {
        method = null;
      }

      return txData.copyWith(
        recipients: [recipient],
        fee: feeAmount,
        otherData: method == null ? null : slatepackMethodOtherData(method),
      );
    } catch (e, s) {
      Logging.instance.e("Mimblewimblecoin prepareSend: $e\n$s");
      rethrow;
    }
  }

  @override
  Future<void> recover({required bool isRescan}) async {
    try {
      await refreshMutex.protect(() async {
        if (isRescan) {
          // clear blockchain info
          await mainDB.deleteWalletBlockchainData(walletId);

          await updateMimblewimbleData(
            mimblewimbleData!.copyWith(
              lastScannedBlock: mimblewimbleData!.restoreHeight,
            ),
          );

          unawaited(startScans());
        } else {
          await updateNode();
          final String password = generatePassword();

          final String stringConfig = await _getConfig();
          final MwcMqsConfigModel mwcmqsConfig = await getRelayConfig();

          await secureStorageInterface.write(
            key: '${walletId}_config',
            value: stringConfig,
          );
          await secureStorageInterface.write(
            key: '${walletId}_password',
            value: password,
          );
          await secureStorageInterface.write(
            key: '${walletId}_mwcmqsConfig',
            value: mwcmqsConfig.toString(),
          );

          await libMwc.recoverWallet(
            config: stringConfig,
            password: password,
            mnemonic: await getMnemonic(),
            name: info.walletId,
          );

          final ExtraMimblewimbleWalletInfo mimblewimblecoinData =
              ExtraMimblewimbleWalletInfo(
                receivingIndex: 0,
                changeIndex: 0,
                slatesToAddresses: {},
                slatesToCommits: {},
                lastScannedBlock: info.restoreHeight,
                restoreHeight: info.restoreHeight,
                creationHeight:
                    mimblewimbleData?.creationHeight ?? info.restoreHeight,
              );

          await updateMimblewimbleData(mimblewimblecoinData);

          //Open Wallet
          await _ensureWalletOpen();

          await _generateAndStoreReceivingAddressForIndex(
            mimblewimblecoinData.receivingIndex,
          );
        }
      });

      unawaited(refresh());
    } catch (e, s) {
      Logging.instance.i(
        "Exception rethrown from electrumx_mixin recover(): $e\n$s",
      );

      rethrow;
    }
  }

  @override
  Future<void> updateTransactions() async {
    try {
      final String wallet = await _ensureWalletOpen();
      const int refreshFromNode = 1;

      final List<String> myAddresses = await mainDB
          .getAddresses(walletId)
          .filter()
          .typeEqualTo(AddressType.mimbleWimble)
          .and()
          .subTypeEqualTo(AddressSubType.receiving)
          .and()
          .valueIsNotEmpty()
          .valueProperty()
          .findAll();
      final Set<String> myAddressesSet = myAddresses.toSet();

      final List<MimblewimbleTransaction> transactions = await libMwc
          .getTransactions(wallet: wallet, refreshFromNode: refreshFromNode);

      final List<TransactionV2> txns = [];

      final Map<dynamic, dynamic> slatesToCommits =
          mimblewimbleData?.slatesToCommits ?? <dynamic, dynamic>{};

      for (final MimblewimbleTransaction tx in transactions) {
        Logging.instance.i("tx: $tx");

        final bool isIncoming =
            libMwc.txTypeIsReceived(tx.txType) ||
            libMwc.txTypeIsReceiveCancelled(tx.txType);
        final String? slateId = tx.txSlateId;
        final String? commitId =
            slatesToCommits[slateId]?['commitId'] as String?;
        final int? numberOfMessages = tx.messages?.length;
        final String? onChainNote = tx.onChainNote;
        final String? addressFrom =
            slatesToCommits[slateId]?["from"] as String?;
        final String? addressTo = slatesToCommits[slateId]?["to"] as String?;

        final int credit = int.parse(tx.amountCredited);
        final int debit = int.parse(tx.amountDebited);
        final int fee = int.tryParse(tx.fee ?? "0") ?? 0;

        // hack Mimblewimblecoin tx data into inputs and outputs
        final List<OutputV2> outputs = [];
        final List<InputV2> inputs = [];
        final bool addressFromIsMine = myAddressesSet.contains(addressFrom);
        final bool addressToIsMine = myAddressesSet.contains(addressTo);

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
              myAddressesSet.first, // Must be changed if we ever do more than a single wallet address!!!
            ],
            walletOwns: true,
          );
        } else {
          txType = TransactionType.outgoing;
        }

        outputs.add(output);
        inputs.add(input);

        final Map<String, dynamic> otherData = <String, dynamic>{
          "isMimblewimblecoinTransaction": true,
          "numberOfMessages": numberOfMessages,
          "slateId": slateId,
          "onChainNote": onChainNote,
          "isCancelled":
              libMwc.txTypeIsSentCancelled(tx.txType) ||
              libMwc.txTypeIsReceiveCancelled(tx.txType),
          "overrideFee": Amount(
            rawValue: BigInt.from(fee),
            fractionDigits: cryptoCurrency.fractionDigits,
          ).toJsonString(),
        };

        final TransactionV2 txn = TransactionV2(
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
      Logging.instance.w(
        "${cryptoCurrency.runtimeType} ${cryptoCurrency.network} net wallet"
        " \"${info.name}\"_${info.walletId} updateTransactions() failed: $e\n$s",
      );
    }
  }

  @override
  Future<void> updateNode() async {
    _mimblewimblecoinNode = getCurrentNode();

    final String walletDir = await currentWalletDirPath();
    await _ensureApiSecret(walletDir);

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
      final NodeModel? node = nodeService.getPrimaryNodeFor(
        currency: cryptoCurrency,
      );
      return await testMwcNodeConnection(
            NodeFormData()
              ..host = node!.host
              ..useSSL = node.useSSL
              ..port = node.port
              ..apiSecret = node.nodeApiSecret,
          ) !=
          null;
    } catch (e, s) {
      Logging.instance.i("$e\n$s");
      return false;
    }
  }
}

Future<String> deleteMimblewimblecoinWallet({
  required String walletId,
  required SecureStorageInterface secureStore,
}) async {
  await secureStore.delete(key: '${walletId}_wallet');

  String? config = await secureStore.read(key: '${walletId}_config');
  if (config == null) {
    return "Tried to delete non existent mimblewimblecoin wallet file with walletId=$walletId";
  }
  if (Platform.isIOS) {
    final Directory appDir = await StackFileSystem.applicationRootDirectory();

    final String path = "${appDir.path}/mimblewimblecoin";
    final String name = walletId.trim();
    final String walletDir = '$path/$name';

    final dynamic editConfig = jsonDecode(config);

    editConfig["wallet_dir"] = walletDir;
    config = jsonEncode(editConfig);
  }

  try {
    // Rust deleteWallet ignores the handle param.
    return libMwc.deleteWallet(wallet: "", config: config);
  } catch (e, s) {
    Logging.instance.e("$e\n$s");
    return "deleteMimblewimblecoinWallet($walletId) failed...";
  }
}

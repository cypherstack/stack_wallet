import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:decimal/decimal.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_libmwc/lib.dart' as mimblewimblecoin;
import 'package:flutter_libmwc/models/transaction.dart'
    as mimblewimblecoin_models;
import 'package:isar/isar.dart';
import 'package:mutex/mutex.dart';
import 'package:stack_wallet_backup/generate_password.dart';

import '../../../models/balance.dart';
import '../../../models/isar/models/blockchain_data/address.dart';
import '../../../models/isar/models/blockchain_data/transaction.dart';
import '../../../models/isar/models/blockchain_data/v2/input_v2.dart';
import '../../../models/isar/models/blockchain_data/v2/output_v2.dart';
import '../../../models/isar/models/blockchain_data/v2/transaction_v2.dart';
import '../../../models/mwc_slatepack_models.dart';
import '../../../models/mwcmqs_config_model.dart';
import '../../../models/node_model.dart';
import '../../../models/paymint/fee_object_model.dart';
import '../../../pages/settings_views/global_settings_view/manage_nodes_views/add_edit_node_view.dart';
import '../../../services/event_bus/events/global/blocks_remaining_event.dart';
import '../../../services/event_bus/events/global/node_connection_status_changed_event.dart';
import '../../../services/event_bus/events/global/refresh_percent_changed_event.dart';
import '../../../services/event_bus/events/global/wallet_sync_status_changed_event.dart';
import '../../../services/event_bus/global_event_bus.dart';
import '../../../utilities/amount/amount.dart';
import '../../../utilities/default_mwcmqs.dart';
import '../../../utilities/flutter_secure_storage_interface.dart';
import '../../../utilities/logger.dart';
import '../../../utilities/stack_file_system.dart';
import '../../../utilities/test_mwcmqs_connection.dart';
import '../../crypto_currency/crypto_currency.dart';
import '../../models/tx_data.dart';
import '../intermediate/bip39_wallet.dart';
import '../supporting/mimblewimblecoin_wallet_info_extension.dart';

class MimblewimblecoinWallet extends Bip39Wallet {
  MimblewimblecoinWallet(CryptoCurrencyNetwork network)
    : super(Mimblewimblecoin(network));

  final syncMutex = Mutex();
  NodeModel? _mimblewimblecoinNode;
  Timer? timer;

  double highestPercent = 0;
  Future<double> get getSyncPercent async {
    final int lastScannedBlock =
        info.mimblewimblecoinData?.lastScannedBlock ?? 0;
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

  Future<void> updateMwcmqsConfig(String host, int port) async {
    final String stringConfig = jsonEncode({
      "mwcmqs_domain": host,
      "mwcmqs_port": port,
    });
    await secureStorageInterface.write(
      key: '${walletId}_mwcmqsConfig',
      value: stringConfig,
    );

    // Restart MWCMQS listener with new configuration if wallet has a handle.
    try {
      final handle = await secureStorageInterface.read(
        key: '${walletId}_wallet',
      );
      if (handle != null && handle.isNotEmpty) {
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
    final existing = await secureStorageInterface.read(
      key: '${walletId}_wallet',
    );
    if (existing != null && existing.isNotEmpty) return existing;

    final config = await _getRealConfig();
    final password = await secureStorageInterface.read(
      key: '${walletId}_password',
    );
    if (password == null) {
      throw Exception('Wallet password not found');
    }
    final opened = await mimblewimblecoin.Libmwc.openWallet(
      config: config,
      password: password,
    );
    await secureStorageInterface.write(
      key: '${walletId}_wallet',
      value: opened,
    );
    return opened;
  }

  /// Returns an empty String on success, error message on failure.
  Future<String> cancelPendingTransactionAndPost(String txSlateId) async {
    try {
      final String wallet =
          (await secureStorageInterface.read(key: '${walletId}_wallet'))!;

      final result = await mimblewimblecoin.Libmwc.cancelTransaction(
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

  Future<MwcMqsConfigModel> getMwcMqsConfig() async {
    // Check if there's a custom MWCMQS config stored.
    final customConfigJson = await secureStorageInterface.read(
      key: '${walletId}_mwcmqsConfig',
    );

    if (customConfigJson != null) {
      try {
        final customConfig =
            jsonDecode(customConfigJson) as Map<String, dynamic>;
        final host = customConfig['mwcmqs_domain'] as String?;
        final port = customConfig['mwcmqs_port'] as int?;

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

  /// Create a slatepack for sending MWC.
  Future<SlatepackResult> createSlatepack({
    required Amount amount,
    String? recipientAddress,
    String? message,
    bool encrypt = false,
    int? minimumConfirmations,
  }) async {
    try {
      final handle = await _ensureWalletOpen();

      // Generate S1 slate JSON.
      final s1Json = await mimblewimblecoin.Libmwc.txInit(
        wallet: handle,
        amount: amount.raw.toInt(),
        minimumConfirmations:
            minimumConfirmations ?? cryptoCurrency.minConfirms,
        selectionStrategyIsAll: false,
        message: message ?? '',
      );

      // Encode to slatepack.
      final encoded = await mimblewimblecoin.Libmwc.encodeSlatepack(
        slateJson: s1Json,
        recipientAddress: recipientAddress,
        encrypt: encrypt,
        wallet: handle,
      );

      return SlatepackResult(
        success: true,
        slatepack: encoded.slatepack,
        slateJson: s1Json,
        wasEncrypted: encoded.wasEncrypted,
        recipientAddress: encoded.recipientAddress,
      );
    } catch (e, s) {
      Logging.instance.e('Failed to create slatepack: $e\n$s');
      return SlatepackResult(success: false, error: e.toString());
    }
  }

  /// Decode a slatepack.
  Future<SlatepackDecodeResult> decodeSlatepack(String slatepack) async {
    try {
      final handle = await secureStorageInterface.read(
        key: '${walletId}_wallet',
      );
      final result =
          handle != null
              ? await mimblewimblecoin.Libmwc.decodeSlatepackWithWallet(
                wallet: handle,
                slatepack: slatepack,
              )
              : await mimblewimblecoin.Libmwc.decodeSlatepack(
                slatepack: slatepack,
              );

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

  /// Receive a slatepack and return response slatepack.
  Future<ReceiveResult> receiveSlatepack(String slatepack) async {
    try {
      final handle = await _ensureWalletOpen();

      // Decode to get slate JSON and sender address.
      final decoded = await mimblewimblecoin.Libmwc.decodeSlatepackWithWallet(
        wallet: handle,
        slatepack: slatepack,
      );

      // Receive and get updated slate JSON.
      final received = await mimblewimblecoin.Libmwc.txReceiveDetailed(
        wallet: handle,
        slateJson: decoded.slateJson,
      );

      // Encode response back to sender if address available.
      final encoded = await mimblewimblecoin.Libmwc.encodeSlatepack(
        slateJson: received.slateJson,
        recipientAddress: decoded.senderAddress,
        encrypt: decoded.senderAddress != null,
        wallet: handle,
      );

      return ReceiveResult(
        success: true,
        slateId: received.slateId,
        commitId: received.commitId,
        responseSlatepack: encoded.slatepack,
        wasEncrypted: encoded.wasEncrypted,
        recipientAddress: decoded.senderAddress,
      );
    } catch (e, s) {
      Logging.instance.e('Failed to receive slatepack: $e\n$s');
      return ReceiveResult(success: false, error: e.toString());
    }
  }

  /// Finalize a slatepack (sender step 3).
  Future<FinalizeResult> finalizeSlatepack(String slatepack) async {
    try {
      final handle = await _ensureWalletOpen();

      // Decode to get slate JSON.
      final decoded = await mimblewimblecoin.Libmwc.decodeSlatepackWithWallet(
        wallet: handle,
        slatepack: slatepack,
      );

      // Finalize transaction.
      final finalized = await mimblewimblecoin.Libmwc.txFinalize(
        wallet: handle,
        slateJson: decoded.slateJson,
      );

      return FinalizeResult(
        success: true,
        slateId: finalized.slateId,
        commitId: finalized.commitId,
      );
    } catch (e, s) {
      Logging.instance.e('Failed to finalize slatepack: $e\n$s');
      return FinalizeResult(success: false, error: e.toString());
    }
  }

  /// Start MWCMQS listener for automatic transaction processing.
  Future<void> startSlatepackListener() async {
    try {
      await _ensureWalletOpen();
      final mwcmqsConfig = await getMwcMqsConfig();
      final wallet = await secureStorageInterface.read(
        key: '${walletId}_wallet',
      );
      mimblewimblecoin.Libmwc.startMwcMqsListener(
        wallet: wallet!,
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
      mimblewimblecoin.Libmwc.stopMwcMqsListener();
    } catch (e, s) {
      Logging.instance.e('Failed to stop slatepack listener: $e\n$s');
    }
  }

  /// Validate MWC address.
  bool validateMwcAddress(String address) {
    return mimblewimblecoin.Libmwc.validateSendAddress(address: address);
  }

  /// Detect if an address is a slatepack.
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

  /// Detect if an address is HTTP format.
  bool isHttpAddress(String address) {
    return address.startsWith('http://') || address.startsWith('https://');
  }

  /// Analyze a slatepack and determine transaction type and metadata.
  /// Returns a record with transaction type and slate information.
  Future<
    ({
      String type,
      String status,
      String? amount,
      bool wasEncrypted,
      String? senderAddress,
      String? recipientAddress,
      String slateId,
    })
  >
  analyzeSlatepack(String slatepack) async {
    try {
      // Get wallet handle if available
      final wallet = await secureStorageInterface.read(
        key: '${walletId}_wallet',
      );

      // Decode the slatepack
      final decoded =
          wallet != null
              ? await mimblewimblecoin.Libmwc.decodeSlatepackWithWallet(
                wallet: wallet,
                slatepack: slatepack,
              )
              : await mimblewimblecoin.Libmwc.decodeSlatepack(
                slatepack: slatepack,
              );

      // Parse the slate JSON to extract metadata
      final slateData = jsonDecode(decoded.slateJson);
      final String slateId = "${slateData['id'] ?? ''}";
      final String? amountStr = slateData['amount']?.toString();

      Logging.instance.d('Analyzed slatepack with ID: $slateId');

      // Determine slate status from the slate structure
      String status = 'Unknown';
      String type = 'Unknown';

      // Check participant data to determine slate status
      final List<dynamic>? participants =
          slateData['participant_data'] as List<dynamic>?;
      if (participants != null && participants.isNotEmpty) {
        // Count how many participants have signatures
        int signedParticipants = 0;
        for (final participant in participants) {
          if (participant['part_sig'] != null) {
            signedParticipants++;
          }
        }

        // Determine status based on signatures and participant count
        if (signedParticipants == 0) {
          status = 'S1';
          type = 'Outgoing'; // Initial send slate - this is outgoing
        } else if (signedParticipants == 1) {
          status = 'S2';
          type = 'Incoming'; // Response slate - this means we're receiving
        } else if (signedParticipants >= participants.length) {
          status = 'S3';
          type = 'Outgoing'; // Finalized slate - completed outgoing transaction
        }
      }

      // Fallback: check for explicit 'sta' field (some slates may have this)
      if (status == 'Unknown' && slateData['sta'] != null) {
        status = "${slateData['sta']}";
        if (status == 'S1') {
          type = 'Outgoing';
        } else if (status == 'S2') {
          type = 'Incoming';
        } else if (status == 'S3') {
          type = 'Outgoing';
        }
      }

      return (
        type: type,
        status: status,
        amount: amountStr,
        wasEncrypted: decoded.wasEncrypted,
        senderAddress: decoded.senderAddress,
        recipientAddress: decoded.recipientAddress,
        slateId: slateId,
      );
    } catch (e) {
      // If we can't decode it, return unknown
      return (
        type: 'Unknown',
        status: 'Unknown',
        amount: null,
        wasEncrypted: false,
        senderAddress: null,
        recipientAddress: null,
        slateId: '',
      );
    }
  }

  /// Improved transaction type detection for slatepacks.
  /// This replaces "Unknown" types with better determined types based on slate analysis.
  Future<String> getSlatepackTransactionType(String address) async {
    try {
      // Check if the address is actually a slatepack
      if (!isSlatepack(address)) {
        return 'Unknown';
      }

      // Analyze the slatepack to determine the actual transaction type
      final analysis = await analyzeSlatepack(address);

      // Map slate status to meaningful transaction types
      switch (analysis.status) {
        case 'S1':
          return 'Outgoing'; // Initial send slate - this is outgoing
        case 'S2':
          return 'Incoming'; // Response slate - this means we're receiving
        case 'S3':
          return 'Outgoing'; // Finalized slate - completed outgoing transaction
        default:
          return analysis.type; // Fall back to our basic analysis
      }
    } catch (e) {
      // If analysis fails, return Unknown
      return 'Unknown';
    }
  }

  /// Enhanced transaction type detection that can analyze slatepack transactions.
  /// Use this method to improve "Unknown" transaction types after they're loaded.
  Future<TransactionType> getEnhancedTransactionType(
    TransactionV2 transaction,
  ) async {
    try {
      // If transaction is already properly typed, return as-is
      if (transaction.type != TransactionType.unknown) {
        return transaction.type;
      }

      // Check if this is a MWC transaction with slatepack data
      if (transaction.isMimblewimblecoinTransaction) {
        // Try to analyze any slatepack addresses in the transaction
        for (final output in transaction.outputs) {
          for (final address in output.addresses) {
            if (isSlatepack(address)) {
              final slatepackType = await getSlatepackTransactionType(address);
              switch (slatepackType) {
                case 'Outgoing':
                  return TransactionType.outgoing;
                case 'Incoming':
                  return TransactionType.incoming;
                default:
                  continue;
              }
            }
          }
        }
      }

      // If we can't determine a better type, return unknown
      return TransactionType.unknown;
    } catch (e) {
      Logging.instance.w("Failed to enhance transaction type: $e");
      return transaction.type;
    }
  }

  // ================= Private =================================================

  Future<String> _getConfig() async {
    if (_mimblewimblecoinNode == null) {
      await updateNode();
    }
    final NodeModel node = _mimblewimblecoinNode!;
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
    final String stringConfig = jsonEncode(config);
    return stringConfig;
  }

  Future<String> _currentWalletDirPath() async {
    final Directory appDir = await StackFileSystem.applicationRootDirectory();

    final path = "${appDir.path}/mimblewimblecoin";
    final String name = walletId.trim();
    return '$path/$name';
  }

  Future<int> _nativeFee(
    int satoshiAmount, {
    bool ifErrorEstimateFee = false,
  }) async {
    final wallet = await secureStorageInterface.read(key: '${walletId}_wallet');
    try {
      final available = info.cachedBalance.spendable.raw.toInt();
      final transactionFees = await mimblewimblecoin.Libmwc.getTransactionFees(
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
        debugPrint("$e $s");
      }
      return realFee;
    } catch (e, s) {
      Logging.instance.e("Error getting fees $e - $s");
      rethrow;
    }
  }

  Future<void> _startSync() async {
    Logging.instance.i("request start sync");
    final wallet = await secureStorageInterface.read(key: '${walletId}_wallet');
    const int refreshFromNode = 1;
    if (!syncMutex.isLocked) {
      await syncMutex.protect(() async {
        // How does getWalletBalances start syncing????
        await mimblewimblecoin.Libmwc.getWalletBalances(
          wallet: wallet!,
          refreshFromNode: refreshFromNode,
          minimumConfirmations: 10,
        );
      });
    } else {
      Logging.instance.i("request start sync denied");
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
    final wallet = await secureStorageInterface.read(key: '${walletId}_wallet');
    const refreshFromNode = 0;
    return await mimblewimblecoin.Libmwc.getWalletBalances(
      wallet: wallet!,
      refreshFromNode: refreshFromNode,
      minimumConfirmations: cryptoCurrency.minConfirms,
    );
  }

  Future<bool> _putSendToAddresses(
    ({String slateId, String commitId}) slateData,
    Map<String, String> txAddressInfo,
  ) async {
    try {
      final slatesToCommits = info.mimblewimblecoinData?.slatesToCommits ?? {};
      final from = txAddressInfo['from'];
      final to = txAddressInfo['to'];
      slatesToCommits[slateData.slateId] = {
        "commitId": slateData.commitId,
        "from": from,
        "to": to,
      };
      await info.updateExtraMimblewimblecoinWalletInfo(
        mimblewimblecoinData: info.mimblewimblecoinData!.copyWith(
          slatesToCommits: slatesToCommits,
        ),
        isar: mainDB.isar,
      );
      return true;
    } catch (e, s) {
      Logging.instance.e("ERROR STORING ADDRESS $e $s");
      return false;
    }
  }

  Future<int> _getCurrentIndex() async {
    try {
      final int receivingIndex = info.mimblewimblecoinData!.receivingIndex;
      // TODO: go through pendingarray and processed array and choose the index
      //  of the last one that has not been processed, or the index after the one most recently processed;
      return receivingIndex;
    } catch (e, s) {
      Logging.instance.e("$e $s");
      return 0;
    }
  }

  Future<Address> _generateAndStoreReceivingAddressForIndex(int index) async {
    Address? address = await getCurrentReceivingAddress();

    if (address == null) {
      final mwcmqsConfig = await getMwcMqsConfig();
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
    final wallet = await secureStorageInterface.read(key: '${walletId}_wallet');

    final walletAddress = await mimblewimblecoin.Libmwc.getAddressInfo(
      wallet: wallet!,
      index: index,
    );

    Logging.instance.i("WALLET_ADDRESS_IS $walletAddress");

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
      mimblewimblecoin.Libmwc.stopMwcMqsListener();
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
      int lastScannedBlock = info.mimblewimblecoinData!.lastScannedBlock;

      // loop while scanning in chain in chunks (of blocks?)
      while (lastScannedBlock < chainHeight) {
        Logging.instance.i(
          "chainHeight: $chainHeight, lastScannedBlock: $lastScannedBlock",
        );

        final int nextScannedBlock = await mimblewimblecoin.Libmwc.scanOutputs(
          wallet: wallet!,
          startHeight: lastScannedBlock,
          numberOfBlocks: scanChunkSize,
        );

        // update local cache
        await info.updateExtraMimblewimblecoinWalletInfo(
          mimblewimblecoinData: info.mimblewimblecoinData!.copyWith(
            lastScannedBlock: nextScannedBlock,
          ),
          isar: mainDB.isar,
        );

        // force firing of scan progress event
        await getSyncPercent;

        // update while loop condition variables
        chainHeight = await this.chainHeight;
        lastScannedBlock = nextScannedBlock;
      }

      Logging.instance.i("_startScans successfully at the tip");
      //Once scanner completes restart listener
      await _listenToMwcmqs();
    } catch (e, s) {
      Logging.instance.e("_startScans failed: $e\n$s");
      rethrow;
    }
  }

  Future<void> _listenToMwcmqs() async {
    Logging.instance.i("STARTING WALLET LISTENER ....");
    final wallet = await secureStorageInterface.read(key: '${walletId}_wallet');
    final MwcMqsConfigModel mwcmqsConfig = await getMwcMqsConfig();
    mimblewimblecoin.Libmwc.startMwcMqsListener(
      wallet: wallet!,
      mwcmqsConfig: mwcmqsConfig.toString(),
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

  int _calculateRestoreHeightFrom({required DateTime date}) {
    final int secondsSinceEpoch = date.millisecondsSinceEpoch ~/ 1000;
    const int mimblewimblecoinFirstBlock = 1565370278;
    const double overestimateSecondsPerBlock = 61;
    final int chosenSeconds = secondsSinceEpoch - mimblewimblecoinFirstBlock;
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
        final MwcMqsConfigModel mwcmqsConfig = await getMwcMqsConfig();
        //if (!_logsInitialized) {
        //    await mimblewimblecoin.Libmwc.initLogs(config: stringConfig);
        //    _logsInitialized = true; // Set flag to true after initializing
        //  }
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

        await mimblewimblecoin.Libmwc.initializeNewWallet(
          config: stringConfig,
          mnemonic: mnemonicString,
          password: password,
          name: name,
        );

        //Open wallet
        encodedWallet = await mimblewimblecoin.Libmwc.openWallet(
          config: stringConfig,
          password: password,
        );
        await secureStorageInterface.write(
          key: '${walletId}_wallet',
          value: encodedWallet,
        );
        //Store MwcMqs address info
        await _generateAndStoreReceivingAddressForIndex(0);

        // subtract a couple days to ensure we have a buffer for SWB
        final bufferedCreateHeight = _calculateRestoreHeightFrom(
          date: DateTime.now().subtract(const Duration(days: 2)),
        );

        final mimblewimblecoinData = ExtraMimblewimblecoinWalletInfo(
          receivingIndex: 0,
          changeIndex: 0,
          slatesToAddresses: {},
          slatesToCommits: {},
          lastScannedBlock: bufferedCreateHeight,
          restoreHeight: bufferedCreateHeight,
          creationHeight: bufferedCreateHeight,
        );

        await info.updateExtraMimblewimblecoinWalletInfo(
          mimblewimblecoinData: mimblewimblecoinData,
          isar: mainDB.isar,
        );
      } else {
        try {
          final config = await _getRealConfig();
          //if (!_logsInitialized) {
          //  await mimblewimblecoin.Libmwc.initLogs(config: config);
          //  _logsInitialized = true; // Set flag to true after initializing
          //}
          final password = await secureStorageInterface.read(
            key: '${walletId}_password',
          );

          final walletOpen = await mimblewimblecoin.Libmwc.openWallet(
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
          Logging.instance.e("$runtimeType init() failed: $e\n$s");
        }
      }
    }

    return await super.init();
  }

  @override
  Future<TxData> confirmSend({required TxData txData}) async {
    try {
      final wallet = await secureStorageInterface.read(
        key: '${walletId}_wallet',
      );
      final MwcMqsConfigModel mwcmqsConfig = await getMwcMqsConfig();

      // TODO determine whether it is worth sending change to a change address.

      final String receiverAddress = txData.recipients!.first.address;

      //if (!receiverAddress.startsWith("http://") ||
      //    !receiverAddress.startsWith("https://")) {
      //  final bool isMwcmqsConnected = await _testMwcmqsServer(
      //    mwcmqsConfig,
      //  );
      //  if (!isMwcmqsConnected) {
      //    throw Exception(
      //        "Failed to send TX : Unable to reach mimblewimblecoin server");
      //  }
      //}

      ({String commitId, String slateId}) transaction;

      if (receiverAddress.startsWith("http://") ||
          receiverAddress.startsWith("https://")) {
        transaction = await mimblewimblecoin.Libmwc.txHttpSend(
          wallet: wallet!,
          selectionStrategyIsAll: 0,
          minimumConfirmations: cryptoCurrency.minConfirms,
          message: txData.noteOnChain ?? "",
          amount: txData.recipients!.first.amount.raw.toInt(),
          address: txData.recipients!.first.address,
        );
      } else if (receiverAddress.startsWith("mwcmqs://")) {
        transaction = await mimblewimblecoin.Libmwc.createTransaction(
          wallet: wallet!,
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

      final Map<String, String> txAddressInfo = {};
      txAddressInfo['from'] = (await getCurrentReceivingAddress())!.value;
      txAddressInfo['to'] = txData.recipients!.first.address;
      await _putSendToAddresses(transaction, txAddressInfo);

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

      // Check if this is a slatepack being provided instead of an address.
      if (isSlatepack(receiverAddress)) {
        // For slatepack input, we need different handling
        // This would be used for receiving/finalizing slatepacks.
        return txData.copyWith(
          fee: Amount.zeroWith(fractionDigits: cryptoCurrency.fractionDigits),
          otherData: jsonEncode({'isSlatepackInput': true}),
        );
      }

      // For regular address-based sends, calculate fee
      final int realFee = await _nativeFee(recipient.amount.raw.toInt());
      final feeAmount = Amount(
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

      // Determine transaction method based on address format.
      String txMethod = 'unknown';
      if (isMwcmqsAddress(receiverAddress)) {
        txMethod = 'mwcmqs';
      } else if (isHttpAddress(receiverAddress)) {
        txMethod = 'http';
      } else if (validateMwcAddress(receiverAddress)) {
        txMethod = 'slatepack'; // Manual slatepack exchange.
      }

      return txData.copyWith(
        recipients: [recipient],
        fee: feeAmount,
        otherData: jsonEncode({'transactionMethod': txMethod}),
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

          await info.updateExtraMimblewimblecoinWalletInfo(
            mimblewimblecoinData: info.mimblewimblecoinData!.copyWith(
              lastScannedBlock: info.mimblewimblecoinData!.restoreHeight,
            ),
            isar: mainDB.isar,
          );

          unawaited(_startScans());
        } else {
          await updateNode();
          final String password = generatePassword();

          final String stringConfig = await _getConfig();
          final MwcMqsConfigModel mwcmqsConfig = await getMwcMqsConfig();

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

          await mimblewimblecoin.Libmwc.recoverWallet(
            config: stringConfig,
            password: password,
            mnemonic: await getMnemonic(),
            name: info.walletId,
          );

          final mimblewimblecoinData = ExtraMimblewimblecoinWalletInfo(
            receivingIndex: 0,
            changeIndex: 0,
            slatesToAddresses: {},
            slatesToCommits: {},
            lastScannedBlock: info.restoreHeight,
            restoreHeight: info.restoreHeight,
            creationHeight:
                info.mimblewimblecoinData?.creationHeight ?? info.restoreHeight,
          );

          await info.updateExtraMimblewimblecoinWalletInfo(
            mimblewimblecoinData: mimblewimblecoinData,
            isar: mainDB.isar,
          );

          //Open Wallet
          final walletOpen = await mimblewimblecoin.Libmwc.openWallet(
            config: stringConfig,
            password: password,
          );
          await secureStorageInterface.write(
            key: '${walletId}_wallet',
            value: walletOpen,
          );

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
  Future<void> refresh() async {
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

      // if (info.epicData?.creationHeight == null) {
      //   await info.updateExtraEpiccashWalletInfo(epicData: inf, isar: isar)
      //   await epicUpdateCreationHeight(await chainHeight);
      // }

      // this will always be zero????
      final int curAdd = await _getCurrentIndex();
      await _generateAndStoreReceivingAddressForIndex(curAdd);

      await _startScans();

      unawaited(_startSync());

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
    } catch (error, strace) {
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
        "Caught exception in refreshWalletData(): $error\n$strace",
      );
    } finally {
      refreshMutex.release();
    }
  }

  @override
  Future<void> updateBalance() async {
    try {
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
      Logging.instance.e(
        "Mimblewimblecoin wallet failed to update balance: $e\n$s",
      );
    }
  }

  @override
  Future<void> updateTransactions() async {
    try {
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

      final transactions = await mimblewimblecoin.Libmwc.getTransactions(
        wallet: wallet!,
        refreshFromNode: refreshFromNode,
      );

      final List<TransactionV2> txns = [];

      final slatesToCommits = info.mimblewimblecoinData?.slatesToCommits ?? {};

      for (final tx in transactions) {
        Logging.instance.i("tx: $tx");

        final isIncoming =
            tx.txType == mimblewimblecoin_models.TransactionType.TxReceived ||
            tx.txType ==
                mimblewimblecoin_models.TransactionType.TxReceivedCancelled;
        final slateId = tx.txSlateId;
        final commitId = slatesToCommits[slateId]?['commitId'] as String?;
        final numberOfMessages = tx.messages?.messages.length;
        final onChainNote = tx.messages?.messages[0].message;
        final addressFrom = slatesToCommits[slateId]?["from"] as String?;
        final addressTo = slatesToCommits[slateId]?["to"] as String?;

        final credit = int.parse(tx.amountCredited);
        final debit = int.parse(tx.amountDebited);
        final fee = int.tryParse(tx.fee ?? "0") ?? 0;

        // hack Mimblewimblecoin tx data into inputs and outputs
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
          // For outgoing transactions, check if we have a slatepack address to analyze
          TransactionType determinedType = TransactionType.outgoing;

          // Try to get better type determination for slatepack transactions
          if (addressTo != null) {
            try {
              final slatepackType = await getSlatepackTransactionType(
                addressTo,
              );
              if (slatepackType == 'Incoming') {
                determinedType = TransactionType.incoming;
              } else if (slatepackType == 'Outgoing') {
                determinedType = TransactionType.outgoing;
              }
              // If slatepackType is 'Unknown', we keep the original outgoing type
            } catch (e) {
              // If analysis fails, keep original type determination
              Logging.instance.w(
                "Failed to analyze slatepack for better type detection: $e",
              );
            }
          }

          txType = determinedType;
        }

        outputs.add(output);
        inputs.add(input);

        final otherData = {
          "isMimblewimblecoinTransaction": true,
          "numberOfMessages": numberOfMessages,
          "slateId": slateId,
          "onChainNote": onChainNote,
          "isCancelled":
              tx.txType ==
                  mimblewimblecoin_models.TransactionType.TxSentCancelled ||
              tx.txType ==
                  mimblewimblecoin_models.TransactionType.TxReceivedCancelled,
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
      Logging.instance.w(
        "${cryptoCurrency.runtimeType} ${cryptoCurrency.network} net wallet"
        " \"${info.name}\"_${info.walletId} updateTransactions() failed: $e\n$s",
      );
    }
  }

  @override
  Future<bool> updateUTXOs() async {
    // not used for mimblewimblecoin
    return false;
  }

  @override
  Future<void> updateNode() async {
    _mimblewimblecoinNode = getCurrentNode();

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
      return await testMwcNodeConnection(
            NodeFormData()
              ..host = node!.host
              ..useSSL = node.useSSL
              ..port = node.port,
          ) !=
          null;
    } catch (e, s) {
      Logging.instance.i("$e\n$s");
      return false;
    }
  }

  @override
  Future<void> updateChainHeight() async {
    final config = await _getRealConfig();
    final latestHeight = await mimblewimblecoin.Libmwc.getChainHeight(
      config: config,
    );
    await info.updateCachedChainHeight(
      newHeight: latestHeight,
      isar: mainDB.isar,
    );
  }

  @override
  Future<Amount> estimateFeeFor(Amount amount, BigInt feeRate) async {
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
    timer?.cancel();
    timer = null;
    await super.exit();
    Logging.instance.i("Mimblewimblecoin_wallet exit finished");
  }
}

Future<String> deleteMimblewimblecoinWallet({
  required String walletId,
  required SecureStorageInterface secureStore,
}) async {
  final wallet = await secureStore.read(key: '${walletId}_wallet');
  String? config = await secureStore.read(key: '${walletId}_config');
  if (Platform.isIOS) {
    final Directory appDir = await StackFileSystem.applicationRootDirectory();

    final path = "${appDir.path}/mimblewimblecoin";
    final String name = walletId.trim();
    final walletDir = '$path/$name';

    final editConfig = jsonDecode(config as String);

    editConfig["wallet_dir"] = walletDir;
    config = jsonEncode(editConfig);
  }

  if (wallet == null) {
    return "Tried to delete non existent mimblewimblecoin wallet file with walletId=$walletId";
  } else {
    try {
      return mimblewimblecoin.Libmwc.deleteWallet(
        wallet: wallet,
        config: config!,
      );
    } catch (e, s) {
      Logging.instance.e("$e\n$s");
      return "deleteMimblewimblecoinWallet($walletId) failed...";
    }
  }
}

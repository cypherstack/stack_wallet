import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:decimal/decimal.dart';
import 'package:isar_community/isar.dart';
import 'package:mutex/mutex.dart';
import 'package:stack_wallet_backup/generate_password.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../../exceptions/main_db/main_db_exception.dart';
import '../../../exceptions/wallet/node_tor_mismatch_config_exception.dart';
import '../../../models/balance.dart';
import '../../../models/epic_slatepack_models.dart';
import '../../../models/epicbox_config_model.dart';
import '../../../models/isar/models/blockchain_data/address.dart';
import '../../../models/isar/models/blockchain_data/transaction.dart';
import '../../../models/isar/models/blockchain_data/v2/input_v2.dart';
import '../../../models/isar/models/blockchain_data/v2/output_v2.dart';
import '../../../models/isar/models/blockchain_data/v2/transaction_v2.dart';
import '../../../models/isar/models/transaction_note.dart';
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
import '../../../utilities/dynamic_object.dart';
import '../../../utilities/flutter_secure_storage_interface.dart';
import '../../../utilities/logger.dart';
import '../../../utilities/stack_file_system.dart';
import '../../../utilities/test_epic_box_connection.dart';
import '../../../utilities/tor_plain_net_option_enum.dart';
import '../../../wl_gen/interfaces/libepiccash_interface.dart';
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

  DynamicObject? _wallet;

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

  /// Opens and initializes the Epic wallet instance.
  /// Should only be called once during wallet initialization.
  // Future<void> open() async {
  //   if (_wallet != null) {
  //     Logging.instance.d("Wallet already open, ensuring listener");
  //     if (!await libEpic.isEpicboxListenerRunning(wallet: _wallet!)) {
  //       await _listenToEpicbox();
  //     }
  //     return;
  //   }
  //
  //   try {
  //     final config = await _getRealConfig();
  //     final password = await secureStorageInterface.read(
  //       key: '${walletId}_password',
  //     );
  //     if (password == null) {
  //       throw Exception('Wallet password not found');
  //     }
  //
  //     final epicboxConfig = await getEpicBoxConfig();
  //
  //     _wallet = await libEpic.openWallet(
  //       config: config,
  //       password: password,
  //       epicboxConfig: epicboxConfig.toString(),
  //     );
  //
  //     await _listenToEpicbox();
  //
  //     Logging.instance.d(
  //       "Epic wallet opened successfully with persistent isolate",
  //     );
  //   } catch (e, s) {
  //     Logging.instance.e("Failed to open Epic wallet", error: e, stackTrace: s);
  //     _wallet = null;
  //     rethrow;
  //   }
  // }

  Future<void> updateEpicboxConfig(String host, int port) async {
    final String stringConfig = jsonEncode({
      "epicbox_domain": host,
      "epicbox_port": port,
      "epicbox_protocol_unsecure": false,
      "epicbox_address_index": 0,
    });
    await secureStorageInterface.write(
      key: '${walletId}_epicboxConfigNewNewNew',
      value: stringConfig,
    );
    libEpic.updateEpicboxConfig(wallet: _wallet!, epicBoxConfig: stringConfig);

    await _generateAndStoreReceivingAddressForIndex(0);
    // TODO: refresh anything that needs to be refreshed/updated due to epicbox info changed
  }

  /// returns an empty String on success, error message on failure
  Future<String> cancelPendingTransactionAndPost(String txSlateId) async {
    try {
      _hackedCheckTorNodePrefs();
      if (_wallet == null) {
        throw Exception('Wallet not initialized');
      }

      final result = await libEpic.cancelTransaction(
        wallet: _wallet!,
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
    // check for user-configured epicbox first
    final storedConfig = await secureStorageInterface.read(
      key: '${walletId}_epicboxConfigNewNewNew',
    );
    if (storedConfig != null && storedConfig.isNotEmpty) {
      try {
        return EpicBoxConfigModel.fromString(storedConfig);
      } catch (e, s) {
        Logging.instance.e(
          "Failed to parse stored epicbox config $storedConfig."
          " Falling back to default.",
          error: e,
          stackTrace: s,
        );
      }
    } else {
      Logging.instance.i("No stored epic box config. Falling back to default.");
    }

    // fall back to default
    return EpicBoxConfigModel.fromServer(DefaultEpicBoxes.defaultEpicBoxServer);
  }

  Future<void> updateRestoreHeight(int height) async {
    final epicData = info.epicData!.copyWith(restoreHeight: height);

    await info.updateExtraEpiccashWalletInfo(
      epicData: epicData,
      isar: mainDB.isar,
    );
  }

  // ================= Slatepack Operations ===================================

  /// Create a slatepack for sending Epic Cash.
  Future<EpicSlatepackResult> createSlatepack({
    required Amount amount,
    String? recipientAddress,
    String? message,
    int? minimumConfirmations,
  }) async {
    try {
      _hackedCheckTorNodePrefs();
      if (_wallet == null) {
        throw Exception('Wallet not opened. Call open() first.');
      }
      // Create transaction with returnSlate: true for slatepack mode.
      final result = await libEpic.createTransaction(
        wallet: _wallet!,
        amount: amount.raw.toInt(),
        address: 'slate', // Not used in slate mode.
        secretKeyIndex: 0,
        minimumConfirmations:
            minimumConfirmations ?? cryptoCurrency.minConfirms,
        note: message ?? '',
        returnSlate: true,
      );

      return EpicSlatepackResult(
        success: true,
        slatepack: result.slateJson,
        slateJson: result.slateJson,
        wasEncrypted: false,
        recipientAddress: recipientAddress,
      );
    } catch (e, s) {
      Logging.instance.e('Failed to create slatepack: $e\n$s');
      return EpicSlatepackResult(success: false, error: e.toString());
    }
  }

  /// Decode a slatepack/slate JSON.
  Future<EpicSlatepackDecodeResult> decodeSlatepack(String slateJson) async {
    try {
      // For Epic Cash, slates are already JSON, so we parse directly.
      // Validate that the JSON is valid.
      jsonDecode(slateJson);

      return EpicSlatepackDecodeResult(
        success: true,
        slateJson: slateJson,
        wasEncrypted: false,
        senderAddress: null,
        recipientAddress: null,
      );
    } catch (e, s) {
      Logging.instance.e('Failed to decode slatepack: $e\n$s');
      return EpicSlatepackDecodeResult(success: false, error: e.toString());
    }
  }

  /// Full decode of a slatepack including type analysis.
  Future<({EpicSlatepackDecodeResult result, String type, String raw})?>
  fullDecodeSlatepack(String slateJson) async {
    // Add delay for showloading exception catching hack fix.
    await Future<void>.delayed(const Duration(seconds: 1));

    if (slateJson.isEmpty) {
      return null;
    }

    // Attempt to decode.
    final decoded = await decodeSlatepack(slateJson);

    if (decoded.success) {
      final analysis = await analyzeSlatepack(slateJson);

      final String slatepackType = switch (analysis.status) {
        'S1' => "S1 (Initial Send)",
        'S2' => "S2 (Response)",
        'S3' => "S3 (Finalized)",
        _ => "Unknown",
      };

      return (result: decoded, type: slatepackType, raw: slateJson);
    } else {
      throw Exception(decoded.error ?? "Failed to decode slatepack");
    }
  }

  /// Receive a slatepack and return response slate JSON.
  Future<EpicReceiveResult> receiveSlatepack(String slateJson) async {
    try {
      _hackedCheckTorNodePrefs();
      if (_wallet == null) {
        throw Exception('Wallet not opened. Call open() first.');
      }

      // Receive and get updated slate JSON.
      final received = await libEpic.txReceive(
        wallet: _wallet!,
        slateJson: slateJson,
      );

      return EpicReceiveResult(
        success: true,
        slateId: received.slateId,
        commitId: received.commitId,
        responseSlatepack: received.slateJson,
        wasEncrypted: false,
        recipientAddress: null,
      );
    } catch (e, s) {
      Logging.instance.e('Failed to receive slatepack: $e\n$s');
      return EpicReceiveResult(success: false, error: e.toString());
    }
  }

  /// Finalize a slatepack (sender step 3).
  Future<EpicFinalizeResult> finalizeSlatepack(String slateJson) async {
    try {
      _hackedCheckTorNodePrefs();
      if (_wallet == null) {
        throw Exception('Wallet not opened. Call open() first.');
      }

      // Finalize transaction.
      final finalized = await libEpic.txFinalize(
        wallet: _wallet!,
        slateJson: slateJson,
      );

      return EpicFinalizeResult(
        success: true,
        slateId: finalized.slateId,
        commitId: finalized.commitId,
      );
    } catch (e, s) {
      Logging.instance.e('Failed to finalize slatepack: $e\n$s');
      return EpicFinalizeResult(success: false, error: e.toString());
    }
  }

  /// Analyze a slatepack and determine transaction type and metadata.
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
  analyzeSlatepack(String slateJson) async {
    try {
      // Parse the slate JSON to extract metadata.
      final slateData = jsonDecode(slateJson);
      final String slateId = "${slateData['id'] ?? ''}";
      final String? amountStr = slateData['amount']?.toString();

      Logging.instance.d('Analyzed slatepack with ID: $slateId');

      // Determine slate status from the slate structure.
      String status = 'Unknown';
      String type = 'Unknown';

      // Check participant data to determine slate status.
      final List<dynamic>? participants =
          slateData['participant_data'] as List<dynamic>?;
      if (participants != null && participants.isNotEmpty) {
        // Count how many participants have signatures.
        int signedParticipants = 0;
        for (final participant in participants) {
          if (participant['part_sig'] != null) {
            signedParticipants++;
          }
        }

        // Determine status based on signatures and participant count.
        if (signedParticipants == 0) {
          status = 'S1';
          type = 'Outgoing'; // Initial send slate - this is outgoing.
        } else if (signedParticipants == 1) {
          status = 'S2';
          type = 'Incoming'; // Response slate - this means we're receiving.
        } else if (signedParticipants >= participants.length) {
          status = 'S3';
          type =
              'Outgoing'; // Finalized slate - completed outgoing transaction.
        }
      }

      // Fallback: check for explicit 'sta' field (some slates may have this).
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
        wasEncrypted: false,
        senderAddress: null,
        recipientAddress: null,
        slateId: slateId,
      );
    } catch (e) {
      // If we can't decode it, return unknown.
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

  /// Check if data is a slate JSON.
  bool isSlateJson(String data) {
    try {
      final parsed = jsonDecode(data);
      // Check for common slate fields.
      return parsed is Map &&
          (parsed.containsKey('id') || parsed.containsKey('slate_id')) &&
          (parsed.containsKey('amount') ||
              parsed.containsKey('participant_data'));
    } catch (e) {
      return false;
    }
  }

  /// Check if address is Epicbox format.
  bool isEpicboxAddress(String address) {
    return address.contains('@');
  }

  /// Check if address is HTTP format.
  bool isHttpAddress(String address) {
    return address.startsWith('http://') || address.startsWith('https://');
  }

  // ================= Private =================================================

  Future<bool> _hasConfig() async =>
      (await secureStorageInterface.read(key: '${walletId}_config')) != null;

  Future<String> _buildConfig() async {
    _epicNode ??= getCurrentNode();

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
    if (_wallet == null) {
      throw Exception('Wallet not opened. Call open() first.');
    }
    try {
      _hackedCheckTorNodePrefs();

      final transactionFees = await libEpic.getTransactionFees(
        wallet: _wallet!,
        amount: satoshiAmount,
        minimumConfirmations: cryptoCurrency.minConfirms,
      );

      int realFee = 0;
      try {
        realFee = (Decimal.parse(
          transactionFees.fee.toString(),
        )).toBigInt().toInt();
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
    if (_wallet == null) {
      throw Exception('Wallet not opened. Call open() first.');
    }
    const int refreshFromNode = 1;
    if (!syncMutex.isLocked) {
      await syncMutex.protect(() async {
        // How does getWalletBalances start syncing?????????!!!!!
        await libEpic.getWalletBalances(
          wallet: _wallet!,
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
    if (_wallet == null) {
      throw Exception('Wallet not opened. Call open() first.');
    }
    const refreshFromNode = 0;
    return (await libEpic.getWalletBalances(
      wallet: _wallet!,
      refreshFromNode: refreshFromNode,
      minimumConfirmations: cryptoCurrency.minConfirms,
    ));
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
        "_testEpicboxServer failed on \"$host:$port\"",
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
      //  of the last one that has not been processed, or the index after the
      //  one most recently processed;
      return receivingIndex;
    } catch (e, s) {
      Logging.instance.e("$e $s", error: e, stackTrace: s);
      return 0;
    }
  }

  Future<void> _updateAddressInDB(Address address) async {
    try {
      final storedAddress = await getCurrentReceivingAddress();
      await mainDB.isar.writeTxn(() async {
        if (storedAddress == null) {
          await mainDB.isar.addresses.put(address);
        } else {
          address.id = storedAddress.id;
          await storedAddress.transactions.load();
          final txns = storedAddress.transactions.toList();
          await mainDB.isar.addresses.delete(storedAddress.id);
          await mainDB.isar.addresses.put(address);
          address.transactions.addAll(txns);
          await address.transactions.save();
        }
      });
    } catch (e) {
      throw MainDBException("failed _updateAddressInDB: $address", e);
    }
  }

  /// Only index 0 is currently used in stack wallet.
  Future<Address> _generateAndStoreReceivingAddressForIndex(int index) async {
    if (_wallet == null) {
      throw Exception('Wallet not opened. Call open() first.');
    }

    // Since only 0 is a valid index in stack wallet at this time, lets just
    // throw is not zero
    if (index != 0) {
      throw Exception("Invalid/unexpected address index used");
    }

    final epicBoxConfig = await getEpicBoxConfig();
    final walletAddress = await libEpic.getAddressInfo(
      wallet: _wallet!,
      index: index,
      epicboxConfig: epicBoxConfig.toString(),
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
    await _updateAddressInDB(address);
    if (info.cachedReceivingAddress != address.value) {
      await info.updateReceivingAddress(
        newAddress: address.value,
        isar: mainDB.isar,
      );
    }

    return address;
  }

  Future<void> _startScans() async {
    try {
      // max number of blocks to scan per loop iteration
      const scanChunkSize = 10000;

      // force firing of scan progress event
      await getSyncPercent;

      // fetch current chain height and last scanned block (should be the
      // restore height if full rescan or a wallet restore)
      int chainHeight = await this.chainHeight;
      int lastScannedBlock = info.epicData!.lastScannedBlock;

      // Only stop the listener if we actually have blocks to scan.
      // This avoids unnecessary reconnections during periodic refresh
      // when the wallet is already synced to the tip.
      final needsScanning = lastScannedBlock < chainHeight;
      if (needsScanning) {
        // Stop listener during active scanning to avoid potential conflicts
        await libEpic.stopEpicboxListener(wallet: _wallet!);
      }

      // loop while scanning in chain in chunks (of blocks?)
      while (lastScannedBlock < chainHeight) {
        Logging.instance.d(
          "chainHeight: $chainHeight, lastScannedBlock: $lastScannedBlock",
        );

        final int nextScannedBlock = await libEpic.scanOutputs(
          wallet: _wallet!,
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

      // Ensure listener is running after refresh.
      // Use health check to verify the Rust listener task is actually alive,
      // not just that we have a pointer (which could be stale).
      if (!await libEpic.isEpicboxListenerRunning(wallet: _wallet!)) {
        Logging.instance.d("Listener not running, starting it...");
        await _listenToEpicbox();
      } else {
        Logging.instance.d("Listener already running, no restart needed");
      }
    } catch (e, s) {
      Logging.instance.e("_startScans failed: ", error: e, stackTrace: s);
      rethrow;
    }
  }

  Future<void> _listenToEpicbox() async {
    Logging.instance.d("STARTING WALLET LISTENER ....");
    final EpicBoxConfigModel epicboxConfig = await getEpicBoxConfig();
    if (_wallet == null) {
      throw Exception('Wallet not opened. Call open() first.');
    }
    libEpic.updateEpicboxConfig(
      wallet: _wallet!,
      epicBoxConfig: epicboxConfig.toString(),
    );
    await libEpic.startEpicboxListener(wallet: _wallet!);
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

  static const _mid = "_:'", _end = "':";

  /// eeehhhhhhhhhhhhhhh
  bool _fuzzyEquals(TransactionV2 a, TransactionV2 b) {
    final isAmountReceivedMatches =
        a.getAmountReceivedInThisWallet(
          fractionDigits: cryptoCurrency.fractionDigits,
        ) ==
        b.getAmountReceivedInThisWallet(
          fractionDigits: cryptoCurrency.fractionDigits,
        );

    final isFeeMatches =
        a.getFee(fractionDigits: cryptoCurrency.fractionDigits) ==
        b.getFee(fractionDigits: cryptoCurrency.fractionDigits);

    final isAmountSentMatches =
        a.getAmountSentFromThisWallet(
          fractionDigits: cryptoCurrency.fractionDigits,
          subtractFee: false,
        ) ==
        b.getAmountSentFromThisWallet(
          fractionDigits: cryptoCurrency.fractionDigits,
          subtractFee: false,
        );

    final isHeightMatches = a.height == b.height;
    final isTxTypeMatches = a.type == b.type && a.subType == b.subType;
    final isSlateIdMatches = a.slateId == b.slateId;

    if (isHeightMatches &&
        isTxTypeMatches &&
        isFeeMatches &&
        isSlateIdMatches &&
        isAmountSentMatches &&
        isAmountReceivedMatches) {
      return true;
    }

    return false;
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
      final existingWalletConfig = await _hasConfig();

      // check if should create a new wallet
      if (!existingWalletConfig) {
        await updateNode();
        final mnemonicString = await getMnemonic();

        final String password = generatePassword();
        final EpicBoxConfigModel epicboxConfig = await getEpicBoxConfig();

        final String stringConfig = await _buildConfig();

        // no need to save the config, just a string flag to know we have a
        // wallet created
        await secureStorageInterface.write(
          key: '${walletId}_config',
          value: "true",
        );

        await secureStorageInterface.write(
          key: '${walletId}_password',
          value: password,
        );
        await secureStorageInterface.write(
          key: '${walletId}_epicboxConfigNewNewNew',
          value: epicboxConfig.toString(),
        );

        final String name = walletId;

        _wallet = await libEpic.initializeNewWallet(
          config: stringConfig,
          mnemonic: mnemonicString,
          password: password,
          name: name,
          epicBoxConfig: epicboxConfig.toString(),
        ); // Spawns worker isolate

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

        await _listenToEpicbox();
      } else {
        try {
          Logging.instance.d(
            "initializeExisting() ${cryptoCurrency.prettyName} wallet",
          );

          final password = await secureStorageInterface.read(
            key: '${walletId}_password',
          );
          final epicboxConfig = await getEpicBoxConfig();

          _wallet = await libEpic.openWallet(
            config: await _buildConfig(),
            password: password!,
            epicboxConfig: epicboxConfig.toString(),
          ); // Spawns worker isolate

          await updateNode();

          // ensure address  is up to date with epic box uri
          await _generateAndStoreReceivingAddressForIndex(0);

          await _listenToEpicbox();
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

      ({String commitId, String slateId, String slateJson}) transaction;

      if (receiverAddress.startsWith("http://") ||
          receiverAddress.startsWith("https://")) {
        final httpResult = await libEpic.txHttpSend(
          wallet: _wallet!,
          selectionStrategyIsAll: 0,
          minimumConfirmations: cryptoCurrency.minConfirms,
          message: txData.noteOnChain ?? "",
          amount: txData.recipients!.first.amount.raw.toInt(),
          address: txData.recipients!.first.address,
        );
        transaction = (
          commitId: httpResult.commitId,
          slateId: httpResult.slateId,
          slateJson: '',
        );
      } else {
        transaction = (await libEpic.createTransaction(
          wallet: _wallet!,
          amount: txData.recipients!.first.amount.raw.toInt(),
          address: txData.recipients!.first.address,
          secretKeyIndex: 0,
          minimumConfirmations: cryptoCurrency.minConfirms,
          note: txData.noteOnChain!,
        ));
      }

      final Map<String, String> txAddressInfo = {};
      txAddressInfo['from'] = (await getCurrentReceivingAddress())!.value;
      txAddressInfo['to'] = txData.recipients!.first.address;
      await _putSendToAddresses((
        commitId: transaction.commitId,
        slateId: transaction.slateId,
      ), txAddressInfo);

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

      TxRecipient recipient = txData.recipients!.first;

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
        recipient = recipient.copyWith(amount: recipient.amount - feeAmount);
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
          // keep old transactions but id them somehow
          // with the current db, there is no other way besides editing the
          // unique key (txid+walletId). Since we cannot change the wallet id we
          // must therefore hack some stupid stuff into the txid...
          final currentTxns1 = await mainDB.isar.transactionV2s
              .where()
              .walletIdEqualTo(walletId)
              .findAll();

          final List<TransactionV2> currentTxns = [];

          for (final current in currentTxns1) {
            if (currentTxns.where((e) => _fuzzyEquals(e, current)).isNotEmpty) {
              Logging.instance.f("DELETING: $current");
              await mainDB.isar.writeTxn(() async {
                await mainDB.isar.transactionV2s.delete(current.id);
              });
            } else {
              currentTxns.add(current);
            }
          }

          for (final current in currentTxns) {
            // check notes first
            final note = await mainDB.isar.transactionNotes
                .where()
                .txidWalletIdEqualTo(current.slateId ?? current.txid, walletId)
                .findFirst();

            // now handle transaction
            final firstTime =
                !(current.txid.contains(_mid) && current.txid.endsWith(_end));

            final String txid;
            if (firstTime) {
              txid = "${current.txid}${_mid}0$_end";
            } else {
              // this should always be 2 parts if we've gotten this far
              final parts = current.txid.split(_mid);
              final rescanCount =
                  int.parse(parts.last.replaceFirst(_end, "")) + 1;
              txid = "${parts.first}$_mid$rescanCount$_end";
            }

            // finally update in db
            await mainDB.isar.writeTxn(() async {
              final updated = current.copyWith(txid: txid);
              if (note != null) {
                final updatedNote = TransactionNote(
                  walletId: walletId,
                  txid: current.slateId ?? txid,
                  value: note.value,
                );
                await mainDB.isar.transactionNotes.delete(note.id);
                await mainDB.isar.transactionNotes.put(updatedNote);
              }

              await mainDB.isar.transactionV2s.delete(current.id);
              await mainDB.isar.transactionV2s.put(updated);
            });
          }

          await info.updateExtraEpiccashWalletInfo(
            epicData: info.epicData!.copyWith(
              lastScannedBlock: info.epicData!.restoreHeight,
            ),
            isar: mainDB.isar,
          );

          final password = await secureStorageInterface.read(
            key: '${walletId}_password',
          );
          final epicboxConfig = await getEpicBoxConfig();

          // maybe there is some way to tel epic-wallet rust to fully rescan...
          final result = await deleteEpicWallet(
            wallet: this,
            secureStore: secureStorageInterface,
          );
          Logging.instance.w("Epic rescan temporary delete result: $result");

          // Close old wallet before recovery
          if (_wallet != null) {
            await libEpic.close(wallet: _wallet!);
            _wallet = null;
          }

          _wallet = await libEpic.recoverWallet(
            config: await _buildConfig(),
            password: password!,
            mnemonic: await getMnemonic(),
            name: info.walletId,
            epicBoxConfig: epicboxConfig.toString(),
          );

          await _generateAndStoreReceivingAddressForIndex(
            info.epicData?.receivingIndex ?? 0,
          );

          await _listenToEpicbox();

          highestPercent = 0;
        } else {
          await updateNode();
          final String password = generatePassword();

          final EpicBoxConfigModel epicboxConfig = await getEpicBoxConfig();

          // no need to save the config, just a string flag to know we have a
          // wallet created
          await secureStorageInterface.write(
            key: '${walletId}_config',
            value: "true",
          );
          await secureStorageInterface.write(
            key: '${walletId}_password',
            value: password,
          );

          await secureStorageInterface.write(
            key: '${walletId}_epicboxConfigNewNewNew',
            value: epicboxConfig.toString(),
          );

          // Close old wallet before recovery
          if (_wallet != null) {
            await libEpic.close(wallet: _wallet!);
            _wallet = null;
          }

          _wallet = await libEpic.recoverWallet(
            config: await _buildConfig(),
            password: password,
            mnemonic: await getMnemonic(),
            name: info.walletId,
            epicBoxConfig: epicboxConfig.toString(),
          );

          await _listenToEpicbox();

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

          await _generateAndStoreReceivingAddressForIndex(
            epicData.receivingIndex,
          );
        }
      });

      unawaited(refresh(doScan: isRescan));
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

      if (_wallet == null) {
        throw Exception('Wallet not opened. Call open() first.');
      }

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

          // TODO: [prio=med] some kind of quick check if wallet needs to
          //  refresh to replace the old refreshIfThereIsNewData call
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
      const refreshFromNode = 1;

      final myAddresses = await mainDB
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

      final transactions = await libEpic.getTransactions(
        wallet: _wallet!,
        refreshFromNode: refreshFromNode,
      );

      final List<TransactionV2> txns = [];

      final slatesToCommits = info.epicData?.slatesToCommits ?? {};

      for (final tx in transactions) {
        final isIncoming =
            libEpic.txTypeIsReceived(tx.txType) ||
            libEpic.txTypeIsReceiveCancelled(tx.txType);
        final slateId = tx.txSlateId;
        final commitId = slatesToCommits[slateId]?['commitId'] as String?;
        final numberOfMessages = tx.messages?.length;
        final onChainNote = tx.messages?.first.message;
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
          addresses: [if (addressTo != null) addressTo],
          walletOwns: true,
        );
        final InputV2 input = InputV2.isarCantDoRequiredInDefaultConstructor(
          scriptSigHex: null,
          scriptSigAsm: null,
          sequence: null,
          outpoint: null,
          addresses: [if (addressFrom != null) addressFrom],
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
                  .first, // Must be changed if we ever do more than a single
              // wallet address!!!
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
              libEpic.txTypeIsSentCancelled(tx.txType) ||
              libEpic.txTypeIsReceiveCancelled(tx.txType),
          "overrideFee": Amount(
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

        if (txns.where((e) => _fuzzyEquals(e, txn)).isEmpty) {
          txns.add(txn);
        }
      }

      final existingTxns = await mainDB.isar.transactionV2s
          .where()
          .walletIdEqualTo(walletId)
          .findAll();

      await mainDB.isar.writeTxn(() async {
        for (final tx in txns) {
          final existingMatches = existingTxns.where(
            (e) => _fuzzyEquals(e, tx),
          );
          TransactionNote? note;
          if (existingMatches.isNotEmpty) {
            // there should only ever be one. If more then something is\
            // wrong somewhere, probably
            if (existingMatches.length > 1) {
              Logging.instance.w(
                "existingMatches length: ${existingMatches.length}",
              );
            }
            for (final match in existingMatches) {
              if (await mainDB.isar.transactionV2s
                      .where()
                      .txidWalletIdEqualTo(match.txid, walletId)
                      .idProperty()
                      .findFirst() !=
                  null) {
                note = await mainDB.isar.transactionNotes
                    .where()
                    .txidWalletIdEqualTo(match.slateId ?? match.txid, walletId)
                    .findFirst();

                await mainDB.isar.transactionV2s.delete(match.id);
              }
            }
          }

          final id = await mainDB.isar.transactionV2s
              .where()
              .txidWalletIdEqualTo(tx.txid, walletId)
              .idProperty()
              .findFirst();

          if (id != null) {
            await mainDB.isar.transactionV2s.delete(id);
          }

          if (note != null) {
            await mainDB.isar.transactionNotes.delete(note.id);
            await mainDB.isar.transactionNotes.put(
              TransactionNote(
                walletId: walletId,
                txid: tx.slateId ?? tx.txid,
                value: note.value,
              ),
            );
          }

          await mainDB.isar.transactionV2s.put(tx);
        }
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

    if (_wallet != null) {
      libEpic.updateConfig(wallet: _wallet!, config: await _buildConfig());
    }

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
    final config = await _buildConfig();
    final latestHeight = await libEpic.getChainHeight(config: config);
    await info.updateCachedChainHeight(
      newHeight: latestHeight,
      isar: mainDB.isar,
    );
  }

  @override
  Future<Amount> estimateFeeFor(Amount amount, BigInt feeRate) async {
    _hackedCheckTorNodePrefs();
    // setting ifErrorEstimateFee doesn't do anything as its not used in the
    // nativeFee function?????
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
    if (_wallet != null) await libEpic.stopEpicboxListener(wallet: _wallet!);
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
  required EpiccashWallet wallet,
  required SecureStorageInterface secureStore,
}) async {
  final config = await wallet._hasConfig() ? await wallet._buildConfig() : null;

  if (config == null) {
    return "Tried to delete non existent epic wallet file with"
        " walletId=${wallet.walletId}";
  } else {
    try {
      if (wallet._wallet != null) await libEpic.close(wallet: wallet._wallet!);
      return libEpic.deleteWallet(config: config);
    } catch (e, s) {
      Logging.instance.e("$e\n$s", error: e, stackTrace: s);
      return "deleteEpicWallet(${wallet.walletId}) failed...";
    }
  }
}

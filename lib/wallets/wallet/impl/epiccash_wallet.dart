import 'dart:async';
import 'dart:convert';

import 'package:decimal/decimal.dart';
import 'package:flutter/foundation.dart';
import 'package:isar_community/isar.dart';
import 'package:stack_wallet_backup/generate_password.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../../exceptions/main_db/main_db_exception.dart';
import '../../../exceptions/wallet/node_tor_mismatch_config_exception.dart';
import '../../../models/epicbox_config_model.dart';
import '../../../models/isar/models/blockchain_data/address.dart';
import '../../../models/isar/models/blockchain_data/transaction.dart';
import '../../../models/isar/models/blockchain_data/v2/input_v2.dart';
import '../../../models/isar/models/blockchain_data/v2/output_v2.dart';
import '../../../models/isar/models/blockchain_data/v2/transaction_v2.dart';
import '../../../models/isar/models/transaction_note.dart';
import '../../../models/node_model.dart';
import '../../../models/slatepack_models.dart';
import '../../../pages/settings_views/global_settings_view/manage_nodes_views/add_edit_node_view.dart';
import '../../../utilities/amount/amount.dart';
import '../../../utilities/default_epicboxes.dart';
import '../../../utilities/dynamic_object.dart';
import '../../../utilities/enums/slatepack_method.dart';
import '../../../utilities/flutter_secure_storage_interface.dart';
import '../../../utilities/logger.dart';
import '../../../utilities/slatepack_terms.dart';
import '../../../utilities/test_epic_box_connection.dart';
import '../../../utilities/tor_plain_net_option_enum.dart';
import '../../../wl_gen/interfaces/libepiccash_interface.dart';
import '../../crypto_currency/crypto_currency.dart';
import '../../isar/models/wallet_info.dart';
import '../../models/tx_data.dart';
import '../intermediate/mimblewimble_wallet.dart';
import '../supporting/mimblewimble_wallet_info_extension.dart';
import '../wallet_mixin_interfaces/slatepack_interface.dart';

//
// refactor of https://github.com/cypherstack/stack_wallet/blob/1d9fb4cd069f22492ece690ac788e05b8f8b1209/lib/services/coins/epiccash/epiccash_wallet.dart
//
class EpiccashWallet extends MimblewimbleWallet {
  EpiccashWallet(CryptoCurrencyNetwork network) : super(Epiccash(network));

  NodeModel? _epicNode;

  DynamicObject? _wallet;

  @override
  String get walletInfoDataKey => WalletInfoKeys.epiccashData;

  @override
  String get walletDirName => "epiccash";

  @override
  int get firstBlockTimestamp => 1565370278;

  @override
  SlatepackTerms get slatepackTerms => SlatepackTerms.slate;

  // Epic Cash users have always defaulted to epicbox.
  @override
  List<SlatepackMethod> get supportedMethods => const [
    SlatepackMethod.relay,
    SlatepackMethod.slatepack,
  ];

  @override
  Future<void> updateRelayConfig(String host, int port) async {
    final String stringConfig = jsonEncode(<String, dynamic>{
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

  @override
  Future<String> cancelPendingTransactionAndPost(String txSlateId) async {
    try {
      _hackedCheckTorNodePrefs();
      if (_wallet == null) {
        throw Exception('Wallet not initialized');
      }

      final String result = await libEpic.cancelTransaction(
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

  @override
  Future<EpicBoxConfigModel> getRelayConfig() async {
    // check for user-configured epicbox first
    final String? storedConfig = await secureStorageInterface.read(
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

  // ================= Slatepack Operations ===================================

  /// Epic slates are exchanged as plain JSON and are never encrypted.
  /// [sendAll] is ignored; prepareSend already took the fee off the amount.
  @override
  Future<SlatepackResult> createSlatepack({
    required Amount amount,
    String? recipientAddress,
    String? message,
    bool sendAll = false,
  }) async {
    try {
      _hackedCheckTorNodePrefs();
      if (_wallet == null) {
        throw Exception('Wallet not opened. Call open() first.');
      }
      final result = await libEpic.createTransaction(
        wallet: _wallet!,
        amount: amount.raw.toInt(),
        address: 'slate', // Not used in slate mode.
        secretKeyIndex: 0,
        minimumConfirmations: cryptoCurrency.minConfirms,
        note: message ?? '',
        returnSlate: true,
      );

      final info = inspectSlateJsonString(result.slateJson);
      return SlatepackResult(
        success: true,
        slatepack: result.slateJson,
        slateJson: result.slateJson,
        wasEncrypted: false,
        recipientAddress: recipientAddress,
        state: SlateState.s1,
        slateId: result.slateId,
        amount: info?.amount ?? amount,
        fee: info?.fee,
      );
    } catch (e, s) {
      Logging.instance.e('Failed to create slatepack: $e\n$s');
      return SlatepackResult(success: false, error: e.toString());
    }
  }

  /// Slates are already JSON so this only validates the input.
  @override
  Future<SlatepackDecodeResult> decodeSlatepack(String slatepack) async {
    try {
      jsonDecode(slatepack);

      return SlatepackDecodeResult(
        success: true,
        slateJson: slatepack,
        wasEncrypted: false,
        senderAddress: null,
        recipientAddress: null,
      );
    } catch (e, s) {
      Logging.instance.e('Failed to decode slatepack: $e\n$s');
      return SlatepackDecodeResult(success: false, error: e.toString());
    }
  }

  @override
  Future<SlatepackResult> receiveSlatepack(String slatepack) async {
    try {
      _hackedCheckTorNodePrefs();
      if (_wallet == null) {
        throw Exception('Wallet not opened. Call open() first.');
      }

      final received = await libEpic.txReceive(
        wallet: _wallet!,
        slateJson: slatepack,
      );

      final info = inspectSlateJsonString(received.slateJson);
      return SlatepackResult(
        success: true,
        slatepack: received.slateJson,
        slateJson: received.slateJson,
        wasEncrypted: false,
        recipientAddress: null,
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
      _hackedCheckTorNodePrefs();
      if (_wallet == null) {
        throw Exception('Wallet not opened. Call open() first.');
      }

      final finalized = await libEpic.txFinalize(
        wallet: _wallet!,
        slateJson: slatepack,
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

  /// Check if address is Epicbox format.
  bool isEpicboxAddress(String address) {
    return address.contains('@');
  }

  // ================= Private =================================================

  Future<bool> _hasConfig() async =>
      (await secureStorageInterface.read(key: '${walletId}_config')) != null;

  Future<String> _buildConfig() async {
    _epicNode ??= getCurrentNode();

    final NodeModel node = _epicNode!;
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
    config["api_listen_port"] = port;
    config["api_listen_interface"] = nodeApiAddress.replaceFirst(
      uri.scheme,
      "",
    );
    final String stringConfig = jsonEncode(config);

    return stringConfig;
  }

  @override
  Future<int> nativeFee(int satoshiAmount) async {
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
        realFee = (Decimal.parse(transactionFees.fee.toString()))
            .toBigInt()
            .toInt();
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
  }) {
    _hackedCheckTorNodePrefs();
    if (_wallet == null) {
      throw Exception('Wallet not opened. Call open() first.');
    }
    return libEpic.getWalletBalances(
      wallet: _wallet!,
      refreshFromNode: refreshFromNode,
      minimumConfirmations: minimumConfirmations,
    );
  }

  @override
  Future<int> fetchChainHeight() async {
    _hackedCheckTorNodePrefs();
    final String config = await _buildConfig();
    return libEpic.getChainHeight(config: config);
  }

  Future<bool> _testEpicboxServer(EpicBoxConfigModel epicboxConfig) async {
    _hackedCheckTorNodePrefs();
    final String host = epicboxConfig.host;
    final int port = epicboxConfig.port ?? 443;
    WebSocketChannel? channel;
    try {
      final Uri uri = Uri.parse('wss://$host:$port');

      channel = WebSocketChannel.connect(uri);

      await channel.ready;

      final dynamic response = await channel.stream.first.timeout(
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

  Future<void> _updateAddressInDB(Address address) async {
    try {
      final Address? storedAddress = await getCurrentReceivingAddress();
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

  /// Query the open native wallet, independently of the cached address.
  Future<String> getNativeReceivingAddress() async {
    if (_wallet == null) {
      throw Exception('Wallet not opened. Call open() first.');
    }

    final epicBoxConfig = await getRelayConfig();
    return libEpic.getAddressInfo(
      wallet: _wallet!,
      index: 0,
      epicboxConfig: epicBoxConfig.toString(),
    );
  }

  /// Only index 0 is currently used in stack wallet.
  Future<Address> _generateAndStoreReceivingAddressForIndex(int index) async {
    // Since only 0 is a valid index in stack wallet at this time, lets just
    // throw is not zero
    if (index != 0) {
      throw Exception("Invalid/unexpected address index used");
    }

    final walletAddress = await getNativeReceivingAddress();

    Logging.instance.d("WALLET_ADDRESS_IS $walletAddress");

    final Address address = Address(
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

  @override
  Future<int> scanOutputs({
    required int startHeight,
    required int numberOfBlocks,
  }) {
    return libEpic.scanOutputs(
      wallet: _wallet!,
      startHeight: startHeight,
      numberOfBlocks: numberOfBlocks,
    );
  }

  @override
  Future<void> pauseListenerForScan({required bool needsScanning}) async {
    // Only stop the listener if we actually have blocks to scan.
    // This avoids unnecessary reconnections during periodic refresh
    // when the wallet is already synced to the tip.
    if (needsScanning) {
      // Stop listener during active scanning to avoid potential conflicts
      await libEpic.stopEpicboxListener(wallet: _wallet!);
    }
  }

  @override
  Future<void> resumeListenerAfterScan() async {
    // Use health check to verify the Rust listener task is actually alive,
    // not just that we have a pointer (which could be stale).
    if (!await libEpic.isEpicboxListenerRunning(wallet: _wallet!)) {
      Logging.instance.d("Listener not running, starting it...");
      await _listenToEpicbox();
    } else {
      Logging.instance.d("Listener already running, no restart needed");
    }
  }

  Future<void> _listenToEpicbox() async {
    Logging.instance.d("STARTING WALLET LISTENER ....");
    final EpicBoxConfigModel epicboxConfig = await getRelayConfig();
    if (_wallet == null) {
      throw Exception('Wallet not opened. Call open() first.');
    }
    libEpic.updateEpicboxConfig(
      wallet: _wallet!,
      epicBoxConfig: epicboxConfig.toString(),
    );
    await libEpic.startEpicboxListener(wallet: _wallet!);
  }

  static const _mid = "_:'", _end = "':";

  /// eeehhhhhhhhhhhhhhh
  bool _fuzzyEquals(TransactionV2 a, TransactionV2 b) {
    final bool isAmountReceivedMatches =
        a.getAmountReceivedInThisWallet(
          fractionDigits: cryptoCurrency.fractionDigits,
        ) ==
        b.getAmountReceivedInThisWallet(
          fractionDigits: cryptoCurrency.fractionDigits,
        );

    final bool isFeeMatches =
        a.getFee(fractionDigits: cryptoCurrency.fractionDigits) ==
        b.getFee(fractionDigits: cryptoCurrency.fractionDigits);

    final bool isAmountSentMatches =
        a.getAmountSentFromThisWallet(
          fractionDigits: cryptoCurrency.fractionDigits,
          subtractFee: false,
        ) ==
        b.getAmountSentFromThisWallet(
          fractionDigits: cryptoCurrency.fractionDigits,
          subtractFee: false,
        );

    final bool isHeightMatches = a.height == b.height;
    final bool isTxTypeMatches = a.type == b.type && a.subType == b.subType;
    final bool isSlateIdMatches = a.slateId == b.slateId;

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
  Future<void> prepareRefresh() async {
    _hackedCheckTorNodePrefs();

    if (_wallet == null) {
      throw Exception('Wallet not opened. Call open() first.');
    }
  }

  @override
  Future<void> init({bool? isRestore}) async {
    if (isRestore != true) {
      final bool existingWalletConfig = await _hasConfig();

      // check if should create a new wallet
      if (!existingWalletConfig) {
        await updateNode();
        final String mnemonicString = await getMnemonic();

        final String password = generatePassword();
        final EpicBoxConfigModel epicboxConfig = await getRelayConfig();

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
        final int bufferedCreateHeight = calculateRestoreHeightFrom(
          date: DateTime.now().subtract(const Duration(days: 2)),
        );

        final ExtraMimblewimbleWalletInfo epicData =
            ExtraMimblewimbleWalletInfo(
              receivingIndex: 0,
              changeIndex: 0,
              slatesToAddresses: {},
              slatesToCommits: {},
              lastScannedBlock: bufferedCreateHeight,
              restoreHeight: bufferedCreateHeight,
              creationHeight: bufferedCreateHeight,
            );

        await updateMimblewimbleData(epicData);

        await _listenToEpicbox();
      } else {
        try {
          Logging.instance.d(
            "initializeExisting() ${cryptoCurrency.prettyName} wallet",
          );

          final String? password = await secureStorageInterface.read(
            key: '${walletId}_password',
          );
          final EpicBoxConfigModel epicboxConfig = await getRelayConfig();

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

  @visibleForTesting
  bool shouldCheckEpicbox(String receiverAddress) =>
      !isHttpAddress(receiverAddress);

  @override
  Future<TxData> confirmSend({required TxData txData}) async {
    try {
      _hackedCheckTorNodePrefs();

      // TODO determine whether it is worth sending change to a change address.

      final String receiverAddress = txData.recipients!.first.address;
      final useEpicbox = shouldCheckEpicbox(receiverAddress);

      if (useEpicbox) {
        final epicboxConfig = await getRelayConfig();
        final bool isEpicboxConnected = await _testEpicboxServer(epicboxConfig);
        if (!isEpicboxConnected) {
          throw Exception("Failed to send TX : Unable to reach epicbox server");
        }
      }

      ({String commitId, String slateId, String slateJson}) transaction;

      if (!useEpicbox) {
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

      final Map<String, String> txAddressInfo = <String, String>{};
      txAddressInfo['from'] = (await getCurrentReceivingAddress())!.value;
      txAddressInfo['to'] = txData.recipients!.first.address;
      await putSendToAddresses((
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

      final int realFee = await nativeFee(recipient.amount.raw.toInt());
      final Amount feeAmount = Amount(
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

      final SlatepackMethod method;
      if (txData.isSlatepackSend || recipient.address.isEmpty) {
        method = SlatepackMethod.slatepack;
      } else if (isHttpAddress(recipient.address)) {
        method = SlatepackMethod.http;
      } else {
        method = SlatepackMethod.relay;
      }

      return txData.copyWith(
        recipients: [recipient],
        fee: feeAmount,
        otherData: slatepackMethodOtherData(method),
      );
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
          final List<TransactionV2> currentTxns1 = await mainDB
              .isar
              .transactionV2s
              .where()
              .walletIdEqualTo(walletId)
              .findAll();

          final List<TransactionV2> currentTxns = [];

          for (final TransactionV2 current in currentTxns1) {
            if (currentTxns
                .where((TransactionV2 e) => _fuzzyEquals(e, current))
                .isNotEmpty) {
              Logging.instance.f("DELETING: $current");
              await mainDB.isar.writeTxn(() async {
                await mainDB.isar.transactionV2s.delete(current.id);
              });
            } else {
              currentTxns.add(current);
            }
          }

          for (final TransactionV2 current in currentTxns) {
            // check notes first
            final TransactionNote? note = await mainDB.isar.transactionNotes
                .where()
                .txidWalletIdEqualTo(current.slateId ?? current.txid, walletId)
                .findFirst();

            // now handle transaction
            final bool firstTime =
                !(current.txid.contains(_mid) && current.txid.endsWith(_end));

            final String txid;
            if (firstTime) {
              txid = "${current.txid}${_mid}0$_end";
            } else {
              // this should always be 2 parts if we've gotten this far
              final List<String> parts = current.txid.split(_mid);
              final int rescanCount =
                  int.parse(parts.last.replaceFirst(_end, "")) + 1;
              txid = "${parts.first}$_mid$rescanCount$_end";
            }

            // finally update in db
            await mainDB.isar.writeTxn(() async {
              final TransactionV2 updated = current.copyWith(txid: txid);
              if (note != null) {
                final TransactionNote updatedNote = TransactionNote(
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

          await updateMimblewimbleData(
            mimblewimbleData!.copyWith(
              lastScannedBlock: mimblewimbleData!.restoreHeight,
            ),
          );

          final String? password = await secureStorageInterface.read(
            key: '${walletId}_password',
          );
          final EpicBoxConfigModel epicboxConfig = await getRelayConfig();

          // maybe there is some way to tel epic-wallet rust to fully rescan...
          final String result = await deleteEpicWallet(
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
            mimblewimbleData?.receivingIndex ?? 0,
          );

          await _listenToEpicbox();

          highestPercent = 0;
        } else {
          await updateNode();
          final String password = generatePassword();

          final EpicBoxConfigModel epicboxConfig = await getRelayConfig();

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

          final ExtraMimblewimbleWalletInfo epicData =
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

          await updateMimblewimbleData(epicData);

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
  Future<void> updateTransactions() async {
    try {
      _hackedCheckTorNodePrefs();
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

      final List<MimblewimbleTransaction> transactions = await libEpic
          .getTransactions(wallet: _wallet!, refreshFromNode: refreshFromNode);

      final List<TransactionV2> txns = [];

      final Map<dynamic, dynamic> slatesToCommits =
          mimblewimbleData?.slatesToCommits ?? <dynamic, dynamic>{};

      for (final MimblewimbleTransaction tx in transactions) {
        final bool isIncoming =
            libEpic.txTypeIsReceived(tx.txType) ||
            libEpic.txTypeIsReceiveCancelled(tx.txType);
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

        // hack epic tx data into inputs and outputs
        final List<OutputV2> outputs = [];
        final List<InputV2> inputs = [];
        final bool addressFromIsMine = myAddressesSet.contains(addressFrom);
        final bool addressToIsMine = myAddressesSet.contains(addressTo);

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

        final Map<String, dynamic> otherData = <String, dynamic>{
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

        if (txns.where((TransactionV2 e) => _fuzzyEquals(e, txn)).isEmpty) {
          txns.add(txn);
        }
      }

      final List<TransactionV2> existingTxns = await mainDB.isar.transactionV2s
          .where()
          .walletIdEqualTo(walletId)
          .findAll();

      await mainDB.isar.writeTxn(() async {
        for (final TransactionV2 tx in txns) {
          final Iterable<TransactionV2> existingMatches = existingTxns.where(
            (TransactionV2 e) => _fuzzyEquals(e, tx),
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
            for (final TransactionV2 match in existingMatches) {
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

          final int? id = await mainDB.isar.transactionV2s
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
      final NodeModel? node = nodeService.getPrimaryNodeFor(
        currency: cryptoCurrency,
      );

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
  Future<void> exit() async {
    if (_wallet != null) await libEpic.stopEpicboxListener(wallet: _wallet!);
    await super.exit();
  }

  void _hackedCheckTorNodePrefs() {
    final NodeModel node = nodeService.getPrimaryNodeFor(
      currency: cryptoCurrency,
    )!;
    final TorPlainNetworkOption netOption = TorPlainNetworkOption.fromNodeData(
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
  final String? config = await wallet._hasConfig()
      ? await wallet._buildConfig()
      : null;

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

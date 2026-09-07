import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:decimal/decimal.dart';
import 'package:flutter/foundation.dart';
import 'package:isar_community/isar.dart';
import 'package:mutex/mutex.dart';

import '../../../models/balance.dart';
import '../../../models/paymint/fee_object_model.dart';
import '../../../models/relay_config_model.dart';
import '../../../models/slatepack_models.dart';
import '../../../services/event_bus/events/global/blocks_remaining_event.dart';
import '../../../services/event_bus/events/global/node_connection_status_changed_event.dart';
import '../../../services/event_bus/events/global/refresh_percent_changed_event.dart';
import '../../../services/event_bus/events/global/wallet_sync_status_changed_event.dart';
import '../../../services/event_bus/global_event_bus.dart';
import '../../../utilities/amount/amount.dart';
import '../../../utilities/logger.dart';
import '../../../utilities/stack_file_system.dart';
import '../../models/tx_data.dart';
import '../supporting/mimblewimble_wallet_info_extension.dart';
import '../supporting/restore_progress.dart';
import 'bip39_wallet.dart';

/// What Epic Cash and MWC have in common: a native wallet that is scanned
/// in block chunks, a relay server for automatic slate exchange, and manual
/// slatepack exchange.
abstract class MimblewimbleWallet extends Bip39Wallet {
  MimblewimbleWallet(super.currency);

  final Mutex syncMutex = Mutex();
  Timer? timer;

  double highestPercent = 0;

  /// The [WalletInfoKeys] entry [ExtraMimblewimbleWalletInfo] is stored under.
  String get walletInfoDataKey;

  /// Subdirectory of the app root holding the native wallet files.
  String get walletDirName;

  /// Unix time of the chain's first block, used to estimate a height from a
  /// date.
  int get firstBlockTimestamp;

  ExtraMimblewimbleWalletInfo? get mimblewimbleData =>
      info.mimblewimbleData(walletInfoDataKey);

  Future<void> updateMimblewimbleData(ExtraMimblewimbleWalletInfo data) {
    return info.updateMimblewimbleData(
      key: walletInfoDataKey,
      data: data,
      isar: mainDB.isar,
    );
  }

  Future<double> get getSyncPercent async {
    final int lastScannedBlock = mimblewimbleData?.lastScannedBlock ?? 0;
    final int _chainHeight = await chainHeight;
    final restorePercent = calculateRestoreProgress(
      scannedHeight: lastScannedBlock,
      chainHeight: _chainHeight,
    );
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

  Future<void> updateRestoreHeight(int height) async {
    await updateMimblewimbleData(
      mimblewimbleData!.copyWith(restoreHeight: height),
    );
  }

  /// Returns an empty String on success, error message on failure.
  Future<String> cancelPendingTransactionAndPost(String txSlateId);

  Future<RelayConfigModel> getRelayConfig();

  Future<void> updateRelayConfig(String host, int port);

  // ================= Slatepack Operations ===================================

  Future<SlatepackResult> createSlatepack({
    required Amount amount,
    String? recipientAddress,
    String? message,
    bool encrypt = false,
    int? minimumConfirmations,
  });

  Future<SlatepackDecodeResult> decodeSlatepack(String slatepack);

  /// Receive a slatepack and return the response slatepack.
  Future<ReceiveResult> receiveSlatepack(String slatepack);

  /// Finalize a slatepack (sender step 3).
  Future<FinalizeResult> finalizeSlatepack(String slatepack);

  bool isSlatepack(String data);

  bool isHttpAddress(String address) {
    return address.startsWith('http://') || address.startsWith('https://');
  }

  /// Cheap syntactic check run by [fullDecodeSlatepack] before decoding.
  /// Throws to reject input that is obviously not a slatepack.
  @protected
  void checkSlatepackFormat(String slatepack) {}

  // this isn't nearly the best way to handle this but better than copy pasting
  // this function in two places (mobile and desktop widgets)...
  Future<({SlatepackDecodeResult result, String type, String raw})?>
  fullDecodeSlatepack(String slatepack) async {
    // add delay for showloading exception catching hack fix
    await Future<void>.delayed(const Duration(seconds: 1));

    if (slatepack.isEmpty) {
      return null;
    }

    checkSlatepackFormat(slatepack);

    final SlatepackDecodeResult decoded = await decodeSlatepack(slatepack);
    if (!decoded.success) {
      throw Exception(decoded.error ?? "Failed to decode slatepack");
    }

    final analysis = await analyzeSlatepack(slatepack);

    final String slatepackType = switch (analysis.status) {
      'S1' => "S1 (Initial Send)",
      'S2' => "S2 (Response)",
      'S3' => "S3 (Finalized)",
      _ => _slatepackTypeFromAddresses(decoded),
    };

    return (result: decoded, type: slatepackType, raw: slatepack);
  }

  String _slatepackTypeFromAddresses(SlatepackDecodeResult decoded) {
    if (decoded.senderAddress != null && decoded.recipientAddress != null) {
      return "S2 (Response)";
    } else if (decoded.senderAddress != null) {
      return "S1 (Initial)";
    } else {
      return "Unknown";
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
  analyzeSlatepack(String slatepack) async {
    try {
      final SlatepackDecodeResult decoded = await decodeSlatepack(slatepack);
      if (!decoded.success) {
        throw Exception(decoded.error);
      }

      final dynamic slateData = jsonDecode(decoded.slateJson!);
      final String slateId = "${slateData['id'] ?? ''}";
      final String? amountStr = slateData['amount']?.toString();

      Logging.instance.d('Analyzed slatepack with ID: $slateId');

      String status = 'Unknown';
      String type = 'Unknown';

      // Count signatures in the participant data to work out which step
      // the slate is at.
      final List<dynamic>? participants =
          slateData['participant_data'] as List<dynamic>?;
      if (participants != null && participants.isNotEmpty) {
        int signedParticipants = 0;
        for (final dynamic participant in participants) {
          if (participant['part_sig'] != null) {
            signedParticipants++;
          }
        }

        if (signedParticipants == 0) {
          status = 'S1';
          type = 'Outgoing';
        } else if (signedParticipants == 1) {
          status = 'S2';
          type = 'Incoming';
        } else if (signedParticipants >= participants.length) {
          status = 'S3';
          type = 'Outgoing';
        }
      }

      // Fallback: some slates carry an explicit 'sta' field.
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
        wasEncrypted: decoded.wasEncrypted ?? false,
        senderAddress: decoded.senderAddress,
        recipientAddress: decoded.recipientAddress,
        slateId: slateId,
      );
    } catch (e) {
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

  // ================= Native wallet hooks =====================================

  @protected
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
  });

  @protected
  Future<int> fetchChainHeight();

  @protected
  Future<int> nativeFee(int satoshiAmount);

  @protected
  Future<int> scanOutputs({
    required int startHeight,
    required int numberOfBlocks,
  });

  /// Called before scanning starts. [needsScanning] is false when the wallet
  /// is already at the tip.
  @protected
  Future<void> pauseListenerForScan({required bool needsScanning});

  /// Called once scanning has reached the tip.
  @protected
  Future<void> resumeListenerAfterScan();

  /// Runs at the start of every [refresh], before scanning.
  @protected
  Future<void> prepareRefresh();

  // ================= Shared implementation ===================================

  Future<String> currentWalletDirPath() async {
    final Directory appDir = await StackFileSystem.applicationRootDirectory();

    final String path = "${appDir.path}/$walletDirName";
    final String name = walletId.trim();
    return '$path/$name';
  }

  // TODO: make more robust estimate of date maybe using https://explorer.epic.tech/api-index
  int calculateRestoreHeightFrom({required DateTime date}) {
    final int secondsSinceEpoch = date.millisecondsSinceEpoch ~/ 1000;
    const double overestimateSecondsPerBlock = 61;
    final int chosenSeconds = secondsSinceEpoch - firstBlockTimestamp;
    final int approximateHeight = chosenSeconds ~/ overestimateSecondsPerBlock;
    int height = approximateHeight;
    if (height < 0) {
      height = 0;
    }
    return height;
  }

  @protected
  Future<void> startSync() async {
    Logging.instance.d("request start sync");
    const int refreshFromNode = 1;
    if (!syncMutex.isLocked) {
      await syncMutex.protect(() async {
        // How does getWalletBalances start syncing?????????!!!!!
        await fetchWalletBalances(
          refreshFromNode: refreshFromNode,
          minimumConfirmations: 10,
        );
      });
    } else {
      Logging.instance.d("request start sync denied");
    }
  }

  @protected
  Future<void> startScans() async {
    try {
      // max number of blocks to scan per loop iteration
      const int scanChunkSize = 10000;

      // force firing of scan progress event
      await getSyncPercent;

      // fetch current chain height and last scanned block (should be the
      // restore height if full rescan or a wallet restore)
      int chainHeight = await this.chainHeight;
      int lastScannedBlock = mimblewimbleData!.lastScannedBlock;

      await pauseListenerForScan(needsScanning: lastScannedBlock < chainHeight);

      // loop while scanning in chain in chunks (of blocks?)
      while (lastScannedBlock < chainHeight) {
        Logging.instance.d(
          "chainHeight: $chainHeight, lastScannedBlock: $lastScannedBlock",
        );

        final int nextScannedBlock = await scanOutputs(
          startHeight: lastScannedBlock,
          numberOfBlocks: scanChunkSize,
        );

        // update local cache
        await updateMimblewimbleData(
          mimblewimbleData!.copyWith(lastScannedBlock: nextScannedBlock),
        );

        // force firing of scan progress event
        await getSyncPercent;

        // update while loop condition variables
        chainHeight = await this.chainHeight;
        lastScannedBlock = nextScannedBlock;
      }

      Logging.instance.d("startScans successfully at the tip");

      await resumeListenerAfterScan();
    } catch (e, s) {
      Logging.instance.e("startScans failed: ", error: e, stackTrace: s);
      rethrow;
    }
  }

  @protected
  Future<bool> putSendToAddresses(
    ({String slateId, String commitId}) slateData,
    Map<String, String> txAddressInfo,
  ) async {
    try {
      final Map<dynamic, dynamic> slatesToCommits =
          mimblewimbleData?.slatesToCommits ?? <dynamic, dynamic>{};
      final String? from = txAddressInfo['from'];
      final String? to = txAddressInfo['to'];
      slatesToCommits[slateData.slateId] = <String, String?>{
        "commitId": slateData.commitId,
        "from": from,
        "to": to,
      };
      await updateMimblewimbleData(
        mimblewimbleData!.copyWith(slatesToCommits: slatesToCommits),
      );
      return true;
    } catch (e, s) {
      Logging.instance.e("ERROR STORING ADDRESS", error: e, stackTrace: s);
      return false;
    }
  }

  @protected
  Future<int> getCurrentIndex() async {
    try {
      final int receivingIndex = mimblewimbleData!.receivingIndex;
      // TODO: go through pendingarray and processed array and choose the index
      //  of the last one that has not been processed, or the index after the
      //  one most recently processed;
      return receivingIndex;
    } catch (e, s) {
      Logging.instance.e("$e $s", error: e, stackTrace: s);
      return 0;
    }
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

      await prepareRefresh();

      if (doScan) {
        await startScans();

        unawaited(startSync());
      }

      GlobalEventBus.instance.fire(RefreshPercentChangedEvent(0.0, walletId));
      await updateChainHeight();

      GlobalEventBus.instance.fire(RefreshPercentChangedEvent(0.1, walletId));
      GlobalEventBus.instance.fire(RefreshPercentChangedEvent(0.2, walletId));
      GlobalEventBus.instance.fire(RefreshPercentChangedEvent(0.3, walletId));

      GlobalEventBus.instance.fire(RefreshPercentChangedEvent(0.50, walletId));
      final Future<void> fetchFuture = updateTransactions();
      GlobalEventBus.instance.fire(RefreshPercentChangedEvent(0.60, walletId));

      GlobalEventBus.instance.fire(RefreshPercentChangedEvent(0.70, walletId));

      await fetchFuture;
      GlobalEventBus.instance.fire(RefreshPercentChangedEvent(0.80, walletId));

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
        timer ??= Timer.periodic(const Duration(seconds: 150), (Timer timer) {
          // TODO: [prio=med] some kind of quick check if wallet needs to
          //  refresh to replace the old refreshIfThereIsNewData call
          unawaited(refresh());
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
      final balances = await fetchWalletBalances(
        refreshFromNode: 0,
        minimumConfirmations: cryptoCurrency.minConfirms,
      );
      final Balance balance = Balance(
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
        "${cryptoCurrency.prettyName} wallet failed to update balance: ",
        error: e,
        stackTrace: s,
      );
    }
  }

  @override
  Future<bool> updateUTXOs() async {
    // not used for mimblewimble coins
    return false;
  }

  @override
  Future<void> updateChainHeight() async {
    final int latestHeight = await fetchChainHeight();
    await info.updateCachedChainHeight(
      newHeight: latestHeight,
      isar: mainDB.isar,
    );
  }

  @override
  Future<Amount> estimateFeeFor(Amount amount, BigInt feeRate) async {
    final int currentFee = await nativeFee(amount.raw.toInt());
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
    Logging.instance.d("$runtimeType exit finished");
  }
}

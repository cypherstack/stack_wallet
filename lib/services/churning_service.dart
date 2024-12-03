import 'dart:async';
import 'dart:math';

import 'package:cs_monero/cs_monero.dart';
import 'package:flutter/cupertino.dart';
import 'package:mutex/mutex.dart';

import '../wallets/wallet/intermediate/lib_monero_wallet.dart';

enum ChurnStatus {
  waiting,
  running,
  failed,
  success;
}

class ChurningService extends ChangeNotifier {
  // stack only uses account 0 at this point in time
  static const kAccount = 0;

  ChurningService({required this.wallet});

  final LibMoneroWallet wallet;
  Wallet get csWallet => wallet.libMoneroWallet!;

  int rounds = 1; // default
  bool ignoreErrors = false; // default

  bool _running = false;

  ChurnStatus waitingForUnlockedBalance = ChurnStatus.waiting;
  ChurnStatus makingChurnTransaction = ChurnStatus.waiting;
  ChurnStatus completedStatus = ChurnStatus.waiting;
  int roundsCompleted = 0;
  bool done = false;
  Object? lastSeenError;

  bool _canChurn() {
    if (csWallet.getUnlockedBalance(accountIndex: kAccount) > BigInt.zero) {
      return true;
    } else {
      return false;
    }
  }

  String? confirmsInfo;
  Future<void> _updateConfirmsInfo() async {
    final currentHeight = wallet.currentKnownChainHeight;
    if (currentHeight < 1) {
      return;
    }

    final outputs = await csWallet.getOutputs(refresh: true);
    final required = wallet.cryptoCurrency.minConfirms;

    int lowestNumberOfConfirms = required;

    for (final output in outputs.where((e) => !e.isFrozen && !e.spent)) {
      final confirms = currentHeight - output.height;

      lowestNumberOfConfirms = min(lowestNumberOfConfirms, confirms);
    }

    final bool shouldNotify;
    if (lowestNumberOfConfirms == required) {
      shouldNotify = confirmsInfo != null;
      confirmsInfo = null;
    } else {
      final prev = confirmsInfo;
      confirmsInfo = "($lowestNumberOfConfirms/$required)";
      shouldNotify = confirmsInfo != prev;
    }

    if (_running && _timerRunning && shouldNotify) {
      notifyListeners();
    }
  }

  Timer? _confirmsTimer;
  bool _timerRunning = false;
  void _stopConfirmsTimer() {
    _timerRunning = false;
    _confirmsTimer?.cancel();
    confirmsInfo = null;
    _confirmsTimer = null;
  }

  void _startConfirmsTimer() {
    _confirmsTimer?.cancel();
    _confirmsTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _updateConfirmsInfo(),
    );
  }

  final _pause = Mutex();
  bool get isPaused => _pause.isLocked;
  void unpause() {
    if (_pause.isLocked) _pause.release();
  }

  Future<void> churn() async {
    if (rounds < 0 || _running) {
      // TODO: error?
      return;
    }

    _running = true;
    waitingForUnlockedBalance = ChurnStatus.running;
    makingChurnTransaction = ChurnStatus.waiting;
    completedStatus = ChurnStatus.waiting;
    roundsCompleted = 0;
    done = false;
    lastSeenError = null;
    notifyListeners();

    final roundsToDo = rounds;
    final continuous = rounds == 0;

    bool complete() => !continuous && roundsCompleted >= roundsToDo;

    while (!complete() && _running) {
      if (_canChurn()) {
        waitingForUnlockedBalance = ChurnStatus.success;
        makingChurnTransaction = ChurnStatus.running;
        notifyListeners();

        try {
          _stopConfirmsTimer();
          Logging.log?.i("Doing churn #${roundsCompleted + 1}");
          await _churnTxSimple();
          waitingForUnlockedBalance = ChurnStatus.success;
          makingChurnTransaction = ChurnStatus.success;
          roundsCompleted++;
          notifyListeners();
        } catch (e, s) {
          Logging.log?.e(
            "Churning round #${roundsCompleted + 1} failed",
            error: e,
            stackTrace: s,
          );
          lastSeenError = e;
          makingChurnTransaction = ChurnStatus.failed;
          notifyListeners();
          if (!ignoreErrors) {
            await _pause.acquire();
            await _pause.protect(() async {});

            if (!_running) {
              completedStatus = ChurnStatus.failed;
              // exit if stop option chosen on error
              return;
            }
          }
        }
      } else {
        Logging.log?.i("Can't churn yet, waiting...");
      }

      if (!complete() && _running) {
        _startConfirmsTimer();
        waitingForUnlockedBalance = ChurnStatus.running;
        makingChurnTransaction = ChurnStatus.waiting;
        completedStatus = ChurnStatus.waiting;
        notifyListeners();
        // sleep
        await Future<void>.delayed(const Duration(seconds: 30));
      }
    }

    waitingForUnlockedBalance = ChurnStatus.success;
    makingChurnTransaction = ChurnStatus.success;
    completedStatus = ChurnStatus.success;
    done = true;
    _running = false;
    notifyListeners();
    Logging.log?.i("Churning complete");
  }

  void stopChurning() {
    done = true;
    _running = false;
    notifyListeners();
    unpause();
  }

  Future<void> _churnTxSimple({
    final TransactionPriority priority = TransactionPriority.normal,
  }) async {
    final address = csWallet.getAddress(
      accountIndex: kAccount,
      addressIndex: 0,
    );

    final pending = await csWallet.createTx(
      output: Recipient(
        address: address.value,
        amount: BigInt.zero, // Doesn't matter if `sweep` is true
      ),
      priority: priority,
      accountIndex: kAccount,
      sweep: true,
    );

    await csWallet.commitTx(pending);
  }
}

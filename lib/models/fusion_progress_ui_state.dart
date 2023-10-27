import 'package:flutter/cupertino.dart';
import 'package:stackwallet/pages_desktop_specific/cashfusion/sub_widgets/fusion_dialog.dart';

class FusionProgressUIState extends ChangeNotifier {
  /// Whether we are able to connect to the server.
  bool _ableToConnect = false;

  // _ableToConnect setter.
  set ableToConnect(bool ableToConnect) {
    _ableToConnect = ableToConnect;
    notifyListeners();
  }

  bool get done {
    if (!_ableToConnect) {
      return false;
    }

    bool _done = (_connecting.status == CashFusionStatus.success) ||
        (_connecting.status == CashFusionStatus.failed);
    _done &= (_outputs.status == CashFusionStatus.success) ||
        (_outputs.status == CashFusionStatus.failed);
    _done &= (_peers.status == CashFusionStatus.success) ||
        (_peers.status == CashFusionStatus.failed);
    _done &= (_fusing.status == CashFusionStatus.success) ||
        (_fusing.status == CashFusionStatus.failed);
    _done &= (_complete.status == CashFusionStatus.success) ||
        (_complete.status == CashFusionStatus.failed);

    _done &= (fusionState.status == CashFusionStatus.success) ||
        (fusionState.status == CashFusionStatus.failed);

    return _done;
  }

  bool get succeeded {
    if (!_ableToConnect) {
      return false;
    }

    bool _succeeded = _connecting.status == CashFusionStatus.success;
    _succeeded &= _outputs.status == CashFusionStatus.success;
    _succeeded &= _peers.status == CashFusionStatus.success;
    _succeeded &= _fusing.status == CashFusionStatus.success;
    _succeeded &= _complete.status == CashFusionStatus.success;

    _succeeded &= fusionState.status == CashFusionStatus.success;

    return _succeeded;
  }

  CashFusionState _connecting =
      CashFusionState(status: CashFusionStatus.waiting, info: null);
  CashFusionState get connecting => _connecting;
  void setConnecting(CashFusionState state, {bool shouldNotify = true}) {
    _connecting = state;
    _running = true;
    if (shouldNotify) {
      notifyListeners();
    }
  }

  CashFusionState _outputs =
      CashFusionState(status: CashFusionStatus.waiting, info: null);
  CashFusionState get outputs => _outputs;
  void setOutputs(CashFusionState state, {bool shouldNotify = true}) {
    _outputs = state;
    _running = true;
    if (shouldNotify) {
      notifyListeners();
    }
  }

  CashFusionState _peers =
      CashFusionState(status: CashFusionStatus.waiting, info: null);
  CashFusionState get peers => _peers;
  void setPeers(CashFusionState state, {bool shouldNotify = true}) {
    _peers = state;
    _running = true;
    if (shouldNotify) {
      notifyListeners();
    }
  }

  CashFusionState _fusing =
      CashFusionState(status: CashFusionStatus.waiting, info: null);
  CashFusionState get fusing => _fusing;
  void setFusing(CashFusionState state, {bool shouldNotify = true}) {
    _fusing = state;
    _running = true;
    if (shouldNotify) {
      notifyListeners();
    }
  }

  CashFusionState _complete =
      CashFusionState(status: CashFusionStatus.waiting, info: null);
  CashFusionState get complete => _complete;
  void setComplete(CashFusionState state, {bool shouldNotify = true}) {
    _complete = state;
    _running = true;
    if (shouldNotify) {
      notifyListeners();
    }
  }

  CashFusionState _fusionStatus =
      CashFusionState(status: CashFusionStatus.waiting, info: null);
  CashFusionState get fusionState => _fusionStatus;
  void setFusionState(CashFusionState state, {bool shouldNotify = true}) {
    _fusionStatus = state;
    _updateRunningState(state.status);
    if (shouldNotify) {
      notifyListeners();
    }
  }

  /// An int storing the number of successfully completed fusion rounds.
  int _fusionRoundsCompleted = 0;
  int get fusionRoundsCompleted => _fusionRoundsCompleted;
  set fusionRoundsCompleted(int fusionRoundsCompleted) {
    _fusionRoundsCompleted = fusionRoundsCompleted;
    notifyListeners();
  }

  /// A helper for incrementing the number of successfully completed fusion rounds.
  void incrementFusionRoundsCompleted() {
    _fusionRoundsCompleted++;
    _fusionRoundsFailed = 0; // Reset failed round count on success.
    _failed = false; // Reset failed flag on success.
    notifyListeners();
  }

  /// An int storing the number of failed fusion rounds.
  int _fusionRoundsFailed = 0;
  int get fusionRoundsFailed => _fusionRoundsFailed;
  set fusionRoundsFailed(int fusionRoundsFailed) {
    _fusionRoundsFailed = fusionRoundsFailed;
    notifyListeners();
  }

  /// A helper for incrementing the number of failed fusion rounds.
  void incrementFusionRoundsFailed() {
    _fusionRoundsFailed++;
    notifyListeners();
  }

  /// A flag indicating that fusion has stopped because the maximum number of
  /// consecutive failed fusion rounds has been reached.
  ///
  /// Set from the interface.  I didn't want to have to configure
  ///
  /// Used to be named maxConsecutiveFusionRoundsFailed.
  bool _failed = false;
  bool get failed => _failed;
  void setFailed(bool failed, {bool shouldNotify = true}) {
    _failed = failed;
    if (shouldNotify) {
      notifyListeners();
    }
  }

  /// A flag indicating that fusion is running.
  bool _running = false;
  bool get running => _running;
  void setRunning(bool running, {bool shouldNotify = true}) {
    _running = running;
    if (shouldNotify) {
      notifyListeners();
    }
  }

  /// A helper method for setting the running flag.
  ///
  /// Sets the running flag to true if the status is running.  Sets the flag to
  /// false if succeeded or failed or the global failed flag is set.
  void _updateRunningState(CashFusionStatus status) {
    if (status == CashFusionStatus.running) {
      _running = true;
    } else if (((status == CashFusionStatus.success ||
                status == CashFusionStatus.failed) &&
            (done || succeeded)) ||
        _failed) {
      _running = false;
    }
  }
}

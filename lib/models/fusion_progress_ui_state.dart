import 'package:flutter/cupertino.dart';
import 'package:stackwallet/pages_desktop_specific/cashfusion/sub_widgets/fusion_dialog.dart';

class FusionProgressUIState extends ChangeNotifier {
  bool _ableToConnect = true; // set to true for now

  bool get done {
    if (!_ableToConnect) {
      return false;
    }

    bool _done = (_connecting == CashFusionStatus.success) ||
        (_connecting == CashFusionStatus.failed);
    _done &= (_outputs == CashFusionStatus.success) ||
        (_outputs == CashFusionStatus.failed);
    _done &= (_peers == CashFusionStatus.success) ||
        (_peers == CashFusionStatus.failed);
    _done &= (_fusing == CashFusionStatus.success) ||
        (_fusing == CashFusionStatus.failed);
    _done &= (_complete == CashFusionStatus.success) ||
        (_complete == CashFusionStatus.failed);

    _done &= (fusionState == CashFusionStatus.success) ||
        (fusionState == CashFusionStatus.failed);

    return _done;
  }

  bool get succeeded {
    if (!_ableToConnect) {
      return false;
    }

    bool _succeeded = _connecting == CashFusionStatus.success;
    _succeeded &= _outputs == CashFusionStatus.success;
    _succeeded &= _peers == CashFusionStatus.success;
    _succeeded &= _fusing == CashFusionStatus.success;
    _succeeded &= _complete == CashFusionStatus.success;

    _succeeded &= fusionState == CashFusionStatus.success;

    return _succeeded;
  }

  CashFusionStatus _connecting = CashFusionStatus.waiting;
  CashFusionStatus get connecting => _connecting;
  set connecting(CashFusionStatus state) {
    _connecting = state;
    notifyListeners();
  }

  CashFusionStatus _outputs = CashFusionStatus.waiting;
  CashFusionStatus get outputs => _outputs;
  set outputs(CashFusionStatus state) {
    _outputs = state;
    notifyListeners();
  }

  CashFusionStatus _peers = CashFusionStatus.waiting;
  CashFusionStatus get peers => _peers;
  set peers(CashFusionStatus state) {
    _peers = state;
    notifyListeners();
  }

  CashFusionStatus _fusing = CashFusionStatus.waiting;
  CashFusionStatus get fusing => _fusing;
  set fusing(CashFusionStatus state) {
    _fusing = state;
    notifyListeners();
  }

  CashFusionStatus _complete = CashFusionStatus.waiting;
  CashFusionStatus get complete => _complete;
  set complete(CashFusionStatus state) {
    _complete = state;
    notifyListeners();
  }

  CashFusionStatus _fusionStatus = CashFusionStatus.waiting;
  CashFusionStatus get fusionState => _fusionStatus;
  set fusionState(CashFusionStatus fusionStatus) {
    _fusionStatus = fusionStatus;
    notifyListeners();
  }

  // Instance variables for info labels on fusion progress steps.
  //
  // "Connecting to server"
  String? _connectionInfo;
  String? get connectionInfo => _connectionInfo;
  set connectionInfo(String? fusionInfo) {
    _connectionInfo = fusionInfo;
    notifyListeners();
  }

  // "Allocating outputs"
  String? _outputsInfo;
  String? get outputsInfo => _outputsInfo;
  set outputsInfo(String? fusionInfo) {
    _outputsInfo = fusionInfo;
    notifyListeners();
  }

  // "Waiting for peers"
  String? _peersInfo;
  String? get peersInfo => _peersInfo;
  set peersInfo(String? fusionInfo) {
    _peersInfo = fusionInfo;
    notifyListeners();
  }

  // "Fusing"
  String? _fusingInfo;
  String? get fusingInfo => _fusingInfo;
  set fusingInfo(String? fusionInfo) {
    _fusingInfo = fusionInfo;
    notifyListeners();
  }

  // "Complete"
  //
  // Should show txId if successful.
  String? _completeInfo;
  String? get completeInfo => _completeInfo;
  set completeInfo(String? fusionInfo) {
    _completeInfo = fusionInfo;
    notifyListeners();
  }
}

import 'package:flutter/cupertino.dart';
import 'package:stackwallet/pages_desktop_specific/cashfusion/sub_widgets/fusion_dialog.dart';

class FusionProgressUIState extends ChangeNotifier {
  bool _ableToConnect = true; // set to true for now

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
  set connecting(CashFusionState state) {
    _connecting = state;
    notifyListeners();
  }

  CashFusionState _outputs =
      CashFusionState(status: CashFusionStatus.waiting, info: null);
  CashFusionState get outputs => _outputs;
  set outputs(CashFusionState state) {
    _outputs = state;
    notifyListeners();
  }

  CashFusionState _peers =
      CashFusionState(status: CashFusionStatus.waiting, info: null);
  CashFusionState get peers => _peers;
  set peers(CashFusionState state) {
    _peers = state;
    notifyListeners();
  }

  CashFusionState _fusing =
      CashFusionState(status: CashFusionStatus.waiting, info: null);
  CashFusionState get fusing => _fusing;
  set fusing(CashFusionState state) {
    _fusing = state;
    notifyListeners();
  }

  CashFusionState _complete =
      CashFusionState(status: CashFusionStatus.waiting, info: null);
  CashFusionState get complete => _complete;
  set complete(CashFusionState state) {
    _complete = state;
    notifyListeners();
  }

  CashFusionState _fusionStatus =
      CashFusionState(status: CashFusionStatus.waiting, info: null);
  CashFusionState get fusionState => _fusionStatus;
  set fusionState(CashFusionState fusionStatus) {
    _fusionStatus = fusionStatus;
    notifyListeners();
  }
}

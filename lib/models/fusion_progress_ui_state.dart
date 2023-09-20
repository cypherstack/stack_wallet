import 'package:flutter/cupertino.dart';
import 'package:stackwallet/pages_desktop_specific/cashfusion/sub_widgets/fusion_dialog.dart';

class FusionProgressUIState extends ChangeNotifier {
  bool _ableToConnect = false;

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
    return _done;
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
}

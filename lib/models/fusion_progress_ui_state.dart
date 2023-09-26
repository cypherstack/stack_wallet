import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stackwallet/pages_desktop_specific/cashfusion/sub_widgets/fusion_dialog.dart';
import 'package:stackwallet/services/coins/manager.dart';

import 'fusion_progress_state.dart';

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

    for (final wallet in _fusionState.values) {
      _done &= (wallet.fusionState == CashFusionStatus.success) ||
          (wallet.fusionState == CashFusionStatus.failed);
    }

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

    for (final wallet in _fusionState.values) {
      _succeeded &= wallet.fusionState == CashFusionStatus.success;
    }

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

  List<Manager> get managers {
    List<Manager> _managers = [];
    for (final item in _fusionState.values) {
      if (item.manager != null) {
        _managers.add(item.manager!);
      }
    }
    return _managers;
  }

  Map<String, FusionProgressState> _fusionState = {};
  Map<String, ChangeNotifierProvider<FusionProgressState>>
      _fusionStateProviders = {};
  Map<String, ChangeNotifierProvider<FusionProgressState>>
      get fusionStateProviders => _fusionStateProviders;

  set fusionState(Map<String, FusionProgressState> state) {
    _fusionState = state;
    _fusionStateProviders = {};
    for (final wallet in _fusionState.values) {
      _fusionStateProviders[wallet.walletId] =
          ChangeNotifierProvider<FusionProgressState>((_) => wallet);
    }

    /// todo: is this true
    _ableToConnect = true;
    notifyListeners();
  }

  FusionProgressState getFusionProgressState(String walletId) {
    return _fusionState[walletId]!;
  }

  ChangeNotifierProvider<FusionProgressState> getFusionProgressStateProvider(
      String walletId) {
    return _fusionStateProviders[walletId]!;
  }

  void update({
    required String walletId,
    required CashFusionStatus fusionStatus,
    Manager? manager,
    String? address,
  }) {
    _fusionState[walletId]!.fusionState = fusionStatus;
    _fusionState[walletId]!.manager =
        manager ?? _fusionState[walletId]!.manager;
    _fusionState[walletId]!.address =
        address ?? _fusionState[walletId]!.address;
    notifyListeners();
  }
}

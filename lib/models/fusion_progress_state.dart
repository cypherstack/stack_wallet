import 'package:flutter/cupertino.dart';
import 'package:stackwallet/pages_desktop_specific/cashfusion/sub_widgets/fusion_dialog.dart';
import 'package:stackwallet/services/coins/manager.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';

class FusionProgressState extends ChangeNotifier {
  final String walletId;
  final String walletName;
  final Coin coin;
  late CashFusionStatus _fusionStatus;
  Manager? manager;
  String? address;

  CashFusionStatus get fusionState => _fusionStatus;
  set fusionState(CashFusionStatus fusionStatus) {
    _fusionStatus = fusionStatus;
    notifyListeners();
  }

  FusionProgressState({
    required this.walletId,
    required this.walletName,
    required this.coin,
    required CashFusionStatus fusionStatus,
    this.manager,
    this.address,
  }) {
    _fusionStatus = fusionStatus;
  }

  FusionProgressState copyWith({
    CashFusionStatus? fusionStatus,
    String? address,
  }) {
    return FusionProgressState(
      walletId: walletId,
      walletName: walletName,
      coin: coin,
      fusionStatus: fusionStatus ?? _fusionStatus,
      manager: manager,
      address: this.address,
    );
  }
}

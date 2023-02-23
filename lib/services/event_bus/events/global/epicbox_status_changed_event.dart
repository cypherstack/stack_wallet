import 'package:epicpay/utilities/logger.dart';

enum EpicBoxStatus { unableToConnect, connected /*, listening*/ }

class EpicBoxStatusChangedEvent {
  EpicBoxStatus newStatus;
  String walletId;

  EpicBoxStatusChangedEvent(this.newStatus, this.walletId) {
    Logging.instance.log(
        "EpicBoxStatusChangedEvent fired in $walletId with arg newStatus = $newStatus",
        level: LogLevel.Info);
  }
}

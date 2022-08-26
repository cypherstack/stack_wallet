import 'package:stackwallet/utilities/logger.dart';

class UpdatedInBackgroundEvent {
  String message;
  String walletId;

  UpdatedInBackgroundEvent(this.message, this.walletId) {
    Logging.instance.log(
        "UpdatedInBackgroundEvent fired with message: $message",
        level: LogLevel.Info);
  }
}

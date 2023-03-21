import 'package:stackduo/utilities/logger.dart';

class RefreshPercentChangedEvent {
  double percent;
  String walletId;

  RefreshPercentChangedEvent(this.percent, this.walletId) {
    Logging.instance.log(
        "RefreshPercentChangedEvent fired on $walletId with percent (range of 0.0-1.0)= $percent",
        level: LogLevel.Info);
  }
}

import 'package:stackduo/utilities/logger.dart';

class BlocksRemainingEvent {
  int blocksRemaining;
  String walletId;

  BlocksRemainingEvent(this.blocksRemaining, this.walletId) {
    Logging.instance.log(
        "RefreshPercentChangedEvent fired on $walletId with blocks remaining = $blocksRemaining",
        level: LogLevel.Info);
  }
}

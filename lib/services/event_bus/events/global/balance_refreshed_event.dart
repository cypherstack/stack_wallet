import 'package:stackwallet/utilities/logger.dart';

class BalanceRefreshedEvent {
  final String walletId;

  BalanceRefreshedEvent(this.walletId) {
    Logging.instance.log(
      "BalanceRefreshedEvent fired on $walletId",
      level: LogLevel.Info,
    );
  }
}

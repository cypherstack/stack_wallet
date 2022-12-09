import 'package:epicpay/utilities/enums/coin_enum.dart';
import 'package:epicpay/utilities/logger.dart';

enum WalletSyncStatus { unableToSync, synced, syncing }

class WalletSyncStatusChangedEvent {
  WalletSyncStatus newStatus;
  String walletId;
  Coin coin;

  WalletSyncStatusChangedEvent(this.newStatus, this.walletId, this.coin) {
    Logging.instance.log(
        "WalletSyncStatusChangedEvent fired in $walletId with arg newStatus = $newStatus",
        level: LogLevel.Info);
  }
}

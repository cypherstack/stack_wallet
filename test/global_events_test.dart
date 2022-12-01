import 'package:flutter_test/flutter_test.dart';
import 'package:epicmobile/services/event_bus/events/global/node_connection_status_changed_event.dart';
import 'package:epicmobile/services/event_bus/events/global/refresh_percent_changed_event.dart';
import 'package:epicmobile/services/event_bus/events/global/updated_in_background_event.dart';
import 'package:epicmobile/services/event_bus/events/global/wallet_sync_status_changed_event.dart';
import 'package:epicmobile/services/event_bus/global_event_bus.dart';
import 'package:epicmobile/utilities/enums/coin_enum.dart';

void main() {
  test("NodeConnectionStatusChangedEvent", () async {
    final listener = GlobalEventBus.instance
        .on<NodeConnectionStatusChangedEvent>()
        .listen((event) {
      expect(event.newStatus, NodeConnectionStatus.connected);
      expect(event.walletId, "some wallet ID");
      expect(event.coin, Coin.bitcoin);
    });
    expect(
        () => GlobalEventBus.instance.fire(NodeConnectionStatusChangedEvent(
            NodeConnectionStatus.connected, "some wallet ID", Coin.bitcoin)),
        returnsNormally);
    listener.cancel();
  });

  test("RefreshPercentChangedEvent", () async {
    final listener = GlobalEventBus.instance
        .on<RefreshPercentChangedEvent>()
        .listen((event) {
      expect(event.percent, 0.5);
      expect(event.walletId, "some id");
    });
    expect(
        () => GlobalEventBus.instance
            .fire(RefreshPercentChangedEvent(0.5, "some id")),
        returnsNormally);
    listener.cancel();
  });

  test("UpdatedInBackgroundEvent", () async {
    final listener =
        GlobalEventBus.instance.on<UpdatedInBackgroundEvent>().listen((event) {
      expect(event.message, "some message string");
      expect(event.walletId, "wallet Id");
    });
    expect(
        () => GlobalEventBus.instance
            .fire(UpdatedInBackgroundEvent("some message string", "wallet Id")),
        returnsNormally);
    listener.cancel();
  });

  test("ActiveWalletNameChangedEvent", () async {
    final listener = GlobalEventBus.instance
        .on<WalletSyncStatusChangedEvent>()
        .listen((event) {
      expect(event.newStatus, WalletSyncStatus.syncing);
      expect(event.walletId, "wallet Id");
      expect(event.coin, Coin.bitcoin);
    });
    expect(
        () => GlobalEventBus.instance.fire(WalletSyncStatusChangedEvent(
            WalletSyncStatus.syncing, "wallet Id", Coin.bitcoin)),
        returnsNormally);
    listener.cancel();
  });
}

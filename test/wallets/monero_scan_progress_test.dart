import 'package:compat/compat.dart' show SyncedSyncStatus, SyncingSyncStatus;
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/address.dart';
import 'package:stackwallet/services/event_bus/events/global/blocks_remaining_event.dart';
import 'package:stackwallet/services/event_bus/events/global/wallet_sync_status_changed_event.dart';
import 'package:stackwallet/services/event_bus/global_event_bus.dart';
import 'package:stackwallet/wallets/crypto_currency/crypto_currency.dart';
import 'package:stackwallet/wallets/isar/models/wallet_info.dart';
import 'package:stackwallet/wallets/wallet/impl/monero_wallet.dart';

class _Wallet extends MoneroWallet {
  _Wallet() : super(CryptoCurrencyNetwork.main);

  @override
  String get walletId => 'sync-test';

  @override
  late final info = WalletInfo(
    walletId: walletId,
    name: 'XMR',
    mainAddressType: AddressType.cryptonote,
    coinName: cryptoCurrency.identifier,
  );

  @override
  Future<void> updateChainHeight() async {}

  // Keep the asynchronous history refresh pending while delivering scan events.
  @override
  Future<void> updateTransactions() =>
      Future<void>.delayed(const Duration(seconds: 1));
}

void main() {
  test('XMR publishes syncing until the scan reaches the current tip', () {
    fakeAsync((clock) {
      final wallet = _Wallet();
      final statuses = <WalletSyncStatus>[];
      final blocks = <int>[];
      final statusSubscription = GlobalEventBus.instance
          .on<WalletSyncStatusChangedEvent>()
          .listen((event) => statuses.add(event.newStatus));
      final blocksSubscription = GlobalEventBus.instance
          .on<BlocksRemainingEvent>()
          .listen((event) => blocks.add(event.blocksRemaining));

      wallet.onSyncingUpdate(syncHeight: 0, nodeHeight: 0);
      wallet.onSyncingUpdate(syncHeight: 101, nodeHeight: 100);
      expect(wallet.syncStatus, isNull);
      wallet.onSyncingUpdate(syncHeight: 1, nodeHeight: 100);
      wallet.onSyncingUpdate(syncHeight: 99, nodeHeight: 100);
      expect(wallet.currentKnownChainHeight, 100);
      expect(wallet.syncStatus!.progress(), .99);
      wallet.onSyncingUpdate(syncHeight: 100, nodeHeight: 100);
      expect(wallet.syncStatus, isA<SyncedSyncStatus>());
      wallet.onSyncingUpdate(syncHeight: 100, nodeHeight: 101);
      expect(wallet.syncStatus, isA<SyncingSyncStatus>());
      clock.flushMicrotasks();

      expect(statuses, [
        WalletSyncStatus.syncing,
        WalletSyncStatus.syncing,
        WalletSyncStatus.synced,
        WalletSyncStatus.syncing,
      ]);
      expect(blocks, [99, 1, 0, 1]);
      statusSubscription.cancel();
      blocksSubscription.cancel();
    });
  });
}

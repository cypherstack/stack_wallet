import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:stackwallet/providers/providers.dart';
import 'package:stackwallet/services/event_bus/events/global/crypto_notification_event.dart';
import 'package:stackwallet/services/notifications_service.dart';
import 'package:stackwallet/wallets/crypto_currency/crypto_currency.dart';
import 'package:stackwallet/widgets/crypto_notifications.dart';

import '../screen_tests/exchange/exchange_view_test.mocks.dart' show MockPrefs;
import 'transaction_card_test.mocks.dart' show MockWallets;

class _Notifications extends Mock implements NotificationsService {}

void main() {
  testWidgets('acknowledges without publishing a deleted or hidden wallet', (
    tester,
  ) async {
    final wallets = MockWallets();
    when(wallets.wallets).thenReturn([]);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          pWallets.overrideWithValue(wallets),
          prefsChangeNotifierProvider.overrideWithProvider(
            ChangeNotifierProvider((_) => MockPrefs()),
          ),
          notificationsProvider.overrideWithProvider(
            ChangeNotifierProvider((_) => _Notifications()),
          ),
        ],
        child: const MaterialApp(home: CryptoNotifications(child: SizedBox())),
      ),
    );
    final event = CryptoNotificationEvent(
      title: 'Incoming transaction',
      walletId: 'deleted-or-hidden',
      walletName: 'Private wallet name',
      date: DateTime(2026),
      shouldWatchForUpdates: false,
      coin: Bitcoin(CryptoCurrencyNetwork.main),
    );
    CryptoNotificationsEventBus.instance.fire(event);
    await tester.pump();
    await expectLater(event.delivered, completes);
    // No notification platform/channel or icon providers are installed. A
    // publication attempt would fail instead of acknowledging this event.
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    expect(CryptoNotificationsEventBus.hasListeners, isFalse);
  });
}

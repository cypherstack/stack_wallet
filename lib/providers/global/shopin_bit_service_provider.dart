import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../db/drift/shared_db/shared_database.dart';
import '../../db/drift/shared_db/tables/notifications.dart';
import '../../external_api_keys.dart';
import '../../services/shopinbit/shopinbit_api.dart';
import '../../services/shopinbit/shopinbit_service.dart';
import '../db/drift_provider.dart';
import 'notifications_provider.dart';

final pShopinBitService = Provider(
  (ref) => ShopInBitService(
    client: ShopInBitClient(
      accessKey: kShopInBitAccessKey,
      partnerSecret: kShopInBitPartnerSecret,
      sandbox: false,
    ),
    db: ref.watch(pSharedDrift),
  ),
);

/// The active customer key's settings row (or null if none yet).
final pShopInBitSettings = StreamProvider.autoDispose<ShopInBitSetting?>(
  (ref) => ref.watch(pSharedDrift).shopInBitSettingsDao.watchCurrentSettings(),
);

/// All tickets for the active customer key, newest first. Watches the key so
/// a key created after startup or switched at runtime re-scopes the list.
final pShopInBitTickets = StreamProvider.autoDispose<List<ShopInBitTicket>>((
  ref,
) {
  final customerKey = ref.watch(_pShopInBitCustomerKey);
  if (customerKey == null) {
    return Stream.value(const <ShopInBitTicket>[]);
  }
  return ref
      .watch(pSharedDrift)
      .shopInBitTicketsDao
      .watchByCustomerKey(customerKey);
});

final pShopInBitTicket = StreamProvider.autoDispose
    .family<ShopInBitTicket?, int>(
      (ref, apiTicketId) =>
          ref.watch(pSharedDrift).shopInBitTicketsDao.watchByApiId(apiTicketId),
    );

final _pShopInBitCustomerKey = Provider.autoDispose<String?>(
  (ref) =>
      ref.watch(pShopInBitSettings.select((s) => s.asData?.value?.customerKey)),
);

/// ShopinBit notifications for the active customer key, newest first (feed).
final pShopInBitNotifications =
    StreamProvider.autoDispose<List<AppNotification>>((ref) {
      final customerKey = ref.watch(_pShopInBitCustomerKey);
      if (customerKey == null) {
        return Stream.value(const <AppNotification>[]);
      }
      return ref
          .watch(pSharedDrift)
          .appNotificationsDao
          .watchByScope(AppNotificationType.shopinbit, customerKey);
    });

/// Unread ShopinBit notification count for the active customer key (bell).
final pShopInBitNotificationUnreadCount = StreamProvider.autoDispose<int>((
  ref,
) {
  final customerKey = ref.watch(_pShopInBitCustomerKey);
  if (customerKey == null) {
    return Stream.value(0);
  }
  return ref
      .watch(pSharedDrift)
      .appNotificationsDao
      .watchUnreadCount(
        type: AppNotificationType.shopinbit,
        scopeId: customerKey,
      );
});

/// True when the global notifications bell should light: any unread Hive
/// notification, or any unread ShopinBit notification for the active key.
final pAnyGlobalUnreadNotifications = Provider.autoDispose<bool>((ref) {
  final hive = ref.watch(
    notificationsProvider.select((value) => value.hasUnreadNotifications),
  );
  final sib =
      (ref.watch(pShopInBitNotificationUnreadCount).asData?.value ?? 0) > 0;
  return hive || sib;
});

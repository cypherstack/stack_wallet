import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../db/drift/shared_db/shared_database.dart';
import '../../notifications/notification_feed_entry.dart';
import '../global/notifications_provider.dart';
import '../global/shopin_bit_service_provider.dart';

/// The merged notification feed, newest first, shared by the mobile and
/// desktop notifications views. Pass a walletId to scope the list to that
/// wallet's Hive notifications (ShopinBit rows are account-level, not
/// per-wallet, so they only appear in the global feed); null is the global
/// feed.
final pNotificationFeed = Provider.autoDispose
    .family<List<NotificationFeedEntry>, String?>((ref, walletId) {
      final all = ref.watch(
        notificationsProvider.select((value) => value.notifications),
      );
      final hive = walletId == null
          ? all
          : all
                .where((element) => element.walletId == walletId)
                .toList(growable: false);
      final sib = walletId == null
          ? (ref.watch(pShopInBitNotifications).asData?.value ??
                const <AppNotification>[])
          : const <AppNotification>[];
      return mergeNotificationFeed(hive, sib);
    });

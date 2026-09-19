import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/ui/unread_notifications_provider.dart';
import 'notification_card.dart';
import 'notification_feed_entry.dart';
import 'shopinbit_notification_card.dart';

class NotificationFeedEntryCard extends ConsumerWidget {
  const NotificationFeedEntryCard({super.key, required this.entry});

  final NotificationFeedEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entry = this.entry;
    if (entry is HiveFeedEntry && entry.model.read == false) {
      ref
          .read(unreadNotificationsStateProvider.state)
          .state
          .add(entry.model.id);
    }

    return switch (entry) {
      HiveFeedEntry e => NotificationCard(notification: e.model),
      AppFeedEntry e => ShopInBitNotificationCard(notification: e.notification),
    };
  }
}

import '../db/drift/shared_db/shared_database.dart';
import '../models/notification_model.dart';

sealed class NotificationFeedEntry {
  DateTime get date;
}

class HiveFeedEntry extends NotificationFeedEntry {
  HiveFeedEntry(this.model);
  final NotificationModel model;
  @override
  DateTime get date => model.date;
}

class AppFeedEntry extends NotificationFeedEntry {
  AppFeedEntry(this.notification);
  final AppNotification notification;
  @override
  DateTime get date => notification.createdAt;
}

List<NotificationFeedEntry> mergeNotificationFeed(
  List<NotificationModel> hive,
  List<AppNotification> app,
) {
  return <NotificationFeedEntry>[
    ...hive.map(HiveFeedEntry.new),
    ...app.map(AppFeedEntry.new),
  ]..sort((a, b) => b.date.compareTo(a.date));
}

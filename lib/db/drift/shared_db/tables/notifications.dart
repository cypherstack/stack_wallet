import "package:drift/drift.dart";

import "shopin_bit_tickets.dart";

enum AppNotificationType { shopinbit }

@TableIndex(name: "app_notifications_scope", columns: {#type, #scopeId, #read})
@TableIndex(name: "app_notifications_target", columns: {#type, #targetId})
class AppNotifications extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get type => textEnum<AppNotificationType>()();

  TextColumn get title => text()();
  TextColumn get body => text().withDefault(const Constant(""))();
  TextColumn get iconAsset => text().nullable()();

  TextColumn get createdAt => text()
      .map(ShopInBitTickets.dateConverter)
      .clientDefault(
        () => ShopInBitTickets.dateConverter.toSql(DateTime.now()),
      )();
  BoolColumn get read => boolean().withDefault(const Constant(false))();

  TextColumn get scopeId => text().nullable()();
  TextColumn get targetId => text().nullable()();
}

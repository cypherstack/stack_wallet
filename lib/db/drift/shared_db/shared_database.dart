import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path/path.dart' as path;

import "../../../models/shopinbit/shopinbit_enums.dart";
import "../../../services/shopinbit/src/models/message.dart";
import '../../../utilities/stack_file_system.dart';
import 'tables/cakepay_orders.dart';
import 'tables/notifications.dart';
import 'tables/shopin_bit_settings.dart';
import 'tables/shopin_bit_tickets.dart';

part 'shared_database.g.dart';

abstract final class SharedDrift {
  static bool _didInit = false;

  static SharedDatabase? _db;

  static SharedDatabase get() {
    if (!_didInit) {
      driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
      _didInit = true;
    }

    return _db ??= SharedDatabase._();
  }
}

@DriftDatabase(
  tables: [
    CakepayOrders,
    ShopInBitSettings,
    ShopInBitTickets,
    AppNotifications,
  ],
  daos: [ShopInBitSettingsDao, ShopInBitTicketsDao, AppNotificationsDao],
)
final class SharedDatabase extends _$SharedDatabase {
  SharedDatabase._([QueryExecutor? executor])
    : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.createTable(shopInBitSettings);
        await m.createTable(shopInBitTickets);
        await m.createTable(appNotifications);
        await m.createIndex(appNotificationsScope);
        await m.createIndex(appNotificationsTarget);
      }
    },
  );

  static QueryExecutor _openConnection() {
    return driftDatabase(
      name: "shared",
      native: DriftNativeOptions(
        shareAcrossIsolates: true,
        databasePath: () async {
          final dir = await StackFileSystem.applicationDriftDirectory();
          return path.join(dir.path, "shared", "shared.db");
        },
      ),
    );
  }
}

@DriftAccessor(tables: [ShopInBitTickets])
class ShopInBitTicketsDao extends DatabaseAccessor<SharedDatabase>
    with _$ShopInBitTicketsDaoMixin {
  ShopInBitTicketsDao(super.db);

  // -- Reads --

  Future<ShopInBitTicket?> getByApiId(int apiTicketId) {
    return (select(
      shopInBitTickets,
    )..where((t) => t.apiTicketId.equals(apiTicketId))).getSingleOrNull();
  }

  Stream<ShopInBitTicket?> watchByApiId(int apiTicketId) {
    return (select(
      shopInBitTickets,
    )..where((t) => t.apiTicketId.equals(apiTicketId))).watchSingleOrNull();
  }

  /// All tickets for the active customer key, newest first.
  Stream<List<ShopInBitTicket>> watchByCustomerKey(String customerKey) {
    return (select(shopInBitTickets)
          ..where((t) => t.customerKey.equals(customerKey))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .watch();
  }

  // -- Writes --

  /// Insert a brand-new ticket. Caller must supply every required field;
  /// pass nullable fields through the companion's `Value(...)` wrappers.
  Future<void> insertTicket(ShopInBitTicketsCompanion companion) async {
    await into(shopInBitTickets).insert(companion);
  }

  /// Patch an existing ticket. Use `Value.absent()` (the companion default)
  /// for fields you don't want to touch. Returns true if a row was updated.
  Future<bool> updateTicket(
    int apiTicketId,
    ShopInBitTicketsCompanion patch,
  ) async {
    final int rows = await (update(
      shopInBitTickets,
    )..where((t) => t.apiTicketId.equals(apiTicketId))).write(patch);
    return rows > 0;
  }

  Future<bool> markRead(int apiTicketId, [DateTime? readAt]) async {
    final int rows =
        await (update(shopInBitTickets)..where(
              (t) =>
                  t.apiTicketId.equals(apiTicketId) &
                  t.lastAgentMessageAt.isNotNull() &
                  (t.lastReadAt.isNull() |
                      t.lastAgentMessageAt.isBiggerThan(t.lastReadAt)),
            ))
            .write(
              ShopInBitTicketsCompanion(
                lastReadAt: Value(readAt ?? DateTime.now().toUtc()),
              ),
            );
    return rows > 0;
  }

  Future<int> deleteByApiId(int apiTicketId) {
    return (delete(
      shopInBitTickets,
    )..where((t) => t.apiTicketId.equals(apiTicketId))).go();
  }

  Future<int> deleteByCustomerKey(String customerKey) {
    return (delete(
      shopInBitTickets,
    )..where((t) => t.customerKey.equals(customerKey))).go();
  }
}

@DriftAccessor(tables: [AppNotifications])
class AppNotificationsDao extends DatabaseAccessor<SharedDatabase>
    with _$AppNotificationsDaoMixin {
  AppNotificationsDao(super.db);

  Stream<List<AppNotification>> watchByScope(
    AppNotificationType type,
    String scopeId,
  ) {
    return (select(appNotifications)
          ..where((t) => t.type.equalsValue(type) & t.scopeId.equals(scopeId))
          ..orderBy([
            (t) => OrderingTerm.desc(t.createdAt),
            (t) => OrderingTerm.desc(t.id),
          ]))
        .watch();
  }

  Expression<bool> _unreadScope({AppNotificationType? type, String? scopeId}) {
    Expression<bool> pred = appNotifications.read.equals(false);
    if (type != null) {
      pred = pred & appNotifications.type.equalsValue(type);
    }
    if (scopeId != null) {
      pred = pred & appNotifications.scopeId.equals(scopeId);
    }
    return pred;
  }

  Stream<int> watchUnreadCount({AppNotificationType? type, String? scopeId}) {
    final count = countAll();
    final query = selectOnly(appNotifications)
      ..addColumns([count])
      ..where(_unreadScope(type: type, scopeId: scopeId));
    return query.watchSingle().map((row) => row.read(count) ?? 0);
  }

  Future<void> add(AppNotificationsCompanion row) async {
    await into(appNotifications).insert(row);
  }

  Future<int> markReadByTarget(AppNotificationType type, String targetId) {
    return (update(appNotifications)..where(
          (t) =>
              t.type.equalsValue(type) &
              t.targetId.equals(targetId) &
              t.read.equals(false),
        ))
        .write(const AppNotificationsCompanion(read: Value(true)));
  }

  /// Mark all unread notifications read, optionally scoped to [type]/[scopeId].
  Future<int> markAllRead({AppNotificationType? type, String? scopeId}) {
    return (update(appNotifications)
          ..where((_) => _unreadScope(type: type, scopeId: scopeId)))
        .write(const AppNotificationsCompanion(read: Value(true)));
  }

  Future<void> pruneScope(
    AppNotificationType type,
    String scopeId, {
    int keep = 200,
  }) async {
    final rows =
        await (select(appNotifications)
              ..where(
                (t) => t.type.equalsValue(type) & t.scopeId.equals(scopeId),
              )
              ..orderBy([(t) => OrderingTerm.desc(t.id)]))
            .get();
    if (rows.length <= keep) return;
    final prunable = rows
        .skip(keep)
        .where((r) => r.read)
        .map((r) => r.id)
        .toList();
    if (prunable.isEmpty) return;
    await (delete(appNotifications)..where((t) => t.id.isIn(prunable))).go();
  }
}

@DriftAccessor(tables: [ShopInBitSettings])
class ShopInBitSettingsDao extends DatabaseAccessor<SharedDatabase>
    with _$ShopInBitSettingsDaoMixin {
  ShopInBitSettingsDao(super.db);

  // -- "Current" (= most-recently-used) row --

  /// Returns the settings row for the most-recently-used customer key,
  /// or null if the user has never generated/recovered one.
  Future<ShopInBitSetting?> getCurrentSettings() {
    return (select(shopInBitSettings)
          ..orderBy([(t) => OrderingTerm.desc(t.lastUsedAt)])
          ..limit(1))
        .getSingleOrNull();
  }

  Stream<ShopInBitSetting?> watchCurrentSettings() {
    return (select(shopInBitSettings)
          ..orderBy([(t) => OrderingTerm.desc(t.lastUsedAt)])
          ..limit(1))
        .watchSingleOrNull();
  }

  // -- Specific row by customer key --

  Future<ShopInBitSetting?> getByKey(String customerKey) {
    return (select(
      shopInBitSettings,
    )..where((t) => t.customerKey.equals(customerKey))).getSingleOrNull();
  }

  Stream<ShopInBitSetting?> watchByKey(String customerKey) {
    return (select(
      shopInBitSettings,
    )..where((t) => t.customerKey.equals(customerKey))).watchSingleOrNull();
  }

  Stream<List<ShopInBitSetting>> watchAll() {
    return (select(
      shopInBitSettings,
    )..orderBy([(t) => OrderingTerm.desc(t.lastUsedAt)])).watch();
  }

  // -- Writes --

  /// Insert if missing, otherwise bump [lastUsedAt]. Returns the row.
  Future<ShopInBitSetting> upsert(String customerKey) {
    final DateTime now = DateTime.now();
    return into(shopInBitSettings).insertReturning(
      ShopInBitSettingsCompanion.insert(
        customerKey: customerKey,
        createdAt: Value(now),
        lastUsedAt: Value(now),
      ),
      onConflict: DoUpdate(
        (_) => ShopInBitSettingsCompanion(lastUsedAt: Value(now)),
        target: [shopInBitSettings.customerKey],
      ),
    );
  }

  Future<int> touch(String customerKey) => _write(
    customerKey,
    ShopInBitSettingsCompanion(lastUsedAt: Value(DateTime.now())),
  );

  Future<int> setPrivacyAccepted(String customerKey, bool value) => _write(
    customerKey,
    ShopInBitSettingsCompanion(privacyAccepted: Value(value)),
  );

  Future<int> setGuidelinesAccepted(
    String customerKey,
    ShopInBitCategory category,
    bool value,
  ) {
    final ShopInBitSettingsCompanion patch = switch (category) {
      .concierge => ShopInBitSettingsCompanion(
        conciergeGuidelinesAccepted: Value(value),
      ),
      .travel => ShopInBitSettingsCompanion(
        travelGuidelinesAccepted: Value(value),
      ),
      .car => ShopInBitSettingsCompanion(carGuidelinesAccepted: Value(value)),
    };
    return _write(customerKey, patch);
  }

  Future<int> setSetupComplete(String customerKey, bool value) => _write(
    customerKey,
    ShopInBitSettingsCompanion(setupComplete: Value(value)),
  );

  Future<int> deleteByKey(String customerKey) {
    return (delete(
      shopInBitSettings,
    )..where((t) => t.customerKey.equals(customerKey))).go();
  }

  Future<int> _write(String customerKey, ShopInBitSettingsCompanion changes) {
    return (update(
      shopInBitSettings,
    )..where((t) => t.customerKey.equals(customerKey))).write(changes);
  }
}

extension ShopInBitSettingGuidelines on ShopInBitSetting {
  bool guidelinesAcceptedFor(ShopInBitCategory category) => switch (category) {
    .concierge => conciergeGuidelinesAccepted,
    .travel => travelGuidelinesAccepted,
    .car => carGuidelinesAccepted,
  };
}

extension ShopInBitTicketUnread on ShopInBitTicket {
  bool get hasUnreadAgentMessage {
    final DateTime? lastAgent = lastAgentMessageAt;
    if (lastAgent == null) return false;
    final DateTime? read = lastReadAt;
    return read == null || lastAgent.isAfter(read);
  }
}

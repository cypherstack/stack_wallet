import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path/path.dart' as path;

import "../../../models/shopinbit/shopinbit_enums.dart";
import "../../../services/shopinbit/src/models/message.dart";
import '../../../utilities/stack_file_system.dart';
import 'tables/cakepay_orders.dart';
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
  tables: [CakepayOrders, ShopInBitSettings, ShopInBitTickets],
  daos: [ShopInBitSettingsDao, ShopInBitTicketsDao],
)
final class SharedDatabase extends _$SharedDatabase {
  SharedDatabase._([QueryExecutor? executor])
    : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (m, from, to) async {
      if (from == 1 && to == 2) {
        await m.createTable(shopInBitSettings);
        await m.createTable(shopInBitTickets);
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

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path/path.dart' as path;

import '../../../models/shopinbit/shopinbit_order_model.dart'
    show ShopInBitCategory, ShopInBitOrderStatus;
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
  tables: [CakepayOrders, ShopinBitSettings, ShopInBitTickets],
  daos: [ShopinBitSettingsDao],
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
        await m.createTable(shopinBitSettings);
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

@DriftAccessor(tables: [ShopinBitSettings])
class ShopinBitSettingsDao extends DatabaseAccessor<SharedDatabase>
    with _$ShopinBitSettingsDaoMixin {
  ShopinBitSettingsDao(super.db);

  Future<ShopinBitSetting> getSettings() async {
    final ShopinBitSetting? row = await (select(
      shopinBitSettings,
    )..where((t) => t.id.equals(0))).getSingleOrNull();
    if (row != null) return row;

    return into(
      shopinBitSettings,
    ).insertReturning(ShopinBitSettingsCompanion.insert(id: const Value(0)));
  }

  Future<void> setGuidelinesAccepted(bool accepted) =>
      _update(ShopinBitSettingsCompanion(guidelinesAccepted: Value(accepted)));

  Future<void> setSetupComplete(bool complete) =>
      _update(ShopinBitSettingsCompanion(setupComplete: Value(complete)));

  Future<void> setDisplayName(String name) =>
      _update(ShopinBitSettingsCompanion(displayName: Value(name)));

  Future<void> _update(ShopinBitSettingsCompanion changes) async {
    await getSettings(); // ensure row exists
    await (update(
      shopinBitSettings,
    )..where((t) => t.id.equals(0))).write(changes);
  }
}

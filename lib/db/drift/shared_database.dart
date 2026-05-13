import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path/path.dart' as path;

import '../../utilities/stack_file_system.dart';

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

class CakepayOrders extends Table {
  TextColumn get orderId => text()();

  @override
  Set<Column> get primaryKey => {orderId};
}

@DriftDatabase(tables: [CakepayOrders])
final class SharedDatabase extends _$SharedDatabase {
  SharedDatabase._([QueryExecutor? executor])
    : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 1;

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

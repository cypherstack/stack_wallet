import 'package:drift/drift.dart';

class ShopinBitSettings extends Table {
  // Single row table - always row 0
  IntColumn get id => integer().withDefault(const Constant(0))();

  BoolColumn get guidelinesAccepted =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get setupComplete =>
      boolean().withDefault(const Constant(false))();
  TextColumn get displayName => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

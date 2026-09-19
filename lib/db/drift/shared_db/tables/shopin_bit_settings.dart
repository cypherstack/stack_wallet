import "package:drift/drift.dart";

/// One row per ShopinBit customer key the user has ever generated or
/// recovered. Whichever row has the most recent `lastUsedAt` is the
/// "current" key — see `ShopInBitSettingsDao.getCurrentSettings`.
class ShopInBitSettings extends Table {
  TextColumn get customerKey => text()();

  BoolColumn get privacyAccepted =>
      boolean().withDefault(const Constant(false))();

  BoolColumn get conciergeGuidelinesAccepted =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get travelGuidelinesAccepted =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get carGuidelinesAccepted =>
      boolean().withDefault(const Constant(false))();

  BoolColumn get setupComplete =>
      boolean().withDefault(const Constant(false))();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get lastUsedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {customerKey};

  @override
  bool get withoutRowId => true;
}

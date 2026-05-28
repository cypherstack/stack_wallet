import 'package:drift/drift.dart';

class CakepayOrders extends Table {
  TextColumn get orderId => text()();

  @override
  Set<Column> get primaryKey => {orderId};
}

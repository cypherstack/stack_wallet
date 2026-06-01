import "dart:convert";

import "package:drift/drift.dart";

import "../../../../models/shopinbit/shopinbit_enums.dart";
import "../../../../services/shopinbit/src/models/message.dart";

class ShopInBitTickets extends Table {
  IntColumn get apiTicketId => integer()();
  TextColumn get customerKey => text()();
  TextColumn get ticketNumber => text()();

  TextColumn get category => textEnum<ShopInBitCategory>()();
  TextColumn get requestDescription => text()();
  TextColumn get deliveryCountry => text()();

  TextColumn get status => textEnum<ShopInBitOrderStatus>()();
  TextColumn get statusRaw => text()();

  TextColumn get offerProductName => text().nullable()();
  TextColumn get offerPrice => text().nullable()();

  TextColumn get paymentInvoiceStatus => text().nullable()();
  TextColumn get trackingLink => text().nullable()();
  DateTimeColumn get lastAgentMessageAt => dateTime().nullable()();

  TextColumn get feeTicketNumber => text().nullable()();

  TextColumn get messages =>
      text().map(const MessagesConverter()).withDefault(const Constant("[]"))();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {apiTicketId};

  @override
  bool get withoutRowId => true;
}

/// Drift TypeConverter so `messages` round-trips between a JSON column and
/// `List<TicketMessage>` on the generated data class.
class MessagesConverter extends TypeConverter<List<TicketMessage>, String> {
  const MessagesConverter();

  @override
  List<TicketMessage> fromSql(String fromDb) {
    final List<dynamic> raw = jsonDecode(fromDb) as List<dynamic>;
    return raw
        .map((e) => TicketMessage.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
  }

  @override
  String toSql(List<TicketMessage> value) {
    return jsonEncode(value.map((m) => m.toMap()).toList());
  }
}

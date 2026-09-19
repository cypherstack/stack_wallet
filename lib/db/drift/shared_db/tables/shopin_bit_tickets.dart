import "dart:convert";

import "package:drift/drift.dart";

import "../../../../models/shopinbit/shopinbit_enums.dart";
import "../../../../services/shopinbit/src/models/message.dart";
import "../../../../utilities/logger.dart";

class ShopInBitTickets extends Table {
  static const dateConverter = Iso8601UtcConverter();

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
  TextColumn get lastAgentMessageAt =>
      text().nullable().map(ShopInBitTickets.dateConverter)();

  TextColumn get feeTicketNumber => text().nullable()();

  TextColumn get messages =>
      text().map(const MessagesConverter()).withDefault(const Constant("[]"))();

  TextColumn get createdAt => text()
      .map(ShopInBitTickets.dateConverter)
      .clientDefault(
        () => ShopInBitTickets.dateConverter.toSql(DateTime.now()),
      )();
  TextColumn get updatedAt => text()
      .map(ShopInBitTickets.dateConverter)
      .clientDefault(
        () => ShopInBitTickets.dateConverter.toSql(DateTime.now()),
      )();

  TextColumn get lastReadAt =>
      text().nullable().map(ShopInBitTickets.dateConverter)();

  @override
  Set<Column<Object>> get primaryKey => {apiTicketId};

  @override
  bool get withoutRowId => true;
}

class Iso8601UtcConverter extends TypeConverter<DateTime, String> {
  const Iso8601UtcConverter();

  @override
  DateTime fromSql(String fromDb) => DateTime.parse(fromDb).toUtc();

  @override
  String toSql(DateTime value) => DateTime.fromMillisecondsSinceEpoch(
    value.toUtc().millisecondsSinceEpoch,
    isUtc: true,
  ).toIso8601String();
}

/// Drift TypeConverter so `messages` round-trips between a JSON column and
/// `List<TicketMessage>` on the generated data class.
class MessagesConverter extends TypeConverter<List<TicketMessage>, String> {
  const MessagesConverter();

  @override
  List<TicketMessage> fromSql(String fromDb) {
    final List<dynamic> raw = jsonDecode(fromDb) as List<dynamic>;
    // Skip any message that fails to parse rather than dropping the whole
    // conversation; mirrors the tolerant parse on the network side.
    final messages = <TicketMessage>[];
    for (final e in raw) {
      try {
        messages.add(TicketMessage.fromJson(e as Map<String, dynamic>));
      } catch (err, s) {
        Logging.instance.w(
          "MessagesConverter skipping malformed message",
          error: err,
          stackTrace: s,
        );
      }
    }
    return List<TicketMessage>.unmodifiable(messages);
  }

  @override
  String toSql(List<TicketMessage> value) {
    return jsonEncode(value.map((m) => m.toMap()).toList());
  }
}

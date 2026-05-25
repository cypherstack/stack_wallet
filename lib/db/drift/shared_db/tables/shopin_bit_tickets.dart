import "dart:convert";

import "package:drift/drift.dart";

import '../../../../models/shopinbit/shopinbit_order_model.dart'
    show ShopInBitCategory, ShopInBitOrderStatus;

class ShopInBitTickets extends Table {
  TextColumn get ticketId => text()();

  TextColumn get displayName => text()();

  IntColumn get category => intEnum<ShopInBitCategory>()();
  IntColumn get status => intEnum<ShopInBitOrderStatus>()();

  TextColumn get requestDescription => text()();
  TextColumn get deliveryCountry => text()();
  TextColumn get offerProductName => text().nullable()();
  TextColumn get offerPrice => text().nullable()();

  TextColumn get shippingName => text()();
  TextColumn get shippingStreet => text()();
  TextColumn get shippingCity => text()();
  TextColumn get shippingPostalCode => text()();
  TextColumn get shippingCountry => text()();

  TextColumn get paymentMethod => text().nullable()();

  TextColumn get messages =>
      text().map(const ShopInBitTicketMessagesConverter())();

  DateTimeColumn get createdAt => dateTime()();
  IntColumn get apiTicketId => integer()();

  // Car research retry support
  TextColumn get carResearchInvoiceId => text().nullable()();
  TextColumn get feeTicketNumber => text().nullable()();
  BoolColumn get needsCreateRequest => boolean()();

  // Car research resumable payment state
  BoolColumn get isPendingPayment => boolean()();
  DateTimeColumn get carResearchExpiresAt => dateTime().nullable()();
  TextColumn get carResearchPaymentLinks => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {ticketId};
}

class ShopInBitTicketMessage {
  final String text;
  final DateTime timestamp;
  final bool isFromUser;

  const ShopInBitTicketMessage({
    required this.text,
    required this.timestamp,
    required this.isFromUser,
  });

  factory ShopInBitTicketMessage.fromJson(Map<String, dynamic> json) {
    return ShopInBitTicketMessage(
      text: json["text"] as String,
      timestamp: DateTime.parse(json["timestamp"] as String),
      isFromUser: json["isFromUser"] as bool,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      "text": text,
      "timestamp": timestamp.toIso8601String(),
      "isFromUser": isFromUser,
    };
  }

  @override
  String toString() => toMap().toString();
}

class ShopInBitTicketMessagesConverter
    extends TypeConverter<List<ShopInBitTicketMessage>, String>
    with
        JsonTypeConverter2<
          List<ShopInBitTicketMessage>,
          String,
          List<dynamic>
        > {
  const ShopInBitTicketMessagesConverter();

  @override
  List<ShopInBitTicketMessage> fromSql(String fromDb) {
    final List<dynamic> decoded = jsonDecode(fromDb) as List<dynamic>;
    return fromJson(decoded);
  }

  @override
  String toSql(List<ShopInBitTicketMessage> value) {
    return jsonEncode(toJson(value));
  }

  @override
  List<ShopInBitTicketMessage> fromJson(List<dynamic> json) {
    return json
        .map((e) => ShopInBitTicketMessage.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  List<dynamic> toJson(List<ShopInBitTicketMessage> value) {
    return value.map((m) => m.toMap()).toList();
  }
}

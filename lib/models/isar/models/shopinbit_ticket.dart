import 'package:isar_community/isar.dart';

import '../../shopinbit/shopinbit_order_model.dart';

part 'shopinbit_ticket.g.dart';

@collection
class ShopInBitTicket {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String ticketId;

  late String displayName;
  @enumerated
  late ShopInBitCategory category;
  @enumerated
  late ShopInBitOrderStatus status;
  late String requestDescription;
  late String deliveryCountry;
  late String? offerProductName;
  late String? offerPrice;
  late String shippingName;
  late String shippingStreet;
  late String shippingCity;
  late String shippingPostalCode;
  late String shippingCountry;
  late String? paymentMethod;
  late List<ShopInBitTicketMessage> messages;
  late DateTime createdAt;
  late int apiTicketId;

  // Car research retry support
  String? carResearchInvoiceId;
  String? feeTicketNumber;
  late bool needsCreateRequest;

  // Car research resumable payment state
  late bool isPendingPayment;
  DateTime? carResearchExpiresAt;
  String? carResearchPaymentLinks;
}

@embedded
class ShopInBitTicketMessage {
  late String text;
  late DateTime timestamp;
  late bool isFromUser;

  ShopInBitTicketMessage();
}

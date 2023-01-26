import 'package:stackwallet/models/buy/response_objects/quote.dart';

class SimplexOrder {
  final SimplexQuote quote;

  late final String paymentId;
  late final String orderId;
  late final String userId;
  // TODO remove after userIds are sourced from isar/storage

  SimplexOrder({
    required this.quote,
    required this.paymentId,
    required this.orderId,
    required this.userId,
  });
}

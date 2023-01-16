import 'package:decimal/decimal.dart';
import 'package:stackwallet/models/buy/response_objects/crypto.dart';
import 'package:stackwallet/models/buy/response_objects/fiat.dart';

class SimplexQuote {
  // todo: this class

  final Crypto crypto;
  final Fiat fiat;

  final Decimal youPayFiatPrice;
  final Decimal youReceiveCryptoAmount;

  final String purchaseId;
  final String receivingAddress;

  SimplexQuote({
    required this.crypto,
    required this.fiat,
    required this.youPayFiatPrice,
    required this.youReceiveCryptoAmount,
    required this.purchaseId,
    required this.receivingAddress,
  });
}

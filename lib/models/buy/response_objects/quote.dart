import 'package:decimal/decimal.dart';
import 'package:stackwallet/models/buy/response_objects/crypto.dart';
import 'package:stackwallet/models/buy/response_objects/fiat.dart';

class SimplexQuote {
  // todo: this class

  final Crypto crypto;
  final Fiat fiat;

  late final Decimal youPayFiatPrice;
  late final Decimal youReceiveCryptoAmount;

  late final String id;
  late final String receivingAddress;

  late final bool buyWithFiat;

  SimplexQuote(
      {required this.crypto,
      required this.fiat,
      required this.youPayFiatPrice,
      required this.youReceiveCryptoAmount,
      required this.id,
      required this.receivingAddress,
      required this.buyWithFiat});
}

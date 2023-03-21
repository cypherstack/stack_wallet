import 'package:stackduo/exceptions/exchange/exchange_exception.dart';

class UnsupportedCurrencyException extends ExchangeException {
  UnsupportedCurrencyException(super.message, super.type, this.currency);

  final String currency;
}

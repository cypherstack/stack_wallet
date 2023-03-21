import 'package:stackduo/exceptions/exchange/exchange_exception.dart';

class ExchangeResponse<T> {
  late final T? value;
  late final ExchangeException? exception;

  ExchangeResponse({this.value, this.exception});

  @override
  String toString() {
    return "{error: $exception, value: $value}";
  }
}

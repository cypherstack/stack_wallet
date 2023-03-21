import 'package:stackduo/exceptions/sw_exception.dart';

enum ExchangeExceptionType { generic, serializeResponseError, orderNotFound }

class ExchangeException extends SWException {
  ExchangeExceptionType type;
  ExchangeException(super.message, this.type);

  @override
  String toString() {
    return message;
  }
}

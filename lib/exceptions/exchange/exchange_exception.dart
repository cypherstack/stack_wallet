import 'package:stackwallet/exceptions/sw_exception.dart';

enum ExchangeExceptionType { generic, serializeResponseError }

class ExchangeException extends SWException {
  ExchangeExceptionType type;
  ExchangeException(super.message, this.type);

  @override
  String toString() {
    return message;
  }
}

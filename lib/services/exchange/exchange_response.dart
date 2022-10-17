enum ExchangeExceptionType { generic, serializeResponseError }

class ExchangeException implements Exception {
  String errorMessage;
  ExchangeExceptionType type;
  ExchangeException(this.errorMessage, this.type);

  @override
  String toString() {
    return errorMessage;
  }
}

class ExchangeResponse<T> {
  late final T? value;
  late final ExchangeException? exception;

  ExchangeResponse({this.value, this.exception});

  @override
  String toString() {
    return "{error: $exception, value: $value}";
  }
}

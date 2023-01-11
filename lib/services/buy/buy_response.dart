enum BuyExceptionType { generic, serializeResponseError }

class BuyException implements Exception {
  String errorMessage;
  BuyExceptionType type;
  BuyException(this.errorMessage, this.type);

  @override
  String toString() {
    return errorMessage;
  }
}

class BuyResponse<T> {
  late final T? value;
  late final BuyException? exception;

  BuyResponse({this.value, this.exception});

  @override
  String toString() {
    return "{error: $exception, value: $value}";
  }
}

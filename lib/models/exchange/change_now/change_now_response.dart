enum ChangeNowExceptionType { generic, serializeResponseError }

class ChangeNowException implements Exception {
  String errorMessage;
  ChangeNowExceptionType type;
  ChangeNowException(this.errorMessage, this.type);

  @override
  String toString() {
    return errorMessage;
  }
}

class ChangeNowResponse<T> {
  late final T? value;
  late final ChangeNowException? exception;

  ChangeNowResponse({this.value, this.exception});

  @override
  String toString() {
    return "{ error: $exception, value: $value }";
  }
}

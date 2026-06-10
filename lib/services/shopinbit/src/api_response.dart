import 'api_exception.dart';

class ApiResponse<T> {
  final T? value;
  final ApiException? exception;
  final String? customerKey;

  ApiResponse({this.value, this.exception, this.customerKey});

  bool get hasError => exception != null;

  T get valueOrThrow {
    if (exception != null) throw exception!;
    return value as T;
  }

  @override
  String toString() => '{error: $exception, value: $value}';
}

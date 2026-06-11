import 'api_exception.dart';

class ApiResponse<T> {
  final T? value;
  final ApiException? exception;

  ApiResponse({this.value, this.exception});

  bool get hasError => exception != null;

  T get valueOrThrow {
    if (exception != null) throw exception!;
    return value as T;
  }

  @override
  String toString() => '{error: $exception, value: $value}';
}

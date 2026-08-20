class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final String? responseBody;

  ApiException(this.message, {this.statusCode, this.responseBody});

  factory ApiException.fromResponse(int statusCode, String body) {
    return ApiException(
      'HTTP $statusCode',
      statusCode: statusCode,
      responseBody: body,
    );
  }

  factory ApiException.network(Object error) {
    return ApiException('Network error: $error');
  }

  @override
  String toString() =>
      'ApiException: $message'
      '${statusCode != null ? ' (status: $statusCode)' : ''}';
}

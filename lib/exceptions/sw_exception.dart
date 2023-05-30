// generic stack wallet exception which all other custom exceptions should
// extend from

class SWException implements Exception {
  SWException(this.message);

  final String message;

  @override
  toString() => message;
}

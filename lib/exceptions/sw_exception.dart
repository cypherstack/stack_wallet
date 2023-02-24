// generic stack wallet exception which all other custom exceptions should
// extend from

class SWException with Exception {
  SWException(this.message);

  final String message;

  @override
  toString() => message;
}

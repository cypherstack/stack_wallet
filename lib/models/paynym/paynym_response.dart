class PaynymResponse<T> {
  final T? value;
  final int statusCode;
  final String message;

  PaynymResponse(this.value, this.statusCode, this.message);

  @override
  String toString() {
    return "PaynymResponse: value=$value, statusCode=$statusCode, message=$message";
  }
}

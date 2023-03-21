import 'package:stackduo/exceptions/sw_exception.dart';

class MainDBException extends SWException {
  MainDBException(super.message, this.originalError);

  final Object originalError;

  @override
  String toString() {
    return "$message: originalError=$originalError";
  }
}

import 'package:stackduo/exceptions/sw_exception.dart';

class NoSuchTransactionException extends SWException {
  final String txid;

  NoSuchTransactionException(super.message, this.txid);
}

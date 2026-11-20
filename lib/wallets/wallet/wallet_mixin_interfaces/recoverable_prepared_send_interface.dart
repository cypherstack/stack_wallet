import '../../models/tx_data.dart';

/// A wallet that can rehydrate one exact signed preparation after restart.
abstract interface class RecoverablePreparedSendWallet {
  Future<TxData?> recoverPreparedSend();
}

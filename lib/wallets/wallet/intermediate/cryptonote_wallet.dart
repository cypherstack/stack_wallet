import 'dart:async';

import '../../crypto_currency/intermediate/cryptonote_currency.dart';
import '../../models/tx_data.dart';
import '../wallet.dart';
import '../wallet_mixin_interfaces/mnemonic_interface.dart';

abstract class CryptonoteWallet<T extends CryptonoteCurrency> extends Wallet<T>
    with MnemonicInterface<T> {
  CryptonoteWallet(super.currency);

  // ========== Overrides ======================================================

  @override
  Future<TxData> confirmSend({required TxData txData}) {
    // TODO: implement confirmSend
    throw UnimplementedError();
  }

  @override
  Future<TxData> prepareSend({required TxData txData}) {
    // TODO: implement prepareSend
    throw UnimplementedError();
  }

  @override
  Future<void> recover({required bool isRescan}) {
    // TODO: implement recover
    throw UnimplementedError();
  }

  @override
  Future<bool> updateUTXOs() async {
    // do nothing for now
    return false;
  }
}

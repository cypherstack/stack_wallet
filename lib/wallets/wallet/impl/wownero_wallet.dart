import 'package:stackwallet/models/paymint/fee_object_model.dart';
import 'package:stackwallet/utilities/amount/amount.dart';
import 'package:stackwallet/wallets/crypto_currency/coins/wownero.dart';
import 'package:stackwallet/wallets/wallet/intermediate/cryptonote_wallet.dart';

class WowneroWallet extends CryptonoteWallet {
  WowneroWallet(Wownero wownero) : super(wownero);

  @override
  Future<Amount> estimateFeeFor(Amount amount, int feeRate) {
    // TODO: implement estimateFeeFor
    throw UnimplementedError();
  }

  @override
  // TODO: implement fees
  Future<FeeObject> get fees => throw UnimplementedError();

  @override
  Future<bool> pingCheck() {
    // TODO: implement pingCheck
    throw UnimplementedError();
  }

  @override
  Future<void> updateBalance() {
    // TODO: implement updateBalance
    throw UnimplementedError();
  }

  @override
  Future<void> updateChainHeight() {
    // TODO: implement updateChainHeight
    throw UnimplementedError();
  }

  @override
  Future<void> updateNode() {
    // TODO: implement updateNode
    throw UnimplementedError();
  }

  @override
  Future<void> updateTransactions() {
    // TODO: implement updateTransactions
    throw UnimplementedError();
  }

  @override
  Future<void> updateUTXOs() {
    // TODO: implement updateUTXOs
    throw UnimplementedError();
  }
}

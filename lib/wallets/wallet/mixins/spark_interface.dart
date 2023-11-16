import 'package:stackwallet/wallets/models/tx_data.dart';
import 'package:stackwallet/wallets/wallet/intermediate/bip39_hd_wallet.dart';
import 'package:stackwallet/wallets/wallet/mixins/electrumx.dart';

mixin SparkInterface on Bip39HDWallet, ElectrumX {
  Future<TxData> prepareSendSpark({
    required TxData txData,
  }) async {
    throw UnimplementedError();
  }
}

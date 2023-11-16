import 'package:stackwallet/wallets/models/tx_data.dart';
import 'package:stackwallet/wallets/wallet/intermediate/bip39_hd_wallet.dart';
import 'package:stackwallet/wallets/wallet/wallet_mixin_interfaces/electrumx_interface.dart';

mixin SparkInterface on Bip39HDWallet, ElectrumXInterface {
  Future<TxData> prepareSendSpark({
    required TxData txData,
  }) async {
    throw UnimplementedError();
  }
}

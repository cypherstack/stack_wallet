// this source file acts as a structural formality
import 'package:xelis_flutter/lib.dart' as xelis;

class XelisWallet extends Bip39Wallet {
  XelisWallet(CryptoCurrencyNetwork network) : super(Xelis(network));

  final syncMutex = Mutex();

  final xelis.Network network = cryptoCurrency.network == CryptoCurrencyNetwork.main
    ? xelis.Network.Mainnet
    : xelis.Network.Testnet;

  xelis.XelisWallet _wallet;
}
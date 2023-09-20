import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/wallets/crypto_currency/bip39_currency.dart';
import 'package:stackwallet/wallets/crypto_currency/crypto_currency.dart';
import 'package:stackwallet/wallets/example/libepiccash.dart';

class Epiccash extends Bip39Currency {
  Epiccash(super.network) {
    switch (network) {
      case CryptoCurrencyNetwork.main:
        coin = Coin.epicCash;
      default:
        throw Exception("Unsupported network: $network");
    }
  }

  @override
  // change this to change the number of confirms a tx needs in order to show as confirmed
  int get minConfirms => 3;

  @override
  bool validateAddress(String address) {
    // Invalid address that contains HTTP and epicbox domain
    if ((address.startsWith("http://") || address.startsWith("https://")) &&
        address.contains("@")) {
      return false;
    }
    if (address.startsWith("http://") || address.startsWith("https://")) {
      if (Uri.tryParse(address) != null) {
        return true;
      }
    }

    return LibEpiccash.validateSendAddress(address: address);
  }

  String getMnemonic() {
    return LibEpiccash.getMnemonic();
  }

  Future<String> initializeNew(({String config, String mnemonic, String password, String name})? data) {
    return LibEpiccash.initializeNewWallet(
        config: data!.config,
        mnemonic: data.mnemonic,
        password: data.password,
        name: data.name);
  }
}

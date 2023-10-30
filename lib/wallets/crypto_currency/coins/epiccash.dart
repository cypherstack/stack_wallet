import 'package:flutter_libepiccash/lib.dart' as epic;
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/wallets/crypto_currency/bip39_currency.dart';
import 'package:stackwallet/wallets/crypto_currency/crypto_currency.dart';

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
  String get genesisHash {
    return "not used in epiccash";
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

    return epic.LibEpiccash.validateSendAddress(address: address);
  }
}

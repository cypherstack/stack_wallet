import 'package:nanodart/nanodart.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/wallets/crypto_currency/crypto_currency.dart';
import 'package:stackwallet/wallets/crypto_currency/intermediate/nano_currency.dart';

class Nano extends NanoCurrency {
  Nano(super.network) {
    switch (network) {
      case CryptoCurrencyNetwork.main:
        coin = Coin.nano;
      default:
        throw Exception("Unsupported network: $network");
    }
  }

  @override
  int get minConfirms => 1;

  @override
  String get defaultRepresentative =>
      "nano_38713x95zyjsqzx6nm1dsom1jmm668owkeb9913ax6nfgj15az3nu8xkx579";

  @override
  int get nanoAccountType => NanoAccountType.NANO;
}

import 'package:nanodart/nanodart.dart';
import 'package:stackwallet/wallets/crypto_currency/intermediate/bip39_currency.dart';

abstract class NanoCurrency extends Bip39Currency {
  NanoCurrency(super.network);

  String get defaultRepresentative;

  int get nanoAccountType;

  @override
  bool validateAddress(String address) => NanoAccounts.isValid(
        nanoAccountType,
        address,
      );

  @override
  String get genesisHash => throw UnimplementedError(
        "Not used in nano based coins",
      );
}

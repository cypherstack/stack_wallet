import 'package:nanodart/nanodart.dart';
import 'package:stackwallet/wallets/crypto_currency/intermediate/bip39_currency.dart';

abstract class NanoCurrency extends Bip39Currency {
  NanoCurrency(super.network);

  String get defaultRepresentative;

  int get nanoAccountType;

  @override
  bool get hasMnemonicPassphraseSupport => false;

  @override
  int get targetBlockTimeSeconds => 1; // TODO: Verify this

  @override
  bool get hasBuySupport => false;

  @override
  int get defaultSeedPhraseLength => 24;

  @override
  List<int> get possibleMnemonicLengths => [defaultSeedPhraseLength, 12];

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

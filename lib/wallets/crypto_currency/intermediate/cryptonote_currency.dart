import '../../../models/isar/models/blockchain_data/address.dart';
import '../crypto_currency.dart';
import '../interfaces/view_only_option_currency_interface.dart';

abstract class CryptonoteCurrency extends CryptoCurrency
    with ViewOnlyOptionCurrencyInterface {
  CryptonoteCurrency(super.network);

  @override
  String get genesisHash {
    return "not used in stack's cryptonote coins";
  }

  @override
  AddressType get defaultAddressType => AddressType.cryptonote;
}

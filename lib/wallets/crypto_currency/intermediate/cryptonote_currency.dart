import '../../../models/isar/models/blockchain_data/address.dart';
import '../crypto_currency.dart';

abstract class CryptonoteCurrency extends CryptoCurrency {
  CryptonoteCurrency(super.network);

  @override
  String get genesisHash {
    return "not used in stack's cryptonote coins";
  }

  @override
  AddressType get primaryAddressType => AddressType.cryptonote;
}

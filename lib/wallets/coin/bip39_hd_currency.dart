import 'package:coinlib/coinlib.dart' as coinlib;
import 'package:stackwallet/models/isar/models/blockchain_data/address.dart';
import 'package:stackwallet/utilities/enums/derive_path_type_enum.dart';
import 'package:stackwallet/wallets/coin/crypto_currency.dart';

abstract class Bip39HDCurrency extends CryptoCurrency {
  Bip39HDCurrency(super.network);

  coinlib.NetworkParams get networkParams;

  String constructDerivePath({
    required DerivePathType derivePathType,
    int account = 0,
    required int chain,
    required int index,
  });

  ({coinlib.Address address, AddressType addressType}) getAddressForPublicKey({
    required coinlib.ECPublicKey publicKey,
    required DerivePathType derivePathType,
  });
}

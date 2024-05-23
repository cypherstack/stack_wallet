import '../../models/isar/models/blockchain_data/address.dart';
import '../../models/node_model.dart';
import '../../utilities/enums/derive_path_type_enum.dart';

export 'package:stackwallet/wallets/crypto_currency/coins/banano.dart';
export 'package:stackwallet/wallets/crypto_currency/coins/bitcoin.dart';
export 'package:stackwallet/wallets/crypto_currency/coins/bitcoin_frost.dart';
export 'package:stackwallet/wallets/crypto_currency/coins/bitcoincash.dart';
export 'package:stackwallet/wallets/crypto_currency/coins/dogecoin.dart';
export 'package:stackwallet/wallets/crypto_currency/coins/ecash.dart';
export 'package:stackwallet/wallets/crypto_currency/coins/epiccash.dart';
export 'package:stackwallet/wallets/crypto_currency/coins/ethereum.dart';
export 'package:stackwallet/wallets/crypto_currency/coins/firo.dart';
export 'package:stackwallet/wallets/crypto_currency/coins/litecoin.dart';
export 'package:stackwallet/wallets/crypto_currency/coins/monero.dart';
export 'package:stackwallet/wallets/crypto_currency/coins/namecoin.dart';
export 'package:stackwallet/wallets/crypto_currency/coins/nano.dart';
export 'package:stackwallet/wallets/crypto_currency/coins/particl.dart';
export 'package:stackwallet/wallets/crypto_currency/coins/peercoin.dart';
export 'package:stackwallet/wallets/crypto_currency/coins/solana.dart';
export 'package:stackwallet/wallets/crypto_currency/coins/stellar.dart';
export 'package:stackwallet/wallets/crypto_currency/coins/tezos.dart';
export 'package:stackwallet/wallets/crypto_currency/coins/wownero.dart';
export 'package:stackwallet/wallets/crypto_currency/crypto_currency.dart';

enum CryptoCurrencyNetwork {
  main,
  test,
  stage;
}

abstract class CryptoCurrency {
  // @Deprecated("[prio=low] Should eventually move away from Coin enum")
  // late final CryptoCurrency coin;

  final CryptoCurrencyNetwork network;

  CryptoCurrency(this.network);

  // Identifier should be unique.
  /// This [identifier] should also match the old `Coin` enum name for each
  /// respective coin as it is used to differentiate between coins in persistent
  /// storage.
  String get identifier;

  /// Should be the [identifier] of the main net version of the currency
  String get mainNetId;

  String get ticker;
  String get prettyName;
  String get uriScheme;

  // override in subclass if the currency has tokens on it's network
  // (used for eth currently)
  bool get hasTokenSupport => false;

  // Override in subclass if the currency has Tor support:
  bool get torSupport => false;

  int get minConfirms;

  // TODO: [prio=low] could be handled differently as (at least) epiccash does not use this
  String get genesisHash;

  bool validateAddress(String address);

  NodeModel get defaultNode;

  int get defaultSeedPhraseLength;
  int get fractionDigits;
  bool get hasBuySupport;
  bool get hasMnemonicPassphraseSupport;
  List<int> get possibleMnemonicLengths;
  AddressType get primaryAddressType;
  BigInt get satsPerCoin;
  int get targetBlockTimeSeconds;
  DerivePathType get primaryDerivePathType;

  Uri defaultBlockExplorer(String txid);

  @override
  bool operator ==(Object other) {
    return other is CryptoCurrency &&
        other.runtimeType == runtimeType &&
        other.network == network;
  }

  @override
  int get hashCode => Object.hash(runtimeType, network);
}

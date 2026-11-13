import 'package:zcash_flutter/zcash_flutter.dart' as zcash;

import '../../../models/isar/models/blockchain_data/address.dart';
import '../../../models/node_model.dart';
import '../../../utilities/enums/derive_path_type_enum.dart';
import '../crypto_currency.dart';
import '../intermediate/bip39_currency.dart';

class Zcash extends Bip39Currency {
  Zcash(super.network) {
    switch (network) {
      case CryptoCurrencyNetwork.main:
        _identifier = 'zcash';
        _prettyName = 'Zcash';
        _ticker = 'ZEC';
      case CryptoCurrencyNetwork.test:
        _identifier = 'zcashTestNet';
        _prettyName = 'tZcash';
        _ticker = 'tZEC';
      case CryptoCurrencyNetwork.regtest:
        _identifier = 'zcashRegtest';
        _prettyName = 'Zcash Regtest';
        _ticker = 'rZEC';
      case CryptoCurrencyNetwork.stage:
      case CryptoCurrencyNetwork.test4:
        throw ArgumentError.value(network, 'network', 'Unsupported network');
    }
  }

  late final String _identifier;
  late final String _prettyName;
  late final String _ticker;

  zcash.ZcashNetwork get nativeNetwork => switch (network) {
    CryptoCurrencyNetwork.main => zcash.ZcashNetwork.mainnet,
    CryptoCurrencyNetwork.test => zcash.ZcashNetwork.testnet,
    CryptoCurrencyNetwork.regtest => zcash.ZcashNetwork.regtest,
    CryptoCurrencyNetwork.stage || CryptoCurrencyNetwork.test4 =>
      throw StateError('Unsupported Zcash network: $network'),
  };

  @override
  String get identifier => _identifier;

  @override
  String get mainNetId => 'zcash';

  @override
  String get prettyName => _prettyName;

  @override
  String get ticker => _ticker;

  @override
  String get uriScheme => 'zcash';

  @override
  int get minConfirms => 1;

  @override
  int get minCoinbaseConfirms => 100;

  @override
  String get genesisHash => throw UnsupportedError(
    'Zcash chain access is not part of the wallet identity slice',
  );

  @override
  bool validateAddress(String address) =>
      zcash.isValidAddress(address, nativeNetwork);

  @override
  AddressType? getAddressType(String address) {
    if (!validateAddress(address)) return null;
    return zcash.classifyAddress(address) == zcash.AddressType.unified
        ? AddressType.zcashUnified
        : null;
  }

  @override
  NodeModel defaultNode({required bool isPrimary}) => throw UnsupportedError(
    'Zcash node access is not part of the wallet identity slice',
  );

  @override
  int get defaultSeedPhraseLength => 24;

  @override
  int get fractionDigits => 8;

  @override
  bool get hasBuySupport => false;

  @override
  bool get hasMnemonicPassphraseSupport => true;

  @override
  List<int> get possibleMnemonicLengths => const [12, 15, 18, 21, 24];

  @override
  AddressType get defaultAddressType => AddressType.zcashUnified;

  @override
  BigInt get satsPerCoin => BigInt.from(100000000);

  @override
  int get targetBlockTimeSeconds => 75;

  @override
  DerivePathType get defaultDerivePathType => throw UnsupportedError(
    'Zcash does not use a Bitcoin-style derivation path selector',
  );

  @override
  Uri defaultBlockExplorer(String txid) => throw UnsupportedError(
    'Zcash transaction lookup is not part of the wallet identity slice',
  );
}

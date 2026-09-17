import '../../models/isar/models/blockchain_data/address.dart';
import '../../models/node_model.dart';
import '../../utilities/enums/derive_path_type_enum.dart';

export 'coins/banano.dart';
export 'coins/bitcoin.dart';
export 'coins/bitcoin_frost.dart';
export 'coins/bitcoincash.dart';
export 'coins/bellscoin.dart';
export 'coins/bitfinite.dart';
export 'coins/cardano.dart';
export 'coins/dash.dart';
export 'coins/dogecoin.dart';
export 'coins/pepecoin.dart';
export 'coins/ecash.dart';
export 'coins/epiccash.dart';
export 'coins/mimblewimblecoin.dart';
export 'coins/ethereum.dart';
export 'coins/fact0rn.dart';
export 'coins/firo.dart';
export 'coins/litecoin.dart';
export 'coins/monero.dart';
export 'coins/namecoin.dart';
export 'coins/nano.dart';
export 'coins/particl.dart';
export 'coins/peercoin.dart';
export 'coins/salvium.dart';
export 'coins/solana.dart';
export 'coins/stellar.dart';
export 'coins/tezos.dart';
export 'coins/wownero.dart';
export 'coins/xelis.dart';

enum CryptoCurrencyNetwork {
  main,
  test,
  stage,
  test4;

  bool get isTestNet =>
      this == CryptoCurrencyNetwork.test || this == CryptoCurrencyNetwork.test4;
}

abstract class CryptoCurrency {
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
  /// The coin's own brand colour, when it has a published one.
  ///
  /// Only consulted if the active theme defines no colour for this coin. Themes
  /// carried over from upstream only cover the coins upstream ships, so anything
  /// added since falls back to the theme's primary and ends up looking like
  /// every other coin. A published brand colour is a better answer than that,
  /// and a theme that defines its own still wins.
  int? get brandColorValue => null;

  bool get hasTokenSupport => false;

  // Override in subclass if the currency has Tor support:
  bool get torSupport => false;

  int get minConfirms;

  /// Confirmations a COINBASE output needs before it can be spent.
  ///
  /// This is a consensus rule, not a risk preference, and it is not the same
  /// question as [minConfirms]. [minConfirms] asks how many blocks deep an
  /// ordinary payment should be before this wallet is willing to treat it as
  /// settled, which is a judgement call: a BCH-style chain answers zero and
  /// accepts the reordering risk. A coinbase output is different. The chain
  /// itself will reject a transaction that spends one too early, so a wallet
  /// that counts an immature reward as spendable is not taking a risk, it is
  /// stating something the network will refuse.
  ///
  /// It used to default to [minConfirms], which made every Bitcoin-derived
  /// coin wrong in the dangerous direction: BitFinite answered 0 and most of
  /// the others answered 1, against a real maturity of 100. A miner's freshly
  /// won block showed up in the spendable balance, "send max" offered it, and
  /// the network rejected the transaction. That is the wallet's own target
  /// user hitting it on the wallet's own chain.
  ///
  /// So the default is the Bitcoin-derived 100 these chains inherit.
  /// BitFinite's own COINBASE_MATURITY is 100, read from our consensus header
  /// rather than assumed. Where a chain's real maturity is lower the only
  /// cost is a reward sitting in the pending balance a little longer, which
  /// is the safe direction to be wrong in: too high delays good news, too low
  /// offers coins that cannot be spent.
  int get minCoinbaseConfirms => 100;

  // TODO: [prio=low] could be handled differently as (at least) epiccash/mimblewimblecoin does not use this
  String get genesisHash;

  bool validateAddress(String address);
  AddressType? getAddressType(String address);

  NodeModel defaultNode({required bool isPrimary});

  /// Extra built-in failover nodes seeded alongside [defaultNode]. Empty by
  /// default; a coin can override to ship additional failover servers.
  List<NodeModel> get additionalDefaultNodes => const [];


  int get defaultSeedPhraseLength;
  int get fractionDigits;
  bool get hasBuySupport;
  bool get hasMnemonicPassphraseSupport;
  List<int> get possibleMnemonicLengths;
  AddressType get defaultAddressType;
  BigInt get satsPerCoin;
  int get targetBlockTimeSeconds;
  DerivePathType get defaultDerivePathType;

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

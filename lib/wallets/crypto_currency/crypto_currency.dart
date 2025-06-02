import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/isar/models/blockchain_data/address.dart';
import '../../models/node_model.dart';
import '../../providers/db/main_db_provider.dart';
import '../../providers/global/node_service_provider.dart';
import '../../providers/global/prefs_provider.dart';
import '../../providers/global/secure_store_provider.dart';
import '../../providers/global/wallets_provider.dart';
import '../../utilities/address_utils.dart';
import '../../utilities/enums/derive_path_type_enum.dart';
import '../../utilities/logger.dart';
import '../isar/models/wallet_info.dart';
import '../wallet/wallet.dart';

export 'coins/banano.dart';
export 'coins/bitcoin.dart';
export 'coins/bitcoin_frost.dart';
export 'coins/bitcoincash.dart';
export 'coins/cardano.dart';
export 'coins/dash.dart';
export 'coins/dogecoin.dart';
export 'coins/ecash.dart';
export 'coins/epiccash.dart';
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
  bool get hasTokenSupport => false;

  // Override in subclass if the currency has Tor support:
  bool get torSupport => false;

  int get minConfirms;
  int get minCoinbaseConfirms => minConfirms;

  // TODO: [prio=low] could be handled differently as (at least) epiccash does not use this
  String get genesisHash;

  bool validateAddress(String address);

  NodeModel defaultNode({required bool isPrimary});

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

  Future<Wallet?> importPaperWallet(WalletUriData walletData, WidgetRef ref, {Wallet? newWallet}) async {
    try {
      final info = WalletInfo.createNew(
        coin: walletData.coin,
        name: "${walletData.coin.prettyName} Paper Wallet ${walletData.address != null ? '(${walletData.address!.substring(walletData.address!.length - 4)})' : ''}",
        restoreHeight: walletData.height ?? 0,
        otherDataJsonString: walletData.toJson(),
      );

      final wallet = await Wallet.create(
        walletInfo: info,
        mainDB: ref.read(mainDBProvider),
        secureStorageInterface: ref.read(secureStoreProvider),
        nodeService: ref.read(nodeServiceChangeNotifierProvider),
        prefs: ref.read(prefsChangeNotifierProvider),
        mnemonicPassphrase: null,
        mnemonic: walletData.seed,
      );

      await wallet.init();
      await wallet.recover(isRescan: false);
      await wallet.info.setMnemonicVerified(isar: ref
          .read(mainDBProvider)
          .isar);
      ref.read(pWallets).addWallet(wallet);
      return wallet;
    } catch (e, stackTrace) {
      Logging.instance.e(
        "Error importing paper wallet: $e",
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }
}

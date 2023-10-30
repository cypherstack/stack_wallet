import 'package:isar/isar.dart';
import 'package:stackwallet/db/isar/main_db.dart';
import 'package:stackwallet/services/node_service.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/utilities/flutter_secure_storage_interface.dart';
import 'package:stackwallet/utilities/prefs.dart';
import 'package:stackwallet/wallets/crypto_currency/coins/bitcoin.dart';
import 'package:stackwallet/wallets/crypto_currency/crypto_currency.dart';
import 'package:stackwallet/wallets/isar_models/wallet_info.dart';
import 'package:stackwallet/wallets/models/tx_data.dart';
import 'package:stackwallet/wallets/wallet/impl/bitcoin_wallet.dart';
import 'package:stackwallet/wallets/wallet/mixins/electrumx_mixin.dart';

abstract class Wallet<T extends CryptoCurrency> {
  int get isarTransactionVersion => 1;

  Wallet(this.cryptoCurrency);

  //============================================================================
  // ========== Properties =====================================================

  final T cryptoCurrency;

  late final MainDB mainDB;
  late final SecureStorageInterface secureStorageInterface;
  late final WalletInfo walletInfo;
  late final Prefs prefs;

  //============================================================================
  // ========== Wallet Info Convenience Getters ================================

  String get walletId => walletInfo.walletId;
  WalletType get walletType => walletInfo.walletType;

  //============================================================================
  // ========== Static Main ====================================================

  /// Create a new wallet and save [walletInfo] to db.
  static Future<Wallet> create({
    required WalletInfo walletInfo,
    required MainDB mainDB,
    required SecureStorageInterface secureStorageInterface,
    required NodeService nodeService,
    required Prefs prefs,
    String? mnemonic,
    String? mnemonicPassphrase,
    String? privateKey,
  }) async {
    final Wallet wallet = await _construct(
      walletInfo: walletInfo,
      mainDB: mainDB,
      secureStorageInterface: secureStorageInterface,
      nodeService: nodeService,
      prefs: prefs,
    );

    switch (walletInfo.walletType) {
      case WalletType.bip39:
      case WalletType.bip39HD:
        await secureStorageInterface.write(
          key: mnemonicKey(walletId: walletInfo.walletId),
          value: mnemonic,
        );
        await secureStorageInterface.write(
          key: mnemonicPassphraseKey(walletId: walletInfo.walletId),
          value: mnemonicPassphrase,
        );
        break;

      case WalletType.cryptonote:
        break;

      case WalletType.privateKeyBased:
        break;
    }

    // Store in db after wallet creation
    await wallet.mainDB.isar.walletInfo.put(wallet.walletInfo);

    return wallet;
  }

  /// Load an existing wallet via [WalletInfo] using [walletId].
  static Future<Wallet> load({
    required String walletId,
    required MainDB mainDB,
    required SecureStorageInterface secureStorageInterface,
    required NodeService nodeService,
    required Prefs prefs,
  }) async {
    final walletInfo = await mainDB.isar.walletInfo
        .where()
        .walletIdEqualTo(walletId)
        .findFirst();

    if (walletInfo == null) {
      throw Exception(
        "WalletInfo not found for $walletId when trying to call Wallet.load()",
      );
    }

    return await _construct(
      walletInfo: walletInfo!,
      mainDB: mainDB,
      secureStorageInterface: secureStorageInterface,
      nodeService: nodeService,
      prefs: prefs,
    );
  }

  //============================================================================
  // ========== Static Util ====================================================

  // secure storage key
  static String mnemonicKey({
    required String walletId,
  }) =>
      "${walletId}_mnemonic";

  // secure storage key
  static String mnemonicPassphraseKey({
    required String walletId,
  }) =>
      "${walletId}_mnemonicPassphrase";

  // secure storage key
  static String privateKeyKey({
    required String walletId,
  }) =>
      "${walletId}_privateKey";

  //============================================================================
  // ========== Private ========================================================

  /// Construct wallet instance by [WalletType] from [walletInfo]
  static Future<Wallet> _construct({
    required WalletInfo walletInfo,
    required MainDB mainDB,
    required SecureStorageInterface secureStorageInterface,
    required NodeService nodeService,
    required Prefs prefs,
  }) async {
    final Wallet wallet = _loadWallet(
      walletInfo: walletInfo,
      nodeService: nodeService,
      prefs: prefs,
    );

    if (wallet is ElectrumXMixin) {
      // initialize electrumx instance
      await wallet.updateNode();
    }

    return wallet
      ..secureStorageInterface = secureStorageInterface
      ..mainDB = mainDB
      ..walletInfo = walletInfo;
  }

  static Wallet _loadWallet({
    required WalletInfo walletInfo,
    required NodeService nodeService,
    required Prefs prefs,
  }) {
    switch (walletInfo.coin) {
      case Coin.bitcoin:
        return BitcoinWallet(
          Bitcoin(CryptoCurrencyNetwork.main),
          nodeService: nodeService,
          prefs: prefs,
        );
      case Coin.bitcoinTestNet:
        return BitcoinWallet(
          Bitcoin(CryptoCurrencyNetwork.test),
          nodeService: nodeService,
          prefs: prefs,
        );

      default:
        // should never hit in reality
        throw Exception("Unknown crypto currency");
    }
  }

  //============================================================================
  // ========== Must override ==================================================

  /// Create and sign a transaction in preparation to submit to network
  Future<TxData> prepareSend({required TxData txData});

  /// Broadcast transaction to network. On success update local wallet state to
  /// reflect updated balance, transactions, utxos, etc.
  Future<TxData> confirmSend({required TxData txData});

  /// Recover a wallet by scanning the blockchain. If called on a new wallet a
  /// normal recovery should occur. When called on an existing wallet and
  /// [isRescan] is false then it should throw. Otherwise this function should
  /// delete all locally stored blockchain data and refetch it.
  Future<void> recover({required bool isRescan});

  Future<void> updateTransactions();
  Future<void> updateUTXOs();
  Future<void> updateBalance();

  // Should probably call the above 3 functions
  // Should fire events
  Future<void> refresh();

  //===========================================

  Future<void> updateNode();
}

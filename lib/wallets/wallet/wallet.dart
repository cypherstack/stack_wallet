import 'package:isar/isar.dart';
import 'package:stackwallet/db/isar/main_db.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/utilities/flutter_secure_storage_interface.dart';
import 'package:stackwallet/wallets/coin/bip39_hd_currency.dart';
import 'package:stackwallet/wallets/coin/coins/bitcoin.dart';
import 'package:stackwallet/wallets/coin/crypto_currency.dart';
import 'package:stackwallet/wallets/isar_models/wallet_info.dart';
import 'package:stackwallet/wallets/models/tx_data.dart';
import 'package:stackwallet/wallets/wallet/bip39_hd_wallet.dart';
import 'package:stackwallet/wallets/wallet/private_key_based_wallet.dart';

abstract class Wallet<T extends CryptoCurrency> {
  Wallet(this.cryptoCurrency);

  //============================================================================
  // ========== Properties =====================================================

  final T cryptoCurrency;

  late final MainDB mainDB;
  late final SecureStorageInterface secureStorageInterface;
  late final WalletInfo walletInfo;

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
    String? mnemonic,
    String? mnemonicPassphrase,
    String? privateKey,
    int? startDate,
  }) async {
    final Wallet wallet = await _construct(
      walletInfo: walletInfo,
      mainDB: mainDB,
      secureStorageInterface: secureStorageInterface,
    );

    switch (walletInfo.walletType) {
      case WalletType.bip39:
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
    );
  }

  //============================================================================
  // ========== Static Util ====================================================

  static String mnemonicKey({
    required String walletId,
  }) =>
      "${walletId}_mnemonic";

  static String mnemonicPassphraseKey({
    required String walletId,
  }) =>
      "${walletId}_mnemonicPassphrase";

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
  }) async {
    final Wallet wallet;

    final cryptoCurrency = _loadCurrency(walletInfo: walletInfo);

    switch (walletInfo.walletType) {
      case WalletType.bip39:
        wallet = Bip39HDWallet(cryptoCurrency as Bip39HDCurrency);
        break;

      case WalletType.cryptonote:
        wallet = PrivateKeyBasedWallet(cryptoCurrency);
        break;

      case WalletType.privateKeyBased:
        wallet = PrivateKeyBasedWallet(cryptoCurrency);
        break;
    }

    return wallet
      ..secureStorageInterface = secureStorageInterface
      ..mainDB = mainDB
      ..walletInfo = walletInfo;
  }

  static CryptoCurrency _loadCurrency({
    required WalletInfo walletInfo,
  }) {
    switch (walletInfo.coin) {
      case Coin.bitcoin:
        return Bitcoin(CryptoCurrencyNetwork.main);
      case Coin.bitcoinTestNet:
        return Bitcoin(CryptoCurrencyNetwork.test);

      default:
        // should never hit in reality
        throw Exception("Unknown cryupto currency");
    }
  }

  //============================================================================
  // ========== Must override ==================================================

  /// Create and sign a transaction in preparation to submit to network
  Future<TxData> prepareSend({required TxData txData});

  /// Broadcast transaction to network. On success update local wallet state to
  /// reflect updated balance, transactions, utxos, etc.
  Future<TxData> confirmSend({required TxData txData});
}

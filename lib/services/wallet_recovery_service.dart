import '../models/keys/key_data_interface.dart';
import '../models/keys/wallet_recovery_material.dart';
import '../wallets/isar/models/wallet_info.dart';
import '../wallets/wallet/impl/bitcoin_frost_wallet.dart';
import '../wallets/wallet/intermediate/cryptonote_wallet.dart';
import '../wallets/wallet/wallet.dart';
import '../wallets/wallet/wallet_mixin_interfaces/extended_keys_interface.dart';
import '../wallets/wallet/wallet_mixin_interfaces/mnemonic_interface.dart';
import '../wallets/wallet/wallet_mixin_interfaces/view_only_option_interface.dart';

class WalletRecoveryService {
  const WalletRecoveryService._();

  static Future<WalletRecoveryMaterial> getMaterial(Wallet wallet) async {
    if (wallet is BitcoinFrostWallet) {
      final results = await Future.wait([
        wallet.getSerializedKeys(),
        wallet.getMultisigConfig(),
        wallet.getSerializedKeysPrevGen(),
        wallet.getMultisigConfigPrevGen(),
      ]);
      final keys = results[0];
      final config = results[1];
      if (keys == null || config == null) {
        throw StateError("FROST recovery data is unavailable");
      }

      return FrostWalletRecoveryMaterial(
        walletId: wallet.walletId,
        data: (
          myName: wallet.frostInfo.myName,
          config: config,
          keys: keys,
          prevGen: results[2] == null || results[3] == null
              ? null
              : (config: results[3]!, keys: results[2]!),
        ),
      );
    }

    if (wallet is ViewOnlyOptionInterface && wallet.isViewOnly) {
      final data = await wallet.getViewOnlyWalletData();
      return ViewOnlyWalletRecoveryMaterial(
        walletId: wallet.walletId,
        keyData: data,
      );
    }

    if (wallet.info.recoveryType == WalletRecoveryType.privateKeys) {
      if (wallet is! CryptonoteWallet) {
        throw UnsupportedError(
          "Unsupported private-key wallet: ${wallet.runtimeType}",
        );
      }
      return PrivateKeyWalletRecoveryMaterial(
        walletId: wallet.walletId,
        keyData: await wallet.getKeys(),
      );
    }

    if (wallet is! MnemonicInterface) {
      throw UnsupportedError(
        "Unsupported wallet recovery type: ${wallet.runtimeType}",
      );
    }

    final words = await wallet.getMnemonicAsWords();
    if (words.isEmpty) {
      throw StateError("Wallet mnemonic is unavailable");
    }

    final KeyDataInterface? supplementalKeyData;
    if (wallet is ExtendedKeysInterface) {
      supplementalKeyData = await wallet.getXPrivs();
    } else if (wallet is CryptonoteWallet) {
      supplementalKeyData = await wallet.getKeys();
    } else {
      supplementalKeyData = null;
    }

    return MnemonicWalletRecoveryMaterial(
      walletId: wallet.walletId,
      words: words,
      supplementalKeyData: supplementalKeyData,
    );
  }
}

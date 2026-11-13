import 'cryptonote_key_restore_data.dart';
import 'key_data_interface.dart';
import 'view_only_wallet_data.dart';

typedef FrostWalletRecoveryData = ({
  String myName,
  String config,
  String keys,
  ({String config, String keys})? prevGen,
});

sealed class WalletRecoveryMaterial {
  const WalletRecoveryMaterial({required this.walletId});

  final String walletId;
}

final class MnemonicWalletRecoveryMaterial extends WalletRecoveryMaterial {
  MnemonicWalletRecoveryMaterial({
    required super.walletId,
    required List<String> words,
    this.supplementalKeyData,
  }) : words = List.unmodifiable(words) {
    if (words.isEmpty) {
      throw ArgumentError.value(words, "words", "Mnemonic cannot be empty");
    }
  }

  final List<String> words;
  final KeyDataInterface? supplementalKeyData;
}

final class PrivateKeyWalletRecoveryMaterial extends WalletRecoveryMaterial {
  const PrivateKeyWalletRecoveryMaterial({
    required super.walletId,
    required this.keyData,
    this.cryptonoteKeyRestoreData,
  });

  final KeyDataInterface keyData;
  final CryptonoteKeyRestoreData? cryptonoteKeyRestoreData;
}

final class ViewOnlyWalletRecoveryMaterial extends WalletRecoveryMaterial {
  const ViewOnlyWalletRecoveryMaterial({
    required super.walletId,
    required this.keyData,
  });

  final ViewOnlyWalletData keyData;
}

final class FrostWalletRecoveryMaterial extends WalletRecoveryMaterial {
  const FrostWalletRecoveryMaterial({
    required super.walletId,
    required this.data,
  });

  final FrostWalletRecoveryData data;
}

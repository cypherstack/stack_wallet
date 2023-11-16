import 'package:stackwallet/wallets/crypto_currency/coins/banano.dart';
import 'package:stackwallet/wallets/crypto_currency/crypto_currency.dart';
import 'package:stackwallet/wallets/crypto_currency/intermediate/nano_currency.dart';
import 'package:stackwallet/wallets/isar/models/wallet_info.dart';
import 'package:stackwallet/wallets/wallet/intermediate/bip39_wallet.dart';
import 'package:stackwallet/wallets/wallet/wallet_mixin_interfaces/nano_interface.dart';

class BananoWallet extends Bip39Wallet<NanoCurrency> with NanoInterface {
  BananoWallet(CryptoCurrencyNetwork network) : super(Banano(network));

  Future<void> updateMonkeyImageBytes(List<int> bytes) async {
    await info.updateOtherData(
      newEntries: {
        WalletInfoKeys.bananoMonkeyImageBytes: bytes,
      },
      isar: mainDB.isar,
    );
  }

  List<int>? getMonkeyImageBytes() {
    final list = info.otherData[WalletInfoKeys.bananoMonkeyImageBytes] as List?;
    if (list == null) {
      return null;
    }
    return List<int>.from(list);
  }
}

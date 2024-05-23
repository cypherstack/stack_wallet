import '../../crypto_currency/coins/banano.dart';
import '../../crypto_currency/crypto_currency.dart';
import '../../crypto_currency/intermediate/nano_currency.dart';
import '../../isar/models/wallet_info.dart';
import '../intermediate/bip39_wallet.dart';
import '../wallet_mixin_interfaces/nano_interface.dart';

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

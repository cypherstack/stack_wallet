import 'package:compat/compat.dart' as lib_monero_compat;

import '../../../utilities/amount/amount.dart';
import '../../../wl_gen/interfaces/cs_salvium_interface.dart'
    show WrappedWallet;
import '../../../wl_gen/interfaces/cs_wownero_interface.dart';
import '../../crypto_currency/crypto_currency.dart';
import '../intermediate/lib_wownero_wallet.dart';

class WowneroWallet extends LibWowneroWallet {
  WowneroWallet(CryptoCurrencyNetwork network)
    : super(Wownero(network), lib_monero_compat.WalletType.wownero);

  @override
  Future<Amount> estimateFeeFor(Amount amount, BigInt feeRate) async {
    if (wallet == null || syncStatus is! lib_monero_compat.SyncedSyncStatus) {
      return Amount.zeroWith(fractionDigits: cryptoCurrency.fractionDigits);
    }

    int approximateFee = 0;
    await estimateFeeMutex.protect(() async {
      approximateFee = await csWownero.estimateFee(
        feeRate.toInt(),
        amount.raw,
        wallet: wallet!,
      );
    });

    return Amount(
      rawValue: BigInt.from(approximateFee),
      fractionDigits: cryptoCurrency.fractionDigits,
    );
  }

  @override
  bool walletExists(String path) => csWownero.walletExists(path);

  @override
  Future<WrappedWallet> loadWallet({
    required String path,
    required String password,
  }) => csWownero.loadWallet(walletId, path: path, password: password);

  @override
  Future<WrappedWallet> getCreatedWallet({
    required String path,
    required String password,
    required int wordCount,
    required String seedOffset,
  }) => csWownero.getCreatedWallet(
    path: path,
    password: password,
    wordCount: wordCount,
    seedOffset: seedOffset,
  );

  @override
  Future<WrappedWallet> getRestoredWallet({
    required String path,
    required String password,
    required String mnemonic,
    required String seedOffset,
    int height = 0,
  }) => csWownero.getRestoredWallet(
    path: path,
    password: password,
    mnemonic: mnemonic,
    height: height,
    seedOffset: seedOffset,
    walletId: walletId,
  );

  @override
  Future<WrappedWallet> getRestoredFromViewKeyWallet({
    required String path,
    required String password,
    required String address,
    required String privateViewKey,
    int height = 0,
  }) => csWownero.getRestoredFromViewKeyWallet(
    walletId: walletId,
    path: path,
    password: password,
    address: address,
    privateViewKey: privateViewKey,
    height: height,
  );

  @override
  void invalidSeedLengthCheck(int length) {
    if (!(length == 16 || length == 25)) {
      throw Exception("Invalid wownero mnemonic length found: $length");
    }
  }
}

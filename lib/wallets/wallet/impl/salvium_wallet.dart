import 'dart:async';

import '../../../utilities/amount/amount.dart';
import '../../../wl_gen/interfaces/cs_salvium_interface.dart';
import '../../crypto_currency/crypto_currency.dart';
import '../intermediate/lib_salvium_wallet.dart';

class SalviumWallet extends LibSalviumWallet {
  SalviumWallet(CryptoCurrencyNetwork network) : super(Salvium(network));

  @override
  Future<Amount> estimateFeeFor(Amount amount, BigInt feeRate) async {
    if (wallet ==
        null /*||
        syncStatus is! lib_monero_compat.SyncedSyncStatus*/ ) {
      return Amount.zeroWith(fractionDigits: cryptoCurrency.fractionDigits);
    }

    int approximateFee = 0;
    await estimateFeeMutex.protect(() async {
      approximateFee = await csSalvium.estimateFee(
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
  bool walletExists(String path) => csSalvium.walletExists(path);

  @override
  Future<WrappedWallet> loadWallet({
    required String path,
    required String password,
  }) => csSalvium.loadWallet(walletId, path: path, password: password);

  @override
  Future<WrappedWallet> getCreatedWallet({
    required String path,
    required String password,
    required int wordCount,
    required String seedOffset,
  }) => csSalvium.getCreatedWallet(
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
  }) async => await csSalvium.getRestoredWallet(
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
  }) async => csSalvium.getRestoredFromViewKeyWallet(
    walletId: walletId,
    path: path,
    password: password,
    address: address,
    privateViewKey: privateViewKey,
    height: height,
  );

  @override
  void invalidSeedLengthCheck(int length) {
    if (length != 25 && length != 16) {
      throw Exception("Invalid salvium mnemonic length found: $length");
    }
  }
}

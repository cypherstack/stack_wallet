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
  }) => csSalvium.loadWallet(
    walletId,
    path: path,
    password: password,
    network: cryptoCurrency.network == CryptoCurrencyNetwork.main ? 0 : 1,
  );

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
    network: cryptoCurrency.network == CryptoCurrencyNetwork.main ? 0 : 1,
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
    network: cryptoCurrency.network == CryptoCurrencyNetwork.main ? 0 : 1,
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
    network: cryptoCurrency.network == CryptoCurrencyNetwork.main ? 0 : 1,
  );

  @override
  void invalidSeedLengthCheck(int length) {
    if (length != 25 && length != 16) {
      throw Exception("Invalid salvium mnemonic length found: $length");
    }
  }
}

import 'dart:async';

import 'package:compat/compat.dart' as lib_monero_compat;

import '../../../utilities/amount/amount.dart';
import '../../../wl_gen/interfaces/cs_monero_interface.dart';
import '../../crypto_currency/crypto_currency.dart';
import '../intermediate/lib_monero_wallet.dart';

class MoneroWallet extends LibMoneroWallet {
  MoneroWallet(CryptoCurrencyNetwork network)
    : super(Monero(network), lib_monero_compat.WalletType.monero);

  @override
  Future<Amount> estimateFeeFor(Amount amount, BigInt feeRate) async {
    if (!csMonero.walletInstanceExists(walletId) ||
        syncStatus is! lib_monero_compat.SyncedSyncStatus) {
      return Amount.zeroWith(fractionDigits: cryptoCurrency.fractionDigits);
    }

    int approximateFee = 0;
    await estimateFeeMutex.protect(() async {
      approximateFee = await csMonero.estimateFee(
        feeRate.toInt(),
        amount.raw,
        walletId: walletId,
      );
    });

    return Amount(
      rawValue: BigInt.from(approximateFee),
      fractionDigits: cryptoCurrency.fractionDigits,
    );
  }

  @override
  bool walletExists(String path) =>
      csMonero.walletExists(path, csCoin: CsCoin.monero);

  @override
  Future<void> loadWallet({required String path, required String password}) =>
      csMonero.loadWallet(
        walletId,
        path: path,
        password: password,
        csCoin: CsCoin.monero,
      );

  @override
  Future<void> getCreatedWallet({
    required String path,
    required String password,
    required int wordCount,
    required String seedOffset,
    required final void Function(int refreshFromBlockHeight, String seed)
    onCreated,
  }) => csMonero.getCreatedWallet(
    csCoin: CsCoin.monero,
    path: path,
    password: password,
    wordCount: wordCount,
    seedOffset: seedOffset,
    onCreated: onCreated,
  );

  @override
  Future<void> getRestoredWallet({
    required String path,
    required String password,
    required String mnemonic,
    required String seedOffset,
    int height = 0,
  }) => csMonero.getRestoredWallet(
    path: path,
    password: password,
    mnemonic: mnemonic,
    height: height,
    seedOffset: seedOffset,
    csCoin: CsCoin.monero,
    walletId: walletId,
  );

  @override
  Future<void> getRestoredFromViewKeyWallet({
    required String path,
    required String password,
    required String address,
    required String privateViewKey,
    int height = 0,
  }) => csMonero.getRestoredFromViewKeyWallet(
    walletId: walletId,
    csCoin: CsCoin.monero,
    path: path,
    password: password,
    address: address,
    privateViewKey: privateViewKey,
    height: height,
  );

  @override
  void invalidSeedLengthCheck(int length) {
    if (length != 25 && length != 16) {
      throw Exception("Invalid monero mnemonic length found: $length");
    }
  }
}

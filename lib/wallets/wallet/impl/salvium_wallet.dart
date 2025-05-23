import 'dart:async';

import 'package:compat/compat.dart' as lib_monero_compat;
import 'package:cs_salvium/cs_salvium.dart' as lib_salvium;

import '../../../utilities/amount/amount.dart';
import '../../crypto_currency/crypto_currency.dart';
import '../intermediate/lib_salvium_wallet.dart';

class SalviumWallet extends LibSalviumWallet {
  SalviumWallet(CryptoCurrencyNetwork network)
    : super(Salvium(network));

  @override
  Future<Amount> estimateFeeFor(Amount amount, BigInt feeRate) async {
    if (libSalviumWallet == null /*||
        syncStatus is! lib_monero_compat.SyncedSyncStatus*/) {
      return Amount.zeroWith(fractionDigits: cryptoCurrency.fractionDigits);
    }

    lib_salvium.TransactionPriority priority;
    switch (feeRate.toInt()) {
      case 1:
        priority = lib_salvium.TransactionPriority.low;
        break;
      case 2:
        priority = lib_salvium.TransactionPriority.medium;
        break;
      case 3:
        priority = lib_salvium.TransactionPriority.high;
        break;
      case 4:
        priority = lib_salvium.TransactionPriority.last;
        break;
      case 0:
      default:
        priority = lib_salvium.TransactionPriority.normal;
        break;
    }

    int approximateFee = 0;
    await estimateFeeMutex.protect(() async {
      approximateFee = await libSalviumWallet!.estimateFee(
        priority,
        amount.raw.toInt(),
      );
    });

    return Amount(
      rawValue: BigInt.from(approximateFee),
      fractionDigits: cryptoCurrency.fractionDigits,
    );
  }

  @override
  bool walletExists(String path) => lib_salvium.SalviumWallet.isWalletExist(path);

  @override
  Future<void> loadWallet({
    required String path,
    required String password,
  }) async {
    libSalviumWallet = await lib_salvium.SalviumWallet.loadWallet(
      path: path,
      password: password,
    );
  }

  @override
  Future<lib_salvium.Wallet> getCreatedWallet({
    required String path,
    required String password,
    required int wordCount,
    required String seedOffset,
  }) async {
    final lib_salvium.SalviumSeedType type;
    switch (wordCount) {
      case 25:
        type = lib_salvium.SalviumSeedType.twentyFive;
        break;

      default:
        throw Exception("Invalid mnemonic word count: $wordCount");
    }

    return await lib_salvium.SalviumWallet.create(
      path: path,
      password: password,
      seedType: type,
      seedOffset: seedOffset,
    );
  }

  @override
  Future<lib_salvium.Wallet> getRestoredWallet({
    required String path,
    required String password,
    required String mnemonic,
    required String seedOffset,
    int height = 0,
  }) async => await lib_salvium.SalviumWallet.restoreWalletFromSeed(
    path: path,
    password: password,
    seed: mnemonic,
    restoreHeight: height,
    seedOffset: seedOffset,
  );

  @override
  Future<lib_salvium.Wallet> getRestoredFromViewKeyWallet({
    required String path,
    required String password,
    required String address,
    required String privateViewKey,
    int height = 0,
  }) async => lib_salvium.SalviumWallet.createViewOnlyWallet(
    path: path,
    password: password,
    address: address,
    viewKey: privateViewKey,
    restoreHeight: height,
  );

  @override
  void invalidSeedLengthCheck(int length) {
    if (length != 25 && length != 16) {
      throw Exception("Invalid salvium mnemonic length found: $length");
    }
  }
}

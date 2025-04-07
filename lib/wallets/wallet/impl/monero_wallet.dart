import 'dart:async';

import 'package:compat/compat.dart' as lib_monero_compat;
import 'package:cs_monero/cs_monero.dart' as lib_monero;

import '../../../utilities/amount/amount.dart';
import '../../crypto_currency/crypto_currency.dart';
import '../intermediate/lib_monero_wallet.dart';

class MoneroWallet extends LibMoneroWallet {
  MoneroWallet(CryptoCurrencyNetwork network)
    : super(Monero(network), lib_monero_compat.WalletType.monero);

  @override
  Future<Amount> estimateFeeFor(Amount amount, BigInt feeRate) async {
    if (libMoneroWallet == null ||
        syncStatus is! lib_monero_compat.SyncedSyncStatus) {
      return Amount.zeroWith(fractionDigits: cryptoCurrency.fractionDigits);
    }

    lib_monero.TransactionPriority priority;
    switch (feeRate.toInt()) {
      case 1:
        priority = lib_monero.TransactionPriority.low;
        break;
      case 2:
        priority = lib_monero.TransactionPriority.medium;
        break;
      case 3:
        priority = lib_monero.TransactionPriority.high;
        break;
      case 4:
        priority = lib_monero.TransactionPriority.last;
        break;
      case 0:
      default:
        priority = lib_monero.TransactionPriority.normal;
        break;
    }

    int approximateFee = 0;
    await estimateFeeMutex.protect(() async {
      approximateFee = await libMoneroWallet!.estimateFee(
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
  bool walletExists(String path) => lib_monero.MoneroWallet.isWalletExist(path);

  @override
  Future<void> loadWallet({
    required String path,
    required String password,
  }) async {
    libMoneroWallet = await lib_monero.MoneroWallet.loadWallet(
      path: path,
      password: password,
    );
  }

  @override
  Future<lib_monero.Wallet> getCreatedWallet({
    required String path,
    required String password,
    required int wordCount,
  }) async {
    final lib_monero.MoneroSeedType type;
    switch (wordCount) {
      case 16:
        type = lib_monero.MoneroSeedType.sixteen;
        break;

      case 25:
        type = lib_monero.MoneroSeedType.twentyFive;
        break;

      default:
        throw Exception("Invalid mnemonic word count: $wordCount");
    }

    return await lib_monero.MoneroWallet.create(
      path: path,
      password: password,
      seedType: type,
    );
  }

  @override
  Future<lib_monero.Wallet> getRestoredWallet({
    required String path,
    required String password,
    required String mnemonic,
    int height = 0,
  }) async => await lib_monero.MoneroWallet.restoreWalletFromSeed(
    path: path,
    password: password,
    seed: mnemonic,
    restoreHeight: height,
  );

  @override
  Future<lib_monero.Wallet> getRestoredFromViewKeyWallet({
    required String path,
    required String password,
    required String address,
    required String privateViewKey,
    int height = 0,
  }) async => lib_monero.MoneroWallet.createViewOnlyWallet(
    path: path,
    password: password,
    address: address,
    viewKey: privateViewKey,
    restoreHeight: height,
  );

  @override
  void invalidSeedLengthCheck(int length) {
    if (length != 25 && length != 16) {
      throw Exception("Invalid monero mnemonic length found: $length");
    }
  }
}

import 'dart:async';

import 'package:compat/compat.dart' as lib_monero_compat;
import 'package:cs_monero/cs_monero.dart' as lib_monero;

import '../../../utilities/amount/amount.dart';
import '../../../utilities/enums/fee_rate_type_enum.dart';
import '../../crypto_currency/crypto_currency.dart';
import '../../models/tx_data.dart';
import '../intermediate/lib_monero_wallet.dart';

class WowneroWallet extends LibMoneroWallet {
  WowneroWallet(CryptoCurrencyNetwork network)
      : super(
          Wownero(network),
          lib_monero_compat.WalletType.wownero,
        );

  @override
  Future<Amount> estimateFeeFor(Amount amount, int feeRate) async {
    if (libMoneroWallet == null ||
        syncStatus is! lib_monero_compat.SyncedSyncStatus) {
      return Amount.zeroWith(
        fractionDigits: cryptoCurrency.fractionDigits,
      );
    }

    lib_monero.TransactionPriority priority;
    FeeRateType feeRateType = FeeRateType.slow;
    switch (feeRate) {
      case 1:
        priority = lib_monero.TransactionPriority.low;
        feeRateType = FeeRateType.average;
        break;
      case 2:
        priority = lib_monero.TransactionPriority.medium;
        feeRateType = FeeRateType.average;
        break;
      case 3:
        priority = lib_monero.TransactionPriority.high;
        feeRateType = FeeRateType.fast;
        break;
      case 4:
        priority = lib_monero.TransactionPriority.last;
        feeRateType = FeeRateType.fast;
        break;
      case 0:
      default:
        priority = lib_monero.TransactionPriority.normal;
        feeRateType = FeeRateType.slow;
        break;
    }

    dynamic approximateFee;
    await estimateFeeMutex.protect(() async {
      {
        try {
          final data = await prepareSend(
            txData: TxData(
              recipients: [
                // This address is only used for getting an approximate fee, never for sending
                (
                  address:
                      "WW3iVcnoAY6K9zNdU4qmdvZELefx6xZz4PMpTwUifRkvMQckyadhSPYMVPJhBdYE8P9c27fg9RPmVaWNFx1cDaj61HnetqBiy",
                  amount: amount,
                  isChange: false,
                ),
              ],
              feeRateType: feeRateType,
            ),
          );
          approximateFee = data.fee!;

          // unsure why this delay?
          await Future<void>.delayed(const Duration(milliseconds: 500));
        } catch (e) {
          approximateFee = libMoneroWallet!.estimateFee(
            priority,
            amount.raw.toInt(),
          );
        }
      }
    });

    if (approximateFee is Amount) {
      return approximateFee as Amount;
    } else {
      return Amount(
        rawValue: BigInt.from(approximateFee as int),
        fractionDigits: cryptoCurrency.fractionDigits,
      );
    }
  }

  @override
  bool walletExists(String path) =>
      lib_monero.WowneroWallet.isWalletExist(path);

  @override
  void loadWallet({
    required String path,
    required String password,
  }) {
    libMoneroWallet = lib_monero.WowneroWallet.loadWallet(
      path: path,
      password: password,
    );
  }

  @override
  Future<lib_monero.Wallet> getCreatedWallet({
    required String path,
    required String password,
  }) async =>
      await lib_monero.WowneroWallet.create(
        path: path,
        password: password,
        seedType: lib_monero.WowneroSeedType
            .fourteen, // TODO: check we want to actually use 14 here
        overrideDeprecated14WordSeedException: true,
      );

  @override
  Future<lib_monero.Wallet> getRestoredWallet({
    required String path,
    required String password,
    required String mnemonic,
    int height = 0,
  }) async =>
      await lib_monero.WowneroWallet.restoreWalletFromSeed(
        path: path,
        password: password,
        seed: mnemonic,
        restoreHeight: height,
      );

  @override
  void invalidSeedLengthCheck(int length) {
    if (!(length == 14 || length == 25)) {
      throw Exception("Invalid wownero mnemonic length found: $length");
    }
  }
}

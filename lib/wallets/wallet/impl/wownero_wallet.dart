import 'dart:async';

import 'package:compat/compat.dart' as lib_monero_compat;

import '../../../models/isar/models/blockchain_data/address.dart';
import '../../../utilities/amount/amount.dart';
import '../../../utilities/enums/fee_rate_type_enum.dart';
import '../../../wl_gen/interfaces/cs_monero_interface.dart';
import '../../../wl_gen/interfaces/cs_salvium_interface.dart'
    show WrappedWallet;
import '../../crypto_currency/crypto_currency.dart';
import '../../models/tx_data.dart';
import '../intermediate/lib_monero_wallet.dart';

class WowneroWallet extends LibMoneroWallet {
  WowneroWallet(CryptoCurrencyNetwork network)
    : super(Wownero(network), lib_monero_compat.WalletType.wownero);

  @override
  Future<Amount> estimateFeeFor(Amount amount, BigInt feeRate) async {
    if (wallet == null || syncStatus is! lib_monero_compat.SyncedSyncStatus) {
      return Amount.zeroWith(fractionDigits: cryptoCurrency.fractionDigits);
    }

    FeeRateType feeRateType = FeeRateType.slow;
    switch (feeRate.toInt()) {
      case 1:
        feeRateType = FeeRateType.average;
        break;
      case 2:
        feeRateType = FeeRateType.average;
        break;
      case 3:
        feeRateType = FeeRateType.fast;
        break;
      case 4:
        feeRateType = FeeRateType.fast;
        break;
      case 0:
      default:
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
                TxRecipient(
                  address:
                      "WW3iVcnoAY6K9zNdU4qmdvZELefx6xZz4PMpTwUifRkvMQckyadhSPYMVPJhBdYE8P9c27fg9RPmVaWNFx1cDaj61HnetqBiy",
                  amount: amount,
                  isChange: false,
                  addressType: AddressType.cryptonote,
                ),
              ],
              feeRateType: feeRateType,
            ),
          );
          approximateFee = data.fee!;

          // unsure why this delay?
          await Future<void>.delayed(const Duration(milliseconds: 500));
        } catch (e) {
          approximateFee = await csMonero.estimateFee(
            feeRate.toInt(),
            amount.raw,
            wallet: wallet!,
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
      csMonero.walletExists(path, csCoin: CsCoin.wownero);

  @override
  Future<WrappedWallet> loadWallet({
    required String path,
    required String password,
  }) => csMonero.loadWallet(
    walletId,
    path: path,
    password: password,
    csCoin: CsCoin.wownero,
  );

  @override
  Future<WrappedWallet> getCreatedWallet({
    required String path,
    required String password,
    required int wordCount,
    required String seedOffset,
  }) => csMonero.getCreatedWallet(
    csCoin: CsCoin.wownero,
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
  }) => csMonero.getRestoredWallet(
    path: path,
    password: password,
    mnemonic: mnemonic,
    height: height,
    seedOffset: seedOffset,
    csCoin: CsCoin.wownero,
    walletId: walletId,
  );

  @override
  Future<WrappedWallet> getRestoredFromViewKeyWallet({
    required String path,
    required String password,
    required String address,
    required String privateViewKey,
    int height = 0,
  }) => csMonero.getRestoredFromViewKeyWallet(
    walletId: walletId,
    csCoin: CsCoin.wownero,
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

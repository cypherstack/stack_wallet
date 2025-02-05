import 'package:isar/isar.dart';

import '../db/isar/main_db.dart';
import '../wallets/crypto_currency/crypto_currency.dart';
import 'amount/amount.dart';
import 'amount/amount_formatter.dart';
import 'amount/amount_unit.dart';

abstract class WalletDevTools {
  static String checkFiroTransactionTally(String walletId) {
    final amtFmt = AmountFormatter(
      unit: AmountUnit.normal,
      locale: "en_US",
      coin: Firo(CryptoCurrencyNetwork.main),
      maxDecimals: 8,
    );

    final all = MainDB.instance.isar.transactionV2s
        .where()
        .walletIdEqualTo(walletId)
        .findAllSync();

    final totalCount = all.length;

    BigInt runningBalance = BigInt.zero;
    for (final tx in all) {
      final ownIns = tx.inputs
          .where((e) => e.walletOwns)
          .map((e) => e.value)
          .fold(BigInt.zero, (p, e) => p + e);
      runningBalance -= ownIns;

      final ownOuts = tx.outputs
          .where((e) => e.walletOwns)
          .map((e) => e.value)
          .fold(BigInt.zero, (p, e) => p + e);
      runningBalance += ownOuts;
    }

    final balanceAccordingToTxHistory = Amount(
      rawValue: runningBalance,
      fractionDigits: 8,
    );

    print("======== $walletId =============");
    print("totalTxCount: $totalCount");
    print(
      "balanceAccordingToTxns: ${amtFmt.format(balanceAccordingToTxHistory)}",
    );
    print("==================================================");

    return amtFmt.format(balanceAccordingToTxHistory);
  }
}

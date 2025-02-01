import 'package:isar/isar.dart';

import '../db/isar/main_db.dart';
import '../models/isar/models/blockchain_data/v2/transaction_v2.dart';
import '../models/isar/models/firo_specific/lelantus_coin.dart';
import '../wallets/crypto_currency/crypto_currency.dart';
import '../wallets/isar/models/spark_coin.dart';
import '../wallets/wallet/impl/firo_wallet.dart';
import 'amount/amount.dart';
import 'amount/amount_formatter.dart';
import 'amount/amount_unit.dart';
import 'logger.dart';

abstract class WalletDevTools {
  static String checkFiroTransactionTally(FiroWallet wallet) {
    final amtFmt = AmountFormatter(
      unit: AmountUnit.normal,
      locale: "en_US",
      coin: Firo(CryptoCurrencyNetwork.main),
      maxDecimals: 8,
    );

    final all = MainDB.instance.isar.transactionV2s
        .where()
        .walletIdEqualTo(wallet.walletId)
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

    final lelantusCoinsCount = MainDB.instance.isar.lelantusCoins
        .where()
        .walletIdEqualTo(wallet.walletId)
        .countSync();
    final sparkCoinsCount = MainDB.instance.isar.sparkCoins
        .where()
        .walletIdEqualToAnyLTagHash(wallet.walletId)
        .countSync();

    final buffer = StringBuffer();
    buffer.writeln("============= ${wallet.info.name} =============");
    buffer.writeln("wallet id: ${wallet.walletId}");
    buffer.writeln("totalTxCount: $totalCount");
    buffer.writeln(
      "balanceAccordingToTxns: ${amtFmt.format(balanceAccordingToTxHistory)}",
    );
    buffer.writeln("lelantusCoinsCount: $lelantusCoinsCount");
    buffer.writeln("sparkCoinsCount: $sparkCoinsCount");
    buffer.writeln("==================================================");

    Logging.instance.d(buffer);

    return amtFmt.format(balanceAccordingToTxHistory);
  }
}

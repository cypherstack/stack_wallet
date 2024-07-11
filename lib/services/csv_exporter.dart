import 'package:csv/csv.dart';

import '../models/isar/models/blockchain_data/v2/transaction_v2.dart';
import '../models/isar/models/isar_models.dart';
import '../utilities/amount/amount.dart';
import '../utilities/amount/amount_formatter.dart';
import '../utilities/amount/amount_unit.dart';
import '../wallets/crypto_currency/crypto_currency.dart';

abstract final class CsvExporter {
  static String transactionV2sToCsv(
    List<TransactionV2> transactions,
    List<TransactionNote> notes,
    CryptoCurrency coin,
    String locale,
    EthContract? ethContract,
    String? sparkChangeAddress,
  ) {
    final List<List<dynamic>?> rows = [];

    rows.add([
      "Timestamp",
      "Height",
      "Txid",
      "Amount",
      "Fee",
      "Type",
      "Sub Type",
      "Note",
      "Input Addresses",
      "Output Addresses",
    ]);

    for (final _transaction in transactions) {
      final amountFormatter = AmountFormatter(
        unit: AmountUnit.normal,
        locale: locale,
        coin: coin,
        maxDecimals: coin.fractionDigits,
      );
      final List<String> row = [];

      // unix timestamp
      row.add(_transaction.timestamp.toString());

      // height
      row.add(_transaction.height.toString());

      // txid
      row.add(_transaction.txid);

      // amount
      row.add(
        _parseAmountFromTxnV2(
          _transaction,
          amountFormatter,
          ethContract,
          sparkChangeAddress,
        ),
      );

      // fee
      row.add(
        amountFormatter.format(
          _transaction.getFee(
              fractionDigits: amountFormatter.coin.fractionDigits),
          ethContract: ethContract,
          withUnitName: false,
        ),
      );

      // type
      row.add(_transaction.type.name);

      // sub type
      row.add(_transaction.subType.name);

      // note
      final note = notes.firstWhere(
        (e) => e.txid == _transaction.txid,
        orElse: () => TransactionNote(walletId: "", txid: "", value: ""),
      );
      row.add(note.value);

      // in addresses
      row.add(_transaction.inputs.map((e) => e.addresses.join(",")).join(","));

      // out addresses
      row.add(_transaction.outputs.map((e) => e.addresses.join(",")).join(","));

      // finally add row
      rows.add(row);
    }

    // convert
    final csv = const ListToCsvConverter().convert(rows);

    return csv;
  }

  static String _parseAmountFromTxnV2(
    TransactionV2 txn,
    AmountFormatter amountFormatter,
    EthContract? ethContract,
    String? sparkChangeAddress,
  ) {
    final Amount amount;
    final fractionDigits =
        ethContract?.decimals ?? amountFormatter.coin.fractionDigits;
    if (txn.subType == TransactionSubType.cashFusion) {
      amount = txn.getAmountReceivedInThisWallet(
        fractionDigits: fractionDigits,
      );
    } else {
      switch (txn.type) {
        case TransactionType.outgoing:
          amount = txn.getAmountSentFromThisWallet(
            fractionDigits: fractionDigits,
          );
          break;

        case TransactionType.incoming:
        case TransactionType.sentToSelf:
          if (txn.subType == TransactionSubType.sparkMint) {
            amount = txn.getAmountSparkSelfMinted(
              fractionDigits: fractionDigits,
            );
          } else if (txn.subType == TransactionSubType.sparkSpend) {
            amount = Amount(
              rawValue: txn.outputs
                  .where(
                    (e) =>
                        e.walletOwns &&
                        !e.addresses.contains(sparkChangeAddress!),
                  )
                  .fold(BigInt.zero, (p, e) => p + e.value),
              fractionDigits: amountFormatter.coin.fractionDigits,
            );
          } else {
            amount = txn.getAmountReceivedInThisWallet(
              fractionDigits: fractionDigits,
            );
          }
          break;

        case TransactionType.unknown:
          amount = txn.getAmountSentFromThisWallet(
            fractionDigits: fractionDigits,
          );
          break;
      }
    }

    return amountFormatter.format(
      amount,
      ethContract: ethContract,
      withUnitName: false,
    );
  }
}

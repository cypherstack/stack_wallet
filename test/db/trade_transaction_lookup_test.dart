import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:stackwallet/db/isar/main_db.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/address.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/transaction.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/v2/transaction_v2.dart';

import '../support/isar_test_utils.dart';

void main() {
  test(
    'trade lookup is wallet-scoped and reads both transaction versions',
    () async {
      await initializeTestIsar();
      final directory = await Directory.systemTemp.createTemp('trade-lookup-');
      addTearDown(() => directory.delete(recursive: true));
      final isar = await Isar.open(
        [AddressSchema, TransactionSchema, TransactionV2Schema],
        directory: directory.path,
        name: 'trade-lookup',
        inspector: false,
      );
      addTearDown(isar.close);
      final db = MainDB.instance;
      await db.initMainDB(mock: isar);

      // Both collections index the pair (transaction ID, wallet ID).
      const txid = 'pay-in';
      const first = {'walletId': 'first', 'txid': txid};
      const second = {'walletId': 'second', 'txid': txid};
      await isar.writeTxn(() async {
        await isar.transactions.importJson([first]);
        await isar.transactionV2s.importJson([second]);
      });
      expect(await db.getTradeTransaction('first', txid), isA<Transaction>());
      expect(
        await db.getTradeTransaction('second', txid),
        isA<TransactionV2>(),
      );
      expect(await db.getTradeTransaction('third', txid), isNull);
      await isar.writeTxn(() => isar.transactionV2s.importJson([first]));
      expect(await db.getTradeTransaction('first', txid), isA<TransactionV2>());
    },
  );
}

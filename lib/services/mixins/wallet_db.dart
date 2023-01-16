import 'package:isar/isar.dart';
import 'package:stackwallet/db/main_db.dart';
import 'package:stackwallet/models/isar/models/isar_models.dart';
import 'package:tuple/tuple.dart';

mixin WalletDB {
  MainDB get db => MainDB.instance;

  Future<void> isarInit(String walletId) async {
    await db.isarInit();
  }

  Future<void> addNewTransactionData(
      List<Tuple4<Transaction, List<Output>, List<Input>, Address?>>
          transactionsData,
      String walletId) async {
    await db.isar.writeTxn(() async {
      for (final data in transactionsData) {
        final tx = data.item1;

        final potentiallyUnconfirmedTx = await db
            .getTransactions(walletId)
            .filter()
            .txidEqualTo(tx.txid)
            .findFirst();
        if (potentiallyUnconfirmedTx != null) {
          // update use id to replace tx
          tx.id = potentiallyUnconfirmedTx.id;
          await db.isar.transactions.delete(potentiallyUnconfirmedTx.id);
        }
        // save transaction
        await db.isar.transactions.put(tx);

        // link and save outputs
        if (data.item2.isNotEmpty) {
          await db.isar.outputs.putAll(data.item2);
          tx.outputs.addAll(data.item2);
          await tx.outputs.save();
        }

        // link and save inputs
        if (data.item3.isNotEmpty) {
          await db.isar.inputs.putAll(data.item3);
          tx.inputs.addAll(data.item3);
          await tx.inputs.save();
        }

        if (data.item4 != null) {
          final address = await db
              .getAddresses(walletId)
              .filter()
              .valueEqualTo(data.item4!.value)
              .findFirst();

          // check if address exists in db and add if it does not
          if (address == null) {
            await db.isar.addresses.put(data.item4!);
          }

          // link and save address
          tx.address.value = address ?? data.item4!;
          await tx.address.save();
        }
      }
    });
  }
}

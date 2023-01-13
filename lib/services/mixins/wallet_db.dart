import 'package:isar/isar.dart';
import 'package:stackwallet/models/isar/models/isar_models.dart';
import 'package:stackwallet/utilities/stack_file_system.dart';
import 'package:tuple/tuple.dart';

mixin WalletDB {
  Isar? _isar;

  Isar get isar => _isar!;

  /// open the db if it was not already open
  /// returns true if the db was not yet open
  /// returns false if the db was already open
  Future<bool> isarInit(String walletId) async {
    if (_isar != null && isar.isOpen) return false;
    _isar = await Isar.open(
      [
        TransactionSchema,
        TransactionNoteSchema,
        InputSchema,
        OutputSchema,
        UTXOSchema,
        AddressSchema,
      ],
      directory: (await StackFileSystem.applicationIsarDirectory()).path,
      inspector: true,
      name: walletId,
    );
    return true;
  }

  Future<bool> isarClose() async => await _isar?.close() ?? false;

  Future<void> addNewTransactionData(
      List<Tuple4<Transaction, List<Output>, List<Input>, Address?>>
          transactionsData) async {
    await isar.writeTxn(() async {
      for (final data in transactionsData) {
        final tx = data.item1;

        final potentiallyUnconfirmedTx =
            await isar.transactions.where().txidEqualTo(tx.txid).findFirst();
        if (potentiallyUnconfirmedTx != null) {
          // update use id to replace tx
          tx.id = potentiallyUnconfirmedTx.id;
          await isar.transactions.delete(potentiallyUnconfirmedTx.id);
        }
        // save transaction
        await isar.transactions.put(tx);

        // link and save outputs
        if (data.item2.isNotEmpty) {
          await isar.outputs.putAll(data.item2);
          tx.outputs.addAll(data.item2);
          await tx.outputs.save();
        }

        // link and save inputs
        if (data.item3.isNotEmpty) {
          await isar.inputs.putAll(data.item3);
          tx.inputs.addAll(data.item3);
          await tx.inputs.save();
        }

        if (data.item4 != null) {
          final address = await isar.addresses
              .where()
              .valueEqualTo(data.item4!.value)
              .findFirst();

          // check if address exists in db and add if it does not
          if (address == null) {
            await isar.addresses.put(data.item4!);
          }

          // link and save address
          tx.address.value = address ?? data.item4!;
          await tx.address.save();
        }
      }
    });
  }
}

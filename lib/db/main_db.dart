import 'package:isar/isar.dart';
import 'package:stackwallet/models/isar/models/isar_models.dart';
import 'package:stackwallet/utilities/stack_file_system.dart';

class MainDB {
  MainDB._();
  static MainDB? _instance;
  static MainDB get instance => _instance ??= MainDB._();

  Isar? _isar;

  Isar get isar => _isar!;

  Future<bool> isarInit() async {
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
      name: "wallet_data",
    );
    return true;
  }

  // addresses
  QueryBuilder<Address, Address, QAfterWhereClause> getAddresses(
          String walletId) =>
      isar.addresses.where().walletIdEqualTo(walletId);

  Future<void> putAddress(Address address) => isar.writeTxn(() async {
        await isar.addresses.put(address);
      });

  Future<void> putAddresses(List<Address> addresses) => isar.writeTxn(() async {
        await isar.addresses.putAll(addresses);
      });

  Future<void> updateAddress(Address oldAddress, Address newAddress) =>
      isar.writeTxn(() async {
        newAddress.id = oldAddress.id;
        await oldAddress.transactions.load();
        final txns = oldAddress.transactions.toList();
        await isar.addresses.delete(oldAddress.id);
        await isar.addresses.put(newAddress);
        newAddress.transactions.addAll(txns);
        await newAddress.transactions.save();
      });

  // transactions
  QueryBuilder<Transaction, Transaction, QAfterWhereClause> getTransactions(
          String walletId) =>
      isar.transactions.where().walletIdEqualTo(walletId);

  Future<void> putTransaction(Transaction transaction) =>
      isar.writeTxn(() async {
        await isar.transactions.put(transaction);
      });

  Future<void> putTransactions(List<Transaction> transactions) =>
      isar.writeTxn(() async {
        await isar.transactions.putAll(transactions);
      });

  // utxos
  QueryBuilder<UTXO, UTXO, QAfterWhereClause> getUTXOs(String walletId) =>
      isar.utxos.where().walletIdEqualTo(walletId);

  Future<void> putUTXO(UTXO utxo) => isar.writeTxn(() async {
        await isar.utxos.put(utxo);
      });

  Future<void> putUTXOs(List<UTXO> utxos) => isar.writeTxn(() async {
        await isar.utxos.putAll(utxos);
      });

  // inputs
  QueryBuilder<Input, Input, QAfterWhereClause> getInputs(String walletId) =>
      isar.inputs.where().walletIdEqualTo(walletId);

  Future<void> putInput(Input input) => isar.writeTxn(() async {
        await isar.inputs.put(input);
      });

  Future<void> putInputs(List<Input> inputs) => isar.writeTxn(() async {
        await isar.inputs.putAll(inputs);
      });

  // outputs
  QueryBuilder<Output, Output, QAfterWhereClause> getOutputs(String walletId) =>
      isar.outputs.where().walletIdEqualTo(walletId);

  Future<void> putOutput(Output output) => isar.writeTxn(() async {
        await isar.outputs.put(output);
      });

  Future<void> putOutputs(List<Output> outputs) => isar.writeTxn(() async {
        await isar.outputs.putAll(outputs);
      });

  // transaction notes
  QueryBuilder<TransactionNote, TransactionNote, QAfterWhereClause>
      getTransactionNotes(String walletId) =>
          isar.transactionNotes.where().walletIdEqualTo(walletId);

  Future<void> putTransactionNote(TransactionNote transactionNote) =>
      isar.writeTxn(() async {
        await isar.transactionNotes.put(transactionNote);
      });

  Future<void> putTransactionNotes(List<TransactionNote> transactionNotes) =>
      isar.writeTxn(() async {
        await isar.transactionNotes.putAll(transactionNotes);
      });

  //
  Future<void> deleteWalletBlockchainData(String walletId) async {
    final transactionCount = await getTransactions(walletId).count();
    final addressCount = await getAddresses(walletId).count();
    final utxoCount = await getUTXOs(walletId).count();
    final inputCount = await getInputs(walletId).count();
    final outputCount = await getOutputs(walletId).count();

    await isar.writeTxn(() async {
      const paginateLimit = 50;

      // transactions
      for (int i = 0; i < transactionCount; i += paginateLimit) {
        final txns = await getTransactions(walletId)
            .offset(i)
            .limit(paginateLimit)
            .findAll();
        await isar.transactions
            .deleteAll(txns.map((e) => e.id).toList(growable: false));
      }

      // addresses
      for (int i = 0; i < addressCount; i += paginateLimit) {
        final addresses = await getAddresses(walletId)
            .offset(i)
            .limit(paginateLimit)
            .findAll();
        await isar.addresses
            .deleteAll(addresses.map((e) => e.id).toList(growable: false));
      }

      // utxos
      for (int i = 0; i < utxoCount; i += paginateLimit) {
        final utxos =
            await getUTXOs(walletId).offset(i).limit(paginateLimit).findAll();
        await isar.utxos
            .deleteAll(utxos.map((e) => e.id).toList(growable: false));
      }

      // inputs
      for (int i = 0; i < inputCount; i += paginateLimit) {
        final inputs =
            await getInputs(walletId).offset(i).limit(paginateLimit).findAll();
        await isar.inputs
            .deleteAll(inputs.map((e) => e.id).toList(growable: false));
      }

      // outputs
      for (int i = 0; i < outputCount; i += paginateLimit) {
        final outputs =
            await getOutputs(walletId).offset(i).limit(paginateLimit).findAll();
        await isar.outputs
            .deleteAll(outputs.map((e) => e.id).toList(growable: false));
      }
    });
  }
}

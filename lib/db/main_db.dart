import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import 'package:stackwallet/exceptions/main_db/main_db_exception.dart';
import 'package:stackwallet/models/isar/models/isar_models.dart';
import 'package:stackwallet/utilities/stack_file_system.dart';
import 'package:tuple/tuple.dart';

class MainDB {
  MainDB._();
  static MainDB? _instance;
  static MainDB get instance => _instance ??= MainDB._();

  Isar? _isar;

  Isar get isar => _isar!;

  Future<bool> initMainDB({Isar? mock}) async {
    if (mock != null) {
      _isar = mock;
      return true;
    }
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
      inspector: kDebugMode,
      name: "wallet_data",
    );
    return true;
  }

  // addresses
  QueryBuilder<Address, Address, QAfterWhereClause> getAddresses(
          String walletId) =>
      isar.addresses.where().walletIdEqualTo(walletId);

  Future<int> putAddress(Address address) async {
    try {
      return await isar.writeTxn(() async {
        return await isar.addresses.put(address);
      });
    } catch (e) {
      throw MainDBException("failed putAddress: $address", e);
    }
  }

  Future<List<int>> putAddresses(List<Address> addresses) async {
    try {
      return await isar.writeTxn(() async {
        return await isar.addresses.putAll(addresses);
      });
    } catch (e) {
      throw MainDBException("failed putAddresses: $addresses", e);
    }
  }

  Future<List<int>> updateOrPutAddresses(List<Address> addresses) async {
    try {
      List<int> ids = [];
      await isar.writeTxn(() async {
        for (final address in addresses) {
          final storedAddress = await isar.addresses
              .getByValueWalletId(address.value, address.walletId);

          int id;
          if (storedAddress == null) {
            id = await isar.addresses.put(address);
          } else {
            address.id = storedAddress.id;
            await storedAddress.transactions.load();
            final txns = storedAddress.transactions.toList();
            await isar.addresses.delete(storedAddress.id);
            id = await isar.addresses.put(address);
            address.transactions.addAll(txns);
            await address.transactions.save();
          }
          ids.add(id);
        }
      });
      return ids;
    } catch (e) {
      throw MainDBException("failed updateOrPutAddresses: $addresses", e);
    }
  }

  Future<Address?> getAddress(String walletId, String address) async {
    return isar.addresses.getByValueWalletId(address, walletId);
  }

  Future<int> updateAddress(Address oldAddress, Address newAddress) async {
    try {
      return await isar.writeTxn(() async {
        newAddress.id = oldAddress.id;
        await oldAddress.transactions.load();
        final txns = oldAddress.transactions.toList();
        await isar.addresses.delete(oldAddress.id);
        final id = await isar.addresses.put(newAddress);
        newAddress.transactions.addAll(txns);
        await newAddress.transactions.save();
        return id;
      });
    } catch (e) {
      throw MainDBException(
          "failed updateAddress: from=$oldAddress to=$newAddress", e);
    }
  }

  // transactions
  QueryBuilder<Transaction, Transaction, QAfterWhereClause> getTransactions(
          String walletId) =>
      isar.transactions.where().walletIdEqualTo(walletId);

  Future<int> putTransaction(Transaction transaction) async {
    try {
      return await isar.writeTxn(() async {
        return await isar.transactions.put(transaction);
      });
    } catch (e) {
      throw MainDBException("failed putTransaction: $transaction", e);
    }
  }

  Future<List<int>> putTransactions(List<Transaction> transactions) async {
    try {
      return await isar.writeTxn(() async {
        return await isar.transactions.putAll(transactions);
      });
    } catch (e) {
      throw MainDBException("failed putTransactions: $transactions", e);
    }
  }

  Future<Transaction?> getTransaction(String walletId, String txid) async {
    return isar.transactions.getByTxidWalletId(txid, walletId);
  }

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

  Future<void> addNewTransactionData(
    List<Tuple4<Transaction, List<Output>, List<Input>, Address?>>
        transactionsData,
    String walletId,
  ) async {
    try {
      await isar.writeTxn(() async {
        for (final data in transactionsData) {
          final tx = data.item1;

          final potentiallyUnconfirmedTx = await getTransactions(walletId)
              .filter()
              .txidEqualTo(tx.txid)
              .findFirst();
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
            final address = await getAddresses(walletId)
                .filter()
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
    } catch (e) {
      throw MainDBException("failed addNewTransactionData", e);
    }
  }
}

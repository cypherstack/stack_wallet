import 'package:isar/isar.dart';
import 'package:stackwallet/exceptions/main_db/main_db_exception.dart';
import 'package:stackwallet/exceptions/sw_exception.dart';
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
        UTXOSchema,
        AddressSchema,
        AddressLabelSchema,
        EthContractSchema,
      ],
      directory: (await StackFileSystem.applicationIsarDirectory()).path,
      // inspector: kDebugMode,
      inspector: false,
      name: "wallet_data",
      maxSizeMiB: 512,
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

  Stream<Transaction?> watchTransaction({
    required Id id,
    bool fireImmediately = false,
  }) {
    return isar.transactions.watchObject(id, fireImmediately: fireImmediately);
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

  Future<TransactionNote?> getTransactionNote(
      String walletId, String txid) async {
    return isar.transactionNotes.getByTxidWalletId(
      txid,
      walletId,
    );
  }

  Stream<TransactionNote?> watchTransactionNote({
    required Id id,
    bool fireImmediately = false,
  }) {
    return isar.transactionNotes
        .watchObject(id, fireImmediately: fireImmediately);
  }

  // address labels
  QueryBuilder<AddressLabel, AddressLabel, QAfterWhereClause> getAddressLabels(
          String walletId) =>
      isar.addressLabels.where().walletIdEqualTo(walletId);

  Future<int> putAddressLabel(AddressLabel addressLabel) =>
      isar.writeTxn(() async {
        return await isar.addressLabels.put(addressLabel);
      });

  int putAddressLabelSync(AddressLabel addressLabel) => isar.writeTxnSync(() {
        return isar.addressLabels.putSync(addressLabel);
      });

  Future<void> putAddressLabels(List<AddressLabel> addressLabels) =>
      isar.writeTxn(() async {
        await isar.addressLabels.putAll(addressLabels);
      });

  Future<AddressLabel?> getAddressLabel(
      String walletId, String addressString) async {
    return isar.addressLabels.getByAddressStringWalletId(
      addressString,
      walletId,
    );
  }

  AddressLabel? getAddressLabelSync(String walletId, String addressString) {
    return isar.addressLabels.getByAddressStringWalletIdSync(
      addressString,
      walletId,
    );
  }

  Stream<AddressLabel?> watchAddressLabel({
    required Id id,
    bool fireImmediately = false,
  }) {
    return isar.addressLabels.watchObject(id, fireImmediately: fireImmediately);
  }

  Future<int> updateAddressLabel(AddressLabel addressLabel) async {
    try {
      return await isar.writeTxn(() async {
        final deleted = await isar.addresses.delete(addressLabel.id);
        if (!deleted) {
          throw SWException("Failed to delete $addressLabel before updating");
        }
        return await isar.addressLabels.put(addressLabel);
      });
    } catch (e) {
      throw MainDBException("failed updateAddressLabel", e);
    }
  }

  //
  Future<void> deleteWalletBlockchainData(String walletId) async {
    final transactionCount = await getTransactions(walletId).count();
    final addressCount = await getAddresses(walletId).count();
    final utxoCount = await getUTXOs(walletId).count();

    await isar.writeTxn(() async {
      const paginateLimit = 50;

      // transactions
      for (int i = 0; i < transactionCount; i += paginateLimit) {
        final txnIds = await getTransactions(walletId)
            .offset(i)
            .limit(paginateLimit)
            .idProperty()
            .findAll();
        await isar.transactions.deleteAll(txnIds);
      }

      // addresses
      for (int i = 0; i < addressCount; i += paginateLimit) {
        final addressIds = await getAddresses(walletId)
            .offset(i)
            .limit(paginateLimit)
            .idProperty()
            .findAll();
        await isar.addresses.deleteAll(addressIds);
      }

      // utxos
      for (int i = 0; i < utxoCount; i += paginateLimit) {
        final utxoIds = await getUTXOs(walletId)
            .offset(i)
            .limit(paginateLimit)
            .idProperty()
            .findAll();
        await isar.utxos.deleteAll(utxoIds);
      }
    });
  }

  Future<void> deleteAddressLabels(String walletId) async {
    final addressLabelCount = await getAddressLabels(walletId).count();
    await isar.writeTxn(() async {
      const paginateLimit = 50;
      for (int i = 0; i < addressLabelCount; i += paginateLimit) {
        final labelIds = await getAddressLabels(walletId)
            .offset(i)
            .limit(paginateLimit)
            .idProperty()
            .findAll();
        await isar.addressLabels.deleteAll(labelIds);
      }
    });
  }

  Future<void> deleteTransactionNotes(String walletId) async {
    final noteCount = await getTransactionNotes(walletId).count();
    await isar.writeTxn(() async {
      const paginateLimit = 50;
      for (int i = 0; i < noteCount; i += paginateLimit) {
        final labelIds = await getTransactionNotes(walletId)
            .offset(i)
            .limit(paginateLimit)
            .idProperty()
            .findAll();
        await isar.transactionNotes.deleteAll(labelIds);
      }
    });
  }

  Future<void> addNewTransactionData(
    List<Tuple2<Transaction, Address?>> transactionsData,
    String walletId,
  ) async {
    try {
      await isar.writeTxn(() async {
        for (final data in transactionsData) {
          final tx = data.item1;

          final potentiallyUnconfirmedTx = await getTransaction(
            walletId,
            tx.txid,
          );
          if (potentiallyUnconfirmedTx != null) {
            // update use id to replace tx
            tx.id = potentiallyUnconfirmedTx.id;
            await isar.transactions.delete(potentiallyUnconfirmedTx.id);
          }
          // save transaction
          await isar.transactions.put(tx);

          if (data.item2 != null) {
            final address = await getAddress(walletId, data.item2!.value);

            // check if address exists in db and add if it does not
            if (address == null) {
              await isar.addresses.put(data.item2!);
            }

            // link and save address
            tx.address.value = address ?? data.item2!;
            await tx.address.save();
          }
        }
      });
    } catch (e) {
      throw MainDBException("failed addNewTransactionData", e);
    }
  }
}

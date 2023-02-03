import 'dart:convert';

import 'package:hive/hive.dart';
import 'package:stackwallet/db/main_db.dart';
import 'package:stackwallet/electrumx_rpc/electrumx.dart';
import 'package:stackwallet/hive/db.dart';
import 'package:stackwallet/models/exchange/change_now/exchange_transaction.dart';
import 'package:stackwallet/models/exchange/response_objects/trade.dart';
import 'package:stackwallet/models/isar/models/isar_models.dart' as isar_models;
import 'package:stackwallet/models/models.dart';
import 'package:stackwallet/models/node_model.dart';
import 'package:stackwallet/services/mixins/wallet_db.dart';
import 'package:stackwallet/services/node_service.dart';
import 'package:stackwallet/services/wallets_service.dart';
import 'package:stackwallet/utilities/default_nodes.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/utilities/flutter_secure_storage_interface.dart';
import 'package:stackwallet/utilities/format.dart';
import 'package:stackwallet/utilities/logger.dart';
import 'package:stackwallet/utilities/prefs.dart';
import 'package:tuple/tuple.dart';

class DbVersionMigrator with WalletDB {
  Future<void> migrate(
    int fromVersion, {
    required SecureStorageInterface secureStore,
  }) async {
    Logging.instance.log(
      "Running migrate fromVersion $fromVersion",
      level: LogLevel.Warning,
    );
    switch (fromVersion) {
      case 0:
        await Hive.openBox<dynamic>(DB.boxNameAllWalletsData);
        await Hive.openBox<dynamic>(DB.boxNamePrefs);
        final walletsService =
            WalletsService(secureStorageInterface: secureStore);
        final nodeService = NodeService(secureStorageInterface: secureStore);
        final prefs = Prefs.instance;
        final walletInfoList = await walletsService.walletNames;
        await prefs.init();

        ElectrumX? client;
        int? latestSetId;

        // only instantiate client if there are firo wallets
        if (walletInfoList.values.any((element) => element.coin == Coin.firo)) {
          await Hive.openBox<NodeModel>(DB.boxNameNodeModels);
          await Hive.openBox<NodeModel>(DB.boxNamePrimaryNodes);
          final node = nodeService.getPrimaryNodeFor(coin: Coin.firo) ??
              DefaultNodes.firo;
          List<ElectrumXNode> failovers = nodeService
              .failoverNodesFor(coin: Coin.firo)
              .map(
                (e) => ElectrumXNode(
                  address: e.host,
                  port: e.port,
                  name: e.name,
                  id: e.id,
                  useSSL: e.useSSL,
                ),
              )
              .toList();

          client = ElectrumX.from(
            node: ElectrumXNode(
                address: node.host,
                port: node.port,
                name: node.name,
                id: node.id,
                useSSL: node.useSSL),
            prefs: prefs,
            failovers: failovers,
          );

          try {
            latestSetId = await client.getLatestCoinId();
          } catch (e) {
            // default to 2 for now
            latestSetId = 2;
            Logging.instance.log(
                "Failed to fetch latest coin id during firo db migrate: $e \nUsing a default value of 2",
                level: LogLevel.Warning);
          }
        }

        for (final walletInfo in walletInfoList.values) {
          // migrate each firo wallet's lelantus coins
          if (walletInfo.coin == Coin.firo) {
            await Hive.openBox<dynamic>(walletInfo.walletId);
            final _lelantusCoins = DB.instance.get<dynamic>(
                boxName: walletInfo.walletId, key: '_lelantus_coins') as List?;
            final List<Map<dynamic, LelantusCoin>> lelantusCoins = [];
            for (var lCoin in _lelantusCoins ?? []) {
              lelantusCoins
                  .add({lCoin.keys.first: lCoin.values.first as LelantusCoin});
            }

            List<Map<dynamic, LelantusCoin>> coins = [];
            for (final element in lelantusCoins) {
              LelantusCoin coin = element.values.first;
              int anonSetId = coin.anonymitySetId;
              if (coin.anonymitySetId == 1 &&
                  (coin.publicCoin == '' ||
                      coin.publicCoin == "jmintData.publicCoin")) {
                anonSetId = latestSetId!;
              }
              coins.add({
                element.keys.first: LelantusCoin(coin.index, coin.value,
                    coin.publicCoin, coin.txId, anonSetId, coin.isUsed)
              });
            }
            Logger.print("newcoins $coins", normalLength: false);
            await DB.instance.put<dynamic>(
                boxName: walletInfo.walletId,
                key: '_lelantus_coins',
                value: coins);
          }
        }

        // update version
        await DB.instance.put<dynamic>(
            boxName: DB.boxNameDBInfo, key: "hive_data_version", value: 1);

        // try to continue migrating
        return await migrate(1, secureStore: secureStore);

      case 1:
        await Hive.openBox<ExchangeTransaction>(DB.boxNameTrades);
        await Hive.openBox<Trade>(DB.boxNameTradesV2);
        final trades =
            DB.instance.values<ExchangeTransaction>(boxName: DB.boxNameTrades);

        for (final old in trades) {
          if (old.statusObject != null) {
            final trade = Trade.fromExchangeTransaction(old, false);
            await DB.instance.put<Trade>(
              boxName: DB.boxNameTradesV2,
              key: trade.uuid,
              value: trade,
            );
          }
        }

        // update version
        await DB.instance.put<dynamic>(
            boxName: DB.boxNameDBInfo, key: "hive_data_version", value: 2);

        // try to continue migrating
        return await migrate(2, secureStore: secureStore);

      case 2:
        await Hive.openBox<dynamic>(DB.boxNamePrefs);
        final prefs = Prefs.instance;
        await prefs.init();
        if (!(await prefs.isExternalCallsSet())) {
          prefs.externalCalls = true;
        }

        // update version
        await DB.instance.put<dynamic>(
            boxName: DB.boxNameDBInfo, key: "hive_data_version", value: 3);
        return await migrate(3, secureStore: secureStore);

      case 3:
        // clear possible broken firo cache
        await DB.instance.deleteBoxFromDisk(
            boxName: DB.instance.boxNameSetCache(coin: Coin.firo));
        await DB.instance.deleteBoxFromDisk(
            boxName: DB.instance.boxNameUsedSerialsCache(coin: Coin.firo));

        // update version
        await DB.instance.put<dynamic>(
            boxName: DB.boxNameDBInfo, key: "hive_data_version", value: 4);

        // try to continue migrating
        return await migrate(4, secureStore: secureStore);

      case 4:
        // migrate
        await _v4(secureStore);

        // update version
        await DB.instance.put<dynamic>(
            boxName: DB.boxNameDBInfo, key: "hive_data_version", value: 5);

        // try to continue migrating
        return await migrate(5, secureStore: secureStore);

      default:
        // finally return
        return;
    }
  }

  Future<void> _v4(SecureStorageInterface secureStore) async {
    await Hive.openBox<dynamic>(DB.boxNameAllWalletsData);
    await Hive.openBox<dynamic>(DB.boxNamePrefs);
    final walletsService = WalletsService(secureStorageInterface: secureStore);
    final prefs = Prefs.instance;
    final walletInfoList = await walletsService.walletNames;
    await prefs.init();

    for (final walletId in walletInfoList.keys) {
      final info = walletInfoList[walletId]!;
      assert(info.walletId == walletId);

      final walletBox = await Hive.openBox<dynamic>(info.walletId);

      final receiveDerivePrefix = "${walletId}_receiveDerivations";
      final changeDerivePrefix = "${walletId}_changeDerivations";

      const receiveAddressesPrefix = "receivingAddresses";
      const changeAddressesPrefix = "changeAddresses";

      final p2pkhRcvDerivations =
          (await secureStore.read(key: receiveDerivePrefix)) ??
              (await secureStore.read(key: "${receiveDerivePrefix}P2PKH"));
      final p2shRcvDerivations =
          await secureStore.read(key: "${receiveDerivePrefix}P2SH");
      final p2wpkhRcvDerivations =
          await secureStore.read(key: "${receiveDerivePrefix}P2WPKH");

      final p2pkhCngDerivations =
          (await secureStore.read(key: changeDerivePrefix)) ??
              (await secureStore.read(key: "${changeDerivePrefix}P2PKH"));
      final p2shCngDerivations =
          await secureStore.read(key: "${changeDerivePrefix}P2SH");
      final p2wpkhCngDerivations =
          await secureStore.read(key: "${changeDerivePrefix}P2WPKH");

      // useless?
      // const receiveIndexPrefix = "receivingIndex";
      // const changeIndexPrefix = "changeIndex";
      // final p2pkhRcvIndex = walletBox.get(receiveIndexPrefix) as int? ??
      //     walletBox.get("${receiveIndexPrefix}P2PKH") as int?;
      // final p2shRcvIndex =
      //     walletBox.get("${receiveIndexPrefix}P2SH") as int?;
      // final p2wpkhRcvIndex =
      //     walletBox.get("${receiveIndexPrefix}P2WPKH") as int?;
      //
      // final p2pkhCngIndex = walletBox.get(changeIndexPrefix) as int? ??
      //     walletBox.get("${changeIndexPrefix}P2PKH") as int?;
      // final p2shCngIndex =
      //     walletBox.get("${changeIndexPrefix}P2SH") as int?;
      // final p2wpkhCngIndex =
      //     walletBox.get("${changeIndexPrefix}P2WPKH") as int?;

      final List<isar_models.Address> newAddresses = [];

      if (p2pkhRcvDerivations != null) {
        newAddresses.addAll(
          _v4GetAddressesFromDerivationString(
            p2pkhRcvDerivations,
            isar_models.AddressType.p2pkh,
            isar_models.AddressSubType.receiving,
            walletId,
          ),
        );
      }

      if (p2shRcvDerivations != null) {
        newAddresses.addAll(
          _v4GetAddressesFromDerivationString(
            p2shRcvDerivations,
            isar_models.AddressType.p2sh,
            isar_models.AddressSubType.receiving,
            walletId,
          ),
        );
      }

      if (p2wpkhRcvDerivations != null) {
        newAddresses.addAll(
          _v4GetAddressesFromDerivationString(
            p2wpkhRcvDerivations,
            isar_models.AddressType.p2wpkh,
            isar_models.AddressSubType.receiving,
            walletId,
          ),
        );
      }

      if (p2pkhCngDerivations != null) {
        newAddresses.addAll(
          _v4GetAddressesFromDerivationString(
            p2pkhCngDerivations,
            isar_models.AddressType.p2pkh,
            isar_models.AddressSubType.change,
            walletId,
          ),
        );
      }

      if (p2shCngDerivations != null) {
        newAddresses.addAll(
          _v4GetAddressesFromDerivationString(
            p2shCngDerivations,
            isar_models.AddressType.p2sh,
            isar_models.AddressSubType.change,
            walletId,
          ),
        );
      }

      if (p2wpkhCngDerivations != null) {
        newAddresses.addAll(
          _v4GetAddressesFromDerivationString(
            p2wpkhCngDerivations,
            isar_models.AddressType.p2wpkh,
            isar_models.AddressSubType.change,
            walletId,
          ),
        );
      }

      final currentNewSet = newAddresses.map((e) => e.value).toSet();

      final p2pkhRcvAddresses = _v4GetAddressesFromList(
          _getList(walletBox.get(receiveAddressesPrefix) ??
              walletBox.get("${receiveAddressesPrefix}P2PKH")),
          isar_models.AddressType.p2pkh,
          isar_models.AddressSubType.receiving,
          walletId);
      for (final address in p2pkhRcvAddresses) {
        if (!currentNewSet.contains(address.value)) {
          newAddresses.add(address);
        }
      }

      final p2shRcvAddresses = _v4GetAddressesFromList(
          _getList(walletBox.get("${receiveAddressesPrefix}P2SH")),
          isar_models.AddressType.p2sh,
          isar_models.AddressSubType.receiving,
          walletId);
      for (final address in p2shRcvAddresses) {
        if (!currentNewSet.contains(address.value)) {
          newAddresses.add(address);
        }
      }

      final p2wpkhRcvAddresses = _v4GetAddressesFromList(
          _getList(walletBox.get("${receiveAddressesPrefix}P2WPKH")),
          isar_models.AddressType.p2wpkh,
          isar_models.AddressSubType.receiving,
          walletId);
      for (final address in p2wpkhRcvAddresses) {
        if (!currentNewSet.contains(address.value)) {
          newAddresses.add(address);
        }
      }

      final p2pkhCngAddresses = _v4GetAddressesFromList(
          _getList(walletBox.get(changeAddressesPrefix) ??
              walletBox.get("${changeAddressesPrefix}P2PKH")),
          isar_models.AddressType.p2wpkh,
          isar_models.AddressSubType.change,
          walletId);
      for (final address in p2pkhCngAddresses) {
        if (!currentNewSet.contains(address.value)) {
          newAddresses.add(address);
        }
      }

      final p2shCngAddresses = _v4GetAddressesFromList(
          _getList(walletBox.get("${changeAddressesPrefix}P2SH")),
          isar_models.AddressType.p2wpkh,
          isar_models.AddressSubType.change,
          walletId);
      for (final address in p2shCngAddresses) {
        if (!currentNewSet.contains(address.value)) {
          newAddresses.add(address);
        }
      }

      final p2wpkhCngAddresses = _v4GetAddressesFromList(
          _getList(walletBox.get("${changeAddressesPrefix}P2WPKH")),
          isar_models.AddressType.p2wpkh,
          isar_models.AddressSubType.change,
          walletId);
      for (final address in p2wpkhCngAddresses) {
        if (!currentNewSet.contains(address.value)) {
          newAddresses.add(address);
        }
      }

      // transactions
      final txnData = walletBox.get("latest_tx_model") as TransactionData?;
      final txns = txnData?.getAllTransactions().values ?? [];
      final txnDataLelantus =
          walletBox.get("latest_lelantus_tx_model") as TransactionData?;
      final txnsLelantus = txnDataLelantus?.getAllTransactions().values ?? [];

      final List<Tuple2<isar_models.Transaction, isar_models.Address?>>
          newTransactions = [];

      newTransactions
          .addAll(_parseTransactions(txns, walletId, false, newAddresses));
      newTransactions.addAll(
          _parseTransactions(txnsLelantus, walletId, true, newAddresses));

      // store newly parsed data in isar
      await MainDB.instance.initMainDB();
      initWalletDB();
      await db.isar.writeTxn(() async {
        await db.isar.addresses.putAll(newAddresses);
      });
      await db.addNewTransactionData(newTransactions, walletId);

      // delete data from hive
      await walletBox.delete(receiveAddressesPrefix);
      await walletBox.delete("${receiveAddressesPrefix}P2PKH");
      await walletBox.delete("${receiveAddressesPrefix}P2SH");
      await walletBox.delete("${receiveAddressesPrefix}P2WPKH");
      await walletBox.delete(changeAddressesPrefix);
      await walletBox.delete("${changeAddressesPrefix}P2PKH");
      await walletBox.delete("${changeAddressesPrefix}P2SH");
      await walletBox.delete("${changeAddressesPrefix}P2WPKH");
      await walletBox.delete("latest_tx_model");
      await walletBox.delete("latest_lelantus_tx_model");
    }
  }

  List<Tuple2<isar_models.Transaction, isar_models.Address?>>
      _parseTransactions(
    Iterable<Transaction> txns,
    String walletId,
    bool isLelantus,
    List<isar_models.Address> parsedAddresses,
  ) {
    List<Tuple2<isar_models.Transaction, isar_models.Address?>> transactions =
        [];
    for (final tx in txns) {
      final type = tx.txType.toLowerCase() == "received"
          ? isar_models.TransactionType.incoming
          : isar_models.TransactionType.outgoing;
      final subType = tx.subType.toLowerCase() == "mint"
          ? isar_models.TransactionSubType.mint
          : tx.subType.toLowerCase() == "join"
              ? isar_models.TransactionSubType.join
              : isar_models.TransactionSubType.none;

      final List<isar_models.Input> inputs = [];
      final List<isar_models.Output> outputs = [];

      for (final inp in tx.inputs) {
        final input = isar_models.Input(
          txid: inp.txid,
          vout: inp.vout,
          scriptSig: inp.scriptsig,
          scriptSigAsm: inp.scriptsigAsm,
          isCoinbase: inp.isCoinbase,
          sequence: inp.sequence,
          innerRedeemScriptAsm: inp.innerRedeemscriptAsm,
        );
        inputs.add(input);
      }
      for (final out in tx.outputs) {
        final output = isar_models.Output(
          scriptPubKey: out.scriptpubkey,
          scriptPubKeyAsm: out.scriptpubkeyAsm,
          scriptPubKeyType: out.scriptpubkeyType,
          scriptPubKeyAddress: out.scriptpubkeyAddress,
          value: out.value,
        );
        outputs.add(output);
      }

      final transaction = isar_models.Transaction(
        walletId: walletId,
        txid: tx.txid,
        timestamp: tx.timestamp,
        type: type,
        subType: subType,
        amount: tx.amount,
        fee: tx.fees,
        height: tx.height,
        isCancelled: tx.isCancelled,
        isLelantus: false,
        slateId: tx.slateId,
        otherData: tx.otherData,
        inputs: inputs,
        outputs: outputs,
      );

      isar_models.Address? address;
      if (tx.address.isNotEmpty) {
        final addresses = parsedAddresses.where((e) => e.value == tx.address);
        if (addresses.isNotEmpty) {
          address = addresses.first;
        } else {
          address = isar_models.Address(
            walletId: walletId,
            value: tx.address,
            publicKey: [],
            derivationIndex: -1,
            type: isar_models.AddressType.unknown,
            subType: type == isar_models.TransactionType.incoming
                ? isar_models.AddressSubType.receiving
                : isar_models.AddressSubType.unknown,
          );
        }
      }

      transactions.add(Tuple2(transaction, address));
    }
    return transactions;
  }

  List<isar_models.Address> _v4GetAddressesFromDerivationString(
    String derivationsString,
    isar_models.AddressType type,
    isar_models.AddressSubType subType,
    String walletId,
  ) {
    final List<isar_models.Address> addresses = [];

    final derivations =
        Map<String, dynamic>.from(jsonDecode(derivationsString) as Map);

    for (final entry in derivations.entries) {
      final addr = entry.value["address"] as String? ?? entry.key;
      final pubKey = entry.value["pubKey"] as String? ??
          entry.value["publicKey"] as String;
      final index = int.tryParse(entry.key) ?? -1;

      final address = isar_models.Address(
        walletId: walletId,
        value: addr,
        publicKey: Format.stringToUint8List(pubKey),
        derivationIndex: index,
        type: type,
        subType: subType,
      );
      addresses.add(address);
    }

    return addresses;
  }

  List<isar_models.Address> _v4GetAddressesFromList(
    List<String> addressStrings,
    isar_models.AddressType type,
    isar_models.AddressSubType subType,
    String walletId,
  ) {
    final List<isar_models.Address> addresses = [];

    for (final addr in addressStrings) {
      final address = isar_models.Address(
        walletId: walletId,
        value: addr,
        publicKey: [],
        derivationIndex: -1,
        type: type,
        subType: subType,
      );
      addresses.add(address);
    }

    return addresses;
  }

  List<String> _getList(dynamic list) {
    if (list == null) return [];
    return List<String>.from(list as List);
  }
}

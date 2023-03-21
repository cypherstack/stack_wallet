import 'package:hive/hive.dart';
import 'package:stackduo/db/main_db.dart';
import 'package:stackduo/electrumx_rpc/electrumx.dart';
import 'package:stackduo/hive/db.dart';
import 'package:stackduo/models/exchange/change_now/exchange_transaction.dart';
import 'package:stackduo/models/exchange/response_objects/trade.dart';
import 'package:stackduo/models/isar/models/isar_models.dart' as isar_models;
import 'package:stackduo/models/models.dart';
import 'package:stackduo/models/node_model.dart';
import 'package:stackduo/services/mixins/wallet_db.dart';
import 'package:stackduo/services/node_service.dart';
import 'package:stackduo/services/wallets_service.dart';
import 'package:stackduo/utilities/constants.dart';
import 'package:stackduo/utilities/default_nodes.dart';
import 'package:stackduo/utilities/enums/coin_enum.dart';
import 'package:stackduo/utilities/flutter_secure_storage_interface.dart';
import 'package:stackduo/utilities/logger.dart';
import 'package:stackduo/utilities/prefs.dart';
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
    await MainDB.instance.initMainDB();

    for (final walletId in walletInfoList.keys) {
      final info = walletInfoList[walletId]!;
      assert(info.walletId == walletId);

      final walletBox = await Hive.openBox<dynamic>(info.walletId);

      const receiveAddressesPrefix = "receivingAddresses";
      const changeAddressesPrefix = "changeAddresses";

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

      // set empty mnemonic passphrase as we used that by default before
      if ((await secureStore.read(key: '${walletId}_mnemonicPassphrase')) ==
          null) {
        await secureStore.write(
            key: '${walletId}_mnemonicPassphrase', value: "");
      }
    }
  }
}

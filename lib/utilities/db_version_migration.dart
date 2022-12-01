import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive/hive.dart';
import 'package:epicmobile/electrumx_rpc/electrumx.dart';
import 'package:epicmobile/hive/db.dart';
import 'package:epicmobile/models/exchange/change_now/exchange_transaction.dart';
import 'package:epicmobile/models/exchange/response_objects/trade.dart';
import 'package:epicmobile/models/lelantus_coin.dart';
import 'package:epicmobile/models/node_model.dart';
import 'package:epicmobile/services/node_service.dart';
import 'package:epicmobile/services/wallets_service.dart';
import 'package:epicmobile/utilities/default_nodes.dart';
import 'package:epicmobile/utilities/enums/coin_enum.dart';
import 'package:epicmobile/utilities/flutter_secure_storage_interface.dart';
import 'package:epicmobile/utilities/logger.dart';
import 'package:epicmobile/utilities/prefs.dart';

class DbVersionMigrator {
  Future<void> migrate(
    int fromVersion, {
    FlutterSecureStorageInterface secureStore = const SecureStorageWrapper(
      FlutterSecureStorage(),
    ),
  }) async {
    Logging.instance.log(
      "Running migrate fromVersion $fromVersion",
      level: LogLevel.Warning,
    );
    switch (fromVersion) {
      case 0:
        await Hive.openBox<dynamic>(DB.boxNameAllWalletsData);
        await Hive.openBox<dynamic>(DB.boxNamePrefs);
        final walletsService = WalletsService();
        final nodeService = NodeService();
        final prefs = Prefs.instance;
        final walletInfoList = await walletsService.walletNames;
        await prefs.init();

        ElectrumX? client;
        int? latestSetId;

        // update version
        await DB.instance.put<dynamic>(
            boxName: DB.boxNameDBInfo, key: "hive_data_version", value: 1);

        // try to continue migrating
        return await migrate(1);

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
        return await migrate(2);
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
        return await migrate(3);

      default:
        // finally return
        return;
    }
  }
}

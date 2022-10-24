import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive/hive.dart';
import 'package:stackwallet/electrumx_rpc/electrumx.dart';
import 'package:stackwallet/hive/db.dart';
import 'package:stackwallet/models/exchange/change_now/exchange_transaction.dart';
import 'package:stackwallet/models/exchange/response_objects/trade.dart';
import 'package:stackwallet/models/lelantus_coin.dart';
import 'package:stackwallet/models/node_model.dart';
import 'package:stackwallet/services/node_service.dart';
import 'package:stackwallet/services/wallets_service.dart';
import 'package:stackwallet/utilities/default_nodes.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/utilities/flutter_secure_storage_interface.dart';
import 'package:stackwallet/utilities/logger.dart';
import 'package:stackwallet/utilities/prefs.dart';

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

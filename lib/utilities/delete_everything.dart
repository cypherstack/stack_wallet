import 'package:stackwallet/db/hive/db.dart';
import 'package:stackwallet/utilities/logger.dart';

Future<bool> deleteEverything() async {
  try {
    await DB.instance.deleteBoxFromDisk(boxName: DB.boxNameAddressBook);
    await DB.instance.deleteBoxFromDisk(boxName: DB.boxNameDebugInfo);
    await DB.instance.deleteBoxFromDisk(boxName: DB.boxNameNodeModels);
    await DB.instance.deleteBoxFromDisk(boxName: DB.boxNamePrimaryNodes);
    await DB.instance.deleteBoxFromDisk(boxName: DB.boxNameAllWalletsData);
    await DB.instance.deleteBoxFromDisk(boxName: DB.boxNameNotifications);
    await DB.instance.deleteBoxFromDisk(boxName: DB.boxNameWatchedTransactions);
    await DB.instance.deleteBoxFromDisk(boxName: DB.boxNameWatchedTrades);
    await DB.instance.deleteBoxFromDisk(boxName: DB.boxNameTrades);
    await DB.instance.deleteBoxFromDisk(boxName: DB.boxNameTradesV2);
    await DB.instance.deleteBoxFromDisk(boxName: DB.boxNameTradeNotes);
    await DB.instance.deleteBoxFromDisk(boxName: DB.boxNameTradeLookup);
    await DB.instance.deleteBoxFromDisk(boxName: DB.boxNameFavoriteWallets);
    await DB.instance.deleteBoxFromDisk(boxName: DB.boxNamePrefs);
    await DB.instance
        .deleteBoxFromDisk(boxName: DB.boxNameWalletsToDeleteOnStart);
    await DB.instance.deleteBoxFromDisk(boxName: DB.boxNamePriceCache);
    await DB.instance.deleteBoxFromDisk(boxName: DB.boxNameDBInfo);
    await DB.instance.deleteBoxFromDisk(boxName: "theme");
    return true;
  } catch (e, s) {
    Logging.instance.log("$e $s", level: LogLevel.Error);
    return false;
  }
}

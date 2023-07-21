import 'package:flutter_test/flutter_test.dart';
import 'package:hive_test/hive_test.dart';
import 'package:stackwallet/db/hive/db.dart';

void main() {
  group("DB box names", () {
    test("address book", () => expect(DB.boxNameAddressBook, "addressBook"));
    test("nodes", () => expect(DB.boxNameNodeModels, "nodeModels"));
    test("primary nodes", () => expect(DB.boxNamePrimaryNodes, "primaryNodes"));
    test("wallets info", () => expect(DB.boxNameAllWalletsData, "wallets"));
    test("notifications",
        () => expect(DB.boxNameNotifications, "notificationModels"));
    test(
        "watched transactions",
        () => expect(
            DB.boxNameWatchedTransactions, "watchedTxNotificationModels"));
    test(
        "watched trades",
        () =>
            expect(DB.boxNameWatchedTrades, "watchedTradesNotificationModels"));
    test("trades", () => expect(DB.boxNameTrades, "exchangeTransactionsBox"));
    test("trade notes", () => expect(DB.boxNameTradeNotes, "tradeNotesBox"));
    test("tx <> trade lookup table",
        () => expect(DB.boxNameTradeLookup, "tradeToTxidLookUpBox"));
    test("favorite wallets",
        () => expect(DB.boxNameFavoriteWallets, "favoriteWallets"));
    test("preferences", () => expect(DB.boxNamePrefs, "prefs"));
    test(
        "deleted wallets to clear out on start",
        () =>
            expect(DB.boxNameWalletsToDeleteOnStart, "walletsToDeleteOnStart"));
    test("price cache",
        () => expect(DB.boxNamePriceCache, "priceAPIPrice24hCache"));
  });

  group("tests requiring test hive environment", () {
    setUp(() async {
      await setUpTestHive();
    });

    test("DB init", () async {});

    tearDown(() async {
      await tearDownTestHive();
    });
  });
}

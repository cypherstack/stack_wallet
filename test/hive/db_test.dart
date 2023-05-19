import 'package:flutter_test/flutter_test.dart';
import 'package:hive_test/hive_test.dart';
import 'package:stackwallet/db/hive/db.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';

void main() {
  group("DB box names", () {
    test("address book", () => expect(DB.boxNameAddressBook, "addressBook"));
    test("debug info", () => expect(DB.boxNameDebugInfo, "debugInfoBox"));
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

    test("boxNameTxCache", () {
      for (final coin in Coin.values) {
        expect(DB.instance.boxNameTxCache(coin: coin), "${coin.name}_txCache");
      }
    });

    test("boxNameSetCache", () {
      for (final coin in Coin.values) {
        expect(DB.instance.boxNameSetCache(coin: coin),
            "${coin.name}_anonymitySetCache");
      }
    });

    test("boxNameUsedSerialsCache", () {
      for (final coin in Coin.values) {
        expect(DB.instance.boxNameUsedSerialsCache(coin: coin),
            "${coin.name}_usedSerialsCache");
      }
    });
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

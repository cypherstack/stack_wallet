import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:hive_test/hive_test.dart';
import 'package:mockito/annotations.dart';
import 'package:stackwallet/hive/db.dart';
import 'package:stackwallet/services/wallets_service.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/utilities/flutter_secure_storage_interface.dart';

@GenerateMocks([SecureStorageWrapper])
void main() {
  setUp(() async {
    await setUpTestHive();
    final wallets = await Hive.openBox<dynamic>(DB.boxNameAllWalletsData);
    await wallets.put('names', {
      "wallet_id": {
        "name": "My Firo Wallet",
        "id": "wallet_id",
        "coin": "bitcoin",
      },
      "wallet_id2": {
        "name": "wallet2",
        "id": "wallet_id2",
        "coin": "bitcoin",
      },
    });
  });

  test("get walletNames", () async {
    final service = WalletsService(secureStorageInterface: FakeSecureStorage());
    expect((await service.walletNames).toString(),
        '{wallet_id: WalletInfo: {"name":"My Firo Wallet","id":"wallet_id","coin":"bitcoin"}, wallet_id2: WalletInfo: {"name":"wallet2","id":"wallet_id2","coin":"bitcoin"}}');
  });

  test("get null wallet names", () async {
    final wallets = await Hive.openBox<dynamic>('wallets');
    await wallets.put('names', null);
    final service = WalletsService(secureStorageInterface: FakeSecureStorage());
    expect(await service.walletNames, <String, WalletInfo>{});
    expect((await service.walletNames).toString(), '{}');
  });

  test("rename wallet to same name", () async {
    final service = WalletsService(secureStorageInterface: FakeSecureStorage());
    expect(
        await service.renameWallet(
            from: "My Firo Wallet",
            to: "My Firo Wallet",
            shouldNotifyListeners: false),
        true);
    expect((await service.walletNames).toString(),
        '{wallet_id: WalletInfo: {"name":"My Firo Wallet","id":"wallet_id","coin":"bitcoin"}, wallet_id2: WalletInfo: {"name":"wallet2","id":"wallet_id2","coin":"bitcoin"}}');
  });

  test("rename wallet to new name", () async {
    final service = WalletsService(secureStorageInterface: FakeSecureStorage());
    expect(
        await service.renameWallet(
            from: "My Firo Wallet",
            to: "My New Wallet",
            shouldNotifyListeners: false),
        true);

    expect((await service.walletNames).toString(),
        '{wallet_id: WalletInfo: {"name":"My New Wallet","id":"wallet_id","coin":"bitcoin"}, wallet_id2: WalletInfo: {"name":"wallet2","id":"wallet_id2","coin":"bitcoin"}}');
  });

  test("attempt rename wallet to another existing name", () async {
    final service = WalletsService(secureStorageInterface: FakeSecureStorage());
    expect(
        await service.renameWallet(
            from: "My Firo Wallet",
            to: "wallet2",
            shouldNotifyListeners: false),
        false);
    expect((await service.walletNames).toString(),
        '{wallet_id: WalletInfo: {"name":"My Firo Wallet","id":"wallet_id","coin":"bitcoin"}, wallet_id2: WalletInfo: {"name":"wallet2","id":"wallet_id2","coin":"bitcoin"}}');
  });

  test("add new wallet name", () async {
    final service = WalletsService(secureStorageInterface: FakeSecureStorage());
    expect(
        await service.addNewWallet(
            name: "wallet3", coin: Coin.bitcoin, shouldNotifyListeners: false),
        isA<String>());
    expect((await service.walletNames).length, 3);
  });

  test("add duplicate wallet name fails", () async {
    final service = WalletsService(secureStorageInterface: FakeSecureStorage());
    expect(
        await service.addNewWallet(
            name: "wallet2", coin: Coin.bitcoin, shouldNotifyListeners: false),
        null);
    expect((await service.walletNames).length, 2);
  });

  test("check for duplicates when null names", () async {
    final wallets = await Hive.openBox<dynamic>('wallets');
    await wallets.put('names', null);
    final service = WalletsService(secureStorageInterface: FakeSecureStorage());
    expect(await service.checkForDuplicate("anything"), false);
  });

  test("check for duplicates when some names with no matches", () async {
    final service = WalletsService(secureStorageInterface: FakeSecureStorage());
    expect(await service.checkForDuplicate("anything"), false);
  });

  test("check for duplicates when some names with a match", () async {
    final service = WalletsService(secureStorageInterface: FakeSecureStorage());
    expect(await service.checkForDuplicate("wallet2"), true);
  });

  test("get existing wallet id", () async {
    final service = WalletsService(secureStorageInterface: FakeSecureStorage());
    expect(await service.getWalletId("wallet2"), "wallet_id2");
  });

  test("get non existent wallet id", () async {
    final service = WalletsService(secureStorageInterface: FakeSecureStorage());
    await expectLater(await service.getWalletId("wallet 99"), null);
  });

  // test("delete a wallet", () async {
  //   await Hive.openBox<String>(DB.boxNameWalletsToDeleteOnStart);
  //   await Hive.openBox<TradeWalletLookup>(DB.boxNameTradeLookup);
  //   await Hive.openBox<NotificationModel>(DB.boxNameNotifications);
  //   final secureStore = MockSecureStorageWrapper();
  //
  //   when(secureStore.delete(key: "wallet_id_pin")).thenAnswer((_) async {});
  //   when(secureStore.delete(key: "wallet_id_mnemonic"))
  //       .thenAnswer((_) async {});
  //
  //   final service = WalletsService(secureStorageInterface: secureStore);
  //
  //   expect(await service.deleteWallet("My Firo Wallet", false), 0);
  //   expect((await service.walletNames).length, 1);
  //
  //   verify(secureStore.delete(key: "wallet_id_pin")).called(1);
  //   verify(secureStore.delete(key: "wallet_id_mnemonic")).called(1);
  //
  //   verifyNoMoreInteractions(secureStore);
  // });
  //
  // test("delete last wallet", () async {
  //   await Hive.openBox<String>(DB.boxNameWalletsToDeleteOnStart);
  //   await Hive.openBox<TradeWalletLookup>(DB.boxNameTradeLookup);
  //   await Hive.openBox<NotificationModel>(DB.boxNameNotifications);
  //   final wallets = await Hive.openBox<dynamic>('wallets');
  //   await wallets.put('names', {
  //     "wallet_id": {
  //       "name": "My Firo Wallet",
  //       "id": "wallet_id",
  //       "coin": "bitcoin",
  //     },
  //   });
  //   final secureStore = MockSecureStorageWrapper();
  //
  //   when(secureStore.delete(key: "wallet_id_pin")).thenAnswer((_) async {});
  //   when(secureStore.delete(key: "wallet_id_mnemonic"))
  //       .thenAnswer((_) async {});
  //
  //   final service = WalletsService(secureStorageInterface: secureStore);
  //
  //   expect(await service.deleteWallet("My Firo Wallet", false), 2);
  //   expect((await service.walletNames).length, 0);
  //
  //   verify(secureStore.delete(key: "wallet_id_pin")).called(1);
  //   verify(secureStore.delete(key: "wallet_id_mnemonic")).called(1);
  //
  //   verifyNoMoreInteractions(secureStore);
  // });

  // test("get", () async {
  //   final service = WalletsService();
  // });

  tearDown(() async {
    await tearDownTestHive();
  });
}

import 'dart:convert';

import 'package:bitcoindart/bitcoindart.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:hive_test/hive_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:stackwallet/electrumx_rpc/cached_electrumx.dart';
import 'package:stackwallet/electrumx_rpc/electrumx.dart';
import 'package:stackwallet/hive/db.dart';
import 'package:stackwallet/models/paymint/fee_object_model.dart';
import 'package:stackwallet/models/paymint/transactions_model.dart';
import 'package:stackwallet/models/paymint/utxo_model.dart';
import 'package:stackwallet/services/coins/bitcoincash/bitcoincash_wallet.dart';
import 'package:stackwallet/services/price.dart';
import 'package:stackwallet/services/transaction_notification_tracker.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/utilities/flutter_secure_storage_interface.dart';

import 'bitcoincash_history_sample_data.dart';
import 'bitcoincash_transaction_data_samples.dart';
import 'bitcoincash_utxo_sample_data.dart';
import 'bitcoincash_wallet_test.mocks.dart';
import 'bitcoincash_wallet_test_parameters.dart';

@GenerateMocks(
    [ElectrumX, CachedElectrumX, PriceAPI, TransactionNotificationTracker])
void main() {
  group("bitcoincash constants", () {
    test("bitcoincash minimum confirmations", () async {
      expect(MINIMUM_CONFIRMATIONS, 3);
    });
    test("bitcoincash dust limit", () async {
      expect(DUST_LIMIT, 1000000);
    });
    test("bitcoincash mainnet genesis block hash", () async {
      expect(GENESIS_HASH_MAINNET,
          "000000000019d6689c085ae165831e934ff763ae46a2a6c172b3f1b60a8ce26f");
    });

    test("bitcoincash testnet genesis block hash", () async {
      expect(GENESIS_HASH_TESTNET,
          "000000000933ea01ad0ee984209779baaec3ced90fa3f408719526f8d77f4943");
    });
  });

  test("bitcoincash DerivePathType enum", () {
    expect(DerivePathType.values.length, 1);
    expect(DerivePathType.values.toString(), "[DerivePathType.bip44]");
  });

  group("bip32 node/root", () {
    test("getBip32Root", () {
      final root = getBip32Root(TEST_MNEMONIC, bitcoincash);
      expect(root.toWIF(), ROOT_WIF);
    });

    test("basic getBip32Node", () {
      final node =
          getBip32Node(0, 0, TEST_MNEMONIC, bitcoincash, DerivePathType.bip44);
      expect(node.toWIF(), NODE_WIF_44);
    });
  });

  group("validate mainnet bitcoincash addresses", () {
    MockElectrumX? client;
    MockCachedElectrumX? cachedClient;
    MockPriceAPI? priceAPI;
    FakeSecureStorage? secureStore;
    MockTransactionNotificationTracker? tracker;

    BitcoinCashWallet? mainnetWallet;

    setUp(() {
      client = MockElectrumX();
      cachedClient = MockCachedElectrumX();
      priceAPI = MockPriceAPI();
      secureStore = FakeSecureStorage();
      tracker = MockTransactionNotificationTracker();

      mainnetWallet = BitcoinCashWallet(
        walletId: "validateAddressMainNet",
        walletName: "validateAddressMainNet",
        coin: Coin.bitcoincash,
        client: client!,
        cachedClient: cachedClient!,
        tracker: tracker!,
        priceAPI: priceAPI,
        secureStore: secureStore,
      );
    });

    test("valid mainnet legacy/p2pkh address type", () {
      expect(
          mainnetWallet?.addressType(
              address: "1DP3PUePwMa5CoZwzjznVKhzdLsZftjcAT"),
          DerivePathType.bip44);
      expect(secureStore?.interactions, 0);
      verifyNoMoreInteractions(client);
      verifyNoMoreInteractions(cachedClient);
      verifyNoMoreInteractions(tracker);
      verifyNoMoreInteractions(priceAPI);
    });

    test("invalid base58 address type", () {
      expect(
          () => mainnetWallet?.addressType(
              address: "mhqpGtwhcR6gFuuRjLTpHo41919QfuGy8Y"),
          throwsArgumentError);
      expect(secureStore?.interactions, 0);
      verifyNoMoreInteractions(client);
      verifyNoMoreInteractions(cachedClient);
      verifyNoMoreInteractions(tracker);
      verifyNoMoreInteractions(priceAPI);
    });

    test("invalid bech32 address type", () {
      expect(
          () => mainnetWallet?.addressType(
              address: "tb1qzzlm6mnc8k54mx6akehl8p9ray8r439va5ndyq"),
          throwsArgumentError);
      expect(secureStore?.interactions, 0);
      verifyNoMoreInteractions(client);
      verifyNoMoreInteractions(cachedClient);
      verifyNoMoreInteractions(tracker);
      verifyNoMoreInteractions(priceAPI);
    });

    test("address has no matching script", () {
      expect(
          () => mainnetWallet?.addressType(
              address: "mpMk94ETazqonHutyC1v6ajshgtP8oiFKU"),
          throwsArgumentError);
      expect(secureStore?.interactions, 0);
      verifyNoMoreInteractions(client);
      verifyNoMoreInteractions(cachedClient);
      verifyNoMoreInteractions(tracker);
      verifyNoMoreInteractions(priceAPI);
    });

    test("invalid mainnet bitcoincash legacy/p2pkh address", () {
      expect(
          mainnetWallet?.validateAddress("mhqpGtwhcR6gFuuRjLTpHo41919QfuGy8Y"),
          true);
      expect(secureStore?.interactions, 0);
      verifyNoMoreInteractions(client);
      verifyNoMoreInteractions(cachedClient);
      verifyNoMoreInteractions(tracker);
      verifyNoMoreInteractions(priceAPI);
    });
  });

  group("testNetworkConnection", () {
    MockElectrumX? client;
    MockCachedElectrumX? cachedClient;
    MockPriceAPI? priceAPI;
    FakeSecureStorage? secureStore;
    MockTransactionNotificationTracker? tracker;

    BitcoinCashWallet? bch;

    setUp(() {
      client = MockElectrumX();
      cachedClient = MockCachedElectrumX();
      priceAPI = MockPriceAPI();
      secureStore = FakeSecureStorage();
      tracker = MockTransactionNotificationTracker();

      bch = BitcoinCashWallet(
        walletId: "testNetworkConnection",
        walletName: "testNetworkConnection",
        coin: Coin.bitcoincash,
        client: client!,
        cachedClient: cachedClient!,
        tracker: tracker!,
        priceAPI: priceAPI,
        secureStore: secureStore,
      );
    });

    test("attempted connection fails due to server error", () async {
      when(client?.ping()).thenAnswer((_) async => false);
      final bool? result = await bch?.testNetworkConnection();
      expect(result, false);
      expect(secureStore?.interactions, 0);
      verify(client?.ping()).called(1);
      verifyNoMoreInteractions(client);
      verifyNoMoreInteractions(cachedClient);
      verifyNoMoreInteractions(tracker);
      verifyNoMoreInteractions(priceAPI);
    });

    test("attempted connection fails due to exception", () async {
      when(client?.ping()).thenThrow(Exception);
      final bool? result = await bch?.testNetworkConnection();
      expect(result, false);
      expect(secureStore?.interactions, 0);
      verify(client?.ping()).called(1);
      verifyNoMoreInteractions(client);
      verifyNoMoreInteractions(cachedClient);
      verifyNoMoreInteractions(tracker);
      verifyNoMoreInteractions(priceAPI);
    });

    test("attempted connection test success", () async {
      when(client?.ping()).thenAnswer((_) async => true);
      final bool? result = await bch?.testNetworkConnection();
      expect(result, true);
      expect(secureStore?.interactions, 0);
      verify(client?.ping()).called(1);
      verifyNoMoreInteractions(client);
      verifyNoMoreInteractions(cachedClient);
      verifyNoMoreInteractions(tracker);
      verifyNoMoreInteractions(priceAPI);
    });
  });

  group("basic getters, setters, and functions", () {
    final bchcoin = Coin.bitcoincash;
    final testWalletId = "BCHtestWalletID";
    final testWalletName = "BCHWallet";

    MockElectrumX? client;
    MockCachedElectrumX? cachedClient;
    MockPriceAPI? priceAPI;
    FakeSecureStorage? secureStore;
    MockTransactionNotificationTracker? tracker;

    BitcoinCashWallet? bch;

    setUp(() async {
      client = MockElectrumX();
      cachedClient = MockCachedElectrumX();
      priceAPI = MockPriceAPI();
      secureStore = FakeSecureStorage();
      tracker = MockTransactionNotificationTracker();

      bch = BitcoinCashWallet(
        walletId: testWalletId,
        walletName: testWalletName,
        coin: bchcoin,
        client: client!,
        cachedClient: cachedClient!,
        tracker: tracker!,
        priceAPI: priceAPI,
        secureStore: secureStore,
      );
    });

    test("get networkType main", () async {
      expect(bch?.coin, bchcoin);
      expect(secureStore?.interactions, 0);
      verifyNoMoreInteractions(client);
      verifyNoMoreInteractions(cachedClient);
      verifyNoMoreInteractions(tracker);
      verifyNoMoreInteractions(priceAPI);
    });

    test("get networkType test", () async {
      bch = BitcoinCashWallet(
        walletId: testWalletId,
        walletName: testWalletName,
        coin: bchcoin,
        client: client!,
        cachedClient: cachedClient!,
        tracker: tracker!,
        priceAPI: priceAPI,
        secureStore: secureStore,
      );
      expect(bch?.coin, bchcoin);
      expect(secureStore?.interactions, 0);
      verifyNoMoreInteractions(client);
      verifyNoMoreInteractions(cachedClient);
      verifyNoMoreInteractions(tracker);
      verifyNoMoreInteractions(priceAPI);
    });

    test("get cryptoCurrency", () async {
      expect(Coin.bitcoincash, Coin.bitcoincash);
      expect(secureStore?.interactions, 0);
      verifyNoMoreInteractions(client);
      verifyNoMoreInteractions(cachedClient);
      verifyNoMoreInteractions(tracker);
      verifyNoMoreInteractions(priceAPI);
    });

    test("get coinName", () async {
      expect(Coin.bitcoincash, Coin.bitcoincash);
      expect(secureStore?.interactions, 0);
      verifyNoMoreInteractions(client);
      verifyNoMoreInteractions(cachedClient);
      verifyNoMoreInteractions(tracker);
      verifyNoMoreInteractions(priceAPI);
    });

    test("get coinTicker", () async {
      expect(Coin.bitcoincash, Coin.bitcoincash);
      expect(secureStore?.interactions, 0);
      verifyNoMoreInteractions(client);
      verifyNoMoreInteractions(cachedClient);
      verifyNoMoreInteractions(tracker);
      verifyNoMoreInteractions(priceAPI);
    });

    test("get and set walletName", () async {
      expect(Coin.bitcoincash, Coin.bitcoincash);
      bch?.walletName = "new name";
      expect(bch?.walletName, "new name");
      expect(secureStore?.interactions, 0);
      verifyNoMoreInteractions(client);
      verifyNoMoreInteractions(cachedClient);
      verifyNoMoreInteractions(tracker);
      verifyNoMoreInteractions(priceAPI);
    });

    test("estimateTxFee", () async {
      expect(bch?.estimateTxFee(vSize: 356, feeRatePerKB: 1), 356);
      expect(bch?.estimateTxFee(vSize: 356, feeRatePerKB: 900), 356);
      expect(bch?.estimateTxFee(vSize: 356, feeRatePerKB: 999), 356);
      expect(bch?.estimateTxFee(vSize: 356, feeRatePerKB: 1000), 356);
      expect(bch?.estimateTxFee(vSize: 356, feeRatePerKB: 1001), 712);
      expect(bch?.estimateTxFee(vSize: 356, feeRatePerKB: 1699), 712);
      expect(bch?.estimateTxFee(vSize: 356, feeRatePerKB: 2000), 712);
      expect(bch?.estimateTxFee(vSize: 356, feeRatePerKB: 12345), 4628);
      expect(secureStore?.interactions, 0);
      verifyNoMoreInteractions(client);
      verifyNoMoreInteractions(cachedClient);
      verifyNoMoreInteractions(tracker);
      verifyNoMoreInteractions(priceAPI);
    });

    test("get fees succeeds", () async {
      when(client?.ping()).thenAnswer((_) async => true);
      when(client?.getServerFeatures()).thenAnswer((_) async => {
            "hosts": {},
            "pruning": null,
            "server_version": "Unit tests",
            "protocol_min": "1.4",
            "protocol_max": "1.4.2",
            "genesis_hash": GENESIS_HASH_TESTNET,
            "hash_function": "sha256",
            "services": []
          });
      when(client?.estimateFee(blocks: 1))
          .thenAnswer((realInvocation) async => Decimal.zero);
      when(client?.estimateFee(blocks: 5))
          .thenAnswer((realInvocation) async => Decimal.one);
      when(client?.estimateFee(blocks: 20))
          .thenAnswer((realInvocation) async => Decimal.ten);

      final fees = await bch?.fees;
      expect(fees, isA<FeeObject>());
      expect(fees?.slow, 1000000000);
      expect(fees?.medium, 100000000);
      expect(fees?.fast, 0);

      verify(client?.estimateFee(blocks: 1)).called(1);
      verify(client?.estimateFee(blocks: 5)).called(1);
      verify(client?.estimateFee(blocks: 20)).called(1);
      expect(secureStore?.interactions, 0);
      verifyNoMoreInteractions(client);
      verifyNoMoreInteractions(cachedClient);
      verifyNoMoreInteractions(tracker);
      verifyNoMoreInteractions(priceAPI);
    });

    test("get fees fails", () async {
      when(client?.ping()).thenAnswer((_) async => true);
      when(client?.getServerFeatures()).thenAnswer((_) async => {
            "hosts": {},
            "pruning": null,
            "server_version": "Unit tests",
            "protocol_min": "1.4",
            "protocol_max": "1.4.2",
            "genesis_hash": GENESIS_HASH_TESTNET,
            "hash_function": "sha256",
            "services": []
          });
      when(client?.estimateFee(blocks: 1))
          .thenAnswer((realInvocation) async => Decimal.zero);
      when(client?.estimateFee(blocks: 5))
          .thenAnswer((realInvocation) async => Decimal.one);
      when(client?.estimateFee(blocks: 20))
          .thenThrow(Exception("some exception"));

      bool didThrow = false;
      try {
        await bch?.fees;
      } catch (_) {
        didThrow = true;
      }

      expect(didThrow, true);

      verify(client?.estimateFee(blocks: 1)).called(1);
      verify(client?.estimateFee(blocks: 5)).called(1);
      verify(client?.estimateFee(blocks: 20)).called(1);
      expect(secureStore?.interactions, 0);
      verifyNoMoreInteractions(client);
      verifyNoMoreInteractions(cachedClient);
      verifyNoMoreInteractions(tracker);
      verifyNoMoreInteractions(priceAPI);
    });

    test("get maxFee", () async {
      when(client?.ping()).thenAnswer((_) async => true);
      when(client?.getServerFeatures()).thenAnswer((_) async => {
            "hosts": {},
            "pruning": null,
            "server_version": "Unit tests",
            "protocol_min": "1.4",
            "protocol_max": "1.4.2",
            "genesis_hash": GENESIS_HASH_TESTNET,
            "hash_function": "sha256",
            "services": []
          });
      when(client?.estimateFee(blocks: 20))
          .thenAnswer((realInvocation) async => Decimal.zero);
      when(client?.estimateFee(blocks: 5))
          .thenAnswer((realInvocation) async => Decimal.one);
      when(client?.estimateFee(blocks: 1))
          .thenAnswer((realInvocation) async => Decimal.ten);

      final maxFee = await bch?.maxFee;
      expect(maxFee, 1000000000);

      verify(client?.estimateFee(blocks: 1)).called(1);
      verify(client?.estimateFee(blocks: 5)).called(1);
      verify(client?.estimateFee(blocks: 20)).called(1);
      expect(secureStore?.interactions, 0);
      verifyNoMoreInteractions(client);
      verifyNoMoreInteractions(cachedClient);
      verifyNoMoreInteractions(tracker);
      verifyNoMoreInteractions(priceAPI);
    });
  });

  group("BCHWallet service class functions that depend on shared storage", () {
    final bchcoin = Coin.bitcoincash;
    final bchtestcoin = Coin.bitcoincashTestnet;
    final testWalletId = "BCHtestWalletID";
    final testWalletName = "BCHWallet";

    bool hiveAdaptersRegistered = false;

    MockElectrumX? client;
    MockCachedElectrumX? cachedClient;
    MockPriceAPI? priceAPI;
    FakeSecureStorage? secureStore;
    MockTransactionNotificationTracker? tracker;

    BitcoinCashWallet? bch;

    setUp(() async {
      await setUpTestHive();
      if (!hiveAdaptersRegistered) {
        hiveAdaptersRegistered = true;

        // Registering Transaction Model Adapters
        Hive.registerAdapter(TransactionDataAdapter());
        Hive.registerAdapter(TransactionChunkAdapter());
        Hive.registerAdapter(TransactionAdapter());
        Hive.registerAdapter(InputAdapter());
        Hive.registerAdapter(OutputAdapter());

        // Registering Utxo Model Adapters
        Hive.registerAdapter(UtxoDataAdapter());
        Hive.registerAdapter(UtxoObjectAdapter());
        Hive.registerAdapter(StatusAdapter());

        final wallets = await Hive.openBox('wallets');
        await wallets.put('currentWalletName', testWalletName);
      }

      client = MockElectrumX();
      cachedClient = MockCachedElectrumX();
      priceAPI = MockPriceAPI();
      secureStore = FakeSecureStorage();
      tracker = MockTransactionNotificationTracker();

      bch = BitcoinCashWallet(
        walletId: testWalletId,
        walletName: testWalletName,
        coin: bchcoin,
        client: client!,
        cachedClient: cachedClient!,
        tracker: tracker!,
        priceAPI: priceAPI,
        secureStore: secureStore,
      );
    });

    // test("initializeWallet no network", () async {
    //   when(client?.ping()).thenAnswer((_) async => false);
    //   await Hive.openBox<dynamic>(testWalletId);
    //   await Hive.openBox<dynamic>(DB.boxNamePrefs);
    //   expect(bch?.initializeNew(), false);
    //   expect(secureStore?.interactions, 0);
    //   verify(client?.ping()).called(0);
    //   verifyNoMoreInteractions(client);
    //   verifyNoMoreInteractions(cachedClient);
    //   verifyNoMoreInteractions(priceAPI);
    // });

    // test("initializeExisting no network exception", () async {
    //   when(client?.ping()).thenThrow(Exception("Network connection failed"));
    //   // bch?.initializeNew();
    //   expect(bch?.initializeExisting(), false);
    //   expect(secureStore?.interactions, 0);
    //   verify(client?.ping()).called(1);
    //   verifyNoMoreInteractions(client);
    //   verifyNoMoreInteractions(cachedClient);
    //   verifyNoMoreInteractions(priceAPI);
    // });

    test("initializeNew mainnet throws bad network", () async {
      when(client?.getServerFeatures()).thenAnswer((_) async => {
            "hosts": {},
            "pruning": null,
            "server_version": "Unit tests",
            "protocol_min": "1.4",
            "protocol_max": "1.4.2",
            "genesis_hash": GENESIS_HASH_TESTNET,
            "hash_function": "sha256",
            "services": []
          });

      await Hive.openBox<dynamic>(testWalletId);
      await Hive.openBox<dynamic>(DB.boxNamePrefs);

      expectLater(() => bch?.initializeNew(), throwsA(isA<Exception>()))
          .then((_) {
        expect(secureStore?.interactions, 0);
        verifyNever(client?.ping()).called(0);
        verify(client?.getServerFeatures()).called(1);
        verifyNoMoreInteractions(client);
        verifyNoMoreInteractions(cachedClient);
        verifyNoMoreInteractions(priceAPI);
      });
    });

    test("initializeNew throws mnemonic overwrite exception", () async {
      when(client?.getServerFeatures()).thenAnswer((_) async => {
            "hosts": {},
            "pruning": null,
            "server_version": "Unit tests",
            "protocol_min": "1.4",
            "protocol_max": "1.4.2",
            "genesis_hash": GENESIS_HASH_MAINNET,
            "hash_function": "sha256",
            "services": []
          });
      await secureStore?.write(
          key: "${testWalletId}_mnemonic", value: "some mnemonic");

      await Hive.openBox<dynamic>(testWalletId);
      await Hive.openBox<dynamic>(DB.boxNamePrefs);

      expectLater(() => bch?.initializeNew(), throwsA(isA<Exception>()))
          .then((_) {
        expect(secureStore?.interactions, 2);
        verifyNever(client?.ping()).called(0);
        verify(client?.getServerFeatures()).called(1);
        verifyNoMoreInteractions(client);
        verifyNoMoreInteractions(cachedClient);
        verifyNoMoreInteractions(priceAPI);
      });
    });

    test("initializeExisting testnet throws bad network", () async {
      when(client?.ping()).thenAnswer((_) async => true);
      when(client?.getServerFeatures()).thenAnswer((_) async => {
            "hosts": {},
            "pruning": null,
            "server_version": "Unit tests",
            "protocol_min": "1.4",
            "protocol_max": "1.4.2",
            "genesis_hash": GENESIS_HASH_TESTNET,
            "hash_function": "sha256",
            "services": []
          });

      bch = BitcoinCashWallet(
        walletId: testWalletId,
        walletName: testWalletName,
        coin: bchcoin,
        client: client!,
        cachedClient: cachedClient!,
        tracker: tracker!,
        priceAPI: priceAPI,
        secureStore: secureStore,
      );

      await Hive.openBox<dynamic>(testWalletId);
      await Hive.openBox<dynamic>(DB.boxNamePrefs);

      expectLater(() => bch?.initializeNew(), throwsA(isA<Exception>()))
          .then((_) {
        expect(secureStore?.interactions, 0);
        verifyNever(client?.ping()).called(0);
        verify(client?.getServerFeatures()).called(1);
        verifyNoMoreInteractions(client);
        verifyNoMoreInteractions(cachedClient);
        verifyNoMoreInteractions(priceAPI);
      });
    });

    // test("getCurrentNode", () async {
    //   // when(priceAPI?.getbitcoincashPrice(baseCurrency: "USD"))
    //   //     .thenAnswer((realInvocation) async => Decimal.fromInt(10));
    //   when(client?.ping()).thenAnswer((_) async => true);
    //   when(client?.getServerFeatures()).thenAnswer((_) async => {
    //         "hosts": {},
    //         "pruning": null,
    //         "server_version": "Unit tests",
    //         "protocol_min": "1.4",
    //         "protocol_max": "1.4.2",
    //         "genesis_hash": GENESIS_HASH_MAINNET,
    //         "hash_function": "sha256",
    //         "services": []
    //       });
    //   // await DebugService.instance.init();
    //   expect(bch?.initializeExisting(), true);
    //
    //   bool didThrow = false;
    //   try {
    //     await bch?.getCurrentNode();
    //   } catch (_) {
    //     didThrow = true;
    //   }
    //   // expect no nodes on a fresh wallet unless set in db externally
    //   expect(didThrow, true);
    //
    //   // set node
    //   final wallet = await Hive.openBox(testWalletId);
    //   await wallet.put("nodes", {
    //     "default": {
    //       "id": "some nodeID",
    //       "ipAddress": "some address",
    //       "port": "9000",
    //       "useSSL": true,
    //     }
    //   });
    //   await wallet.put("activeNodeName", "default");
    //
    //   // try fetching again
    //   final node = await bch?.getCurrentNode();
    //   expect(node.toString(),
    //       "ElectrumXNode: {address: some address, port: 9000, name: default, useSSL: true}");
    //
    //   verify(client?.ping()).called(1);
    //   verify(client?.getServerFeatures()).called(1);
    //   verifyNoMoreInteractions(client);
    //   verifyNoMoreInteractions(cachedClient);
    //   verifyNoMoreInteractions(priceAPI);
    // });

    // test("initializeWallet new main net wallet", () async {
    //   when(priceAPI?.getbitcoincashPrice(baseCurrency: "USD"))
    //       .thenAnswer((realInvocation) async => Decimal.fromInt(10));
    //   when(client?.ping()).thenAnswer((_) async => true);
    //   when(client?.getServerFeatures()).thenAnswer((_) async => {
    //         "hosts": {},
    //         "pruning": null,
    //         "server_version": "Unit tests",
    //         "protocol_min": "1.4",
    //         "protocol_max": "1.4.2",
    //         "genesis_hash": GENESIS_HASH_MAINNET,
    //         "hash_function": "sha256",
    //         "services": []
    //       });
    //   expect(await bch?.initializeWallet(), true);
    //
    //   final wallet = await Hive.openBox(testWalletId);
    //
    //   expect(await wallet.get("addressBookEntries"), {});
    //   expect(await wallet.get('notes'), null);
    //   expect(await wallet.get("id"), testWalletId);
    //   expect(await wallet.get("preferredFiatCurrency"), null);
    //   expect(await wallet.get("blocked_tx_hashes"), ["0xdefault"]);
    //
    //   final changeAddressesP2PKH = await wallet.get("changeAddressesP2PKH");
    //   expect(changeAddressesP2PKH, isA<List<String>>());
    //   expect(changeAddressesP2PKH.length, 1);
    //   expect(await wallet.get("changeIndexP2PKH"), 0);
    //
    //   final receivingAddressesP2PKH =
    //       await wallet.get("receivingAddressesP2PKH");
    //   expect(receivingAddressesP2PKH, isA<List<String>>());
    //   expect(receivingAddressesP2PKH.length, 1);
    //   expect(await wallet.get("receivingIndexP2PKH"), 0);
    //
    //   final p2pkhReceiveDerivations = jsonDecode(await secureStore?.read(
    //       key: "${testWalletId}_receiveDerivationsP2PKH"));
    //   expect(p2pkhReceiveDerivations.length, 1);
    //
    //   final p2pkhChangeDerivations = jsonDecode(await secureStore.read(
    //       key: "${testWalletId}_changeDerivationsP2PKH"));
    //   expect(p2pkhChangeDerivations.length, 1);
    //
    //   expect(secureStore?.interactions, 10);
    //   expect(secureStore?.reads, 7);
    //   expect(secureStore?.writes, 3);
    //   expect(secureStore?.deletes, 0);
    //   verify(client?.ping()).called(1);
    //   verify(client?.getServerFeatures()).called(1);
    //   verifyNoMoreInteractions(client);
    //   verifyNoMoreInteractions(cachedClient);
    //   verifyNoMoreInteractions(priceAPI);
    // });

    // // test("initializeWallet existing main net wallet", () async {
    // //   when(priceAPI?.getbitcoincashPrice(baseCurrency: "USD"))
    // //       .thenAnswer((realInvocation) async => Decimal.fromInt(10));
    // //   when(client?.ping()).thenAnswer((_) async => true);
    // //   when(client?.getBatchHistory(args: anyNamed("args")))
    // //       .thenAnswer((_) async => {});
    // //   when(client?.getServerFeatures()).thenAnswer((_) async => {
    // //         "hosts": {},
    // //         "pruning": null,
    // //         "server_version": "Unit tests",
    // //         "protocol_min": "1.4",
    // //         "protocol_max": "1.4.2",
    // //         "genesis_hash": GENESIS_HASH_MAINNET,
    // //         "hash_function": "sha256",
    // //         "services": []
    // //       });
    // //   // init new wallet
    // //   expect(bch?.initializeNew(), true);
    // //
    // //   // fetch data to compare later
    // //   final newWallet = await Hive.openBox(testWalletId);
    // //
    // //   final addressBookEntries = await newWallet.get("addressBookEntries");
    // //   final notes = await newWallet.get('notes');
    // //   final wID = await newWallet.get("id");
    // //   final currency = await newWallet.get("preferredFiatCurrency");
    // //   final blockedHashes = await newWallet.get("blocked_tx_hashes");
    // //
    // //   final changeAddressesP2PKH = await newWallet.get("changeAddressesP2PKH");
    // //   final changeIndexP2PKH = await newWallet.get("changeIndexP2PKH");
    // //
    // //   final receivingAddressesP2PKH =
    // //       await newWallet.get("receivingAddressesP2PKH");
    // //   final receivingIndexP2PKH = await newWallet.get("receivingIndexP2PKH");
    // //
    // //   final p2pkhReceiveDerivations = jsonDecode(await secureStore?.read(
    // //       key: "${testWalletId}_receiveDerivationsP2PKH"));
    // //
    // //   final p2pkhChangeDerivations = jsonDecode(await secureStore?.read(
    // //       key: "${testWalletId}_changeDerivationsP2PKH"));
    // //
    // //   // exit new wallet
    // //   await bch?.exit();
    // //
    // //   // open existing/created wallet
    // //   bch = BitcoinCashWallet(
    // //     walletId: testWalletId,
    // //     walletName: testWalletName,
    // //     coin: dtestcoin,
    // //     client: client!,
    // //     cachedClient: cachedClient!,
    // //     priceAPI: priceAPI,
    // //     secureStore: secureStore,
    // //   );
    // //
    // //   // init existing
    // //   expect(bch?.initializeExisting(), true);
    // //
    // //   // compare data to ensure state matches state of previously closed wallet
    // //   final wallet = await Hive.openBox(testWalletId);
    // //
    // //   expect(await wallet.get("addressBookEntries"), addressBookEntries);
    // //   expect(await wallet.get('notes'), notes);
    // //   expect(await wallet.get("id"), wID);
    // //   expect(await wallet.get("preferredFiatCurrency"), currency);
    // //   expect(await wallet.get("blocked_tx_hashes"), blockedHashes);
    // //
    // //   expect(await wallet.get("changeAddressesP2PKH"), changeAddressesP2PKH);
    // //   expect(await wallet.get("changeIndexP2PKH"), changeIndexP2PKH);
    // //
    // //   expect(
    // //       await wallet.get("receivingAddressesP2PKH"), receivingAddressesP2PKH);
    // //   expect(await wallet.get("receivingIndexP2PKH"), receivingIndexP2PKH);
    // //
    // //   expect(
    // //       jsonDecode(await secureStore?.read(
    // //           key: "${testWalletId}_receiveDerivationsP2PKH")),
    // //       p2pkhReceiveDerivations);
    // //
    // //   expect(
    // //       jsonDecode(await secureStore?.read(
    // //           key: "${testWalletId}_changeDerivationsP2PKH")),
    // //       p2pkhChangeDerivations);
    // //
    // //   expect(secureStore?.interactions, 12);
    // //   expect(secureStore?.reads, 9);
    // //   expect(secureStore?.writes, 3);
    // //   expect(secureStore?.deletes, 0);
    // //   verify(client?.ping()).called(2);
    // //   verify(client?.getServerFeatures()).called(1);
    // //   verifyNoMoreInteractions(client);
    // //   verifyNoMoreInteractions(cachedClient);
    // //   verifyNoMoreInteractions(priceAPI);
    // // });

    test("get current receiving addresses", () async {
      bch = BitcoinCashWallet(
        walletId: testWalletId,
        walletName: testWalletName,
        coin: bchtestcoin,
        client: client!,
        cachedClient: cachedClient!,
        tracker: tracker!,
        priceAPI: priceAPI,
        secureStore: secureStore,
      );
      when(client?.ping()).thenAnswer((_) async => true);
      when(client?.getServerFeatures()).thenAnswer((_) async => {
            "hosts": {},
            "pruning": null,
            "server_version": "Unit tests",
            "protocol_min": "1.4",
            "protocol_max": "1.4.2",
            "genesis_hash": GENESIS_HASH_TESTNET,
            "hash_function": "sha256",
            "services": []
          });

      await Hive.openBox<dynamic>(testWalletId);
      await Hive.openBox<dynamic>(DB.boxNamePrefs);

      await bch?.initializeNew();
      await bch?.initializeExisting();
      expect(
          Address.validateAddress(
              await bch!.currentReceivingAddress, bitcoincashtestnet),
          true);
      expect(
          Address.validateAddress(
              await bch!.currentReceivingAddress, bitcoincashtestnet),
          true);
      expect(
          Address.validateAddress(
              await bch!.currentReceivingAddress, bitcoincashtestnet),
          true);

      verifyNever(client?.ping()).called(0);
      verify(client?.getServerFeatures()).called(1);
      verifyNoMoreInteractions(client);
      verifyNoMoreInteractions(cachedClient);
      verifyNoMoreInteractions(priceAPI);
    });

    test("get allOwnAddresses", () async {
      bch = BitcoinCashWallet(
        walletId: testWalletId,
        walletName: testWalletName,
        coin: bchtestcoin,
        client: client!,
        cachedClient: cachedClient!,
        tracker: tracker!,
        priceAPI: priceAPI,
        secureStore: secureStore,
      );
      when(client?.ping()).thenAnswer((_) async => true);
      when(client?.getServerFeatures()).thenAnswer((_) async => {
            "hosts": {},
            "pruning": null,
            "server_version": "Unit tests",
            "protocol_min": "1.4",
            "protocol_max": "1.4.2",
            "genesis_hash": GENESIS_HASH_TESTNET,
            "hash_function": "sha256",
            "services": []
          });

      await Hive.openBox<dynamic>(testWalletId);
      await Hive.openBox<dynamic>(DB.boxNamePrefs);

      await bch?.initializeNew();
      await bch?.initializeExisting();
      final addresses = await bch?.allOwnAddresses;
      expect(addresses, isA<List<String>>());
      expect(addresses?.length, 2);

      for (int i = 0; i < 2; i++) {
        expect(
            Address.validateAddress(addresses![i], bitcoincashtestnet), true);
      }

      verifyNever(client?.ping()).called(0);
      verify(client?.getServerFeatures()).called(1);
      verifyNoMoreInteractions(client);
      verifyNoMoreInteractions(cachedClient);
      verifyNoMoreInteractions(priceAPI);
    });

    // test("get utxos and balances", () async {
    //   bch = BitcoinCashWallet(
    //     walletId: testWalletId,
    //     walletName: testWalletName,
    //     coin: dtestcoin,
    //     client: client!,
    //     cachedClient: cachedClient!,
    //     tracker: tracker!,
    //     priceAPI: priceAPI,
    //     secureStore: secureStore,
    //   );
    //   when(client?.ping()).thenAnswer((_) async => true);
    //   when(client?.getServerFeatures()).thenAnswer((_) async => {
    //         "hosts": {},
    //         "pruning": null,
    //         "server_version": "Unit tests",
    //         "protocol_min": "1.4",
    //         "protocol_max": "1.4.2",
    //         "genesis_hash": GENESIS_HASH_TESTNET,
    //         "hash_function": "sha256",
    //         "services": []
    //       });
    //
    //   await Hive.openBox<dynamic>(testWalletId);
    //   await Hive.openBox<dynamic>(DB.boxNamePrefs);
    //
    //   when(client?.getBatchUTXOs(args: anyNamed("args")))
    //       .thenAnswer((_) async => batchGetUTXOResponse0);
    //
    //   when(client?.estimateFee(blocks: 20))
    //       .thenAnswer((realInvocation) async => Decimal.zero);
    //   when(client?.estimateFee(blocks: 5))
    //       .thenAnswer((realInvocation) async => Decimal.one);
    //   when(client?.estimateFee(blocks: 1))
    //       .thenAnswer((realInvocation) async => Decimal.ten);
    //
    //   when(cachedClient?.getTransaction(
    //     txHash: tx1.txid,
    //     coin: Coin.bitcoincashTestNet,
    //   )).thenAnswer((_) async => tx1Raw);
    //   when(cachedClient?.getTransaction(
    //     txHash: tx2.txid,
    //     coin: Coin.bitcoincashTestNet,
    //   )).thenAnswer((_) async => tx2Raw);
    //   when(cachedClient?.getTransaction(
    //     txHash: tx3.txid,
    //     coin: Coin.bitcoincashTestNet,
    //   )).thenAnswer((_) async => tx3Raw);
    //   when(cachedClient?.getTransaction(
    //     txHash: tx4.txid,
    //     coin: Coin.bitcoincashTestNet,
    //   )).thenAnswer((_) async => tx4Raw);
    //
    //   await bch?.initializeNew();
    //   await bch?.initializeExisting();
    //
    //   final utxoData = await bch?.utxoData;
    //   expect(utxoData, isA<UtxoData>());
    //   expect(utxoData.toString(),
    //       r"{totalUserCurrency: $103.2173, satoshiBalance: 1032173000, bitcoinBalance: null, unspentOutputArray: [{txid: 86198a91805b6c53839a6a97736c434a5a2f85d68595905da53df7df59b9f01a, vout: 0, value: 800000000, fiat: $80, blocked: false, status: {confirmed: true, blockHash: e52cabb4445eb9ceb3f4f8d68cc64b1ede8884ce560296c27826a48ecc477370, blockHeight: 4274457, blockTime: 1655755742, confirmations: 100}}, {txid: a4b6bd97a4b01b4305d0cf02e9bac6b7c37cda2f8e9dfe291ce4170b810ed469, vout: 0, value: 72173000, fiat: $7.2173, blocked: false, status: {confirmed: false, blockHash: bd239f922b3ecec299a90e4d1ce389334e8df4b95470fb5919966b0b650bb95b, blockHeight: 4270459, blockTime: 1655500912, confirmations: 0}}, {txid: 68c159dcc2f962cbc61f7dd3c8d0dcc14da8adb443811107115531c853fc0c60, vout: 1, value: 100000000, fiat: $10, blocked: false, status: {confirmed: false, blockHash: 9fee9b9446cfe81abb1a17bec56e6c160d9a6527e5b68b1141a827573bc2649f, blockHeight: 4255659, blockTime: 1654553247, confirmations: 0}}, {txid: 628a78606058ce4036aee3907e042742156c1894d34419578de5671b53ea5800, vout: 0, value: 60000000, fiat: $6, blocked: false, status: {confirmed: true, blockHash: bc461ab43e3a80d9a4d856ee9ff70f41d86b239d5f0581ffd6a5c572889a6b86, blockHeight: 4270352, blockTime: 1652888705, confirmations: 100}}]}");
    //
    //   final outputs = await bch?.unspentOutputs;
    //   expect(outputs, isA<List<UtxoObject>>());
    //   expect(outputs?.length, 4);
    //
    //   final availableBalance = await bch?.availableBalance;
    //   expect(availableBalance, Decimal.parse("8.6"));
    //
    //   final totalBalance = await bch?.totalBalance;
    //   expect(totalBalance, Decimal.parse("10.32173"));
    //
    //   final pendingBalance = await bch?.pendingBalance;
    //   expect(pendingBalance, Decimal.parse("1.72173"));
    //
    //   final balanceMinusMaxFee = await bch?.balanceMinusMaxFee;
    //   expect(balanceMinusMaxFee, Decimal.parse("7.6"));
    //
    //   verify(client?.ping()).called(1);
    //   verify(client?.getServerFeatures()).called(1);
    //   verify(client?.estimateFee(blocks: 1)).called(1);
    //   verify(client?.estimateFee(blocks: 5)).called(1);
    //   verify(client?.estimateFee(blocks: 20)).called(1);
    //   verify(client?.getBatchUTXOs(args: anyNamed("args"))).called(1);
    //   verify(cachedClient?.getTransaction(
    //     txHash: tx1.txid,
    //     coin: Coin.bitcoincashTestNet,
    //   )).called(1);
    //   verify(cachedClient?.getTransaction(
    //     txHash: tx2.txid,
    //     coin: Coin.bitcoincashTestNet,
    //   )).called(1);
    //   verify(cachedClient?.getTransaction(
    //     txHash: tx3.txid,
    //     coin: Coin.bitcoincashTestNet,
    //   )).called(1);
    //   verify(cachedClient?.getTransaction(
    //     txHash: tx4.txid,
    //     coin: Coin.bitcoincashTestNet,
    //   )).called(1);
    //
    //   verifyNoMoreInteractions(client);
    //   verifyNoMoreInteractions(cachedClient);
    //   verifyNoMoreInteractions(priceAPI);
    // });
    //
    // // test("get utxos - multiple batches", () async {
    // //   bch = BitcoinCashWallet(
    // //     walletId: testWalletId,
    // //     walletName: testWalletName,
    // //     coin: dtestcoin,
    // //     client: client!,
    // //     cachedClient: cachedClient!,
    // //     priceAPI: priceAPI,
    // //     secureStore: secureStore,
    // //   );
    // //   when(client?.ping()).thenAnswer((_) async => true);
    // //   when(client?.getServerFeatures()).thenAnswer((_) async => {
    // //         "hosts": {},
    // //         "pruning": null,
    // //         "server_version": "Unit tests",
    // //         "protocol_min": "1.4",
    // //         "protocol_max": "1.4.2",
    // //         "genesis_hash": GENESIS_HASH_TESTNET,
    // //         "hash_function": "sha256",
    // //         "services": []
    // //       });
    // //
    // //   when(client?.getBatchUTXOs(args: anyNamed("args")))
    // //       .thenAnswer((_) async => {});
    // //
    // //   when(priceAPI?.getbitcoincashPrice(baseCurrency: "USD"))
    // //       .thenAnswer((realInvocation) async => Decimal.fromInt(10));
    // //
    // //   await bch?.initializeWallet();
    // //
    // //   // add some extra addresses to make sure we have more than the single batch size of 10
    // //   final wallet = await Hive.openBox(testWalletId);
    // //   final addresses = await wallet.get("receivingAddressesP2PKH");
    // //   addresses.add("DQaAi9R58GXMpDyhePys6hHCuif4fhc1sN");
    // //   addresses.add("DBVhuF8QgeuxU2pssxzMgJqPhGCx5qyVkD");
    // //   addresses.add("DCAokB2CXXPWC2JPj6jrK6hxANwTF2m21x");
    // //   addresses.add("D6Y9brE3jUGPrqLmSEWh6yQdgY5b7ZkTib");
    // //   addresses.add("DKdtobt3M5b3kQWZf1zRUZn3Ys6JTQwbPL");
    // //   addresses.add("DBYiFr1BRc2zB19p8jxdSu6DvFGTdWvkVF");
    // //   addresses.add("DE5ffowvbHPzzY6aRVGpzxR2QqikXxUKPG");
    // //   addresses.add("DA97TLg1741J2aLK6z9bVZoWysgQbMR45K");
    // //   addresses.add("DGGmf9q4PKcJXauPRstsFetu9DjW1VSBYk");
    // //   addresses.add("D9bXqnTtufcb6oJyuZniCXbst8MMLzHxUd");
    // //   addresses.add("DA6nv8M4kYL4RxxKrcsPaPUA1KrFA7CTfN");
    // //   await wallet.put("receivingAddressesP2PKH", addresses);
    // //
    // //   final utxoData = await bch?.utxoData;
    // //   expect(utxoData, isA<UtxoData>());
    // //
    // //   final outputs = await bch?.unspentOutputs;
    // //   expect(outputs, isA<List<UtxoObject>>());
    // //   expect(outputs?.length, 0);
    // //
    // //   verify(client?.ping()).called(1);
    // //   verify(client?.getServerFeatures()).called(1);
    // //   verify(client?.getBatchUTXOs(args: anyNamed("args"))).called(2);
    // //   verify(priceAPI?.getbitcoincashPrice(baseCurrency: "USD")).called(1);
    // //
    // //   verifyNoMoreInteractions(client);
    // //   verifyNoMoreInteractions(cachedClient);
    // //   verifyNoMoreInteractions(priceAPI);
    // // });
    //
    test("get utxos fails", () async {
      bch = BitcoinCashWallet(
        walletId: testWalletId,
        walletName: testWalletName,
        coin: bchtestcoin,
        client: client!,
        cachedClient: cachedClient!,
        tracker: tracker!,
        priceAPI: priceAPI,
        secureStore: secureStore,
      );
      when(client?.ping()).thenAnswer((_) async => true);
      when(client?.getServerFeatures()).thenAnswer((_) async => {
            "hosts": {},
            "pruning": null,
            "server_version": "Unit tests",
            "protocol_min": "1.4",
            "protocol_max": "1.4.2",
            "genesis_hash": GENESIS_HASH_TESTNET,
            "hash_function": "sha256",
            "services": []
          });

      await Hive.openBox<dynamic>(testWalletId);
      await Hive.openBox<dynamic>(DB.boxNamePrefs);

      when(client?.getBatchUTXOs(args: anyNamed("args")))
          .thenThrow(Exception("some exception"));

      await bch?.initializeNew();
      await bch?.initializeExisting();

      final utxoData = await bch?.utxoData;
      expect(utxoData, isA<UtxoData>());
      expect(utxoData.toString(),
          r"{totalUserCurrency: 0.00, satoshiBalance: 0, bitcoinBalance: 0, unspentOutputArray: []}");

      final outputs = await bch?.unspentOutputs;
      expect(outputs, isA<List<UtxoObject>>());
      expect(outputs?.length, 0);

      verifyNever(client?.ping()).called(0);
      verify(client?.getServerFeatures()).called(1);
      verify(client?.getBatchUTXOs(args: anyNamed("args"))).called(1);

      verifyNoMoreInteractions(client);
      verifyNoMoreInteractions(cachedClient);
      verifyNoMoreInteractions(priceAPI);
    });

    test("chain height fetch, update, and get", () async {
      bch = BitcoinCashWallet(
        walletId: testWalletId,
        walletName: testWalletName,
        coin: bchtestcoin,
        client: client!,
        cachedClient: cachedClient!,
        tracker: tracker!,
        priceAPI: priceAPI,
        secureStore: secureStore,
      );
      when(client?.ping()).thenAnswer((_) async => true);
      when(client?.getServerFeatures()).thenAnswer((_) async => {
            "hosts": {},
            "pruning": null,
            "server_version": "Unit tests",
            "protocol_min": "1.4",
            "protocol_max": "1.4.2",
            "genesis_hash": GENESIS_HASH_TESTNET,
            "hash_function": "sha256",
            "services": []
          });

      await Hive.openBox<dynamic>(testWalletId);
      await Hive.openBox<dynamic>(DB.boxNamePrefs);

      await bch?.initializeNew();
      await bch?.initializeExisting();

      // get stored
      expect(await bch?.storedChainHeight, 0);

      // fetch fails
      when(client?.getBlockHeadTip()).thenThrow(Exception("Some exception"));
      expect(await bch?.chainHeight, -1);

      // fetch succeeds
      when(client?.getBlockHeadTip()).thenAnswer((realInvocation) async => {
            "height": 100,
            "hex": "some block hex",
          });
      expect(await bch?.chainHeight, 100);

      // update
      await bch?.updateStoredChainHeight(newHeight: 1000);

      // fetch updated
      expect(await bch?.storedChainHeight, 1000);

      verifyNever(client?.ping()).called(0);
      verify(client?.getServerFeatures()).called(1);
      verify(client?.getBlockHeadTip()).called(2);
      verifyNoMoreInteractions(client);
      verifyNoMoreInteractions(cachedClient);
      verifyNoMoreInteractions(tracker);
      verifyNoMoreInteractions(priceAPI);
    });

    test("getTxCount succeeds", () async {
      when(client?.getHistory(
              scripthash:
                  "1df1cab6d109d506aa424b00b6a013c5e1947dc13b78d62b4d0e9f518b3035d1"))
          .thenAnswer((realInvocation) async => [
                {
                  "height": 757727,
                  "tx_hash":
                      "aaac451c49c2e3bcbccb8a9fded22257eeb94c1702b456171aa79250bc1b20e0"
                },
                {
                  "height": 0,
                  "tx_hash":
                      "9ac29f35b72ca596bc45362d1f9556b0555e1fb633ca5ac9147a7fd467700afe"
                }
              ]);

      final count =
          await bch?.getTxCount(address: "1MMi672ueYFXLLdtZqPe4FsrS46gNDyRq1");

      expect(count, 2);

      verify(client?.getHistory(
              scripthash:
                  "1df1cab6d109d506aa424b00b6a013c5e1947dc13b78d62b4d0e9f518b3035d1"))
          .called(1);

      expect(secureStore?.interactions, 0);
      verifyNoMoreInteractions(client);
      verifyNoMoreInteractions(cachedClient);
      verifyNoMoreInteractions(tracker);
      verifyNoMoreInteractions(priceAPI);
    });
    //TODO - Needs refactoring
    test("getTxCount fails", () async {
      when(client?.getHistory(
              scripthash:
                  "64953f7db441a21172de206bf70b920c8c718ed4f03df9a85073c0400be0053c"))
          .thenThrow(Exception("some exception"));

      bool didThrow = false;
      try {
        await bch?.getTxCount(address: "D6biRASajCy7GcJ8R6ZP4RE94fNRerJLCC");
      } catch (_) {
        didThrow = true;
      }
      expect(didThrow, true);

      verifyNever(client?.getHistory(
              scripthash:
                  "64953f7db441a21172de206bf70b920c8c718ed4f03df9a85073c0400be0053c"))
          .called(0);

      expect(secureStore?.interactions, 0);
      verifyNoMoreInteractions(client);
      verifyNoMoreInteractions(cachedClient);
      verifyNoMoreInteractions(tracker);
      verifyNoMoreInteractions(priceAPI);
    });

    test("_checkCurrentReceivingAddressesForTransactions succeeds", () async {
      when(client?.ping()).thenAnswer((_) async => true);
      when(client?.getServerFeatures()).thenAnswer((_) async => {
            "hosts": {},
            "pruning": null,
            "server_version": "Unit tests",
            "protocol_min": "1.4",
            "protocol_max": "1.4.2",
            "genesis_hash": GENESIS_HASH_MAINNET,
            "hash_function": "sha256",
            "services": []
          });
      when(client?.getHistory(scripthash: anyNamed("scripthash")))
          .thenAnswer((realInvocation) async => [
                {
                  "height": 4270385,
                  "tx_hash":
                      "c07f740ad72c0dd759741f4c9ab4b1586a22bc16545584364ac9b3d845766271"
                },
                {
                  "height": 4270459,
                  "tx_hash":
                      "82da70c660daf4d42abd403795d047918c4021ff1d706b61790cda01a1c5ae5a"
                }
              ]);

      await Hive.openBox<dynamic>(testWalletId);
      await Hive.openBox<dynamic>(DB.boxNamePrefs);

      await bch?.initializeNew();
      await bch?.initializeExisting();

      bool didThrow = false;
      try {
        await bch?.checkCurrentReceivingAddressesForTransactions();
      } catch (_) {
        didThrow = true;
      }
      expect(didThrow, false);

      verify(client?.getHistory(scripthash: anyNamed("scripthash"))).called(1);
      verify(client?.getServerFeatures()).called(1);
      verifyNever(client?.ping()).called(0);

      expect(secureStore?.interactions, 11);
      expect(secureStore?.reads, 7);
      expect(secureStore?.writes, 4);
      expect(secureStore?.deletes, 0);
      verifyNoMoreInteractions(client);
      verifyNoMoreInteractions(cachedClient);
      verifyNoMoreInteractions(priceAPI);
    });

    test("_checkCurrentReceivingAddressesForTransactions fails", () async {
      when(client?.ping()).thenAnswer((_) async => true);
      when(client?.getServerFeatures()).thenAnswer((_) async => {
            "hosts": {},
            "pruning": null,
            "server_version": "Unit tests",
            "protocol_min": "1.4",
            "protocol_max": "1.4.2",
            "genesis_hash": GENESIS_HASH_MAINNET,
            "hash_function": "sha256",
            "services": []
          });
      when(client?.getHistory(scripthash: anyNamed("scripthash")))
          .thenThrow(Exception("some exception"));

      await Hive.openBox<dynamic>(testWalletId);
      await Hive.openBox<dynamic>(DB.boxNamePrefs);

      await bch?.initializeNew();
      await bch?.initializeExisting();

      bool didThrow = false;
      try {
        await bch?.checkCurrentReceivingAddressesForTransactions();
      } catch (_) {
        didThrow = true;
      }
      expect(didThrow, true);

      verify(client?.getHistory(scripthash: anyNamed("scripthash"))).called(1);
      verify(client?.getServerFeatures()).called(1);
      verifyNever(client?.ping()).called(0);

      expect(secureStore?.interactions, 8);
      expect(secureStore?.reads, 5);
      expect(secureStore?.writes, 3);
      expect(secureStore?.deletes, 0);
      verifyNoMoreInteractions(client);
      verifyNoMoreInteractions(cachedClient);
      verifyNoMoreInteractions(priceAPI);
    });

    test("_checkCurrentChangeAddressesForTransactions succeeds", () async {
      when(client?.ping()).thenAnswer((_) async => true);
      when(client?.getServerFeatures()).thenAnswer((_) async => {
            "hosts": {},
            "pruning": null,
            "server_version": "Unit tests",
            "protocol_min": "1.4",
            "protocol_max": "1.4.2",
            "genesis_hash": GENESIS_HASH_MAINNET,
            "hash_function": "sha256",
            "services": []
          });
      when(client?.getHistory(scripthash: anyNamed("scripthash")))
          .thenAnswer((realInvocation) async => [
                {
                  "height": 4286283,
                  "tx_hash":
                      "4c119685401e28982283e644c57d84fde6aab83324012e35c9b49e6efd99b49b"
                },
                {
                  "height": 4286295,
                  "tx_hash":
                      "82da70c660daf4d42abd403795d047918c4021ff1d706b61790cda01a1c5ae5a"
                }
              ]);

      await Hive.openBox<dynamic>(testWalletId);
      await Hive.openBox<dynamic>(DB.boxNamePrefs);

      await bch?.initializeNew();
      await bch?.initializeExisting();

      bool didThrow = false;
      try {
        await bch?.checkCurrentChangeAddressesForTransactions();
      } catch (_) {
        didThrow = true;
      }
      expect(didThrow, false);

      verify(client?.getHistory(scripthash: anyNamed("scripthash"))).called(1);
      verify(client?.getServerFeatures()).called(1);
      verifyNever(client?.ping()).called(0);

      expect(secureStore?.interactions, 11);
      expect(secureStore?.reads, 7);
      expect(secureStore?.writes, 4);
      expect(secureStore?.deletes, 0);
      verifyNoMoreInteractions(client);
      verifyNoMoreInteractions(cachedClient);
      verifyNoMoreInteractions(tracker);
      verifyNoMoreInteractions(priceAPI);
    });

    test("_checkCurrentChangeAddressesForTransactions fails", () async {
      when(client?.ping()).thenAnswer((_) async => true);
      when(client?.getServerFeatures()).thenAnswer((_) async => {
            "hosts": {},
            "pruning": null,
            "server_version": "Unit tests",
            "protocol_min": "1.4",
            "protocol_max": "1.4.2",
            "genesis_hash": GENESIS_HASH_MAINNET,
            "hash_function": "sha256",
            "services": []
          });
      when(client?.getHistory(scripthash: anyNamed("scripthash")))
          .thenThrow(Exception("some exception"));

      await Hive.openBox<dynamic>(testWalletId);
      await Hive.openBox<dynamic>(DB.boxNamePrefs);

      await bch?.initializeNew();
      await bch?.initializeExisting();

      bool didThrow = false;
      try {
        await bch?.checkCurrentChangeAddressesForTransactions();
      } catch (_) {
        didThrow = true;
      }
      expect(didThrow, true);

      verify(client?.getHistory(scripthash: anyNamed("scripthash"))).called(1);
      verify(client?.getServerFeatures()).called(1);
      verifyNever(client?.ping()).called(0);

      expect(secureStore?.interactions, 8);
      expect(secureStore?.reads, 5);
      expect(secureStore?.writes, 3);
      expect(secureStore?.deletes, 0);
      verifyNoMoreInteractions(client);
      verifyNoMoreInteractions(cachedClient);
      verifyNoMoreInteractions(priceAPI);
    });

    // test("getAllTxsToWatch", () async {
    //   TestWidgetsFlutterBinding.ensureInitialized();
    //   var notifications = {"show": 0};
    //   const MethodChannel('dexterous.com/flutter/local_notifications')
    //       .setMockMethodCallHandler((call) async {
    //     notifications[call.method]++;
    //   });
    //
    //   bch?.pastUnconfirmedTxs = {
    //     "88b7b5077d940dde1bc63eba37a09dec8e7b9dad14c183a2e879a21b6ec0ac1c",
    //     "b39bac02b65af46a49e2985278fe24ca00dd5d627395d88f53e35568a04e10fa",
    //   };
    //
    //   await bch?.getAllTxsToWatch(transactionData);
    //   expect(notifications.length, 1);
    //   expect(notifications["show"], 3);
    //
    //   expect(bch?.unconfirmedTxs, {
    //     "b2f75a017a7435f1b8c2e080a865275d8f80699bba68d8dce99a94606e7b3528",
    //     'dcca229760b44834478f0b266c9b3f5801e0139fdecacdc0820e447289a006d3',
    //   });
    //
    //   expect(secureStore?.interactions, 0);
    //   verifyNoMoreInteractions(client);
    //   verifyNoMoreInteractions(cachedClient);
    //   verifyNoMoreInteractions(priceAPI);
    // });
    //
    // test("refreshIfThereIsNewData true A", () async {
    //   when(client?.getTransaction(
    //     txHash:
    //         "a4b6bd97a4b01b4305d0cf02e9bac6b7c37cda2f8e9dfe291ce4170b810ed469",
    //   )).thenAnswer((_) async => tx2Raw);
    //   when(client?.getTransaction(
    //     txHash:
    //         "86198a91805b6c53839a6a97736c434a5a2f85d68595905da53df7df59b9f01a",
    //   )).thenAnswer((_) async => tx1Raw);
    //
    //   bch = BitcoinCashWallet(
    //     walletId: testWalletId,
    //     walletName: testWalletName,
    //     coin: dtestcoin,
    //     client: client!,
    //     cachedClient: cachedClient!,
    //     priceAPI: priceAPI,
    //     secureStore: secureStore,
    //   );
    //   final wallet = await Hive.openBox(testWalletId);
    //   await wallet.put('receivingAddressesP2PKH', []);
    //
    //   await wallet.put('changeAddressesP2PKH', []);
    //
    //   bch?.unconfirmedTxs = {
    //     "a4b6bd97a4b01b4305d0cf02e9bac6b7c37cda2f8e9dfe291ce4170b810ed469",
    //     "86198a91805b6c53839a6a97736c434a5a2f85d68595905da53df7df59b9f01a"
    //   };
    //
    //   final result = await bch?.refreshIfThereIsNewData();
    //
    //   expect(result, true);
    //
    //   verify(client?.getTransaction(
    //     txHash:
    //         "a4b6bd97a4b01b4305d0cf02e9bac6b7c37cda2f8e9dfe291ce4170b810ed469",
    //   )).called(1);
    //   verify(client?.getTransaction(
    //     txHash:
    //         "86198a91805b6c53839a6a97736c434a5a2f85d68595905da53df7df59b9f01a",
    //   )).called(1);
    //
    //   expect(secureStore?.interactions, 0);
    //   verifyNoMoreInteractions(client);
    //   verifyNoMoreInteractions(cachedClient);
    //   verifyNoMoreInteractions(priceAPI);
    // });
    //
    // test("refreshIfThereIsNewData true B", () async {
    //   // when(priceAPI.getbitcoincashPrice(baseCurrency: "USD"))
    //   //     .thenAnswer((_) async => Decimal.fromInt(10));
    //
    //   when(client?.getBatchHistory(args: anyNamed("args")))
    //       .thenAnswer((realInvocation) async {
    //     final uuids = Map<String, List<dynamic>>.from(realInvocation
    //             .namedArguments.values.first as Map<dynamic, dynamic>)
    //         .keys
    //         .toList(growable: false);
    //     return {
    //       uuids[0]: [
    //         {
    //           "tx_hash":
    //               "351a94874379a5444c8891162472acf66de538a1abc647d4753f3e1eb5ec66f9",
    //           "height": 4286305
    //         },
    //         {
    //           "tx_hash":
    //               "82da70c660daf4d42abd403795d047918c4021ff1d706b61790cda01a1c5ae5a",
    //           "height": 4286295
    //         }
    //       ],
    //       uuids[1]: [
    //         {
    //           "tx_hash":
    //               "4c119685401e28982283e644c57d84fde6aab83324012e35c9b49e6efd99b49b",
    //           "height": 4286283
    //         }
    //       ],
    //     };
    //   });
    //
    //   when(client?.getTransaction(
    //     txHash:
    //         "82da70c660daf4d42abd403795d047918c4021ff1d706b61790cda01a1c5ae5a",
    //   )).thenAnswer((_) async => tx2Raw);
    //   when(client?.getTransaction(
    //     txHash:
    //         "4c119685401e28982283e644c57d84fde6aab83324012e35c9b49e6efd99b49b",
    //   )).thenAnswer((_) async => tx1Raw);
    //
    //   when(cachedClient?.getTransaction(
    //           txHash:
    //               "351a94874379a5444c8891162472acf66de538a1abc647d4753f3e1eb5ec66f9",
    //           coin: Coin.bitcoincashTestNet,
    //           callOutSideMainIsolate: false))
    //       .thenAnswer((_) async => tx3Raw);
    //   when(cachedClient?.getTransaction(
    //           txHash:
    //               "351a94874379a5444c8891162472acf66de538a1abc647d4753f3e1eb5ec66f9",
    //           coin: Coin.bitcoincashTestNet,
    //           callOutSideMainIsolate: false))
    //       .thenAnswer((_) async => tx3Raw);
    //   when(cachedClient?.getTransaction(
    //           txHash:
    //               "4c119685401e28982283e644c57d84fde6aab83324012e35c9b49e6efd99b49b",
    //           coin: Coin.bitcoincashTestNet,
    //           callOutSideMainIsolate: false))
    //       .thenAnswer((_) async => tx1Raw);
    //   when(cachedClient?.getTransaction(
    //           txHash:
    //               "4493caff0e1b4f248e3c6219e7f288cfdb46c32b72a77aec469098c5f7f5154e",
    //           coin: Coin.bitcoincashTestNet,
    //           callOutSideMainIsolate: false))
    //       .thenAnswer((_) async => tx5Raw);
    //   when(cachedClient?.getTransaction(
    //           txHash:
    //               "e095cbe5531d174c3fc5c9c39a0e6ba2769489cdabdc17b35b2e3a33a3c2fc61",
    //           coin: Coin.bitcoincashTestNet,
    //           callOutSideMainIsolate: false))
    //       .thenAnswer((_) async => tx6Raw);
    //   when(cachedClient?.getTransaction(
    //           txHash:
    //               "d3054c63fe8cfafcbf67064ec66b9fbe1ac293860b5d6ffaddd39546658b72de",
    //           coin: Coin.bitcoincashTestNet,
    //           callOutSideMainIsolate: false))
    //       .thenAnswer((_) async => tx7Raw);
    //   when(cachedClient?.getTransaction(
    //           txHash:
    //               "7b34e60cc37306f866667deb67b14096f4ea2add941fd6e2238a639000642b82",
    //           coin: Coin.bitcoincashTestNet,
    //           callOutSideMainIsolate: false))
    //       .thenAnswer((_) async => tx4Raw);
    //   when(cachedClient?.getTransaction(
    //           txHash:
    //               "a70c6f0690fa84712dc6b3d20ee13862fe015a08cf2dc8949c4300d49c3bdeb5",
    //           coin: Coin.bitcoincashTestNet,
    //           callOutSideMainIsolate: false))
    //       .thenAnswer((_) async => tx8Raw);
    //
    //   bch = BitcoinCashWallet(
    //     walletId: testWalletId,
    //     walletName: testWalletName,
    //     coin: dtestcoin,
    //     client: client!,
    //     cachedClient: cachedClient!,
    //     priceAPI: priceAPI,
    //     secureStore: secureStore,
    //   );
    //   final wallet = await Hive.openBox(testWalletId);
    //   await wallet.put('receivingAddressesP2PKH', []);
    //
    //   await wallet.put('changeAddressesP2PKH', []);
    //
    //   bch?.unconfirmedTxs = {
    //     "82da70c660daf4d42abd403795d047918c4021ff1d706b61790cda01a1c5ae5a",
    //   };
    //
    //   final result = await bch?.refreshIfThereIsNewData();
    //
    //   expect(result, true);
    //
    //   verify(client?.getBatchHistory(args: anyNamed("args"))).called(2);
    //   verify(client?.getTransaction(
    //     txHash:
    //         "82da70c660daf4d42abd403795d047918c4021ff1d706b61790cda01a1c5ae5a",
    //   )).called(1);
    //   verify(cachedClient?.getTransaction(
    //           txHash: anyNamed("tx_hash"),
    //           verbose: true,
    //           coin: Coin.bitcoincashTestNet,
    //           callOutSideMainIsolate: false))
    //       .called(9);
    //   // verify(priceAPI?.getbitcoincashPrice(baseCurrency: "USD")).called(1);
    //
    //   expect(secureStore?.interactions, 0);
    //   verifyNoMoreInteractions(client);
    //   verifyNoMoreInteractions(cachedClient);
    //   verifyNoMoreInteractions(priceAPI);
    // });

    // test("refreshIfThereIsNewData false A", () async {
    //   // when(priceAPI.getbitcoincashPrice(baseCurrency: "USD"))
    //   //     .thenAnswer((_) async => Decimal.fromInt(10));
    //
    //   when(client?.getBatchHistory(args: anyNamed("args")))
    //       .thenAnswer((realInvocation) async {
    //     final uuids = Map<String, List<dynamic>>.from(realInvocation
    //             .namedArguments.values.first as Map<dynamic, dynamic>)
    //         .keys
    //         .toList(growable: false);
    //     return {
    //       uuids[0]: [
    //         {
    //           "tx_hash":
    //               "351a94874379a5444c8891162472acf66de538a1abc647d4753f3e1eb5ec66f9",
    //           "height": 4286305
    //         },
    //         {
    //           "tx_hash":
    //               "82da70c660daf4d42abd403795d047918c4021ff1d706b61790cda01a1c5ae5a",
    //           "height": 4286295
    //         }
    //       ],
    //       uuids[1]: [
    //         {
    //           "tx_hash":
    //               "4c119685401e28982283e644c57d84fde6aab83324012e35c9b49e6efd99b49b",
    //           "height": 4286283
    //         }
    //       ],
    //     };
    //   });
    //
    //   when(client?.getTransaction(
    //     txHash:
    //         "82da70c660daf4d42abd403795d047918c4021ff1d706b61790cda01a1c5ae5a",
    //   )).thenAnswer((_) async => tx2Raw);
    //   when(client?.getTransaction(
    //     txHash:
    //         "4c119685401e28982283e644c57d84fde6aab83324012e35c9b49e6efd99b49b",
    //   )).thenAnswer((_) async => tx1Raw);
    //
    //   when(cachedClient?.getTransaction(
    //           txHash:
    //               "4c119685401e28982283e644c57d84fde6aab83324012e35c9b49e6efd99b49b",
    //           coin: Coin.bitcoincashTestNet,
    //           callOutSideMainIsolate: false))
    //       .thenAnswer((_) async => tx1Raw);
    //   when(cachedClient?.getTransaction(
    //           txHash:
    //               "82da70c660daf4d42abd403795d047918c4021ff1d706b61790cda01a1c5ae5a",
    //           coin: Coin.bitcoincashTestNet,
    //           callOutSideMainIsolate: false))
    //       .thenAnswer((_) async => tx2Raw);
    //   when(cachedClient?.getTransaction(
    //           txHash:
    //               "351a94874379a5444c8891162472acf66de538a1abc647d4753f3e1eb5ec66f9",
    //           coin: Coin.bitcoincashTestNet,
    //           callOutSideMainIsolate: false))
    //       .thenAnswer((_) async => tx3Raw);
    //   when(cachedClient?.getTransaction(
    //           txHash:
    //               "4493caff0e1b4f248e3c6219e7f288cfdb46c32b72a77aec469098c5f7f5154e",
    //           coin: Coin.bitcoincashTestNet,
    //           callOutSideMainIsolate: false))
    //       .thenAnswer((_) async => tx5Raw);
    //   when(cachedClient?.getTransaction(
    //           txHash:
    //               "7b34e60cc37306f866667deb67b14096f4ea2add941fd6e2238a639000642b82",
    //           coin: Coin.bitcoincashTestNet,
    //           callOutSideMainIsolate: false))
    //       .thenAnswer((_) async => tx4Raw);
    //   when(cachedClient?.getTransaction(
    //           txHash:
    //               "e095cbe5531d174c3fc5c9c39a0e6ba2769489cdabdc17b35b2e3a33a3c2fc61",
    //           coin: Coin.bitcoincashTestNet,
    //           callOutSideMainIsolate: false))
    //       .thenAnswer((_) async => tx6Raw);
    //   when(cachedClient?.getTransaction(
    //           txHash:
    //               "d3054c63fe8cfafcbf67064ec66b9fbe1ac293860b5d6ffaddd39546658b72de",
    //           coin: Coin.bitcoincashTestNet,
    //           callOutSideMainIsolate: false))
    //       .thenAnswer((_) async => tx7Raw);
    //   when(cachedClient?.getTransaction(
    //           txHash:
    //               "a70c6f0690fa84712dc6b3d20ee13862fe015a08cf2dc8949c4300d49c3bdeb5",
    //           coin: Coin.bitcoincashTestNet,
    //           callOutSideMainIsolate: false))
    //       .thenAnswer((_) async => tx8Raw);
    //
    //   bch = BitcoinCashWallet(
    //     walletId: testWalletId,
    //     walletName: testWalletName,
    //     coin: dtestcoin,
    //     client: client!,
    //     cachedClient: cachedClient!,
    //     tracker: tracker!,
    //     priceAPI: priceAPI,
    //     secureStore: secureStore,
    //   );
    //   final wallet = await Hive.openBox(testWalletId);
    //   await wallet.put('receivingAddressesP2PKH', []);
    //
    //   await wallet.put('changeAddressesP2PKH', []);
    //
    //   bch?.unconfirmedTxs = {
    //     "82da70c660daf4d42abd403795d047918c4021ff1d706b61790cda01a1c5ae5a",
    //     "351a94874379a5444c8891162472acf66de538a1abc647d4753f3e1eb5ec66f9"
    //   };
    //
    //   final result = await bch?.refreshIfThereIsNewData();
    //
    //   expect(result, false);
    //
    //   verify(client?.getBatchHistory(args: anyNamed("args"))).called(2);
    //   verify(client?.getTransaction(
    //     txHash:
    //         "82da70c660daf4d42abd403795d047918c4021ff1d706b61790cda01a1c5ae5a",
    //   )).called(1);
    //   verify(cachedClient?.getTransaction(
    //           txHash: anyNamed("tx_hash"),
    //           verbose: true,
    //           coin: Coin.bitcoincashTestNet,
    //           callOutSideMainIsolate: false))
    //       .called(15);
    //   // verify(priceAPI.getbitcoincashPrice(baseCurrency: "USD")).called(1);
    //
    //   expect(secureStore?.interactions, 0);
    //   verifyNoMoreInteractions(client);
    //   verifyNoMoreInteractions(cachedClient);
    //   verifyNoMoreInteractions(priceAPI);
    // });

    // // test("refreshIfThereIsNewData false B", () async {
    // //   when(client?.getBatchHistory(args: anyNamed("args")))
    // //       .thenThrow(Exception("some exception"));
    // //
    // //   when(client?.getTransaction(
    // //     txHash:
    // //         "82da70c660daf4d42abd403795d047918c4021ff1d706b61790cda01a1c5ae5a",
    // //   )).thenAnswer((_) async => tx2Raw);
    // //
    // //   bch = BitcoinCashWallet(
    // //     walletId: testWalletId,
    // //     walletName: testWalletName,
    // //     coin: dtestcoin,
    // //     client: client!,
    // //     cachedClient: cachedClient!,
    // //     tracker: tracker!,
    // //     priceAPI: priceAPI,
    // //     secureStore: secureStore,
    // //   );
    // //   final wallet = await Hive.openBox(testWalletId);
    // //   await wallet.put('receivingAddressesP2PKH', []);
    // //
    // //   await wallet.put('changeAddressesP2PKH', []);
    // //
    // //   bch?.unconfirmedTxs = {
    // //     "82da70c660daf4d42abd403795d047918c4021ff1d706b61790cda01a1c5ae5a",
    // //   };
    // //
    // //   final result = await bch?.refreshIfThereIsNewData();
    // //
    // //   expect(result, false);
    // //
    // //   verify(client?.getBatchHistory(args: anyNamed("args"))).called(1);
    // //   verify(client?.getTransaction(
    // //     txHash:
    // //         "a4b6bd97a4b01b4305d0cf02e9bac6b7c37cda2f8e9dfe291ce4170b810ed469",
    // //   )).called(1);
    // //
    // //   expect(secureStore?.interactions, 0);
    // //   verifyNoMoreInteractions(client);
    // //   verifyNoMoreInteractions(cachedClient);
    // //   verifyNoMoreInteractions(priceAPI);
    // // });

    test("fullRescan succeeds", () async {
      when(client?.getServerFeatures()).thenAnswer((_) async => {
            "hosts": {},
            "pruning": null,
            "server_version": "Unit tests",
            "protocol_min": "1.4",
            "protocol_max": "1.4.2",
            "genesis_hash": GENESIS_HASH_MAINNET,
            "hash_function": "sha256",
            "services": []
          });
      when(client?.getBatchHistory(args: historyBatchArgs0))
          .thenAnswer((_) async => historyBatchResponse);
      when(client?.getBatchHistory(args: historyBatchArgs1))
          .thenAnswer((_) async => historyBatchResponse);
      when(cachedClient?.clearSharedTransactionCache(coin: Coin.bitcoincash))
          .thenAnswer((realInvocation) async {});

      final wallet = await Hive.openBox(testWalletId);

      // restore so we have something to rescan
      await bch?.recoverFromMnemonic(
          mnemonic: TEST_MNEMONIC,
          maxUnusedAddressGap: 2,
          maxNumberOfIndexesToCheck: 1000,
          height: 4000);

      // fetch valid wallet data
      final preReceivingAddressesP2PKH =
          await wallet.get('receivingAddressesP2PKH');
      final preChangeAddressesP2PKH = await wallet.get('changeAddressesP2PKH');
      final preReceivingIndexP2PKH = await wallet.get('receivingIndexP2PKH');
      final preChangeIndexP2PKH = await wallet.get('changeIndexP2PKH');
      final preUtxoData = await wallet.get('latest_utxo_model');
      final preReceiveDerivationsStringP2PKH = await secureStore?.read(
          key: "${testWalletId}_receiveDerivationsP2PKH");
      final preChangeDerivationsStringP2PKH = await secureStore?.read(
          key: "${testWalletId}_changeDerivationsP2PKH");

      // destroy the data that the rescan will fix
      await wallet.put(
          'receivingAddressesP2PKH', ["some address", "some other address"]);
      await wallet
          .put('changeAddressesP2PKH', ["some address", "some other address"]);

      await wallet.put('receivingIndexP2PKH', 123);
      await wallet.put('changeIndexP2PKH', 123);
      await secureStore?.write(
          key: "${testWalletId}_receiveDerivationsP2PKH", value: "{}");
      await secureStore?.write(
          key: "${testWalletId}_changeDerivationsP2PKH", value: "{}");

      bool hasThrown = false;
      try {
        await bch?.fullRescan(2, 1000);
      } catch (_) {
        hasThrown = true;
      }
      expect(hasThrown, false);

      // fetch wallet data again
      final receivingAddressesP2PKH =
          await wallet.get('receivingAddressesP2PKH');
      final changeAddressesP2PKH = await wallet.get('changeAddressesP2PKH');
      final receivingIndexP2PKH = await wallet.get('receivingIndexP2PKH');
      final changeIndexP2PKH = await wallet.get('changeIndexP2PKH');
      final utxoData = await wallet.get('latest_utxo_model');
      final receiveDerivationsStringP2PKH = await secureStore?.read(
          key: "${testWalletId}_receiveDerivationsP2PKH");
      final changeDerivationsStringP2PKH = await secureStore?.read(
          key: "${testWalletId}_changeDerivationsP2PKH");

      expect(preReceivingAddressesP2PKH, receivingAddressesP2PKH);
      expect(preChangeAddressesP2PKH, changeAddressesP2PKH);
      expect(preReceivingIndexP2PKH, receivingIndexP2PKH);
      expect(preChangeIndexP2PKH, changeIndexP2PKH);
      expect(preUtxoData, utxoData);
      expect(preReceiveDerivationsStringP2PKH, receiveDerivationsStringP2PKH);
      expect(preChangeDerivationsStringP2PKH, changeDerivationsStringP2PKH);

      verify(client?.getServerFeatures()).called(1);
      verify(client?.getBatchHistory(args: historyBatchArgs0)).called(2);
      // verify(client?.getBatchHistory(args: historyBatchArgs1)).called(2);
      verify(cachedClient?.clearSharedTransactionCache(coin: Coin.bitcoincash))
          .called(1);

      expect(secureStore?.writes, 9);
      expect(secureStore?.reads, 12);
      expect(secureStore?.deletes, 2);

      verifyNoMoreInteractions(client);
      verifyNoMoreInteractions(cachedClient);
      verifyNoMoreInteractions(tracker);
      verifyNoMoreInteractions(priceAPI);
    });

    test("get mnemonic list", () async {
      when(client?.getServerFeatures()).thenAnswer((_) async => {
            "hosts": {},
            "pruning": null,
            "server_version": "Unit tests",
            "protocol_min": "1.4",
            "protocol_max": "1.4.2",
            "genesis_hash": GENESIS_HASH_MAINNET,
            "hash_function": "sha256",
            "services": []
          });

      // when(client?.getBatchHistory(args: anyNamed("args")))
      //     .thenAnswer((thing) async {
      //   print(jsonEncode(thing.namedArguments.entries.first.value));
      //   return {};
      // });

      when(client?.getBatchHistory(args: historyBatchArgs0))
          .thenAnswer((_) async => emptyHistoryBatchResponse);
      when(client?.getBatchHistory(args: historyBatchArgs1))
          .thenAnswer((_) async => emptyHistoryBatchResponse);

      final wallet = await Hive.openBox(testWalletId);

      // add maxNumberOfIndexesToCheck and height
      await bch?.recoverFromMnemonic(
          mnemonic: TEST_MNEMONIC,
          maxUnusedAddressGap: 2,
          maxNumberOfIndexesToCheck: 1000,
          height: 4000);

      expect(await bch?.mnemonic, TEST_MNEMONIC.split(" "));
      //
      verify(client?.getServerFeatures()).called(1);
      verify(client?.getBatchHistory(args: historyBatchArgs0)).called(1);
      verify(client?.getBatchHistory(args: historyBatchArgs1)).called(1);

      verifyNoMoreInteractions(client);
      verifyNoMoreInteractions(cachedClient);
      verifyNoMoreInteractions(tracker);
      verifyNoMoreInteractions(priceAPI);
    });

    test(
        "recoverFromMnemonic using empty seed on mainnet fails due to bad genesis hash match",
        () async {
      when(client?.getServerFeatures()).thenAnswer((_) async => {
            "hosts": {},
            "pruning": null,
            "server_version": "Unit tests",
            "protocol_min": "1.4",
            "protocol_max": "1.4.2",
            "genesis_hash": GENESIS_HASH_TESTNET,
            "hash_function": "sha256",
            "services": []
          });

      bool hasThrown = false;
      try {
        await bch?.recoverFromMnemonic(
            mnemonic: TEST_MNEMONIC,
            maxUnusedAddressGap: 2,
            maxNumberOfIndexesToCheck: 1000,
            height: 4000);
      } catch (_) {
        hasThrown = true;
      }
      expect(hasThrown, true);

      verify(client?.getServerFeatures()).called(1);

      expect(secureStore?.interactions, 0);
      verifyNoMoreInteractions(client);
      verifyNoMoreInteractions(cachedClient);
      verifyNoMoreInteractions(priceAPI);
    });

    test(
        "recoverFromMnemonic using empty seed on testnet fails due to bad genesis hash match",
        () async {
      bch = BitcoinCashWallet(
        walletId: testWalletId,
        walletName: testWalletName,
        coin: Coin.bitcoincash,
        client: client!,
        cachedClient: cachedClient!,
        tracker: tracker!,
        priceAPI: priceAPI,
        secureStore: secureStore,
      );
      when(client?.getServerFeatures()).thenAnswer((_) async => {
            "hosts": {},
            "pruning": null,
            "server_version": "Unit tests",
            "protocol_min": "1.4",
            "protocol_max": "1.4.2",
            "genesis_hash": GENESIS_HASH_MAINNET,
            "hash_function": "sha256",
            "services": []
          });

      bool hasThrown = false;
      try {
        await bch?.recoverFromMnemonic(
            mnemonic: TEST_MNEMONIC,
            maxUnusedAddressGap: 2,
            maxNumberOfIndexesToCheck: 1000,
            height: 4000);
      } catch (_) {
        hasThrown = true;
      }
      expect(hasThrown, true);

      verify(client?.getServerFeatures()).called(1);

      expect(secureStore?.interactions, 0);
      verifyNoMoreInteractions(client);
      verifyNoMoreInteractions(cachedClient);
      verifyNoMoreInteractions(priceAPI);
    });

    test(
        "recoverFromMnemonic using empty seed on mainnet fails due to attempted overwrite of mnemonic",
        () async {
      when(client?.getServerFeatures()).thenAnswer((_) async => {
            "hosts": {},
            "pruning": null,
            "server_version": "Unit tests",
            "protocol_min": "1.4",
            "protocol_max": "1.4.2",
            "genesis_hash": GENESIS_HASH_MAINNET,
            "hash_function": "sha256",
            "services": []
          });

      await secureStore?.write(
          key: "${testWalletId}_mnemonic", value: "some mnemonic words");

      bool hasThrown = false;
      try {
        await bch?.recoverFromMnemonic(
            mnemonic: TEST_MNEMONIC,
            maxUnusedAddressGap: 2,
            maxNumberOfIndexesToCheck: 1000,
            height: 4000);
      } catch (_) {
        hasThrown = true;
      }
      expect(hasThrown, true);

      verify(client?.getServerFeatures()).called(1);

      expect(secureStore?.interactions, 2);
      verifyNoMoreInteractions(client);
      verifyNoMoreInteractions(cachedClient);
      verifyNoMoreInteractions(priceAPI);
    });

    test("recoverFromMnemonic using non empty seed on mainnet succeeds",
        () async {
      when(client?.getServerFeatures()).thenAnswer((_) async => {
            "hosts": {},
            "pruning": null,
            "server_version": "Unit tests",
            "protocol_min": "1.4",
            "protocol_max": "1.4.2",
            "genesis_hash": GENESIS_HASH_MAINNET,
            "hash_function": "sha256",
            "services": []
          });
      when(client?.getBatchHistory(args: historyBatchArgs0))
          .thenAnswer((_) async => historyBatchResponse);
      // when(client?.getBatchHistory(args: historyBatchArgs1))
      //     .thenAnswer((_) async => historyBatchResponse);

      final wallet = await Hive.openBox(testWalletId);

      bool hasThrown = false;
      try {
        await bch?.recoverFromMnemonic(
            mnemonic: TEST_MNEMONIC,
            maxUnusedAddressGap: 2,
            maxNumberOfIndexesToCheck: 1000,
            height: 4000);
      } catch (_) {
        hasThrown = true;
      }
      expect(hasThrown, false);

      verify(client?.getServerFeatures()).called(1);
      verify(client?.getBatchHistory(args: historyBatchArgs0)).called(1);
      // verify(client?.getBatchHistory(args: historyBatchArgs1)).called(1);

      expect(secureStore?.interactions, 6);
      expect(secureStore?.writes, 3);
      expect(secureStore?.reads, 3);
      expect(secureStore?.deletes, 0);

      verifyNoMoreInteractions(client);
      verifyNoMoreInteractions(cachedClient);
      verifyNoMoreInteractions(tracker);
      verifyNoMoreInteractions(priceAPI);
    });

    test("fullRescan succeeds", () async {
      when(client?.getServerFeatures()).thenAnswer((_) async => {
            "hosts": {},
            "pruning": null,
            "server_version": "Unit tests",
            "protocol_min": "1.4",
            "protocol_max": "1.4.2",
            "genesis_hash": GENESIS_HASH_MAINNET,
            "hash_function": "sha256",
            "services": []
          });
      when(client?.getBatchHistory(args: historyBatchArgs0))
          .thenAnswer((_) async => historyBatchResponse);
      when(client?.getBatchHistory(args: historyBatchArgs1))
          .thenAnswer((_) async => historyBatchResponse);
      when(cachedClient?.clearSharedTransactionCache(coin: Coin.bitcoincash))
          .thenAnswer((realInvocation) async {});

      final wallet = await Hive.openBox(testWalletId);

      // restore so we have something to rescan
      await bch?.recoverFromMnemonic(
          mnemonic: TEST_MNEMONIC,
          maxUnusedAddressGap: 2,
          maxNumberOfIndexesToCheck: 1000,
          height: 4000);

      // fetch valid wallet data
      final preReceivingAddressesP2PKH =
          await wallet.get('receivingAddressesP2PKH');
      final preChangeAddressesP2PKH = await wallet.get('changeAddressesP2PKH');
      final preReceivingIndexP2PKH = await wallet.get('receivingIndexP2PKH');
      final preChangeIndexP2PKH = await wallet.get('changeIndexP2PKH');
      final preUtxoData = await wallet.get('latest_utxo_model');
      final preReceiveDerivationsStringP2PKH = await secureStore?.read(
          key: "${testWalletId}_receiveDerivationsP2PKH");
      final preChangeDerivationsStringP2PKH = await secureStore?.read(
          key: "${testWalletId}_changeDerivationsP2PKH");

      // destroy the data that the rescan will fix
      await wallet.put(
          'receivingAddressesP2PKH', ["some address", "some other address"]);
      await wallet
          .put('changeAddressesP2PKH', ["some address", "some other address"]);

      await wallet.put('receivingIndexP2PKH', 123);
      await wallet.put('changeIndexP2PKH', 123);
      await secureStore?.write(
          key: "${testWalletId}_receiveDerivationsP2PKH", value: "{}");
      await secureStore?.write(
          key: "${testWalletId}_changeDerivationsP2PKH", value: "{}");

      bool hasThrown = false;
      try {
        await bch?.fullRescan(2, 1000);
      } catch (_) {
        hasThrown = true;
      }
      expect(hasThrown, false);

      // fetch wallet data again
      final receivingAddressesP2PKH =
          await wallet.get('receivingAddressesP2PKH');
      final changeAddressesP2PKH = await wallet.get('changeAddressesP2PKH');
      final receivingIndexP2PKH = await wallet.get('receivingIndexP2PKH');
      final changeIndexP2PKH = await wallet.get('changeIndexP2PKH');
      final utxoData = await wallet.get('latest_utxo_model');
      final receiveDerivationsStringP2PKH = await secureStore?.read(
          key: "${testWalletId}_receiveDerivationsP2PKH");
      final changeDerivationsStringP2PKH = await secureStore?.read(
          key: "${testWalletId}_changeDerivationsP2PKH");

      expect(preReceivingAddressesP2PKH, receivingAddressesP2PKH);
      expect(preChangeAddressesP2PKH, changeAddressesP2PKH);
      expect(preReceivingIndexP2PKH, receivingIndexP2PKH);
      expect(preChangeIndexP2PKH, changeIndexP2PKH);
      expect(preUtxoData, utxoData);
      expect(preReceiveDerivationsStringP2PKH, receiveDerivationsStringP2PKH);
      expect(preChangeDerivationsStringP2PKH, changeDerivationsStringP2PKH);

      verify(client?.getServerFeatures()).called(1);
      verify(client?.getBatchHistory(args: historyBatchArgs0)).called(2);
      // verify(client?.getBatchHistory(args: historyBatchArgs1)).called(2);
      verify(cachedClient?.clearSharedTransactionCache(coin: Coin.bitcoincash))
          .called(1);

      expect(secureStore?.writes, 9);
      expect(secureStore?.reads, 12);
      expect(secureStore?.deletes, 2);

      verifyNoMoreInteractions(client);
      verifyNoMoreInteractions(cachedClient);
      verifyNoMoreInteractions(tracker);
      verifyNoMoreInteractions(priceAPI);
    });

    test("fullRescan fails", () async {
      when(client?.getServerFeatures()).thenAnswer((_) async => {
            "hosts": {},
            "pruning": null,
            "server_version": "Unit tests",
            "protocol_min": "1.4",
            "protocol_max": "1.4.2",
            "genesis_hash": GENESIS_HASH_MAINNET,
            "hash_function": "sha256",
            "services": []
          });

      when(client?.getBatchHistory(args: historyBatchArgs0))
          .thenAnswer((_) async => historyBatchResponse);
      // when(client?.getBatchHistory(args: historyBatchArgs1))
      //     .thenAnswer((_) async => historyBatchResponse);
      when(cachedClient?.clearSharedTransactionCache(coin: Coin.bitcoincash))
          .thenAnswer((realInvocation) async {});

      final wallet = await Hive.openBox(testWalletId);

      // restore so we have something to rescan
      await bch?.recoverFromMnemonic(
          mnemonic: TEST_MNEMONIC,
          maxUnusedAddressGap: 2,
          maxNumberOfIndexesToCheck: 1000,
          height: 4000);

      // fetch wallet data
      final preReceivingAddressesP2PKH =
          await wallet.get('receivingAddressesP2PKH');

      final preChangeAddressesP2PKH = await wallet.get('changeAddressesP2PKH');
      final preReceivingIndexP2PKH = await wallet.get('receivingIndexP2PKH');
      final preChangeIndexP2PKH = await wallet.get('changeIndexP2PKH');
      final preUtxoData = await wallet.get('latest_utxo_model');
      final preReceiveDerivationsStringP2PKH = await secureStore?.read(
          key: "${testWalletId}_receiveDerivationsP2PKH");
      final preChangeDerivationsStringP2PKH = await secureStore?.read(
          key: "${testWalletId}_changeDerivationsP2PKH");

      when(client?.getBatchHistory(args: historyBatchArgs0))
          .thenThrow(Exception("fake exception"));

      bool hasThrown = false;
      try {
        await bch?.fullRescan(2, 1000);
      } catch (_) {
        hasThrown = true;
      }
      expect(hasThrown, true);

      // fetch wallet data again
      final receivingAddressesP2PKH =
          await wallet.get('receivingAddressesP2PKH');

      final changeAddressesP2PKH = await wallet.get('changeAddressesP2PKH');
      final receivingIndexP2PKH = await wallet.get('receivingIndexP2PKH');
      final changeIndexP2PKH = await wallet.get('changeIndexP2PKH');
      final utxoData = await wallet.get('latest_utxo_model');
      final receiveDerivationsStringP2PKH = await secureStore?.read(
          key: "${testWalletId}_receiveDerivationsP2PKH");
      final changeDerivationsStringP2PKH = await secureStore?.read(
          key: "${testWalletId}_changeDerivationsP2PKH");

      expect(preReceivingAddressesP2PKH, receivingAddressesP2PKH);
      expect(preChangeAddressesP2PKH, changeAddressesP2PKH);
      expect(preReceivingIndexP2PKH, receivingIndexP2PKH);
      expect(preChangeIndexP2PKH, changeIndexP2PKH);
      expect(preUtxoData, utxoData);
      expect(preReceiveDerivationsStringP2PKH, receiveDerivationsStringP2PKH);
      expect(preChangeDerivationsStringP2PKH, changeDerivationsStringP2PKH);

      verify(client?.getServerFeatures()).called(1);
      verify(client?.getBatchHistory(args: historyBatchArgs0)).called(2);
      // verify(client?.getBatchHistory(args: historyBatchArgs1)).called(1);
      verify(cachedClient?.clearSharedTransactionCache(coin: Coin.bitcoincash))
          .called(1);

      expect(secureStore?.writes, 7);
      expect(secureStore?.reads, 12);
      expect(secureStore?.deletes, 4);

      verifyNoMoreInteractions(client);
      verifyNoMoreInteractions(cachedClient);
      verifyNoMoreInteractions(tracker);
      verifyNoMoreInteractions(priceAPI);
    });

    // // test("fetchBuildTxData succeeds", () async {
    // //   when(client.getServerFeatures()).thenAnswer((_) async => {
    // //         "hosts": {},
    // //         "pruning": null,
    // //         "server_version": "Unit tests",
    // //         "protocol_min": "1.4",
    // //         "protocol_max": "1.4.2",
    // //         "genesis_hash": GENESIS_HASH_MAINNET,
    // //         "hash_function": "sha256",
    // //         "services": []
    // //       });
    // //   when(client.getBatchHistory(args: historyBatchArgs0))
    // //       .thenAnswer((_) async => historyBatchResponse);
    // //   when(client.getBatchHistory(args: historyBatchArgs1))
    // //       .thenAnswer((_) async => historyBatchResponse);
    // //   when(cachedClient.getTransaction(
    // //           tx_hash:
    // //               "339dac760e4c9c81ed30a7fde7062785cb20712b18e108accdc39800f884fda9",
    // //           coinName: "bitcoincash",
    // //           callOutSideMainIsolate: false))
    // //       .thenAnswer((_) async => tx9Raw);
    // //   when(cachedClient.getTransaction(
    // //           tx_hash:
    // //               "c2edf283df75cc2724320b866857a82d80266a59d69ab5a7ca12033adbffa44e",
    // //           coinName: "bitcoincash",
    // //           callOutSideMainIsolate: false))
    // //       .thenAnswer((_) async => tx10Raw);
    // //   when(cachedClient.getTransaction(
    // //           tx_hash:
    // //               "d0c451513bee7d96cb88824d9d720e6b5b90073721b4985b439687f894c3989c",
    // //           coinName: "bitcoincash",
    // //           callOutSideMainIsolate: false))
    // //       .thenAnswer((_) async => tx11Raw);
    // //
    // //   // recover to fill data
    // //   await bch.recoverFromMnemonic(
    // //       mnemonic: TEST_MNEMONIC,
    // //       maxUnusedAddressGap: 2,
    // //       maxNumberOfIndexesToCheck: 1000,
    // //       height: 4000);
    // //
    // //   // modify addresses to trigger all change code branches
    // //   final chg44 =
    // //       await secureStore.read(key: testWalletId + "_changeDerivationsP2PKH");
    // //   await secureStore.write(
    // //       key: testWalletId + "_changeDerivationsP2PKH",
    // //       value: chg44.replaceFirst("1vFHF5q21GccoBwrB4zEUAs9i3Bfx797U",
    // //           "D5cQWPnhM3RRJVDz8wWC5jWt3PRCfg1zA6"));
    // //
    // //   final data = await bch.fetchBuildTxData(utxoList);
    // //
    // //   expect(data.length, 3);
    // //   expect(
    // //       data["339dac760e4c9c81ed30a7fde7062785cb20712b18e108accdc39800f884fda9"]
    // //           .length,
    // //       2);
    // //   expect(
    // //       data["c2edf283df75cc2724320b866857a82d80266a59d69ab5a7ca12033adbffa44e"]
    // //           .length,
    // //       3);
    // //   expect(
    // //       data["d0c451513bee7d96cb88824d9d720e6b5b90073721b4985b439687f894c3989c"]
    // //           .length,
    // //       2);
    // //   expect(
    // //       data["339dac760e4c9c81ed30a7fde7062785cb20712b18e108accdc39800f884fda9"]
    // //           ["output"],
    // //       isA<Uint8List>());
    // //   expect(
    // //       data["c2edf283df75cc2724320b866857a82d80266a59d69ab5a7ca12033adbffa44e"]
    // //           ["output"],
    // //       isA<Uint8List>());
    // //   expect(
    // //       data["d0c451513bee7d96cb88824d9d720e6b5b90073721b4985b439687f894c3989c"]
    // //           ["output"],
    // //       isA<Uint8List>());
    // //   expect(
    // //       data["339dac760e4c9c81ed30a7fde7062785cb20712b18e108accdc39800f884fda9"]
    // //           ["keyPair"],
    // //       isA<ECPair>());
    // //   expect(
    // //       data["c2edf283df75cc2724320b866857a82d80266a59d69ab5a7ca12033adbffa44e"]
    // //           ["keyPair"],
    // //       isA<ECPair>());
    // //   expect(
    // //       data["d0c451513bee7d96cb88824d9d720e6b5b90073721b4985b439687f894c3989c"]
    // //           ["keyPair"],
    // //       isA<ECPair>());
    // //   expect(
    // //       data["c2edf283df75cc2724320b866857a82d80266a59d69ab5a7ca12033adbffa44e"]
    // //           ["redeemScript"],
    // //       isA<Uint8List>());
    // //
    // //   // modify addresses to trigger all receiving code branches
    // //   final rcv44 = await secureStore.read(
    // //       key: testWalletId + "_receiveDerivationsP2PKH");
    // //   await secureStore.write(
    // //       key: testWalletId + "_receiveDerivationsP2PKH",
    // //       value: rcv44.replaceFirst("1RMSPixoLPuaXuhR2v4HsUMcRjLncKDaw",
    // //           "D5cQWPnhM3RRJVDz8wWC5jWt3PRCfg1zA6"));
    // //
    // //   final data2 = await bch.fetchBuildTxData(utxoList);
    // //
    // //   expect(data2.length, 3);
    // //   expect(
    // //       data2["339dac760e4c9c81ed30a7fde7062785cb20712b18e108accdc39800f884fda9"]
    // //           .length,
    // //       2);
    // //   expect(
    // //       data2["c2edf283df75cc2724320b866857a82d80266a59d69ab5a7ca12033adbffa44e"]
    // //           .length,
    // //       3);
    // //   expect(
    // //       data2["d0c451513bee7d96cb88824d9d720e6b5b90073721b4985b439687f894c3989c"]
    // //           .length,
    // //       2);
    // //   expect(
    // //       data2["339dac760e4c9c81ed30a7fde7062785cb20712b18e108accdc39800f884fda9"]
    // //           ["output"],
    // //       isA<Uint8List>());
    // //   expect(
    // //       data2["c2edf283df75cc2724320b866857a82d80266a59d69ab5a7ca12033adbffa44e"]
    // //           ["output"],
    // //       isA<Uint8List>());
    // //   expect(
    // //       data2["d0c451513bee7d96cb88824d9d720e6b5b90073721b4985b439687f894c3989c"]
    // //           ["output"],
    // //       isA<Uint8List>());
    // //   expect(
    // //       data2["339dac760e4c9c81ed30a7fde7062785cb20712b18e108accdc39800f884fda9"]
    // //           ["keyPair"],
    // //       isA<ECPair>());
    // //   expect(
    // //       data2["c2edf283df75cc2724320b866857a82d80266a59d69ab5a7ca12033adbffa44e"]
    // //           ["keyPair"],
    // //       isA<ECPair>());
    // //   expect(
    // //       data2["d0c451513bee7d96cb88824d9d720e6b5b90073721b4985b439687f894c3989c"]
    // //           ["keyPair"],
    // //       isA<ECPair>());
    // //   expect(
    // //       data2["c2edf283df75cc2724320b866857a82d80266a59d69ab5a7ca12033adbffa44e"]
    // //           ["redeemScript"],
    // //       isA<Uint8List>());
    // //
    // //   verify(client.getServerFeatures()).called(1);
    // //   verify(cachedClient.getTransaction(
    // //           tx_hash:
    // //               "339dac760e4c9c81ed30a7fde7062785cb20712b18e108accdc39800f884fda9",
    // //           coinName: "bitcoincash",
    // //           callOutSideMainIsolate: false))
    // //       .called(2);
    // //   verify(cachedClient.getTransaction(
    // //           tx_hash:
    // //               "c2edf283df75cc2724320b866857a82d80266a59d69ab5a7ca12033adbffa44e",
    // //           coinName: "bitcoincash",
    // //           callOutSideMainIsolate: false))
    // //       .called(2);
    // //   verify(cachedClient.getTransaction(
    // //           tx_hash:
    // //               "d0c451513bee7d96cb88824d9d720e6b5b90073721b4985b439687f894c3989c",
    // //           coinName: "bitcoincash",
    // //           callOutSideMainIsolate: false))
    // //       .called(2);
    // //   verify(client.getBatchHistory(args: historyBatchArgs0)).called(1);
    // //   verify(client.getBatchHistory(args: historyBatchArgs1)).called(1);
    // //
    // //   expect(secureStore.interactions, 38);
    // //   expect(secureStore.writes, 13);
    // //   expect(secureStore.reads, 25);
    // //   expect(secureStore.deletes, 0);
    // //
    // //   verifyNoMoreInteractions(client);
    // //   verifyNoMoreInteractions(cachedClient);
    // //   verifyNoMoreInteractions(priceAPI);
    // // });

    // test("fetchBuildTxData throws", () async {
    //   when(client?.getServerFeatures()).thenAnswer((_) async => {
    //         "hosts": {},
    //         "pruning": null,
    //         "server_version": "Unit tests",
    //         "protocol_min": "1.4",
    //         "protocol_max": "1.4.2",
    //         "genesis_hash": GENESIS_HASH_MAINNET,
    //         "hash_function": "sha256",
    //         "services": []
    //       });
    //   when(client?.getBatchHistory(args: historyBatchArgs0))
    //       .thenAnswer((_) async => historyBatchResponse);
    //   when(client?.getBatchHistory(args: historyBatchArgs1))
    //       .thenAnswer((_) async => historyBatchResponse);
    //   when(cachedClient?.getTransaction(
    //           txHash:
    //               "2087ce09bc316877c9f10971526a2bffa3078d52ea31752639305cdcd8230703",
    //           coin: Coin.bitcoincash,
    //           callOutSideMainIsolate: false))
    //       .thenAnswer((_) async => tx9Raw);
    //   when(cachedClient?.getTransaction(
    //           txHash:
    //               "ed32c967a0e86d51669ac21c2bb9bc9c50f0f55fbacdd8db21d0a986fba93bd7",
    //           coin: Coin.bitcoincash,
    //           callOutSideMainIsolate: false))
    //       .thenAnswer((_) async => tx10Raw);
    //   when(cachedClient?.getTransaction(
    //           txHash:
    //               "3f0032f89ac44b281b50314cff3874c969c922839dddab77ced54e86a21c3fd4",
    //           coin: Coin.bitcoincash,
    //           callOutSideMainIsolate: false))
    //       .thenThrow(Exception("some exception"));
    //
    //   // recover to fill data
    //   await bch?.recoverFromMnemonic(
    //       mnemonic: TEST_MNEMONIC,
    //       maxUnusedAddressGap: 2,
    //       maxNumberOfIndexesToCheck: 1000,
    //       height: 4000);
    //
    //   bool didThrow = false;
    //   try {
    //     await bch?.fetchBuildTxData(utxoList);
    //   } catch (_) {
    //     didThrow = true;
    //   }
    //   expect(didThrow, true);
    //
    //   verify(client?.getServerFeatures()).called(1);
    //   verify(cachedClient?.getTransaction(
    //           txHash:
    //               "2087ce09bc316877c9f10971526a2bffa3078d52ea31752639305cdcd8230703",
    //           coin: Coin.bitcoincash,
    //           callOutSideMainIsolate: false))
    //       .called(1);
    //   verify(cachedClient?.getTransaction(
    //           txHash:
    //               "ed32c967a0e86d51669ac21c2bb9bc9c50f0f55fbacdd8db21d0a986fba93bd7",
    //           coin: Coin.bitcoincash,
    //           callOutSideMainIsolate: false))
    //       .called(1);
    //   verify(cachedClient?.getTransaction(
    //           txHash:
    //               "3f0032f89ac44b281b50314cff3874c969c922839dddab77ced54e86a21c3fd4",
    //           coin: Coin.bitcoincash,
    //           callOutSideMainIsolate: false))
    //       .called(1);
    //   verify(client?.getBatchHistory(args: historyBatchArgs0)).called(1);
    //   verify(client?.getBatchHistory(args: historyBatchArgs1)).called(1);
    //
    //   expect(secureStore?.interactions, 14);
    //   expect(secureStore?.writes, 7);
    //   expect(secureStore?.reads, 7);
    //   expect(secureStore?.deletes, 0);
    //
    //   verifyNoMoreInteractions(client);
    //   verifyNoMoreInteractions(cachedClient);
    //   verifyNoMoreInteractions(priceAPI);
    // });

    // test("build transaction succeeds", () async {
    //   when(client?.getServerFeatures()).thenAnswer((_) async => {
    //         "hosts": {},
    //         "pruning": null,
    //         "server_version": "Unit tests",
    //         "protocol_min": "1.4",
    //         "protocol_max": "1.4.2",
    //         "genesis_hash": GENESIS_HASH_MAINNET,
    //         "hash_function": "sha256",
    //         "services": []
    //       });
    //   when(client?.getBatchHistory(args: historyBatchArgs0))
    //       .thenAnswer((_) async => historyBatchResponse);
    //   when(client?.getBatchHistory(args: historyBatchArgs1))
    //       .thenAnswer((_) async => historyBatchResponse);
    //   when(cachedClient?.getTransaction(
    //           txHash:
    //               "e9673acb3bfa928f92a7d5a545151a672e9613fdf972f3849e16094c1ed28268",
    //           coin: Coin.bitcoincash,
    //           callOutSideMainIsolate: false))
    //       .thenAnswer((_) async => tx9Raw);
    //   when(cachedClient?.getTransaction(
    //           txHash:
    //               "fa5bfa4eb581bedb28ca96a65ee77d8e81159914b70d5b7e215994221cc02a63",
    //           coin: Coin.bitcoincash,
    //           callOutSideMainIsolate: false))
    //       .thenAnswer((_) async => tx10Raw);
    //   when(cachedClient?.getTransaction(
    //           txHash:
    //               "694617f0000499be2f6af5f8d1ddbcf1a70ad4710c0cee6f33a13a64bba454ed",
    //           coin: Coin.bitcoincash,
    //           callOutSideMainIsolate: false))
    //       .thenAnswer((_) async => tx11Raw);
    //
    //   // recover to fill data
    //   await bch?.recoverFromMnemonic(
    //       mnemonic: TEST_MNEMONIC,
    //       maxUnusedAddressGap: 2,
    //       maxNumberOfIndexesToCheck: 1000,
    //       height: 4000);
    //
    //   // modify addresses to properly mock data to build a tx
    //   final rcv44 = await secureStore?.read(
    //       key: testWalletId + "_receiveDerivationsP2PKH");
    //   await secureStore?.write(
    //       key: testWalletId + "_receiveDerivationsP2PKH",
    //       value: rcv44?.replaceFirst("1RMSPixoLPuaXuhR2v4HsUMcRjLncKDaw",
    //           "D5cQWPnhM3RRJVDz8wWC5jWt3PRCfg1zA6"));
    //
    //   final data = await bch?.fetchBuildTxData(utxoList);
    //
    //   final txData = await bch?.buildTransaction(
    //       utxosToUse: utxoList,
    //       utxoSigningData: data!,
    //       recipients: ["DS7cKFKdfbarMrYjFBQqEcHR5km6D51c74"],
    //       satoshiAmounts: [13000]);
    //
    //   expect(txData?.length, 2);
    //   expect(txData?["hex"], isA<String>());
    //   expect(txData?["vSize"], isA<int>());
    //
    //   verify(client?.getServerFeatures()).called(1);
    //   verify(cachedClient?.getTransaction(
    //           txHash:
    //               "d3054c63fe8cfafcbf67064ec66b9fbe1ac293860b5d6ffaddd39546658b72de",
    //           coin: Coin.bitcoincash,
    //           callOutSideMainIsolate: false))
    //       .called(1);
    //   verify(cachedClient?.getTransaction(
    //           txHash:
    //               "fa5bfa4eb581bedb28ca96a65ee77d8e81159914b70d5b7e215994221cc02a63",
    //           coin: Coin.bitcoincash,
    //           callOutSideMainIsolate: false))
    //       .called(1);
    //   verify(cachedClient?.getTransaction(
    //           txHash:
    //               "694617f0000499be2f6af5f8d1ddbcf1a70ad4710c0cee6f33a13a64bba454ed",
    //           coin: Coin.bitcoincash,
    //           callOutSideMainIsolate: false))
    //       .called(1);
    //   verify(client?.getBatchHistory(args: historyBatchArgs0)).called(1);
    //   verify(client?.getBatchHistory(args: historyBatchArgs1)).called(1);
    //
    //   expect(secureStore?.interactions, 26);
    //   expect(secureStore?.writes, 10);
    //   expect(secureStore?.reads, 16);
    //   expect(secureStore?.deletes, 0);
    //
    //   verifyNoMoreInteractions(client);
    //   verifyNoMoreInteractions(cachedClient);
    //   verifyNoMoreInteractions(priceAPI);
    // });

    test("confirmSend error 1", () async {
      bool didThrow = false;
      try {
        await bch?.confirmSend(txData: 1);
      } catch (_) {
        didThrow = true;
      }

      expect(didThrow, true);

      expect(secureStore?.interactions, 0);
      verifyNoMoreInteractions(client);
      verifyNoMoreInteractions(cachedClient);
      verifyNoMoreInteractions(tracker);
      verifyNoMoreInteractions(priceAPI);
    });

    test("confirmSend error 2", () async {
      bool didThrow = false;
      try {
        await bch?.confirmSend(txData: 2);
      } catch (_) {
        didThrow = true;
      }

      expect(didThrow, true);

      expect(secureStore?.interactions, 0);
      verifyNoMoreInteractions(client);
      verifyNoMoreInteractions(cachedClient);
      verifyNoMoreInteractions(tracker);
      verifyNoMoreInteractions(priceAPI);
    });

    test("confirmSend some other error code", () async {
      bool didThrow = false;
      try {
        await bch?.confirmSend(txData: 42);
      } catch (_) {
        didThrow = true;
      }

      expect(didThrow, true);

      expect(secureStore?.interactions, 0);
      verifyNoMoreInteractions(client);
      verifyNoMoreInteractions(cachedClient);
      verifyNoMoreInteractions(tracker);
      verifyNoMoreInteractions(priceAPI);
    });

    test("confirmSend no hex", () async {
      bool didThrow = false;
      try {
        await bch?.confirmSend(txData: {"some": "strange map"});
      } catch (_) {
        didThrow = true;
      }

      expect(didThrow, true);

      expect(secureStore?.interactions, 0);
      verifyNoMoreInteractions(client);
      verifyNoMoreInteractions(cachedClient);
      verifyNoMoreInteractions(tracker);
      verifyNoMoreInteractions(priceAPI);
    });

    test("confirmSend fails due to vSize being greater than fee", () async {
      bool didThrow = false;
      try {
        await bch
            ?.confirmSend(txData: {"hex": "a string", "fee": 1, "vSize": 10});
      } catch (_) {
        didThrow = true;
      }

      expect(didThrow, true);

      verify(client?.broadcastTransaction(
              rawTx: "a string", requestID: anyNamed("requestID")))
          .called(1);

      expect(secureStore?.interactions, 0);
      verifyNoMoreInteractions(client);
      verifyNoMoreInteractions(cachedClient);
      verifyNoMoreInteractions(tracker);
      verifyNoMoreInteractions(priceAPI);
    });

    test("confirmSend fails when broadcast transactions throws", () async {
      when(client?.broadcastTransaction(
              rawTx: "a string", requestID: anyNamed("requestID")))
          .thenThrow(Exception("some exception"));

      bool didThrow = false;
      try {
        await bch
            ?.confirmSend(txData: {"hex": "a string", "fee": 10, "vSize": 10});
      } catch (_) {
        didThrow = true;
      }

      expect(didThrow, true);

      verify(client?.broadcastTransaction(
              rawTx: "a string", requestID: anyNamed("requestID")))
          .called(1);

      expect(secureStore?.interactions, 0);
      verifyNoMoreInteractions(client);
      verifyNoMoreInteractions(cachedClient);
      verifyNoMoreInteractions(tracker);
      verifyNoMoreInteractions(priceAPI);
    });

    test("refresh wallet mutex locked", () async {
      when(client?.getServerFeatures()).thenAnswer((_) async => {
            "hosts": {},
            "pruning": null,
            "server_version": "Unit tests",
            "protocol_min": "1.4",
            "protocol_max": "1.4.2",
            "genesis_hash": GENESIS_HASH_MAINNET,
            "hash_function": "sha256",
            "services": []
          });
      when(client?.getBatchHistory(args: historyBatchArgs0))
          .thenAnswer((_) async => historyBatchResponse);
      // when(client?.getBatchHistory(args: historyBatchArgs1))
      //     .thenAnswer((_) async => historyBatchResponse);

      final wallet = await Hive.openBox(testWalletId);

      // recover to fill data
      await bch?.recoverFromMnemonic(
          mnemonic: TEST_MNEMONIC,
          maxUnusedAddressGap: 2,
          maxNumberOfIndexesToCheck: 1000,
          height: 4000);

      bch?.refreshMutex = true;

      await bch?.refresh();

      verify(client?.getServerFeatures()).called(1);
      verify(client?.getBatchHistory(args: historyBatchArgs0)).called(1);
      // verify(client?.getBatchHistory(args: historyBatchArgs1)).called(1);

      expect(secureStore?.interactions, 6);
      expect(secureStore?.writes, 3);
      expect(secureStore?.reads, 3);
      expect(secureStore?.deletes, 0);

      verifyNoMoreInteractions(client);
      verifyNoMoreInteractions(cachedClient);
      verifyNoMoreInteractions(tracker);
      verifyNoMoreInteractions(priceAPI);
    });

    test("refresh wallet throws", () async {
      when(client?.getBlockHeadTip()).thenThrow(Exception("some exception"));
      when(client?.getServerFeatures()).thenAnswer((_) async => {
            "hosts": {},
            "pruning": null,
            "server_version": "Unit tests",
            "protocol_min": "1.4",
            "protocol_max": "1.4.2",
            "genesis_hash": GENESIS_HASH_MAINNET,
            "hash_function": "sha256",
            "services": []
          });
      when(client?.getBatchHistory(args: historyBatchArgs0))
          .thenAnswer((_) async => historyBatchResponse);
      // when(client?.getBatchHistory(args: historyBatchArgs1))
      //     .thenAnswer((_) async => historyBatchResponse);
      when(client?.getHistory(scripthash: anyNamed("scripthash")))
          .thenThrow(Exception("some exception"));

      final wallet = await Hive.openBox(testWalletId);

      // recover to fill data
      await bch?.recoverFromMnemonic(
          mnemonic: TEST_MNEMONIC,
          maxUnusedAddressGap: 2,
          maxNumberOfIndexesToCheck: 1000,
          height: 4000);

      await bch?.refresh();

      verify(client?.getServerFeatures()).called(1);
      verify(client?.getBatchHistory(args: historyBatchArgs0)).called(1);
      // verify(client?.getBatchHistory(args: historyBatchArgs1)).called(1);
      verify(client?.getBlockHeadTip()).called(1);
      verify(client?.getHistory(scripthash: anyNamed("scripthash"))).called(1);

      expect(secureStore?.interactions, 6);
      expect(secureStore?.writes, 3);
      expect(secureStore?.reads, 3);
      expect(secureStore?.deletes, 0);

      verifyNoMoreInteractions(client);
      verifyNoMoreInteractions(cachedClient);
      verifyNoMoreInteractions(tracker);
      verifyNoMoreInteractions(priceAPI);
    });

    // test("refresh wallet normally", () async {
    //   when(client?.getBlockHeadTip()).thenAnswer((realInvocation) async =>
    //       {"height": 520481, "hex": "some block hex"});
    //   when(client?.getServerFeatures()).thenAnswer((_) async => {
    //         "hosts": {},
    //         "pruning": null,
    //         "server_version": "Unit tests",
    //         "protocol_min": "1.4",
    //         "protocol_max": "1.4.2",
    //         "genesis_hash": GENESIS_HASH_MAINNET,
    //         "hash_function": "sha256",
    //         "services": []
    //       });
    //   when(client?.getBatchHistory(args: historyBatchArgs0))
    //       .thenAnswer((_) async => historyBatchResponse);
    //   when(client?.getBatchHistory(args: historyBatchArgs1))
    //       .thenAnswer((_) async => historyBatchResponse);
    //   when(client?.getHistory(scripthash: anyNamed("scripthash")))
    //       .thenAnswer((_) async => []);
    //   when(client?.estimateFee(blocks: anyNamed("blocks")))
    //       .thenAnswer((_) async => Decimal.one);
    //   // when(priceAPI?.getPricesAnd24hChange(baseCurrency: "USD"))
    //   //     .thenAnswer((_) async => Decimal.one);
    //
    //   await Hive.openBox<dynamic>(testWalletId);
    //   await Hive.openBox<dynamic>(DB.boxNamePrefs);
    //
    //   // recover to fill data
    //   await bch?.recoverFromMnemonic(
    //       mnemonic: TEST_MNEMONIC,
    //       maxUnusedAddressGap: 2,
    //       maxNumberOfIndexesToCheck: 1000,
    //       height: 4000);
    //
    //   when(client?.getBatchHistory(args: anyNamed("args")))
    //       .thenAnswer((_) async => {});
    //   when(client?.getBatchUTXOs(args: anyNamed("args")))
    //       .thenAnswer((_) async => emptyHistoryBatchResponse);
    //
    //   await bch?.refresh();
    //
    //   verify(client?.getServerFeatures()).called(1);
    //   verify(client?.getBatchHistory(args: historyBatchArgs0)).called(1);
    //   verify(client?.getBatchHistory(args: historyBatchArgs1)).called(1);
    //   verify(client?.getBatchHistory(args: anyNamed("args"))).called(1);
    //   verify(client?.getBatchUTXOs(args: anyNamed("args"))).called(1);
    //   verify(client?.getHistory(scripthash: anyNamed("scripthash"))).called(2);
    //   verify(client?.estimateFee(blocks: anyNamed("blocks"))).called(3);
    //   verify(client?.getBlockHeadTip()).called(1);
    //   // verify(priceAPI?.getPricesAnd24hChange(baseCurrency: "USD")).called(2);
    //
    //   expect(secureStore?.interactions, 6);
    //   expect(secureStore?.writes, 2);
    //   expect(secureStore?.reads, 2);
    //   expect(secureStore?.deletes, 0);
    //
    //   verifyNoMoreInteractions(client);
    //   verifyNoMoreInteractions(cachedClient);
    //   verifyNoMoreInteractions(priceAPI);
    // });
  });

  tearDown(() async {
    await tearDownTestHive();
  });
}

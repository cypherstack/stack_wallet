import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:hive_test/hive_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:stackwallet/electrumx_rpc/cached_electrumx.dart';
import 'package:stackwallet/electrumx_rpc/electrumx.dart';
import 'package:stackwallet/models/models.dart';
import 'package:stackwallet/services/coins/particl/particl_wallet.dart';
import 'package:stackwallet/services/price.dart';
import 'package:stackwallet/services/transaction_notification_tracker.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/utilities/flutter_secure_storage_interface.dart';
import 'package:tuple/tuple.dart';

import 'particl_history_sample_data.dart';
import 'particl_wallet_test.mocks.dart';
import 'particl_wallet_test_parameters.dart';

@GenerateMocks(
    [ElectrumX, CachedElectrumX, PriceAPI, TransactionNotificationTracker])
void main() {
  group("particl constants", () {
    test("particl minimum confirmations", () async {
      expect(MINIMUM_CONFIRMATIONS,
          1); // TODO confirm particl minimum confirmations
    });
    test("particl dust limit", () async {
      expect(DUST_LIMIT, 294); // TODO confirm particl dust limit
    });
    test("particl mainnet genesis block hash", () async {
      expect(GENESIS_HASH_MAINNET,
          "0000ee0784c195317ac95623e22fddb8c7b8825dc3998e0bb924d66866eccf4c");
    });
    test("particl testnet genesis block hash", () async {
      expect(GENESIS_HASH_TESTNET,
          "0000594ada5310b367443ee0afd4fa3d0bbd5850ea4e33cdc7d6a904a7ec7c90");
    });
  });

  test("particl DerivePathType enum", () {
    expect(DerivePathType.values.length, 2);
    expect(DerivePathType.values.toString(),
        "[DerivePathType.bip44, DerivePathType.bip84]");
  });

  group("bip32 node/root", () {
    test("getBip32Root", () {
      final root = getBip32Root(TEST_MNEMONIC, particl);
      expect(root.toWIF(), ROOT_WIF);
    });

    // test("getBip32NodeFromRoot", () {
    //   final root = getBip32Root(TEST_MNEMONIC, particl);
    //   // two mainnet
    //   final node44 = getBip32NodeFromRoot(0, 0, root, DerivePathType.bip44);
    //   expect(node44.toWIF(), NODE_WIF_44);
    //   final node49 = getBip32NodeFromRoot(0, 0, root, DerivePathType.bip49);
    //   expect(node49.toWIF(), NODE_WIF_49);
    //   // and one on testnet
    //   final node84 = getBip32NodeFromRoot(
    //       0, 0, getBip32Root(TEST_MNEMONIC, testnet), DerivePathType.bip84);
    //   expect(node84.toWIF(), NODE_WIF_84);
    //   // a bad derive path
    //   bool didThrow = false;
    //   try {
    //     getBip32NodeFromRoot(0, 0, root, null);
    //   } catch (_) {
    //     didThrow = true;
    //   }
    //   expect(didThrow, true);
    //   // finally an invalid network
    //   didThrow = false;
    //   final invalidNetwork = NetworkType(
    //       messagePrefix: '\x18hello world\n',
    //       bech32: 'gg',
    //       bip32: Bip32Type(public: 0x055521e, private: 0x055555),
    //       pubKeyHash: 0x55,
    //       scriptHash: 0x55,
    //       wif: 0x00);
    //   try {
    //     getBip32NodeFromRoot(0, 0, getBip32Root(TEST_MNEMONIC, invalidNetwork),
    //         DerivePathType.bip44);
    //   } catch (_) {
    //     didThrow = true;
    //   }
    //   expect(didThrow, true);
    // });

    // test("basic getBip32Node", () {
    //   final node =
    //       getBip32Node(0, 0, TEST_MNEMONIC, testnet, DerivePathType.bip84);
    //   expect(node.toWIF(), NODE_WIF_84);
    // });
  });

  group("validate mainnet particl addresses", () {
    MockElectrumX? client;
    MockCachedElectrumX? cachedClient;
    MockPriceAPI? priceAPI;
    late FakeSecureStorage secureStore;
    MockTransactionNotificationTracker? tracker;

    ParticlWallet?
        mainnetWallet; // TODO reimplement testnet, see 9baa30c1a40b422bb5f4746efc1220b52691ace6 and sneurlax/stack_wallet#ec399ade0aef1d9ab2dd78876a2d20819dae4ba0

    setUp(() {
      client = MockElectrumX();
      cachedClient = MockCachedElectrumX();
      priceAPI = MockPriceAPI();
      secureStore = FakeSecureStorage();
      tracker = MockTransactionNotificationTracker();

      mainnetWallet = ParticlWallet(
        walletId: "validateAddressMainNet",
        walletName: "validateAddressMainNet",
        coin: Coin.particl,
        client: client!,
        cachedClient: cachedClient!,
        tracker: tracker!,
        priceAPI: priceAPI,
        secureStore: secureStore,
      );
    });

    test("valid mainnet particl legacy/p2pkh address", () {
      expect(
          mainnetWallet?.validateAddress("Pi9W46PhXkNRusar2KVMbXftYpGzEYGcSa"),
          true);
      expect(secureStore.interactions, 0);
      verifyNoMoreInteractions(client);
      verifyNoMoreInteractions(cachedClient);
      verifyNoMoreInteractions(priceAPI);
    });

    test("valid mainnet particl legacy/p2pkh address type", () {
      expect(
          mainnetWallet?.addressType(
              address: "Pi9W46PhXkNRusar2KVMbXftYpGzEYGcSa"),
          DerivePathType.bip44);
      expect(secureStore.interactions, 0);
      verifyNoMoreInteractions(client);
      verifyNoMoreInteractions(cachedClient);
      verifyNoMoreInteractions(tracker);
      verifyNoMoreInteractions(priceAPI);
    });

    test("valid mainnet particl p2wpkh address", () {
      expect(
          mainnetWallet
              ?.validateAddress("pw1qj6t0kvsmx8qd95pdh4rwxaz5qp5qtfz0xq2rja"),
          true);
      expect(
          mainnetWallet
              ?.validateAddress("bc1qc5ymmsay89r6gr4fy2kklvrkuvzyln4shdvjhf"),
          false);
      expect(secureStore.interactions, 0);
      verifyNoMoreInteractions(client);
      verifyNoMoreInteractions(cachedClient);
      verifyNoMoreInteractions(priceAPI);
    });

    test("valid mainnet particl legacy/p2pkh address", () {
      expect(
          mainnetWallet?.validateAddress("PputQYxNxMiYh3sg7vSh25wg3XxHiPHag7"),
          true);
      expect(secureStore.interactions, 0);
      verifyNoMoreInteractions(client);
      verifyNoMoreInteractions(cachedClient);
      verifyNoMoreInteractions(priceAPI);
    });

    test("invalid mainnet particl legacy/p2pkh address", () {
      expect(
          mainnetWallet?.validateAddress("PputQYxNxMiYh3sg7vSh25wg3XxHiP0000"),
          false);
      expect(
          mainnetWallet?.validateAddress("16YB85zQHjro7fqjR2hMcwdQWCX8jNVtr5"),
          false);
      expect(secureStore.interactions, 0);
      verifyNoMoreInteractions(client);
      verifyNoMoreInteractions(cachedClient);
      verifyNoMoreInteractions(priceAPI);
    });

    test("invalid mainnet particl p2wpkh address", () {
      expect(
          mainnetWallet
              ?.validateAddress("pw1qce3dhmmle4e0833mssj7ptta3ehydjf0tsa3ju"),
          false);
      expect(secureStore.interactions, 0);
      verifyNoMoreInteractions(client);
      verifyNoMoreInteractions(cachedClient);
      verifyNoMoreInteractions(tracker);
      verifyNoMoreInteractions(priceAPI);
    });

    // test("invalid bech32 address type", () {
    //   expect(
    //       () => mainnetWallet?.addressType(
    //           address: "tb1qzzlm6mnc8k54mx6akehl8p9ray8r439va5ndyq"),
    //       throwsArgumentError);
    //   expect(secureStore?.interactions, 0);
    //   verifyNoMoreInteractions(client);
    //   verifyNoMoreInteractions(cachedClient);
    //   verifyNoMoreInteractions(tracker);
    //   verifyNoMoreInteractions(priceAPI);
    // });

    test("address has no matching script", () {
      expect(
          () => mainnetWallet?.addressType(
              address: "mpMk94ETazqonHutyC1v6ajshgtP8oiFKU"),
          throwsArgumentError);
      expect(secureStore.interactions, 0);
      verifyNoMoreInteractions(client);
      verifyNoMoreInteractions(cachedClient);
      verifyNoMoreInteractions(tracker);
      verifyNoMoreInteractions(priceAPI);
    });
  });

  // group("testNetworkConnection", () {
  //   MockElectrumX? client;
  //   MockCachedElectrumX? cachedClient;
  //   MockPriceAPI? priceAPI;
  //   late FakeSecureStorage secureStore;
  //   MockTransactionNotificationTracker? tracker;

  //   ParticlWallet? part;

  //   setUp(() {
  //     client = MockElectrumX();
  //     cachedClient = MockCachedElectrumX();
  //     priceAPI = MockPriceAPI();
  //     secureStore = FakeSecureStorage();
  //     tracker = MockTransactionNotificationTracker();

  //     nmc = ParticlWallet(
  //       walletId: "testNetworkConnection",
  //       walletName: "testNetworkConnection",
  //       coin: Coin.particl,
  //       client: client!,
  //       cachedClient: cachedClient!,
  //       tracker: tracker!,
  //       priceAPI: priceAPI,
  //       secureStore: secureStore,
  //     );
  //   });

  //   test("attempted connection fails due to server error", () async {
  //     when(client?.ping()).thenAnswer((_) async => false);
  //     final bool? result = await nmc?.testNetworkConnection();
  //     expect(result, false);
  //     expect(secureStore.interactions, 0);
  //     verify(client?.ping()).called(1);
  //     verifyNoMoreInteractions(client);
  //     verifyNoMoreInteractions(cachedClient);
  //     verifyNoMoreInteractions(priceAPI);
  //   });

  //   test("attempted connection fails due to exception", () async {
  //     when(client?.ping()).thenThrow(Exception);
  //     final bool? result = await nmc?.testNetworkConnection();
  //     expect(result, false);
  //     expect(secureStore.interactions, 0);
  //     verify(client?.ping()).called(1);
  //     verifyNoMoreInteractions(client);
  //     verifyNoMoreInteractions(cachedClient);
  //     verifyNoMoreInteractions(priceAPI);
  //   });

  //   test("attempted connection test success", () async {
  //     when(client?.ping()).thenAnswer((_) async => true);
  //     final bool? result = await nmc?.testNetworkConnection();
  //     expect(result, true);
  //     expect(secureStore.interactions, 0);
  //     verify(client?.ping()).called(1);
  //     verifyNoMoreInteractions(client);
  //     verifyNoMoreInteractions(cachedClient);
  //     verifyNoMoreInteractions(priceAPI);
  //   });
  // });

  group("basic getters, setters, and functions", () {
    final testWalletId = "ParticltestWalletID";
    final testWalletName = "ParticlWallet";

    MockElectrumX? client;
    MockCachedElectrumX? cachedClient;
    MockPriceAPI? priceAPI;
    late FakeSecureStorage secureStore;
    MockTransactionNotificationTracker? tracker;

    ParticlWallet? part;

    setUp(() async {
      client = MockElectrumX();
      cachedClient = MockCachedElectrumX();
      priceAPI = MockPriceAPI();
      secureStore = FakeSecureStorage();
      tracker = MockTransactionNotificationTracker();

      part = ParticlWallet(
        walletId: testWalletId,
        walletName: testWalletName,
        coin: Coin.particl,
        client: client!,
        cachedClient: cachedClient!,
        tracker: tracker!,
        priceAPI: priceAPI,
        secureStore: secureStore,
      );
    });

    test("get networkType main", () async {
      expect(Coin.particl, Coin.particl);
      expect(secureStore.interactions, 0);
      verifyNoMoreInteractions(client);
      verifyNoMoreInteractions(cachedClient);
      verifyNoMoreInteractions(priceAPI);
    });

    test("get networkType test", () async {
      part = ParticlWallet(
        walletId: testWalletId,
        walletName: testWalletName,
        coin: Coin.particl,
        client: client!,
        cachedClient: cachedClient!,
        tracker: tracker!,
        priceAPI: priceAPI,
        secureStore: secureStore,
      );
      expect(Coin.particl, Coin.particl);
      expect(secureStore.interactions, 0);
      verifyNoMoreInteractions(client);
      verifyNoMoreInteractions(cachedClient);
      verifyNoMoreInteractions(priceAPI);
    });

    test("get cryptoCurrency", () async {
      expect(Coin.particl, Coin.particl);
      expect(secureStore.interactions, 0);
      verifyNoMoreInteractions(client);
      verifyNoMoreInteractions(cachedClient);
      verifyNoMoreInteractions(priceAPI);
    });

    test("get coinName", () async {
      expect(Coin.particl, Coin.particl);
      expect(secureStore.interactions, 0);
      verifyNoMoreInteractions(client);
      verifyNoMoreInteractions(cachedClient);
      verifyNoMoreInteractions(priceAPI);
    });

    test("get coinTicker", () async {
      expect(Coin.particl, Coin.particl);
      expect(secureStore.interactions, 0);
      verifyNoMoreInteractions(client);
      verifyNoMoreInteractions(cachedClient);
      verifyNoMoreInteractions(priceAPI);
    });

    test("get and set walletName", () async {
      expect(Coin.particl, Coin.particl);
      part?.walletName = "new name";
      expect(part?.walletName, "new name");
      expect(secureStore.interactions, 0);
      verifyNoMoreInteractions(client);
      verifyNoMoreInteractions(cachedClient);
      verifyNoMoreInteractions(priceAPI);
    });

    // test("estimateTxFee", () async {
    //   expect(part?.estimateTxFee(vSize: 356, feeRatePerKB: 1), 356);
    //   expect(part?.estimateTxFee(vSize: 356, feeRatePerKB: 900), 356);
    //   expect(part?.estimateTxFee(vSize: 356, feeRatePerKB: 999), 356);
    //   expect(part?.estimateTxFee(vSize: 356, feeRatePerKB: 1000), 356);
    //   expect(part?.estimateTxFee(vSize: 356, feeRatePerKB: 1001), 712);
    //   expect(part?.estimateTxFee(vSize: 356, feeRatePerKB: 1699), 712);
    //   expect(part?.estimateTxFee(vSize: 356, feeRatePerKB: 2000), 712);
    //   expect(part?.estimateTxFee(vSize: 356, feeRatePerKB: 12345), 4628);
    //   expect(secureStore.interactions, 0);
    //   verifyNoMoreInteractions(client);
    //   verifyNoMoreInteractions(cachedClient);
    //   verifyNoMoreInteractions(priceAPI);
    // });

    // test("get fees succeeds", () async {
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
    //   when(client?.estimateFee(blocks: 1))
    //       .thenAnswer((realInvocation) async => Decimal.zero);
    //   when(client?.estimateFee(blocks: 5))
    //       .thenAnswer((realInvocation) async => Decimal.one);
    //   when(client?.estimateFee(blocks: 20))
    //       .thenAnswer((realInvocation) async => Decimal.ten);
    //
    //   final fees = await part?.fees;
    //   expect(fees, isA<FeeObject>());
    //   expect(fees?.slow, 1000000000);
    //   expect(fees?.medium, 100000000);
    //   expect(fees?.fast, 0);
    //
    //   verify(client?.estimateFee(blocks: 1)).called(1);
    //   verify(client?.estimateFee(blocks: 5)).called(1);
    //   verify(client?.estimateFee(blocks: 20)).called(1);
    //   expect(secureStore.interactions, 0);
    //   verifyNoMoreInteractions(client);
    //   verifyNoMoreInteractions(cachedClient);
    //   verifyNoMoreInteractions(priceAPI);
    // });

    // test("get fees fails", () async {
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
    //   when(client?.estimateFee(blocks: 1))
    //       .thenAnswer((realInvocation) async => Decimal.zero);
    //   when(client?.estimateFee(blocks: 5))
    //       .thenAnswer((realInvocation) async => Decimal.one);
    //   when(client?.estimateFee(blocks: 20))
    //       .thenThrow(Exception("some exception"));
    //
    //   bool didThrow = false;
    //   try {
    //     await part?.fees;
    //   } catch (_) {
    //     didThrow = true;
    //   }
    //
    //   expect(didThrow, true);
    //
    //   verify(client?.estimateFee(blocks: 1)).called(1);
    //   verify(client?.estimateFee(blocks: 5)).called(1);
    //   verify(client?.estimateFee(blocks: 20)).called(1);
    //   expect(secureStore.interactions, 0);
    //   verifyNoMoreInteractions(client);
    //   verifyNoMoreInteractions(cachedClient);
    //   verifyNoMoreInteractions(priceAPI);
    // });

    // test("get maxFee", () async {
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
    //   when(client?.estimateFee(blocks: 20))
    //       .thenAnswer((realInvocation) async => Decimal.zero);
    //   when(client?.estimateFee(blocks: 5))
    //       .thenAnswer((realInvocation) async => Decimal.one);
    //   when(client?.estimateFee(blocks: 1))
    //       .thenAnswer((realInvocation) async => Decimal.ten);
    //
    //   final maxFee = await nmc?.maxFee;
    //   expect(maxFee, 1000000000);
    //
    //   verify(client?.estimateFee(blocks: 1)).called(1);
    //   verify(client?.estimateFee(blocks: 5)).called(1);
    //   verify(client?.estimateFee(blocks: 20)).called(1);
    //   expect(secureStore.interactions, 0);
    //   verifyNoMoreInteractions(client);
    //   verifyNoMoreInteractions(cachedClient);
    //   verifyNoMoreInteractions(tracker);
    //   verifyNoMoreInteractions(priceAPI);
    // });
  });

  group("Particl service class functions that depend on shared storage", () {
    const testWalletId = "ParticltestWalletID";
    const testWalletName = "ParticlWallet";

    bool hiveAdaptersRegistered = false;

    MockElectrumX? client;
    MockCachedElectrumX? cachedClient;
    MockPriceAPI? priceAPI;
    late FakeSecureStorage secureStore;
    MockTransactionNotificationTracker? tracker;

    ParticlWallet? part;

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

      part = ParticlWallet(
        walletId: testWalletId,
        walletName: testWalletName,
        coin: Coin.particl,
        client: client!,
        cachedClient: cachedClient!,
        tracker: tracker!,
        priceAPI: priceAPI,
        secureStore: secureStore,
      );
    });

    // test("initializeWallet no network", () async {
    //   when(client?.ping()).thenAnswer((_) async => false);
    //   expect(await part?.initializeNew(), false);
    //   expect(secureStore.interactions, 0);
    //   verify(client?.ping()).called(1);
    //   verifyNoMoreInteractions(client);
    //   verifyNoMoreInteractions(cachedClient);
    //   verifyNoMoreInteractions(priceAPI);
    // });

    // test("initializeWallet no network exception", () async {
    //   when(client?.ping()).thenThrow(Exception("Network connection failed"));
    //   final wallets = await Hive.openBox(testWalletId);
    //   expect(await nmc?.initializeExisting(), false);
    //   expect(secureStore.interactions, 0);
    //   verify(client?.ping()).called(1);
    //   verifyNoMoreInteractions(client);
    //   verifyNoMoreInteractions(cachedClient);
    //   verifyNoMoreInteractions(priceAPI);
    // });

    // test("initializeWallet mainnet throws bad network", () async {
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
    //   // await nmc?.initializeNew();
    //   final wallets = await Hive.openBox(testWalletId);
    //
    //   expectLater(() => nmc?.initializeExisting(), throwsA(isA<Exception>()))
    //       .then((_) {
    //     expect(secureStore.interactions, 0);
    //     // verify(client?.ping()).called(1);
    //     // verify(client?.getServerFeatures()).called(1);
    //     verifyNoMoreInteractions(client);
    //     verifyNoMoreInteractions(cachedClient);
    //     verifyNoMoreInteractions(priceAPI);
    //   });
    // });
    //
    // test("initializeWallet throws mnemonic overwrite exception", () async {
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
    //   await secureStore.write(
    //       key: "${testWalletId}_mnemonic", value: "some mnemonic");
    //
    //   final wallets = await Hive.openBox(testWalletId);
    //   expectLater(() => nmc?.initializeExisting(), throwsA(isA<Exception>()))
    //       .then((_) {
    //     expect(secureStore.interactions, 1);
    //     // verify(client?.ping()).called(1);
    //     // verify(client?.getServerFeatures()).called(1);
    //     verifyNoMoreInteractions(client);
    //     verifyNoMoreInteractions(cachedClient);
    //     verifyNoMoreInteractions(priceAPI);
    //   });
    // });
    //
    // test(
    //     "recoverFromMnemonic using empty seed on mainnet fails due to bad genesis hash match",
    //     () async {
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
    //   bool hasThrown = false;
    //   try {
    //     await nmc?.recoverFromMnemonic(
    //         mnemonic: TEST_MNEMONIC,
    //         maxUnusedAddressGap: 2,
    //         maxNumberOfIndexesToCheck: 1000,
    //         height: 4000);
    //   } catch (_) {
    //     hasThrown = true;
    //   }
    //   expect(hasThrown, true);
    //
    //   verify(client?.getServerFeatures()).called(1);
    //
    //   expect(secureStore.interactions, 0);
    //   verifyNoMoreInteractions(client);
    //   verifyNoMoreInteractions(cachedClient);
    //   verifyNoMoreInteractions(priceAPI);
    // });
    //
    // test(
    //     "recoverFromMnemonic using empty seed on mainnet fails due to attempted overwrite of mnemonic",
    //     () async {
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
    //
    //   await secureStore.write(
    //       key: "${testWalletId}_mnemonic", value: "some mnemonic words");
    //
    //   bool hasThrown = false;
    //   try {
    //     await nmc?.recoverFromMnemonic(
    //         mnemonic: TEST_MNEMONIC,
    //         maxUnusedAddressGap: 2,
    //         maxNumberOfIndexesToCheck: 1000,
    //         height: 4000);
    //   } catch (_) {
    //     hasThrown = true;
    //   }
    //   expect(hasThrown, true);
    //
    //   verify(client?.getServerFeatures()).called(1);
    //
    //   expect(secureStore.interactions, 2);
    //   verifyNoMoreInteractions(client);
    //   verifyNoMoreInteractions(cachedClient);
    //   verifyNoMoreInteractions(priceAPI);
    // });

    // test("recoverFromMnemonic using empty seed on mainnet succeeds", () async {
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
    //       .thenAnswer((_) async => emptyHistoryBatchResponse);
    //   when(client?.getBatchHistory(args: historyBatchArgs1))
    //       .thenAnswer((_) async => emptyHistoryBatchResponse);
    //   when(client?.getBatchHistory(args: historyBatchArgs2))
    //       .thenAnswer((_) async => emptyHistoryBatchResponse);
    //   when(client?.getBatchHistory(args: historyBatchArgs3))
    //       .thenAnswer((_) async => emptyHistoryBatchResponse);
    //   when(client?.getBatchHistory(args: historyBatchArgs4))
    //       .thenAnswer((_) async => emptyHistoryBatchResponse);
    //   when(client?.getBatchHistory(args: historyBatchArgs5))
    //       .thenAnswer((_) async => emptyHistoryBatchResponse);
    //   await DB.instance.init();
    //   final wallet = await Hive.openBox(testWalletId);
    //   bool hasThrown = false;
    //   try {
    //     await nmc?.recoverFromMnemonic(
    //         mnemonic: TEST_MNEMONIC,
    //         maxUnusedAddressGap: 2,
    //         maxNumberOfIndexesToCheck: 1000,
    //         height: 4000);
    //   } catch (_) {
    //     hasThrown = true;
    //   }
    //   expect(hasThrown, false);
    //
    //   verify(client?.getServerFeatures()).called(1);
    //   verify(client?.getBatchHistory(args: historyBatchArgs0)).called(1);
    //   verify(client?.getBatchHistory(args: historyBatchArgs1)).called(1);
    //   verify(client?.getBatchHistory(args: historyBatchArgs2)).called(1);
    //   verify(client?.getBatchHistory(args: historyBatchArgs3)).called(1);
    //   verify(client?.getBatchHistory(args: historyBatchArgs4)).called(1);
    //   verify(client?.getBatchHistory(args: historyBatchArgs5)).called(1);
    //
    //   expect(secureStore.interactions, 20);
    //   expect(secureStore.writes, 7);
    //   expect(secureStore.reads, 13);
    //   expect(secureStore.deletes, 0);
    //
    //   verifyNoMoreInteractions(client);
    //   verifyNoMoreInteractions(cachedClient);
    //   verifyNoMoreInteractions(priceAPI);
    // });

    // test("get mnemonic list", () async {
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
    //       .thenAnswer((_) async => emptyHistoryBatchResponse);
    //   when(client?.getBatchHistory(args: historyBatchArgs1))
    //       .thenAnswer((_) async => emptyHistoryBatchResponse);
    //   when(client?.getBatchHistory(args: historyBatchArgs2))
    //       .thenAnswer((_) async => emptyHistoryBatchResponse);
    //   when(client?.getBatchHistory(args: historyBatchArgs3))
    //       .thenAnswer((_) async => emptyHistoryBatchResponse);
    //   when(client?.getBatchHistory(args: historyBatchArgs4))
    //       .thenAnswer((_) async => emptyHistoryBatchResponse);
    //   when(client?.getBatchHistory(args: historyBatchArgs5))
    //       .thenAnswer((_) async => emptyHistoryBatchResponse);
    //
    //   final wallet = await Hive.openBox(testWalletId);
    //
    //   await nmc?.recoverFromMnemonic(
    //       mnemonic: TEST_MNEMONIC,
    //       maxUnusedAddressGap: 2,
    //       maxNumberOfIndexesToCheck: 1000,
    //       height: 4000);
    //
    //   expect(await nmc?.mnemonic, TEST_MNEMONIC.split(" "));
    //
    //   verify(client?.getServerFeatures()).called(1);
    //   verify(client?.getBatchHistory(args: historyBatchArgs0)).called(1);
    //   verify(client?.getBatchHistory(args: historyBatchArgs1)).called(1);
    //   verify(client?.getBatchHistory(args: historyBatchArgs2)).called(1);
    //   verify(client?.getBatchHistory(args: historyBatchArgs3)).called(1);
    //   verify(client?.getBatchHistory(args: historyBatchArgs4)).called(1);
    //   verify(client?.getBatchHistory(args: historyBatchArgs5)).called(1);
    //
    //   verifyNoMoreInteractions(client);
    //   verifyNoMoreInteractions(cachedClient);
    //   verifyNoMoreInteractions(priceAPI);
    // });

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
      when(client?.getBatchHistory(args: historyBatchArgs1))
          .thenAnswer((_) async => historyBatchResponse);
      when(client?.getBatchHistory(args: historyBatchArgs2))
          .thenAnswer((_) async => historyBatchResponse);
      when(client?.getBatchHistory(args: historyBatchArgs3))
          .thenAnswer((_) async => historyBatchResponse);
      when(client?.getBatchHistory(args: historyBatchArgs4))
          .thenAnswer((_) async => historyBatchResponse);
      when(client?.getBatchHistory(args: historyBatchArgs5))
          .thenAnswer((_) async => historyBatchResponse);

      List<dynamic> dynamicArgValues = [];

      when(client?.getBatchHistory(args: anyNamed("args")))
          .thenAnswer((realInvocation) async {
        if (realInvocation.namedArguments.values.first.length == 1) {
          dynamicArgValues.add(realInvocation.namedArguments.values.first);
        }

        return historyBatchResponse;
      });

      await Hive.openBox<dynamic>(testWalletId);

      bool hasThrown = false;
      try {
        await part?.recoverFromMnemonic(
            mnemonic: TEST_MNEMONIC,
            maxUnusedAddressGap: 2,
            maxNumberOfIndexesToCheck: 1000,
            height: 4000);
      } catch (_) {
        hasThrown = true;
      }
      expect(hasThrown, false);

      verify(client?.getServerFeatures()).called(1);
      // verify(client?.getBatchHistory(args: historyBatchArgs0)).called(1); // TODO remove this def above
      // verify(client?.getBatchHistory(args: historyBatchArgs1)).called(1); // TODO remove this def above
      verify(client?.getBatchHistory(args: historyBatchArgs2)).called(1);
      verify(client?.getBatchHistory(args: historyBatchArgs3)).called(1);
      verify(client?.getBatchHistory(args: historyBatchArgs4)).called(1);
      verify(client?.getBatchHistory(args: historyBatchArgs5)).called(1);

      for (final arg in dynamicArgValues) {
        final map = Map<String, List<dynamic>>.from(arg as Map);
        verify(client?.getBatchHistory(args: map)).called(1);
        expect(activeScriptHashes.contains(map.values.first.first as String),
            true);
      }

      expect(secureStore.interactions, 10);
      expect(secureStore.writes, 5);
      expect(secureStore.reads, 5);
      expect(secureStore.deletes, 0);

      verifyNoMoreInteractions(client);
      verifyNoMoreInteractions(cachedClient);
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
      when(client?.getBatchHistory(args: historyBatchArgs2))
          .thenAnswer((_) async => historyBatchResponse);
      when(client?.getBatchHistory(args: historyBatchArgs3))
          .thenAnswer((_) async => historyBatchResponse);
      when(client?.getBatchHistory(args: historyBatchArgs4))
          .thenAnswer((_) async => historyBatchResponse);
      when(client?.getBatchHistory(args: historyBatchArgs5))
          .thenAnswer((_) async => historyBatchResponse);
      when(cachedClient?.clearSharedTransactionCache(coin: Coin.particl))
          .thenAnswer((realInvocation) async {});

      when(client?.getBatchHistory(args: {
        "0": [
          "8ba03c2c46ed4980fa1e4c84cbceeb2d5e1371a7ccbaf5f3d69c5114161a2247"
        ]
      })).thenAnswer((realInvocation) async => {"0": []});

      when(client?.getBatchHistory(args: {
        "0": [
          "3fedd8a2d5fc355727afe353413dc1a0ef861ba768744d5b8193c33cbc829339"
        ]
      })).thenAnswer((realInvocation) async => {"0": []});

      when(client?.getBatchHistory(args: {
        "0": [
          "b6fce6c41154ccf70676c5c91acd9b6899ef0195e34b4c05c4920daa827c19a3"
        ]
      })).thenAnswer((realInvocation) async => {"0": []});

      when(client?.getBatchHistory(args: {
        "0": [
          "0e8b6756b404db5a381fd71ad79cb595a6c36c938cf9913c5a0494b667c2151a"
        ]
      })).thenAnswer((realInvocation) async => {"0": []});
      when(client?.getBatchHistory(args: {
        "0": [
          "9b56ab30c7bef0e1eaa10a632c8e2dcdd11b2158d7a917c03d62936afd0015fc"
        ]
      })).thenAnswer((realInvocation) async => {"0": []});
      when(client?.getBatchHistory(args: {
        "0": [
          "c4b1d9cd4edb7c13eae863b1e4f8fd5acff29f1fe153c4f859906cbea26a3f2f"
        ]
      })).thenAnswer((realInvocation) async => {"0": []});

      final wallet = await Hive.openBox<dynamic>(testWalletId);

      // restore so we have something to rescan
      await part?.recoverFromMnemonic(
          mnemonic: TEST_MNEMONIC,
          maxUnusedAddressGap: 2,
          maxNumberOfIndexesToCheck: 1000,
          height: 4000);

      // fetch valid wallet data
      final preReceivingAddressesP2PKH =
          await wallet.get('receivingAddressesP2PKH');
      final preReceivingAddressesP2SH =
          await wallet.get('receivingAddressesP2SH');
      final preReceivingAddressesP2WPKH =
          await wallet.get('receivingAddressesP2WPKH');
      final preChangeAddressesP2PKH = await wallet.get('changeAddressesP2PKH');
      final preChangeAddressesP2SH = await wallet.get('changeAddressesP2SH');
      final preChangeAddressesP2WPKH =
          await wallet.get('changeAddressesP2WPKH');
      final preReceivingIndexP2PKH = await wallet.get('receivingIndexP2PKH');
      final preReceivingIndexP2SH = await wallet.get('receivingIndexP2SH');
      final preReceivingIndexP2WPKH = await wallet.get('receivingIndexP2WPKH');
      final preChangeIndexP2PKH = await wallet.get('changeIndexP2PKH');
      final preChangeIndexP2SH = await wallet.get('changeIndexP2SH');
      final preChangeIndexP2WPKH = await wallet.get('changeIndexP2WPKH');
      final preUtxoData = await wallet.get('latest_utxo_model');
      final preReceiveDerivationsStringP2PKH = await secureStore.read(
          key: "${testWalletId}_receiveDerivationsP2PKH");
      final preChangeDerivationsStringP2PKH =
          await secureStore.read(key: "${testWalletId}_changeDerivationsP2PKH");
      final preReceiveDerivationsStringP2SH =
          await secureStore.read(key: "${testWalletId}_receiveDerivationsP2SH");
      final preChangeDerivationsStringP2SH =
          await secureStore.read(key: "${testWalletId}_changeDerivationsP2SH");
      final preReceiveDerivationsStringP2WPKH = await secureStore.read(
          key: "${testWalletId}_receiveDerivationsP2WPKH");
      final preChangeDerivationsStringP2WPKH = await secureStore.read(
          key: "${testWalletId}_changeDerivationsP2WPKH");

      // destroy the data that the rescan will fix
      await wallet.put(
          'receivingAddressesP2PKH', ["some address", "some other address"]);
      await wallet.put(
          'receivingAddressesP2SH', ["some address", "some other address"]);
      await wallet.put(
          'receivingAddressesP2WPKH', ["some address", "some other address"]);
      await wallet
          .put('changeAddressesP2PKH', ["some address", "some other address"]);
      await wallet
          .put('changeAddressesP2SH', ["some address", "some other address"]);
      await wallet
          .put('changeAddressesP2WPKH', ["some address", "some other address"]);
      await wallet.put('receivingIndexP2PKH', 123);
      await wallet.put('receivingIndexP2SH', 123);
      await wallet.put('receivingIndexP2WPKH', 123);
      await wallet.put('changeIndexP2PKH', 123);
      await wallet.put('changeIndexP2SH', 123);
      await wallet.put('changeIndexP2WPKH', 123);
      await secureStore.write(
          key: "${testWalletId}_receiveDerivationsP2PKH", value: "{}");
      await secureStore.write(
          key: "${testWalletId}_changeDerivationsP2PKH", value: "{}");
      await secureStore.write(
          key: "${testWalletId}_receiveDerivationsP2SH", value: "{}");
      await secureStore.write(
          key: "${testWalletId}_changeDerivationsP2SH", value: "{}");
      await secureStore.write(
          key: "${testWalletId}_receiveDerivationsP2WPKH", value: "{}");
      await secureStore.write(
          key: "${testWalletId}_changeDerivationsP2WPKH", value: "{}");

      bool hasThrown = false;
      try {
        await part?.fullRescan(2, 1000);
      } catch (_) {
        hasThrown = true;
      }
      expect(hasThrown, false);

      // fetch wallet data again
      final receivingAddressesP2PKH =
          await wallet.get('receivingAddressesP2PKH');
      // final receivingAddressesP2SH = await wallet.get('receivingAddressesP2SH');
      // final receivingAddressesP2WPKH =
      //     await wallet.get('receivingAddressesP2WPKH');
      final changeAddressesP2PKH = await wallet.get('changeAddressesP2PKH');
      // final changeAddressesP2SH = await wallet.get('changeAddressesP2SH');
      // final changeAddressesP2WPKH = await wallet.get('changeAddressesP2WPKH');
      final receivingIndexP2PKH = await wallet.get('receivingIndexP2PKH');
      // final receivingIndexP2SH = await wallet.get('receivingIndexP2SH');
      // final receivingIndexP2WPKH = await wallet.get('receivingIndexP2WPKH');
      final changeIndexP2PKH = await wallet.get('changeIndexP2PKH');
      // final changeIndexP2SH = await wallet.get('changeIndexP2SH');
      // final changeIndexP2WPKH = await wallet.get('changeIndexP2WPKH');
      final utxoData = await wallet.get('latest_utxo_model');
      final receiveDerivationsStringP2PKH = await secureStore.read(
          key: "${testWalletId}_receiveDerivationsP2PKH");
      final changeDerivationsStringP2PKH =
          await secureStore.read(key: "${testWalletId}_changeDerivationsP2PKH");
      // final receiveDerivationsStringP2SH =
      //     await secureStore.read(key: "${testWalletId}_receiveDerivationsP2SH");
      // final changeDerivationsStringP2SH =
      //     await secureStore.read(key: "${testWalletId}_changeDerivationsP2SH");
      // final receiveDerivationsStringP2WPKH = await secureStore.read(
      //     key: "${testWalletId}_receiveDerivationsP2WPKH");
      // final changeDerivationsStringP2WPKH = await secureStore.read(
      //     key: "${testWalletId}_changeDerivationsP2WPKH");

      expect(preReceivingAddressesP2PKH, receivingAddressesP2PKH);
      // expect(preReceivingAddressesP2SH, receivingAddressesP2SH);
      // expect(preReceivingAddressesP2WPKH, receivingAddressesP2WPKH);
      expect(preChangeAddressesP2PKH, changeAddressesP2PKH);
      // expect(preChangeAddressesP2SH, changeAddressesP2SH);
      // expect(preChangeAddressesP2WPKH, changeAddressesP2WPKH);
      expect(preReceivingIndexP2PKH, receivingIndexP2PKH);
      // expect(preReceivingIndexP2SH, receivingIndexP2SH);
      // expect(preReceivingIndexP2WPKH, receivingIndexP2WPKH);
      expect(preChangeIndexP2PKH, changeIndexP2PKH);
      // expect(preChangeIndexP2SH, changeIndexP2SH);
      // expect(preChangeIndexP2WPKH, changeIndexP2WPKH);
      expect(preUtxoData, utxoData);
      expect(preReceiveDerivationsStringP2PKH, receiveDerivationsStringP2PKH);
      expect(preChangeDerivationsStringP2PKH, changeDerivationsStringP2PKH);
      // expect(preReceiveDerivationsStringP2SH, receiveDerivationsStringP2SH);
      // expect(preChangeDerivationsStringP2SH, changeDerivationsStringP2SH);
      // expect(preReceiveDerivationsStringP2WPKH, receiveDerivationsStringP2WPKH);
      // expect(preChangeDerivationsStringP2WPKH, changeDerivationsStringP2WPKH);

      verify(client?.getServerFeatures()).called(1);
      // verify(client?.getBatchHistory(args: historyBatchArgs0)).called(1); // TODO remove this def above
      // verify(client?.getBatchHistory(args: historyBatchArgs1)).called(1); // TODO remove this def above
      verify(client?.getBatchHistory(args: historyBatchArgs2)).called(2);
      verify(client?.getBatchHistory(args: historyBatchArgs3)).called(2);
      verify(client?.getBatchHistory(args: historyBatchArgs4)).called(2);
      verify(client?.getBatchHistory(args: historyBatchArgs5)).called(2);
      // verify(client?.getBatchHistory(args: {
      //   "0": [
      //     "8ba03c2c46ed4980fa1e4c84cbceeb2d5e1371a7ccbaf5f3d69c5114161a2247"
      //   ]
      // })).called(2);
      verify(client?.getBatchHistory(args: {
        "0": [
          "3fedd8a2d5fc355727afe353413dc1a0ef861ba768744d5b8193c33cbc829339"
        ]
      })).called(2);

      verify(client?.getBatchHistory(args: {
        "0": [
          "b6fce6c41154ccf70676c5c91acd9b6899ef0195e34b4c05c4920daa827c19a3"
        ]
      })).called(2);

      verify(client?.getBatchHistory(args: {
        "0": [
          "0e8b6756b404db5a381fd71ad79cb595a6c36c938cf9913c5a0494b667c2151a"
        ]
      })).called(2);

      // verify(client?.getBatchHistory(args: {
      //   "0": [
      //     "9b56ab30c7bef0e1eaa10a632c8e2dcdd11b2158d7a917c03d62936afd0015fc"
      //   ]
      // })).called(2);

      verify(client?.getBatchHistory(args: {
        "0": [
          "c4b1d9cd4edb7c13eae863b1e4f8fd5acff29f1fe153c4f859906cbea26a3f2f"
        ]
      })).called(2);
      verify(cachedClient?.clearSharedTransactionCache(coin: Coin.particl))
          .called(1);

      expect(secureStore.writes, 19);
      expect(secureStore.reads, 22);
      expect(secureStore.deletes, 4);

      verifyNoMoreInteractions(client);
      verifyNoMoreInteractions(cachedClient);
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
      when(client?.getBatchHistory(args: historyBatchArgs1))
          .thenAnswer((_) async => historyBatchResponse);
      when(client?.getBatchHistory(args: historyBatchArgs2))
          .thenAnswer((_) async => historyBatchResponse);
      when(client?.getBatchHistory(args: historyBatchArgs3))
          .thenAnswer((_) async => historyBatchResponse);
      when(client?.getBatchHistory(args: historyBatchArgs4))
          .thenAnswer((_) async => historyBatchResponse);
      when(client?.getBatchHistory(args: historyBatchArgs5))
          .thenAnswer((_) async => historyBatchResponse);

      when(client?.getBatchHistory(args: {
        "0": [
          "8ba03c2c46ed4980fa1e4c84cbceeb2d5e1371a7ccbaf5f3d69c5114161a2247"
        ]
      })).thenAnswer((realInvocation) async => {"0": []});

      when(client?.getBatchHistory(args: {
        "0": [
          "3fedd8a2d5fc355727afe353413dc1a0ef861ba768744d5b8193c33cbc829339"
        ]
      })).thenAnswer((realInvocation) async => {"0": []});

      when(client?.getBatchHistory(args: {
        "0": [
          "b6fce6c41154ccf70676c5c91acd9b6899ef0195e34b4c05c4920daa827c19a3"
        ]
      })).thenAnswer((realInvocation) async => {"0": []});

      when(client?.getBatchHistory(args: {
        "0": [
          "0e8b6756b404db5a381fd71ad79cb595a6c36c938cf9913c5a0494b667c2151a"
        ]
      })).thenAnswer((realInvocation) async => {"0": []});

      when(client?.getBatchHistory(args: {
        "0": [
          "9b56ab30c7bef0e1eaa10a632c8e2dcdd11b2158d7a917c03d62936afd0015fc"
        ]
      })).thenAnswer((realInvocation) async => {"0": []});

      when(client?.getBatchHistory(args: {
        "0": [
          "c4b1d9cd4edb7c13eae863b1e4f8fd5acff29f1fe153c4f859906cbea26a3f2f"
        ]
      })).thenAnswer((realInvocation) async => {"0": []});

      when(cachedClient?.clearSharedTransactionCache(coin: Coin.particl))
          .thenAnswer((realInvocation) async {});

      final wallet = await Hive.openBox<dynamic>(testWalletId);

      // restore so we have something to rescan
      await part?.recoverFromMnemonic(
          mnemonic: TEST_MNEMONIC,
          maxUnusedAddressGap: 2,
          maxNumberOfIndexesToCheck: 1000,
          height: 4000);

      // fetch wallet data
      final preReceivingAddressesP2PKH =
          await wallet.get('receivingAddressesP2PKH');
      final preReceivingAddressesP2SH =
          await wallet.get('receivingAddressesP2SH');
      final preReceivingAddressesP2WPKH =
          await wallet.get('receivingAddressesP2WPKH');
      final preChangeAddressesP2PKH = await wallet.get('changeAddressesP2PKH');
      final preChangeAddressesP2SH = await wallet.get('changeAddressesP2SH');
      final preChangeAddressesP2WPKH =
          await wallet.get('changeAddressesP2WPKH');
      final preReceivingIndexP2PKH = await wallet.get('receivingIndexP2PKH');
      final preReceivingIndexP2SH = await wallet.get('receivingIndexP2SH');
      final preReceivingIndexP2WPKH = await wallet.get('receivingIndexP2WPKH');
      final preChangeIndexP2PKH = await wallet.get('changeIndexP2PKH');
      final preChangeIndexP2SH = await wallet.get('changeIndexP2SH');
      final preChangeIndexP2WPKH = await wallet.get('changeIndexP2WPKH');
      final preUtxoData = await wallet.get('latest_utxo_model');
      final preReceiveDerivationsStringP2PKH = await secureStore.read(
          key: "${testWalletId}_receiveDerivationsP2PKH");
      final preChangeDerivationsStringP2PKH =
          await secureStore.read(key: "${testWalletId}_changeDerivationsP2PKH");
      final preReceiveDerivationsStringP2SH =
          await secureStore.read(key: "${testWalletId}_receiveDerivationsP2SH");
      final preChangeDerivationsStringP2SH =
          await secureStore.read(key: "${testWalletId}_changeDerivationsP2SH");
      final preReceiveDerivationsStringP2WPKH = await secureStore.read(
          key: "${testWalletId}_receiveDerivationsP2WPKH");
      final preChangeDerivationsStringP2WPKH = await secureStore.read(
          key: "${testWalletId}_changeDerivationsP2WPKH");

      when(client?.getBatchHistory(args: historyBatchArgs0))
          .thenThrow(Exception("fake exception"));
      when(client?.getBatchHistory(args: historyBatchArgs1))
          .thenThrow(Exception("fake exception"));
      when(client?.getBatchHistory(args: historyBatchArgs2))
          .thenThrow(Exception("fake exception"));
      when(client?.getBatchHistory(args: historyBatchArgs3))
          .thenThrow(Exception("fake exception"));
      when(client?.getBatchHistory(args: historyBatchArgs4))
          .thenThrow(Exception("fake exception"));
      when(client?.getBatchHistory(args: historyBatchArgs5))
          .thenThrow(Exception("fake exception"));

      bool hasThrown = false;
      try {
        await part?.fullRescan(2, 1000);
      } catch (_) {
        hasThrown = true;
      }
      expect(hasThrown, true);

      // fetch wallet data again
      final receivingAddressesP2PKH =
          await wallet.get('receivingAddressesP2PKH');
      final receivingAddressesP2SH = await wallet.get('receivingAddressesP2SH');
      // final receivingAddressesP2WPKH =
      //     await wallet.get('receivingAddressesP2WPKH');
      final changeAddressesP2PKH = await wallet.get('changeAddressesP2PKH');
      // final changeAddressesP2SH = await wallet.get('changeAddressesP2SH');
      // final changeAddressesP2WPKH = await wallet.get('changeAddressesP2WPKH');
      final receivingIndexP2PKH = await wallet.get('receivingIndexP2PKH');
      // final receivingIndexP2SH = await wallet.get('receivingIndexP2SH');
      // final receivingIndexP2WPKH = await wallet.get('receivingIndexP2WPKH');
      final changeIndexP2PKH = await wallet.get('changeIndexP2PKH');
      // final changeIndexP2SH = await wallet.get('changeIndexP2SH');
      // final changeIndexP2WPKH = await wallet.get('changeIndexP2WPKH');
      final utxoData = await wallet.get('latest_utxo_model');
      final receiveDerivationsStringP2PKH = await secureStore.read(
          key: "${testWalletId}_receiveDerivationsP2PKH");
      final changeDerivationsStringP2PKH =
          await secureStore.read(key: "${testWalletId}_changeDerivationsP2PKH");
      // final receiveDerivationsStringP2SH =
      //     await secureStore.read(key: "${testWalletId}_receiveDerivationsP2SH");
      // final changeDerivationsStringP2SH =
      //     await secureStore.read(key: "${testWalletId}_changeDerivationsP2SH");
      // final receiveDerivationsStringP2WPKH = await secureStore.read(
      //     key: "${testWalletId}_receiveDerivationsP2WPKH");
      // final changeDerivationsStringP2WPKH = await secureStore.read(
      //     key: "${testWalletId}_changeDerivationsP2WPKH");

      expect(preReceivingAddressesP2PKH, receivingAddressesP2PKH);
      expect(preReceivingAddressesP2SH, receivingAddressesP2SH);
      // expect(preReceivingAddressesP2WPKH, receivingAddressesP2WPKH);
      expect(preChangeAddressesP2PKH, changeAddressesP2PKH);
      // expect(preChangeAddressesP2SH, changeAddressesP2SH);
      // expect(preChangeAddressesP2WPKH, changeAddressesP2WPKH);
      expect(preReceivingIndexP2PKH, receivingIndexP2PKH);
      // expect(preReceivingIndexP2SH, receivingIndexP2SH);
      // expect(preReceivingIndexP2WPKH, receivingIndexP2WPKH);
      expect(preChangeIndexP2PKH, changeIndexP2PKH);
      // expect(preChangeIndexP2SH, changeIndexP2SH);
      // expect(preChangeIndexP2WPKH, changeIndexP2WPKH);
      expect(preUtxoData, utxoData);
      expect(preReceiveDerivationsStringP2PKH, receiveDerivationsStringP2PKH);
      expect(preChangeDerivationsStringP2PKH, changeDerivationsStringP2PKH);
      // expect(preReceiveDerivationsStringP2SH, receiveDerivationsStringP2SH);
      // expect(preChangeDerivationsStringP2SH, changeDerivationsStringP2SH);
      // expect(preReceiveDerivationsStringP2WPKH, receiveDerivationsStringP2WPKH);
      // expect(preChangeDerivationsStringP2WPKH, changeDerivationsStringP2WPKH);

      verify(client?.getServerFeatures()).called(1);
      // verify(client?.getBatchHistory(args: historyBatchArgs0)).called(2);
      // verify(client?.getBatchHistory(args: historyBatchArgs1)).called(2);
      // verify(client?.getBatchHistory(args: historyBatchArgs2)).called(2);
      verify(client?.getBatchHistory(args: historyBatchArgs3)).called(2);
      verify(client?.getBatchHistory(args: historyBatchArgs4)).called(2);
      verify(client?.getBatchHistory(args: historyBatchArgs5)).called(2);

      // verify(client?.getBatchHistory(args: {
      //   "0": [
      //     "8ba03c2c46ed4980fa1e4c84cbceeb2d5e1371a7ccbaf5f3d69c5114161a2247"
      //   ]
      // })).called(2);
      verify(client?.getBatchHistory(args: {
        "0": [
          "3fedd8a2d5fc355727afe353413dc1a0ef861ba768744d5b8193c33cbc829339"
        ]
      })).called(1);
      verify(client?.getBatchHistory(args: {
        "0": [
          "b6fce6c41154ccf70676c5c91acd9b6899ef0195e34b4c05c4920daa827c19a3"
        ]
      })).called(1);
      verify(client?.getBatchHistory(args: {
        "0": [
          "0e8b6756b404db5a381fd71ad79cb595a6c36c938cf9913c5a0494b667c2151a"
        ]
      })).called(1);
      // verify(client?.getBatchHistory(args: {
      //   "0": [
      //     "9b56ab30c7bef0e1eaa10a632c8e2dcdd11b2158d7a917c03d62936afd0015fc"
      //   ]
      // })).called(1);
      verify(client?.getBatchHistory(args: {
        "0": [
          "c4b1d9cd4edb7c13eae863b1e4f8fd5acff29f1fe153c4f859906cbea26a3f2f"
        ]
      })).called(1);
      verify(cachedClient?.clearSharedTransactionCache(coin: Coin.particl))
          .called(1);

      expect(secureStore.writes, 13);
      expect(secureStore.reads, 22);
      expect(secureStore.deletes, 8);

      // verifyNoMoreInteractions(client);
      verifyNoMoreInteractions(cachedClient);
      verifyNoMoreInteractions(priceAPI);
    });

    // test("prepareSend fails", () async {
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
    //   when(client?.getBatchHistory(args: historyBatchArgs2))
    //       .thenAnswer((_) async => historyBatchResponse);
    //   when(client?.getBatchHistory(args: historyBatchArgs3))
    //       .thenAnswer((_) async => historyBatchResponse);
    //   when(client?.getBatchHistory(args: historyBatchArgs4))
    //       .thenAnswer((_) async => historyBatchResponse);
    //   when(client?.getBatchHistory(args: historyBatchArgs5))
    //       .thenAnswer((_) async => historyBatchResponse);
    //
    //   List<dynamic> dynamicArgValues = [];
    //
    //   when(client?.getBatchHistory(args: anyNamed("args")))
    //       .thenAnswer((realInvocation) async {
    //     if (realInvocation.namedArguments.values.first.length == 1) {
    //       dynamicArgValues.add(realInvocation.namedArguments.values.first);
    //     }
    //
    //     return historyBatchResponse;
    //   });
    //
    //   await Hive.openBox<dynamic>(testWalletId);
    //
    //   when(cachedClient?.getTransaction(
    //           txHash:
    //               "dffa9543852197f9fb90f8adafaab8a0b9b4925e9ada8c6bdcaf00bf2e9f60d7",
    //           coin: Coin.particl))
    //       .thenAnswer((_) async => tx2Raw);
    //   when(cachedClient?.getTransaction(
    //           txHash:
    //               "71b56532e9e7321bd8c30d0f8b14530743049d2f3edd5623065c46eee1dda04d",
    //           coin: Coin.particl))
    //       .thenAnswer((_) async => tx3Raw);
    //   when(cachedClient?.getTransaction(
    //     txHash:
    //         "c7e700f7e23a85bbdd9de86d502322a933607ee7ea7e16adaf02e477cdd849b9",
    //     coin: Coin.particl,
    //   )).thenAnswer((_) async => tx4Raw);
    //
    //   // recover to fill data
    //   await nmc?.recoverFromMnemonic(
    //       mnemonic: TEST_MNEMONIC,
    //       maxUnusedAddressGap: 2,
    //       maxNumberOfIndexesToCheck: 1000,
    //       height: 4000);
    //
    //   // modify addresses to properly mock data to build a tx
    //   final rcv44 = await secureStore.read(
    //       key: testWalletId + "_receiveDerivationsP2PKH");
    //   await secureStore.write(
    //       key: testWalletId + "_receiveDerivationsP2PKH",
    //       value: rcv44?.replaceFirst("1RMSPixoLPuaXuhR2v4HsUMcRjLncKDaw",
    //           "16FuTPaeRSPVxxCnwQmdyx2PQWxX6HWzhQ"));
    //   final rcv49 =
    //       await secureStore.read(key: testWalletId + "_receiveDerivationsP2SH");
    //   await secureStore.write(
    //       key: testWalletId + "_receiveDerivationsP2SH",
    //       value: rcv49?.replaceFirst("3AV74rKfibWmvX34F99yEvUcG4LLQ9jZZk",
    //           "36NvZTcMsMowbt78wPzJaHHWaNiyR73Y4g"));
    //   final rcv84 = await secureStore.read(
    //       key: testWalletId + "_receiveDerivationsP2WPKH");
    //   await secureStore.write(
    //       key: testWalletId + "_receiveDerivationsP2WPKH",
    //       value: rcv84?.replaceFirst(
    //           "bc1qggtj4ka8jsaj44hhd5mpamx7mp34m2d3w7k0m0",
    //           "bc1q42lja79elem0anu8q8s3h2n687re9jax556pcc"));
    //
    //   nmc?.outputsList = utxoList;
    //
    //   bool didThrow = false;
    //   try {
    //     await nmc?.prepareSend(
    //         address: "nc1q6k4x8ye6865z3rc8zkt8gyu52na7njqt6hsk4v",
    //         satoshiAmount: 15000);
    //   } catch (_) {
    //     didThrow = true;
    //   }
    //
    //   expect(didThrow, true);
    //
    //   verify(client?.getServerFeatures()).called(1);
    //
    //   /// verify transaction no matching calls
    //
    //   // verify(cachedClient?.getTransaction(
    //   //         txHash:
    //   //             "2087ce09bc316877c9f10971526a2bffa3078d52ea31752639305cdcd8230703",
    //   //         coin: Coin.particl,
    //   //         callOutSideMainIsolate: false))
    //   //     .called(1);
    //   // verify(cachedClient?.getTransaction(
    //   //         txHash:
    //   //             "ed32c967a0e86d51669ac21c2bb9bc9c50f0f55fbacdd8db21d0a986fba93bd7",
    //   //         coin: Coin.particl,
    //   //         callOutSideMainIsolate: false))
    //   //     .called(1);
    //   // verify(cachedClient?.getTransaction(
    //   //         txHash:
    //   //             "3f0032f89ac44b281b50314cff3874c969c922839dddab77ced54e86a21c3fd4",
    //   //         coin: Coin.particl,
    //   //         callOutSideMainIsolate: false))
    //   //     .called(1);
    //   verify(client?.getBatchHistory(args: historyBatchArgs0)).called(1);
    //   verify(client?.getBatchHistory(args: historyBatchArgs1)).called(1);
    //   verify(client?.getBatchHistory(args: historyBatchArgs2)).called(1);
    //   verify(client?.getBatchHistory(args: historyBatchArgs3)).called(1);
    //   verify(client?.getBatchHistory(args: historyBatchArgs4)).called(1);
    //   verify(client?.getBatchHistory(args: historyBatchArgs5)).called(1);
    //
    //   for (final arg in dynamicArgValues) {
    //     final map = Map<String, List<dynamic>>.from(arg as Map);
    //
    //     verify(client?.getBatchHistory(args: map)).called(1);
    //     expect(activeScriptHashes.contains(map.values.first.first as String),
    //         true);
    //   }
    //
    //   expect(secureStore.interactions, 20);
    //   expect(secureStore.writes, 10);
    //   expect(secureStore.reads, 10);
    //   expect(secureStore.deletes, 0);
    //
    //   verifyNoMoreInteractions(client);
    //   verifyNoMoreInteractions(cachedClient);
    //   verifyNoMoreInteractions(priceAPI);
    // });

    // test("confirmSend no hex", () async {
    //   bool didThrow = false;
    //   try {
    //     await nmc?.confirmSend(txData: {"some": "strange map"});
    //   } catch (_) {
    //     didThrow = true;
    //   }
    //
    //   expect(didThrow, true);
    //
    //   expect(secureStore.interactions, 0);
    //   verifyNoMoreInteractions(client);
    //   verifyNoMoreInteractions(cachedClient);
    //   verifyNoMoreInteractions(priceAPI);
    // });

    // test("confirmSend hex is not string", () async {
    //   bool didThrow = false;
    //   try {
    //     await nmc?.confirmSend(txData: {"hex": true});
    //   } catch (_) {
    //     didThrow = true;
    //   }
    //
    //   expect(didThrow, true);
    //
    //   expect(secureStore.interactions, 0);
    //   verifyNoMoreInteractions(client);
    //   verifyNoMoreInteractions(cachedClient);
    //   verifyNoMoreInteractions(priceAPI);
    // });

    // test("confirmSend hex is string but missing other data", () async {
    //   bool didThrow = false;
    //   try {
    //     await nmc?.confirmSend(txData: {"hex": "a string"});
    //   } catch (_) {
    //     didThrow = true;
    //   }
    //
    //   expect(didThrow, true);
    //
    //   verify(client?.broadcastTransaction(
    //           rawTx: "a string", requestID: anyNamed("requestID")))
    //       .called(1);
    //
    //   expect(secureStore.interactions, 0);
    //   verifyNoMoreInteractions(client);
    //   verifyNoMoreInteractions(cachedClient);
    //   verifyNoMoreInteractions(priceAPI);
    // });

    // test("confirmSend fails due to vSize being greater than fee", () async {
    //   bool didThrow = false;
    //   try {
    //     await nmc
    //         ?.confirmSend(txData: {"hex": "a string", "fee": 1, "vSize": 10});
    //   } catch (_) {
    //     didThrow = true;
    //   }
    //
    //   expect(didThrow, true);
    //
    //   verify(client?.broadcastTransaction(
    //           rawTx: "a string", requestID: anyNamed("requestID")))
    //       .called(1);
    //
    //   expect(secureStore.interactions, 0);
    //   verifyNoMoreInteractions(client);
    //   verifyNoMoreInteractions(cachedClient);
    //   verifyNoMoreInteractions(priceAPI);
    // });

    // test("confirmSend fails when broadcast transactions throws", () async {
    //   when(client?.broadcastTransaction(
    //           rawTx: "a string", requestID: anyNamed("requestID")))
    //       .thenThrow(Exception("some exception"));
    //
    //   bool didThrow = false;
    //   try {
    //     await nmc
    //         ?.confirmSend(txData: {"hex": "a string", "fee": 10, "vSize": 10});
    //   } catch (_) {
    //     didThrow = true;
    //   }
    //
    //   expect(didThrow, true);
    //
    //   verify(client?.broadcastTransaction(
    //           rawTx: "a string", requestID: anyNamed("requestID")))
    //       .called(1);
    //
    //   expect(secureStore.interactions, 0);
    //   verifyNoMoreInteractions(client);
    //   verifyNoMoreInteractions(cachedClient);
    //   verifyNoMoreInteractions(tracker);
    //   verifyNoMoreInteractions(priceAPI);
    // });
    //
    // // this test will create a non mocked electrumx client that will try to connect
    // // to the provided ipAddress below. This will throw a bunch of errors
    // // which what we want here as actually calling electrumx calls here is unwanted.
    // // test("listen to NodesChangedEvent", () async {
    // //   nmc = ParticlWallet(
    // //     walletId: testWalletId,
    // //     walletName: testWalletName,
    // //     networkType: BasicNetworkType.test,
    // //     client: client,
    // //     cachedClient: cachedClient,
    // //     priceAPI: priceAPI,
    // //     secureStore: secureStore,
    // //   );
    // //
    // //   // set node
    // //   final wallet = await Hive.openBox(testWalletId);
    // //   await wallet.put("nodes", {
    // //     "default": {
    // //       "id": "some nodeID",
    // //       "ipAddress": "some address",
    // //       "port": "9000",
    // //       "useSSL": true,
    // //     }
    // //   });
    // //   await wallet.put("activeNodeID_Bitcoin", "default");
    // //
    // //   final a = nmc.cachedElectrumXClient;
    // //
    // //   // return when refresh is called on node changed trigger
    // //   nmc.longMutex = true;
    // //
    // //   GlobalEventBus.instance
    // //       .fire(NodesChangedEvent(NodesChangedEventType.updatedCurrentNode));
    // //
    // //   // make sure event has processed before continuing
    // //   await Future.delayed(Duration(seconds: 5));
    // //
    // //   final b = nmc.cachedElectrumXClient;
    // //
    // //   expect(identical(a, b), false);
    // //
    // //   await nmc.exit();
    // //
    // //   expect(secureStore.interactions, 0);
    // //   verifyNoMoreInteractions(client);
    // //   verifyNoMoreInteractions(cachedClient);
    // //   verifyNoMoreInteractions(priceAPI);
    // // });

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
      when(client?.getBatchHistory(args: historyBatchArgs1))
          .thenAnswer((_) async => historyBatchResponse);
      when(client?.getBatchHistory(args: historyBatchArgs2))
          .thenAnswer((_) async => historyBatchResponse);
      when(client?.getBatchHistory(args: historyBatchArgs3))
          .thenAnswer((_) async => historyBatchResponse);
      when(client?.getBatchHistory(args: historyBatchArgs4))
          .thenAnswer((_) async => historyBatchResponse);
      when(client?.getBatchHistory(args: historyBatchArgs5))
          .thenAnswer((_) async => historyBatchResponse);

      List<dynamic> dynamicArgValues = [];

      when(client?.getBatchHistory(args: anyNamed("args")))
          .thenAnswer((realInvocation) async {
        if (realInvocation.namedArguments.values.first.length == 1) {
          dynamicArgValues.add(realInvocation.namedArguments.values.first);
        }

        return historyBatchResponse;
      });

      await Hive.openBox<dynamic>(testWalletId);

      // recover to fill data
      await part?.recoverFromMnemonic(
          mnemonic: TEST_MNEMONIC,
          maxUnusedAddressGap: 2,
          maxNumberOfIndexesToCheck: 1000,
          height: 4000);

      part?.refreshMutex = true;

      await part?.refresh();

      verify(client?.getServerFeatures()).called(1);
      verify(client?.getBatchHistory(args: historyBatchArgs0)).called(1);
      verify(client?.getBatchHistory(args: historyBatchArgs1)).called(1);
      verify(client?.getBatchHistory(args: historyBatchArgs2)).called(1);
      verify(client?.getBatchHistory(args: historyBatchArgs3)).called(1);
      verify(client?.getBatchHistory(args: historyBatchArgs4)).called(1);
      verify(client?.getBatchHistory(args: historyBatchArgs5)).called(1);

      for (final arg in dynamicArgValues) {
        final map = Map<String, List<dynamic>>.from(arg as Map);

        verify(client?.getBatchHistory(args: map)).called(1);
        expect(activeScriptHashes.contains(map.values.first.first as String),
            true);
      }

      expect(secureStore.interactions, 14);
      expect(secureStore.writes, 7);
      expect(secureStore.reads, 7);
      expect(secureStore.deletes, 0);

      verifyNoMoreInteractions(client);
      verifyNoMoreInteractions(cachedClient);
      verifyNoMoreInteractions(tracker);
      verifyNoMoreInteractions(priceAPI);
    });

    test("refresh wallet normally", () async {
      when(client?.getBlockHeadTip()).thenAnswer((realInvocation) async =>
          {"height": 520481, "hex": "some block hex"});
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
          .thenAnswer((_) async => []);
      when(client?.estimateFee(blocks: anyNamed("blocks")))
          .thenAnswer((_) async => Decimal.one);

      when(priceAPI?.getPricesAnd24hChange(baseCurrency: "USD"))
          .thenAnswer((_) async => {Coin.particl: Tuple2(Decimal.one, 0.3)});

      final List<dynamic> dynamicArgValues = [];

      when(client?.getBatchHistory(args: anyNamed("args")))
          .thenAnswer((realInvocation) async {
        dynamicArgValues.add(realInvocation.namedArguments.values.first);
        return historyBatchResponse;
      });

      await Hive.openBox<dynamic>(testWalletId);

      // recover to fill data
      await part?.recoverFromMnemonic(
          mnemonic: TEST_MNEMONIC,
          maxUnusedAddressGap: 2,
          maxNumberOfIndexesToCheck: 1000,
          height: 4000);

      when(client?.getBatchHistory(args: anyNamed("args")))
          .thenAnswer((_) async => {});
      when(client?.getBatchUTXOs(args: anyNamed("args")))
          .thenAnswer((_) async => emptyHistoryBatchResponse);

      await part?.refresh();

      verify(client?.getServerFeatures()).called(1);
      verify(client?.getHistory(scripthash: anyNamed("scripthash"))).called(4);
      verify(client?.estimateFee(blocks: anyNamed("blocks"))).called(3);
      verify(client?.getBlockHeadTip()).called(1);
      verify(priceAPI?.getPricesAnd24hChange(baseCurrency: "USD")).called(2);

      for (final arg in dynamicArgValues) {
        final map = Map<String, List<dynamic>>.from(arg as Map);

        verify(client?.getBatchHistory(args: map)).called(1);
      }

      expect(secureStore.interactions, 14);
      expect(secureStore.writes, 7);
      expect(secureStore.reads, 7);
      expect(secureStore.deletes, 0);

      verifyNoMoreInteractions(cachedClient);
      verifyNoMoreInteractions(priceAPI);
    });

    tearDown(() async {
      await tearDownTestHive();
    });
  });
}

import 'package:bitcoindart/bitcoindart.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:hive_test/hive_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:stackwallet/electrumx_rpc/cached_electrumx.dart';
import 'package:stackwallet/electrumx_rpc/electrumx.dart';
import 'package:stackwallet/models/paymint/fee_object_model.dart';
import 'package:stackwallet/models/paymint/transactions_model.dart';
import 'package:stackwallet/models/paymint/utxo_model.dart';
import 'package:stackwallet/services/coins/bitcoin/bitcoin_wallet.dart';
import 'package:stackwallet/services/price.dart';
import 'package:stackwallet/services/transaction_notification_tracker.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/utilities/flutter_secure_storage_interface.dart';

import 'bitcoin_history_sample_data.dart';
import 'bitcoin_transaction_data_samples.dart';
import 'bitcoin_utxo_sample_data.dart';
import 'bitcoin_wallet_test.mocks.dart';
import 'bitcoin_wallet_test_parameters.dart';

@GenerateMocks(
    [ElectrumX, CachedElectrumX, PriceAPI, TransactionNotificationTracker])
void main() {
  group("bitcoin constants", () {
    test("bitcoin minimum confirmations", () async {
      expect(MINIMUM_CONFIRMATIONS, 2);
    });
    test("bitcoin dust limit", () async {
      expect(DUST_LIMIT, 294);
    });
    test("bitcoin mainnet genesis block hash", () async {
      expect(GENESIS_HASH_MAINNET,
          "000000000019d6689c085ae165831e934ff763ae46a2a6c172b3f1b60a8ce26f");
    });
    test("bitcoin testnet genesis block hash", () async {
      expect(GENESIS_HASH_TESTNET,
          "000000000933ea01ad0ee984209779baaec3ced90fa3f408719526f8d77f4943");
    });
  });

  test("bitcoin DerivePathType enum", () {
    expect(DerivePathType.values.length, 3);
    expect(DerivePathType.values.toString(),
        "[DerivePathType.bip44, DerivePathType.bip49, DerivePathType.bip84]");
  });

  group("bip32 node/root", () {
    test("getBip32Root", () {
      final root = getBip32Root(TEST_MNEMONIC, bitcoin);
      expect(root.toWIF(), ROOT_WIF);
    });

    // test("getBip32NodeFromRoot", () {
    //   final root = getBip32Root(TEST_MNEMONIC, bitcoin);
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

    test("basic getBip32Node", () {
      final node =
          getBip32Node(0, 0, TEST_MNEMONIC, testnet, DerivePathType.bip84);
      expect(node.toWIF(), NODE_WIF_84);
    });
  });

  group("validate testnet bitcoin addresses", () {
    MockElectrumX? client;
    MockCachedElectrumX? cachedClient;
    MockPriceAPI? priceAPI;
    FakeSecureStorage? secureStore;
    MockTransactionNotificationTracker? tracker;

    BitcoinWallet? testnetWallet;

    setUp(() {
      client = MockElectrumX();
      cachedClient = MockCachedElectrumX();
      priceAPI = MockPriceAPI();
      secureStore = FakeSecureStorage();
      tracker = MockTransactionNotificationTracker();

      testnetWallet = BitcoinWallet(
        walletId: "validateAddressTestNet",
        walletName: "validateAddressTestNet",
        coin: Coin.bitcoinTestNet,
        client: client!,
        cachedClient: cachedClient!,
        tracker: tracker!,
        priceAPI: priceAPI,
        secureStore: secureStore,
      );
    });

    test("valid testnet bitcoin legacy/p2pkh address", () {
      expect(
          testnetWallet?.validateAddress("mhqpGtwhcR6gFuuRjLTpHo41919QfuGy8Y"),
          true);
      expect(secureStore?.interactions, 0);
      verifyNoMoreInteractions(client);
      verifyNoMoreInteractions(cachedClient);
      verifyNoMoreInteractions(priceAPI);
    });

    test("valid testnet bitcoin p2sh-p2wpkh address", () {
      expect(
          testnetWallet?.validateAddress("2Mugf9hpSYdQPPLNtWiU2utCi6cM9v5Pnro"),
          true);
      expect(secureStore?.interactions, 0);
      verifyNoMoreInteractions(client);
      verifyNoMoreInteractions(cachedClient);
      verifyNoMoreInteractions(priceAPI);
    });

    test("valid testnet bitcoin p2wpkh address", () {
      expect(
          testnetWallet
              ?.validateAddress("tb1qzzlm6mnc8k54mx6akehl8p9ray8r439va5ndyq"),
          true);
      expect(secureStore?.interactions, 0);
      verifyNoMoreInteractions(client);
      verifyNoMoreInteractions(cachedClient);
      verifyNoMoreInteractions(priceAPI);
    });

    test("invalid testnet bitcoin legacy/p2pkh address", () {
      expect(
          testnetWallet?.validateAddress("16YB85zQHjro7fqjR2hMcwdQWCX8jNVtr5"),
          false);
      expect(secureStore?.interactions, 0);
      verifyNoMoreInteractions(client);
      verifyNoMoreInteractions(cachedClient);
      verifyNoMoreInteractions(priceAPI);
    });

    test("invalid testnet bitcoin p2sh-p2wpkh address", () {
      expect(
          testnetWallet?.validateAddress("3Ns8HuQmkyyKnVixk2yQtG7pN3GcJ6xctk"),
          false);
      expect(secureStore?.interactions, 0);
      verifyNoMoreInteractions(client);
      verifyNoMoreInteractions(cachedClient);
      verifyNoMoreInteractions(priceAPI);
    });

    test("invalid testnet bitcoin p2wpkh address", () {
      expect(
          testnetWallet
              ?.validateAddress("bc1qc5ymmsay89r6gr4fy2kklvrkuvzyln4shdvjhf"),
          false);
      expect(secureStore?.interactions, 0);
      verifyNoMoreInteractions(client);
      verifyNoMoreInteractions(cachedClient);
      verifyNoMoreInteractions(priceAPI);
    });
  });

  group("validate mainnet bitcoin addresses", () {
    MockElectrumX? client;
    MockCachedElectrumX? cachedClient;
    MockPriceAPI? priceAPI;
    FakeSecureStorage? secureStore;
    MockTransactionNotificationTracker? tracker;

    BitcoinWallet? mainnetWallet;

    setUp(() {
      client = MockElectrumX();
      cachedClient = MockCachedElectrumX();
      priceAPI = MockPriceAPI();
      secureStore = FakeSecureStorage();
      tracker = MockTransactionNotificationTracker();

      mainnetWallet = BitcoinWallet(
        walletId: "validateAddressMainNet",
        walletName: "validateAddressMainNet",
        coin: Coin.bitcoin,
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
              address: "16YB85zQHjro7fqjR2hMcwdQWCX8jNVtr5"),
          DerivePathType.bip44);
      expect(secureStore?.interactions, 0);
      verifyNoMoreInteractions(client);
      verifyNoMoreInteractions(cachedClient);
      verifyNoMoreInteractions(tracker);
      verifyNoMoreInteractions(priceAPI);
    });

    test("valid mainnet p2sh-p2wpkh address type", () {
      expect(
          mainnetWallet?.addressType(
              address: "3Ns8HuQmkyyKnVixk2yQtG7pN3GcJ6xctk"),
          DerivePathType.bip49);
      expect(secureStore?.interactions, 0);
      verifyNoMoreInteractions(client);
      verifyNoMoreInteractions(cachedClient);
      verifyNoMoreInteractions(tracker);
      verifyNoMoreInteractions(priceAPI);
    });

    test("valid mainnet bech32 p2wpkh address type", () {
      expect(
          mainnetWallet?.addressType(
              address: "bc1qc5ymmsay89r6gr4fy2kklvrkuvzyln4shdvjhf"),
          DerivePathType.bip84);
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

    test("valid mainnet bitcoin legacy/p2pkh address", () {
      expect(
          mainnetWallet?.validateAddress("16YB85zQHjro7fqjR2hMcwdQWCX8jNVtr5"),
          true);
      expect(secureStore?.interactions, 0);
      verifyNoMoreInteractions(client);
      verifyNoMoreInteractions(cachedClient);
      verifyNoMoreInteractions(tracker);
      verifyNoMoreInteractions(priceAPI);
    });

    test("valid mainnet bitcoin p2sh-p2wpkh address", () {
      expect(
          mainnetWallet?.validateAddress("3Ns8HuQmkyyKnVixk2yQtG7pN3GcJ6xctk"),
          true);
      expect(secureStore?.interactions, 0);
      verifyNoMoreInteractions(client);
      verifyNoMoreInteractions(cachedClient);
      verifyNoMoreInteractions(tracker);
      verifyNoMoreInteractions(priceAPI);
    });

    test("valid mainnet bitcoin p2wpkh address", () {
      expect(
          mainnetWallet
              ?.validateAddress("bc1qc5ymmsay89r6gr4fy2kklvrkuvzyln4shdvjhf"),
          true);
      expect(secureStore?.interactions, 0);
      verifyNoMoreInteractions(client);
      verifyNoMoreInteractions(cachedClient);
      verifyNoMoreInteractions(tracker);
      verifyNoMoreInteractions(priceAPI);
    });

    test("invalid mainnet bitcoin legacy/p2pkh address", () {
      expect(
          mainnetWallet?.validateAddress("mhqpGtwhcR6gFuuRjLTpHo41919QfuGy8Y"),
          false);
      expect(secureStore?.interactions, 0);
      verifyNoMoreInteractions(client);
      verifyNoMoreInteractions(cachedClient);
      verifyNoMoreInteractions(tracker);
      verifyNoMoreInteractions(priceAPI);
    });

    test("invalid mainnet bitcoin p2sh-p2wpkh address", () {
      expect(
          mainnetWallet?.validateAddress("2Mugf9hpSYdQPPLNtWiU2utCi6cM9v5Pnro"),
          false);
      expect(secureStore?.interactions, 0);
      verifyNoMoreInteractions(client);
      verifyNoMoreInteractions(cachedClient);
      verifyNoMoreInteractions(tracker);
      verifyNoMoreInteractions(priceAPI);
    });

    test("invalid mainnet bitcoin p2wpkh address", () {
      expect(
          mainnetWallet
              ?.validateAddress("tb1qzzlm6mnc8k54mx6akehl8p9ray8r439va5ndyq"),
          false);
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

    BitcoinWallet? btc;

    setUp(() {
      client = MockElectrumX();
      cachedClient = MockCachedElectrumX();
      priceAPI = MockPriceAPI();
      secureStore = FakeSecureStorage();
      tracker = MockTransactionNotificationTracker();

      btc = BitcoinWallet(
        walletId: "testNetworkConnection",
        walletName: "testNetworkConnection",
        coin: Coin.bitcoin,
        client: client!,
        cachedClient: cachedClient!,
        tracker: tracker!,
        priceAPI: priceAPI,
        secureStore: secureStore,
      );
    });

    test("attempted connection fails due to server error", () async {
      when(client?.ping()).thenAnswer((_) async => false);
      final bool? result = await btc?.testNetworkConnection();
      expect(result, false);
      expect(secureStore?.interactions, 0);
      verify(client?.ping()).called(1);
      verifyNoMoreInteractions(client);
      verifyNoMoreInteractions(cachedClient);
      verifyNoMoreInteractions(priceAPI);
    });

    test("attempted connection fails due to exception", () async {
      when(client?.ping()).thenThrow(Exception);
      final bool? result = await btc?.testNetworkConnection();
      expect(result, false);
      expect(secureStore?.interactions, 0);
      verify(client?.ping()).called(1);
      verifyNoMoreInteractions(client);
      verifyNoMoreInteractions(cachedClient);
      verifyNoMoreInteractions(priceAPI);
    });

    test("attempted connection test success", () async {
      when(client?.ping()).thenAnswer((_) async => true);
      final bool? result = await btc?.testNetworkConnection();
      expect(result, true);
      expect(secureStore?.interactions, 0);
      verify(client?.ping()).called(1);
      verifyNoMoreInteractions(client);
      verifyNoMoreInteractions(cachedClient);
      verifyNoMoreInteractions(priceAPI);
    });
  });

  group("basic getters, setters, and functions", () {
    final testWalletId = "BTCtestWalletID";
    final testWalletName = "BTCWallet";

    MockElectrumX? client;
    MockCachedElectrumX? cachedClient;
    MockPriceAPI? priceAPI;
    FakeSecureStorage? secureStore;
    MockTransactionNotificationTracker? tracker;

    BitcoinWallet? btc;

    setUp(() async {
      client = MockElectrumX();
      cachedClient = MockCachedElectrumX();
      priceAPI = MockPriceAPI();
      secureStore = FakeSecureStorage();
      tracker = MockTransactionNotificationTracker();

      btc = BitcoinWallet(
        walletId: testWalletId,
        walletName: testWalletName,
        coin: Coin.bitcoin,
        client: client!,
        cachedClient: cachedClient!,
        tracker: tracker!,
        priceAPI: priceAPI,
        secureStore: secureStore,
      );
    });

    test("get networkType main", () async {
      expect(Coin.bitcoin, Coin.bitcoin);
      expect(secureStore?.interactions, 0);
      verifyNoMoreInteractions(client);
      verifyNoMoreInteractions(cachedClient);
      verifyNoMoreInteractions(priceAPI);
    });

    test("get networkType test", () async {
      btc = BitcoinWallet(
        walletId: testWalletId,
        walletName: testWalletName,
        coin: Coin.bitcoinTestNet,
        client: client!,
        cachedClient: cachedClient!,
        tracker: tracker!,
        priceAPI: priceAPI,
        secureStore: secureStore,
      );
      expect(Coin.bitcoinTestNet, Coin.bitcoinTestNet);
      expect(secureStore?.interactions, 0);
      verifyNoMoreInteractions(client);
      verifyNoMoreInteractions(cachedClient);
      verifyNoMoreInteractions(priceAPI);
    });

    test("get cryptoCurrency", () async {
      expect(Coin.bitcoin, Coin.bitcoin);
      expect(secureStore?.interactions, 0);
      verifyNoMoreInteractions(client);
      verifyNoMoreInteractions(cachedClient);
      verifyNoMoreInteractions(priceAPI);
    });

    test("get coinName", () async {
      expect(Coin.bitcoin, Coin.bitcoin);
      expect(secureStore?.interactions, 0);
      verifyNoMoreInteractions(client);
      verifyNoMoreInteractions(cachedClient);
      verifyNoMoreInteractions(priceAPI);
    });

    test("get coinTicker", () async {
      expect(Coin.bitcoin, Coin.bitcoin);
      expect(secureStore?.interactions, 0);
      verifyNoMoreInteractions(client);
      verifyNoMoreInteractions(cachedClient);
      verifyNoMoreInteractions(priceAPI);
    });

    test("get and set walletName", () async {
      expect(Coin.bitcoin, Coin.bitcoin);
      btc?.walletName = "new name";
      expect(btc?.walletName, "new name");
      expect(secureStore?.interactions, 0);
      verifyNoMoreInteractions(client);
      verifyNoMoreInteractions(cachedClient);
      verifyNoMoreInteractions(priceAPI);
    });

    test("estimateTxFee", () async {
      expect(btc?.estimateTxFee(vSize: 356, feeRatePerKB: 1), 356);
      expect(btc?.estimateTxFee(vSize: 356, feeRatePerKB: 900), 356);
      expect(btc?.estimateTxFee(vSize: 356, feeRatePerKB: 999), 356);
      expect(btc?.estimateTxFee(vSize: 356, feeRatePerKB: 1000), 356);
      expect(btc?.estimateTxFee(vSize: 356, feeRatePerKB: 1001), 712);
      expect(btc?.estimateTxFee(vSize: 356, feeRatePerKB: 1699), 712);
      expect(btc?.estimateTxFee(vSize: 356, feeRatePerKB: 2000), 712);
      expect(btc?.estimateTxFee(vSize: 356, feeRatePerKB: 12345), 4628);
      expect(secureStore?.interactions, 0);
      verifyNoMoreInteractions(client);
      verifyNoMoreInteractions(cachedClient);
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

      final fees = await btc?.fees;
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
        await btc?.fees;
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
      verifyNoMoreInteractions(priceAPI);
    });

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
    //   final maxFee = await btc?.maxFee;
    //   expect(maxFee, 1000000000);
    //
    //   verify(client?.estimateFee(blocks: 1)).called(1);
    //   verify(client?.estimateFee(blocks: 5)).called(1);
    //   verify(client?.estimateFee(blocks: 20)).called(1);
    //   expect(secureStore?.interactions, 0);
    //   verifyNoMoreInteractions(client);
    //   verifyNoMoreInteractions(cachedClient);
    //   verifyNoMoreInteractions(tracker);
    //   verifyNoMoreInteractions(priceAPI);
    // });
  });

  group("Bitcoin service class functions that depend on shared storage", () {
    final testWalletId = "BTCtestWalletID";
    final testWalletName = "BTCWallet";

    bool hiveAdaptersRegistered = false;

    MockElectrumX? client;
    MockCachedElectrumX? cachedClient;
    MockPriceAPI? priceAPI;
    FakeSecureStorage? secureStore;
    MockTransactionNotificationTracker? tracker;

    BitcoinWallet? btc;

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

      btc = BitcoinWallet(
        walletId: testWalletId,
        walletName: testWalletName,
        coin: Coin.bitcoin,
        client: client!,
        cachedClient: cachedClient!,
        tracker: tracker!,
        priceAPI: priceAPI,
        secureStore: secureStore,
      );
    });

    // test("initializeWallet no network", () async {
    //   when(client?.ping()).thenAnswer((_) async => false);
    //   expect(await btc?.initializeWallet(), false);
    //   expect(secureStore?.interactions, 0);
    //   verify(client?.ping()).called(1);
    //   verifyNoMoreInteractions(client);
    //   verifyNoMoreInteractions(cachedClient);
    //   verifyNoMoreInteractions(priceAPI);
    // });

    // test("initializeWallet no network exception", () async {
    //   when(client?.ping()).thenThrow(Exception("Network connection failed"));
    //   final wallets = await Hive.openBox(testWalletId);
    //   expect(await btc?.initializeExisting(), false);
    //   expect(secureStore?.interactions, 0);
    //   verify(client?.ping()).called(1);
    //   verifyNoMoreInteractions(client);
    //   verifyNoMoreInteractions(cachedClient);
    //   verifyNoMoreInteractions(priceAPI);
    // });

    test("initializeWallet mainnet throws bad network", () async {
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
      // await btc?.initializeNew();
      final wallets = await Hive.openBox(testWalletId);

      expectLater(() => btc?.initializeExisting(), throwsA(isA<Exception>()))
          .then((_) {
        expect(secureStore?.interactions, 0);
        // verify(client?.ping()).called(1);
        // verify(client?.getServerFeatures()).called(1);
        verifyNoMoreInteractions(client);
        verifyNoMoreInteractions(cachedClient);
        verifyNoMoreInteractions(priceAPI);
      });
    });

    test("initializeWallet throws mnemonic overwrite exception", () async {
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
      await secureStore?.write(
          key: "${testWalletId}_mnemonic", value: "some mnemonic");

      final wallets = await Hive.openBox(testWalletId);
      expectLater(() => btc?.initializeExisting(), throwsA(isA<Exception>()))
          .then((_) {
        expect(secureStore?.interactions, 1);
        // verify(client?.ping()).called(1);
        // verify(client?.getServerFeatures()).called(1);
        verifyNoMoreInteractions(client);
        verifyNoMoreInteractions(cachedClient);
        verifyNoMoreInteractions(priceAPI);
      });
    });

    // test("initializeWallet testnet throws bad network", () async {
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
    //
    //   btc = BitcoinWallet(
    //     walletId: testWalletId,
    //     walletName: testWalletName,
    //     coin: Coin.bitcoinTestNet,
    //     client: client!,
    //     cachedClient: cachedClient!,
    //     tracker: tracker!,
    //     priceAPI: priceAPI,
    //     secureStore: secureStore,
    //   );
    //
    //   expectLater(() => btc?.initializeWallet(), throwsA(isA<Exception>()))
    //       .then((_) {
    //     expect(secureStore?.interactions, 0);
    //     verify(client?.ping()).called(1);
    //     verify(client?.getServerFeatures()).called(1);
    //     verifyNoMoreInteractions(client);
    //     verifyNoMoreInteractions(cachedClient);
    //     verifyNoMoreInteractions(priceAPI);
    //   });
    // });

    // test("getCurrentNode", () async {
    //   // when(priceAPI.getBitcoinPrice(baseCurrency: "USD"))
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
    //   expect(await btc?.initializeWallet(), true);
    //
    //   bool didThrow = false;
    //   try {
    //     await btc?.getCurrentNode();
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
    //   await wallet.put("activeNodeID_Bitcoin", "default");
    //
    //   // try fetching again
    //   final node = await btc?.getCurrentNode();
    //   expect(node.toString(),
    //       "ElectrumXNode: {address: some address, port: 9000, name: default, useSSL: true}");
    //
    //   verify(client?.ping()).called(1);
    //   verify(client?.getServerFeatures()).called(1);
    //   verifyNoMoreInteractions(client);
    //   verifyNoMoreInteractions(cachedClient);
    //   verifyNoMoreInteractions(priceAPI);
    // });
    //
    // test("initializeWallet new main net wallet", () async {
    //   // when(priceAPI.getBitcoinPrice(baseCurrency: "USD"))
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
    //   expect(await btc?.initializeWallet(), true);
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
    //   final changeAddressesP2SH = await wallet.get("changeAddressesP2SH");
    //   expect(changeAddressesP2SH, isA<List<String>>());
    //   expect(changeAddressesP2SH.length, 1);
    //   expect(await wallet.get("changeIndexP2SH"), 0);
    //   final changeAddressesP2WPKH = await wallet.get("changeAddressesP2WPKH");
    //   expect(changeAddressesP2WPKH, isA<List<String>>());
    //   expect(changeAddressesP2WPKH.length, 1);
    //   expect(await wallet.get("changeIndexP2WPKH"), 0);
    //
    //   final receivingAddressesP2PKH =
    //       await wallet.get("receivingAddressesP2PKH");
    //   expect(receivingAddressesP2PKH, isA<List<String>>());
    //   expect(receivingAddressesP2PKH.length, 1);
    //   expect(await wallet.get("receivingIndexP2PKH"), 0);
    //   final receivingAddressesP2SH = await wallet.get("receivingAddressesP2SH");
    //   expect(receivingAddressesP2SH, isA<List<String>>());
    //   expect(receivingAddressesP2SH.length, 1);
    //   expect(await wallet.get("receivingIndexP2SH"), 0);
    //   final receivingAddressesP2WPKH =
    //       await wallet.get("receivingAddressesP2WPKH");
    //   expect(receivingAddressesP2WPKH, isA<List<String>>());
    //   expect(receivingAddressesP2WPKH.length, 1);
    //   expect(await wallet.get("receivingIndexP2WPKH"), 0);
    //
    //   final p2pkhReceiveDerivations = jsonDecode(await secureStore?.read(
    //       key: "${testWalletId}_receiveDerivationsP2PKH"));
    //   expect(p2pkhReceiveDerivations.length, 1);
    //   final p2shReceiveDerivations = jsonDecode(await secureStore.read(
    //       key: "${testWalletId}_receiveDerivationsP2SH"));
    //   expect(p2shReceiveDerivations.length, 1);
    //   final p2wpkhReceiveDerivations = jsonDecode(await secureStore.read(
    //       key: "${testWalletId}_receiveDerivationsP2WPKH"));
    //   expect(p2wpkhReceiveDerivations.length, 1);
    //
    //   final p2pkhChangeDerivations = jsonDecode(await secureStore.read(
    //       key: "${testWalletId}_changeDerivationsP2PKH"));
    //   expect(p2pkhChangeDerivations.length, 1);
    //   final p2shChangeDerivations = jsonDecode(
    //       await secureStore.read(key: "${testWalletId}_changeDerivationsP2SH"));
    //   expect(p2shChangeDerivations.length, 1);
    //   final p2wpkhChangeDerivations = jsonDecode(await secureStore.read(
    //       key: "${testWalletId}_changeDerivationsP2WPKH"));
    //   expect(p2wpkhChangeDerivations.length, 1);
    //
    //   expect(secureStore?.interactions, 26); // 20 in reality + 6 in this test
    //   expect(secureStore?.reads, 19); // 13 in reality + 6 in this test
    //   expect(secureStore?.writes, 7);
    //   expect(secureStore?.deletes, 0);
    //   verify(client?.ping()).called(1);
    //   verify(client?.getServerFeatures()).called(1);
    //   verifyNoMoreInteractions(client);
    //   verifyNoMoreInteractions(cachedClient);
    //   verifyNoMoreInteractions(priceAPI);
    // });
    //
    // test("initializeWallet existing main net wallet", () async {
    //   // when(priceAPI.getBitcoinPrice(baseCurrency: "USD"))
    //   //     .thenAnswer((realInvocation) async => Decimal.fromInt(10));
    //   when(client?.ping()).thenAnswer((_) async => true);
    //   when(client?.getBatchHistory(args: anyNamed("args")))
    //       .thenAnswer((_) async => {});
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
    //   // init new wallet
    //   expect(await btc?.initializeWallet(), true);
    //
    //   // fetch data to compare later
    //   final newWallet = await Hive.openBox(testWalletId);
    //
    //   final addressBookEntries = await newWallet.get("addressBookEntries");
    //   final notes = await newWallet.get('notes');
    //   final wID = await newWallet.get("id");
    //   final currency = await newWallet.get("preferredFiatCurrency");
    //   final blockedHashes = await newWallet.get("blocked_tx_hashes");
    //
    //   final changeAddressesP2PKH = await newWallet.get("changeAddressesP2PKH");
    //   final changeIndexP2PKH = await newWallet.get("changeIndexP2PKH");
    //   final changeAddressesP2SH = await newWallet.get("changeAddressesP2SH");
    //   final changeIndexP2SH = await newWallet.get("changeIndexP2SH");
    //   final changeAddressesP2WPKH =
    //       await newWallet.get("changeAddressesP2WPKH");
    //   final changeIndexP2WPKH = await newWallet.get("changeIndexP2WPKH");
    //
    //   final receivingAddressesP2PKH =
    //       await newWallet.get("receivingAddressesP2PKH");
    //   final receivingIndexP2PKH = await newWallet.get("receivingIndexP2PKH");
    //   final receivingAddressesP2SH =
    //       await newWallet.get("receivingAddressesP2SH");
    //   final receivingIndexP2SH = await newWallet.get("receivingIndexP2SH");
    //   final receivingAddressesP2WPKH =
    //       await newWallet.get("receivingAddressesP2WPKH");
    //   final receivingIndexP2WPKH = await newWallet.get("receivingIndexP2WPKH");
    //
    //   final p2pkhReceiveDerivations = jsonDecode(await secureStore.read(
    //       key: "${testWalletId}_receiveDerivationsP2PKH"));
    //   final p2shReceiveDerivations = jsonDecode(await secureStore.read(
    //       key: "${testWalletId}_receiveDerivationsP2SH"));
    //   final p2wpkhReceiveDerivations = jsonDecode(await secureStore.read(
    //       key: "${testWalletId}_receiveDerivationsP2WPKH"));
    //
    //   final p2pkhChangeDerivations = jsonDecode(await secureStore.read(
    //       key: "${testWalletId}_changeDerivationsP2PKH"));
    //   final p2shChangeDerivations = jsonDecode(
    //       await secureStore.read(key: "${testWalletId}_changeDerivationsP2SH"));
    //   final p2wpkhChangeDerivations = jsonDecode(await secureStore.read(
    //       key: "${testWalletId}_changeDerivationsP2WPKH"));
    //
    //   // exit new wallet
    //   await btc?.exit();
    //
    //   // open existing/created wallet
    //   btc = BitcoinWallet(
    //     walletId: testWalletId,
    //     walletName: testWalletName,
    //     coin: Coin.bitcoin,
    //     client: client!,
    //     cachedClient: cachedClient!,
    //     tracker: tracker!,
    //     priceAPI: priceAPI,
    //     secureStore: secureStore,
    //   );
    //
    //   // init existing
    //   expect(await btc?.initializeWallet(), true);
    //
    //   // compare data to ensure state matches state of previously closed wallet
    //   final wallet = await Hive.openBox(testWalletId);
    //
    //   expect(await wallet.get("addressBookEntries"), addressBookEntries);
    //   expect(await wallet.get('notes'), notes);
    //   expect(await wallet.get("id"), wID);
    //   expect(await wallet.get("preferredFiatCurrency"), currency);
    //   expect(await wallet.get("blocked_tx_hashes"), blockedHashes);
    //
    //   expect(await wallet.get("changeAddressesP2PKH"), changeAddressesP2PKH);
    //   expect(await wallet.get("changeIndexP2PKH"), changeIndexP2PKH);
    //   expect(await wallet.get("changeAddressesP2SH"), changeAddressesP2SH);
    //   expect(await wallet.get("changeIndexP2SH"), changeIndexP2SH);
    //   expect(await wallet.get("changeAddressesP2WPKH"), changeAddressesP2WPKH);
    //   expect(await wallet.get("changeIndexP2WPKH"), changeIndexP2WPKH);
    //
    //   expect(
    //       await wallet.get("receivingAddressesP2PKH"), receivingAddressesP2PKH);
    //   expect(await wallet.get("receivingIndexP2PKH"), receivingIndexP2PKH);
    //   expect(
    //       await wallet.get("receivingAddressesP2SH"), receivingAddressesP2SH);
    //   expect(await wallet.get("receivingIndexP2SH"), receivingIndexP2SH);
    //   expect(await wallet.get("receivingAddressesP2WPKH"),
    //       receivingAddressesP2WPKH);
    //   expect(await wallet.get("receivingIndexP2WPKH"), receivingIndexP2WPKH);
    //
    //   expect(
    //       jsonDecode(await secureStore.read(
    //           key: "${testWalletId}_receiveDerivationsP2PKH")),
    //       p2pkhReceiveDerivations);
    //   expect(
    //       jsonDecode(await secureStore.read(
    //           key: "${testWalletId}_receiveDerivationsP2SH")),
    //       p2shReceiveDerivations);
    //   expect(
    //       jsonDecode(await secureStore.read(
    //           key: "${testWalletId}_receiveDerivationsP2WPKH")),
    //       p2wpkhReceiveDerivations);
    //
    //   expect(
    //       jsonDecode(await secureStore.read(
    //           key: "${testWalletId}_changeDerivationsP2PKH")),
    //       p2pkhChangeDerivations);
    //   expect(
    //       jsonDecode(await secureStore.read(
    //           key: "${testWalletId}_changeDerivationsP2SH")),
    //       p2shChangeDerivations);
    //   expect(
    //       jsonDecode(await secureStore.read(
    //           key: "${testWalletId}_changeDerivationsP2WPKH")),
    //       p2wpkhChangeDerivations);
    //
    //   expect(secureStore?.interactions, 32); // 20 in reality + 12 in this test
    //   expect(secureStore?.reads, 25); // 13 in reality + 12 in this test
    //   expect(secureStore?.writes, 7);
    //   expect(secureStore?.deletes, 0);
    //   verify(client?.ping()).called(2);
    //   verify(client?.getServerFeatures()).called(1);
    //   verifyNoMoreInteractions(client);
    //   verifyNoMoreInteractions(cachedClient);
    //   verifyNoMoreInteractions(priceAPI);
    // });
    //
    // // test("get fiatPrice", () async {
    // //   // when(priceAPI.getBitcoinPrice(baseCurrency: "USD"))
    // //   //     .thenAnswer((realInvocation) async => Decimal.fromInt(10));
    // //   await Hive.openBox(testWalletId);
    // //   expect(await btc.basePrice, Decimal.fromInt(10));
    // //   verify(priceAPI.getBitcoinPrice(baseCurrency: "USD")).called(1);
    // //   verifyNoMoreInteractions(client);
    // //   verifyNoMoreInteractions(cachedClient);
    // //   verifyNoMoreInteractions(priceAPI);
    // // });
    //
    // test("get current receiving addresses", () async {
    //   btc = BitcoinWallet(
    //     walletId: testWalletId,
    //     walletName: testWalletName,
    //     coin: Coin.bitcoinTestNet,
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
    //   await btc?.initializeWallet();
    //   expect(
    //       Address.validateAddress(await btc!.currentReceivingAddress, testnet),
    //       true);
    //   expect(
    //       Address.validateAddress(
    //           await btc!.currentReceivingAddressP2SH, testnet),
    //       true);
    //   expect(
    //       Address.validateAddress(
    //           await btc!.currentLegacyReceivingAddress, testnet),
    //       true);
    //
    //   verify(client?.ping()).called(1);
    //   verify(client?.getServerFeatures()).called(1);
    //   verifyNoMoreInteractions(client);
    //   verifyNoMoreInteractions(cachedClient);
    //   verifyNoMoreInteractions(priceAPI);
    // });
    //
    // test("get allOwnAddresses", () async {
    //   btc = BitcoinWallet(
    //     walletId: testWalletId,
    //     walletName: testWalletName,
    //     coin: Coin.bitcoinTestNet,
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
    //   await btc?.initializeWallet();
    //   final addresses = await btc?.allOwnAddresses;
    //   expect(addresses, isA<List<String>>());
    //   expect(addresses?.length, 6);
    //
    //   for (int i = 0; i < 6; i++) {
    //     expect(Address.validateAddress(addresses[i], testnet), true);
    //   }
    //
    //   verify(client?.ping()).called(1);
    //   verify(client?.getServerFeatures()).called(1);
    //   verifyNoMoreInteractions(client);
    //   verifyNoMoreInteractions(cachedClient);
    //   verifyNoMoreInteractions(priceAPI);
    // });

    // test("get utxos and balances", () async {
    //   btc = BitcoinWallet(
    //     walletId: testWalletId,
    //     walletName: testWalletName,
    //     coin: Coin.bitcoinTestNet,
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
    //   when(client?.getBatchUTXOs(args: anyNamed("args")))
    //       .thenAnswer((_) async => batchGetUTXOResponse0);
    //
    //   when(client?.estimateFee(blocks: 10))
    //       .thenAnswer((realInvocation) async => Decimal.zero);
    //   when(client?.estimateFee(blocks: 5))
    //       .thenAnswer((realInvocation) async => Decimal.one);
    //   when(client?.estimateFee(blocks: 1))
    //       .thenAnswer((realInvocation) async => Decimal.ten);
    //   // when(priceAPI.getBitcoinPrice(baseCurrency: "USD"))
    //   //     .thenAnswer((realInvocation) async => Decimal.fromInt(10));
    //
    //   when(cachedClient?.getTransaction(
    //           txHash: tx1.txid,
    //           coin: Coin.bitcoinTestNet,
    //           callOutSideMainIsolate: false))
    //       .thenAnswer((_) async => tx1Raw);
    //   when(cachedClient?.getTransaction(
    //           txHash: tx2.txid,
    //           coin: Coin.bitcoinTestNet,
    //           callOutSideMainIsolate: false))
    //       .thenAnswer((_) async => tx2Raw);
    //   when(cachedClient?.getTransaction(
    //           txHash: tx3.txid,
    //           coin: Coin.bitcoinTestNet,
    //           callOutSideMainIsolate: false))
    //       .thenAnswer((_) async => tx3Raw);
    //   when(cachedClient?.getTransaction(
    //           txHash: tx4.txid,
    //           coin: Coin.bitcoinTestNet,
    //           callOutSideMainIsolate: false))
    //       .thenAnswer((_) async => tx4Raw);
    //
    //   await btc?.initializeNew();
    //   await btc?.initializeExisting();
    //   final utxoData = await btc?.utxoData;
    //   expect(utxoData, isA<UtxoData>());
    //   expect(utxoData.toString(),
    //       r"{totalUserCurrency: $0.0076497, satoshiBalance: 76497, bitcoinBalance: 0.00076497, unspentOutputArray: [{txid: 88b7b5077d940dde1bc63eba37a09dec8e7b9dad14c183a2e879a21b6ec0ac1c, vout: 0, value: 17000, fiat: $0.0017, blocked: false, status: {confirmed: true, blockHash: 00000000000000198ca8300deab26c5c1ec1df0da5afd30c9faabd340d8fc194, blockHeight: 437146, blockTime: 1652994245, confirmations: 100}}, {txid: b2f75a017a7435f1b8c2e080a865275d8f80699bba68d8dce99a94606e7b3528, vout: 0, value: 36037, fiat: $0.0036037, blocked: false, status: {confirmed: false, blockHash: 000000000000003db63ad679a539f2088dcc97a149c99ca790ce0c5f7b5acff0, blockHeight: 441696, blockTime: 1652923129, confirmations: 0}}, {txid: dcca229760b44834478f0b266c9b3f5801e0139fdecacdc0820e447289a006d3, vout: 1, value: 14714, fiat: $0.0014714, blocked: false, status: {confirmed: false, blockHash: 0000000000000030bec9bc58a3ab4857de1cc63cfed74204a6be57f125fb2fa7, blockHeight: 437146, blockTime: 1652888705, confirmations: 0}}, {txid: b39bac02b65af46a49e2985278fe24ca00dd5d627395d88f53e35568a04e10fa, vout: 0, value: 8746, fiat: $0.0008746, blocked: false, status: {confirmed: true, blockHash: 0000000039b80e9a10b7bcaf0f193b51cb870a4febe9b427c1f41a3f42eaa80b, blockHeight: 441696, blockTime: 1652993683, confirmations: 22861}}]}");
    //
    //   final outputs = await btc?.unspentOutputs;
    //   expect(outputs, isA<List<UtxoObject>>());
    //   expect(outputs?.length, 4);
    //
    //   final availableBalance = await btc?.availableBalance;
    //   expect(availableBalance, Decimal.parse("0.00025746"));
    //
    //   final totalBalance = await btc?.totalBalance;
    //   expect(totalBalance, Decimal.parse("0.00076497"));
    //
    //   final pendingBalance = await btc?.pendingBalance;
    //   expect(pendingBalance, Decimal.parse("0.00050751"));
    //
    //   final balanceMinusMaxFee = await btc?.balanceMinusMaxFee;
    //   expect(balanceMinusMaxFee, Decimal.parse("-9.99974254"));
    //
    //   verify(client?.ping()).called(1);
    //   verify(client?.getServerFeatures()).called(1);
    //   verify(client?.estimateFee(blocks: 1)).called(1);
    //   verify(client?.estimateFee(blocks: 5)).called(1);
    //   verify(client?.estimateFee(blocks: 10)).called(1);
    //   verify(client?.getBatchUTXOs(args: anyNamed("args"))).called(1);
    //   // verify(priceAPI.getBitcoinPrice(baseCurrency: "USD")).called(1);
    //   verify(cachedClient?.getTransaction(
    //           txHash: tx1.txid,
    //           coin: Coin.bitcoinTestNet,
    //           callOutSideMainIsolate: false))
    //       .called(1);
    //   verify(cachedClient?.getTransaction(
    //           txHash: tx2.txid,
    //           coin: Coin.bitcoinTestNet,
    //           callOutSideMainIsolate: false))
    //       .called(1);
    //   verify(cachedClient?.getTransaction(
    //           txHash: tx3.txid,
    //           coin: Coin.bitcoinTestNet,
    //           callOutSideMainIsolate: false))
    //       .called(1);
    //   verify(cachedClient?.getTransaction(
    //           txHash: tx4.txid,
    //           coin: Coin.bitcoinTestNet,
    //           callOutSideMainIsolate: false))
    //       .called(1);
    //
    //   verifyNoMoreInteractions(client);
    //   verifyNoMoreInteractions(cachedClient);
    //   verifyNoMoreInteractions(priceAPI);
    // });

    // test("get utxos - multiple batches", () async {
    //   btc = BitcoinWallet(
    //     walletId: testWalletId,
    //     walletName: testWalletName,
    //     coin: Coin.bitcoinTestNet,
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
    //   when(client?.getBatchUTXOs(args: anyNamed("args")))
    //       .thenAnswer((_) async => {});
    //
    //   // when(priceAPI.getBitcoinPrice(baseCurrency: "USD"))
    //   //     .thenAnswer((realInvocation) async => Decimal.fromInt(10));
    //
    //   await btc?.initializeNew();
    //   await btc?.initializeExisting();
    //
    //   // add some extra addresses to make sure we have more than the single batch size of 10
    //   final wallet = await Hive.openBox(DB);
    //   final addresses = await wallet.get("receivingAddressesP2WPKH");
    //   addresses.add("tb1qpfl2uz3jvazy9wr4vqhwluyhgtd29rsmghpqxp");
    //   addresses.add("tb1qznt3psdpcyz8lwj7xxl6q78hjw2mj095nd4gxu");
    //   addresses.add("tb1q7yjjyh9h4uy7j0wdtcmptw3g083kxrqlvgjz86");
    //   addresses.add("tb1qt05shktwcq7kgxccva20cfwt47kav9s6n8yr9p");
    //   addresses.add("tb1q4nk5wdylywl4dg2a45naae7u08vtgyujqfrv58");
    //   addresses.add("tb1qxwccgfq9tmd6lx823cuejuea9wdzpaml9wkapm");
    //   addresses.add("tb1qk88negkdqusr8tpj0hpvs98lq6ka4vyw6kfnqf");
    //   addresses.add("tb1qw0jzneqwp0t4ah9w3za4k9d8d4tz8y3zxqmtgx");
    //   addresses.add("tb1qccqjlpndx46sv7t6uurlyyjre5vwjfdzzlf2vd");
    //   addresses.add("tb1q3hfpe69rrhr5348xd04rfz9g3h22yk64pwur8v");
    //   addresses.add("tb1q4rp373202aur96a28lp0pmts6kp456nka45e7d");
    //   await wallet.put("receivingAddressesP2WPKH", addresses);
    //
    //   final utxoData = await btc?.utxoData;
    //   expect(utxoData, isA<UtxoData>());
    //
    //   final outputs = await btc?.unspentOutputs;
    //   expect(outputs, isA<List<UtxoObject>>());
    //   expect(outputs?.length, 0);
    //
    //   verify(client?.ping()).called(1);
    //   verify(client?.getServerFeatures()).called(1);
    //   verify(client?.getBatchUTXOs(args: anyNamed("args"))).called(2);
    //   // verify(priceAPI.getBitcoinPrice(baseCurrency: "USD")).called(1);
    //
    //   verifyNoMoreInteractions(client);
    //   verifyNoMoreInteractions(cachedClient);
    //   verifyNoMoreInteractions(priceAPI);
    // });
    //
    // test("get utxos fails", () async {
    //   btc = BitcoinWallet(
    //     walletId: testWalletId,
    //     walletName: testWalletName,
    //     coin: Coin.bitcoinTestNet,
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
    //   when(client?.getBatchUTXOs(args: anyNamed("args")))
    //       .thenThrow(Exception("some exception"));
    //
    //   await btc?.initializeWallet();
    //   final utxoData = await btc?.utxoData;
    //   expect(utxoData, isA<UtxoData>());
    //   expect(utxoData.toString(),
    //       r"{totalUserCurrency: $0.00, satoshiBalance: 0, bitcoinBalance: 0, unspentOutputArray: []}");
    //
    //   final outputs = await btc?.unspentOutputs;
    //   expect(outputs, isA<List<UtxoObject>>());
    //   expect(outputs?.length, 0);
    //
    //   verify(client?.ping()).called(1);
    //   verify(client?.getServerFeatures()).called(1);
    //   verify(client?.getBatchUTXOs(args: anyNamed("args"))).called(1);
    //
    //   verifyNoMoreInteractions(client);
    //   verifyNoMoreInteractions(cachedClient);
    //   verifyNoMoreInteractions(priceAPI);
    // });
    //
    // test("chain height fetch, update, and get", () async {
    //   btc = BitcoinWallet(
    //     walletId: testWalletId,
    //     walletName: testWalletName,
    //     coin: Coin.bitcoinTestNet,
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
    //   await btc?.initializeWallet();
    //
    //   // get stored
    //   expect(await btc?.storedChainHeight, 0);
    //
    //   // fetch fails
    //   when(client?.getBlockHeadTip()).thenThrow(Exception("Some exception"));
    //   expect(await btc?.chainHeight, -1);
    //
    //   // fetch succeeds
    //   when(client?.getBlockHeadTip()).thenAnswer((realInvocation) async => {
    //         "height": 100,
    //         "hex": "some block hex",
    //       });
    //   expect(await btc?.chainHeight, 100);
    //
    //   // update
    //   await btc?.updateStoredChainHeight(newHeight: 1000);
    //
    //   // fetch updated
    //   expect(await btc?.storedChainHeight, 1000);
    //
    //   verify(client?.ping()).called(1);
    //   verify(client?.getServerFeatures()).called(1);
    //   verify(client?.getBlockHeadTip()).called(2);
    //   verifyNoMoreInteractions(client);
    //   verifyNoMoreInteractions(cachedClient);
    //   verifyNoMoreInteractions(priceAPI);
    // });
    //
    // test("fetch and update useBiometrics", () async {
    //   // get
    //   expect(await btc?.useBiometrics, false);
    //
    //   // then update
    //   await btc?.updateBiometricsUsage(true);
    //
    //   // finally check updated
    //   expect(await btc?.useBiometrics, true);
    //
    //   expect(secureStore?.interactions, 0);
    //   verifyNoMoreInteractions(client);
    //   verifyNoMoreInteractions(cachedClient);
    //   verifyNoMoreInteractions(priceAPI);
    // });
    //
    // test("getTxCount succeeds", () async {
    //   when(client?.getHistory(
    //           scripthash:
    //               "4e94cc7b4a85791445260ae4403233b6a4784185f9716d73f136c6642615fce9"))
    //       .thenAnswer((realInvocation) async => [
    //             {
    //               "height": 200004,
    //               "tx_hash":
    //                   "acc3758bd2a26f869fcc67d48ff30b96464d476bca82c1cd6656e7d506816412"
    //             },
    //             {
    //               "height": 215008,
    //               "tx_hash":
    //                   "f3e1bf48975b8d6060a9de8884296abb80be618dc00ae3cb2f6cee3085e09403"
    //             }
    //           ]);
    //
    //   final count =
    //       await btc?.getTxCount(address: "3Ns8HuQmkyyKnVixk2yQtG7pN3GcJ6xctk");
    //
    //   expect(count, 2);
    //
    //   verify(client?.getHistory(
    //           scripthash:
    //               "4e94cc7b4a85791445260ae4403233b6a4784185f9716d73f136c6642615fce9"))
    //       .called(1);
    //
    //   expect(secureStore?.interactions, 0);
    //   verifyNoMoreInteractions(client);
    //   verifyNoMoreInteractions(cachedClient);
    //   verifyNoMoreInteractions(priceAPI);
    // });
    //
    // test("getTxCount fails", () async {
    //   when(client?.getHistory(
    //           scripthash:
    //               "4e94cc7b4a85791445260ae4403233b6a4784185f9716d73f136c6642615fce9"))
    //       .thenThrow(Exception("some exception"));
    //
    //   bool didThrow = false;
    //   try {
    //     await btc?.getTxCount(address: "3Ns8HuQmkyyKnVixk2yQtG7pN3GcJ6xctk");
    //   } catch (_) {
    //     didThrow = true;
    //   }
    //   expect(didThrow, true);
    //
    //   verify(client?.getHistory(
    //           scripthash:
    //               "4e94cc7b4a85791445260ae4403233b6a4784185f9716d73f136c6642615fce9"))
    //       .called(1);
    //
    //   expect(secureStore?.interactions, 0);
    //   verifyNoMoreInteractions(client);
    //   verifyNoMoreInteractions(cachedClient);
    //   verifyNoMoreInteractions(priceAPI);
    // });
    //
    // test("_checkCurrentReceivingAddressesForTransactions succeeds", () async {
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
    //   when(client?.getHistory(scripthash: anyNamed("scripthash")))
    //       .thenAnswer((realInvocation) async => [
    //             {
    //               "height": 200004,
    //               "tx_hash":
    //                   "acc3758bd2a26f869fcc67d48ff30b96464d476bca82c1cd6656e7d506816412"
    //             },
    //             {
    //               "height": 215008,
    //               "tx_hash":
    //                   "f3e1bf48975b8d6060a9de8884296abb80be618dc00ae3cb2f6cee3085e09403"
    //             }
    //           ]);
    //
    //   await btc?.initializeWallet();
    //
    //   bool didThrow = false;
    //   try {
    //     await btc?.checkCurrentReceivingAddressesForTransactions();
    //   } catch (_) {
    //     didThrow = true;
    //   }
    //   expect(didThrow, false);
    //
    //   verify(client?.getHistory(scripthash: anyNamed("scripthash"))).called(3);
    //   verify(client?.getServerFeatures()).called(1);
    //   verify(client?.ping()).called(1);
    //
    //   expect(secureStore?.interactions, 29);
    //   expect(secureStore?.reads, 19);
    //   expect(secureStore?.writes, 10);
    //   expect(secureStore?.deletes, 0);
    //   verifyNoMoreInteractions(client);
    //   verifyNoMoreInteractions(cachedClient);
    //   verifyNoMoreInteractions(priceAPI);
    // });

    // test("_checkCurrentReceivingAddressesForTransactions fails", () async {
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
    //   when(client?.getHistory(scripthash: anyNamed("scripthash")))
    //       .thenThrow(Exception("some exception"));
    //   final wallet = await Hive.openBox(testWalletId);
    //
    //   await btc?.initializeNew();
    //   await btc?.initializeExisting();
    //
    //   bool didThrow = false;
    //   try {
    //     await btc?.checkCurrentReceivingAddressesForTransactions();
    //   } catch (_) {
    //     didThrow = true;
    //   }
    //   expect(didThrow, true);
    //
    //   verify(client?.getHistory(scripthash: anyNamed("scripthash"))).called(1);
    //   verify(client?.getServerFeatures()).called(1);
    //   verify(client?.ping()).called(1);
    //
    //   expect(secureStore?.interactions, 20);
    //   expect(secureStore?.reads, 13);
    //   expect(secureStore?.writes, 7);
    //   expect(secureStore?.deletes, 0);
    //   verifyNoMoreInteractions(client);
    //   verifyNoMoreInteractions(cachedClient);
    //   verifyNoMoreInteractions(priceAPI);
    // });

    // test("_checkCurrentChangeAddressesForTransactions succeeds", () async {
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
    //   when(client?.getHistory(scripthash: anyNamed("scripthash")))
    //       .thenAnswer((realInvocation) async => [
    //             {
    //               "height": 200004,
    //               "tx_hash":
    //                   "acc3758bd2a26f869fcc67d48ff30b96464d476bca82c1cd6656e7d506816412"
    //             },
    //             {
    //               "height": 215008,
    //               "tx_hash":
    //                   "f3e1bf48975b8d6060a9de8884296abb80be618dc00ae3cb2f6cee3085e09403"
    //             }
    //           ]);
    //
    //   await btc?.initializeWallet();
    //
    //   bool didThrow = false;
    //   try {
    //     await btc?.checkCurrentChangeAddressesForTransactions();
    //   } catch (_) {
    //     didThrow = true;
    //   }
    //   expect(didThrow, false);
    //
    //   verify(client?.getHistory(scripthash: anyNamed("scripthash"))).called(3);
    //   verify(client?.getServerFeatures()).called(1);
    //   verify(client?.ping()).called(1);
    //
    //   expect(secureStore?.interactions, 29);
    //   expect(secureStore?.reads, 19);
    //   expect(secureStore?.writes, 10);
    //   expect(secureStore?.deletes, 0);
    //   verifyNoMoreInteractions(client);
    //   verifyNoMoreInteractions(cachedClient);
    //   verifyNoMoreInteractions(priceAPI);
    // });
    //
    // test("_checkCurrentChangeAddressesForTransactions fails", () async {
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
    //   when(client?.getHistory(scripthash: anyNamed("scripthash")))
    //       .thenThrow(Exception("some exception"));
    //
    //   await btc?.initializeWallet();
    //
    //   bool didThrow = false;
    //   try {
    //     await btc?.checkCurrentChangeAddressesForTransactions();
    //   } catch (_) {
    //     didThrow = true;
    //   }
    //   expect(didThrow, true);
    //
    //   verify(client?.getHistory(scripthash: anyNamed("scripthash"))).called(1);
    //   verify(client?.getServerFeatures()).called(1);
    //   verify(client?.ping()).called(1);
    //
    //   expect(secureStore?.interactions, 20);
    //   expect(secureStore?.reads, 13);
    //   expect(secureStore?.writes, 7);
    //   expect(secureStore?.deletes, 0);
    //   verifyNoMoreInteractions(client);
    //   verifyNoMoreInteractions(cachedClient);
    //   verifyNoMoreInteractions(priceAPI);
    // });
    //
    // test("getAllTxsToWatch", () async {
    //   TestWidgetsFlutterBinding.ensureInitialized();
    //   var notifications = {"show": 0};
    //   const MethodChannel('dexterous.com/flutter/local_notifications')
    //       .setMockMethodCallHandler((call) async {
    //     notifications[call.method]++;
    //   });
    //
    //   btc?.pastUnconfirmedTxs = {
    //     "88b7b5077d940dde1bc63eba37a09dec8e7b9dad14c183a2e879a21b6ec0ac1c",
    //     "b39bac02b65af46a49e2985278fe24ca00dd5d627395d88f53e35568a04e10fa",
    //   };
    //
    //   await btc?.getAllTxsToWatch(transactionData);
    //   expect(notifications.length, 1);
    //   expect(notifications["show"], 3);
    //
    //   expect(btc?.unconfirmedTxs, {
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
    //     tx_hash:
    //         "b2f75a017a7435f1b8c2e080a865275d8f80699bba68d8dce99a94606e7b3528",
    //   )).thenAnswer((_) async => tx2Raw);
    //   when(client?.getTransaction(
    //     tx_hash:
    //         "88b7b5077d940dde1bc63eba37a09dec8e7b9dad14c183a2e879a21b6ec0ac1c",
    //   )).thenAnswer((_) async => tx1Raw);
    //
    //   btc = BitcoinWallet(
    //     walletId: testWalletId,
    //     walletName: testWalletName,
    //     coin: Coin.bitcoinTestNet,
    //     client: client!,
    //     cachedClient: cachedClient!,
    //     tracker: tracker!,
    //     priceAPI: priceAPI,
    //     secureStore: secureStore,
    //   );
    //   final wallet = await Hive.openBox(testWalletId);
    //   await wallet.put('receivingAddressesP2PKH', []);
    //   await wallet.put('receivingAddressesP2SH', [
    //     "2Mv83bPh2HzPRXptuQg9ejbKpSp87Zi52zT",
    //   ]);
    //   await wallet.put('receivingAddressesP2WPKH', [
    //     "tb1q3ywehep0ykrkaqkt0hrgsqyns4mnz2ls8nxfzg",
    //   ]);
    //
    //   await wallet.put('changeAddressesP2PKH', []);
    //   await wallet.put('changeAddressesP2SH', []);
    //   await wallet.put('changeAddressesP2WPKH', []);
    //
    //   btc?.unconfirmedTxs = {
    //     "b2f75a017a7435f1b8c2e080a865275d8f80699bba68d8dce99a94606e7b3528",
    //     "88b7b5077d940dde1bc63eba37a09dec8e7b9dad14c183a2e879a21b6ec0ac1c"
    //   };
    //
    //   final result = await btc?.refreshIfThereIsNewData();
    //
    //   expect(result, true);
    //
    //   verify(client?.getTransaction(
    //     tx_hash:
    //         "b2f75a017a7435f1b8c2e080a865275d8f80699bba68d8dce99a94606e7b3528",
    //   )).called(1);
    //   verify(client.getTransaction(
    //     tx_hash:
    //         "88b7b5077d940dde1bc63eba37a09dec8e7b9dad14c183a2e879a21b6ec0ac1c",
    //   )).called(1);
    //
    //   expect(secureStore.interactions, 0);
    //   verifyNoMoreInteractions(client);
    //   verifyNoMoreInteractions(cachedClient);
    //   verifyNoMoreInteractions(priceAPI);
    // });
    //
    // test("refreshIfThereIsNewData true B", () async {
    //   // when(priceAPI.getBitcoinPrice(baseCurrency: "USD"))
    //   //     .thenAnswer((_) async => Decimal.fromInt(10));
    //
    //   when(client?.getBatchHistory(args: anyNamed("args")))
    //       .thenAnswer((realInvocation) async {
    //     final uuids = Map<String, List<dynamic>>.from(
    //             realInvocation.namedArguments.values.first)
    //         .keys
    //         .toList(growable: false);
    //     return {
    //       uuids[0]: [
    //         {
    //           "tx_hash":
    //               "dcca229760b44834478f0b266c9b3f5801e0139fdecacdc0820e447289a006d3",
    //           "height": 2226003
    //         },
    //         {
    //           "tx_hash":
    //               "b2f75a017a7435f1b8c2e080a865275d8f80699bba68d8dce99a94606e7b3528",
    //           "height": 2226102
    //         }
    //       ],
    //       uuids[1]: [
    //         {
    //           "tx_hash":
    //               "88b7b5077d940dde1bc63eba37a09dec8e7b9dad14c183a2e879a21b6ec0ac1c",
    //           "height": 2226326
    //         }
    //       ],
    //     };
    //   });
    //
    //   when(client?.getTransaction(
    //     tx_hash:
    //         "b2f75a017a7435f1b8c2e080a865275d8f80699bba68d8dce99a94606e7b3528",
    //   )).thenAnswer((_) async => tx2Raw);
    //   when(client?.getTransaction(
    //     tx_hash:
    //         "88b7b5077d940dde1bc63eba37a09dec8e7b9dad14c183a2e879a21b6ec0ac1c",
    //   )).thenAnswer((_) async => tx1Raw);
    //
    //   when(cachedClient?.getTransaction(
    //           tx_hash:
    //               "dcca229760b44834478f0b266c9b3f5801e0139fdecacdc0820e447289a006d3",
    //           coinName: "tBitcoin",
    //           callOutSideMainIsolate: false))
    //       .thenAnswer((_) async => tx3Raw);
    //   when(cachedClient?.getTransaction(
    //           tx_hash:
    //               "b2f75a017a7435f1b8c2e080a865275d8f80699bba68d8dce99a94606e7b3528",
    //           coinName: "tBitcoin",
    //           callOutSideMainIsolate: false))
    //       .thenAnswer((_) async => tx3Raw);
    //   when(cachedClient?.getTransaction(
    //           tx_hash:
    //               "88b7b5077d940dde1bc63eba37a09dec8e7b9dad14c183a2e879a21b6ec0ac1c",
    //           coinName: "tBitcoin",
    //           callOutSideMainIsolate: false))
    //       .thenAnswer((_) async => tx1Raw);
    //   when(cachedClient?.getTransaction(
    //           tx_hash:
    //               "6261002b30122ab3b2ba8c481134e8a3ce08a3a1a429b8ebb3f28228b100ac1a",
    //           coinName: "tBitcoin",
    //           callOutSideMainIsolate: false))
    //       .thenAnswer((_) async => tx5Raw);
    //   when(cachedClient?.getTransaction(
    //           tx_hash:
    //               "717080fc0054f655260b1591a0059bf377a589a98284173d20a1c8f3316c086e",
    //           coinName: "tBitcoin",
    //           callOutSideMainIsolate: false))
    //       .thenAnswer((_) async => tx6Raw);
    //   when(cachedClient?.getTransaction(
    //           tx_hash:
    //               "1baec51e7630e3640ccf0e34f160c8ad3eb6021ecafe3618a1afae328f320f53",
    //           coinName: "tBitcoin",
    //           callOutSideMainIsolate: false))
    //       .thenAnswer((_) async => tx7Raw);
    //   when(cachedClient?.getTransaction(
    //           tx_hash:
    //               "b39bac02b65af46a49e2985278fe24ca00dd5d627395d88f53e35568a04e10fa",
    //           coinName: "tBitcoin",
    //           callOutSideMainIsolate: false))
    //       .thenAnswer((_) async => tx4Raw);
    //   when(cachedClient?.getTransaction(
    //           tx_hash:
    //               "46b1f19763ac68e39b8218429f4e29b150f850901562fe44a05fade9e0acd65f",
    //           coinName: "tBitcoin",
    //           callOutSideMainIsolate: false))
    //       .thenAnswer((_) async => tx8Raw);
    //
    //   btc = BitcoinWallet(
    //     walletId: testWalletId,
    //     walletName: testWalletName,
    //     coin: Coin.bitcoinTestNet,
    //     client: client!,
    //     cachedClient: cachedClient!,
    //     tracker: tracker!,
    //     priceAPI: priceAPI,
    //     secureStore: secureStore,
    //   );
    //   final wallet = await Hive.openBox(testWalletId);
    //   await wallet.put('receivingAddressesP2PKH', []);
    //   await wallet.put('receivingAddressesP2SH', [
    //     "2Mv83bPh2HzPRXptuQg9ejbKpSp87Zi52zT",
    //   ]);
    //   await wallet.put('receivingAddressesP2WPKH', [
    //     "tb1q3ywehep0ykrkaqkt0hrgsqyns4mnz2ls8nxfzg",
    //   ]);
    //
    //   await wallet.put('changeAddressesP2PKH', []);
    //   await wallet.put('changeAddressesP2SH', []);
    //   await wallet.put('changeAddressesP2WPKH', []);
    //
    //   btc.unconfirmedTxs = {
    //     "b2f75a017a7435f1b8c2e080a865275d8f80699bba68d8dce99a94606e7b3528",
    //   };
    //
    //   final result = await btc?.refreshIfThereIsNewData();
    //
    //   expect(result, true);
    //
    //   verify(client?.getBatchHistory(args: anyNamed("args"))).called(2);
    //   verify(client?.getTransaction(
    //     tx_hash:
    //         "b2f75a017a7435f1b8c2e080a865275d8f80699bba68d8dce99a94606e7b3528",
    //   )).called(1);
    //   verify(cachedClient?.getTransaction(
    //           tx_hash: anyNamed("tx_hash"),
    //           verbose: true,
    //           coinName: "tBitcoin",
    //           callOutSideMainIsolate: false))
    //       .called(9);
    //   // verify(priceAPI.getBitcoinPrice(baseCurrency: "USD")).called(1);
    //
    //   expect(secureStore?.interactions, 0);
    //   verifyNoMoreInteractions(client);
    //   verifyNoMoreInteractions(cachedClient);
    //   verifyNoMoreInteractions(priceAPI);
    // });
    //
    // test("refreshIfThereIsNewData false A", () async {
    //   // when(priceAPI.getBitcoinPrice(baseCurrency: "USD"))
    //   //     .thenAnswer((_) async => Decimal.fromInt(10));
    //
    //   when(client?.getBatchHistory(args: anyNamed("args")))
    //       .thenAnswer((realInvocation) async {
    //     final uuids = Map<String, List<dynamic>>.from(
    //             realInvocation.namedArguments.values.first)
    //         .keys
    //         .toList(growable: false);
    //     return {
    //       uuids[0]: [
    //         {
    //           "tx_hash":
    //               "dcca229760b44834478f0b266c9b3f5801e0139fdecacdc0820e447289a006d3",
    //           "height": 2226003
    //         },
    //         {
    //           "tx_hash":
    //               "b2f75a017a7435f1b8c2e080a865275d8f80699bba68d8dce99a94606e7b3528",
    //           "height": 2226102
    //         }
    //       ],
    //       uuids[1]: [
    //         {
    //           "tx_hash":
    //               "88b7b5077d940dde1bc63eba37a09dec8e7b9dad14c183a2e879a21b6ec0ac1c",
    //           "height": 2226326
    //         }
    //       ],
    //     };
    //   });
    //
    //   when(client?.getTransaction(
    //     tx_hash:
    //         "b2f75a017a7435f1b8c2e080a865275d8f80699bba68d8dce99a94606e7b3528",
    //   )).thenAnswer((_) async => tx2Raw);
    //   when(client?.getTransaction(
    //     tx_hash:
    //         "88b7b5077d940dde1bc63eba37a09dec8e7b9dad14c183a2e879a21b6ec0ac1c",
    //   )).thenAnswer((_) async => tx1Raw);
    //
    //   when(cachedClient?.getTransaction(
    //           tx_hash:
    //               "dcca229760b44834478f0b266c9b3f5801e0139fdecacdc0820e447289a006d3",
    //           coinName: "tBitcoin",
    //           callOutSideMainIsolate: false))
    //       .thenAnswer((_) async => tx3Raw);
    //   when(cachedClient?.getTransaction(
    //           tx_hash:
    //               "b2f75a017a7435f1b8c2e080a865275d8f80699bba68d8dce99a94606e7b3528",
    //           coinName: "tBitcoin",
    //           callOutSideMainIsolate: false))
    //       .thenAnswer((_) async => tx2Raw);
    //   when(cachedClient?.getTransaction(
    //           tx_hash:
    //               "88b7b5077d940dde1bc63eba37a09dec8e7b9dad14c183a2e879a21b6ec0ac1c",
    //           coinName: "tBitcoin",
    //           callOutSideMainIsolate: false))
    //       .thenAnswer((_) async => tx1Raw);
    //   when(cachedClient?.getTransaction(
    //           tx_hash:
    //               "6261002b30122ab3b2ba8c481134e8a3ce08a3a1a429b8ebb3f28228b100ac1a",
    //           coinName: "tBitcoin",
    //           callOutSideMainIsolate: false))
    //       .thenAnswer((_) async => tx5Raw);
    //   when(cachedClient?.getTransaction(
    //           tx_hash:
    //               "717080fc0054f655260b1591a0059bf377a589a98284173d20a1c8f3316c086e",
    //           coinName: "tBitcoin",
    //           callOutSideMainIsolate: false))
    //       .thenAnswer((_) async => tx6Raw);
    //   when(cachedClient?.getTransaction(
    //           tx_hash:
    //               "1baec51e7630e3640ccf0e34f160c8ad3eb6021ecafe3618a1afae328f320f53",
    //           coinName: "tBitcoin",
    //           callOutSideMainIsolate: false))
    //       .thenAnswer((_) async => tx7Raw);
    //   when(cachedClient?.getTransaction(
    //           tx_hash:
    //               "b39bac02b65af46a49e2985278fe24ca00dd5d627395d88f53e35568a04e10fa",
    //           coinName: "tBitcoin",
    //           callOutSideMainIsolate: false))
    //       .thenAnswer((_) async => tx4Raw);
    //   when(cachedClient?.getTransaction(
    //           tx_hash:
    //               "46b1f19763ac68e39b8218429f4e29b150f850901562fe44a05fade9e0acd65f",
    //           coinName: "tBitcoin",
    //           callOutSideMainIsolate: false))
    //       .thenAnswer((_) async => tx8Raw);
    //
    //   btc = BitcoinWallet(
    //     walletId: testWalletId,
    //     walletName: testWalletName,
    //     coin: Coin.bitcoinTestNet,
    //     client: client!,
    //     cachedClient: cachedClient!,
    //     tracker: tracker!,
    //     priceAPI: priceAPI,
    //     secureStore: secureStore,
    //   );
    //   final wallet = await Hive.openBox(testWalletId);
    //   await wallet.put('receivingAddressesP2PKH', []);
    //   await wallet.put('receivingAddressesP2SH', [
    //     "2Mv83bPh2HzPRXptuQg9ejbKpSp87Zi52zT",
    //   ]);
    //   await wallet.put('receivingAddressesP2WPKH', [
    //     "tb1q3ywehep0ykrkaqkt0hrgsqyns4mnz2ls8nxfzg",
    //   ]);
    //
    //   await wallet.put('changeAddressesP2PKH', []);
    //   await wallet.put('changeAddressesP2SH', []);
    //   await wallet.put('changeAddressesP2WPKH', []);
    //
    //   btc?.unconfirmedTxs = {
    //     "b2f75a017a7435f1b8c2e080a865275d8f80699bba68d8dce99a94606e7b3528",
    //   };
    //
    //   final result = await btc?.refreshIfThereIsNewData();
    //
    //   expect(result, false);
    //
    //   verify(client?.getBatchHistory(args: anyNamed("args"))).called(2);
    //   verify(client?.getTransaction(
    //     tx_hash:
    //         "b2f75a017a7435f1b8c2e080a865275d8f80699bba68d8dce99a94606e7b3528",
    //   )).called(1);
    //   verify(cachedClient?.getTransaction(
    //           tx_hash: anyNamed("tx_hash"),
    //           verbose: true,
    //           coinName: "tBitcoin",
    //           callOutSideMainIsolate: false))
    //       .called(15);
    //   // verify(priceAPI.getBitcoinPrice(baseCurrency: "USD")).called(1);
    //
    //   expect(secureStore?.interactions, 0);
    //   verifyNoMoreInteractions(client);
    //   verifyNoMoreInteractions(cachedClient);
    //   verifyNoMoreInteractions(priceAPI);
    // });

    // test("refreshIfThereIsNewData false B", () async {
    //   when(client?.getBatchHistory(args: anyNamed("args")))
    //       .thenThrow(Exception("some exception"));
    //
    //   when(client?.getTransaction(
    //     txHash:
    //         "b2f75a017a7435f1b8c2e080a865275d8f80699bba68d8dce99a94606e7b3528",
    //   )).thenAnswer((_) async => tx2Raw);
    //
    //   btc = BitcoinWallet(
    //     walletId: testWalletId,
    //     walletName: testWalletName,
    //     coin: Coin.bitcoinTestNet,
    //     client: client!,
    //     cachedClient: cachedClient!,
    //     tracker: tracker!,
    //     priceAPI: priceAPI,
    //     secureStore: secureStore,
    //   );
    //   final wallet = await Hive.openBox(testWalletId);
    //   await wallet.put('receivingAddressesP2PKH', []);
    //   await wallet.put('receivingAddressesP2SH', [
    //     "2Mv83bPh2HzPRXptuQg9ejbKpSp87Zi52zT",
    //   ]);
    //   await wallet.put('receivingAddressesP2WPKH', [
    //     "tb1q3ywehep0ykrkaqkt0hrgsqyns4mnz2ls8nxfzg",
    //   ]);
    //
    //   await wallet.put('changeAddressesP2PKH', []);
    //   await wallet.put('changeAddressesP2SH', []);
    //   await wallet.put('changeAddressesP2WPKH', []);
    //
    //   btc?.txTracker = {
    //     "b2f75a017a7435f1b8c2e080a865275d8f80699bba68d8dce99a94606e7b3528",
    //   };
    //
    //   // btc?.unconfirmedTxs = {
    //   //   "b2f75a017a7435f1b8c2e080a865275d8f80699bba68d8dce99a94606e7b3528",
    //   // };
    //
    //   final result = await btc?.refreshIfThereIsNewData();
    //
    //   expect(result, false);
    //
    //   verify(client?.getBatchHistory(args: anyNamed("args"))).called(1);
    //   verify(client?.getTransaction(
    //     txHash:
    //         "b2f75a017a7435f1b8c2e080a865275d8f80699bba68d8dce99a94606e7b3528",
    //   )).called(1);
    //
    //   expect(secureStore?.interactions, 0);
    //   verifyNoMoreInteractions(client);
    //   verifyNoMoreInteractions(cachedClient);
    //   verifyNoMoreInteractions(priceAPI);
    // });

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
        await btc?.recoverFromMnemonic(
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
      btc = BitcoinWallet(
        walletId: testWalletId,
        walletName: testWalletName,
        coin: Coin.bitcoinTestNet,
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
        await btc?.recoverFromMnemonic(
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
        await btc?.recoverFromMnemonic(
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

    test("recoverFromMnemonic using empty seed on mainnet succeeds", () async {
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
          .thenAnswer((_) async => emptyHistoryBatchResponse);
      when(client?.getBatchHistory(args: historyBatchArgs1))
          .thenAnswer((_) async => emptyHistoryBatchResponse);
      // await DB.instance.init();
      final wallet = await Hive.openBox(testWalletId);
      bool hasThrown = false;
      try {
        await btc?.recoverFromMnemonic(
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
      verify(client?.getBatchHistory(args: historyBatchArgs1)).called(1);

      expect(secureStore?.interactions, 20);
      expect(secureStore?.writes, 7);
      expect(secureStore?.reads, 13);
      expect(secureStore?.deletes, 0);

      verifyNoMoreInteractions(client);
      verifyNoMoreInteractions(cachedClient);
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
      when(client?.getBatchHistory(args: historyBatchArgs0))
          .thenAnswer((_) async => emptyHistoryBatchResponse);
      when(client?.getBatchHistory(args: historyBatchArgs1))
          .thenAnswer((_) async => emptyHistoryBatchResponse);

      final wallet = await Hive.openBox(testWalletId);

      await btc?.recoverFromMnemonic(
          mnemonic: TEST_MNEMONIC,
          maxUnusedAddressGap: 2,
          maxNumberOfIndexesToCheck: 1000,
          height: 4000);

      expect(await btc?.mnemonic, TEST_MNEMONIC.split(" "));

      verify(client?.getServerFeatures()).called(1);
      verify(client?.getBatchHistory(args: historyBatchArgs0)).called(1);
      verify(client?.getBatchHistory(args: historyBatchArgs1)).called(1);

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
      when(client?.getBatchHistory(args: historyBatchArgs1))
          .thenAnswer((_) async => historyBatchResponse);

      final wallet = await Hive.openBox(testWalletId);

      bool hasThrown = false;
      try {
        await btc?.recoverFromMnemonic(
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
      verify(client?.getBatchHistory(args: historyBatchArgs1)).called(1);

      expect(secureStore?.interactions, 14);
      expect(secureStore?.writes, 7);
      expect(secureStore?.reads, 7);
      expect(secureStore?.deletes, 0);

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
      when(cachedClient?.clearSharedTransactionCache(coin: Coin.bitcoin))
          .thenAnswer((realInvocation) async {});

      final wallet = await Hive.openBox(testWalletId);

      // restore so we have something to rescan
      await btc?.recoverFromMnemonic(
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
      final preReceiveDerivationsStringP2PKH = await secureStore?.read(
          key: "${testWalletId}_receiveDerivationsP2PKH");
      final preChangeDerivationsStringP2PKH = await secureStore?.read(
          key: "${testWalletId}_changeDerivationsP2PKH");
      final preReceiveDerivationsStringP2SH = await secureStore?.read(
          key: "${testWalletId}_receiveDerivationsP2SH");
      final preChangeDerivationsStringP2SH =
          await secureStore?.read(key: "${testWalletId}_changeDerivationsP2SH");
      final preReceiveDerivationsStringP2WPKH = await secureStore?.read(
          key: "${testWalletId}_receiveDerivationsP2WPKH");
      final preChangeDerivationsStringP2WPKH = await secureStore?.read(
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
      await secureStore?.write(
          key: "${testWalletId}_receiveDerivationsP2PKH", value: "{}");
      await secureStore?.write(
          key: "${testWalletId}_changeDerivationsP2PKH", value: "{}");
      await secureStore?.write(
          key: "${testWalletId}_receiveDerivationsP2SH", value: "{}");
      await secureStore?.write(
          key: "${testWalletId}_changeDerivationsP2SH", value: "{}");
      await secureStore?.write(
          key: "${testWalletId}_receiveDerivationsP2WPKH", value: "{}");
      await secureStore?.write(
          key: "${testWalletId}_changeDerivationsP2WPKH", value: "{}");

      bool hasThrown = false;
      try {
        await btc?.fullRescan(2, 1000);
      } catch (_) {
        hasThrown = true;
      }
      expect(hasThrown, false);

      // fetch wallet data again
      final receivingAddressesP2PKH =
          await wallet.get('receivingAddressesP2PKH');
      final receivingAddressesP2SH = await wallet.get('receivingAddressesP2SH');
      final receivingAddressesP2WPKH =
          await wallet.get('receivingAddressesP2WPKH');
      final changeAddressesP2PKH = await wallet.get('changeAddressesP2PKH');
      final changeAddressesP2SH = await wallet.get('changeAddressesP2SH');
      final changeAddressesP2WPKH = await wallet.get('changeAddressesP2WPKH');
      final receivingIndexP2PKH = await wallet.get('receivingIndexP2PKH');
      final receivingIndexP2SH = await wallet.get('receivingIndexP2SH');
      final receivingIndexP2WPKH = await wallet.get('receivingIndexP2WPKH');
      final changeIndexP2PKH = await wallet.get('changeIndexP2PKH');
      final changeIndexP2SH = await wallet.get('changeIndexP2SH');
      final changeIndexP2WPKH = await wallet.get('changeIndexP2WPKH');
      final utxoData = await wallet.get('latest_utxo_model');
      final receiveDerivationsStringP2PKH = await secureStore?.read(
          key: "${testWalletId}_receiveDerivationsP2PKH");
      final changeDerivationsStringP2PKH = await secureStore?.read(
          key: "${testWalletId}_changeDerivationsP2PKH");
      final receiveDerivationsStringP2SH = await secureStore?.read(
          key: "${testWalletId}_receiveDerivationsP2SH");
      final changeDerivationsStringP2SH =
          await secureStore?.read(key: "${testWalletId}_changeDerivationsP2SH");
      final receiveDerivationsStringP2WPKH = await secureStore?.read(
          key: "${testWalletId}_receiveDerivationsP2WPKH");
      final changeDerivationsStringP2WPKH = await secureStore?.read(
          key: "${testWalletId}_changeDerivationsP2WPKH");

      expect(preReceivingAddressesP2PKH, receivingAddressesP2PKH);
      expect(preReceivingAddressesP2SH, receivingAddressesP2SH);
      expect(preReceivingAddressesP2WPKH, receivingAddressesP2WPKH);
      expect(preChangeAddressesP2PKH, changeAddressesP2PKH);
      expect(preChangeAddressesP2SH, changeAddressesP2SH);
      expect(preChangeAddressesP2WPKH, changeAddressesP2WPKH);
      expect(preReceivingIndexP2PKH, receivingIndexP2PKH);
      expect(preReceivingIndexP2SH, receivingIndexP2SH);
      expect(preReceivingIndexP2WPKH, receivingIndexP2WPKH);
      expect(preChangeIndexP2PKH, changeIndexP2PKH);
      expect(preChangeIndexP2SH, changeIndexP2SH);
      expect(preChangeIndexP2WPKH, changeIndexP2WPKH);
      expect(preUtxoData, utxoData);
      expect(preReceiveDerivationsStringP2PKH, receiveDerivationsStringP2PKH);
      expect(preChangeDerivationsStringP2PKH, changeDerivationsStringP2PKH);
      expect(preReceiveDerivationsStringP2SH, receiveDerivationsStringP2SH);
      expect(preChangeDerivationsStringP2SH, changeDerivationsStringP2SH);
      expect(preReceiveDerivationsStringP2WPKH, receiveDerivationsStringP2WPKH);
      expect(preChangeDerivationsStringP2WPKH, changeDerivationsStringP2WPKH);

      verify(client?.getServerFeatures()).called(1);
      verify(client?.getBatchHistory(args: historyBatchArgs0)).called(2);
      verify(client?.getBatchHistory(args: historyBatchArgs1)).called(2);
      verify(cachedClient?.clearSharedTransactionCache(coin: Coin.bitcoin))
          .called(1);

      expect(secureStore?.writes, 25);
      expect(secureStore?.reads, 32);
      expect(secureStore?.deletes, 6);

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
      when(cachedClient?.clearSharedTransactionCache(coin: Coin.bitcoin))
          .thenAnswer((realInvocation) async {});

      final wallet = await Hive.openBox(testWalletId);

      // restore so we have something to rescan
      await btc?.recoverFromMnemonic(
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
      final preReceiveDerivationsStringP2PKH = await secureStore?.read(
          key: "${testWalletId}_receiveDerivationsP2PKH");
      final preChangeDerivationsStringP2PKH = await secureStore?.read(
          key: "${testWalletId}_changeDerivationsP2PKH");
      final preReceiveDerivationsStringP2SH = await secureStore?.read(
          key: "${testWalletId}_receiveDerivationsP2SH");
      final preChangeDerivationsStringP2SH =
          await secureStore?.read(key: "${testWalletId}_changeDerivationsP2SH");
      final preReceiveDerivationsStringP2WPKH = await secureStore?.read(
          key: "${testWalletId}_receiveDerivationsP2WPKH");
      final preChangeDerivationsStringP2WPKH = await secureStore?.read(
          key: "${testWalletId}_changeDerivationsP2WPKH");

      when(client?.getBatchHistory(args: historyBatchArgs0))
          .thenThrow(Exception("fake exception"));

      bool hasThrown = false;
      try {
        await btc?.fullRescan(2, 1000);
      } catch (_) {
        hasThrown = true;
      }
      expect(hasThrown, true);

      // fetch wallet data again
      final receivingAddressesP2PKH =
          await wallet.get('receivingAddressesP2PKH');
      final receivingAddressesP2SH = await wallet.get('receivingAddressesP2SH');
      final receivingAddressesP2WPKH =
          await wallet.get('receivingAddressesP2WPKH');
      final changeAddressesP2PKH = await wallet.get('changeAddressesP2PKH');
      final changeAddressesP2SH = await wallet.get('changeAddressesP2SH');
      final changeAddressesP2WPKH = await wallet.get('changeAddressesP2WPKH');
      final receivingIndexP2PKH = await wallet.get('receivingIndexP2PKH');
      final receivingIndexP2SH = await wallet.get('receivingIndexP2SH');
      final receivingIndexP2WPKH = await wallet.get('receivingIndexP2WPKH');
      final changeIndexP2PKH = await wallet.get('changeIndexP2PKH');
      final changeIndexP2SH = await wallet.get('changeIndexP2SH');
      final changeIndexP2WPKH = await wallet.get('changeIndexP2WPKH');
      final utxoData = await wallet.get('latest_utxo_model');
      final receiveDerivationsStringP2PKH = await secureStore?.read(
          key: "${testWalletId}_receiveDerivationsP2PKH");
      final changeDerivationsStringP2PKH = await secureStore?.read(
          key: "${testWalletId}_changeDerivationsP2PKH");
      final receiveDerivationsStringP2SH = await secureStore?.read(
          key: "${testWalletId}_receiveDerivationsP2SH");
      final changeDerivationsStringP2SH =
          await secureStore?.read(key: "${testWalletId}_changeDerivationsP2SH");
      final receiveDerivationsStringP2WPKH = await secureStore?.read(
          key: "${testWalletId}_receiveDerivationsP2WPKH");
      final changeDerivationsStringP2WPKH = await secureStore?.read(
          key: "${testWalletId}_changeDerivationsP2WPKH");

      expect(preReceivingAddressesP2PKH, receivingAddressesP2PKH);
      expect(preReceivingAddressesP2SH, receivingAddressesP2SH);
      expect(preReceivingAddressesP2WPKH, receivingAddressesP2WPKH);
      expect(preChangeAddressesP2PKH, changeAddressesP2PKH);
      expect(preChangeAddressesP2SH, changeAddressesP2SH);
      expect(preChangeAddressesP2WPKH, changeAddressesP2WPKH);
      expect(preReceivingIndexP2PKH, receivingIndexP2PKH);
      expect(preReceivingIndexP2SH, receivingIndexP2SH);
      expect(preReceivingIndexP2WPKH, receivingIndexP2WPKH);
      expect(preChangeIndexP2PKH, changeIndexP2PKH);
      expect(preChangeIndexP2SH, changeIndexP2SH);
      expect(preChangeIndexP2WPKH, changeIndexP2WPKH);
      expect(preUtxoData, utxoData);
      expect(preReceiveDerivationsStringP2PKH, receiveDerivationsStringP2PKH);
      expect(preChangeDerivationsStringP2PKH, changeDerivationsStringP2PKH);
      expect(preReceiveDerivationsStringP2SH, receiveDerivationsStringP2SH);
      expect(preChangeDerivationsStringP2SH, changeDerivationsStringP2SH);
      expect(preReceiveDerivationsStringP2WPKH, receiveDerivationsStringP2WPKH);
      expect(preChangeDerivationsStringP2WPKH, changeDerivationsStringP2WPKH);

      verify(client?.getServerFeatures()).called(1);
      verify(client?.getBatchHistory(args: historyBatchArgs0)).called(2);
      verify(client?.getBatchHistory(args: historyBatchArgs1)).called(1);
      verify(cachedClient?.clearSharedTransactionCache(coin: Coin.bitcoin))
          .called(1);

      expect(secureStore?.writes, 19);
      expect(secureStore?.reads, 32);
      expect(secureStore?.deletes, 12);

      verifyNoMoreInteractions(client);
      verifyNoMoreInteractions(cachedClient);
      verifyNoMoreInteractions(priceAPI);
    });

    // test("fetchBuildTxData succeeds", () async {
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
    //           tx_hash:
    //               "2087ce09bc316877c9f10971526a2bffa3078d52ea31752639305cdcd8230703",
    //           coinName: "Bitcoin",
    //           callOutSideMainIsolate: false))
    //       .thenAnswer((_) async => tx9Raw);
    //   when(cachedClient?.getTransaction(
    //           tx_hash:
    //               "ed32c967a0e86d51669ac21c2bb9bc9c50f0f55fbacdd8db21d0a986fba93bd7",
    //           coinName: "Bitcoin",
    //           callOutSideMainIsolate: false))
    //       .thenAnswer((_) async => tx10Raw);
    //   when(cachedClient?.getTransaction(
    //           tx_hash:
    //               "3f0032f89ac44b281b50314cff3874c969c922839dddab77ced54e86a21c3fd4",
    //           coinName: "Bitcoin",
    //           callOutSideMainIsolate: false))
    //       .thenAnswer((_) async => tx11Raw);
    //
    //   // recover to fill data
    //   await btc?.recoverFromMnemonic(
    //       mnemonic: TEST_MNEMONIC,
    //       maxUnusedAddressGap: 2,
    //       maxNumberOfIndexesToCheck: 1000);
    //
    //   // modify addresses to trigger all change code branches
    //   final chg44 = await secureStore?.read(
    //       key: testWalletId + "_changeDerivationsP2PKH");
    //   await secureStore?.write(
    //       key: testWalletId + "_changeDerivationsP2PKH",
    //       value: chg44?.replaceFirst("1vFHF5q21GccoBwrB4zEUAs9i3Bfx797U",
    //           "16FuTPaeRSPVxxCnwQmdyx2PQWxX6HWzhQ"));
    //   final chg49 =
    //       await secureStore?.read(key: testWalletId + "_changeDerivationsP2SH");
    //   await secureStore?.write(
    //       key: testWalletId + "_changeDerivationsP2SH",
    //       value: chg49?.replaceFirst("3ANTVqufTH1tLAuoQHhng8jndRsA9hcNy7",
    //           "36NvZTcMsMowbt78wPzJaHHWaNiyR73Y4g"));
    //   final chg84 = await secureStore?.read(
    //       key: testWalletId + "_changeDerivationsP2WPKH");
    //   await secureStore?.write(
    //       key: testWalletId + "_changeDerivationsP2WPKH",
    //       value: chg84?.replaceFirst(
    //           "bc1qn2x7h96kufgfjxtkhsnq03jqwqde8zasffqvd2",
    //           "bc1q42lja79elem0anu8q8s3h2n687re9jax556pcc"));
    //
    //   final data = await btc?.fetchBuildTxData(utxoList);
    //
    //   expect(data?.length, 3);
    //   expect(
    //       data?["2087ce09bc316877c9f10971526a2bffa3078d52ea31752639305cdcd8230703"]
    //           ?.length,
    //       2);
    //   expect(
    //       data?["ed32c967a0e86d51669ac21c2bb9bc9c50f0f55fbacdd8db21d0a986fba93bd7"]
    //           .length,
    //       3);
    //   expect(
    //       data?["3f0032f89ac44b281b50314cff3874c969c922839dddab77ced54e86a21c3fd4"]
    //           .length,
    //       2);
    //   expect(
    //       data?["2087ce09bc316877c9f10971526a2bffa3078d52ea31752639305cdcd8230703"]
    //           ["output"],
    //       isA<Uint8List>());
    //   expect(
    //       data?["ed32c967a0e86d51669ac21c2bb9bc9c50f0f55fbacdd8db21d0a986fba93bd7"]
    //           ["output"],
    //       isA<Uint8List>());
    //   expect(
    //       data?["3f0032f89ac44b281b50314cff3874c969c922839dddab77ced54e86a21c3fd4"]
    //           ["output"],
    //       isA<Uint8List>());
    //   expect(
    //       data?["2087ce09bc316877c9f10971526a2bffa3078d52ea31752639305cdcd8230703"]
    //           ["keyPair"],
    //       isA<ECPair>());
    //   expect(
    //       data?["ed32c967a0e86d51669ac21c2bb9bc9c50f0f55fbacdd8db21d0a986fba93bd7"]
    //           ["keyPair"],
    //       isA<ECPair>());
    //   expect(
    //       data?["3f0032f89ac44b281b50314cff3874c969c922839dddab77ced54e86a21c3fd4"]
    //           ["keyPair"],
    //       isA<ECPair>());
    //   expect(
    //       data?["ed32c967a0e86d51669ac21c2bb9bc9c50f0f55fbacdd8db21d0a986fba93bd7"]
    //           ["redeemScript"],
    //       isA<Uint8List>());
    //
    //   // modify addresses to trigger all receiving code branches
    //   final rcv44 = await secureStore?.read(
    //       key: testWalletId + "_receiveDerivationsP2PKH");
    //   await secureStore?.write(
    //       key: testWalletId + "_receiveDerivationsP2PKH",
    //       value: rcv44?.replaceFirst("1RMSPixoLPuaXuhR2v4HsUMcRjLncKDaw",
    //           "16FuTPaeRSPVxxCnwQmdyx2PQWxX6HWzhQ"));
    //   final rcv49 = await secureStore?.read(
    //       key: testWalletId + "_receiveDerivationsP2SH");
    //   await secureStore?.write(
    //       key: testWalletId + "_receiveDerivationsP2SH",
    //       value: rcv49?.replaceFirst("3AV74rKfibWmvX34F99yEvUcG4LLQ9jZZk",
    //           "36NvZTcMsMowbt78wPzJaHHWaNiyR73Y4g"));
    //   final rcv84 = await secureStore?.read(
    //       key: testWalletId + "_receiveDerivationsP2WPKH");
    //   await secureStore?.write(
    //       key: testWalletId + "_receiveDerivationsP2WPKH",
    //       value: rcv84?.replaceFirst(
    //           "bc1qggtj4ka8jsaj44hhd5mpamx7mp34m2d3w7k0m0",
    //           "bc1q42lja79elem0anu8q8s3h2n687re9jax556pcc"));
    //
    //   final data2 = await btc?.fetchBuildTxData(utxoList);
    //
    //   expect(data2?.length, 3);
    //   expect(
    //       data2?["2087ce09bc316877c9f10971526a2bffa3078d52ea31752639305cdcd8230703"]
    //           .length,
    //       2);
    //   expect(
    //       data2?["ed32c967a0e86d51669ac21c2bb9bc9c50f0f55fbacdd8db21d0a986fba93bd7"]
    //           .length,
    //       3);
    //   expect(
    //       data2?["3f0032f89ac44b281b50314cff3874c969c922839dddab77ced54e86a21c3fd4"]
    //           .length,
    //       2);
    //   expect(
    //       data2?["2087ce09bc316877c9f10971526a2bffa3078d52ea31752639305cdcd8230703"]
    //           ["output"],
    //       isA<Uint8List>());
    //   expect(
    //       data2?["ed32c967a0e86d51669ac21c2bb9bc9c50f0f55fbacdd8db21d0a986fba93bd7"]
    //           ["output"],
    //       isA<Uint8List>());
    //   expect(
    //       data2?["3f0032f89ac44b281b50314cff3874c969c922839dddab77ced54e86a21c3fd4"]
    //           ["output"],
    //       isA<Uint8List>());
    //   expect(
    //       data2?["2087ce09bc316877c9f10971526a2bffa3078d52ea31752639305cdcd8230703"]
    //           ["keyPair"],
    //       isA<ECPair>());
    //   expect(
    //       data2?["ed32c967a0e86d51669ac21c2bb9bc9c50f0f55fbacdd8db21d0a986fba93bd7"]
    //           ["keyPair"],
    //       isA<ECPair>());
    //   expect(
    //       data2?["3f0032f89ac44b281b50314cff3874c969c922839dddab77ced54e86a21c3fd4"]
    //           ["keyPair"],
    //       isA<ECPair>());
    //   expect(
    //       data2?["ed32c967a0e86d51669ac21c2bb9bc9c50f0f55fbacdd8db21d0a986fba93bd7"]
    //           ["redeemScript"],
    //       isA<Uint8List>());
    //
    //   verify(client?.getServerFeatures()).called(1);
    //   verify(cachedClient?.getTransaction(
    //           tx_hash:
    //               "2087ce09bc316877c9f10971526a2bffa3078d52ea31752639305cdcd8230703",
    //           coinName: "Bitcoin",
    //           callOutSideMainIsolate: false))
    //       .called(2);
    //   verify(cachedClient?.getTransaction(
    //           tx_hash:
    //               "ed32c967a0e86d51669ac21c2bb9bc9c50f0f55fbacdd8db21d0a986fba93bd7",
    //           coinName: "Bitcoin",
    //           callOutSideMainIsolate: false))
    //       .called(2);
    //   verify(cachedClient?.getTransaction(
    //           tx_hash:
    //               "3f0032f89ac44b281b50314cff3874c969c922839dddab77ced54e86a21c3fd4",
    //           coinName: "Bitcoin",
    //           callOutSideMainIsolate: false))
    //       .called(2);
    //   verify(client?.getBatchHistory(args: historyBatchArgs0)).called(1);
    //   verify(client?.getBatchHistory(args: historyBatchArgs1)).called(1);
    //
    //   expect(secureStore?.interactions, 38);
    //   expect(secureStore?.writes, 13);
    //   expect(secureStore?.reads, 25);
    //   expect(secureStore?.deletes, 0);
    //
    //   verifyNoMoreInteractions(client);
    //   verifyNoMoreInteractions(cachedClient);
    //   verifyNoMoreInteractions(priceAPI);
    // });
    //
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
    //           tx_hash:
    //               "2087ce09bc316877c9f10971526a2bffa3078d52ea31752639305cdcd8230703",
    //           coinName: "Bitcoin",
    //           callOutSideMainIsolate: false))
    //       .thenAnswer((_) async => tx9Raw);
    //   when(cachedClient?.getTransaction(
    //           tx_hash:
    //               "ed32c967a0e86d51669ac21c2bb9bc9c50f0f55fbacdd8db21d0a986fba93bd7",
    //           coinName: "Bitcoin",
    //           callOutSideMainIsolate: false))
    //       .thenAnswer((_) async => tx10Raw);
    //   when(cachedClient?.getTransaction(
    //           tx_hash:
    //               "3f0032f89ac44b281b50314cff3874c969c922839dddab77ced54e86a21c3fd4",
    //           coinName: "Bitcoin",
    //           callOutSideMainIsolate: false))
    //       .thenThrow(Exception("some exception"));
    //
    //   // recover to fill data
    //   await btc?.recoverFromMnemonic(
    //       mnemonic: TEST_MNEMONIC,
    //       maxUnusedAddressGap: 2,
    //       maxNumberOfIndexesToCheck: 1000);
    //
    //   bool didThrow = false;
    //   try {
    //     await btc?.fetchBuildTxData(utxoList);
    //   } catch (_) {
    //     didThrow = true;
    //   }
    //   expect(didThrow, true);
    //
    //   verify(client?.getServerFeatures()).called(1);
    //   verify(cachedClient?.getTransaction(
    //           tx_hash:
    //               "2087ce09bc316877c9f10971526a2bffa3078d52ea31752639305cdcd8230703",
    //           coinName: "Bitcoin",
    //           callOutSideMainIsolate: false))
    //       .called(1);
    //   verify(cachedClient?.getTransaction(
    //           tx_hash:
    //               "ed32c967a0e86d51669ac21c2bb9bc9c50f0f55fbacdd8db21d0a986fba93bd7",
    //           coinName: "Bitcoin",
    //           callOutSideMainIsolate: false))
    //       .called(1);
    //   verify(cachedClient?.getTransaction(
    //           tx_hash:
    //               "3f0032f89ac44b281b50314cff3874c969c922839dddab77ced54e86a21c3fd4",
    //           coinName: "Bitcoin",
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
    //
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
    //           tx_hash:
    //               "2087ce09bc316877c9f10971526a2bffa3078d52ea31752639305cdcd8230703",
    //           coinName: "Bitcoin",
    //           callOutSideMainIsolate: false))
    //       .thenAnswer((_) async => tx9Raw);
    //   when(cachedClient?.getTransaction(
    //           tx_hash:
    //               "ed32c967a0e86d51669ac21c2bb9bc9c50f0f55fbacdd8db21d0a986fba93bd7",
    //           coinName: "Bitcoin",
    //           callOutSideMainIsolate: false))
    //       .thenAnswer((_) async => tx10Raw);
    //   when(cachedClient?.getTransaction(
    //           tx_hash:
    //               "3f0032f89ac44b281b50314cff3874c969c922839dddab77ced54e86a21c3fd4",
    //           coinName: "Bitcoin",
    //           callOutSideMainIsolate: false))
    //       .thenAnswer((_) async => tx11Raw);
    //
    //   // recover to fill data
    //   await btc?.recoverFromMnemonic(
    //       mnemonic: TEST_MNEMONIC,
    //       maxUnusedAddressGap: 2,
    //       maxNumberOfIndexesToCheck: 1000);
    //
    //   // modify addresses to properly mock data to build a tx
    //   final rcv44 = await secureStore?.read(
    //       key: testWalletId + "_receiveDerivationsP2PKH");
    //   await secureStore?.write(
    //       key: testWalletId + "_receiveDerivationsP2PKH",
    //       value: rcv44?.replaceFirst("1RMSPixoLPuaXuhR2v4HsUMcRjLncKDaw",
    //           "16FuTPaeRSPVxxCnwQmdyx2PQWxX6HWzhQ"));
    //   final rcv49 = await secureStore?.read(
    //       key: testWalletId + "_receiveDerivationsP2SH");
    //   await secureStore?.write(
    //       key: testWalletId + "_receiveDerivationsP2SH",
    //       value: rcv49?.replaceFirst("3AV74rKfibWmvX34F99yEvUcG4LLQ9jZZk",
    //           "36NvZTcMsMowbt78wPzJaHHWaNiyR73Y4g"));
    //   final rcv84 = await secureStore?.read(
    //       key: testWalletId + "_receiveDerivationsP2WPKH");
    //   await secureStore?.write(
    //       key: testWalletId + "_receiveDerivationsP2WPKH",
    //       value: rcv84?.replaceFirst(
    //           "bc1qggtj4ka8jsaj44hhd5mpamx7mp34m2d3w7k0m0",
    //           "bc1q42lja79elem0anu8q8s3h2n687re9jax556pcc"));
    //
    //   final data = await btc?.fetchBuildTxData(utxoList);
    //
    //   final txData = await btc?.buildTransaction(
    //       utxosToUse: utxoList,
    //       utxoSigningData: data!,
    //       recipients: ["bc1q42lja79elem0anu8q8s3h2n687re9jax556pcc"],
    //       satoshiAmounts: [13000]);
    //
    //   expect(txData?.length, 2);
    //   expect(txData?["hex"], isA<String>());
    //   expect(txData?["vSize"], isA<int>());
    //
    //   verify(client?.getServerFeatures()).called(1);
    //   verify(cachedClient?.getTransaction(
    //           tx_hash:
    //               "2087ce09bc316877c9f10971526a2bffa3078d52ea31752639305cdcd8230703",
    //           coinName: "Bitcoin",
    //           callOutSideMainIsolate: false))
    //       .called(1);
    //   verify(cachedClient?.getTransaction(
    //           tx_hash:
    //               "ed32c967a0e86d51669ac21c2bb9bc9c50f0f55fbacdd8db21d0a986fba93bd7",
    //           coinName: "Bitcoin",
    //           callOutSideMainIsolate: false))
    //       .called(1);
    //   verify(cachedClient?.getTransaction(
    //           tx_hash:
    //               "3f0032f89ac44b281b50314cff3874c969c922839dddab77ced54e86a21c3fd4",
    //           coinName: "Bitcoin",
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
    //
    // test("build transaction fails", () async {
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
    //           tx_hash:
    //               "2087ce09bc316877c9f10971526a2bffa3078d52ea31752639305cdcd8230703",
    //           coinName: "Bitcoin",
    //           callOutSideMainIsolate: false))
    //       .thenAnswer((_) async => tx9Raw);
    //   when(cachedClient?.getTransaction(
    //           tx_hash:
    //               "ed32c967a0e86d51669ac21c2bb9bc9c50f0f55fbacdd8db21d0a986fba93bd7",
    //           coinName: "Bitcoin",
    //           callOutSideMainIsolate: false))
    //       .thenAnswer((_) async => tx10Raw);
    //   when(cachedClient?.getTransaction(
    //           tx_hash:
    //               "3f0032f89ac44b281b50314cff3874c969c922839dddab77ced54e86a21c3fd4",
    //           coinName: "Bitcoin",
    //           callOutSideMainIsolate: false))
    //       .thenAnswer((_) async => tx11Raw);
    //
    //   // recover to fill data
    //   await btc?.recoverFromMnemonic(
    //       mnemonic: TEST_MNEMONIC,
    //       maxUnusedAddressGap: 2,
    //       maxNumberOfIndexesToCheck: 1000);
    //
    //   // modify addresses to properly mock data to build a tx
    //   final rcv44 = await secureStore?.read(
    //       key: testWalletId + "_receiveDerivationsP2PKH");
    //   await secureStore?.write(
    //       key: testWalletId + "_receiveDerivationsP2PKH",
    //       value: rcv44?.replaceFirst("1RMSPixoLPuaXuhR2v4HsUMcRjLncKDaw",
    //           "16FuTPaeRSPVxxCnwQmdyx2PQWxX6HWzhQ"));
    //   final rcv49 = await secureStore?.read(
    //       key: testWalletId + "_receiveDerivationsP2SH");
    //   await secureStore?.write(
    //       key: testWalletId + "_receiveDerivationsP2SH",
    //       value: rcv49?.replaceFirst("3AV74rKfibWmvX34F99yEvUcG4LLQ9jZZk",
    //           "36NvZTcMsMowbt78wPzJaHHWaNiyR73Y4g"));
    //   final rcv84 = await secureStore?.read(
    //       key: testWalletId + "_receiveDerivationsP2WPKH");
    //   await secureStore?.write(
    //       key: testWalletId + "_receiveDerivationsP2WPKH",
    //       value: rcv84?.replaceFirst(
    //           "bc1qggtj4ka8jsaj44hhd5mpamx7mp34m2d3w7k0m0",
    //           "bc1q42lja79elem0anu8q8s3h2n687re9jax556pcc"));
    //
    //   final data = await btc?.fetchBuildTxData(utxoList);
    //
    //   // give bad data toi build tx
    //   data["ed32c967a0e86d51669ac21c2bb9bc9c50f0f55fbacdd8db21d0a986fba93bd7"]
    //       ["keyPair"] = null;
    //
    //   bool didThrow = false;
    //   try {
    //     await btc?.buildTransaction(
    //         utxosToUse: utxoList,
    //         utxoSigningData: data!,
    //         recipients: ["bc1q42lja79elem0anu8q8s3h2n687re9jax556pcc"],
    //         satoshiAmounts: [13000]);
    //   } catch (_) {
    //     didThrow = true;
    //   }
    //   expect(didThrow, true);
    //
    //   verify(client?.getServerFeatures()).called(1);
    //   verify(cachedClient?.getTransaction(
    //           tx_hash:
    //               "2087ce09bc316877c9f10971526a2bffa3078d52ea31752639305cdcd8230703",
    //           coinName: "Bitcoin",
    //           callOutSideMainIsolate: false))
    //       .called(1);
    //   verify(cachedClient?.getTransaction(
    //           tx_hash:
    //               "ed32c967a0e86d51669ac21c2bb9bc9c50f0f55fbacdd8db21d0a986fba93bd7",
    //           coinName: "Bitcoin",
    //           callOutSideMainIsolate: false))
    //       .called(1);
    //   verify(cachedClient?.getTransaction(
    //           tx_hash:
    //               "3f0032f89ac44b281b50314cff3874c969c922839dddab77ced54e86a21c3fd4",
    //           coinName: "Bitcoin",
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
    //
    // test("two output coinSelection succeeds", () async {
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
    //       .thenAnswer((_) async => [
    //             {"height": 1000, "tx_hash": "some tx hash"}
    //           ]);
    //   when(cachedClient?.getTransaction(
    //           tx_hash:
    //               "2087ce09bc316877c9f10971526a2bffa3078d52ea31752639305cdcd8230703",
    //           coinName: "Bitcoin",
    //           callOutSideMainIsolate: false))
    //       .thenAnswer((_) async => tx9Raw);
    //   when(cachedClient?.getTransaction(
    //           tx_hash:
    //               "ed32c967a0e86d51669ac21c2bb9bc9c50f0f55fbacdd8db21d0a986fba93bd7",
    //           coinName: "Bitcoin",
    //           callOutSideMainIsolate: false))
    //       .thenAnswer((_) async => tx10Raw);
    //   when(cachedClient?.getTransaction(
    //           tx_hash:
    //               "3f0032f89ac44b281b50314cff3874c969c922839dddab77ced54e86a21c3fd4",
    //           coinName: "Bitcoin",
    //           callOutSideMainIsolate: false))
    //       .thenAnswer((_) async => tx11Raw);
    //
    //   // recover to fill data
    //   await btc?.recoverFromMnemonic(
    //       mnemonic: TEST_MNEMONIC,
    //       maxUnusedAddressGap: 2,
    //       maxNumberOfIndexesToCheck: 1000);
    //
    //   // modify addresses to properly mock data to build a tx
    //   final rcv44 = await secureStore?.read(
    //       key: testWalletId + "_receiveDerivationsP2PKH");
    //   await secureStore?.write(
    //       key: testWalletId + "_receiveDerivationsP2PKH",
    //       value: rcv44?.replaceFirst("1RMSPixoLPuaXuhR2v4HsUMcRjLncKDaw",
    //           "16FuTPaeRSPVxxCnwQmdyx2PQWxX6HWzhQ"));
    //   final rcv49 = await secureStore?.read(
    //       key: testWalletId + "_receiveDerivationsP2SH");
    //   await secureStore?.write(
    //       key: testWalletId + "_receiveDerivationsP2SH",
    //       value: rcv49?.replaceFirst("3AV74rKfibWmvX34F99yEvUcG4LLQ9jZZk",
    //           "36NvZTcMsMowbt78wPzJaHHWaNiyR73Y4g"));
    //   final rcv84 = await secureStore?.read(
    //       key: testWalletId + "_receiveDerivationsP2WPKH");
    //   await secureStore?.write(
    //       key: testWalletId + "_receiveDerivationsP2WPKH",
    //       value: rcv84?.replaceFirst(
    //           "bc1qggtj4ka8jsaj44hhd5mpamx7mp34m2d3w7k0m0",
    //           "bc1q42lja79elem0anu8q8s3h2n687re9jax556pcc"));
    //
    //   final result = await btc?.coinSelection(
    //       18000, 1000, "bc1q42lja79elem0anu8q8s3h2n687re9jax556pcc",
    //       utxos: utxoList);
    //
    //   expect(result, isA<Map<String, dynamic>>());
    //   expect(result.length > 0, true);
    //
    //   verify(client?.getServerFeatures()).called(1);
    //   verify(cachedClient?.getTransaction(
    //           tx_hash:
    //               "2087ce09bc316877c9f10971526a2bffa3078d52ea31752639305cdcd8230703",
    //           coinName: "Bitcoin",
    //           callOutSideMainIsolate: false))
    //       .called(1);
    //   verify(cachedClient?.getTransaction(
    //           tx_hash:
    //               "ed32c967a0e86d51669ac21c2bb9bc9c50f0f55fbacdd8db21d0a986fba93bd7",
    //           coinName: "Bitcoin",
    //           callOutSideMainIsolate: false))
    //       .called(1);
    //   verify(cachedClient?.getTransaction(
    //           tx_hash:
    //               "3f0032f89ac44b281b50314cff3874c969c922839dddab77ced54e86a21c3fd4",
    //           coinName: "Bitcoin",
    //           callOutSideMainIsolate: false))
    //       .called(1);
    //   verify(client?.getBatchHistory(args: historyBatchArgs0)).called(1);
    //   verify(client?.getBatchHistory(args: historyBatchArgs1)).called(1);
    //   verify(client?.getHistory(scripthash: anyNamed("scripthash"))).called(1);
    //
    //   expect(secureStore?.interactions, 29);
    //   expect(secureStore?.writes, 11);
    //   expect(secureStore?.reads, 18);
    //   expect(secureStore?.deletes, 0);
    //
    //   verifyNoMoreInteractions(client);
    //   verifyNoMoreInteractions(cachedClient);
    //   verifyNoMoreInteractions(priceAPI);
    // });
    //
    // test("one output option A coinSelection", () async {
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
    //       .thenAnswer((_) async => [
    //             {"height": 1000, "tx_hash": "some tx hash"}
    //           ]);
    //   when(cachedClient?.getTransaction(
    //           tx_hash:
    //               "2087ce09bc316877c9f10971526a2bffa3078d52ea31752639305cdcd8230703",
    //           coinName: "Bitcoin",
    //           callOutSideMainIsolate: false))
    //       .thenAnswer((_) async => tx9Raw);
    //   when(cachedClient?.getTransaction(
    //           tx_hash:
    //               "ed32c967a0e86d51669ac21c2bb9bc9c50f0f55fbacdd8db21d0a986fba93bd7",
    //           coinName: "Bitcoin",
    //           callOutSideMainIsolate: false))
    //       .thenAnswer((_) async => tx10Raw);
    //   when(cachedClient?.getTransaction(
    //           tx_hash:
    //               "3f0032f89ac44b281b50314cff3874c969c922839dddab77ced54e86a21c3fd4",
    //           coinName: "Bitcoin",
    //           callOutSideMainIsolate: false))
    //       .thenAnswer((_) async => tx11Raw);
    //
    //   // recover to fill data
    //   await btc?.recoverFromMnemonic(
    //       mnemonic: TEST_MNEMONIC,
    //       maxUnusedAddressGap: 2,
    //       maxNumberOfIndexesToCheck: 1000);
    //
    //   // modify addresses to properly mock data to build a tx
    //   final rcv44 = await secureStore?.read(
    //       key: testWalletId + "_receiveDerivationsP2PKH");
    //   await secureStore?.write(
    //       key: testWalletId + "_receiveDerivationsP2PKH",
    //       value: rcv44?.replaceFirst("1RMSPixoLPuaXuhR2v4HsUMcRjLncKDaw",
    //           "16FuTPaeRSPVxxCnwQmdyx2PQWxX6HWzhQ"));
    //   final rcv49 = await secureStore?.read(
    //       key: testWalletId + "_receiveDerivationsP2SH");
    //   await secureStore?.write(
    //       key: testWalletId + "_receiveDerivationsP2SH",
    //       value: rcv49?.replaceFirst("3AV74rKfibWmvX34F99yEvUcG4LLQ9jZZk",
    //           "36NvZTcMsMowbt78wPzJaHHWaNiyR73Y4g"));
    //   final rcv84 = await secureStore?.read(
    //       key: testWalletId + "_receiveDerivationsP2WPKH");
    //   await secureStore?.write(
    //       key: testWalletId + "_receiveDerivationsP2WPKH",
    //       value: rcv84?.replaceFirst(
    //           "bc1qggtj4ka8jsaj44hhd5mpamx7mp34m2d3w7k0m0",
    //           "bc1q42lja79elem0anu8q8s3h2n687re9jax556pcc"));
    //
    //   final result = await btc?.coinSelection(
    //       18500, 1000, "bc1q42lja79elem0anu8q8s3h2n687re9jax556pcc",
    //       utxos: utxoList);
    //
    //   expect(result, isA<Map<String, dynamic>>());
    //   expect(result.length > 0, true);
    //
    //   verify(client?.getServerFeatures()).called(1);
    //   verify(cachedClient?.getTransaction(
    //           tx_hash:
    //               "2087ce09bc316877c9f10971526a2bffa3078d52ea31752639305cdcd8230703",
    //           coinName: "Bitcoin",
    //           callOutSideMainIsolate: false))
    //       .called(1);
    //   verify(cachedClient.getTransaction(
    //           tx_hash:
    //               "ed32c967a0e86d51669ac21c2bb9bc9c50f0f55fbacdd8db21d0a986fba93bd7",
    //           coinName: "Bitcoin",
    //           callOutSideMainIsolate: false))
    //       .called(1);
    //   verify(cachedClient.getTransaction(
    //           tx_hash:
    //               "3f0032f89ac44b281b50314cff3874c969c922839dddab77ced54e86a21c3fd4",
    //           coinName: "Bitcoin",
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
    //
    // test("one output option B coinSelection", () async {
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
    //       .thenAnswer((_) async => [
    //             {"height": 1000, "tx_hash": "some tx hash"}
    //           ]);
    //   when(cachedClient?.getTransaction(
    //           tx_hash:
    //               "2087ce09bc316877c9f10971526a2bffa3078d52ea31752639305cdcd8230703",
    //           coinName: "Bitcoin",
    //           callOutSideMainIsolate: false))
    //       .thenAnswer((_) async => tx9Raw);
    //   when(cachedClient?.getTransaction(
    //           tx_hash:
    //               "ed32c967a0e86d51669ac21c2bb9bc9c50f0f55fbacdd8db21d0a986fba93bd7",
    //           coinName: "Bitcoin",
    //           callOutSideMainIsolate: false))
    //       .thenAnswer((_) async => tx10Raw);
    //   when(cachedClient?.getTransaction(
    //           tx_hash:
    //               "3f0032f89ac44b281b50314cff3874c969c922839dddab77ced54e86a21c3fd4",
    //           coinName: "Bitcoin",
    //           callOutSideMainIsolate: false))
    //       .thenAnswer((_) async => tx11Raw);
    //
    //   // recover to fill data
    //   await btc?.recoverFromMnemonic(
    //       mnemonic: TEST_MNEMONIC,
    //       maxUnusedAddressGap: 2,
    //       maxNumberOfIndexesToCheck: 1000);
    //
    //   // modify addresses to properly mock data to build a tx
    //   final rcv44 = await secureStore?.read(
    //       key: testWalletId + "_receiveDerivationsP2PKH");
    //   await secureStore?.write(
    //       key: testWalletId + "_receiveDerivationsP2PKH",
    //       value: rcv44?.replaceFirst("1RMSPixoLPuaXuhR2v4HsUMcRjLncKDaw",
    //           "16FuTPaeRSPVxxCnwQmdyx2PQWxX6HWzhQ"));
    //   final rcv49 =
    //       await secureStore?.read(key: testWalletId + "_receiveDerivationsP2SH");
    //   await secureStore?.write(
    //       key: testWalletId + "_receiveDerivationsP2SH",
    //       value: rcv49?.replaceFirst("3AV74rKfibWmvX34F99yEvUcG4LLQ9jZZk",
    //           "36NvZTcMsMowbt78wPzJaHHWaNiyR73Y4g"));
    //   final rcv84 = await secureStore?.read(
    //       key: testWalletId + "_receiveDerivationsP2WPKH");
    //   await secureStore?.write(
    //       key: testWalletId + "_receiveDerivationsP2WPKH",
    //       value: rcv84?.replaceFirst(
    //           "bc1qggtj4ka8jsaj44hhd5mpamx7mp34m2d3w7k0m0",
    //           "bc1q42lja79elem0anu8q8s3h2n687re9jax556pcc"));
    //
    //   final result = await btc?.coinSelection(
    //       18651, 1000, "bc1q42lja79elem0anu8q8s3h2n687re9jax556pcc",
    //       utxos: utxoList);
    //
    //   expect(result, isA<Map<String, dynamic>>());
    //   expect(result.length > 0, true);
    //
    //   verify(client?.getServerFeatures()).called(1);
    //   verify(cachedClient?.getTransaction(
    //           tx_hash:
    //               "2087ce09bc316877c9f10971526a2bffa3078d52ea31752639305cdcd8230703",
    //           coinName: "Bitcoin",
    //           callOutSideMainIsolate: false))
    //       .called(1);
    //   verify(cachedClient?.getTransaction(
    //           tx_hash:
    //               "ed32c967a0e86d51669ac21c2bb9bc9c50f0f55fbacdd8db21d0a986fba93bd7",
    //           coinName: "Bitcoin",
    //           callOutSideMainIsolate: false))
    //       .called(1);
    //   verify(cachedClient?.getTransaction(
    //           tx_hash:
    //               "3f0032f89ac44b281b50314cff3874c969c922839dddab77ced54e86a21c3fd4",
    //           coinName: "Bitcoin",
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
    //
    // test("insufficient funds option A coinSelection", () async {
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
    //
    //   // recover to fill data
    //   await btc?.recoverFromMnemonic(
    //       mnemonic: TEST_MNEMONIC,
    //       maxUnusedAddressGap: 2,
    //       maxNumberOfIndexesToCheck: 1000);
    //
    //   // modify addresses to properly mock data to build a tx
    //   final rcv44 = await secureStore?.read(
    //       key: testWalletId + "_receiveDerivationsP2PKH");
    //   await secureStore?.write(
    //       key: testWalletId + "_receiveDerivationsP2PKH",
    //       value: rcv44?.replaceFirst("1RMSPixoLPuaXuhR2v4HsUMcRjLncKDaw",
    //           "16FuTPaeRSPVxxCnwQmdyx2PQWxX6HWzhQ"));
    //   final rcv49 =
    //       await secureStore?.read(key: testWalletId + "_receiveDerivationsP2SH");
    //   await secureStore?.write(
    //       key: testWalletId + "_receiveDerivationsP2SH",
    //       value: rcv49?.replaceFirst("3AV74rKfibWmvX34F99yEvUcG4LLQ9jZZk",
    //           "36NvZTcMsMowbt78wPzJaHHWaNiyR73Y4g"));
    //   final rcv84 = await secureStore?.read(
    //       key: testWalletId + "_receiveDerivationsP2WPKH");
    //   await secureStore?.write(
    //       key: testWalletId + "_receiveDerivationsP2WPKH",
    //       value: rcv84?.replaceFirst(
    //           "bc1qggtj4ka8jsaj44hhd5mpamx7mp34m2d3w7k0m0",
    //           "bc1q42lja79elem0anu8q8s3h2n687re9jax556pcc"));
    //
    //   final result = await btc?.coinSelection(
    //       20000, 1000, "bc1q42lja79elem0anu8q8s3h2n687re9jax556pcc",
    //       utxos: utxoList);
    //
    //   expect(result, 1);
    //
    //   verify(client?.getServerFeatures()).called(1);
    //   verify(client?.getBatchHistory(args: historyBatchArgs0)).called(1);
    //   verify(client?.getBatchHistory(args: historyBatchArgs1)).called(1);
    //
    //   expect(secureStore?.interactions, 20);
    //   expect(secureStore?.writes, 10);
    //   expect(secureStore?.reads, 10);
    //   expect(secureStore?.deletes, 0);
    //
    //   verifyNoMoreInteractions(client);
    //   verifyNoMoreInteractions(cachedClient);
    //   verifyNoMoreInteractions(priceAPI);
    // });
    //
    // test("insufficient funds option B coinSelection", () async {
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
    //
    //   // recover to fill data
    //   await btc?.recoverFromMnemonic(
    //       mnemonic: TEST_MNEMONIC,
    //       maxUnusedAddressGap: 2,
    //       maxNumberOfIndexesToCheck: 1000);
    //
    //   // modify addresses to properly mock data to build a tx
    //   final rcv44 = await secureStore?.read(
    //       key: testWalletId + "_receiveDerivationsP2PKH");
    //   await secureStore?.write(
    //       key: testWalletId + "_receiveDerivationsP2PKH",
    //       value: rcv44?.replaceFirst("1RMSPixoLPuaXuhR2v4HsUMcRjLncKDaw",
    //           "16FuTPaeRSPVxxCnwQmdyx2PQWxX6HWzhQ"));
    //   final rcv49 =
    //       await secureStore?.read(key: testWalletId + "_receiveDerivationsP2SH");
    //   await secureStore?.write(
    //       key: testWalletId + "_receiveDerivationsP2SH",
    //       value: rcv49?.replaceFirst("3AV74rKfibWmvX34F99yEvUcG4LLQ9jZZk",
    //           "36NvZTcMsMowbt78wPzJaHHWaNiyR73Y4g"));
    //   final rcv84 = await secureStore?.read(
    //       key: testWalletId + "_receiveDerivationsP2WPKH");
    //   await secureStore?.write(
    //       key: testWalletId + "_receiveDerivationsP2WPKH",
    //       value: rcv84?.replaceFirst(
    //           "bc1qggtj4ka8jsaj44hhd5mpamx7mp34m2d3w7k0m0",
    //           "bc1q42lja79elem0anu8q8s3h2n687re9jax556pcc"));
    //
    //   final result = await btc?.coinSelection(
    //       19000, 1000, "bc1q42lja79elem0anu8q8s3h2n687re9jax556pcc",
    //       utxos: utxoList);
    //
    //   expect(result, 2);
    //
    //   verify(client?.getServerFeatures()).called(1);
    //   verify(client?.getBatchHistory(args: historyBatchArgs0)).called(1);
    //   verify(client?.getBatchHistory(args: historyBatchArgs1)).called(1);
    //
    //   expect(secureStore?.interactions, 20);
    //   expect(secureStore?.writes, 10);
    //   expect(secureStore?.reads, 10);
    //   expect(secureStore?.deletes, 0);
    //
    //   verifyNoMoreInteractions(client);
    //   verifyNoMoreInteractions(cachedClient);
    //   verifyNoMoreInteractions(priceAPI);
    // });
    //
    // test("insufficient funds option C coinSelection", () async {
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
    //   when(cachedClient.?getTransaction(
    //           tx_hash:
    //               "2087ce09bc316877c9f10971526a2bffa3078d52ea31752639305cdcd8230703",
    //           coinName: "Bitcoin",
    //           callOutSideMainIsolate: false))
    //       .thenAnswer((_) async => tx9Raw);
    //   when(cachedClient?.getTransaction(
    //           tx_hash:
    //               "ed32c967a0e86d51669ac21c2bb9bc9c50f0f55fbacdd8db21d0a986fba93bd7",
    //           coinName: "Bitcoin",
    //           callOutSideMainIsolate: false))
    //       .thenAnswer((_) async => tx10Raw);
    //   when(cachedClient?.getTransaction(
    //           tx_hash:
    //               "3f0032f89ac44b281b50314cff3874c969c922839dddab77ced54e86a21c3fd4",
    //           coinName: "Bitcoin",
    //           callOutSideMainIsolate: false))
    //       .thenAnswer((_) async => tx11Raw);
    //
    //   // recover to fill data
    //   await btc?.recoverFromMnemonic(
    //       mnemonic: TEST_MNEMONIC,
    //       maxUnusedAddressGap: 2,
    //       maxNumberOfIndexesToCheck: 1000);
    //
    //   // modify addresses to properly mock data to build a tx
    //   final rcv44 = await secureStore?.read(
    //       key: testWalletId + "_receiveDerivationsP2PKH");
    //   await secureStore?.write(
    //       key: testWalletId + "_receiveDerivationsP2PKH",
    //       value: rcv44?.replaceFirst("1RMSPixoLPuaXuhR2v4HsUMcRjLncKDaw",
    //           "16FuTPaeRSPVxxCnwQmdyx2PQWxX6HWzhQ"));
    //   final rcv49 =
    //       await secureStore?.read(key: testWalletId + "_receiveDerivationsP2SH");
    //   await secureStore?.write(
    //       key: testWalletId + "_receiveDerivationsP2SH",
    //       value: rcv49?.replaceFirst("3AV74rKfibWmvX34F99yEvUcG4LLQ9jZZk",
    //           "36NvZTcMsMowbt78wPzJaHHWaNiyR73Y4g"));
    //   final rcv84 = await secureStore?.read(
    //       key: testWalletId + "_receiveDerivationsP2WPKH");
    //   await secureStore?.write(
    //       key: testWalletId + "_receiveDerivationsP2WPKH",
    //       value: rcv84?.replaceFirst(
    //           "bc1qggtj4ka8jsaj44hhd5mpamx7mp34m2d3w7k0m0",
    //           "bc1q42lja79elem0anu8q8s3h2n687re9jax556pcc"));
    //
    //   final result = await btc?.coinSelection(
    //       18900, 1000, "bc1q42lja79elem0anu8q8s3h2n687re9jax556pcc",
    //       utxos: utxoList);
    //
    //   expect(result, 2);
    //
    //   verify(client?.getServerFeatures()).called(1);
    //   verify(client?.getBatchHistory(args: historyBatchArgs0)).called(1);
    //   verify(client?.getBatchHistory(args: historyBatchArgs1)).called(1);
    //   verify(cachedClient?.getTransaction(
    //           tx_hash:
    //               "2087ce09bc316877c9f10971526a2bffa3078d52ea31752639305cdcd8230703",
    //           coinName: "Bitcoin",
    //           callOutSideMainIsolate: false))
    //       .called(1);
    //   verify(cachedClient?.getTransaction(
    //           tx_hash:
    //               "ed32c967a0e86d51669ac21c2bb9bc9c50f0f55fbacdd8db21d0a986fba93bd7",
    //           coinName: "Bitcoin",
    //           callOutSideMainIsolate: false))
    //       .called(1);
    //   verify(cachedClient?.getTransaction(
    //           tx_hash:
    //               "3f0032f89ac44b281b50314cff3874c969c922839dddab77ced54e86a21c3fd4",
    //           coinName: "Bitcoin",
    //           callOutSideMainIsolate: false))
    //       .called(1);
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
    //
    // test("check for more outputs coinSelection", () async {
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
    //           tx_hash:
    //               "2087ce09bc316877c9f10971526a2bffa3078d52ea31752639305cdcd8230703",
    //           coinName: "Bitcoin",
    //           callOutSideMainIsolate: false))
    //       .thenAnswer((_) async => tx9Raw);
    //   when(cachedClient?.getTransaction(
    //           tx_hash:
    //               "ed32c967a0e86d51669ac21c2bb9bc9c50f0f55fbacdd8db21d0a986fba93bd7",
    //           coinName: "Bitcoin",
    //           callOutSideMainIsolate: false))
    //       .thenAnswer((_) async => tx10Raw);
    //   when(cachedClient?.getTransaction(
    //           tx_hash:
    //               "3f0032f89ac44b281b50314cff3874c969c922839dddab77ced54e86a21c3fd4",
    //           coinName: "Bitcoin",
    //           callOutSideMainIsolate: false))
    //       .thenAnswer((_) async => tx11Raw);
    //
    //   // recover to fill data
    //   await btc?.recoverFromMnemonic(
    //       mnemonic: TEST_MNEMONIC,
    //       maxUnusedAddressGap: 2,
    //       maxNumberOfIndexesToCheck: 1000);
    //
    //   // modify addresses to properly mock data to build a tx
    //   final rcv44 = await secureStore?.read(
    //       key: testWalletId + "_receiveDerivationsP2PKH");
    //   await secureStore?.write(
    //       key: testWalletId + "_receiveDerivationsP2PKH",
    //       value: rcv44?.replaceFirst("1RMSPixoLPuaXuhR2v4HsUMcRjLncKDaw",
    //           "16FuTPaeRSPVxxCnwQmdyx2PQWxX6HWzhQ"));
    //   final rcv49 =
    //       await secureStore?.read(key: testWalletId + "_receiveDerivationsP2SH");
    //   await secureStore?.write(
    //       key: testWalletId + "_receiveDerivationsP2SH",
    //       value: rcv49?.replaceFirst("3AV74rKfibWmvX34F99yEvUcG4LLQ9jZZk",
    //           "36NvZTcMsMowbt78wPzJaHHWaNiyR73Y4g"));
    //   final rcv84 = await secureStore?.read(
    //       key: testWalletId + "_receiveDerivationsP2WPKH");
    //   await secureStore?.write(
    //       key: testWalletId + "_receiveDerivationsP2WPKH",
    //       value: rcv84?.replaceFirst(
    //           "bc1qggtj4ka8jsaj44hhd5mpamx7mp34m2d3w7k0m0",
    //           "bc1q42lja79elem0anu8q8s3h2n687re9jax556pcc"));
    //   when(client?.getHistory(scripthash: anyNamed("scripthash")))
    //       .thenAnswer((_) async => [
    //             {"height": 1000, "tx_hash": "some tx hash"}
    //           ]);
    //
    //   final result = await btc?.coinSelection(
    //       11900, 1000, "bc1q42lja79elem0anu8q8s3h2n687re9jax556pcc",
    //       utxos: utxoList);
    //
    //   expect(result, isA<Map<String, dynamic>>());
    //   expect(result.length > 0, true);
    //
    //   verify(client?.getServerFeatures()).called(1);
    //   verify(client?.getBatchHistory(args: historyBatchArgs0)).called(1);
    //   verify(client?.getBatchHistory(args: historyBatchArgs1)).called(1);
    //   verify(cachedClient?.getTransaction(
    //           tx_hash:
    //               "2087ce09bc316877c9f10971526a2bffa3078d52ea31752639305cdcd8230703",
    //           coinName: "Bitcoin",
    //           callOutSideMainIsolate: false))
    //       .called(2);
    //   verify(cachedClient?.getTransaction(
    //           tx_hash:
    //               "ed32c967a0e86d51669ac21c2bb9bc9c50f0f55fbacdd8db21d0a986fba93bd7",
    //           coinName: "Bitcoin",
    //           callOutSideMainIsolate: false))
    //       .called(2);
    //   verify(cachedClient?.getTransaction(
    //           tx_hash:
    //               "3f0032f89ac44b281b50314cff3874c969c922839dddab77ced54e86a21c3fd4",
    //           coinName: "Bitcoin",
    //           callOutSideMainIsolate: false))
    //       .called(1);
    //
    //   verify(client?.getHistory(scripthash: anyNamed("scripthash"))).called(1);
    //
    //   expect(secureStore?.interactions, 33);
    //   expect(secureStore?.writes, 11);
    //   expect(secureStore?.reads, 22);
    //   expect(secureStore?.deletes, 0);
    //
    //   verifyNoMoreInteractions(client);
    //   verifyNoMoreInteractions(cachedClient);
    //   verifyNoMoreInteractions(priceAPI);
    // });
    //
    // test("prepareSend and confirmSend succeed", () async {
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
    //       .thenAnswer((_) async => [
    //             {"height": 1000, "tx_hash": "some tx hash"}
    //           ]);
    //   when(cachedClient?.getTransaction(
    //           tx_hash:
    //               "2087ce09bc316877c9f10971526a2bffa3078d52ea31752639305cdcd8230703",
    //           coinName: "Bitcoin",
    //           callOutSideMainIsolate: false))
    //       .thenAnswer((_) async => tx9Raw);
    //   when(cachedClient?.getTransaction(
    //           tx_hash:
    //               "ed32c967a0e86d51669ac21c2bb9bc9c50f0f55fbacdd8db21d0a986fba93bd7",
    //           coinName: "Bitcoin",
    //           callOutSideMainIsolate: false))
    //       .thenAnswer((_) async => tx10Raw);
    //   when(cachedClient?.getTransaction(
    //           tx_hash:
    //               "3f0032f89ac44b281b50314cff3874c969c922839dddab77ced54e86a21c3fd4",
    //           coinName: "Bitcoin",
    //           callOutSideMainIsolate: false))
    //       .thenAnswer((_) async => tx11Raw);
    //
    //   // recover to fill data
    //   await btc?.recoverFromMnemonic(
    //       mnemonic: TEST_MNEMONIC,
    //       maxUnusedAddressGap: 2,
    //       maxNumberOfIndexesToCheck: 1000);
    //
    //   // modify addresses to properly mock data to build a tx
    //   final rcv44 = await secureStore?.read(
    //       key: testWalletId + "_receiveDerivationsP2PKH");
    //   await secureStore?.write(
    //       key: testWalletId + "_receiveDerivationsP2PKH",
    //       value: rcv44?.replaceFirst("1RMSPixoLPuaXuhR2v4HsUMcRjLncKDaw",
    //           "16FuTPaeRSPVxxCnwQmdyx2PQWxX6HWzhQ"));
    //   final rcv49 = await secureStore?.read(
    //       key: testWalletId + "_receiveDerivationsP2SH");
    //   await secureStore?.write(
    //       key: testWalletId + "_receiveDerivationsP2SH",
    //       value: rcv49?.replaceFirst("3AV74rKfibWmvX34F99yEvUcG4LLQ9jZZk",
    //           "36NvZTcMsMowbt78wPzJaHHWaNiyR73Y4g"));
    //   final rcv84 = await secureStore?.read(
    //       key: testWalletId + "_receiveDerivationsP2WPKH");
    //   await secureStore?.write(
    //       key: testWalletId + "_receiveDerivationsP2WPKH",
    //       value: rcv84?.replaceFirst(
    //           "bc1qggtj4ka8jsaj44hhd5mpamx7mp34m2d3w7k0m0",
    //           "bc1q42lja79elem0anu8q8s3h2n687re9jax556pcc"));
    //
    //   btc?.outputsList = utxoList;
    //
    //   final result = await btc?.prepareSend(
    //       toAddress: "bc1q42lja79elem0anu8q8s3h2n687re9jax556pcc",
    //       amount: 15000);
    //
    //   expect(result, isA<Map<String, dynamic>>());
    //   expect(result?.length! > 0, true);
    //
    //   when(client?.broadcastTransaction(
    //           rawTx: result!["hex"], requestID: anyNamed("requestID")))
    //       .thenAnswer((_) async => "some txHash");
    //
    //   final sentResult = await btc?.confirmSend(txData: result!);
    //   expect(sentResult, "some txHash");
    //
    //   verify(client?.getServerFeatures()).called(1);
    //   verify(cachedClient?.getTransaction(
    //           tx_hash:
    //               "2087ce09bc316877c9f10971526a2bffa3078d52ea31752639305cdcd8230703",
    //           coinName: "Bitcoin",
    //           callOutSideMainIsolate: false))
    //       .called(1);
    //   verify(cachedClient?.getTransaction(
    //           tx_hash:
    //               "ed32c967a0e86d51669ac21c2bb9bc9c50f0f55fbacdd8db21d0a986fba93bd7",
    //           coinName: "Bitcoin",
    //           callOutSideMainIsolate: false))
    //       .called(1);
    //   verify(cachedClient?.getTransaction(
    //           tx_hash:
    //               "3f0032f89ac44b281b50314cff3874c969c922839dddab77ced54e86a21c3fd4",
    //           coinName: "Bitcoin",
    //           callOutSideMainIsolate: false))
    //       .called(1);
    //   verify(client?.getBatchHistory(args: historyBatchArgs0)).called(1);
    //   verify(client?.getBatchHistory(args: historyBatchArgs1)).called(1);
    //   verify(client?.broadcastTransaction(
    //           rawTx: result!["hex"], requestID: anyNamed("requestID")))
    //       .called(1);
    //   verify(client?.getHistory(scripthash: anyNamed("scripthash"))).called(1);
    //
    //   expect(secureStore?.interactions, 29);
    //   expect(secureStore?.writes, 11);
    //   expect(secureStore?.reads, 18);
    //   expect(secureStore?.deletes, 0);
    //
    //   verifyNoMoreInteractions(client);
    //   verifyNoMoreInteractions(cachedClient);
    //   verifyNoMoreInteractions(priceAPI);
    // });

    test("prepareSend fails", () async {
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

      final wallet = await Hive.openBox(testWalletId);

      when(cachedClient?.getTransaction(
              txHash:
                  "2087ce09bc316877c9f10971526a2bffa3078d52ea31752639305cdcd8230703",
              coin: Coin.bitcoin))
          .thenAnswer((_) async => tx9Raw);
      when(cachedClient?.getTransaction(
              txHash:
                  "ed32c967a0e86d51669ac21c2bb9bc9c50f0f55fbacdd8db21d0a986fba93bd7",
              coin: Coin.bitcoin))
          .thenAnswer((_) async => tx10Raw);
      when(cachedClient?.getTransaction(
        txHash:
            "3f0032f89ac44b281b50314cff3874c969c922839dddab77ced54e86a21c3fd4",
        coin: Coin.bitcoin,
      )).thenAnswer((_) async => tx11Raw);

      // recover to fill data
      await btc?.recoverFromMnemonic(
          mnemonic: TEST_MNEMONIC,
          maxUnusedAddressGap: 2,
          maxNumberOfIndexesToCheck: 1000,
          height: 4000);

      // modify addresses to properly mock data to build a tx
      final rcv44 = await secureStore?.read(
          key: testWalletId + "_receiveDerivationsP2PKH");
      await secureStore?.write(
          key: testWalletId + "_receiveDerivationsP2PKH",
          value: rcv44?.replaceFirst("1RMSPixoLPuaXuhR2v4HsUMcRjLncKDaw",
              "16FuTPaeRSPVxxCnwQmdyx2PQWxX6HWzhQ"));
      final rcv49 = await secureStore?.read(
          key: testWalletId + "_receiveDerivationsP2SH");
      await secureStore?.write(
          key: testWalletId + "_receiveDerivationsP2SH",
          value: rcv49?.replaceFirst("3AV74rKfibWmvX34F99yEvUcG4LLQ9jZZk",
              "36NvZTcMsMowbt78wPzJaHHWaNiyR73Y4g"));
      final rcv84 = await secureStore?.read(
          key: testWalletId + "_receiveDerivationsP2WPKH");
      await secureStore?.write(
          key: testWalletId + "_receiveDerivationsP2WPKH",
          value: rcv84?.replaceFirst(
              "bc1qggtj4ka8jsaj44hhd5mpamx7mp34m2d3w7k0m0",
              "bc1q42lja79elem0anu8q8s3h2n687re9jax556pcc"));

      btc?.outputsList = utxoList;

      bool didThrow = false;
      try {
        await btc?.prepareSend(
            address: "bc1q42lja79elem0anu8q8s3h2n687re9jax556pcc",
            satoshiAmount: 15000);
      } catch (_) {
        didThrow = true;
      }

      expect(didThrow, true);

      verify(client?.getServerFeatures()).called(1);

      /// verify transaction no matching calls

      // verify(cachedClient?.getTransaction(
      //         txHash:
      //             "2087ce09bc316877c9f10971526a2bffa3078d52ea31752639305cdcd8230703",
      //         coin: Coin.bitcoin,
      //         callOutSideMainIsolate: false))
      //     .called(1);
      // verify(cachedClient?.getTransaction(
      //         txHash:
      //             "ed32c967a0e86d51669ac21c2bb9bc9c50f0f55fbacdd8db21d0a986fba93bd7",
      //         coin: Coin.bitcoin,
      //         callOutSideMainIsolate: false))
      //     .called(1);
      // verify(cachedClient?.getTransaction(
      //         txHash:
      //             "3f0032f89ac44b281b50314cff3874c969c922839dddab77ced54e86a21c3fd4",
      //         coin: Coin.bitcoin,
      //         callOutSideMainIsolate: false))
      //     .called(1);
      verify(client?.getBatchHistory(args: historyBatchArgs0)).called(1);
      verify(client?.getBatchHistory(args: historyBatchArgs1)).called(1);

      expect(secureStore?.interactions, 20);
      expect(secureStore?.writes, 10);
      expect(secureStore?.reads, 10);
      expect(secureStore?.deletes, 0);

      verifyNoMoreInteractions(client);
      verifyNoMoreInteractions(cachedClient);
      verifyNoMoreInteractions(priceAPI);
    });

    test("confirmSend no hex", () async {
      bool didThrow = false;
      try {
        await btc?.confirmSend(txData: {"some": "strange map"});
      } catch (_) {
        didThrow = true;
      }

      expect(didThrow, true);

      expect(secureStore?.interactions, 0);
      verifyNoMoreInteractions(client);
      verifyNoMoreInteractions(cachedClient);
      verifyNoMoreInteractions(priceAPI);
    });

    test("confirmSend hex is not string", () async {
      bool didThrow = false;
      try {
        await btc?.confirmSend(txData: {"hex": true});
      } catch (_) {
        didThrow = true;
      }

      expect(didThrow, true);

      expect(secureStore?.interactions, 0);
      verifyNoMoreInteractions(client);
      verifyNoMoreInteractions(cachedClient);
      verifyNoMoreInteractions(priceAPI);
    });

    test("confirmSend hex is string but missing other data", () async {
      bool didThrow = false;
      try {
        await btc?.confirmSend(txData: {"hex": "a string"});
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
      verifyNoMoreInteractions(priceAPI);
    });

    test("confirmSend fails due to vSize being greater than fee", () async {
      bool didThrow = false;
      try {
        await btc
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
      verifyNoMoreInteractions(priceAPI);
    });

    test("confirmSend fails when broadcast transactions throws", () async {
      when(client?.broadcastTransaction(
              rawTx: "a string", requestID: anyNamed("requestID")))
          .thenThrow(Exception("some exception"));

      bool didThrow = false;
      try {
        await btc
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
    //
    // // this test will create a non mocked electrumx client that will try to connect
    // // to the provided ipAddress below. This will throw a bunch of errors
    // // which what we want here as actually calling electrumx calls here is unwanted.
    // // test("listen to NodesChangedEvent", () async {
    // //   btc = BitcoinWallet(
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
    // //   final a = btc.cachedElectrumXClient;
    // //
    // //   // return when refresh is called on node changed trigger
    // //   btc.longMutex = true;
    // //
    // //   GlobalEventBus.instance
    // //       .fire(NodesChangedEvent(NodesChangedEventType.updatedCurrentNode));
    // //
    // //   // make sure event has processed before continuing
    // //   await Future.delayed(Duration(seconds: 5));
    // //
    // //   final b = btc.cachedElectrumXClient;
    // //
    // //   expect(identical(a, b), false);
    // //
    // //   await btc.exit();
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

      final wallet = await Hive.openBox(testWalletId);

      // recover to fill data
      await btc?.recoverFromMnemonic(
          mnemonic: TEST_MNEMONIC,
          maxUnusedAddressGap: 2,
          maxNumberOfIndexesToCheck: 1000,
          height: 4000);

      btc?.refreshMutex = true;

      await btc?.refresh();

      verify(client?.getServerFeatures()).called(1);
      verify(client?.getBatchHistory(args: historyBatchArgs0)).called(1);
      verify(client?.getBatchHistory(args: historyBatchArgs1)).called(1);

      expect(secureStore?.interactions, 14);
      expect(secureStore?.writes, 7);
      expect(secureStore?.reads, 7);
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
      when(client?.getBatchHistory(args: historyBatchArgs1))
          .thenAnswer((_) async => historyBatchResponse);
      when(client?.getHistory(scripthash: anyNamed("scripthash")))
          .thenThrow(Exception("some exception"));

      final wallet = await Hive.openBox(testWalletId);

      // recover to fill data
      await btc?.recoverFromMnemonic(
          mnemonic: TEST_MNEMONIC,
          maxUnusedAddressGap: 2,
          maxNumberOfIndexesToCheck: 1000,
          height: 4000);

      await btc?.refresh();

      verify(client?.getServerFeatures()).called(1);
      verify(client?.getBatchHistory(args: historyBatchArgs0)).called(1);
      verify(client?.getBatchHistory(args: historyBatchArgs1)).called(1);
      verify(client?.getBlockHeadTip()).called(1);
      verify(client?.getHistory(scripthash: anyNamed("scripthash"))).called(1);

      expect(secureStore?.interactions, 14);
      expect(secureStore?.writes, 7);
      expect(secureStore?.reads, 7);
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
    //   // when(priceAPI.getBitcoinPrice(baseCurrency: "USD"))
    //   //     .thenAnswer((_) async => Decimal.one);
    //
    //   // recover to fill data
    //   await btc?.recoverFromMnemonic(
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
    //   await btc?.refresh();
    //
    //   verify(client?.getServerFeatures()).called(1);
    //   verify(client?.getBatchHistory(args: historyBatchArgs0)).called(1);
    //   verify(client?.getBatchHistory(args: historyBatchArgs1)).called(1);
    //   verify(client?.getBatchHistory(args: anyNamed("args"))).called(1);
    //   verify(client?.getBatchUTXOs(args: anyNamed("args"))).called(1);
    //   verify(client?.getHistory(scripthash: anyNamed("scripthash"))).called(4);
    //   verify(client?.estimateFee(blocks: anyNamed("blocks"))).called(3);
    //   verify(client?.getBlockHeadTip()).called(1);
    //   // verify(priceAPI.getBitcoinPrice(baseCurrency: "USD")).called(2);
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

    tearDown(() async {
      await tearDownTestHive();
    });
  });
}

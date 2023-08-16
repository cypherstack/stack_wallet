import 'dart:async';
import 'dart:convert';

import 'package:decimal/decimal.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:hive_test/hive_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:stackwallet/db/isar/main_db.dart';
import 'package:stackwallet/electrumx_rpc/cached_electrumx.dart';
import 'package:stackwallet/electrumx_rpc/electrumx.dart';
import 'package:stackwallet/models/isar/models/isar_models.dart';
import 'package:stackwallet/models/lelantus_fee_data.dart';
import 'package:stackwallet/models/paymint/transactions_model.dart' as old;
import 'package:stackwallet/services/coins/firo/firo_wallet.dart';
import 'package:stackwallet/services/transaction_notification_tracker.dart';
import 'package:stackwallet/utilities/amount/amount.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/utilities/flutter_secure_storage_interface.dart';

import 'firo_wallet_test.mocks.dart';
import 'firo_wallet_test_parameters.dart';
import 'sample_data/get_anonymity_set_sample_data.dart';
import 'sample_data/get_used_serials_sample_data.dart';
import 'sample_data/get_utxos_sample_data.dart';
import 'sample_data/gethistory_samples.dart';
import 'sample_data/transaction_data_samples.dart';

@GenerateMocks([
  ElectrumX,
  CachedElectrumX,
  TransactionNotificationTracker,
  MainDB,
])
void main() {
  group("isolate functions", () {
    test("isolateRestore success", () async {
      final cachedClient = MockCachedElectrumX();
      final txDataOLD = old.TransactionData.fromJson(dateTimeChunksJson);
      final Map<dynamic, dynamic> setData = {};
      setData[1] = GetAnonymitySetSampleData.data;
      final usedSerials = GetUsedSerialsSampleData.serials["serials"] as List;

      when(cachedClient.getTransaction(
        txHash: SampleGetTransactionData.txHash8,
        coin: Coin.firo,
      )).thenAnswer((_) async {
        return SampleGetTransactionData.txData8;
      });
      when(cachedClient.getTransaction(
        txHash: SampleGetTransactionData.txHash9,
        coin: Coin.firo,
      )).thenAnswer((_) async {
        return SampleGetTransactionData.txData9;
      });
      when(cachedClient.getTransaction(
        txHash: SampleGetTransactionData.txHash7,
        coin: Coin.firo,
      )).thenAnswer((_) async {
        return SampleGetTransactionData.txData7;
      });

      final message = await isolateRestore(
        TEST_MNEMONIC,
        "",
        Coin.firo,
        1,
        setData,
        List<String>.from(usedSerials),
        firoNetwork,
        "walletId",
      );
      const currentHeight = 100000000000;

      final txData = txDataOLD
          .getAllTransactions()
          .values
          .map(
            (t) => Transaction(
              walletId: "walletId",
              txid: t.txid,
              timestamp: t.timestamp,
              type: t.txType == "Sent"
                  ? TransactionType.outgoing
                  : TransactionType.incoming,
              subType: t.subType == "mint"
                  ? TransactionSubType.mint
                  : t.subType == "join"
                      ? TransactionSubType.join
                      : TransactionSubType.none,
              amount: t.amount,
              amountString: Amount(
                rawValue: BigInt.from(t.amount),
                fractionDigits: Coin.firo.decimals,
              ).toJsonString(),
              fee: t.fees,
              height: t.height,
              isCancelled: t.isCancelled,
              isLelantus: null,
              slateId: t.slateId,
              otherData: t.otherData,
              nonce: null,
              inputs: [],
              outputs: [],
              numberOfMessages: null,
            ),
          )
          .toList();

      final result = await staticProcessRestore(txData, message, currentHeight);

      expect(result, isA<Map<String, dynamic>>());
      expect(result["_lelantus_coins"], isA<List<LelantusCoin>>());
      expect(result["newTxMap"], isA<Map<String, Transaction>>());
    });

    test("isolateRestore throws", () async {
      final Map<dynamic, dynamic> setData = {};
      final usedSerials = <dynamic>[];

      expect(
          () => isolateRestore(
                TEST_MNEMONIC,
                "",
                Coin.firo,
                1,
                setData,
                List<String>.from(usedSerials),
                firoNetwork,
                "walletId",
              ),
          throwsA(isA<Error>()));
    });

    test("isolateCreateJoinSplitTransaction not enough funds", () async {
      final result = await isolateCreateJoinSplitTransaction(
        100,
        "aNmsUtzPzQ3SKWNjEH48GacMQJXWN5Rotm",
        false,
        TEST_MNEMONIC,
        "",
        2,
        [],
        459185,
        Coin.firo,
        firoNetwork,
        [GetAnonymitySetSampleData.data],
      );

      expect(result, 1);
    });

    // test("isolateCreateJoinSplitTransaction success", () async {
    //   final result = await isolateCreateJoinSplitTransaction(
    //     9000,
    //     "aNmsUtzPzQ3SKWNjEH48GacMQJXWN5Rotm",
    //     true,
    //     TEST_MNEMONIC,
    //     2,
    //     Decimal.ten,
    //     SampleLelantus.lelantusEntries,
    //     459185,
    //     Coin.firo,
    //     firoNetwork,
    //     [GetAnonymitySetSampleData.data],
    //     "en_US",
    //   );
    //
    //   expect(result, isA<Map<String, dynamic>>());
    // });

    test("isolateEstimateJoinSplitFee", () async {
      final result = await isolateEstimateJoinSplitFee(
        1000,
        false,
        SampleLelantus.lelantusEntries,
        Coin.firo,
      );

      expect(result, isA<LelantusFeeData>());
    });

    test("call getIsolate with missing args", () async {
      final receivePort = await getIsolate({
        "function": "estimateJoinSplit",
        "subtractFeeFromAmount": true,
      });
      expect(await receivePort.first, "Error");
    });

    test("call getIsolate with bad args", () async {
      final receivePort = await getIsolate({
        "function": "estimateJoinSplit",
        "spendAmount": "spendAmount",
        "subtractFeeFromAmount": true,
        "lelantusEntries": MockCachedElectrumX(),
      });
      expect(await receivePort.first, "Error");
    });
  });

  group("Other standalone functions in firo_wallet.dart", () {
    test("Firo main net parameters", () {
      expect(firoNetwork.messagePrefix, '\x18Zcoin Signed Message:\n');
      expect(firoNetwork.bech32, 'bc');
      expect(firoNetwork.bip32.private, 0x0488ade4);
      expect(firoNetwork.bip32.public, 0x0488b21e);
      expect(firoNetwork.pubKeyHash, 0x52);
      expect(firoNetwork.scriptHash, 0x07);
      expect(firoNetwork.wif, 0xd2);
    });

    test("Firo test net parameters", () {
      expect(firoTestNetwork.messagePrefix, '\x18Zcoin Signed Message:\n');
      expect(firoTestNetwork.bech32, 'bc');
      expect(firoTestNetwork.bip32.private, 0x04358394);
      expect(firoTestNetwork.bip32.public, 0x043587cf);
      expect(firoTestNetwork.pubKeyHash, 0x41);
      expect(firoTestNetwork.scriptHash, 0xb2);
      expect(firoTestNetwork.wif, 0xb9);
    });

    // group("getJMintTransactions", () {
    //   test(
    //       "getJMintTransactions throws Error due to some invalid transactions passed to this function",
    //       () {
    //     final cachedClient = MockCachedElectrumX();
    //
    //
    //     // mock price calls
    // when(priceAPI.getPricesAnd24hChange( baseCurrency: "USD"))
    //     .thenAnswer((_) async => {Coin.firo : Tuple2(Decimal.fromInt(10), 1.0)});
    //
    //     // mock transaction calls
    //     when(cachedClient.getTransaction(
    //             txHash: SampleGetTransactionData.txHash0,
    //             coin: Coin.firo,))
    //         .thenAnswer((_) async => SampleGetTransactionData.txData0);
    //     when(cachedClient.getTransaction(
    //             txHash: SampleGetTransactionData.txHash1,
    //             coin: Coin.firo,
    //             ))
    //         .thenAnswer((_) async => SampleGetTransactionData.txData1);
    //     when(cachedClient.getTransaction(
    //             txHash: SampleGetTransactionData.txHash2,
    //             coin: Coin.firo,
    //             ))
    //         .thenAnswer((_) async => SampleGetTransactionData.txData2);
    //     when(cachedClient.getTransaction(
    //             txHash: SampleGetTransactionData.txHash3,
    //             coin: Coin.firo,
    //             ))
    //         .thenAnswer((_) async => SampleGetTransactionData.txData3);
    //     when(cachedClient.getTransaction(
    //             txHash: SampleGetTransactionData.txHash4,
    //             coin: Coin.firo,
    //             ))
    //         .thenAnswer((_) async => SampleGetTransactionData.txData4);
    //     when(cachedClient.getTransaction(
    //             txHash: SampleGetTransactionData.txHash5,
    //             coin: Coin.firo,
    //             ))
    //         .thenAnswer((_) async => SampleGetTransactionData.txData5);
    //
    //     final transactions = [
    //       SampleGetTransactionData.txHash0,
    //       SampleGetTransactionData.txHash1,
    //       SampleGetTransactionData.txHash2,
    //       SampleGetTransactionData.txHash3,
    //       SampleGetTransactionData.txHash4,
    //       SampleGetTransactionData.txHash5,
    //     ];
    //
    //     expect(
    //         () async => await getJMintTransactions(
    //               cachedClient,
    //               transactions,
    //               "USD",
    //               "Firo",
    //               false,
    //               Decimal.ten,
    //               "en_US",
    //             ),
    //         throwsA(isA<Error>()));
    //   });
    //
    //   test("getJMintTransactions success", () async {
    //     final cachedClient = MockCachedElectrumX();
    //
    //
    //     // mock price calls
    // when(priceAPI.getPricesAnd24hChange( baseCurrency: "USD"))
    //     .thenAnswer((_) async => {Coin.firo : Tuple2(Decimal.fromInt(10), 1.0)});
    //
    //     // mock transaction calls
    //     when(cachedClient.getTransaction(
    //             txHash: SampleGetTransactionData.txHash0,
    //             coin: Coin.firo,
    //             ))
    //         .thenAnswer((_) async => SampleGetTransactionData.txData0);
    //
    //     when(cachedClient.getTransaction(
    //             txHash: SampleGetTransactionData.txHash2,
    //             coin: Coin.firo,
    //             ))
    //         .thenAnswer((_) async => SampleGetTransactionData.txData2);
    //
    //     when(cachedClient.getTransaction(
    //             txHash: SampleGetTransactionData.txHash4,
    //             coin: Coin.firo,
    //             ))
    //         .thenAnswer((_) async => SampleGetTransactionData.txData4);
    //
    //     when(cachedClient.getTransaction(
    //             txHash: SampleGetTransactionData.txHash6,
    //             coin: Coin.firo,
    //             ))
    //         .thenAnswer((_) async => SampleGetTransactionData.txData6);
    //
    //     final transactions = [
    //       SampleGetTransactionData.txHash0,
    //       SampleGetTransactionData.txHash2,
    //       SampleGetTransactionData.txHash4,
    //       SampleGetTransactionData.txHash6,
    //     ];
    //
    //     final result = await getJMintTransactions(
    //       cachedClient,
    //       transactions,
    //       "USD",
    //       "Firo",
    //       false,
    //       Decimal.ten,
    //       "en_US",
    //     );
    //
    //     expect(result, isA<List<Transaction>>());
    //     expect(result.length, 4);
    //   });
    // });
    //
    // test("getAnonymitySet", () async {
    //   final cachedClient = MockCachedElectrumX();
    //   when(cachedClient.getAnonymitySet(
    //           groupId: "1", coin: Coin.firo, ))
    //       .thenAnswer((_) async => {
    //             "blockHash":
    //                 "c8e0ee6b8f7c1c85973e2b09321dc8644483f19dd7677ab0f33f7ffb1c6a0ec1",
    //             "setHash":
    //                 "3d67502ae9e9d21d452dbbad1d961c6fcf594a3e44e9ca7b874f991a4c0e2f2d",
    //             "serializedCoins": [
    //               "388b82fdc27fd4a64c3290578d00b210bf9aa0bd9e4b08be1913bf95877bead00100",
    //               "a554e4b700c161adefbe7933c6e2784cc029a590d75c7ad35407323e7579e8680100",
    //               "162ec5f41380f590462514615fae016ff674e3e07513039d16f90161d88d83220000",
    //               "... ~50000 more strings ...",
    //               "6482f50f21b38246f3f9f074cbf61b00ad175b63a946467a85bd22fe1a89825b0100",
    //               "7a9e57560d4abc384a48bf850a12df94e83d33496bb456aad26e7317921845330000",
    //               "a7a8ddf79fdaf6846c0c19eb00ba7a95713a1a62df91761cb74b122606385fb80000"
    //             ]
    //           });
    //
    //   final result =
    //       await getAnonymitySet(cachedClient, "", "1", false, "Firo");
    //
    //   expect(result, isA<Map<String, dynamic>>());
    //   expect(result["blockHash"],
    //       "c8e0ee6b8f7c1c85973e2b09321dc8644483f19dd7677ab0f33f7ffb1c6a0ec1");
    //   expect(result["setHash"],
    //       "3d67502ae9e9d21d452dbbad1d961c6fcf594a3e44e9ca7b874f991a4c0e2f2d");
    //   expect(result["serializedCoins"], isA<List<String>>());
    // });

    test("getBlockHead", () async {
      final client = MockElectrumX();
      when(client.getBlockHeadTip()).thenAnswer(
          (_) async => {"height": 4359032, "hex": "... some block hex ..."});

      int result = await getBlockHead(client);
      expect(result, 4359032);
    });
  });

  group("validate firo addresses", () {
    test("check valid firo main net address", () async {
      final firo = FiroWallet(
        walletName: 'unit test',
        walletId: 'some id',
        coin: Coin.firo,
        client: MockElectrumX(),
        cachedClient: MockCachedElectrumX(),
        secureStore: FakeSecureStorage(),
        tracker: MockTransactionNotificationTracker(),
      );

      expect(firo.validateAddress("a8VV7vMzJdTQj1eLEJNskhLEBUxfNWhpAg"), true);
    });

    test("check invalid firo main net address", () async {
      final firo = FiroWallet(
        walletName: 'unit test',
        walletId: 'some id',
        coin: Coin.firo,
        client: MockElectrumX(),
        cachedClient: MockCachedElectrumX(),
        secureStore: FakeSecureStorage(),
        tracker: MockTransactionNotificationTracker(),
      );

      expect(firo.validateAddress("sDda3fsd4af"), false);
    });

    test("check valid firo test net address against main net", () async {
      final firo = FiroWallet(
        walletName: 'unit test',
        walletId: 'some id',
        coin: Coin.firo,
        client: MockElectrumX(),
        cachedClient: MockCachedElectrumX(),
        secureStore: FakeSecureStorage(),
        tracker: MockTransactionNotificationTracker(),
      );

      expect(firo.validateAddress("THqfkegzJjpF4PQFAWPhJWMWagwHecfqva"), false);
    });

    test("check valid firo test net address", () async {
      final firo = FiroWallet(
        walletName: 'unit test',
        walletId: 'some id',
        coin: Coin.firoTestNet,
        client: MockElectrumX(),
        cachedClient: MockCachedElectrumX(),
        secureStore: FakeSecureStorage(),
        tracker: MockTransactionNotificationTracker(),
      );

      expect(firo.validateAddress("THqfkegzJjpF4PQFAWPhJWMWagwHecfqva"), true);
    });

    test("check invalid firo test net address", () async {
      final firo = FiroWallet(
        walletName: 'unit test',
        walletId: 'some id',
        coin: Coin.firoTestNet,
        client: MockElectrumX(),
        cachedClient: MockCachedElectrumX(),
        secureStore: FakeSecureStorage(),
        tracker: MockTransactionNotificationTracker(),
      );

      expect(firo.validateAddress("sDda3fsd4af"), false);
    });

    test("check valid firo address against test net", () async {
      final firo = FiroWallet(
        walletName: 'unit test',
        walletId: 'some id',
        coin: Coin.firoTestNet,
        client: MockElectrumX(),
        cachedClient: MockCachedElectrumX(),
        secureStore: FakeSecureStorage(),
        tracker: MockTransactionNotificationTracker(),
      );

      expect(firo.validateAddress("a8VV7vMzJdTQj1eLEJNskhLEBUxfNWhpAg"), false);
    });
  });

  group("testNetworkConnection", () {
    test("attempted connection fails due to server error", () async {
      final client = MockElectrumX();
      when(client.ping()).thenAnswer((_) async => false);

      final firo = FiroWallet(
        walletName: 'unit test',
        walletId: 'some id',
        coin: Coin.firo,
        client: client,
        cachedClient: MockCachedElectrumX(),
        secureStore: FakeSecureStorage(),
        tracker: MockTransactionNotificationTracker(),
      );
      final bool result = await firo.testNetworkConnection();

      expect(result, false);
    });

    test("attempted connection fails due to exception", () async {
      final client = MockElectrumX();
      when(client.ping()).thenThrow(Exception);

      final firo = FiroWallet(
        walletName: 'unit test',
        walletId: 'some id',
        coin: Coin.firo,
        client: client,
        cachedClient: MockCachedElectrumX(),
        secureStore: FakeSecureStorage(),
        tracker: MockTransactionNotificationTracker(),
      );
      final bool result = await firo.testNetworkConnection();

      expect(result, false);
    });

    test("attempted connection test success", () async {
      final client = MockElectrumX();
      when(client.ping()).thenAnswer((_) async => true);

      final firo = FiroWallet(
        walletName: 'unit test',
        walletId: 'some id',
        coin: Coin.firoTestNet,
        client: client,
        cachedClient: MockCachedElectrumX(),
        secureStore: FakeSecureStorage(),
        tracker: MockTransactionNotificationTracker(),
      );
      final bool result = await firo.testNetworkConnection();

      expect(result, true);
    });
  });

  group("FiroWallet service class functions that depend on shared storage", () {
    const testWalletId = "testWalletID";
    const testWalletName = "Test Wallet";

    setUp(() async {
      await setUpTestHive();

      final wallets = await Hive.openBox<dynamic>('wallets');
      await wallets.put('currentWalletName', testWalletName);
    });

    // test("initializeWallet no network", () async {
    //   final client = MockElectrumX();
    //   final cachedClient = MockCachedElectrumX();
    //   final secureStore = FakeSecureStorage();
    //
    //
    //   when(client.getServerFeatures()).thenAnswer((_) async => false);
    //
    //   final firo = FiroWallet(
    //     walletName: testWalletName,
    //     walletId: testWalletId + "initializeWallet no net",
    //     client: client,coin: Coin.firo,
    //     cachedClient: cachedClient,
    //     secureStore: secureStore,
    //
    //
    //     tracker: MockTransactionNotificationTracker(),
    //   );
    //
    //   expect(await firo.initializeNew(), false);
    // });

    // test("initializeWallet no network exception", () async {
    //   final client = MockElectrumX();
    //   final cachedClient = MockCachedElectrumX();
    //   final secureStore = FakeSecureStorage();
    //
    //
    //   when(client.ping()).thenThrow(Exception("Network connection failed"));
    //
    //   final firo = FiroWallet(
    //     walletName: testWalletName,
    //     walletId: "${testWalletId}initializeWallet no net exception",
    //     client: client,
    //     coin: Coin.firo,
    //     cachedClient: cachedClient,
    //     secureStore: secureStore,
    //
    //
    //     tracker: MockTransactionNotificationTracker(),
    //   );
    //
    //   expect(await firo.initializeWallet(), false);
    // });
    //
    // test("initializeWallet throws bad network on testnet", () async {
    //   final client = MockElectrumX();
    //   final cachedClient = MockCachedElectrumX();
    //   final secureStore = FakeSecureStorage();
    //
    //
    //   when(client.ping()).thenAnswer((_) async => true);
    //
    //   when(client.getServerFeatures()).thenAnswer((_) async => {
    //         "hosts": <dynamic, dynamic>{},
    //         "pruning": null,
    //         "server_version": "Unit tests",
    //         "protocol_min": "1.4",
    //         "protocol_max": "1.4.2",
    //         "genesis_hash": GENESIS_HASH_MAINNET,
    //         "hash_function": "sha256",
    //         "services": <dynamic>[]
    //       });
    //
    //   final firo = FiroWallet(
    //     walletName: testWalletName,
    //     walletId: testWalletId + "initializeWallet bad net testnet",
    //     coin: Coin.firoTestNet,
    //     client: client,
    //     cachedClient: cachedClient,
    //     secureStore: secureStore,
    //
    //
    //     tracker: MockTransactionNotificationTracker(),
    //   );
    //
    //   expect(() => firo.initializeWallet(), throwsA(isA<Exception>()));
    // });
    //
    // test("initializeWallet throws bad network on mainnet", () async {
    //   final client = MockElectrumX();
    //   final cachedClient = MockCachedElectrumX();
    //   final secureStore = FakeSecureStorage();
    //
    //
    //   when(client.ping()).thenAnswer((_) async => true);
    //
    //   when(client.getServerFeatures()).thenAnswer((_) async => {
    //         "hosts": <dynamic, dynamic>{},
    //         "pruning": null,
    //         "server_version": "Unit tests",
    //         "protocol_min": "1.4",
    //         "protocol_max": "1.4.2",
    //         "genesis_hash": GENESIS_HASH_TESTNET,
    //         "hash_function": "sha256",
    //         "services": <dynamic>[]
    //       });
    //
    //   final firo = FiroWallet(
    //     walletName: testWalletName,
    //     walletId: testWalletId + "initializeWallet bad net mainnet",
    //     client: client,
    //     cachedClient: cachedClient,
    //     secureStore: secureStore,
    //
    //
    //     tracker: MockTransactionNotificationTracker(),
    //   );
    //
    //   expect(() => firo.initializeWallet(), throwsA(isA<Exception>()));
    // });
    //
    // test("initializeWallet new test net wallet", () async {
    //   TestWidgetsFlutterBinding.ensureInitialized();
    //   const MethodChannel('uk.spiralarm.flutter/devicelocale')
    //       .setMockMethodCallHandler((methodCall) async => 'en_US');
    //
    //   final client = MockElectrumX();
    //   final cachedClient = MockCachedElectrumX();
    //   final secureStore = FakeSecureStorage();
    //
    //   when(priceAPI.getPrice(ticker: "tFIRO", baseCurrency: "USD"))
    //       .thenAnswer((_) async => Decimal.fromInt(-1));
    //
    //   when(client.ping()).thenAnswer((_) async => true);
    //
    //   when(client.getServerFeatures()).thenAnswer((_) async => {
    //         "hosts": <dynamic, dynamic>{},
    //         "pruning": null,
    //         "server_version": "Unit tests",
    //         "protocol_min": "1.4",
    //         "protocol_max": "1.4.2",
    //         "genesis_hash": GENESIS_HASH_TESTNET,
    //         "hash_function": "sha256",
    //         "services": <dynamic>[]
    //       });
    //
    //   final List<Map<String, dynamic>> emptyList = [];
    //
    //   when(client.getUTXOs(scripthash: anyNamed("scripthash")))
    //       .thenAnswer((_) async => emptyList);
    //   when(client.getHistory(scripthash: anyNamed("scripthash")))
    //       .thenAnswer((_) async => emptyList);
    //
    //   final firo = FiroWallet(
    //     walletName: testWalletName,
    //     walletId: testWalletId + "initializeWallet testnet",
    //     coin: Coin.firoTestNet,
    //     client: client,
    //     cachedClient: cachedClient,
    //     secureStore: secureStore,
    //
    //
    //     tracker: MockTransactionNotificationTracker(),
    //   );
    //
    //   await firo.initializeWallet();
    //
    //   final wallet =
    //       await Hive.openBox(testWalletId + "initializeWallet testnet");
    //
    //   expect(await wallet.get("addressBookEntries"), {});
    //
    //   expect(await wallet.get("blocked_tx_hashes"), ["0xdefault"]);
    //
    //   final result = await wallet.get("changeAddresses");
    //   expect(result, isA<List<String>>());
    //   expect(result.length, 1);
    //
    //   expect(await wallet.get("changeIndex"), 0);
    //
    //   expect(await wallet.get("id"), testWalletId + "initializeWallet testnet");
    //
    //   expect(await wallet.get("jindex"), []);
    //
    //   expect(await wallet.get("mintIndex"), 0);
    //
    //
    //   final currentReceivingAddress = await firo.currentReceivingAddress;
    //   expect(currentReceivingAddress, isA<String>());
    //
    //   expect(await wallet.get("receivingIndex"), 0);
    // });
    //
    // test("initializeWallet an already existing test net wallet", () async {
    //   TestWidgetsFlutterBinding.ensureInitialized();
    //   const MethodChannel('uk.spiralarm.flutter/devicelocale')
    //       .setMockMethodCallHandler((methodCall) async => 'en_US');
    //
    //   final client = MockElectrumX();
    //   final cachedClient = MockCachedElectrumX();
    //   final secureStore = FakeSecureStorage();
    //
    //   // when(priceAPI.getPrice(ticker: "tFIRO", baseCurrency: "USD"))
    //   //     .thenAnswer((_) async => Decimal.fromInt(-1));
    //
    //   when(client.ping()).thenAnswer((_) async => true);
    //
    //   when(client.getServerFeatures()).thenAnswer((_) async => {
    //         "hosts": <dynamic, dynamic>{},
    //         "pruning": null,
    //         "server_version": "Unit tests",
    //         "protocol_min": "1.4",
    //         "protocol_max": "1.4.2",
    //         "genesis_hash": GENESIS_HASH_TESTNET,
    //         "hash_function": "sha256",
    //         "services": <dynamic>[]
    //       });
    //
    //   final List<Map<String, dynamic>> emptyList = [];
    //
    //   when(client.getUTXOs(scripthash: anyNamed("scripthash")))
    //       .thenAnswer((_) async => emptyList);
    //   when(client.getHistory(scripthash: anyNamed("scripthash")))
    //       .thenAnswer((_) async => emptyList);
    //
    //   final firo = FiroWallet(
    //     walletName: testWalletName,
    //     walletId: testWalletId + "initializeWallet existing",
    //     coin: Coin.firoTestNet,
    //     client: client,
    //     cachedClient: cachedClient,
    //     secureStore: secureStore,
    //
    //
    //     tracker: MockTransactionNotificationTracker(),
    //   );
    //
    //   // 1st call to create wallet
    //   await firo.initializeWallet();
    //
    //   final wallet =
    //       await Hive.openBox(testWalletId + "initializeWallet existing");
    //
    //   expect(await wallet.get("addressBookEntries"), {});
    //
    //   expect(await wallet.get("blocked_tx_hashes"), ["0xdefault"]);
    //
    //   final result = await wallet.get("changeAddresses");
    //   expect(result, isA<List<String>>());
    //   expect(result.length, 1);
    //
    //   expect(await wallet.get("changeIndex"), 0);
    //
    //   expect(
    //       await wallet.get("id"), testWalletId + "initializeWallet existing");
    //
    //   expect(await wallet.get("jindex"), []);
    //
    //   expect(await wallet.get("mintIndex"), 0);
    //
    //   expect(firo.fiatCurrency, "USD");
    //
    //   final currentReceivingAddress = await firo.currentReceivingAddress;
    //   expect(currentReceivingAddress, isA<String>());
    //
    //   expect(await wallet.get("receivingIndex"), 0);
    //
    //   // second call to test initialization of existing wallet;
    //   await firo.initializeWallet();
    //
    //   final wallet2 =
    //       await Hive.openBox(testWalletId + "initializeWallet existing");
    //
    //   expect(await wallet2.get("addressBookEntries"), {});
    //
    //   expect(await wallet2.get("blocked_tx_hashes"), ["0xdefault"]);
    //
    //   final result2 = await wallet2.get("changeAddresses");
    //   expect(result2, isA<List<String>>());
    //   expect(result2.length, 1);
    //
    //   expect(await wallet2.get("changeIndex"), 0);
    //
    //   expect(
    //       await wallet2.get("id"), testWalletId + "initializeWallet existing");
    //
    //   expect(await wallet2.get("jindex"), []);
    //
    //   expect(await wallet2.get("mintIndex"), 0);
    //
    //   expect(firo.fiatCurrency, "USD");
    //
    //   final cra = await wallet2.get("receivingAddresses");
    //   expect(cra, isA<List<String>>());
    //   expect(cra.length, 1);
    //
    //   expect(await wallet2.get("receivingIndex"), 0);
    // });
    //
    // test("initializeWallet new main net wallet", () async {
    //   TestWidgetsFlutterBinding.ensureInitialized();
    //   const MethodChannel('uk.spiralarm.flutter/devicelocale')
    //       .setMockMethodCallHandler((methodCall) async => 'en_US');
    //
    //   final client = MockElectrumX();
    //   final cachedClient = MockCachedElectrumX();
    //   final secureStore = FakeSecureStorage();
    //
    //   // mock price calls
    //       when(priceAPI.getPricesAnd24hChange(baseCurrency: "USD")).thenAnswer(
    //           (_) async => {Coin.firo: Tuple2(Decimal.fromInt(10), 1.0)});
    //
    //   when(client.ping()).thenAnswer((_) async => true);
    //
    //   when(client.getServerFeatures()).thenAnswer((_) async => {
    //         "hosts": <dynamic, dynamic>{},
    //         "pruning": null,
    //         "server_version": "Unit tests",
    //         "protocol_min": "1.4",
    //         "protocol_max": "1.4.2",
    //         "genesis_hash": GENESIS_HASH_MAINNET,
    //         "hash_function": "sha256",
    //         "services": <dynamic>[]
    //       });
    //
    //   final List<Map<String, dynamic>> emptyList = [];
    //
    //   when(client.getUTXOs(scripthash: anyNamed("scripthash")))
    //       .thenAnswer((_) async => emptyList);
    //   when(client.getHistory(scripthash: anyNamed("scripthash")))
    //       .thenAnswer((_) async => emptyList);
    //
    //   final firo = FiroWallet(
    //     walletName: testWalletName,
    //     walletId: testWalletId + "initializeWallet",
    //     coin: Coin.firo,
    //     client: client,
    //     cachedClient: cachedClient,
    //     secureStore: secureStore,
    //
    //
    //     tracker: MockTransactionNotificationTracker(),
    //   );
    //
    //   expect(await firo.initializeWallet(), true);
    //
    //   final wallet = await Hive.openBox(testWalletId + "initializeWallet");
    //
    //   var result = await wallet.get("addressBookEntries");
    //   expect(result, {});
    //
    //   result = await wallet.get("blocked_tx_hashes");
    //   expect(result, ["0xdefault"]);
    //
    //   result = await wallet.get("changeAddresses");
    //   expect(result, isA<List<String>>());
    //   expect(result.length, 1);
    //
    //   result = await wallet.get("changeIndex");
    //   expect(result, 0);
    //
    //   result = await wallet.get("id");
    //   expect(result, testWalletId + "initializeWallet");
    //
    //   result = await wallet.get("jindex");
    //   expect(result, []);
    //
    //   result = await wallet.get("mintIndex");
    //   expect(result, 0);
    //
    //   result = await wallet.get("preferredFiatCurrency");
    //   expect(result, null);
    //
    //   result = await wallet.get("receivingAddresses");
    //   expect(result, isA<List<String>>());
    //   expect(result.length, 1);
    //
    //   result = await wallet.get("receivingIndex");
    //   expect(result, 0);
    // });

    // test("getAllTxsToWatch", () async {
    //   final client = MockElectrumX();
    //   final cachedClient = MockCachedElectrumX();
    //   final secureStore = FakeSecureStorage();
    //
    //   final tracker = MockTransactionNotificationTracker();
    //       //
    //   await Hive.openBox<dynamic>(DB.boxNamePrefs);
    //   await Prefs.instance.init();
    //
    //   when(tracker.wasNotifiedPending(
    //           "51576e2230c2911a508aabb85bb50045f04b8dc958790ce2372986c3ebbe7d3e"))
    //       .thenAnswer((realInvocation) => false);
    //   when(tracker.wasNotifiedPending(
    //           "FF7e74edecd8c14ff5a8ddeb54e9e5e9c7c301c6f76f0ac1ac8119c6cc15e35"))
    //       .thenAnswer((realInvocation) => false);
    //   when(tracker.wasNotifiedPending(
    //           "ac0322cfdd008fa2a79bec525468fd05cf51a5a4e2c2e9c15598b659ec71ac68"))
    //       .thenAnswer((realInvocation) => false);
    //   when(tracker.wasNotifiedPending(
    //           "395f382ed5a595e116d5226e3cb5b664388363b6c171118a26ca729bf314c9fc"))
    //       .thenAnswer((realInvocation) => false);
    //   when(tracker.wasNotifiedPending(
    //           "ea77e74edecd8c14ff5a8ddeb54e9e5e9c7c301c6f76f0ac1ac8119c6cc15e35"))
    //       .thenAnswer((realInvocation) => false);
    //   when(tracker.wasNotifiedPending(
    //           "f4217364cbe6a81ef7ecaaeba0a6d6b576a9850b3e891fa7b88ed4927c505218"))
    //       .thenAnswer((realInvocation) => true);
    //   when(tracker.wasNotifiedPending(
    //           "e8e4bfc080bd6133d38263d2ac7ef6f60dfd73eb29b464e34766ebb5a0d27dd8"))
    //       .thenAnswer((realInvocation) => true);
    //   when(tracker.wasNotifiedConfirmed(
    //           "f4217364cbe6a81ef7ecaaeba0a6d6b576a9850b3e891fa7b88ed4927c505218"))
    //       .thenAnswer((realInvocation) => true);
    //   when(tracker.wasNotifiedConfirmed(
    //           "e8e4bfc080bd6133d38263d2ac7ef6f60dfd73eb29b464e34766ebb5a0d27dd8"))
    //       .thenAnswer((realInvocation) => true);
    //
    //   final firo = FiroWallet(
    //     walletName: testWalletName,
    //     walletId: "${testWalletId}getAllTxsToWatch",
    //     coin: Coin.firo,
    //     client: client,
    //     cachedClient: cachedClient,
    //     secureStore: secureStore,
    //
    //
    //     tracker: tracker,
    //   );
    //
    //TODO: mock NotificationAPI
    //   await firo.getAllTxsToWatch(txData, lTxData);
    //
    //
    //   // expect(firo.unconfirmedTxs, {
    //   //   "51576e2230c2911a508aabb85bb50045f04b8dc958790ce2372986c3ebbe7d3e",
    //   //   'FF7e74edecd8c14ff5a8ddeb54e9e5e9c7c301c6f76f0ac1ac8119c6cc15e35',
    //   //   "f4217364cbe6a81ef7ecaaeba0a6d6b576a9850b3e891fa7b88ed4927c505218"
    //   // });
    // });

    group("refreshIfThereIsNewData", () {
      // test("refreshIfThereIsNewData with no unconfirmed transactions",
      //     () async {
      //   TestWidgetsFlutterBinding.ensureInitialized();
      //   const MethodChannel('uk.spiralarm.flutter/devicelocale')
      //       .setMockMethodCallHandler((methodCall) async => 'en_US');
      //
      //   final client = MockElectrumX();
      //   final cachedClient = MockCachedElectrumX();
      //   final secureStore = FakeSecureStorage();
      //   final tracker = MockTransactionNotificationTracker();
      //
      //   when(tracker.pendings).thenAnswer((realInvocation) => [
      //         "51576e2230c2911a508aabb85bb50045f04b8dc958790ce2372986c3ebbe7d3e",
      //         "FF7e74edecd8c14ff5a8ddeb54e9e5e9c7c301c6f76f0ac1ac8119c6cc15e35",
      //         "f4217364cbe6a81ef7ecaaeba0a6d6b576a9850b3e891fa7b88ed4927c505218"
      //       ]);
      //   when(tracker.wasNotifiedPending(
      //           "51576e2230c2911a508aabb85bb50045f04b8dc958790ce2372986c3ebbe7d3e"))
      //       .thenAnswer((realInvocation) => true);
      //   when(tracker.wasNotifiedPending(
      //           "FF7e74edecd8c14ff5a8ddeb54e9e5e9c7c301c6f76f0ac1ac8119c6cc15e35"))
      //       .thenAnswer((realInvocation) => true);
      //   when(tracker.wasNotifiedPending(
      //           "f4217364cbe6a81ef7ecaaeba0a6d6b576a9850b3e891fa7b88ed4927c505218"))
      //       .thenAnswer((realInvocation) => true);
      //
      //   when(tracker.wasNotifiedConfirmed(
      //           "51576e2230c2911a508aabb85bb50045f04b8dc958790ce2372986c3ebbe7d3e"))
      //       .thenAnswer((realInvocation) => true);
      //   when(tracker.wasNotifiedConfirmed(
      //           "FF7e74edecd8c14ff5a8ddeb54e9e5e9c7c301c6f76f0ac1ac8119c6cc15e35"))
      //       .thenAnswer((realInvocation) => true);
      //   when(tracker.wasNotifiedConfirmed(
      //           "f4217364cbe6a81ef7ecaaeba0a6d6b576a9850b3e891fa7b88ed4927c505218"))
      //       .thenAnswer((realInvocation) => true);
      //
      //   when(client.getBatchHistory(args: batchHistoryRequest0))
      //       .thenAnswer((realInvocation) async => batchHistoryResponse0);
      //
      //   // mock transaction calls
      //   when(cachedClient.getTransaction(
      //     txHash: SampleGetTransactionData.txHash0,
      //     coin: Coin.firo,
      //   )).thenAnswer((_) async => SampleGetTransactionData.txData0);
      //   when(cachedClient.getTransaction(
      //     txHash: SampleGetTransactionData.txHash1,
      //     coin: Coin.firo,
      //   )).thenAnswer((_) async => SampleGetTransactionData.txData1);
      //   when(cachedClient.getTransaction(
      //     txHash: SampleGetTransactionData.txHash2,
      //     coin: Coin.firo,
      //   )).thenAnswer((_) async => SampleGetTransactionData.txData2);
      //   when(cachedClient.getTransaction(
      //     txHash: SampleGetTransactionData.txHash3,
      //     coin: Coin.firo,
      //   )).thenAnswer((_) async => SampleGetTransactionData.txData3);
      //   when(cachedClient.getTransaction(
      //     txHash: SampleGetTransactionData.txHash4,
      //     coin: Coin.firo,
      //   )).thenAnswer((_) async => SampleGetTransactionData.txData4);
      //   when(cachedClient.getTransaction(
      //     txHash: SampleGetTransactionData.txHash5,
      //     coin: Coin.firo,
      //   )).thenAnswer((_) async => SampleGetTransactionData.txData5);
      //   when(cachedClient.getTransaction(
      //     txHash: SampleGetTransactionData.txHash6,
      //     coin: Coin.firo,
      //   )).thenAnswer((_) async => SampleGetTransactionData.txData6);
      //
      //   final firo = FiroWallet(
      //     walletName: testWalletName,
      //     walletId: "${testWalletId}refreshIfThereIsNewData",
      //     coin: Coin.firo,
      //     client: client,
      //     cachedClient: cachedClient,
      //     secureStore: secureStore,
      //     tracker: tracker,
      //   );
      //
      //   // firo.unconfirmedTxs = {};
      //
      //   final wallet = await Hive.openBox<dynamic>(
      //       "${testWalletId}refreshIfThereIsNewData");
      //   await wallet.put('receivingAddresses', [
      //     "a8VV7vMzJdTQj1eLEJNskhLEBUxfNWhpAg",
      //     "aPjLWDTPQsoPHUTxKBNRzoebDALj3eTcfh",
      //     "aKmXfS7nEZdqWBGRdAXcyMoEoKhZQDPBoq",
      //   ]);
      //
      //   await wallet.put('changeAddresses', [
      //     "a5V5r6We6mNZzWJwGwEeRML3mEYLjvK39w",
      //   ]);
      //
      //   final result = await firo.refreshIfThereIsNewData();
      //   expect(result, false);
      // });

      //   TODO: mock NotificationAPI
      //   test("refreshIfThereIsNewData with two unconfirmed transactions",
      //       () async {
      //     final client = MockElectrumX();
      //     final cachedClient = MockCachedElectrumX();
      //     final secureStore = FakeSecureStorage();
      //
      //     final tracker = MockTransactionNotificationTracker();
      //       //
      //     when(client.getTransaction(txHash: SampleGetTransactionData.txHash6))
      //         .thenAnswer((_) async => SampleGetTransactionData.txData6);
      //
      //     when(client.getTransaction(
      //             txHash:
      //                 "f4217364cbe6a81ef7ecaaeba0a6d6b576a9850b3e891fa7b88ed4927c505218"))
      //         .thenAnswer((_) async => SampleGetTransactionData.txData7);
      //
      //     when(tracker.wasNotifiedPending(
      //             "51576e2230c2911a508aabb85bb50045f04b8dc958790ce2372986c3ebbe7d3e"))
      //         .thenAnswer((realInvocation) => true);
      //     when(tracker.wasNotifiedPending(
      //             "FF7e74edecd8c14ff5a8ddeb54e9e5e9c7c301c6f76f0ac1ac8119c6cc15e35"))
      //         .thenAnswer((realInvocation) => false);
      //     when(tracker.wasNotifiedPending(
      //             "f4217364cbe6a81ef7ecaaeba0a6d6b576a9850b3e891fa7b88ed4927c505218"))
      //         .thenAnswer((realInvocation) => false);
      //     when(tracker.wasNotifiedPending(
      //             "e8e4bfc080bd6133d38263d2ac7ef6f60dfd73eb29b464e34766ebb5a0d27dd8"))
      //         .thenAnswer((realInvocation) => false);
      //     when(tracker.wasNotifiedPending(
      //             "ac0322cfdd008fa2a79bec525468fd05cf51a5a4e2c2e9c15598b659ec71ac68"))
      //         .thenAnswer((realInvocation) => false);
      //     when(tracker.wasNotifiedPending(
      //             "ea77e74edecd8c14ff5a8ddeb54e9e5e9c7c301c6f76f0ac1ac8119c6cc15e35"))
      //         .thenAnswer((realInvocation) => false);
      //     when(tracker.wasNotifiedPending(
      //             "395f382ed5a595e116d5226e3cb5b664388363b6c171118a26ca729bf314c9fc"))
      //         .thenAnswer((realInvocation) => false);
      //
      //     final firo = FiroWallet(
      //       walletName: testWalletName,
      //       walletId: testWalletId + "refreshIfThereIsNewData",
      //       coin: Coin.firo,
      //       client: client,
      //       cachedClient: cachedClient,
      //       secureStore: secureStore,
      //
      //
      //       tracker: tracker,
      //     );
      //
      //     await firo.getAllTxsToWatch(txData, lTxData);
      //
      //     final result = await firo.refreshIfThereIsNewData();
      //
      //     expect(result, true);
      //   });
    });

    test("submitHexToNetwork", () async {
      final client = MockElectrumX();
      final cachedClient = MockCachedElectrumX();
      final secureStore = FakeSecureStorage();

      when(client.broadcastTransaction(
              rawTx:
                  "0200000001ddba3ce3a3ab07d342183fa6743d3b620149c1db26efa239323384d82f9e2859010000006a47304402207d4982586eb4b0de17ee88f8eae4aaf7bc68590ae048e67e75932fe84a73f7f3022011392592558fb39d8c132234ad34a2c7f5071d2dab58d8c9220d343078413497012102f123ab9dbd627ab572de7cd77eda6e3781213a2ef4ab5e0d6e87f1c0d944b2caffffffff01e42e000000000000a5c5bc76bae786dc3a7d939757c34e15994d403bdaf418f9c9fa6eb90ac6e8ffc3550100772ad894f285988789669acd69ba695b9485c90141d7833209d05bcdad1b898b0000f5cba1a513dd97d81f89159f2be6eb012e987335fffa052c1fbef99550ba488fb6263232e7a0430c0a3ca8c728a5d8c8f2f985c8b586024a0f488c73130bd5ec9e7c23571f23c2d34da444ecc2fb65a12cee2ad3b8d3fcc337a2c2a45647eb43cff50600"))
          .thenAnswer((_) async =>
              "b36161c6e619395b3d40a851c45c1fef7a5c541eed911b5524a66c5703a689c9");

      final firo = FiroWallet(
        walletName: testWalletName,
        walletId: "${testWalletId}submitHexToNetwork",
        coin: Coin.firo,
        client: client,
        cachedClient: cachedClient,
        secureStore: secureStore,
        tracker: MockTransactionNotificationTracker(),
      );

      final txid = await firo.submitHexToNetwork(
          "0200000001ddba3ce3a3ab07d342183fa6743d3b620149c1db26efa239323384d82f9e2859010000006a47304402207d4982586eb4b0de17ee88f8eae4aaf7bc68590ae048e67e75932fe84a73f7f3022011392592558fb39d8c132234ad34a2c7f5071d2dab58d8c9220d343078413497012102f123ab9dbd627ab572de7cd77eda6e3781213a2ef4ab5e0d6e87f1c0d944b2caffffffff01e42e000000000000a5c5bc76bae786dc3a7d939757c34e15994d403bdaf418f9c9fa6eb90ac6e8ffc3550100772ad894f285988789669acd69ba695b9485c90141d7833209d05bcdad1b898b0000f5cba1a513dd97d81f89159f2be6eb012e987335fffa052c1fbef99550ba488fb6263232e7a0430c0a3ca8c728a5d8c8f2f985c8b586024a0f488c73130bd5ec9e7c23571f23c2d34da444ecc2fb65a12cee2ad3b8d3fcc337a2c2a45647eb43cff50600");

      expect(txid,
          "b36161c6e619395b3d40a851c45c1fef7a5c541eed911b5524a66c5703a689c9");
    });

    // the above test needs to pass in order for this test to pass
    test("buildMintTransaction", () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      const MethodChannel('uk.spiralarm.flutter/devicelocale')
          .setMockMethodCallHandler((methodCall) async => 'en_US');

      List<UTXO> utxos = [
        UTXO(
          txid: BuildMintTxTestParams.utxoInfo["txid"] as String,
          vout: BuildMintTxTestParams.utxoInfo["vout"] as int,
          value: BuildMintTxTestParams.utxoInfo["value"] as int,
          isCoinbase: false,
          walletId: '',
          name: '',
          isBlocked: false,
          blockedReason: '',
          blockHash: '',
          blockHeight: -1,
          blockTime: 42,
        )
      ];
      const sats = 9658;
      final client = MockElectrumX();
      final cachedClient = MockCachedElectrumX();
      final secureStore = FakeSecureStorage();
      final mainDB = MockMainDB();

      await secureStore.write(
          key: "${testWalletId}buildMintTransaction_mnemonic",
          value: BuildMintTxTestParams.mnemonic);
      await secureStore.write(
          key: "${testWalletId}buildMintTransaction_mnemonicPassphrase",
          value: "");

      when(cachedClient.getTransaction(
        txHash: BuildMintTxTestParams.utxoInfo["txid"] as String,
        coin: Coin.firo,
      )).thenAnswer((_) async => BuildMintTxTestParams.cachedClientResponse);
      when(cachedClient.getAnonymitySet(
        groupId: "1",
        coin: Coin.firo,
      )).thenAnswer(
        (_) async => GetAnonymitySetSampleData.data,
      );
      when(cachedClient.getAnonymitySet(
        groupId: "2",
        coin: Coin.firo,
      )).thenAnswer(
        (_) async => GetAnonymitySetSampleData.data,
      );

      when(client.getBlockHeadTip()).thenAnswer(
          (_) async => {"height": 455873, "hex": "this value not used here"});
      when(client.getLatestCoinId()).thenAnswer((_) async => 2);

      when(mainDB.getAddress("${testWalletId}buildMintTransaction", any))
          .thenAnswer((realInvocation) async => null);

      when(mainDB.getHighestUsedMintIndex(
              walletId: "${testWalletId}submitHexToNetwork"))
          .thenAnswer((_) async => null);
      when(mainDB.getHighestUsedMintIndex(
              walletId: "testWalletIDbuildMintTransaction"))
          .thenAnswer((_) async => null);

      final firo = FiroWallet(
        walletName: testWalletName,
        walletId: "${testWalletId}buildMintTransaction",
        coin: Coin.firo,
        client: client,
        cachedClient: cachedClient,
        secureStore: secureStore,
        tracker: MockTransactionNotificationTracker(),
        mockableOverride: mainDB,
      );

      final wallet =
          await Hive.openBox<dynamic>("${testWalletId}buildMintTransaction");

      await wallet.put("mintIndex", 0);

      await secureStore.write(
          key: "${testWalletId}buildMintTransaction_receiveDerivations",
          value: jsonEncode(BuildMintTxTestParams.receiveDerivations));
      await secureStore.write(
          key: "${testWalletId}buildMintTransaction_changeDerivations",
          value: jsonEncode(BuildMintTxTestParams.changeDerivations));

      List<Map<String, dynamic>> mintsWithoutFee =
          await firo.createMintsFromAmount(sats);

      final result =
          await firo.buildMintTransaction(utxos, sats, mintsWithoutFee);

      expect(result["txHex"], isA<String>());
    });

    // test("recoverFromMnemonic succeeds", () async {
    //   TestWidgetsFlutterBinding.ensureInitialized();
    //   const MethodChannel('uk.spiralarm.flutter/devicelocale')
    //       .setMockMethodCallHandler((methodCall) async => 'en_US');
    //
    //   final client = MockElectrumX();
    //   final cachedClient = MockCachedElectrumX();
    //   final secureStore = FakeSecureStorage();
    //
    //   // mock electrumx client calls
    //   when(client.getServerFeatures()).thenAnswer((_) async => {
    //         "hosts": <dynamic, dynamic>{},
    //         "pruning": null,
    //         "server_version": "Unit tests",
    //         "protocol_min": "1.4",
    //         "protocol_max": "1.4.2",
    //         "genesis_hash": GENESIS_HASH_MAINNET,
    //         "hash_function": "sha256",
    //         "services": <dynamic>[]
    //       });
    //
    //   when(client.getLatestCoinId()).thenAnswer((_) async => 1);
    //   when(cachedClient.getUsedCoinSerials(
    //     coin: Coin.firo,
    //   )).thenAnswer(
    //       (_) async => GetUsedSerialsSampleData.serials["serials"] as List);
    //
    //   when(cachedClient.getAnonymitySet(
    //     groupId: "1",
    //     coin: Coin.firo,
    //   )).thenAnswer(
    //     (_) async => GetAnonymitySetSampleData.data,
    //   );
    //
    //   when(cachedClient.getTransaction(
    //     txHash: SampleGetTransactionData.txHash0,
    //     coin: Coin.firo,
    //   )).thenAnswer((_) async {
    //     return SampleGetTransactionData.txData0;
    //   });
    //   when(cachedClient.getTransaction(
    //     txHash: SampleGetTransactionData.txHash1,
    //     coin: Coin.firo,
    //   )).thenAnswer((_) async {
    //     return SampleGetTransactionData.txData1;
    //   });
    //   when(cachedClient.getTransaction(
    //     txHash: SampleGetTransactionData.txHash2,
    //     coin: Coin.firo,
    //   )).thenAnswer((_) async {
    //     return SampleGetTransactionData.txData2;
    //   });
    //   when(cachedClient.getTransaction(
    //     txHash: SampleGetTransactionData.txHash3,
    //     coin: Coin.firo,
    //   )).thenAnswer((_) async {
    //     return SampleGetTransactionData.txData3;
    //   });
    //   when(cachedClient.getTransaction(
    //     txHash: SampleGetTransactionData.txHash4,
    //     coin: Coin.firo,
    //   )).thenAnswer((_) async {
    //     return SampleGetTransactionData.txData4;
    //   });
    //   when(cachedClient.getTransaction(
    //     txHash: SampleGetTransactionData.txHash5,
    //     coin: Coin.firo,
    //   )).thenAnswer((_) async {
    //     return SampleGetTransactionData.txData5;
    //   });
    //   when(cachedClient.getTransaction(
    //     txHash: SampleGetTransactionData.txHash6,
    //     coin: Coin.firo,
    //   )).thenAnswer((_) async {
    //     return SampleGetTransactionData.txData6;
    //   });
    //   when(cachedClient.getTransaction(
    //     txHash: SampleGetTransactionData.txHash8,
    //     coin: Coin.firo,
    //   )).thenAnswer((_) async {
    //     return SampleGetTransactionData.txData8;
    //   });
    //   when(cachedClient.getTransaction(
    //     txHash: SampleGetTransactionData.txHash9,
    //     coin: Coin.firo,
    //   )).thenAnswer((_) async {
    //     return SampleGetTransactionData.txData9;
    //   });
    //   when(cachedClient.getTransaction(
    //     txHash: SampleGetTransactionData.txHash7,
    //     coin: Coin.firo,
    //   )).thenAnswer((_) async {
    //     return SampleGetTransactionData.txData7;
    //   });
    //
    //   final firo = FiroWallet(
    //     walletName: testWalletName,
    //     walletId: "${testWalletId}recoverFromMnemonic",
    //     coin: Coin.firo,
    //     client: client,
    //     cachedClient: cachedClient,
    //     secureStore: secureStore,
    //     tracker: MockTransactionNotificationTracker(),
    //   );
    //
    //   // pre grab derivations in order to set up mock calls needed later on
    //   await firo.fillAddresses(TEST_MNEMONIC);
    //   final wallet =
    //       await Hive.openBox<dynamic>("${testWalletId}recoverFromMnemonic");
    //
    //   final rcv = await secureStore.read(
    //       key: "${testWalletId}recoverFromMnemonic_receiveDerivations");
    //   final chg = await secureStore.read(
    //       key: "${testWalletId}recoverFromMnemonic_changeDerivations");
    //   final receiveDerivations =
    //       Map<String, dynamic>.from(jsonDecode(rcv as String) as Map);
    //   final changeDerivations =
    //       Map<String, dynamic>.from(jsonDecode(chg as String) as Map);
    //
    //   for (int i = 0; i < receiveDerivations.length; i++) {
    //     final receiveHash = AddressUtils.convertToScriptHash(
    //         receiveDerivations["$i"]!["address"] as String, firoNetwork);
    //     final changeHash = AddressUtils.convertToScriptHash(
    //         changeDerivations["$i"]!["address"] as String, firoNetwork);
    //     List<Map<String, dynamic>> data;
    //     switch (receiveHash) {
    //       case SampleGetHistoryData.scripthash0:
    //         data = SampleGetHistoryData.data0;
    //         break;
    //       case SampleGetHistoryData.scripthash1:
    //         data = SampleGetHistoryData.data1;
    //         break;
    //       case SampleGetHistoryData.scripthash2:
    //         data = SampleGetHistoryData.data2;
    //         break;
    //       case SampleGetHistoryData.scripthash3:
    //         data = SampleGetHistoryData.data3;
    //         break;
    //       default:
    //         data = [];
    //     }
    //     when(client.getHistory(scripthash: receiveHash))
    //         .thenAnswer((_) async => data);
    //
    //     switch (changeHash) {
    //       case SampleGetHistoryData.scripthash0:
    //         data = SampleGetHistoryData.data0;
    //         break;
    //       case SampleGetHistoryData.scripthash1:
    //         data = SampleGetHistoryData.data1;
    //         break;
    //       case SampleGetHistoryData.scripthash2:
    //         data = SampleGetHistoryData.data2;
    //         break;
    //       case SampleGetHistoryData.scripthash3:
    //         data = SampleGetHistoryData.data3;
    //         break;
    //       default:
    //         data = [];
    //     }
    //
    //     when(client.getHistory(scripthash: changeHash))
    //         .thenAnswer((_) async => data);
    //   }
    //
    //   when(client.getBatchHistory(args: {
    //     "0": [SampleGetHistoryData.scripthash0],
    //     "1": [SampleGetHistoryData.scripthash3]
    //   })).thenAnswer((realInvocation) async => {
    //         "0": SampleGetHistoryData.data0,
    //         "1": SampleGetHistoryData.data3,
    //       });
    //
    //   await firo.recoverFromMnemonic(
    //       mnemonic: TEST_MNEMONIC,
    //       maxUnusedAddressGap: 20,
    //       height: 0,
    //       maxNumberOfIndexesToCheck: 1000);
    //
    //   final receivingAddresses = await wallet.get('receivingAddresses');
    //   expect(receivingAddresses, ["a8VV7vMzJdTQj1eLEJNskhLEBUxfNWhpAg"]);
    //
    //   final changeAddresses = await wallet.get('changeAddresses');
    //   expect(changeAddresses, ["a5V5r6We6mNZzWJwGwEeRML3mEYLjvK39w"]);
    //
    //   final receivingIndex = await wallet.get('receivingIndex');
    //   expect(receivingIndex, 0);
    //
    //   final changeIndex = await wallet.get('changeIndex');
    //   expect(changeIndex, 0);
    //
    //   final _rcv = await secureStore.read(
    //       key: "${testWalletId}recoverFromMnemonic_receiveDerivations");
    //   final _chg = await secureStore.read(
    //       key: "${testWalletId}recoverFromMnemonic_changeDerivations");
    //   final _receiveDerivations =
    //       Map<String, dynamic>.from(jsonDecode(_rcv as String) as Map);
    //   final _changeDerivations =
    //       Map<String, dynamic>.from(jsonDecode(_chg as String) as Map);
    //   // expect(_receiveDerivations.length, 190);
    //   // expect(_changeDerivations.length, 190);
    //   expect(_receiveDerivations.length, 80);
    //   expect(_changeDerivations.length, 80);
    //
    //   final mintIndex = await wallet.get('mintIndex');
    //   expect(mintIndex, 8);
    //
    //   final lelantusCoins = await wallet.get('_lelantus_coins') as List;
    //   expect(lelantusCoins.length, 7);
    //   final lcoin = lelantusCoins
    //       .firstWhere((element) =>
    //           (Map<String, LelantusCoin>.from(element as Map))
    //               .values
    //               .first
    //               .txId ==
    //           "36c92daa4005d368e28cea917fdb2c1e7069319a4a79fb2ff45c089100680232")
    //       .values
    //       .first as LelantusCoin;
    //   expect(lcoin.index, 1);
    //   expect(lcoin.value, 9658);
    //   expect(lcoin.publicCoin,
    //       "7fd927efbea0a9e4ba299209aaee610c63359857596be0a2da276011a0baa84a0000");
    //   expect(lcoin.txId,
    //       "36c92daa4005d368e28cea917fdb2c1e7069319a4a79fb2ff45c089100680232");
    //   expect(lcoin.anonymitySetId, 1);
    //   expect(lcoin.isUsed, true);
    //
    //   final jIndex = await wallet.get('jindex');
    //   expect(jIndex, [2, 4, 6]);
    //
    //   final lelantusTxModel = await wallet.get('latest_lelantus_tx_model');
    //   expect(lelantusTxModel.getAllTransactions().length, 5);
    // }, timeout: const Timeout(Duration(minutes: 5)));
    //
    // test("fullRescan succeeds", () async {
    //   TestWidgetsFlutterBinding.ensureInitialized();
    //   const MethodChannel('uk.spiralarm.flutter/devicelocale')
    //       .setMockMethodCallHandler((methodCall) async => 'en_US');
    //
    //   final client = MockElectrumX();
    //   final cachedClient = MockCachedElectrumX();
    //   final secureStore = FakeSecureStorage();
    //
    //   await secureStore.write(
    //       key: '${testWalletId}fullRescan_mnemonic', value: TEST_MNEMONIC);
    //
    //   // mock electrumx client calls
    //   when(client.getLatestCoinId()).thenAnswer((_) async => 1);
    //   // when(client.getCoinsForRecovery(setId: 1))
    //   //     .thenAnswer((_) async => getCoinsForRecoveryResponse);
    //   when(client.getUsedCoinSerials(startNumber: 0))
    //       .thenAnswer((_) async => GetUsedSerialsSampleData.serials);
    //
    //   when(cachedClient.getAnonymitySet(
    //           groupId: "1", blockhash: "", coin: Coin.firo))
    //       .thenAnswer((_) async => GetAnonymitySetSampleData.data);
    //   when(cachedClient.getUsedCoinSerials(startNumber: 0, coin: Coin.firo))
    //       .thenAnswer(
    //           (_) async => GetUsedSerialsSampleData.serials['serials'] as List);
    //
    //   when(cachedClient.clearSharedTransactionCache(coin: Coin.firo))
    //       .thenAnswer((_) async => {});
    //
    //   final firo = FiroWallet(
    //     walletName: testWalletName,
    //     walletId: "${testWalletId}fullRescan",
    //     coin: Coin.firo,
    //     client: client,
    //     cachedClient: cachedClient,
    //     secureStore: secureStore,
    //     tracker: MockTransactionNotificationTracker(),
    //   );
    //
    //   // pre grab derivations in order to set up mock calls needed later on
    //   await firo.fillAddresses(TEST_MNEMONIC);
    //   final wallet = await Hive.openBox<dynamic>("${testWalletId}fullRescan");
    //
    //   final rcv = await secureStore.read(
    //       key: "${testWalletId}fullRescan_receiveDerivations");
    //   final chg = await secureStore.read(
    //       key: "${testWalletId}fullRescan_changeDerivations");
    //   final receiveDerivations =
    //       Map<String, dynamic>.from(jsonDecode(rcv as String) as Map);
    //   final changeDerivations =
    //       Map<String, dynamic>.from(jsonDecode(chg as String) as Map);
    //
    //   for (int i = 0; i < receiveDerivations.length; i++) {
    //     final receiveHash = AddressUtils.convertToScriptHash(
    //         receiveDerivations["$i"]!["address"] as String, firoNetwork);
    //     final changeHash = AddressUtils.convertToScriptHash(
    //         changeDerivations["$i"]!["address"] as String, firoNetwork);
    //     List<Map<String, dynamic>> data;
    //     switch (receiveHash) {
    //       case SampleGetHistoryData.scripthash0:
    //         data = SampleGetHistoryData.data0;
    //         break;
    //       case SampleGetHistoryData.scripthash1:
    //         data = SampleGetHistoryData.data1;
    //         break;
    //       case SampleGetHistoryData.scripthash2:
    //         data = SampleGetHistoryData.data2;
    //         break;
    //       case SampleGetHistoryData.scripthash3:
    //         data = SampleGetHistoryData.data3;
    //         break;
    //       default:
    //         data = [];
    //     }
    //     when(client.getHistory(scripthash: receiveHash))
    //         .thenAnswer((_) async => data);
    //
    //     switch (changeHash) {
    //       case SampleGetHistoryData.scripthash0:
    //         data = SampleGetHistoryData.data0;
    //         break;
    //       case SampleGetHistoryData.scripthash1:
    //         data = SampleGetHistoryData.data1;
    //         break;
    //       case SampleGetHistoryData.scripthash2:
    //         data = SampleGetHistoryData.data2;
    //         break;
    //       case SampleGetHistoryData.scripthash3:
    //         data = SampleGetHistoryData.data3;
    //         break;
    //       default:
    //         data = [];
    //     }
    //
    //     when(client.getHistory(scripthash: changeHash))
    //         .thenAnswer((_) async => data);
    //   }
    //
    //   when(client.getBatchHistory(args: {
    //     "0": [SampleGetHistoryData.scripthash0],
    //     "1": [SampleGetHistoryData.scripthash3]
    //   })).thenAnswer((realInvocation) async => {
    //         "0": SampleGetHistoryData.data0,
    //         "1": SampleGetHistoryData.data3,
    //       });
    //
    //   // mock transaction calls
    //   when(cachedClient.getTransaction(
    //     txHash: SampleGetTransactionData.txHash0,
    //     coin: Coin.firo,
    //   )).thenAnswer((_) async => SampleGetTransactionData.txData0);
    //   when(cachedClient.getTransaction(
    //     txHash: SampleGetTransactionData.txHash1,
    //     coin: Coin.firo,
    //   )).thenAnswer((_) async => SampleGetTransactionData.txData1);
    //   when(cachedClient.getTransaction(
    //     txHash: SampleGetTransactionData.txHash2,
    //     coin: Coin.firo,
    //   )).thenAnswer((_) async => SampleGetTransactionData.txData2);
    //   when(cachedClient.getTransaction(
    //     txHash: SampleGetTransactionData.txHash3,
    //     coin: Coin.firo,
    //   )).thenAnswer((_) async => SampleGetTransactionData.txData3);
    //   when(cachedClient.getTransaction(
    //     txHash: SampleGetTransactionData.txHash4,
    //     coin: Coin.firo,
    //   )).thenAnswer((_) async => SampleGetTransactionData.txData4);
    //   when(cachedClient.getTransaction(
    //     txHash: SampleGetTransactionData.txHash5,
    //     coin: Coin.firo,
    //   )).thenAnswer((_) async => SampleGetTransactionData.txData5);
    //   when(cachedClient.getTransaction(
    //     txHash: SampleGetTransactionData.txHash6,
    //     coin: Coin.firo,
    //   )).thenAnswer((_) async => SampleGetTransactionData.txData6);
    //   when(cachedClient.getTransaction(
    //     txHash: SampleGetTransactionData.txHash7,
    //     coin: Coin.firo,
    //   )).thenAnswer((_) async => SampleGetTransactionData.txData7);
    //   when(cachedClient.getTransaction(
    //     txHash: SampleGetTransactionData.txHash8,
    //     coin: Coin.firo,
    //   )).thenAnswer((_) async => SampleGetTransactionData.txData8);
    //   when(cachedClient.getTransaction(
    //     txHash: SampleGetTransactionData.txHash9,
    //     coin: Coin.firo,
    //   )).thenAnswer((_) async => SampleGetTransactionData.txData9);
    //   when(cachedClient.getTransaction(
    //     txHash: SampleGetTransactionData.txHash10,
    //     coin: Coin.firo,
    //   )).thenAnswer((_) async => SampleGetTransactionData.txData10);
    //
    //   await firo.fullRescan(20, 1000);
    //
    //   final receivingAddresses = await wallet.get('receivingAddresses');
    //   expect(receivingAddresses, ["a8VV7vMzJdTQj1eLEJNskhLEBUxfNWhpAg"]);
    //
    //   final changeAddresses = await wallet.get('changeAddresses');
    //   expect(changeAddresses, ["a5V5r6We6mNZzWJwGwEeRML3mEYLjvK39w"]);
    //
    //   final receivingIndex = await wallet.get('receivingIndex');
    //   expect(receivingIndex, 0);
    //
    //   final changeIndex = await wallet.get('changeIndex');
    //   expect(changeIndex, 0);
    //
    //   final _rcv = await secureStore.read(
    //       key: "${testWalletId}fullRescan_receiveDerivations");
    //   final _chg = await secureStore.read(
    //       key: "${testWalletId}fullRescan_changeDerivations");
    //   final _receiveDerivations =
    //       Map<String, dynamic>.from(jsonDecode(_rcv as String) as Map);
    //   final _changeDerivations =
    //       Map<String, dynamic>.from(jsonDecode(_chg as String) as Map);
    //   // expect(_receiveDerivations.length, 150);
    //   // expect(_changeDerivations.length, 150);
    //   expect(_receiveDerivations.length, 40);
    //   expect(_changeDerivations.length, 40);
    //
    //   final mintIndex = await wallet.get('mintIndex');
    //   expect(mintIndex, 8);
    //
    //   final lelantusCoins = await wallet.get('_lelantus_coins') as List;
    //   expect(lelantusCoins.length, 7);
    //   final lcoin = lelantusCoins
    //       .firstWhere((element) =>
    //           (Map<String, LelantusCoin>.from(element as Map))
    //               .values
    //               .first
    //               .txId ==
    //           "36c92daa4005d368e28cea917fdb2c1e7069319a4a79fb2ff45c089100680232")
    //       .values
    //       .first as LelantusCoin;
    //   expect(lcoin.index, 1);
    //   expect(lcoin.value, 9658);
    //   expect(lcoin.publicCoin,
    //       "7fd927efbea0a9e4ba299209aaee610c63359857596be0a2da276011a0baa84a0000");
    //   expect(lcoin.txId,
    //       "36c92daa4005d368e28cea917fdb2c1e7069319a4a79fb2ff45c089100680232");
    //   expect(lcoin.anonymitySetId, 1);
    //   expect(lcoin.isUsed, true);
    //
    //   final jIndex = await wallet.get('jindex');
    //   expect(jIndex, [2, 4, 6]);
    //
    //   final lelantusTxModel = await wallet.get('latest_lelantus_tx_model');
    //   expect(lelantusTxModel.getAllTransactions().length, 5);
    // }, timeout: const Timeout(Duration(minutes: 3)));
    //
    // test("fullRescan fails", () async {
    //   TestWidgetsFlutterBinding.ensureInitialized();
    //   const MethodChannel('uk.spiralarm.flutter/devicelocale')
    //       .setMockMethodCallHandler((methodCall) async => 'en_US');
    //
    //   final client = MockElectrumX();
    //   final cachedClient = MockCachedElectrumX();
    //   final secureStore = FakeSecureStorage();
    //
    //   await secureStore.write(
    //       key: '${testWalletId}fullRescan_mnemonic', value: TEST_MNEMONIC);
    //
    //   // mock electrumx client calls
    //   when(client.getLatestCoinId()).thenAnswer((_) async => 1);
    //   // when(client.getCoinsForRecovery(setId: 1))
    //   //     .thenAnswer((_) async => getCoinsForRecoveryResponse);
    //   when(client.getUsedCoinSerials(startNumber: 0))
    //       .thenAnswer((_) async => GetUsedSerialsSampleData.serials);
    //
    //   when(cachedClient.clearSharedTransactionCache(coin: Coin.firo))
    //       .thenAnswer((_) async => {});
    //
    //   final firo = FiroWallet(
    //     walletName: testWalletName,
    //     walletId: "${testWalletId}fullRescan",
    //     coin: Coin.firo,
    //     client: client,
    //     cachedClient: cachedClient,
    //     secureStore: secureStore,
    //     tracker: MockTransactionNotificationTracker(),
    //   );
    //
    //   // pre grab derivations in order to set up mock calls needed later on
    //   await firo.fillAddresses(TEST_MNEMONIC);
    //   final wallet = await Hive.openBox<dynamic>("${testWalletId}fullRescan");
    //
    //   final rcv = await secureStore.read(
    //       key: "${testWalletId}fullRescan_receiveDerivations");
    //   final chg = await secureStore.read(
    //       key: "${testWalletId}fullRescan_changeDerivations");
    //   final receiveDerivations =
    //       Map<String, dynamic>.from(jsonDecode(rcv as String) as Map);
    //   final changeDerivations =
    //       Map<String, dynamic>.from(jsonDecode(chg as String) as Map);
    //
    //   for (int i = 0; i < receiveDerivations.length; i++) {
    //     final receiveHash = AddressUtils.convertToScriptHash(
    //         receiveDerivations["$i"]!["address"] as String, firoNetwork);
    //     final changeHash = AddressUtils.convertToScriptHash(
    //         changeDerivations["$i"]!["address"] as String, firoNetwork);
    //     List<Map<String, dynamic>> data;
    //     switch (receiveHash) {
    //       case SampleGetHistoryData.scripthash0:
    //         data = SampleGetHistoryData.data0;
    //         break;
    //       case SampleGetHistoryData.scripthash1:
    //         data = SampleGetHistoryData.data1;
    //         break;
    //       case SampleGetHistoryData.scripthash2:
    //         data = SampleGetHistoryData.data2;
    //         break;
    //       case SampleGetHistoryData.scripthash3:
    //         data = SampleGetHistoryData.data3;
    //         break;
    //       default:
    //         data = [];
    //     }
    //     when(client.getHistory(scripthash: receiveHash))
    //         .thenAnswer((_) async => data);
    //
    //     switch (changeHash) {
    //       case SampleGetHistoryData.scripthash0:
    //         data = SampleGetHistoryData.data0;
    //         break;
    //       case SampleGetHistoryData.scripthash1:
    //         data = SampleGetHistoryData.data1;
    //         break;
    //       case SampleGetHistoryData.scripthash2:
    //         data = SampleGetHistoryData.data2;
    //         break;
    //       case SampleGetHistoryData.scripthash3:
    //         data = SampleGetHistoryData.data3;
    //         break;
    //       default:
    //         data = [];
    //     }
    //
    //     when(client.getHistory(scripthash: changeHash))
    //         .thenAnswer((_) async => data);
    //   }
    //
    //   when(client.getLatestCoinId()).thenThrow(Exception());
    //
    //   bool didThrow = false;
    //   try {
    //     await firo.fullRescan(20, 1000);
    //   } catch (e) {
    //     didThrow = true;
    //   }
    //   expect(didThrow, true);
    //
    //   final receivingAddresses = await wallet.get('receivingAddresses');
    //   expect(receivingAddresses, null);
    //
    //   final changeAddresses = await wallet.get('changeAddresses');
    //   expect(changeAddresses, null);
    //
    //   final receivingIndex = await wallet.get('receivingIndex');
    //   expect(receivingIndex, null);
    //
    //   final changeIndex = await wallet.get('changeIndex');
    //   expect(changeIndex, null);
    //
    //   final _rcv = await secureStore.read(
    //       key: "${testWalletId}fullRescan_receiveDerivations");
    //   final _chg = await secureStore.read(
    //       key: "${testWalletId}fullRescan_changeDerivations");
    //   final _receiveDerivations =
    //       Map<String, dynamic>.from(jsonDecode(_rcv as String) as Map);
    //   final _changeDerivations =
    //       Map<String, dynamic>.from(jsonDecode(_chg as String) as Map);
    //
    //   expect(_receiveDerivations.length, 40);
    //   expect(_changeDerivations.length, 40);
    //
    //   final mintIndex = await wallet.get('mintIndex');
    //   expect(mintIndex, null);
    //
    //   final lelantusCoins = await wallet.get('_lelantus_coins');
    //   expect(lelantusCoins, null);
    //
    //   final jIndex = await wallet.get('jindex');
    //   expect(jIndex, null);
    //
    //   final lelantusTxModel = await wallet.get('latest_lelantus_tx_model');
    //   expect(lelantusTxModel, null);
    // }, timeout: const Timeout(Duration(minutes: 3)));
    //
    // test("recoverFromMnemonic then fullRescan", () async {
    //   TestWidgetsFlutterBinding.ensureInitialized();
    //   const MethodChannel('uk.spiralarm.flutter/devicelocale')
    //       .setMockMethodCallHandler((methodCall) async => 'en_US');
    //
    //   final client = MockElectrumX();
    //   final cachedClient = MockCachedElectrumX();
    //   final secureStore = FakeSecureStorage();
    //
    //   // mock electrumx client calls
    //   when(client.getServerFeatures()).thenAnswer((_) async => {
    //         "hosts": <dynamic, dynamic>{},
    //         "pruning": null,
    //         "server_version": "Unit tests",
    //         "protocol_min": "1.4",
    //         "protocol_max": "1.4.2",
    //         "genesis_hash": GENESIS_HASH_MAINNET,
    //         "hash_function": "sha256",
    //         "services": <dynamic>[]
    //       });
    //
    //   when(client.getLatestCoinId()).thenAnswer((_) async => 1);
    //   // when(client.getCoinsForRecovery(setId: 1))
    //   //     .thenAnswer((_) async => getCoinsForRecoveryResponse);
    //   when(client.getUsedCoinSerials(startNumber: 0))
    //       .thenAnswer((_) async => GetUsedSerialsSampleData.serials);
    //
    //   when(cachedClient.clearSharedTransactionCache(coin: Coin.firo))
    //       .thenAnswer((_) async => {});
    //
    //   when(cachedClient.getAnonymitySet(
    //           groupId: "1", blockhash: "", coin: Coin.firo))
    //       .thenAnswer((_) async => GetAnonymitySetSampleData.data);
    //   when(cachedClient.getUsedCoinSerials(startNumber: 0, coin: Coin.firo))
    //       .thenAnswer(
    //           (_) async => GetUsedSerialsSampleData.serials['serials'] as List);
    //
    //   final firo = FiroWallet(
    //     walletName: testWalletName,
    //     walletId: "${testWalletId}recoverFromMnemonic",
    //     coin: Coin.firo,
    //     client: client,
    //     cachedClient: cachedClient,
    //     secureStore: secureStore,
    //     tracker: MockTransactionNotificationTracker(),
    //   );
    //
    //   // pre grab derivations in order to set up mock calls needed later on
    //   await firo.fillAddresses(TEST_MNEMONIC);
    //   final wallet =
    //       await Hive.openBox<dynamic>("${testWalletId}recoverFromMnemonic");
    //
    //   final rcv = await secureStore.read(
    //       key: "${testWalletId}recoverFromMnemonic_receiveDerivations");
    //   final chg = await secureStore.read(
    //       key: "${testWalletId}recoverFromMnemonic_changeDerivations");
    //   final receiveDerivations =
    //       Map<String, dynamic>.from(jsonDecode(rcv as String) as Map);
    //   final changeDerivations =
    //       Map<String, dynamic>.from(jsonDecode(chg as String) as Map);
    //
    //   for (int i = 0; i < receiveDerivations.length; i++) {
    //     final receiveHash = AddressUtils.convertToScriptHash(
    //         receiveDerivations["$i"]!["address"] as String, firoNetwork);
    //     final changeHash = AddressUtils.convertToScriptHash(
    //         changeDerivations["$i"]!["address"] as String, firoNetwork);
    //     List<Map<String, dynamic>> data;
    //     switch (receiveHash) {
    //       case SampleGetHistoryData.scripthash0:
    //         data = SampleGetHistoryData.data0;
    //         break;
    //       case SampleGetHistoryData.scripthash1:
    //         data = SampleGetHistoryData.data1;
    //         break;
    //       case SampleGetHistoryData.scripthash2:
    //         data = SampleGetHistoryData.data2;
    //         break;
    //       case SampleGetHistoryData.scripthash3:
    //         data = SampleGetHistoryData.data3;
    //         break;
    //       default:
    //         data = [];
    //     }
    //     when(client.getHistory(scripthash: receiveHash))
    //         .thenAnswer((_) async => data);
    //
    //     switch (changeHash) {
    //       case SampleGetHistoryData.scripthash0:
    //         data = SampleGetHistoryData.data0;
    //         break;
    //       case SampleGetHistoryData.scripthash1:
    //         data = SampleGetHistoryData.data1;
    //         break;
    //       case SampleGetHistoryData.scripthash2:
    //         data = SampleGetHistoryData.data2;
    //         break;
    //       case SampleGetHistoryData.scripthash3:
    //         data = SampleGetHistoryData.data3;
    //         break;
    //       default:
    //         data = [];
    //     }
    //
    //     when(client.getHistory(scripthash: changeHash))
    //         .thenAnswer((_) async => data);
    //   }
    //
    //   when(client.getBatchHistory(args: {
    //     "0": [SampleGetHistoryData.scripthash0],
    //     "1": [SampleGetHistoryData.scripthash3]
    //   })).thenAnswer((realInvocation) async => {
    //         "0": SampleGetHistoryData.data0,
    //         "1": SampleGetHistoryData.data3,
    //       });
    //
    //   // mock transaction calls
    //   when(cachedClient.getTransaction(
    //     txHash: SampleGetTransactionData.txHash0,
    //     coin: Coin.firo,
    //   )).thenAnswer((_) async => SampleGetTransactionData.txData0);
    //   when(cachedClient.getTransaction(
    //     txHash: SampleGetTransactionData.txHash1,
    //     coin: Coin.firo,
    //   )).thenAnswer((_) async => SampleGetTransactionData.txData1);
    //   when(cachedClient.getTransaction(
    //     txHash: SampleGetTransactionData.txHash2,
    //     coin: Coin.firo,
    //   )).thenAnswer((_) async => SampleGetTransactionData.txData2);
    //   when(cachedClient.getTransaction(
    //     txHash: SampleGetTransactionData.txHash3,
    //     coin: Coin.firo,
    //   )).thenAnswer((_) async => SampleGetTransactionData.txData3);
    //   when(cachedClient.getTransaction(
    //     txHash: SampleGetTransactionData.txHash4,
    //     coin: Coin.firo,
    //   )).thenAnswer((_) async => SampleGetTransactionData.txData4);
    //   when(cachedClient.getTransaction(
    //     txHash: SampleGetTransactionData.txHash5,
    //     coin: Coin.firo,
    //   )).thenAnswer((_) async => SampleGetTransactionData.txData5);
    //   when(cachedClient.getTransaction(
    //     txHash: SampleGetTransactionData.txHash6,
    //     coin: Coin.firo,
    //   )).thenAnswer((_) async => SampleGetTransactionData.txData6);
    //   when(cachedClient.getTransaction(
    //     txHash: SampleGetTransactionData.txHash7,
    //     coin: Coin.firo,
    //   )).thenAnswer((_) async => SampleGetTransactionData.txData7);
    //   when(cachedClient.getTransaction(
    //     txHash: SampleGetTransactionData.txHash8,
    //     coin: Coin.firo,
    //   )).thenAnswer((_) async => SampleGetTransactionData.txData8);
    //   when(cachedClient.getTransaction(
    //     txHash: SampleGetTransactionData.txHash9,
    //     coin: Coin.firo,
    //   )).thenAnswer((_) async => SampleGetTransactionData.txData9);
    //   when(cachedClient.getTransaction(
    //     txHash: SampleGetTransactionData.txHash10,
    //     coin: Coin.firo,
    //   )).thenAnswer((_) async => SampleGetTransactionData.txData10);
    //
    //   await firo.recoverFromMnemonic(
    //       mnemonic: TEST_MNEMONIC,
    //       maxUnusedAddressGap: 20,
    //       maxNumberOfIndexesToCheck: 1000,
    //       height: 0);
    //
    //   final receivingAddresses = await wallet.get('receivingAddresses');
    //   expect(receivingAddresses, ["a8VV7vMzJdTQj1eLEJNskhLEBUxfNWhpAg"]);
    //
    //   final changeAddresses = await wallet.get('changeAddresses');
    //   expect(changeAddresses, ["a5V5r6We6mNZzWJwGwEeRML3mEYLjvK39w"]);
    //
    //   final receivingIndex = await wallet.get('receivingIndex');
    //   expect(receivingIndex, 0);
    //
    //   final changeIndex = await wallet.get('changeIndex');
    //   expect(changeIndex, 0);
    //
    //   final _rcv = await secureStore.read(
    //       key: "${testWalletId}recoverFromMnemonic_receiveDerivations");
    //   final _chg = await secureStore.read(
    //       key: "${testWalletId}recoverFromMnemonic_changeDerivations");
    //   final _receiveDerivations =
    //       Map<String, dynamic>.from(jsonDecode(_rcv as String) as Map);
    //   final _changeDerivations =
    //       Map<String, dynamic>.from(jsonDecode(_chg as String) as Map);
    //   // expect(_receiveDerivations.length, 190);
    //   // expect(_changeDerivations.length, 190);
    //   expect(_receiveDerivations.length, 80);
    //   expect(_changeDerivations.length, 80);
    //
    //   final mintIndex = await wallet.get('mintIndex');
    //   expect(mintIndex, 8);
    //
    //   final lelantusCoins = await wallet.get('_lelantus_coins') as List;
    //   expect(lelantusCoins.length, 7);
    //   final lcoin = lelantusCoins
    //       .firstWhere((element) =>
    //           (Map<String, LelantusCoin>.from(element as Map))
    //               .values
    //               .first
    //               .txId ==
    //           "36c92daa4005d368e28cea917fdb2c1e7069319a4a79fb2ff45c089100680232")
    //       .values
    //       .first as LelantusCoin;
    //   expect(lcoin.index, 1);
    //   expect(lcoin.value, 9658);
    //   expect(lcoin.publicCoin,
    //       "7fd927efbea0a9e4ba299209aaee610c63359857596be0a2da276011a0baa84a0000");
    //   expect(lcoin.txId,
    //       "36c92daa4005d368e28cea917fdb2c1e7069319a4a79fb2ff45c089100680232");
    //   expect(lcoin.anonymitySetId, 1);
    //   expect(lcoin.isUsed, true);
    //
    //   final jIndex = await wallet.get('jindex');
    //   expect(jIndex, [2, 4, 6]);
    //
    //   final lelantusTxModel = await wallet.get('latest_lelantus_tx_model');
    //   expect(lelantusTxModel.getAllTransactions().length, 5);
    //
    //   await firo.fullRescan(20, 1000);
    //
    //   final _receivingAddresses = await wallet.get('receivingAddresses');
    //   expect(_receivingAddresses, ["a8VV7vMzJdTQj1eLEJNskhLEBUxfNWhpAg"]);
    //
    //   final _changeAddresses = await wallet.get('changeAddresses');
    //   expect(_changeAddresses, ["a5V5r6We6mNZzWJwGwEeRML3mEYLjvK39w"]);
    //
    //   final _receivingIndex = await wallet.get('receivingIndex');
    //   expect(_receivingIndex, 0);
    //
    //   final _changeIndex = await wallet.get('changeIndex');
    //   expect(_changeIndex, 0);
    //
    //   final __rcv = await secureStore.read(
    //       key: "${testWalletId}recoverFromMnemonic_receiveDerivations");
    //   final __chg = await secureStore.read(
    //       key: "${testWalletId}recoverFromMnemonic_changeDerivations");
    //   final __receiveDerivations =
    //       Map<String, dynamic>.from(jsonDecode(__rcv as String) as Map);
    //   final __changeDerivations =
    //       Map<String, dynamic>.from(jsonDecode(__chg as String) as Map);
    //   // expect(__receiveDerivations.length, 150);
    //   // expect(__changeDerivations.length, 150);
    //   expect(__receiveDerivations.length, 40);
    //   expect(__changeDerivations.length, 40);
    //
    //   final _mintIndex = await wallet.get('mintIndex');
    //   expect(_mintIndex, 8);
    //
    //   final _lelantusCoins = await wallet.get('_lelantus_coins') as List;
    //   expect(_lelantusCoins.length, 7);
    //   final _lcoin = _lelantusCoins
    //       .firstWhere((element) =>
    //           (Map<String, LelantusCoin>.from(element as Map))
    //               .values
    //               .first
    //               .txId ==
    //           "36c92daa4005d368e28cea917fdb2c1e7069319a4a79fb2ff45c089100680232")
    //       .values
    //       .first as LelantusCoin;
    //   expect(_lcoin.index, 1);
    //   expect(_lcoin.value, 9658);
    //   expect(_lcoin.publicCoin,
    //       "7fd927efbea0a9e4ba299209aaee610c63359857596be0a2da276011a0baa84a0000");
    //   expect(_lcoin.txId,
    //       "36c92daa4005d368e28cea917fdb2c1e7069319a4a79fb2ff45c089100680232");
    //   expect(_lcoin.anonymitySetId, 1);
    //   expect(_lcoin.isUsed, true);
    //
    //   final _jIndex = await wallet.get('jindex');
    //   expect(_jIndex, [2, 4, 6]);
    //
    //   final _lelantusTxModel = await wallet.get('latest_lelantus_tx_model');
    //   expect(_lelantusTxModel.getAllTransactions().length, 5);
    // }, timeout: const Timeout(Duration(minutes: 6)));

    test("recoverFromMnemonic fails testnet", () async {
      final client = MockElectrumX();
      final cachedClient = MockCachedElectrumX();
      final secureStore = FakeSecureStorage();

      // mock electrumx client calls
      when(client.getServerFeatures()).thenAnswer((_) async => {
            "hosts": <dynamic, dynamic>{},
            "pruning": null,
            "server_version": "Unit tests",
            "protocol_min": "1.4",
            "protocol_max": "1.4.2",
            "genesis_hash": GENESIS_HASH_MAINNET,
            "hash_function": "sha256",
            "services": <dynamic>[]
          });

      final firo = FiroWallet(
        walletName: testWalletName,
        walletId: "${testWalletId}recoverFromMnemonic fails testnet",
        coin: Coin.firoTestNet,
        client: client,
        cachedClient: cachedClient,
        secureStore: secureStore,
        tracker: MockTransactionNotificationTracker(),
      );

      expect(
          () async => await firo.recoverFromMnemonic(
              mnemonic: TEST_MNEMONIC,
              maxUnusedAddressGap: 20,
              maxNumberOfIndexesToCheck: 1000,
              height: 0),
          throwsA(isA<Exception>()));
    }, timeout: const Timeout(Duration(minutes: 3)));

    test("recoverFromMnemonic fails mainnet", () async {
      final client = MockElectrumX();
      final cachedClient = MockCachedElectrumX();
      final secureStore = FakeSecureStorage();

      // mock electrumx client calls
      when(client.getServerFeatures()).thenAnswer((_) async => {
            "hosts": <dynamic, dynamic>{},
            "pruning": null,
            "server_version": "Unit tests",
            "protocol_min": "1.4",
            "protocol_max": "1.4.2",
            "genesis_hash": GENESIS_HASH_TESTNET,
            "hash_function": "sha256",
            "services": <dynamic>[]
          });

      final firo = FiroWallet(
        walletName: testWalletName,
        walletId: "${testWalletId}recoverFromMnemonic fails mainnet",
        coin: Coin.firo,
        client: client,
        cachedClient: cachedClient,
        secureStore: secureStore,
        tracker: MockTransactionNotificationTracker(),
      );

      expect(
          () async => await firo.recoverFromMnemonic(
              mnemonic: TEST_MNEMONIC,
              maxUnusedAddressGap: 20,
              height: 0,
              maxNumberOfIndexesToCheck: 1000),
          throwsA(isA<Exception>()));
    });

    test("checkReceivingAddressForTransactions fails", () async {
      final firo = FiroWallet(
        walletId: "${testWalletId}checkReceivingAddressForTransactions fails",
        walletName: testWalletName,
        coin: Coin.firo,
        client: MockElectrumX(),
        cachedClient: MockCachedElectrumX(),
        secureStore: FakeSecureStorage(),
        tracker: MockTransactionNotificationTracker(),
      );

      bool didThrow = false;
      try {
        await firo.checkReceivingAddressForTransactions();
      } catch (_) {
        didThrow = true;
      }
      expect(didThrow, true);
    });

    // test("checkReceivingAddressForTransactions numtxs >= 1", () async {
    //   final client = MockElectrumX();
    //   final secureStore = FakeSecureStorage();
    //
    //   when(client.getHistory(scripthash: SampleGetHistoryData.scripthash1))
    //       .thenAnswer((_) async => SampleGetHistoryData.data1);
    //
    //   final firo = FiroWallet(
    //     walletId:
    //         "${testWalletId}checkReceivingAddressForTransactions numtxs >= 1",
    //     walletName: testWalletName,
    //     coin: Coin.firo,
    //     client: client,
    //     cachedClient: MockCachedElectrumX(),
    //     secureStore: secureStore,
    //     tracker: MockTransactionNotificationTracker(),
    //   );
    //
    //   final wallet = await Hive.openBox<dynamic>(
    //       "${testWalletId}checkReceivingAddressForTransactions numtxs >= 1");
    //   await secureStore.write(
    //       key:
    //           "${testWalletId}checkReceivingAddressForTransactions numtxs >= 1_mnemonic",
    //       value: TEST_MNEMONIC);
    //   await wallet
    //       .put("receivingAddresses", ["aPjLWDTPQsoPHUTxKBNRzoebDALj3eTcfh"]);
    //
    //   await wallet.put("receivingIndex", 1);
    //
    //   await firo.checkReceivingAddressForTransactions();
    //
    //   expect(await wallet.get("receivingIndex"), 2);
    //   expect((await wallet.get("receivingAddresses")).length, 2);
    // });

    test("getLatestSetId", () async {
      final client = MockElectrumX();

      when(client.getLatestCoinId()).thenAnswer((_) async => 1);

      final firo = FiroWallet(
        walletId: "${testWalletId}exit",
        walletName: testWalletName,
        coin: Coin.firo,
        client: client,
        cachedClient: MockCachedElectrumX(),
        secureStore: FakeSecureStorage(),
        tracker: MockTransactionNotificationTracker(),
      );

      final setId = await firo.getLatestSetId();
      expect(setId, 1);
    });

    // test("getSetData", () async {
    //   final client = MockElectrumX();
    //
    //   when(client.getCoinsForRecovery(setId: 1))
    //       .thenAnswer((_) async => getCoinsForRecoveryResponse);
    //
    //   final firo = FiroWallet(
    //     walletId: testWalletId + "exit",
    //     walletName: testWalletName,
    //     networkType: firoNetworkType,
    //     client: client,
    //     cachedClient: MockCachedElectrumX(),
    //     secureStore: FakeSecureStorage(),
    //
    //     tracker: MockTransactionNotificationTracker(),
    //   );
    //
    //   final setData = await firo.getSetData(1);
    //   expect(setData, getCoinsForRecoveryResponse);
    // });

    test("getUsedCoinSerials", () async {
      final client = MockElectrumX();
      final cachedClient = MockCachedElectrumX();

      // when(client.getUsedCoinSerials(startNumber: 0))
      //     .thenAnswer((_) async => GetUsedSerialsSampleData.serials);

      when(cachedClient.getAnonymitySet(
              groupId: "1", blockhash: "", coin: Coin.firo))
          .thenAnswer((_) async => GetAnonymitySetSampleData.data);
      when(cachedClient.getUsedCoinSerials(startNumber: 0, coin: Coin.firo))
          .thenAnswer((_) async => List<String>.from(
              GetUsedSerialsSampleData.serials['serials'] as List));

      final firo = FiroWallet(
        walletId: "${testWalletId}getUsedCoinSerials",
        walletName: testWalletName,
        coin: Coin.firo,
        client: client,
        cachedClient: cachedClient,
        secureStore: FakeSecureStorage(),
        tracker: MockTransactionNotificationTracker(),
      );

      final serials = await firo.getUsedCoinSerials();
      expect(serials, GetUsedSerialsSampleData.serials['serials']);
    });

    test("firo refresh", () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      const MethodChannel('uk.spiralarm.flutter/devicelocale')
          .setMockMethodCallHandler((methodCall) async => 'en_US');

      final client = MockElectrumX();
      final cachedClient = MockCachedElectrumX();
      final secureStore = FakeSecureStorage();

      // set mnemonic
      await secureStore.write(
          key: "${testWalletId}refresh_mnemonic",
          value: RefreshTestParams.mnemonic);

      when(client.getBatchUTXOs(args: batchUtxoRequest))
          .thenAnswer((realInvocation) async => {});

      when(client.getBatchHistory(args: {
        "0": [SampleGetHistoryData.scripthash1],
        "1": [SampleGetHistoryData.scripthash0],
        "2": [SampleGetHistoryData.scripthash2],
        "3": [SampleGetHistoryData.scripthash3],
      })).thenAnswer((realInvocation) async => {
            "0": SampleGetHistoryData.data1,
            "1": SampleGetHistoryData.data0,
            "2": SampleGetHistoryData.data2,
            "3": SampleGetHistoryData.data3,
          });

      // mock electrumx client calls
      when(client.getServerFeatures()).thenAnswer((_) async => {
            "hosts": <dynamic, dynamic>{},
            "pruning": null,
            "server_version": "Unit tests",
            "protocol_min": "1.4",
            "protocol_max": "1.4.2",
            "genesis_hash": GENESIS_HASH_MAINNET,
            "hash_function": "sha256",
            "services": <dynamic>[]
          });

      when(client.getLatestCoinId()).thenAnswer((_) async => 1);
      // when(client.getCoinsForRecovery(setId: 1))
      //     .thenAnswer((_) async => getCoinsForRecoveryResponse);
      when(client.getUsedCoinSerials(startNumber: 0))
          .thenAnswer((_) async => GetUsedSerialsSampleData.serials);

      when(client.estimateFee(blocks: 1))
          .thenAnswer((_) async => Decimal.parse("0.00001000"));
      when(client.estimateFee(blocks: 5))
          .thenAnswer((_) async => Decimal.parse("0.00001000"));
      when(client.estimateFee(blocks: 20))
          .thenAnswer((_) async => Decimal.parse("0.00001000"));

      // mock history calls
      when(client.getHistory(scripthash: SampleGetHistoryData.scripthash0))
          .thenAnswer((_) async => SampleGetHistoryData.data0);
      when(client.getHistory(scripthash: SampleGetHistoryData.scripthash1))
          .thenAnswer((_) async => SampleGetHistoryData.data1);
      when(client.getHistory(scripthash: SampleGetHistoryData.scripthash2))
          .thenAnswer((_) async => SampleGetHistoryData.data2);
      when(client.getHistory(scripthash: SampleGetHistoryData.scripthash3))
          .thenAnswer((_) async => SampleGetHistoryData.data3);

      // mock transaction calls
      when(cachedClient.getTransaction(
        txHash: SampleGetTransactionData.txHash0,
        coin: Coin.firo,
      )).thenAnswer((_) async => SampleGetTransactionData.txData0);
      when(cachedClient.getTransaction(
        txHash: SampleGetTransactionData.txHash1,
        coin: Coin.firo,
      )).thenAnswer((_) async => SampleGetTransactionData.txData1);
      when(cachedClient.getTransaction(
        txHash: SampleGetTransactionData.txHash2,
        coin: Coin.firo,
      )).thenAnswer((_) async => SampleGetTransactionData.txData2);
      when(cachedClient.getTransaction(
        txHash: SampleGetTransactionData.txHash3,
        coin: Coin.firo,
      )).thenAnswer((_) async => SampleGetTransactionData.txData3);
      when(cachedClient.getTransaction(
        txHash: SampleGetTransactionData.txHash4,
        coin: Coin.firo,
      )).thenAnswer((_) async => SampleGetTransactionData.txData4);
      when(cachedClient.getTransaction(
        txHash: SampleGetTransactionData.txHash5,
        coin: Coin.firo,
      )).thenAnswer((_) async => SampleGetTransactionData.txData5);
      when(cachedClient.getTransaction(
        txHash: SampleGetTransactionData.txHash6,
        coin: Coin.firo,
      )).thenAnswer((_) async => SampleGetTransactionData.txData6);

      // mock utxo calls
      when(client.getUTXOs(scripthash: anyNamed("scripthash")))
          .thenAnswer((_) async => []);

      final firo = FiroWallet(
        walletName: testWalletName,
        walletId: "${testWalletId}refresh",
        coin: Coin.firo,
        client: client,
        cachedClient: cachedClient,
        secureStore: secureStore,
        tracker: MockTransactionNotificationTracker(),
      );

      final wallet = await Hive.openBox<dynamic>("${testWalletId}refresh");
      await wallet.put(
          'receivingAddresses', RefreshTestParams.receivingAddresses);
      await wallet.put('changeAddresses', RefreshTestParams.changeAddresses);

      // set timer to non null so a periodic timer isn't created
      firo.timer = Timer(const Duration(), () {});

      await firo.refresh();

      // kill timer and listener
      await firo.exit();
    }, timeout: const Timeout(Duration(minutes: 3)));

    // test("send succeeds", () async {
    //   TestWidgetsFlutterBinding.ensureInitialized();
    //   const MethodChannel('uk.spiralarm.flutter/devicelocale')
    //       .setMockMethodCallHandler((methodCall) async => 'en_US');
    //   final client = MockElectrumX();
    //   final cachedClient = MockCachedElectrumX();
    //   final secureStore = FakeSecureStorage();
    //
    //
    //   String expectedTxid = "-1";
    //   when(client.getLatestCoinId()).thenAnswer((_) async => 1);
    //   when(client.getBlockHeadTip()).thenAnswer(
    //       (_) async => {"height": 459185, "hex": "... some block hex ..."});
    //
    //   when(client.broadcastTransaction(rawTx: anyNamed("rawTx")))
    //       .thenAnswer((realInvocation) async {
    //     final rawTx = realInvocation.namedArguments[Symbol("rawTx")] as String;
    //     final rawTxData = Format.stringToUint8List(rawTx);
    //
    //     final hash = sha256
    //         .convert(sha256.convert(rawTxData.toList(growable: false)).bytes);
    //
    //     final reversedBytes =
    //         Uint8List.fromList(hash.bytes.reversed.toList(growable: false));
    //
    //     final txid = Format.uint8listToString(reversedBytes);
    //     expectedTxid = txid;
    //     return txid;
    //   });
    //
    //   when(cachedClient.getAnonymitySet(
    //     groupId: "1",
    //     coin: Coin.firo,
    //   )).thenAnswer((_) async => GetAnonymitySetSampleData.data);
    //
    //   // mock price calls
    //   when(priceAPI.getPricesAnd24hChange(baseCurrency: "USD")).thenAnswer(
    //       (_) async => {Coin.firo: Tuple2(Decimal.fromInt(10), 1.0)});
    //
    //   // mock transaction calls
    //   when(cachedClient.getTransaction(
    //     txHash: SampleGetTransactionData.txHash0,
    //     coin: Coin.firo,
    //   )).thenAnswer((_) async => SampleGetTransactionData.txData0);
    //   when(cachedClient.getTransaction(
    //     txHash: SampleGetTransactionData.txHash1,
    //     coin: Coin.firo,
    //   )).thenAnswer((_) async => SampleGetTransactionData.txData1);
    //   when(cachedClient.getTransaction(
    //     txHash: SampleGetTransactionData.txHash2,
    //     coin: Coin.firo,
    //   )).thenAnswer((_) async => SampleGetTransactionData.txData2);
    //   when(cachedClient.getTransaction(
    //     txHash: SampleGetTransactionData.txHash3,
    //     coin: Coin.firo,
    //   )).thenAnswer((_) async => SampleGetTransactionData.txData3);
    //   when(cachedClient.getTransaction(
    //     txHash: SampleGetTransactionData.txHash4,
    //     coin: Coin.firo,
    //   )).thenAnswer((_) async => SampleGetTransactionData.txData4);
    //   when(cachedClient.getTransaction(
    //     txHash: SampleGetTransactionData.txHash5,
    //     coin: Coin.firo,
    //   )).thenAnswer((_) async => SampleGetTransactionData.txData5);
    //   when(cachedClient.getTransaction(
    //     txHash: SampleGetTransactionData.txHash6,
    //     coin: Coin.firo,
    //   )).thenAnswer((_) async => SampleGetTransactionData.txData6);
    //   when(cachedClient.getTransaction(
    //     txHash: SampleGetTransactionData.txHash7,
    //     coin: Coin.firo,
    //   )).thenAnswer((_) async => SampleGetTransactionData.txData7);
    //   when(cachedClient.getTransaction(
    //     txHash: SampleGetTransactionData.txHash8,
    //     coin: Coin.firo,
    //   )).thenAnswer((_) async => SampleGetTransactionData.txData8);
    //   when(cachedClient.getTransaction(
    //     txHash: SampleGetTransactionData.txHash9,
    //     coin: Coin.firo,
    //   )).thenAnswer((_) async => SampleGetTransactionData.txData9);
    //   when(cachedClient.getTransaction(
    //     txHash: SampleGetTransactionData.txHash10,
    //     coin: Coin.firo,
    //   )).thenAnswer((_) async => SampleGetTransactionData.txData10);
    //
    //   final firo = FiroWallet(
    //     walletId: "${testWalletId}send",
    //     walletName: testWalletName,
    //     coin: Coin.firo,
    //     client: client,
    //     cachedClient: cachedClient,
    //     secureStore: secureStore,
    //
    //
    //     tracker: MockTransactionNotificationTracker(),
    //   );
    //
    //   // set mnemonic
    //   await secureStore.write(
    //       key: "${testWalletId}send_mnemonic", value: TEST_MNEMONIC);
    //
    //   // set timer to non null so a periodic timer isn't created
    //   firo.timer = Timer(const Duration(), () {});
    //
    //   // build sending wallet
    //   await firo.fillAddresses(TEST_MNEMONIC);
    //   final wallet = await Hive.openBox<dynamic>("${testWalletId}send");
    //
    //   final rcv =
    //       await secureStore.read(key: "${testWalletId}send_receiveDerivations");
    //   final chg =
    //       await secureStore.read(key: "${testWalletId}send_changeDerivations");
    //   final receiveDerivations =
    //       Map<String, dynamic>.from(jsonDecode(rcv as String) as Map);
    //   final changeDerivations =
    //       Map<String, dynamic>.from(jsonDecode(chg as String) as Map);
    //
    //   for (int i = 0; i < receiveDerivations.length; i++) {
    //     final receiveHash = AddressUtils.convertToScriptHash(
    //         receiveDerivations["$i"]!["address"] as String, firoNetwork);
    //     final changeHash = AddressUtils.convertToScriptHash(
    //         changeDerivations["$i"]!["address"] as String, firoNetwork);
    //     List<Map<String, dynamic>> data;
    //     switch (receiveHash) {
    //       case SampleGetHistoryData.scripthash0:
    //         data = SampleGetHistoryData.data0;
    //         break;
    //       case SampleGetHistoryData.scripthash1:
    //         data = SampleGetHistoryData.data1;
    //         break;
    //       case SampleGetHistoryData.scripthash2:
    //         data = SampleGetHistoryData.data2;
    //         break;
    //       case SampleGetHistoryData.scripthash3:
    //         data = SampleGetHistoryData.data3;
    //         break;
    //       default:
    //         data = [];
    //     }
    //     when(client.getHistory(scripthash: receiveHash))
    //         .thenAnswer((_) async => data);
    //
    //     switch (changeHash) {
    //       case SampleGetHistoryData.scripthash0:
    //         data = SampleGetHistoryData.data0;
    //         break;
    //       case SampleGetHistoryData.scripthash1:
    //         data = SampleGetHistoryData.data1;
    //         break;
    //       case SampleGetHistoryData.scripthash2:
    //         data = SampleGetHistoryData.data2;
    //         break;
    //       case SampleGetHistoryData.scripthash3:
    //         data = SampleGetHistoryData.data3;
    //         break;
    //       default:
    //         data = [];
    //     }
    //
    //     when(client.getHistory(scripthash: changeHash))
    //         .thenAnswer((_) async => data);
    //   }
    //
    //   await wallet.put('_lelantus_coins', SampleLelantus.lelantusCoins);
    //   await wallet.put('jindex', [2, 4, 6]);
    //   await wallet.put('mintIndex', 8);
    //   await wallet.put('receivingAddresses', [
    //     "a8VV7vMzJdTQj1eLEJNskhLEBUxfNWhpAg",
    //     "aPjLWDTPQsoPHUTxKBNRzoebDALj3eTcfh",
    //     "aKmXfS7nEZdqWBGRdAXcyMoEoKhZQDPBoq"
    //   ]);
    //   await wallet
    //       .put('changeAddresses', ["a5V5r6We6mNZzWJwGwEeRML3mEYLjvK39w"]);
    //
    //   final result = await firo.send(
    //       toAddress: "aHZJsucDrhr4Uzzx6XXrKnaTgLxsEAokvV", amount: 100);
    //
    //   expect(result, isA<String>());
    //   expect(result, expectedTxid);
    //   expect(result.length, 64);
    // }, timeout: const Timeout(Duration(minutes: 3)));

    // test("prepareSend fails due to insufficient balance", () async {
    //   TestWidgetsFlutterBinding.ensureInitialized();
    //   const MethodChannel('uk.spiralarm.flutter/devicelocale')
    //       .setMockMethodCallHandler((methodCall) async => 'en_US');
    //
    //   final client = MockElectrumX();
    //   final cachedClient = MockCachedElectrumX();
    //   final secureStore = FakeSecureStorage();
    //
    //   when(client.getLatestCoinId()).thenAnswer((_) async => 1);
    //   when(client.getBlockHeadTip()).thenAnswer(
    //       (_) async => {"height": 459185, "hex": "... some block hex ..."});
    //
    //   when(client.broadcastTransaction(rawTx: anyNamed("rawTx")))
    //       .thenAnswer((realInvocation) async {
    //     final rawTx =
    //         realInvocation.namedArguments[const Symbol("rawTx")] as String;
    //     final rawTxData = Format.stringToUint8List(rawTx);
    //
    //     final hash = sha256
    //         .convert(sha256.convert(rawTxData.toList(growable: false)).bytes);
    //
    //     final reversedBytes =
    //         Uint8List.fromList(hash.bytes.reversed.toList(growable: false));
    //
    //     final txid = Format.uint8listToString(reversedBytes);
    //     return txid;
    //   });
    //   when(client.getBatchHistory(args: batchHistoryRequest0))
    //       .thenAnswer((realInvocation) async => batchHistoryResponse0);
    //
    //   when(cachedClient.getAnonymitySet(
    //     groupId: "1",
    //     coin: Coin.firo,
    //   )).thenAnswer((_) async => GetAnonymitySetSampleData.data);
    //
    //   // mock transaction calls
    //   when(cachedClient.getTransaction(
    //     txHash: SampleGetTransactionData.txHash0,
    //     coin: Coin.firo,
    //   )).thenAnswer((_) async => SampleGetTransactionData.txData0);
    //   when(cachedClient.getTransaction(
    //     txHash: SampleGetTransactionData.txHash1,
    //     coin: Coin.firo,
    //   )).thenAnswer((_) async => SampleGetTransactionData.txData1);
    //   when(cachedClient.getTransaction(
    //     txHash: SampleGetTransactionData.txHash2,
    //     coin: Coin.firo,
    //   )).thenAnswer((_) async => SampleGetTransactionData.txData2);
    //   when(cachedClient.getTransaction(
    //     txHash: SampleGetTransactionData.txHash3,
    //     coin: Coin.firo,
    //   )).thenAnswer((_) async => SampleGetTransactionData.txData3);
    //   when(cachedClient.getTransaction(
    //     txHash: SampleGetTransactionData.txHash4,
    //     coin: Coin.firo,
    //   )).thenAnswer((_) async => SampleGetTransactionData.txData4);
    //   when(cachedClient.getTransaction(
    //     txHash: SampleGetTransactionData.txHash5,
    //     coin: Coin.firo,
    //   )).thenAnswer((_) async => SampleGetTransactionData.txData5);
    //   when(cachedClient.getTransaction(
    //     txHash: SampleGetTransactionData.txHash6,
    //     coin: Coin.firo,
    //   )).thenAnswer((_) async => SampleGetTransactionData.txData6);
    //   when(cachedClient.getTransaction(
    //     txHash: SampleGetTransactionData.txHash7,
    //     coin: Coin.firo,
    //   )).thenAnswer((_) async => SampleGetTransactionData.txData7);
    //   when(cachedClient.getTransaction(
    //     txHash: SampleGetTransactionData.txHash8,
    //     coin: Coin.firo,
    //   )).thenAnswer((_) async => SampleGetTransactionData.txData8);
    //   when(cachedClient.getTransaction(
    //     txHash: SampleGetTransactionData.txHash9,
    //     coin: Coin.firo,
    //   )).thenAnswer((_) async => SampleGetTransactionData.txData9);
    //   when(cachedClient.getTransaction(
    //     txHash: SampleGetTransactionData.txHash10,
    //     coin: Coin.firo,
    //   )).thenAnswer((_) async => SampleGetTransactionData.txData10);
    //
    //   final firo = FiroWallet(
    //     walletId: "${testWalletId}send",
    //     coin: Coin.firo,
    //     walletName: testWalletName,
    //     client: client,
    //     cachedClient: cachedClient,
    //     secureStore: secureStore,
    //     tracker: MockTransactionNotificationTracker(),
    //   );
    //
    //   // set mnemonic
    //   await secureStore.write(
    //       key: "${testWalletId}send_mnemonic", value: TEST_MNEMONIC);
    //
    //   // set timer to non null so a periodic timer isn't created
    //   firo.timer = Timer(const Duration(), () {});
    //
    //   // build sending wallet
    //   await firo.fillAddresses(TEST_MNEMONIC);
    //   final wallet = await Hive.openBox<dynamic>("${testWalletId}send");
    //
    //   final rcv =
    //       await secureStore.read(key: "${testWalletId}send_receiveDerivations");
    //   final chg =
    //       await secureStore.read(key: "${testWalletId}send_changeDerivations");
    //   final receiveDerivations =
    //       Map<String, dynamic>.from(jsonDecode(rcv as String) as Map);
    //   final changeDerivations =
    //       Map<String, dynamic>.from(jsonDecode(chg as String) as Map);
    //
    //   for (int i = 0; i < receiveDerivations.length; i++) {
    //     final receiveHash = AddressUtils.convertToScriptHash(
    //         receiveDerivations["$i"]!["address"] as String, firoNetwork);
    //     final changeHash = AddressUtils.convertToScriptHash(
    //         changeDerivations["$i"]!["address"] as String, firoNetwork);
    //     List<Map<String, dynamic>> data;
    //     switch (receiveHash) {
    //       case SampleGetHistoryData.scripthash0:
    //         data = SampleGetHistoryData.data0;
    //         break;
    //       case SampleGetHistoryData.scripthash1:
    //         data = SampleGetHistoryData.data1;
    //         break;
    //       case SampleGetHistoryData.scripthash2:
    //         data = SampleGetHistoryData.data2;
    //         break;
    //       case SampleGetHistoryData.scripthash3:
    //         data = SampleGetHistoryData.data3;
    //         break;
    //       default:
    //         data = [];
    //     }
    //     when(client.getHistory(scripthash: receiveHash))
    //         .thenAnswer((_) async => data);
    //
    //     switch (changeHash) {
    //       case SampleGetHistoryData.scripthash0:
    //         data = SampleGetHistoryData.data0;
    //         break;
    //       case SampleGetHistoryData.scripthash1:
    //         data = SampleGetHistoryData.data1;
    //         break;
    //       case SampleGetHistoryData.scripthash2:
    //         data = SampleGetHistoryData.data2;
    //         break;
    //       case SampleGetHistoryData.scripthash3:
    //         data = SampleGetHistoryData.data3;
    //         break;
    //       default:
    //         data = [];
    //     }
    //
    //     when(client.getHistory(scripthash: changeHash))
    //         .thenAnswer((_) async => data);
    //   }
    //
    //   await wallet.put('_lelantus_coins', <dynamic>[]);
    //   await wallet.put('jindex', <dynamic>[]);
    //   await wallet.put('mintIndex', 0);
    //   await wallet.put('receivingAddresses', [
    //     "a8VV7vMzJdTQj1eLEJNskhLEBUxfNWhpAg",
    //     "aPjLWDTPQsoPHUTxKBNRzoebDALj3eTcfh",
    //     "aKmXfS7nEZdqWBGRdAXcyMoEoKhZQDPBoq"
    //   ]);
    //   await wallet
    //       .put('changeAddresses', ["a5V5r6We6mNZzWJwGwEeRML3mEYLjvK39w"]);
    //
    //   expect(
    //       () async => await firo.prepareSend(
    //           address: "aHZJsucDrhr4Uzzx6XXrKnaTgLxsEAokvV",
    //           satoshiAmount: 100),
    //       throwsA(isA<Exception>()));
    // }, timeout: const Timeout(Duration(minutes: 3)));

    // test("wallet balances", () async {
    //   TestWidgetsFlutterBinding.ensureInitialized();
    //   const MethodChannel('uk.spiralarm.flutter/devicelocale')
    //       .setMockMethodCallHandler((methodCall) async => 'en_US');
    //
    //   final client = MockElectrumX();
    //   final cachedClient = MockCachedElectrumX();
    //
    //   // mock history calls
    //   when(client.getHistory(scripthash: SampleGetHistoryData.scripthash0))
    //       .thenAnswer((_) async => SampleGetHistoryData.data0);
    //   when(client.getHistory(scripthash: SampleGetHistoryData.scripthash1))
    //       .thenAnswer((_) async => SampleGetHistoryData.data1);
    //   when(client.getHistory(scripthash: SampleGetHistoryData.scripthash2))
    //       .thenAnswer((_) async => SampleGetHistoryData.data2);
    //   when(client.getHistory(scripthash: SampleGetHistoryData.scripthash3))
    //       .thenAnswer((_) async => SampleGetHistoryData.data3);
    //
    //   when(client.getBatchHistory(args: batchHistoryRequest0))
    //       .thenAnswer((realInvocation) async => batchHistoryResponse0);
    //
    //   when(client.getBatchUTXOs(args: batchUtxoRequest))
    //       .thenAnswer((realInvocation) async => {});
    //
    //   // mock transaction calls
    //   when(cachedClient.getTransaction(
    //     txHash: SampleGetTransactionData.txHash0,
    //     coin: Coin.firo,
    //   )).thenAnswer((_) async => SampleGetTransactionData.txData0);
    //   when(cachedClient.getTransaction(
    //     txHash: SampleGetTransactionData.txHash1,
    //     coin: Coin.firo,
    //   )).thenAnswer((_) async => SampleGetTransactionData.txData1);
    //   when(cachedClient.getTransaction(
    //     txHash: SampleGetTransactionData.txHash2,
    //     coin: Coin.firo,
    //   )).thenAnswer((_) async => SampleGetTransactionData.txData2);
    //   when(cachedClient.getTransaction(
    //     txHash: SampleGetTransactionData.txHash3,
    //     coin: Coin.firo,
    //   )).thenAnswer((_) async => SampleGetTransactionData.txData3);
    //   when(cachedClient.getTransaction(
    //     txHash: SampleGetTransactionData.txHash4,
    //     coin: Coin.firo,
    //   )).thenAnswer((_) async => SampleGetTransactionData.txData4);
    //   when(cachedClient.getTransaction(
    //     txHash: SampleGetTransactionData.txHash5,
    //     coin: Coin.firo,
    //   )).thenAnswer((_) async => SampleGetTransactionData.txData5);
    //   when(cachedClient.getTransaction(
    //     txHash: SampleGetTransactionData.txHash6,
    //     coin: Coin.firo,
    //   )).thenAnswer((_) async => SampleGetTransactionData.txData6);
    //
    //   final firo = FiroWallet(
    //     walletId: "${testWalletId}wallet balances",
    //     walletName: "pendingBalance wallet name",
    //     coin: Coin.firo,
    //     client: client,
    //     cachedClient: cachedClient,
    //     secureStore: FakeSecureStorage(),
    //     tracker: MockTransactionNotificationTracker(),
    //   );
    //
    //   final wallet =
    //       await Hive.openBox<dynamic>("${testWalletId}wallet balances");
    //   await wallet.put('_lelantus_coins', SampleLelantus.lelantusCoins);
    //   await wallet.put('jindex', [2, 4, 6]);
    //   await wallet.put('mintIndex', 8);
    //   await wallet.put('receivingAddresses', [
    //     "a8VV7vMzJdTQj1eLEJNskhLEBUxfNWhpAg",
    //     "aPjLWDTPQsoPHUTxKBNRzoebDALj3eTcfh",
    //     "aKmXfS7nEZdqWBGRdAXcyMoEoKhZQDPBoq",
    //   ]);
    //
    //   await wallet.put('changeAddresses', [
    //     "a5V5r6We6mNZzWJwGwEeRML3mEYLjvK39w",
    //   ]);
    //
    //   expect(firo.balance.getPending(), Decimal.zero);
    //   expect(firo.balance.getSpendable(), Decimal.parse("0.00021594"));
    //   expect(firo.balance.getTotal(), Decimal.parse("0.00021594"));
    // });

    // test("get transactions", () async {
    //   final client = MockElectrumX();
    //   final cachedClient = MockCachedElectrumX();
    //   final secureStore = FakeSecureStorage();
    //
    //   // set mnemonic
    //   await secureStore.write(
    //       key: "${testWalletId}transactionData_mnemonic",
    //       value: RefreshTestParams.mnemonic);
    //
    //   // mock electrumx client calls
    //   when(client.getServerFeatures()).thenAnswer((_) async => {
    //         "hosts": <dynamic, dynamic>{},
    //         "pruning": null,
    //         "server_version": "Unit tests",
    //         "protocol_min": "1.4",
    //         "protocol_max": "1.4.2",
    //         "genesis_hash": GENESIS_HASH_MAINNET,
    //         "hash_function": "sha256",
    //         "services": <dynamic>[]
    //       });
    //
    //   when(client.getLatestCoinId()).thenAnswer((_) async => 1);
    //   // when(client.getCoinsForRecovery(setId: 1))
    //   //     .thenAnswer((_) async => getCoinsForRecoveryResponse);
    //   when(client.getUsedCoinSerials(startNumber: 0))
    //       .thenAnswer((_) async => GetUsedSerialsSampleData.serials);
    //
    //   when(client.estimateFee(blocks: 1))
    //       .thenAnswer((_) async => Decimal.parse("0.00001000"));
    //   when(client.estimateFee(blocks: 5))
    //       .thenAnswer((_) async => Decimal.parse("0.00001000"));
    //   when(client.estimateFee(blocks: 20))
    //       .thenAnswer((_) async => Decimal.parse("0.00001000"));
    //
    //   // mock history calls
    //   when(client.getHistory(scripthash: SampleGetHistoryData.scripthash0))
    //       .thenAnswer((_) async => SampleGetHistoryData.data0);
    //   when(client.getHistory(scripthash: SampleGetHistoryData.scripthash1))
    //       .thenAnswer((_) async => SampleGetHistoryData.data1);
    //   when(client.getHistory(scripthash: SampleGetHistoryData.scripthash2))
    //       .thenAnswer((_) async => SampleGetHistoryData.data2);
    //   when(client.getHistory(scripthash: SampleGetHistoryData.scripthash3))
    //       .thenAnswer((_) async => SampleGetHistoryData.data3);
    //
    //   // mock transaction calls
    //   when(cachedClient.getTransaction(
    //     txHash: SampleGetTransactionData.txHash0,
    //     coin: Coin.firo,
    //   )).thenAnswer((_) async => SampleGetTransactionData.txData0);
    //   when(cachedClient.getTransaction(
    //     txHash: SampleGetTransactionData.txHash1,
    //     coin: Coin.firo,
    //   )).thenAnswer((_) async => SampleGetTransactionData.txData1);
    //   when(cachedClient.getTransaction(
    //     txHash: SampleGetTransactionData.txHash2,
    //     coin: Coin.firo,
    //   )).thenAnswer((_) async => SampleGetTransactionData.txData2);
    //   when(cachedClient.getTransaction(
    //     txHash: SampleGetTransactionData.txHash3,
    //     coin: Coin.firo,
    //   )).thenAnswer((_) async => SampleGetTransactionData.txData3);
    //   when(cachedClient.getTransaction(
    //     txHash: SampleGetTransactionData.txHash4,
    //     coin: Coin.firo,
    //   )).thenAnswer((_) async => SampleGetTransactionData.txData4);
    //   when(cachedClient.getTransaction(
    //     txHash: SampleGetTransactionData.txHash5,
    //     coin: Coin.firo,
    //   )).thenAnswer((_) async => SampleGetTransactionData.txData5);
    //   when(cachedClient.getTransaction(
    //     txHash: SampleGetTransactionData.txHash6,
    //     coin: Coin.firo,
    //   )).thenAnswer((_) async => SampleGetTransactionData.txData6);
    //
    //   // mock utxo calls
    //   when(client.getUTXOs(scripthash: anyNamed("scripthash")))
    //       .thenAnswer((_) async => []);
    //
    //   final firo = FiroWallet(
    //     walletName: testWalletName,
    //     walletId: "${testWalletId}transactionData",
    //     coin: Coin.firo,
    //     client: client,
    //     cachedClient: cachedClient,
    //     secureStore: secureStore,
    //     tracker: MockTransactionNotificationTracker(),
    //   );
    //
    //   final wallet =
    //       await Hive.openBox<dynamic>("${testWalletId}transactionData");
    //   await wallet.put(
    //       'receivingAddresses', RefreshTestParams.receivingAddresses);
    //   await wallet.put('changeAddresses', RefreshTestParams.changeAddresses);
    //
    //   final txData = await firo.transactions;
    //
    //   expect(txData, isA<List<Transaction>>());
    //
    //   // kill timer and listener
    //   await firo.exit();
    // });

    // test("autoMint", () async {
    //   TestWidgetsFlutterBinding.ensureInitialized();
    //   const MethodChannel('uk.spiralarm.flutter/devicelocale')
    //       .setMockMethodCallHandler((methodCall) async => 'en_US');
    //
    //   final client = MockElectrumX();
    //   final cachedClient = MockCachedElectrumX();
    //   final secureStore = FakeSecureStorage();
    //
    //
    //   // mock electrumx client calls
    //   when(client.getServerFeatures()).thenAnswer((_) async => {
    //         "hosts": <dynamic, dynamic>{},
    //         "pruning": null,
    //         "server_version": "Unit tests",
    //         "protocol_min": "1.4",
    //         "protocol_max": "1.4.2",
    //         "genesis_hash": GENESIS_HASH_MAINNET,
    //         "hash_function": "sha256",
    //         "services": <dynamic>[]
    //       });
    //
    //   when(client.getBlockHeadTip()).thenAnswer(
    //       (_) async => {"height": 465873, "hex": "this value not used here"});
    //
    //   when(client.broadcastTransaction(rawTx: anyNamed("rawTx")))
    //       .thenAnswer((realInvocation) async {
    //     final rawTx =
    //         realInvocation.namedArguments[const Symbol("rawTx")] as String;
    //     final rawTxData = Format.stringToUint8List(rawTx);
    //
    //     final hash = sha256
    //         .convert(sha256.convert(rawTxData.toList(growable: false)).bytes);
    //
    //     final reversedBytes =
    //         Uint8List.fromList(hash.bytes.reversed.toList(growable: false));
    //
    //     final txid = Format.uint8listToString(reversedBytes);
    //
    //     return txid;
    //   });
    //
    //   when(client.estimateFee(blocks: 1))
    //       .thenAnswer((_) async => Decimal.parse("0.00001000"));
    //   when(client.estimateFee(blocks: 5))
    //       .thenAnswer((_) async => Decimal.parse("0.00001000"));
    //   when(client.estimateFee(blocks: 20))
    //       .thenAnswer((_) async => Decimal.parse("0.00001000"));
    //
    //   when(cachedClient.getAnonymitySet(
    //           groupId: "1", blockhash: "", coin: Coin.firo))
    //       .thenAnswer((_) async => GetAnonymitySetSampleData.data);
    //   when(cachedClient.getUsedCoinSerials(startNumber: 0, coin: Coin.firo))
    //       .thenAnswer(
    //           (_) async => GetUsedSerialsSampleData.serials['serials'] as List);
    //
    //   when(client.getLatestCoinId()).thenAnswer((_) async => 1);
    //   // when(client.getCoinsForRecovery(setId: 1))
    //   //     .thenAnswer((_) async => getCoinsForRecoveryResponse);
    //   when(client.getUsedCoinSerials(startNumber: 0))
    //       .thenAnswer((_) async => GetUsedSerialsSampleData.serials);
    //
    //   // mock price calls
    //   when(priceAPI.getPricesAnd24hChange(baseCurrency: "USD")).thenAnswer(
    //       (_) async => {Coin.firo: Tuple2(Decimal.fromInt(10), 1.0)});
    //
    //   // mock transaction calls
    //   when(cachedClient.getTransaction(
    //     txHash: SampleGetTransactionData.txHash0,
    //     coin: Coin.firo,
    //   )).thenAnswer((_) async => SampleGetTransactionData.txData0);
    //   when(cachedClient.getTransaction(
    //     txHash: SampleGetTransactionData.txHash1,
    //     coin: Coin.firo,
    //   )).thenAnswer((_) async => SampleGetTransactionData.txData1);
    //   when(cachedClient.getTransaction(
    //     txHash: SampleGetTransactionData.txHash2,
    //     coin: Coin.firo,
    //   )).thenAnswer((_) async => SampleGetTransactionData.txData2);
    //   when(cachedClient.getTransaction(
    //     txHash: SampleGetTransactionData.txHash3,
    //     coin: Coin.firo,
    //   )).thenAnswer((_) async => SampleGetTransactionData.txData3);
    //   when(cachedClient.getTransaction(
    //     txHash: SampleGetTransactionData.txHash4,
    //     coin: Coin.firo,
    //   )).thenAnswer((_) async => SampleGetTransactionData.txData4);
    //   when(cachedClient.getTransaction(
    //     txHash: SampleGetTransactionData.txHash5,
    //     coin: Coin.firo,
    //   )).thenAnswer((_) async => SampleGetTransactionData.txData5);
    //   when(cachedClient.getTransaction(
    //     txHash: SampleGetTransactionData.txHash6,
    //     coin: Coin.firo,
    //   )).thenAnswer((_) async => SampleGetTransactionData.txData6);
    //   when(cachedClient.getTransaction(
    //     txHash: SampleGetTransactionData.txHash7,
    //     coin: Coin.firo,
    //   )).thenAnswer((_) async => SampleGetTransactionData.txData7);
    //   when(cachedClient.getTransaction(
    //     txHash: SampleGetTransactionData.txHash8,
    //     coin: Coin.firo,
    //   )).thenAnswer((_) async => SampleGetTransactionData.txData8);
    //   when(cachedClient.getTransaction(
    //     txHash: SampleGetTransactionData.txHash9,
    //     coin: Coin.firo,
    //   )).thenAnswer((_) async => SampleGetTransactionData.txData9);
    //   when(cachedClient.getTransaction(
    //     txHash: SampleGetTransactionData.txHash10,
    //     coin: Coin.firo,
    //   )).thenAnswer((_) async => SampleGetTransactionData.txData10);
    //   when(cachedClient.getTransaction(
    //     txHash: SampleGetTransactionData.txHash11,
    //     coin: Coin.firo,
    //   )).thenAnswer((_) async => SampleGetTransactionData.txData11);
    //   when(cachedClient.getTransaction(
    //     txHash: SampleGetTransactionData.txHash12,
    //     coin: Coin.firo,
    //   )).thenAnswer((_) async => SampleGetTransactionData.txData12);
    //
    //   final firo = FiroWallet(
    //     walletName: testWalletName,
    //     walletId: "${testWalletId}autoMint",
    //     coin: Coin.firo,
    //     client: client,
    //     cachedClient: cachedClient,
    //     secureStore: secureStore,
    //
    //
    //     tracker: MockTransactionNotificationTracker(),
    //   );
    //
    //   // pre grab derivations in order to set up mock calls needed later on
    //   await firo.fillAddresses(TEST_MNEMONIC);
    //   final wallet = await Hive.openBox<dynamic>("${testWalletId}autoMint");
    //   await wallet.put(
    //       'receivingAddresses', RefreshTestParams.receivingAddresses);
    //   await wallet.put('changeAddresses', RefreshTestParams.changeAddresses);
    //
    //   final rcv = await secureStore.read(
    //       key: "${testWalletId}autoMint_receiveDerivations");
    //   final chg = await secureStore.read(
    //       key: "${testWalletId}autoMint_changeDerivations");
    //   final receiveDerivations =
    //       Map<String, dynamic>.from(jsonDecode(rcv as String) as Map);
    //   final changeDerivations =
    //       Map<String, dynamic>.from(jsonDecode(chg as String) as Map);
    //
    //   for (int i = 0; i < receiveDerivations.length; i++) {
    //     final receiveHash = AddressUtils.convertToScriptHash(
    //         receiveDerivations["$i"]!["address"] as String, firoNetwork);
    //     final changeHash = AddressUtils.convertToScriptHash(
    //         changeDerivations["$i"]!["address"] as String, firoNetwork);
    //     List<Map<String, dynamic>> data;
    //     switch (receiveHash) {
    //       case SampleGetHistoryData.scripthash0:
    //         data = SampleGetHistoryData.data0;
    //         break;
    //       case SampleGetHistoryData.scripthash1:
    //         data = SampleGetHistoryData.data1;
    //         break;
    //       case SampleGetHistoryData.scripthash2:
    //         data = SampleGetHistoryData.data2;
    //         break;
    //       case SampleGetHistoryData.scripthash3:
    //         data = SampleGetHistoryData.data3;
    //         break;
    //       default:
    //         data = [];
    //     }
    //     when(client.getHistory(scripthash: receiveHash))
    //         .thenAnswer((_) async => data);
    //
    //     switch (changeHash) {
    //       case SampleGetHistoryData.scripthash0:
    //         data = SampleGetHistoryData.data0;
    //         break;
    //       case SampleGetHistoryData.scripthash1:
    //         data = SampleGetHistoryData.data1;
    //         break;
    //       case SampleGetHistoryData.scripthash2:
    //         data = SampleGetHistoryData.data2;
    //         break;
    //       case SampleGetHistoryData.scripthash3:
    //         data = SampleGetHistoryData.data3;
    //         break;
    //       default:
    //         data = [];
    //     }
    //
    //     when(client.getHistory(scripthash: changeHash))
    //         .thenAnswer((_) async => data);
    //   }
    //
    //   when(client.getUTXOs(scripthash: GetUtxoSampleData.scriptHash0))
    //       .thenAnswer((_) async => GetUtxoSampleData.utxos0);
    //   when(client.getUTXOs(scripthash: GetUtxoSampleData.scriptHash1))
    //       .thenAnswer((_) async => GetUtxoSampleData.utxos1);
    //
    //   await firo.recoverFromMnemonic(
    //       mnemonic: TEST_MNEMONIC,
    //       maxUnusedAddressGap: 20,
    //       height: 0,
    //       maxNumberOfIndexesToCheck: 1000);
    //
    //   firo.timer = Timer(const Duration(minutes: 3), () {});
    //
    //   await firo.refresh();
    //
    //   bool flag = false;
    //   try {
    //     await firo.autoMint();
    //   } catch (_) {
    //     flag = true;
    //   }
    //   expect(flag, false);
    //
    //   await firo.exit();
    // }, timeout: const Timeout(Duration(minutes: 3)));

    test("exit", () async {
      final firo = FiroWallet(
        walletId: "${testWalletId}exit",
        walletName: testWalletName,
        coin: Coin.firo,
        client: MockElectrumX(),
        cachedClient: MockCachedElectrumX(),
        secureStore: FakeSecureStorage(),
        tracker: MockTransactionNotificationTracker(),
      );

      firo.timer = Timer(const Duration(seconds: 2), () {});

      bool flag = false;
      try {
        await firo.exit();
      } catch (_) {
        flag = true;
      }
      expect(flag, false);
      expect(firo.timer, null);
    });

    tearDown(() async {
      await tearDownTestHive();
    });
  });

  group("simple getters", () {
    group("fees", () {
      test("get fees succeeds", () async {
        final client = MockElectrumX();

        when(client.estimateFee(blocks: 1))
            .thenAnswer((_) async => Decimal.parse("0.00001000"));
        when(client.estimateFee(blocks: 5))
            .thenAnswer((_) async => Decimal.parse("0.00001000"));
        when(client.estimateFee(blocks: 20))
            .thenAnswer((_) async => Decimal.parse("0.00001000"));

        final firo = FiroWallet(
          walletId: "some id",
          walletName: "some name",
          coin: Coin.firo,
          client: client,
          cachedClient: MockCachedElectrumX(),
          secureStore: FakeSecureStorage(),
          tracker: MockTransactionNotificationTracker(),
        );

        expect((await firo.fees).fast, 1000);
        expect((await firo.fees).medium, 1000);
        expect((await firo.fees).slow, 1000);
      });

      test("get fees throws", () {
        final client = MockElectrumX();

        when(client.estimateFee(blocks: 1))
            .thenThrow(Exception("Some exception"));

        final firo = FiroWallet(
          walletId: "some id",
          walletName: "some name",
          coin: Coin.firo,
          client: client,
          cachedClient: MockCachedElectrumX(),
          secureStore: FakeSecureStorage(),
          tracker: MockTransactionNotificationTracker(),
        );

        expect(firo.fees, throwsA(isA<Exception>()));
      });
    });

    group("coin", () {
      test("get main net coinTicker", () {
        final firo = FiroWallet(
          walletId: "some id",
          walletName: "some name",
          coin: Coin.firo,
          client: MockElectrumX(),
          cachedClient: MockCachedElectrumX(),
          secureStore: FakeSecureStorage(),
          tracker: MockTransactionNotificationTracker(),
        );

        expect(firo.coin, Coin.firo);
      });

      test("get test net coin", () {
        final firo = FiroWallet(
          walletId: "some id",
          walletName: "some name",
          coin: Coin.firoTestNet,
          client: MockElectrumX(),
          cachedClient: MockCachedElectrumX(),
          secureStore: FakeSecureStorage(),
          tracker: MockTransactionNotificationTracker(),
        );

        expect(firo.coin, Coin.firoTestNet);
      });
    });

    group("mnemonic", () {
      test("fetch and convert properly stored mnemonic to list of words",
          () async {
        final store = FakeSecureStorage();
        await store.write(
            key: "some id_mnemonic",
            value: "some test mnemonic string of words");

        final firo = FiroWallet(
          walletName: 'unit test',
          walletId: 'some id',
          coin: Coin.firoTestNet,
          client: MockElectrumX(),
          cachedClient: MockCachedElectrumX(),
          secureStore: store,
          tracker: MockTransactionNotificationTracker(),
        );
        final List<String> result = await firo.mnemonic;

        expect(result, [
          "some",
          "test",
          "mnemonic",
          "string",
          "of",
          "words",
        ]);
      });

      test("attempt fetch and convert non existent mnemonic to list of words",
          () async {
        final store = FakeSecureStorage();
        await store.write(
            key: "some id_mnemonic",
            value: "some test mnemonic string of words");

        final firo = FiroWallet(
          walletName: 'unit test',
          walletId: 'some other id',
          coin: Coin.firoTestNet,
          client: MockElectrumX(),
          cachedClient: MockCachedElectrumX(),
          secureStore: store,
          tracker: MockTransactionNotificationTracker(),
        );
        final mnemonic = await firo.mnemonic;
        expect(mnemonic, <String>[]);
      });
    });

    test("walletName", () {
      final firo = FiroWallet(
        walletId: "some id",
        walletName: "some name",
        coin: Coin.firo,
        client: MockElectrumX(),
        cachedClient: MockCachedElectrumX(),
        secureStore: FakeSecureStorage(),
        tracker: MockTransactionNotificationTracker(),
      );

      expect(firo.walletName, "some name");

      firo.walletName = "new name";
      expect(firo.walletName, "new name");
    });

    test("walletId", () {
      final firo = FiroWallet(
        walletId: "some id",
        walletName: "some name",
        coin: Coin.firo,
        client: MockElectrumX(),
        cachedClient: MockCachedElectrumX(),
        secureStore: FakeSecureStorage(),
        tracker: MockTransactionNotificationTracker(),
      );

      expect(firo.walletId, "some id");
    });
  });
}

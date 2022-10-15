import 'dart:async';
import 'dart:core';
import 'dart:core' as core;
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:hive_test/hive_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:cw_core/monero_amount_format.dart';
import 'package:cw_core/node.dart';
import 'package:cw_core/pending_transaction.dart';
import 'package:cw_core/unspent_coins_info.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/wallet_credentials.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/wallet_service.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:cw_monero/api/wallet.dart';
import 'package:cw_monero/api/wallet_manager.dart' as monero_wallet_manager;
import 'package:cw_monero/pending_monero_transaction.dart';
import 'package:cw_monero/monero_wallet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_libmonero/core/key_service.dart';
import 'package:flutter_libmonero/core/wallet_creation_service.dart';
import 'package:flutter_libmonero/view_model/send/output.dart';
import 'package:flutter_libmonero/monero/monero.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stackwallet/utilities/flutter_secure_storage_interface.dart';

import 'package:stackwallet/services/wallets.dart';

import 'dart:developer' as developer;

// TODO trim down to the minimum imports above

import 'monero_wallet_test_data.dart';

//FlutterSecureStorage? storage;
FakeSecureStorage? storage;
WalletService? walletService;
SharedPreferences? prefs;
KeyService? keysStorage;
MoneroWalletBase? walletBase;
late WalletCreationService _walletCreationService;
dynamic _walletInfoSource;
Wallets? walletsService;

String path = '';

String name = '';
int nettype = 0;
WalletType type = WalletType.monero;

@GenerateMocks([])
void main() async {
  storage = FakeSecureStorage();
  prefs = await SharedPreferences.getInstance();
  keysStorage = KeyService(storage!);
  WalletInfo walletInfo = WalletInfo.external(
      id: '',
      name: '',
      type: type,
      isRecovery: false,
      restoreHeight: 0,
      date: DateTime.now(),
      path: '',
      address: '',
      dirPath: '',
      nettype: 0);
  late WalletCredentials credentials;

  WidgetsFlutterBinding.ensureInitialized();
  Directory appDir = (await getApplicationDocumentsDirectory());
  if (Platform.isIOS) {
    appDir = (await getLibraryDirectory());
  }
  await Hive.close();
  Hive.init(appDir.path);
  Hive.registerAdapter(NodeAdapter());
  Hive.registerAdapter(WalletInfoAdapter());
  Hive.registerAdapter(WalletTypeAdapter());
  Hive.registerAdapter(UnspentCoinsInfoAdapter());

  monero.onStartup();
  _walletInfoSource = await Hive.openBox<WalletInfo>(WalletInfo.boxName);
  walletService = monero.createMoneroWalletService(_walletInfoSource);

  group("Stagenet tests", () {
    setUp(() async {
      try {
        name =
            'namee${Random().nextInt(10000000)}'; // TODO set static name and handle mocked storage etc to not pollute wallet files
        type = WalletType.moneroStageNet;
        nettype = 2;
        final dirPath = await pathForWalletDir(name: name, type: type);
        final path = await pathForWallet(name: name, type: type);
        credentials =
            // //     creating a new wallet
            // monero.createMoneroNewWalletCredentials(
            //     name: name, language: "English");
            // restoring a previous wallet
            monero.createMoneroRestoreWalletFromSeedCredentials(
                name: name, height: 1199000, mnemonic: testMnemonic);

        walletInfo = WalletInfo.external(
            id: WalletBase.idFor(name, type),
            name: name,
            type: type,
            isRecovery: false,
            restoreHeight: credentials.height ?? 0,
            date: DateTime.now(),
            path: path,
            address: "",
            dirPath: dirPath,
            nettype: nettype);
        credentials.walletInfo = walletInfo;

        _walletCreationService = WalletCreationService(
          secureStorage: storage,
          sharedPreferences: prefs,
          walletService: walletService,
          keyService: keysStorage,
        );
        _walletCreationService.changeWalletType();
      } catch (e, s) {
        print(e);
        print(s);
      }
    });

    test("Test stagenet address generation from seed", () async {
      final wallet = await
          // _walletCreationService.create(credentials);
          _walletCreationService.restoreFromSeed(credentials, nettype);
      walletInfo.address = wallet.walletAddresses.address;
      //print(walletInfo.address);

      await _walletInfoSource.add(walletInfo);
      walletBase?.close();
      walletBase = wallet as MoneroWalletBase;
      //print("${walletBase?.seed}");

      expect(walletInfo.address, stagenetTestData[0][0]);
      expect(await walletBase!.getTransactionAddress(0, 0),
          stagenetTestData[0][0]);
      expect(await walletBase!.getTransactionAddress(0, 1),
          stagenetTestData[0][1]);
      expect(await walletBase!.getTransactionAddress(0, 2),
          stagenetTestData[0][2]);
      expect(await walletBase!.getTransactionAddress(1, 0),
          stagenetTestData[1][0]);
      expect(await walletBase!.getTransactionAddress(1, 1),
          stagenetTestData[1][1]);
      expect(await walletBase!.getTransactionAddress(1, 2),
          stagenetTestData[1][2]);
    });
  });

  group("Mainnet tests", () {
    setUp(() async {
      try {
        // if (name?.isEmpty ?? true) {
        // name = await generateName();
        // }
        name = "namee${Random().nextInt(10000000)}";
        type = WalletType.monero;
        nettype = 0;
        final dirPath = await pathForWalletDir(name: name, type: type);
        final path = await pathForWallet(name: name, type: type);
        credentials =
            // //     creating a new wallet
            // monero.createMoneroNewWalletCredentials(
            //     name: name, language: "English");
            // restoring a previous wallet
            monero.createMoneroRestoreWalletFromSeedCredentials(
                name: name, height: 2580000, mnemonic: testMnemonic);

        walletInfo = WalletInfo.external(
            id: WalletBase.idFor(name, type),
            name: name,
            type: type,
            isRecovery: false,
            restoreHeight: credentials.height ?? 0,
            date: DateTime.now(),
            path: path,
            address: "",
            dirPath: dirPath,
            nettype: nettype);
        credentials.walletInfo = walletInfo;

        _walletCreationService = WalletCreationService(
          secureStorage: storage,
          sharedPreferences: prefs,
          walletService: walletService,
          keyService: keysStorage,
        );
        _walletCreationService.changeWalletType();
      } catch (e, s) {
        print(e);
        print(s);
      }
    });

    test("Test mainnet address generation from seed", () async {
      final wallet = await
          // _walletCreationService.create(credentials);
          _walletCreationService.restoreFromSeed(credentials, nettype);
      walletInfo.address = wallet.walletAddresses.address;
      //print(walletInfo.address);

      await _walletInfoSource.add(walletInfo);
      walletBase?.close();
      walletBase = wallet as MoneroWalletBase;
      //print("${walletBase?.seed}");

      // print(walletBase);
      // loggerPrint(walletBase.toString());
      // loggerPrint("name: ${walletBase!.name}  seed: ${walletBase!.seed} id: "
      //     "${walletBase!.id} walletinfo: ${toStringForinfo(walletBase!.walletInfo)} type: ${walletBase!.type} balance: "
      //     "${walletBase!.balance.entries.first.value.available} currency: ${walletBase!.currency}");

      expect(walletInfo.address, mainnetTestData[0][0]);
      expect(
          await walletBase!.getTransactionAddress(0, 0), mainnetTestData[0][0]);
      expect(
          await walletBase!.getTransactionAddress(0, 1), mainnetTestData[0][1]);
      expect(
          await walletBase!.getTransactionAddress(0, 2), mainnetTestData[0][2]);
      expect(
          await walletBase!.getTransactionAddress(1, 0), mainnetTestData[1][0]);
      expect(
          await walletBase!.getTransactionAddress(1, 1), mainnetTestData[1][1]);
      expect(
          await walletBase!.getTransactionAddress(1, 2), mainnetTestData[1][2]);
    });
  });
  /*
  group("Mainnet node tests", () {
    test("Test mainnet node connection", () async {
      await walletBase?.connectToNode(
          node: Node(
              uri: "monero-stagenet.stackwallet.com:38081",
              type: WalletType.moneroStageNet));
      await walletBase!.rescan(
          height:
              credentials.height); // Probably shouldn't be rescanning from 0...
      await walletBase!.getNodeHeight();
      int height = await walletBase!.getNodeHeight();
      print('height: $height');
      bool connected = await walletBase!.isConnected();
      print('connected: $connected');
      //expect...
    });
  });
   */

  // TODO test deletion of wallets ... and delete them
}

Future<String> pathForWalletDir(
    {required String name, required WalletType type}) async {
  Directory root = (await getApplicationDocumentsDirectory());
  if (Platform.isIOS) {
    root = (await getLibraryDirectory());
  }
  final prefix = walletTypeToString(type).toLowerCase();
  final walletsDir = Directory('${root.path}/wallets');
  final walletDire = Directory('${walletsDir.path}/$prefix/$name');

  if (!walletDire.existsSync()) {
    walletDire.createSync(recursive: true);
  }

  return walletDire.path;
}

Future<String> pathForWallet(
        {required String name, required WalletType type}) async =>
    await pathForWalletDir(name: name, type: type)
        .then((path) => path + '/$name');

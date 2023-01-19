import 'dart:core';
import 'dart:io';
import 'dart:math';

import 'package:cw_core/node.dart';
import 'package:cw_core/unspent_coins_info.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/wallet_credentials.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/wallet_service.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:cw_monero/monero_wallet.dart';
import 'package:flutter_libmonero/core/key_service.dart';
import 'package:flutter_libmonero/core/wallet_creation_service.dart';
import 'package:flutter_libmonero/monero/monero.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:hive_test/hive_test.dart';
import 'package:mockito/annotations.dart';
import 'package:path_provider/path_provider.dart';
import 'package:stackwallet/services/wallets.dart';
import 'package:stackwallet/utilities/flutter_secure_storage_interface.dart';

import 'monero_wallet_test_data.dart';

FakeSecureStorage? storage;
WalletService? walletService;
KeyService? keysStorage;
MoneroWalletBase? walletBase;
late WalletCreationService _walletCreationService;
dynamic _walletInfoSource;
Wallets? walletsService;

String path = '';

String name = 'namee${Random().nextInt(10000000)}';
int nettype = 0;
WalletType type = WalletType.monero;

@GenerateMocks([])
void main() async {
  storage = FakeSecureStorage();
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
      dirPath: '');
  late WalletCredentials credentials;

  monero.onStartup();

  bool hiveAdaptersRegistered = false;

  group("Mainnet tests", () {
    setUp(() async {
      await setUpTestHive();
      if (!hiveAdaptersRegistered) {
        hiveAdaptersRegistered = true;

        Hive.registerAdapter(NodeAdapter());
        Hive.registerAdapter(WalletInfoAdapter());
        Hive.registerAdapter(WalletTypeAdapter());
        Hive.registerAdapter(UnspentCoinsInfoAdapter());

        final wallets = await Hive.openBox<dynamic>('wallets');
        await wallets.put('currentWalletName', name);

        _walletInfoSource = await Hive.openBox<WalletInfo>(WalletInfo.boxName);
        walletService = monero
            .createMoneroWalletService(_walletInfoSource as Box<WalletInfo>);
      }

      try {
        // if (name?.isEmpty ?? true) {
        // name = await generateName();
        // }
        final dirPath = await pathForWalletDir(name: name, type: type);
        path = await pathForWallet(name: name, type: type);
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
            dirPath: dirPath);
        credentials.walletInfo = walletInfo;

        _walletCreationService = WalletCreationService(
          secureStorage: storage,
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
          _walletCreationService.restoreFromSeed(credentials);
      walletInfo.address = wallet.walletAddresses.address;
      //print(walletInfo.address);

      await _walletInfoSource.add(walletInfo);
      walletBase?.close();
      walletBase = wallet as MoneroWalletBase;
      //print("${walletBase?.seed}");

      expect(await walletBase!.validateAddress(walletInfo.address ?? ''), true);

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

      expect(await walletBase!.validateAddress(''), false);
      expect(
          await walletBase!.validateAddress(
              '4AeRgkWZsMJhAWKMeCZ3h4ZSPnAcW5VBtRFyLd6gBEf6GgJU2FHXDA6i1DnQTd6h8R3VU5AkbGcWSNhtSwNNPgaD48gp4nn'),
          true);
      expect(
          await walletBase!.validateAddress(
              '4asdfkWZsMJhAWKMeCZ3h4ZSPnAcW5VBtRFyLd6gBEf6GgJU2FHXDA6i1DnQTd6h8R3VU5AkbGcWSNhtSwNNPgaD48gpjkl'),
          false);
      expect(
          await walletBase!.validateAddress(
              '8AeRgkWZsMJhAWKMeCZ3h4ZSPnAcW5VBtRFyLd6gBEf6GgJU2FHXDA6i1DnQTd6h8R3VU5AkbGcWSNhtSwNNPgaD48gp4nn'),
          false);
      expect(
          await walletBase!.validateAddress(
              '84kYPuZ1eaVKGQhf26QPNWbSLQG16BywXdLYYShVrPNMLAUAWce5vcpRc78FxwRphrG6Cda7faCKdUMr8fUCH3peHPenvHy'),
          true);
      expect(
          await walletBase!.validateAddress(
              '8asdfuZ1eaVKGQhf26QPNWbSLQG16BywXdLYYShVrPNMLAUAWce5vcpRc78FxwRphrG6Cda7faCKdUMr8fUCH3peHPenjkl'),
          false);
      expect(
          await walletBase!.validateAddress(
              '44kYPuZ1eaVKGQhf26QPNWbSLQG16BywXdLYYShVrPNMLAUAWce5vcpRc78FxwRphrG6Cda7faCKdUMr8fUCH3peHPenvHy'),
          false);
    });
  });
  /*
  // Not needed; only folder created, wallet files not saved yet.  TODO test saving and deleting wallet files and make sure to clean up leftover folder afterwards
  group("Mainnet wallet deletion test", () {
    test("Test mainnet wallet existence", () {
      expect(monero_wallet_manager.isWalletExistSync(path: path), true);
    });

    test("Test mainnet wallet deletion", () {
      // Remove wallet from wallet service
      walletService?.remove(name);
      walletsService?.removeWallet(walletId: name);
      expect(monero_wallet_manager.isWalletExistSync(path: path), false);
    });
  });

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

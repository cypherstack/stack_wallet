import 'dart:core';
// import 'dart:io';
// import 'dart:math';
//
// TODO: move these tests to libmonero
// TODO: use temp dir for wallets testing and not production location
//
// import 'package:cw_core/node.dart';
// import 'package:cw_core/unspent_coins_info.dart';
// import 'package:cw_core/wallet_base.dart';
// import 'package:cw_core/wallet_credentials.dart';
// import 'package:cw_core/wallet_info.dart';
// import 'package:cw_core/wallet_service.dart';
// import 'package:cw_core/wallet_type.dart';
// import 'package:cw_wownero/wownero_wallet.dart';
// import 'package:flutter_libmonero/core/key_service.dart';
// import 'package:flutter_libmonero/core/wallet_creation_service.dart';
// import 'package:flutter_libmonero/wownero/wownero.dart';
// import 'package:flutter_test/flutter_test.dart';
// import 'package:hive_ce/hive.dart';
// import 'package:hive_test/hive_test.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:stackwallet/utilities/flutter_secure_storage_interface.dart';
//
// import 'wownero_wallet_test_data.dart';
//
// FakeSecureStorage? storage;
// WalletService? walletService;
// KeyService? keysStorage;
// WowneroWalletBase? walletBase;
// late WalletCreationService _walletCreationService;
// dynamic _walletInfoSource;
//
// String path = '';
//
// String name = '';
// int nettype = 0;
// WalletType type = WalletType.wownero;

void main() async {
  // storage = FakeSecureStorage();
  // keysStorage = KeyService(storage!);
  // WalletInfo walletInfo = WalletInfo.external(
  //     id: '',
  //     name: '',
  //     type: type,
  //     isRecovery: false,
  //     restoreHeight: 0,
  //     date: DateTime.now(),
  //     path: '',
  //     address: '',
  //     dirPath: '');
  // late WalletCredentials credentials;
  //
  // wownero.onStartup();
  //
  // bool hiveAdaptersRegistered = false;
  //
  // group("Wownero 14 word seed generation", () {
  //   setUp(() async {
  //     await setUpTestHive();
  //     if (!hiveAdaptersRegistered) {
  //       hiveAdaptersRegistered = true;
  //
  //       Hive.registerAdapter(NodeAdapter());
  //       Hive.registerAdapter(WalletInfoAdapter());
  //       Hive.registerAdapter(WalletTypeAdapter());
  //       Hive.registerAdapter(UnspentCoinsInfoAdapter());
  //
  //       final wallets = await Hive.openBox<dynamic>('wallets');
  //       await wallets.put('currentWalletName', name);
  //
  //       _walletInfoSource = await Hive.openBox<WalletInfo>(WalletInfo.boxName);
  //       walletService = wownero
  //           .createWowneroWalletService(_walletInfoSource as Box<WalletInfo>);
  //     }
  //
  //     bool hasThrown = false;
  //     try {
  //       name = 'namee${Random().nextInt(10000000)}';
  //       final dirPath = await pathForWalletDir(name: name, type: type);
  //       path = await pathForWallet(name: name, type: type);
  //       credentials = wownero.createWowneroNewWalletCredentials(
  //           name: name,
  //           language: "English",
  //           seedWordsLength: 14); // TODO catch failure
  //
  //       walletInfo = WalletInfo.external(
  //           id: WalletBase.idFor(name, type),
  //           name: name,
  //           type: type,
  //           isRecovery: false,
  //           restoreHeight: credentials.height ?? 0,
  //           date: DateTime.now(),
  //           path: path,
  //           address: "",
  //           dirPath: dirPath);
  //       credentials.walletInfo = walletInfo;
  //
  //       _walletCreationService = WalletCreationService(
  //         secureStorage: storage,
  //         walletService: walletService,
  //         keyService: keysStorage,
  //       );
  //       _walletCreationService.changeWalletType();
  //     } catch (e, s) {
  //       print(e);
  //       print(s);
  //       hasThrown = true;
  //     }
  //     expect(hasThrown, false);
  //   });
  //
  //   test("Wownero 14 word seed address generation", () async {
  //     final wallet = await _walletCreationService.create(credentials);
  //     // TODO validate mnemonic
  //     walletInfo.address = wallet.walletAddresses.address;
  //
  //     bool hasThrown = false;
  //     try {
  //       await _walletInfoSource.add(walletInfo);
  //       walletBase?.close();
  //       walletBase = wallet as WowneroWalletBase;
  //
  //       expect(
  //           await walletBase!
  //               .validateAddress(wallet.walletAddresses.address ?? ''),
  //           true);
  //     } catch (_) {
  //       hasThrown = true;
  //     }
  //     expect(hasThrown, false);
  //
  //     // Address validation
  //     expect(walletBase!.validateAddress(''), false);
  //     expect(
  //         walletBase!.validateAddress(
  //             'Wo3jmHvTMLwE6h29fpgcb8PbJSpaKuqM7XTXVfiiu8bLCZsJvrQCbQSJR48Vo3BWNQKsMsXZ4VixndXTH25QtorC27NCjmsEi'),
  //         true);
  //     expect(
  //         walletBase!.validateAddress(
  //             'WasdfHvTMLwE6h29fpgcb8PbJSpaKuqM7XTXVfiiu8bLCZsJvrQCbQSJR48Vo3BWNQKsMsXZ4VixndXTH25QtorC27NCjmjkl'),
  //         false);
  //
  //     walletBase?.close();
  //     walletBase = wallet as WowneroWalletBase;
  //   });
  //
  //   // TODO delete left over wallet file with name: name
  // });
  //
  // group("Wownero 14 word seed restoration", () {
  //   setUp(() async {
  //     bool hasThrown = false;
  //     try {
  //       name = 'namee${Random().nextInt(10000000)}';
  //       final dirPath = await pathForWalletDir(name: name, type: type);
  //       path = await pathForWallet(name: name, type: type);
  //       credentials = wownero.createWowneroRestoreWalletFromSeedCredentials(
  //           name: name,
  //           height: 465760,
  //           mnemonic: testMnemonic14); // TODO catch failure
  //
  //       walletInfo = WalletInfo.external(
  //           id: WalletBase.idFor(name, type),
  //           name: name,
  //           type: type,
  //           isRecovery: false,
  //           restoreHeight: credentials.height ?? 0,
  //           date: DateTime.now(),
  //           path: path,
  //           address: "",
  //           dirPath: dirPath);
  //       credentials.walletInfo = walletInfo;
  //
  //       _walletCreationService = WalletCreationService(
  //         secureStorage: storage,
  //         walletService: walletService,
  //         keyService: keysStorage,
  //       );
  //       _walletCreationService.changeWalletType();
  //     } catch (e, s) {
  //       print(e);
  //       print(s);
  //       hasThrown = true;
  //     }
  //     expect(hasThrown, false);
  //   });
  //
  //   test("Wownero 14 word seed address generation", () async {
  //     final wallet = await _walletCreationService.restoreFromSeed(credentials);
  //     walletInfo.address = wallet.walletAddresses.address;
  //
  //     bool hasThrown = false;
  //     try {
  //       await _walletInfoSource.add(walletInfo);
  //       walletBase?.close();
  //       walletBase = wallet as WowneroWalletBase;
  //
  //       expect(walletInfo.address, mainnetTestData14[0][0]);
  //       expect(
  //           walletBase!.getTransactionAddress(0, 0), mainnetTestData14[0][0]);
  //       expect(
  //           walletBase!.getTransactionAddress(0, 1), mainnetTestData14[0][1]);
  //       expect(
  //           walletBase!.getTransactionAddress(0, 2), mainnetTestData14[0][2]);
  //       expect(
  //           walletBase!.getTransactionAddress(1, 0), mainnetTestData14[1][0]);
  //       expect(
  //           walletBase!.getTransactionAddress(1, 1), mainnetTestData14[1][1]);
  //       expect(
  //           walletBase!.getTransactionAddress(1, 2), mainnetTestData14[1][2]);
  //     } catch (_) {
  //       hasThrown = true;
  //     }
  //     expect(hasThrown, false);
  //
  //     walletBase?.close();
  //     walletBase = wallet as WowneroWalletBase;
  //   });
  //
  //   // TODO delete left over wallet file with name: name
  // });
  //
  // group("Wownero 25 word seed generation", () {
  //   setUp(() async {
  //     bool hasThrown = false;
  //     try {
  //       name = 'namee${Random().nextInt(10000000)}';
  //       final dirPath = await pathForWalletDir(name: name, type: type);
  //       path = await pathForWallet(name: name, type: type);
  //       credentials = wownero.createWowneroNewWalletCredentials(
  //           name: name,
  //           language: "English",
  //           seedWordsLength: 25); // TODO catch failure
  //
  //       walletInfo = WalletInfo.external(
  //           id: WalletBase.idFor(name, type),
  //           name: name,
  //           type: type,
  //           isRecovery: false,
  //           restoreHeight: credentials.height ?? 0,
  //           date: DateTime.now(),
  //           path: path,
  //           address: "",
  //           dirPath: dirPath);
  //       credentials.walletInfo = walletInfo;
  //
  //       _walletCreationService = WalletCreationService(
  //         secureStorage: storage,
  //         walletService: walletService,
  //         keyService: keysStorage,
  //       );
  //       _walletCreationService.changeWalletType();
  //     } catch (e, s) {
  //       print(e);
  //       print(s);
  //       hasThrown = true;
  //     }
  //     expect(hasThrown, false);
  //   });
  //
  //   test("Wownero 25 word seed address generation", () async {
  //     final wallet = await _walletCreationService.create(credentials);
  //     // TODO validate mnemonic
  //     walletInfo.address = wallet.walletAddresses.address;
  //
  //     bool hasThrown = false;
  //     try {
  //       await _walletInfoSource.add(walletInfo);
  //       walletBase?.close();
  //       walletBase = wallet as WowneroWalletBase;
  //
  //       // TODO validate
  //       //expect(walletInfo.address, mainnetTestData14[0][0]);
  //     } catch (_) {
  //       hasThrown = true;
  //     }
  //     expect(hasThrown, false);
  //
  //     walletBase?.close();
  //     walletBase = wallet as WowneroWalletBase;
  //   });
  //
  //   // TODO delete left over wallet file with name: name
  // });
  //
  // group("Wownero 25 word seed restoration", () {
  //   setUp(() async {
  //     bool hasThrown = false;
  //     try {
  //       name = 'namee${Random().nextInt(10000000)}';
  //       final dirPath = await pathForWalletDir(name: name, type: type);
  //       path = await pathForWallet(name: name, type: type);
  //       credentials = wownero.createWowneroRestoreWalletFromSeedCredentials(
  //           name: name,
  //           height: 465760,
  //           mnemonic: testMnemonic25); // TODO catch failure
  //
  //       walletInfo = WalletInfo.external(
  //           id: WalletBase.idFor(name, type),
  //           name: name,
  //           type: type,
  //           isRecovery: false,
  //           restoreHeight: credentials.height ?? 0,
  //           date: DateTime.now(),
  //           path: path,
  //           address: "",
  //           dirPath: dirPath);
  //       credentials.walletInfo = walletInfo;
  //
  //       _walletCreationService = WalletCreationService(
  //         secureStorage: storage,
  //         walletService: walletService,
  //         keyService: keysStorage,
  //       );
  //       _walletCreationService.changeWalletType();
  //     } catch (e, s) {
  //       print(e);
  //       print(s);
  //       hasThrown = true;
  //     }
  //     expect(hasThrown, false);
  //   });
  //
  //   test("Wownero 25 word seed address generation", () async {
  //     final wallet = await _walletCreationService.restoreFromSeed(credentials);
  //     walletInfo.address = wallet.walletAddresses.address;
  //
  //     bool hasThrown = false;
  //     try {
  //       await _walletInfoSource.add(walletInfo);
  //       walletBase?.close();
  //       walletBase = wallet as WowneroWalletBase;
  //
  //       expect(walletInfo.address, mainnetTestData25[0][0]);
  //     } catch (_) {
  //       hasThrown = true;
  //     }
  //     expect(hasThrown, false);
  //
  //     walletBase?.close();
  //     walletBase = wallet as WowneroWalletBase;
  //   });
  //
  //   // TODO delete left over wallet file with name: name
  // });
}

// Future<String> pathForWalletDir(
//     {required String name, required WalletType type}) async {
//   Directory root = (await getApplicationDocumentsDirectory());
//   if (Platform.isIOS) {
//     root = (await getLibraryDirectory());
//   }
//   final prefix = walletTypeToString(type).toLowerCase();
//   final walletsDir = Directory('${root.path}/wallets');
//   final walletDire = Directory('${walletsDir.path}/$prefix/$name');
//
//   if (!walletDire.existsSync()) {
//     walletDire.createSync(recursive: true);
//   }
//
//   return walletDire.path;
// }
//
// Future<String> pathForWallet(
//         {required String name, required WalletType type}) async =>
//     await pathForWalletDir(name: name, type: type)
//         .then((path) => '$path/$name');

import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
// Test-only substitution of the existing wakelock plugin's platform layer.
// ignore: depend_on_referenced_packages
import 'package:wakelock_plus_platform_interface/wakelock_plus_platform_interface.dart';

import 'package:stackwallet/db/drift/shared_db/shared_database.dart';
import 'package:stackwallet/db/hive/db.dart';
import 'package:stackwallet/db/isar/main_db.dart';
import 'package:stackwallet/models/exchange/response_objects/trade.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/address.dart';
import 'package:stackwallet/models/isar/models/transaction_note.dart';
import 'package:stackwallet/models/node_model.dart';
import 'package:stackwallet/models/stack_restoring_ui_state.dart';
import 'package:stackwallet/models/trade_wallet_lookup.dart';
import 'package:stackwallet/pages/settings_views/global_settings_view/stack_backup_views/helpers/restore_create_backup.dart';
import 'package:stackwallet/services/node_service.dart';
import 'package:stackwallet/services/shopinbit/shopinbit_service.dart';
import 'package:stackwallet/services/wallets.dart';
import 'package:stackwallet/utilities/prefs.dart';
import 'package:stackwallet/utilities/stack_file_system.dart';
import 'package:stackwallet/wallets/isar/models/wallet_info.dart';
import 'package:stackwallet/wallets/wallet/impl/xelis_wallet.dart';
import 'package:stackwallet/wallets/wallet/wallet.dart';
import 'package:stackwallet/wl_gen/interfaces/lib_xelis_interface.dart';

import '../support/isar_test_utils.dart';
import 'support/xelis_test_fakes.dart';

class UnusedShopService extends Fake implements ShopInBitService {}

class TestWakelock extends WakelockPlusPlatformInterface {
  @override
  Future<void> toggle({required bool enable}) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'encrypted SWB restores native Xelis with duplicate ID and notes',
    () async {
      final root = await Directory.systemTemp.createTemp('stack_xelis_swb_');
      StackFileSystem.setDesktopOverrideDir(root.path);
      final opened = <Wallet>[];
      addTearDown(() async {
        try {
          for (final wallet in opened.reversed) {
            await wallet.exit();
          }
          await SharedDrift.get().close();
        } finally {
          await MainDB.instance.isar.close();
          await DB.instance.hive.close();
          await root.delete(recursive: true);
        }
      });
      const paths = MethodChannel('plugins.flutter.io/path_provider');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(paths, (call) async {
            if (call.method == 'getTemporaryDirectory') return root.path;
            throw StateError('Unexpected path request: ${call.method}');
          });
      addTearDown(
        () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(paths, null),
      );
      // The host wake-lock plugin has no role in this headless backup test.
      final previousWakelock = WakelockPlusPlatformInterface.instance;
      WakelockPlusPlatformInterface.instance = TestWakelock();
      addTearDown(
        () => WakelockPlusPlatformInterface.instance = previousWakelock,
      );
      await initializeTestIsar();
      await MainDB.instance.initMainDB();
      final hive = DB.instance.hive..init('${root.path}/hive');
      hive.registerAdapter(NodeModelAdapter());
      await hive.openBox<dynamic>(DB.boxNamePrefs);
      await hive.openBox<NodeModel>(DB.boxNameNodeModels);
      await hive.openBox<Trade>(DB.boxNameTradesV2);
      await hive.openBox<String>(DB.boxNameTradeNotes);
      await hive.openBox<TradeWalletLookup>(DB.boxNameTradeLookup);
      final secrets = MemorySecrets();
      final prefs = Prefs.instance;
      await prefs.init();
      final nodes = NodeService(secureStorageInterface: secrets);
      final wallets = Wallets.sharedInstance
        ..mainDB = MainDB.instance
        ..nodeService = nodes;
      await libXelis.initRustLib();
      final original = await Wallet.create(
        walletInfo: WalletInfo(
          walletId: 'swb-original',
          name: 'Xelis SWB fixture',
          mainAddressType: AddressType.xelis,
          coinName: 'xelisTestNet',
        ),
        mainDB: MainDB.instance,
        secureStorageInterface: secrets,
        nodeService: nodes,
        prefs: prefs,
      ) as XelisWallet;
      opened.add(original);
      await original.init();
      wallets.addWallet(original);
      final address = original.info.cachedReceivingAddress;
      final seed = await original.getMnemonic();
      await MainDB.instance.isar.writeTxn(() async {
        await MainDB.instance.isar.transactionNotes.put(
          TransactionNote(
            walletId: original.walletId,
            txid: 'swb-fixture-transaction',
            value: 'preserve this note',
          ),
        );
      });
      final json = await SWB.createStackWalletJSON(secureStorage: secrets);
      final backup = (json['wallets'] as List).single as Map<String, dynamic>;
      expect(backup['mnemonic'] == seed, isTrue);
      expect(backup['coinName'], 'xelisTestNet');
      final plaintext = jsonEncode(json);
      const passphrase = 'temporary fixture backup password';
      final encrypted = await SWB.encryptStackWalletWithPassphrase(
        passphrase,
        plaintext,
      );
      final file = File('${root.path}/fixture.swb');
      await file.writeAsString(encrypted);
      expect((await file.readAsString()).contains(seed), isFalse);
      final decoded = await SWB.decryptStackWalletStringWithPassphrase((
        passphrase: passphrase,
        encryptedText: await file.readAsString(),
      ));
      expect(decoded == plaintext, isTrue);
      await original.exit();
      final state = StackRestoringUIState();
      addTearDown(state.dispose);
      try {
        final result = await SWB.restoreStackWalletJSON(
          decoded!,
          state,
          secrets,
          UnusedShopService(),
        );
        expect(result, isTrue);
        expect(state.succeeded, isTrue);
        final restored = state.wallets.single as XelisWallet;
        expect(restored.walletId, isNot(original.walletId));
        expect(restored.info.cachedReceivingAddress, address);
        expect((await restored.getMnemonic()) == seed, isTrue);
        expect(
          await restored.info.isMnemonicVerified(MainDB.instance.isar),
          isTrue,
        );
        final notes = await MainDB.instance.isar.transactionNotes
            .where()
            .walletIdEqualTo(restored.walletId)
            .findAll();
        expect(notes.single.value, 'preserve this note');
        await restored.exit();
        await MainDB.instance.isar.close();
        await MainDB.instance.initMainDB();
        final loaded = await Wallet.load(
          walletId: restored.walletId,
          mainDB: MainDB.instance,
          secureStorageInterface: secrets,
          nodeService: nodes,
          prefs: prefs,
        ) as XelisWallet;
        opened.add(loaded);
        await loaded.init();
        expect(loaded.info.cachedReceivingAddress, address);
        expect((await loaded.getMnemonic()) == seed, isTrue);
      } finally {
        for (final wallet in state.wallets) {
          await wallet.exit();
        }
      }
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );
}

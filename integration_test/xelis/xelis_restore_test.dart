import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:stackwallet/db/isar/main_db.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/address.dart';
import 'package:stackwallet/services/node_service.dart';
import 'package:stackwallet/utilities/stack_file_system.dart';
import 'package:stackwallet/wallets/isar/models/wallet_info.dart';
import 'package:stackwallet/wallets/wallet/impl/xelis_wallet.dart';
import 'package:stackwallet/wallets/wallet/wallet.dart';
import 'package:stackwallet/wl_gen/interfaces/lib_xelis_interface.dart';

import '../../test/wallets/support/xelis_test_fakes.dart';

class OfflineNodes extends Fake implements NodeService {}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  setUp(() async {
    if (!(Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      throw UnsupportedError('Run this storage scenario on a desktop host.');
    }
    final root = await Directory.systemTemp.createTemp('stack_xelis_restore_');
    addTearDown(() => root.delete(recursive: true));
    StackFileSystem.setDesktopOverrideDir(root.path);
    await MainDB.instance.initMainDB();
    addTearDown(() => MainDB.instance.isar.close());
  });
  testWidgets(
    'native Stack factory restores exported recovery data and reloads',
    (tester) async {
      await libXelis.initRustLib();
      final secrets = MemorySecrets();
      final prefs = SessionPrefs();
      final nodes = OfflineNodes();
      final opened = <XelisWallet>[];
      addTearDown(() async {
        for (final item in opened.reversed) {
          await item.exit();
        }
      });
      Future<XelisWallet> create(
        String id, {
        String? seed,
        String? password,
      }) async {
        final result = await Wallet.create(
          walletInfo: WalletInfo(
            walletId: id,
            name: 'native-restore-fixture',
            mainAddressType: AddressType.xelis,
            coinName: 'xelisTestNet',
          ),
          mainDB: MainDB.instance,
          secureStorageInterface: secrets,
          nodeService: nodes,
          prefs: prefs,
          mnemonic: seed,
          mnemonicPassphrase: password,
        ) as XelisWallet;
        opened.add(result);
        await result.init(isRestore: seed != null);
        return result;
      }

      final original = await create('native-original');
      final seed = await original.getMnemonic();
      final password = await original.getMnemonicPassphrase();
      final address = original.info.cachedReceivingAddress;
      expect(address, isNotEmpty);
      await original.exit();
      opened.remove(original);

      final restored = await create(
        'native-restored',
        seed: seed,
        password: password,
      );
      expect(restored.info.cachedReceivingAddress, address);
      expect((await restored.getCurrentReceivingAddress())!.value, address);
      expect((await restored.getMnemonic()) == seed, isTrue);
      expect(await libXelis.getXelisBalanceRaw(restored.wallet!), BigInt.zero);
      await restored.exit();
      opened.remove(restored);

      final reloaded = await Wallet.load(
        walletId: 'native-restored',
        mainDB: MainDB.instance,
        secureStorageInterface: secrets,
        nodeService: nodes,
        prefs: prefs,
      ) as XelisWallet;
      opened.add(reloaded);
      await reloaded.init();
      expect(reloaded.info.cachedReceivingAddress, address);
      expect((await reloaded.getMnemonic()) == seed, isTrue);
      expect(await libXelis.getXelisBalanceRaw(reloaded.wallet!), BigInt.zero);
    },
  );
}

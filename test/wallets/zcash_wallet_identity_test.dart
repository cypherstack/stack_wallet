import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/db/isar/main_db.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/address.dart';
import 'package:stackwallet/models/node_model.dart';
import 'package:stackwallet/services/node_service.dart';
import 'package:stackwallet/utilities/stack_file_system.dart';
import 'package:stackwallet/wallets/crypto_currency/crypto_currency.dart';
import 'package:stackwallet/wallets/isar/models/wallet_info.dart';
import 'package:stackwallet/wallets/wallet/impl/zcash_wallet.dart';
import 'package:stackwallet/wallets/wallet/wallet.dart';

import 'support/xelis_test_fakes.dart';
import '../support/isar_test_utils.dart';

class OfflineNodes extends Fake implements NodeService {
  @override
  NodeModel? getPrimaryNodeFor({required CryptoCurrency currency}) => null;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(initializeTestIsar);
  late Directory root;

  setUpAll(() async {
    if (!(Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      throw UnsupportedError('Run this storage scenario on a desktop host.');
    }
    root = await Directory.systemTemp.createTemp('stack_zcash_identity_');
    StackFileSystem.setDesktopOverrideDir(root.path);
  });
  tearDownAll(() => root.delete(recursive: true));

  setUp(() async {
    await MainDB.instance.initMainDB();
    addTearDown(() => MainDB.instance.isar.close());
  });

  test(
    'fixed recovery phrase creates, persists, and reopens one unified address',
    () async {
      const phrase =
          'abandon abandon abandon abandon abandon abandon abandon abandon '
          'abandon abandon abandon about';
      final secrets = MemorySecrets();
      final prefs = SessionPrefs();
      final nodes = OfflineNodes();

      final created = await Wallet.create(
        walletInfo: WalletInfo(
          walletId: 'zcash-identity',
          name: 'Zcash identity fixture',
          mainAddressType: AddressType.zcashUnified,
          coinName: 'zcash',
        ),
        mainDB: MainDB.instance,
        secureStorageInterface: secrets,
        nodeService: nodes,
        prefs: prefs,
        mnemonic: phrase,
        mnemonicPassphrase: '',
      ) as ZcashWallet;
      await created.init(isRestore: true);

      final createdAddress = await created.getCurrentReceivingAddress();
      expect(createdAddress, isNotNull);
      expect(createdAddress!.value, startsWith('u1'));
      expect(
        created.cryptoCurrency.validateAddress(createdAddress.value),
        isTrue,
      );
      expect(created.info.cachedReceivingAddress, createdAddress.value);
      expect(await created.pingCheck(), isFalse);
      await expectLater(created.updateNode(), throwsStateError);
      await created.exit();

      final reopened = await Wallet.load(
        walletId: 'zcash-identity',
        mainDB: MainDB.instance,
        secureStorageInterface: secrets,
        nodeService: nodes,
        prefs: prefs,
      ) as ZcashWallet;
      await reopened.init();

      final reopenedAddress = await reopened.getCurrentReceivingAddress();
      expect(reopenedAddress, isNotNull);
      expect(reopenedAddress!.value, createdAddress.value);
      expect(reopened.info.cachedReceivingAddress, createdAddress.value);
      expect(await reopened.getMnemonic(), phrase);
      await reopened.exit();
    },
  );

  test('reopening refuses a cached unified-address mismatch', () async {
    const phrase =
        'abandon abandon abandon abandon abandon abandon abandon abandon '
        'abandon abandon abandon about';
    final secrets = MemorySecrets();
    final prefs = SessionPrefs();
    final nodes = OfflineNodes();
    final created = await Wallet.create(
      walletInfo: WalletInfo(
        walletId: 'zcash-mismatch',
        name: 'Zcash mismatch fixture',
        mainAddressType: AddressType.zcashUnified,
        coinName: 'zcash',
      ),
      mainDB: MainDB.instance,
      secureStorageInterface: secrets,
      nodeService: nodes,
      prefs: prefs,
      mnemonic: phrase,
      mnemonicPassphrase: '',
    ) as ZcashWallet;
    await created.init(isRestore: true);
    final derivedAddress = created.info.cachedReceivingAddress;
    await created.info.updateReceivingAddress(
      newAddress: '${derivedAddress}corrupt',
      isar: MainDB.instance.isar,
    );
    await created.exit();

    final reopened = await Wallet.load(
      walletId: 'zcash-mismatch',
      mainDB: MainDB.instance,
      secureStorageInterface: secrets,
      nodeService: nodes,
      prefs: prefs,
    ) as ZcashWallet;
    await expectLater(
      reopened.init(),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          contains('does not match the saved wallet'),
        ),
      ),
    );
    await reopened.exit();
  });
}

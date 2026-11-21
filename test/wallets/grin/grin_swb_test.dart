import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:stackwallet/wallets/isar/models/wallet_info.dart';
import 'package:stackwallet/wallets/wallet/impl/grin_wallet.dart';
import 'package:stackwallet/wallets/wallet/supporting/grin_wallet_info_extension.dart';

import '../support/grin_fakes.dart';

/// The per-wallet fields restore_create_backup writes for a mnemonic wallet.
Future<Map<String, dynamic>> backupOf(GrinTestWallet wallet) async => {
  'name': wallet.info.name,
  'id': wallet.walletId,
  'otherDataJsonString': wallet.info.otherDataJsonString,
  'mnemonic': await wallet.getMnemonic(),
  'mnemonicPassphrase': await wallet.getMnemonicPassphrase(),
  'coinName': wallet.info.coin.identifier,
  'storedChainHeight': wallet.info.cachedChainHeight,
  'restoreHeight': wallet.info.restoreHeight,
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory dataRoot;
  late Directory isarRoot;
  late Isar isar;

  setUpAll(() async => dataRoot = await setUpGrinTests());
  tearDownAll(() => dataRoot.delete(recursive: true));
  setUp(() async {
    isarRoot = await Directory.systemTemp.createTemp('stack_grin_isar_');
    isar = await openTestIsar(isarRoot);
  });
  tearDown(() async {
    await isar.close();
    await isarRoot.delete(recursive: true);
  });

  test('a backup holds the mnemonic, an empty passphrase, the restore height '
      'and grinData, and no password', () async {
    final original = await GrinHarness.create();
    await original.wallet.init();
    final password = original.backend.creates.single.password;

    final backup = await backupOf(original.wallet);
    final text = jsonEncode(backup);

    expect(backup['mnemonic'], testMnemonic);
    expect(backup['mnemonicPassphrase'], '');
    expect(backup['coinName'], 'grin');
    final height = original.wallet.info.grinData!.creationHeight;
    expect(backup['restoreHeight'], height);
    final otherData =
        jsonDecode(backup['otherDataJsonString'] as String) as Map;
    expect(otherData[WalletInfoKeys.grinData], isNotNull);
    expect(text, isNot(contains(password)));
    expect(text, isNot(contains(GrinWallet.passwordKey(original.walletId))));
    await original.dispose();
  });

  test('restoring a backup creates from the mnemonic, then scans from the '
      'restore height, with a new password', () async {
    final original = await GrinHarness.create();
    await original.wallet.init();
    final backup = await backupOf(original.wallet);
    final oldPassword = original.backend.creates.single.password;
    await original.dispose();

    // A restore gets a new wallet id with the backed up WalletInfo fields.
    final restored = await GrinHarness.create(
      restoreHeight: backup['restoreHeight'] as int,
      otherDataJsonString: backup['otherDataJsonString'] as String,
    );
    await restored.wallet.init(isRestore: true);
    expect(restored.backend.calls, isEmpty);
    await restored.wallet.recover(isRescan: false);
    await pumpEventQueue();

    final create = restored.backend.creates.single;
    expect(create.mnemonic, testMnemonic);
    expect(create.isNewWallet, isFalse);
    expect(create.password, isNot(oldPassword));
    expect(
      restored.secrets.values[GrinWallet.passwordKey(restored.walletId)],
      create.password,
    );
    expect(
      restored.backend.api.calls,
      contains('scan:${backup['restoreHeight']}:false'),
    );
    await restored.dispose();
  });
}

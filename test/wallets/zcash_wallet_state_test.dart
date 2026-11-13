import 'dart:io';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/utilities/flutter_secure_storage_interface.dart';
import 'package:stackwallet/wallets/wallet/intermediate/zcash_wallet_state.dart';
import 'package:zcash_flutter/zcash_flutter.dart' as zcash;

void main() {
  late Directory directory;
  late FakeSecureStorage secrets;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('zcash_state_test_');
    secrets = FakeSecureStorage();
  });

  tearDown(() async {
    await directory.delete(recursive: true);
  });

  zcash.ZcashWalletSyncState walletState({
    String fingerprint = 'account-a',
  }) => zcash.ZcashWalletSyncState.atBirthday(
    cursor: zcash.ZcashLightwalletdSyncCursor.fromTreeState(
      const zcash.TreeState(
        hash:
            '0000000000000000000000000000000000000000000000000000000000000000',
        height: 99,
        time: 1,
      ),
    ),
    network: zcash.ZcashAddressNetwork.mainnet,
    accountFingerprint: fingerprint,
  );

  test('encrypted state reopens at the persisted birthday', () async {
    final path = '${directory.path}/wallet.state';
    final store = ZcashEncryptedWalletStateStore(
      path: path,
      walletId: 'wallet-1',
      network: 'main',
      accountFingerprint: 'account-a',
      secureStorage: secrets,
    );
    await store.save(
      ZcashPersistedWalletState(
        syncState: walletState(),
        observedChainHeight: 99,
      ),
    );

    final reopened = await store.load();

    expect(reopened, isNotNull);
    expect(reopened!.syncState.cursor.nextHeight, 100);
    expect(reopened.observedChainHeight, 99);
    expect(reopened.syncState.accountFingerprint, 'account-a');
  });

  test(
    'persisted state contains no plaintext and rejects corruption',
    () async {
      final path = '${directory.path}/wallet.state';
      final store = ZcashEncryptedWalletStateStore(
        path: path,
        walletId: 'wallet-1',
        network: 'main',
        accountFingerprint: 'account-a-sensitive',
        secureStorage: secrets,
      );
      await store.save(
        ZcashPersistedWalletState(
          syncState: walletState(fingerprint: 'account-a-sensitive'),
          observedChainHeight: 99,
        ),
      );

      final encoded = await File(path).readAsString();
      expect(encoded, isNot(contains('account-a-sensitive')));
      expect(encoded, isNot(contains('observed_chain_height')));

      final envelope = jsonDecode(encoded) as Map<String, dynamic>;
      final ciphertext = base64Decode(envelope['ciphertext'] as String);
      ciphertext[0] ^= 1;
      envelope['ciphertext'] = base64Encode(ciphertext);
      await File(path).writeAsString(jsonEncode(envelope), flush: true);

      await expectLater(
        store.load(),
        throwsA(isA<ZcashStatePersistenceException>()),
      );
    },
  );

  test('reopen cleans an interrupted temporary write', () async {
    final path = '${directory.path}/wallet.state';
    final store = ZcashEncryptedWalletStateStore(
      path: path,
      walletId: 'wallet-1',
      network: 'main',
      accountFingerprint: 'account-a',
      secureStorage: secrets,
    );
    await store.save(
      ZcashPersistedWalletState(
        syncState: walletState(),
        observedChainHeight: 99,
      ),
    );
    final interrupted = File('$path.tmp');
    await interrupted.writeAsString('partial plaintext write');

    final reopened = await store.load();

    expect(reopened?.observedChainHeight, 99);
    expect(await interrupted.exists(), isFalse);
  });

  test('refuses symlink state paths and foreign account contexts', () async {
    final target = File('${directory.path}/target');
    await target.writeAsString('do not overwrite');
    final linkedPath = '${directory.path}/wallet.state';
    await Link(linkedPath).create(target.path);
    final linkedStore = ZcashEncryptedWalletStateStore(
      path: linkedPath,
      walletId: 'wallet-1',
      network: 'main',
      accountFingerprint: 'account-a',
      secureStorage: secrets,
    );
    await expectLater(
      linkedStore.save(
        ZcashPersistedWalletState(
          syncState: walletState(),
          observedChainHeight: 99,
        ),
      ),
      throwsA(isA<ZcashStatePersistenceException>()),
    );
    expect(await target.readAsString(), 'do not overwrite');

    await Link(linkedPath).delete();
    final correctStore = ZcashEncryptedWalletStateStore(
      path: linkedPath,
      walletId: 'wallet-1',
      network: 'main',
      accountFingerprint: 'account-a',
      secureStorage: secrets,
    );
    await correctStore.save(
      ZcashPersistedWalletState(
        syncState: walletState(),
        observedChainHeight: 99,
      ),
    );
    final foreignStore = ZcashEncryptedWalletStateStore(
      path: linkedPath,
      walletId: 'wallet-1',
      network: 'main',
      accountFingerprint: 'account-b',
      secureStorage: secrets,
    );
    await expectLater(
      foreignStore.load(),
      throwsA(isA<ZcashStatePersistenceException>()),
    );
  });

  test('refuses state for a foreign consensus network', () async {
    final store = ZcashEncryptedWalletStateStore(
      path: '${directory.path}/wallet.state',
      walletId: 'wallet-1',
      network: 'main',
      accountFingerprint: 'account-a',
      secureStorage: secrets,
    );
    final foreign = zcash.ZcashWalletSyncState.atBirthday(
      cursor: zcash.ZcashLightwalletdSyncCursor.fromTreeState(
        const zcash.TreeState(
          hash: '0000000000000000000000000000000000000000000000000000000000000000',
          height: 99,
          time: 1,
        ),
      ),
      network: zcash.ZcashAddressNetwork.testnet,
      accountFingerprint: 'account-a',
    );

    await expectLater(
      store.save(
        ZcashPersistedWalletState(syncState: foreign, observedChainHeight: 99),
      ),
      throwsA(isA<ZcashStatePersistenceException>()),
    );
  });

  test('spendable witness state survives restart without plaintext', () async {
    final state = walletState();
    const scan = zcash.ZcashScanResult(
      scannedBlocks: 1,
      discoveredNotes: 1,
      totalValue: 123,
      scannedHeightRange: zcash.CompactBlockScanRange(start: 99, end: 99),
      notes: [
        zcash.ZcashScannedNote(
          height: 99,
          tx: '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef',
          output: 0,
          value: 123,
          pool: 'sapling',
          nullifier: '1111111111111111111111111111111111111111111111111111111111111111',
          recipient: 'secret-sapling-recipient',
          rseed: 'aabb',
          witness: 'ccdd',
        ),
      ],
    );
    state.sapling.apply(scan, accountFingerprint: 'account-a');
    state.orchard.apply(scan, accountFingerprint: 'account-a');
    state.ironwood.apply(scan, accountFingerprint: 'account-a');
    final path = '${directory.path}/wallet.state';
    final store = ZcashEncryptedWalletStateStore(
      path: path,
      walletId: 'wallet-1',
      network: 'main',
      accountFingerprint: 'account-a',
      secureStorage: secrets,
    );

    await store.save(
      ZcashPersistedWalletState(syncState: state, observedChainHeight: 99),
    );
    final reopened = await store.load();
    final encrypted = await File(path).readAsString();

    expect(reopened?.syncState.balance().spendableZatoshis, 123);
    expect(encrypted, isNot(contains('secret-sapling-recipient')));
    expect(encrypted, isNot(contains('aabb')));
    expect(encrypted, isNot(contains('ccdd')));
  });
}

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/wallets/wallet/intermediate/zcash_pending_send_store.dart';
import 'package:stackwallet/wallets/wallet/intermediate/zcash_wallet_state.dart';
import 'package:zcash_flutter/zcash_flutter.dart' as zcash;

import 'support/xelis_test_fakes.dart';

void main() {
  test('pending reservations are encrypted and account-bound', () async {
    final directory = await Directory.systemTemp.createTemp(
      'zcash_pending_store_',
    );
    addTearDown(() => directory.delete(recursive: true));
    final secrets = MemorySecrets();
    final path = '${directory.path}/wallet.pending';
    final store = ZcashEncryptedPendingSendStore(
      path: path,
      walletId: 'wallet-id',
      network: 'main',
      accountFingerprint: 'account-a',
      secureStorage: secrets,
    );

    await store.save(zcash.IronwoodPendingSendState());

    expect((await store.load()).records, isEmpty);
    final envelope = await File(path).readAsString();
    expect(envelope, isNot(contains('account-a')));
    expect(envelope, isNot(contains('pending_send_version')));

    final foreign = ZcashEncryptedPendingSendStore(
      path: path,
      walletId: 'wallet-id',
      network: 'main',
      accountFingerprint: 'account-b',
      secureStorage: secrets,
    );
    await expectLater(
      foreign.load(),
      throwsA(isA<ZcashStatePersistenceException>()),
    );
  });
}

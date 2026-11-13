import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/wallets/wallet/intermediate/zcash_transparent_shielding.dart';
import 'package:stackwallet/wallets/wallet/intermediate/zcash_wallet_state.dart';
import 'package:zcash_flutter/zcash_flutter.dart' as zcash;

import 'support/xelis_test_fakes.dart';

const _sourceTxid =
    '1111111111111111111111111111111111111111111111111111111111111111';
const _shieldingTxid =
    '2222222222222222222222222222222222222222222222222222222222222222';

zcash.ShieldingPreparedSend _prepared({int shieldedZatoshis = 90000}) {
  final coins = zcash.TransparentCoinSet.fromUtxos(
    utxos: [
      const zcash.AddressUtxo(
        address: 'tmWalletReceiver',
        txid: _sourceTxid,
        outputIndex: 2,
        script: '76a914000000000000000000000000000000000000000088ac',
        satoshis: 100000,
        height: 50,
      ),
    ],
    chainHeight: 200,
    coinbaseOutpoints: const {},
  );
  return zcash.ShieldingPreparedSend(
    destination: zcash.ShieldingDestination.ironwood,
    selection: zcash.TransparentInputSelection(
      coins: coins.spendable,
      amountZatoshis: 90000,
      feeZatoshis: 10000,
      changeZatoshis: 0,
      spendsCoinbase: false,
    ),
    transactionHex: '00aa',
    txid: _shieldingTxid,
    feeZatoshis: 10000,
    shieldedZatoshis: shieldedZatoshis,
  );
}

void main() {
  test('shielding reservation survives restart and indeterminate retry', () {
    final prepared = _prepared();
    final state = ZcashTransparentShieldingState()
      ..addPrepared(
        prepared,
        destinationAddress: 'uregtest-wallet',
        createdHeight: 200,
      );

    var restarted = ZcashTransparentShieldingState.fromJson(state.toJson());
    expect(restarted.reservedOutpoints, {'$_sourceTxid:2'});
    restarted.requireBroadcastable(prepared);
    restarted.markSubmitting(prepared.txid);
    restarted.markIndeterminate(prepared.txid);

    restarted = ZcashTransparentShieldingState.fromJson(restarted.toJson());
    restarted.requireBroadcastable(prepared);
    restarted.markSubmitting(prepared.txid);
    restarted.markAcknowledged(prepared.txid);

    expect(
      restarted.records.single.broadcastState,
      ZcashShieldingBroadcastState.acknowledged,
    );
    expect(restarted.reservedOutpoints, {'$_sourceTxid:2'});
  });

  test('definitive rejection releases the transparent inputs', () {
    final prepared = _prepared();
    final state = ZcashTransparentShieldingState()
      ..addPrepared(
        prepared,
        destinationAddress: 'uregtest-wallet',
        createdHeight: 200,
      )
      ..markSubmitting(prepared.txid)
      ..releaseRejected(prepared.txid);

    expect(state.records, isEmpty);
    expect(state.reservedOutpoints, isEmpty);
  });

  test('value mismatch is rejected before an input is reserved', () {
    final state = ZcashTransparentShieldingState();

    expect(
      () => state.addPrepared(
        _prepared(shieldedZatoshis: 89999),
        destinationAddress: 'uregtest-wallet',
        createdHeight: 200,
      ),
      throwsStateError,
    );
    expect(state.records, isEmpty);
    expect(state.reservedOutpoints, isEmpty);
  });

  test('restart makes an interrupted submission retryable', () {
    final prepared = _prepared();
    final state = ZcashTransparentShieldingState()
      ..addPrepared(
        prepared,
        destinationAddress: 'uregtest-wallet',
        createdHeight: 200,
      )
      ..markSubmitting(prepared.txid);

    final restarted = ZcashTransparentShieldingState.fromJson(state.toJson())
      ..recoverInterruptedSubmissions();

    expect(
      restarted.requireBroadcastable(prepared).broadcastState,
      ZcashShieldingBroadcastState.indeterminate,
    );
    expect(restarted.reservedOutpoints, {'$_sourceTxid:2'});
  });

  test('shielding reservations are encrypted and account-bound', () async {
    final directory = await Directory.systemTemp.createTemp(
      'zcash_shielding_store_',
    );
    addTearDown(() => directory.delete(recursive: true));
    final secrets = MemorySecrets();
    final path = '${directory.path}/wallet.shielding';
    final prepared = _prepared();
    final state = ZcashTransparentShieldingState()
      ..addPrepared(
        prepared,
        destinationAddress: 'uregtest-wallet',
        createdHeight: 200,
      );
    final store = ZcashEncryptedTransparentShieldingStore(
      path: path,
      walletId: 'wallet-id',
      network: 'regtest',
      accountFingerprint: 'account-a',
      secureStorage: secrets,
    );

    await store.save(state);
    expect((await store.load()).records.single.txid, _shieldingTxid);
    final envelope = await File(path).readAsString();
    expect(envelope, isNot(contains(_shieldingTxid)));
    expect(envelope, isNot(contains(_sourceTxid)));

    final foreign = ZcashEncryptedTransparentShieldingStore(
      path: path,
      walletId: 'wallet-id',
      network: 'regtest',
      accountFingerprint: 'account-b',
      secureStorage: secrets,
    );
    await expectLater(
      foreign.load(),
      throwsA(isA<ZcashStatePersistenceException>()),
    );
  });
}

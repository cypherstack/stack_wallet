import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/transaction.dart';

import 'helpers.dart';
import 'stack_env.dart';

void main() {
  final fixture = RegtestFixture();

  testWidgets('mined coins move between Stack wallets and survive a restore', (
    tester,
  ) async {
    fixture.dumpLogsOnFailure();
    final chain = fixture.chain;
    final env = fixture.env;
    final network = StackEnv.coin.networkParams;
    final alice = await env.createWallet('alice');
    final bob = await env.createWallet('bob');
    final aliceAddress = await receivingAddress(alice);
    final bobAddress = await receivingAddress(bob);
    expect(aliceAddress, startsWith('bcrt1p'), reason: 'BIP86 by default');

    // The node's wallet pays alice; she sees it unconfirmed, then confirmed.
    final funding = await chain.pay(aliceAddress, '1.0');
    await chain.waitForHistory(aliceAddress, funding, network: network);
    await alice.refresh();
    expect(alice.info.cachedBalance.pendingSpendable.raw, sats('1.0'));
    expect(alice.info.cachedBalance.spendable.raw, BigInt.zero);

    await chain.mine(1);
    await alice.refresh();
    expect(alice.info.cachedBalance.spendable.raw, sats('1.0'));

    // Alice pays bob at 3 sat/vB.
    final toBob = await send(alice, bobAddress, '0.3', satsPerVByte: 3);
    final txid = toBob.txid!;
    expect(await chain.mempool(), contains(txid));
    final entry = await fixture.mempoolEntry(txid);
    expect(entry['bip125-replaceable'], isFalse, reason: 'RBF is opt-in');
    final fee = btcToSats((entry['fees'] as Map)['base'] as num);
    expect(fee, toBob.fee!.raw, reason: 'node and wallet agree on the fee');
    expect(fee >= BigInt.from(3 * (entry['vsize'] as int)), isTrue);
    final outputs = ((await chain.transaction(txid))['vout'] as List)
        .cast<Map<String, dynamic>>()
        .where((o) => (o['scriptPubKey'] as Map)['address'] == bobAddress);
    expect(outputs.map((o) => btcToSats(o['value'] as num)), [sats('0.3')]);

    await chain.waitForHistory(bobAddress, txid, network: network);
    await bob.refresh();
    expect(bob.info.cachedBalance.pendingSpendable.raw, sats('0.3'));

    await chain.mine(1);
    await alice.refresh();
    await bob.refresh();
    expect(bob.info.cachedBalance.spendable.raw, sats('0.3'));
    expect(
      alice.info.cachedBalance.spendable.raw,
      sats('1.0') - sats('0.3') - fee,
    );
    final aliceTxs = await history(alice);
    expect(aliceTxs.map((t) => t.type).toSet(), {
      TransactionType.incoming,
      TransactionType.outgoing,
    });
    expect(aliceTxs.every((t) => t.height != null && t.height! > 0), isTrue);

    // Bob pays a P2WPKH address in the node's wallet, which must see it.
    final minerAddress =
        await chain.rpc('getnewaddress', ['', 'bech32'], 'miner') as String;
    final back = await send(bob, minerAddress, '0.1', satsPerVByte: 2);
    await chain.mine(1);
    final received = Map<String, dynamic>.from(
      await chain.rpc('gettransaction', [back.txid], 'miner') as Map,
    );
    expect(received['confirmations'], 1);
    expect(btcToSats(received['amount'] as num), sats('0.1'));
    await bob.refresh();
    expect(
      bob.info.cachedBalance.spendable.raw,
      sats('0.3') - sats('0.1') - back.fee!.raw,
    );

    // Restoring alice's phrase finds the same coins and history.
    final restored = await env.createWallet(
      'alice restored',
      mnemonic: await alice.getMnemonic(),
    );
    expect(
      restored.info.cachedBalance.spendable.raw,
      alice.info.cachedBalance.spendable.raw,
    );
    expect(
      (await history(restored)).map((t) => t.txid).toSet(),
      aliceTxs.map((t) => t.txid).toSet(),
    );
  }, timeout: const Timeout(Duration(minutes: 10)));
}

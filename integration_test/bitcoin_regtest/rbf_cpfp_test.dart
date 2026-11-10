import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:stackwallet/db/isar/main_db.dart';
import 'package:stackwallet/models/input.dart';
import 'package:stackwallet/models/isar/models/isar_models.dart';
import 'package:stackwallet/wallets/isar/models/wallet_info.dart';

import 'helpers.dart';
import 'stack_env.dart';

void main() {
  final fixture = RegtestFixture();

  testWidgets('an opted-in send is replaced at a higher fee rate', (
    tester,
  ) async {
    fixture.dumpLogsOnFailure();
    final chain = fixture.chain;
    final network = StackEnv.coin.networkParams;
    final alice = await fixture.env.createWallet('alice');
    final bob = await fixture.env.createWallet('bob');
    await alice.info.updateOtherData(
      newEntries: {WalletInfoKeys.enableOptInRbf: true},
      isar: MainDB.instance.isar,
    );
    await fixture.fund(alice, '1.0');
    final bobAddress = await receivingAddress(bob);

    final original = await send(alice, bobAddress, '0.3', satsPerVByte: 2);
    final originalEntry = await fixture.mempoolEntry(original.txid!);
    expect(originalEntry['bip125-replaceable'], isTrue);

    // The boost screen works from the wallet's stored copy of the tx.
    await chain.waitForHistory(bobAddress, original.txid!, network: network);
    await alice.refresh();
    final stored = (await history(alice))
        .firstWhere((t) => t.txid == original.txid);
    final prepared = await alice.prepareRbfSend(
      oldTransaction: stored,
      newRate: 10,
    );
    final bumped = await alice.confirmSend(txData: prepared);

    final mempool = await chain.mempool();
    expect(mempool, contains(bumped.txid));
    expect(mempool, isNot(contains(original.txid)));
    final entry = await fixture.mempoolEntry(bumped.txid!);
    final fee = btcToSats((entry['fees'] as Map)['base'] as num);
    expect(fee, bumped.fee!.raw);
    expect(fee >= BigInt.from(10 * (entry['vsize'] as int)), isTrue);
    expect(fee > original.fee!.raw, isTrue);
    final toBob = ((await chain.transaction(bumped.txid!))['vout'] as List)
        .cast<Map<String, dynamic>>()
        .where((o) => (o['scriptPubKey'] as Map)['address'] == bobAddress);
    expect(toBob.map((o) => btcToSats(o['value'] as num)), [sats('0.3')]);

    await chain.waitForHistory(
      bobAddress,
      bumped.txid!,
      network: network,
      replaced: original.txid,
    );
    await chain.mine(1);
    await alice.refresh();
    await bob.refresh();
    expect(bob.info.cachedBalance.spendable.raw, sats('0.3'));
    expect(
      alice.info.cachedBalance.spendable.raw,
      sats('1.0') - sats('0.3') - fee,
    );
    final txids = (await history(alice)).map((t) => t.txid).toSet();
    expect(txids, contains(bumped.txid));
    expect(txids, isNot(contains(original.txid)));
  });

  testWidgets('a child spending an unconfirmed parent raises its fee rate', (
    tester,
  ) async {
    fixture.dumpLogsOnFailure();
    final chain = fixture.chain;
    final network = StackEnv.coin.networkParams;
    final alice = await fixture.env.createWallet('alice cpfp');
    final bob = await fixture.env.createWallet('bob cpfp');
    await fixture.fund(alice, '1.0');
    final bobAddress = await receivingAddress(bob);

    final parent = await send(alice, bobAddress, '0.3', satsPerVByte: 1);
    await chain.waitForHistory(bobAddress, parent.txid!, network: network);
    await bob.refresh();
    expect(bob.info.cachedBalance.pendingSpendable.raw, sats('0.3'));

    // Coin control on the unconfirmed output is how the app does CPFP.
    final unconfirmed = await MainDB.instance
        .getUTXOs(bob.walletId)
        .filter()
        .txidEqualTo(parent.txid!)
        .findAll();
    expect(unconfirmed, hasLength(1));
    final minerAddress =
        await chain.rpc('getnewaddress', ['', 'bech32'], 'miner') as String;
    final child = await send(
      bob,
      minerAddress,
      '0.1',
      satsPerVByte: 30,
      utxos: {StandardInput(unconfirmed.single)},
    );

    final childEntry = await fixture.mempoolEntry(child.txid!);
    expect(childEntry['depends'], [parent.txid]);
    final parentEntry = await fixture.mempoolEntry(parent.txid!);
    final parentFees = parentEntry['fees'] as Map;
    final parentRate =
        btcToSats(parentFees['base'] as num).toInt() /
        (parentEntry['vsize'] as int);
    final packageRate =
        btcToSats(parentFees['descendant'] as num).toInt() /
        (parentEntry['descendantsize'] as int);
    expect(parentRate, lessThan(2));
    expect(packageRate, greaterThan(10));

    await chain.mine(1);
    await bob.refresh();
    expect(
      bob.info.cachedBalance.spendable.raw,
      sats('0.3') - sats('0.1') - child.fee!.raw,
    );
  });
}

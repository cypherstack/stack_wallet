import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:isar_community/isar.dart';
import 'package:stackwallet/db/isar/main_db.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/transaction.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/v2/transaction_v2.dart';
import 'package:stackwallet/utilities/amount/amount.dart';
import 'package:stackwallet/utilities/enums/fee_rate_type_enum.dart';
import 'package:stackwallet/wallets/models/tx_data.dart';
import 'package:stackwallet/wallets/wallet/impl/bitcoin_wallet.dart';

import 'regtest_chain.dart';
import 'stack_env.dart';

BigInt sats(String btc) {
  final parts = btc.split('.');
  final frac = parts.length > 1 ? parts[1] : '';
  return BigInt.parse(parts[0]) * BigInt.from(100000000) +
      BigInt.parse(frac.padRight(8, '0'));
}

BigInt btcToSats(num btc) => BigInt.from((btc * 1e8).round());

Future<List<TransactionV2>> history(BitcoinWallet wallet) => MainDB
    .instance
    .isar
    .transactionV2s
    .where()
    .walletIdEqualTo(wallet.walletId)
    .findAll();

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late RegtestChain chain;
  late StackEnv env;
  RegtestChain? started;
  StackEnv? opened;

  setUpAll(() async {
    chain = started = await RegtestChain.start();
    env = opened = await StackEnv.open(chain);
  });

  tearDownAll(() async {
    try {
      await opened?.close();
    } finally {
      await started?.stop();
    }
  });

  Future<String> address(BitcoinWallet wallet) async =>
      (await wallet.getCurrentReceivingAddress())!.value;

  /// Builds, signs and broadcasts through the same calls the send view makes.
  Future<TxData> send(
    BitcoinWallet from,
    String to,
    String btc, {
    required int satsPerVByte,
  }) async {
    final prepared = await from.prepareSend(
      txData: TxData(
        recipients: [
          TxRecipient(
            address: to,
            amount: Amount(rawValue: sats(btc), fractionDigits: 8),
            isChange: false,
            addressType: from.cryptoCurrency.getAddressType(to)!,
          ),
        ],
        feeRateType: FeeRateType.custom,
        satsPerVByte: satsPerVByte,
      ),
    );
    return from.confirmSend(txData: prepared);
  }

  testWidgets('mined coins move between Stack wallets and survive a restore', (
    tester,
  ) async {
    addTearDown(() {
      printOnFailure('--- app log\n${env.logTail()}');
      printOnFailure('--- bitcoind and electrs\n${chain.logTail}');
    });
    final network = StackEnv.coin.networkParams;
    final alice = await env.createWallet('alice');
    final bob = await env.createWallet('bob');
    final aliceAddress = await address(alice);
    final bobAddress = await address(bob);
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
    final entry = Map<String, dynamic>.from(
      await chain.rpc('getmempoolentry', [txid]) as Map,
    );
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

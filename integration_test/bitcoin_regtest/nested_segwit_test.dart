import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/utilities/enums/derive_path_type_enum.dart';

import 'helpers.dart';
import 'stack_env.dart';

void main() {
  final fixture = RegtestFixture();

  // Stack never hands out BIP49 addresses, but recover() scans them, so a seed
  // that received to P2SH-P2WPKH in another wallet brings such coins along.
  testWidgets('a restored wallet spends coins on its BIP49 address', (
    tester,
  ) async {
    fixture.dumpLogsOnFailure();
    final chain = fixture.chain;
    final coin = StackEnv.coin;
    final original = await fixture.env.createWallet('bip49 original');
    final root = await original.getRootHDNode();
    final key = root.derivePath(
      coin.constructDerivePath(
        derivePathType: DerivePathType.bip49,
        chain: 0,
        index: 0,
      ),
    );
    final nested = coin
        .getAddressForPublicKey(
          publicKey: key.publicKey,
          derivePathType: DerivePathType.bip49,
        )
        .address
        .toString();
    expect(nested, startsWith('2'), reason: 'regtest P2SH');
    await chain.pay(nested, '0.5');
    await chain.mine(1);

    final restored = await fixture.env.createWallet(
      'bip49 restored',
      mnemonic: await original.getMnemonic(),
    );
    expect(restored.info.cachedBalance.spendable.raw, sats('0.5'));

    final minerAddress =
        await chain.rpc('getnewaddress', ['', 'bech32'], 'miner') as String;
    final spent = await send(restored, minerAddress, '0.2', satsPerVByte: 2);
    await chain.mine(1);
    final received = Map<String, dynamic>.from(
      await chain.rpc('gettransaction', [spent.txid], 'miner') as Map,
    );
    expect(received['confirmations'], 1);
    expect(btcToSats(received['amount'] as num), sats('0.2'));

    await restored.refresh();
    expect(
      restored.info.cachedBalance.spendable.raw,
      sats('0.5') - sats('0.2') - spent.fee!.raw,
    );
  });
}

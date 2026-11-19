import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/address.dart';

import 'harness.dart';

void main() {
  buyFlowTest('a restored wallet moves every derivation path to an address '
      'without history', (t) async {
    await t.launch();
    // The first address of three derivation paths was paid before the restore.
    const usedPaths = {
      AddressType.p2pkh: "m/44'/0'/0'/0",
      AddressType.p2sh: "m/49'/0'/0'/0",
      AddressType.p2wpkh: "m/84'/0'/0'/0",
    };
    t.electrumX.pay(legacyAddress0);
    t.electrumX.pay(nestedSegwitAddress0);
    t.electrumX.pay(segwitAddress0);
    final wallet = await t.addWallet('Restored wallet');

    // The restore saves each path up to its last used address. A refresh then
    // saves the next address of each one.
    await t.refreshUntil(wallet, () async {
      for (final type in usedPaths.keys) {
        if ((await t.receiving(wallet, type)).length < 2) return false;
      }
      return true;
    }, 'a new address on every used derivation path');
    for (final MapEntry(key: type, value: path) in usedPaths.entries) {
      expect(
        (await t.receiving(wallet, type)).map((e) => e.derivationPath!.value),
        ['$path/0', '$path/1'],
        reason: type.name,
      );
    }
    // Taproot has no history, so it stays where it is.
    expect((await t.receiving(wallet, AddressType.p2tr)).map((e) => e.value), [
      taprootAddress0,
    ]);

    // The Buy form offers the unused native SegWit address.
    await t.openBuy();
    await t.chooseFromStack(wallet);
    await t.waitForAddress(segwitAddress1);
  });
}

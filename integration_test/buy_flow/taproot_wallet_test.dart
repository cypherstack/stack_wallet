import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/address.dart';

import 'harness.dart';

void main() {
  buyFlowTest('a Taproot wallet gets one saved native SegWit address, and a '
      'new one once that has been paid', (t) async {
    await t.launch();
    final wallet = await t.addWallet('Taproot wallet');
    expect(wallet.info.mainAddressType, AddressType.p2tr);
    expect(wallet.info.cachedReceivingAddress, taprootAddress0);
    expect(await t.receiving(wallet, AddressType.p2wpkh), isEmpty);

    await t.openBuy();
    expect(t.address, isEmpty);

    // Simplex does not accept Taproot, so the wallet derives a BIP84 address
    // and saves it.
    await t.chooseFromStack(wallet);
    await t.waitForAddress(segwitAddress0);
    var saved = await t.receiving(wallet, AddressType.p2wpkh);
    expect(saved.map((e) => e.value), [segwitAddress0]);
    expect(saved.single.derivationPath!.value, "m/84'/0'/0'/0/0");
    // Every refresh now checks it for payments.
    expect(
      (await wallet.fetchAddressesForElectrumXScan()).map((e) => e.value),
      contains(segwitAddress0),
    );
    // The wallet's own receiving address is still its Taproot one.
    expect(wallet.info.cachedReceivingAddress, taprootAddress0);

    // Choosing the wallet again reuses the saved address.
    await t.clearAddress();
    await t.chooseFromStack(wallet);
    await t.waitForAddress(segwitAddress0);
    expect(await t.receiving(wallet, AddressType.p2wpkh), hasLength(1));

    // Once the address has been paid, a refresh saves the next one and the
    // form offers that.
    t.electrumX.pay(segwitAddress0);
    await t.refreshUntil(
      wallet,
      () async => (await t.receiving(wallet, AddressType.p2wpkh)).length > 1,
      'a new native SegWit address',
    );
    await t.clearAddress();
    await t.chooseFromStack(wallet);
    await t.waitForAddress(segwitAddress1);
    saved = await t.receiving(wallet, AddressType.p2wpkh);
    expect(saved.map((e) => e.value), [segwitAddress0, segwitAddress1]);
    expect(saved.last.derivationPath!.value, "m/84'/0'/0'/0/1");
    expect(wallet.info.cachedReceivingAddress, taprootAddress0);
  });
}

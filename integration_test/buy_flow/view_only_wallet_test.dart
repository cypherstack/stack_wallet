import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/address.dart';

import 'harness.dart';

void main() {
  buyFlowTest('a view only wallet is used as is, or declined when it only '
      'has Taproot addresses', (t) async {
    await t.launch();
    final seed = await t.addWallet('Seed wallet');
    final xPubs = (await seed.getXPubs()).xpubs;
    final segwit = await t.addViewOnlyWallet(
      'View only SegWit',
      xPubs.singleWhere((e) => e.path == "m/84'/0'/0'"),
    );
    final taproot = await t.addViewOnlyWallet(
      'View only Taproot',
      xPubs.singleWhere((e) => e.path == "m/86'/0'/0'"),
    );
    await t.openBuy();

    // Its own address is not Taproot, so it is used as is.
    await t.chooseFromStack(segwit);
    await t.waitForAddress(segwitAddress0);

    // A view only wallet has the public key of one derivation path, so a
    // Taproot one cannot derive the BIP84 address the form needs.
    await t.chooseFromStack(taproot);
    final title = find.text('Wallet not supported');
    await t.ui.waitFor(title, description: 'view only Taproot dialog');
    expect(t.formTakesInput, isFalse);
    expect(
      find.textContaining('a view only Taproot wallet has no other address'),
      findsOneWidget,
    );

    // OK closes the dialog and nothing else.
    t.ui.stage = 'close the dialog';
    await t.ui.tapText('OK');
    await t.ui.until(() => title.evaluate().isEmpty, 'the dialog to close');
    expect(t.formTakesInput, isTrue);
    expect(t.address, segwitAddress0);
    expect(await t.receiving(taproot, AddressType.p2wpkh), isEmpty);

    // The form still works afterwards.
    await t.clearAddress();
    await t.chooseFromStack(segwit);
    await t.waitForAddress(segwitAddress0);
  });
}

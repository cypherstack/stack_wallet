import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:grin/grin.dart';
import 'package:isar_community/isar.dart';
import 'package:stackwallet/utilities/amount/amount.dart';
import 'package:stackwallet/wallets/wallet/impl/grin_wallet.dart';
import 'package:stackwallet/wallets/wallet/supporting/grin/grin_errors.dart';

import '../support/grin_fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory dataRoot;
  late Directory isarRoot;
  late Isar isar;
  late GrinHarness h;

  setUpAll(() async => dataRoot = await setUpGrinTests());
  tearDownAll(() => dataRoot.delete(recursive: true));
  setUp(() async {
    isarRoot = await Directory.systemTemp.createTemp('stack_grin_isar_');
    isar = await openTestIsar(isarRoot);
    h = await GrinHarness.create();
    await h.wallet.init();
  });
  tearDown(() async {
    await h.dispose();
    await isar.close();
    await isarRoot.delete(recursive: true);
  });

  Amount grin(int nano) =>
      Amount(rawValue: BigInt.from(nano), fractionDigits: 9);

  test('an amount mismatch never reaches processInvoice', () async {
    h.backend.api.decoded = slateInfoOf(GrinSlateState.i1, amount: 2000);
    await expectLater(
      h.wallet.processInvoice('i1', confirmedAmount: grin(1000)),
      throwsA(isA<GrinWalletException>()),
    );
    expect(h.backend.api.calls, isNot(contains('processInvoice')));
  });

  test('a slate that is not an I1 never reaches processInvoice', () async {
    for (final state in [GrinSlateState.s1, GrinSlateState.i2]) {
      h.backend.api.decoded = slateInfoOf(state, amount: 1000);
      await expectLater(
        h.wallet.processInvoice('x', confirmedAmount: grin(1000)),
        throwsA(isA<GrinWalletException>()),
      );
    }
    expect(h.backend.api.calls, isNot(contains('processInvoice')));
  });

  test('an unreadable invoice never reaches processInvoice', () async {
    h.backend.api.decoded = null;
    await expectLater(
      h.wallet.processInvoice('garbage', confirmedAmount: grin(1000)),
      throwsA(isA<GrinWalletException>()),
    );
    expect(h.backend.api.calls, isNot(contains('processInvoice')));
  });

  test(
    'a match pays with the expected amount, TTL and confirmations',
    () async {
      h.backend.api.decoded = slateInfoOf(GrinSlateState.i1, amount: 1000);
      final i2 = await h.wallet.processInvoice(
        'i1',
        confirmedAmount: grin(1000),
      );
      expect(i2.state, GrinSlateState.i2);
      final args = h.backend.api.invoicePayments.single;
      expect(args.expectedAmount, BigInt.from(1000));
      expect(args.ttlBlocks, GrinWallet.slatepackTtlBlocks);
      expect(args.minimumConfirmations, 10);
    },
  );

  test('issuing and finalizing an invoice', () async {
    final i1 = await h.wallet.issueInvoice(
      amount: grin(1000),
      payerAddress: 'grin1payer',
    );
    expect(i1.state, GrinSlateState.i1);
    final done = await h.wallet.finalizeInvoice('i2');
    expect(done.posted, isTrue);
  });
}

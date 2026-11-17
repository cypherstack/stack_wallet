import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:grin_native/grin_native.dart';
import 'package:isar_community/isar.dart';
import 'package:stackwallet/models/slatepack_models.dart';
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
    final result = await h.wallet.processInvoice(
      'i1',
      confirmedAmount: grin(1000),
    );
    expect(result.success, isFalse);
    expect(result.error, contains('does not match'));
    expect(h.backend.api.calls, isNot(contains('processInvoice')));
  });

  test('a slate that is not an I1 never reaches processInvoice', () async {
    for (final state in [GrinSlateState.s1, GrinSlateState.i2]) {
      h.backend.api.decoded = slateInfoOf(state, amount: 1000);
      final result = await h.wallet.processInvoice(
        'x',
        confirmedAmount: grin(1000),
      );
      expect(result.success, isFalse);
    }
    expect(h.backend.api.calls, isNot(contains('processInvoice')));
  });

  test('an unreadable invoice never reaches processInvoice', () async {
    h.backend.api.decoded = null;
    final result = await h.wallet.processInvoice(
      'garbage',
      confirmedAmount: grin(1000),
    );
    expect(result.success, isFalse);
    expect(result.error, isNot(contains(remoteText)));
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
      expect(i2.success, isTrue);
      expect(i2.state, SlateState.i2);
      expect(i2.slatepack, startsWith('BEGINSLATEPACK.'));
      expect((await h.wallet.localTxForSlate(i2.slateId!))?.isSend, isTrue);
      final args = h.backend.api.invoicePayments.single;
      expect(args.expectedAmount, BigInt.from(1000));
      expect(args.ttlBlocks, GrinWallet.slatepackTtlBlocks);
      expect(args.minimumConfirmations, 10);
    },
  );

  test('a payment that failed after it was recorded names its slate', () async {
    final api = h.backend.api;
    api.decoded = slateInfoOf(GrinSlateState.i1, amount: 1000);
    api.invoiceError = grinError(11, details: {'slate_id': 'slate-p'});
    final kept = await h.wallet.processInvoice(
      'i1',
      confirmedAmount: grin(1000),
    );
    expect(kept.success, isFalse);
    expect(kept.slateId, 'slate-p');
    expect(kept.error, contains(grinLeftPendingNote));
    expect(kept.error, isNot(contains(remoteText)));

    api.invoiceError = grinError(11);
    final nothing = await h.wallet.processInvoice(
      'i1',
      confirmedAmount: grin(1000),
    );
    expect(nothing.success, isFalse);
    expect(nothing.slateId, isNull);
  });

  test('issuing and finalizing an invoice', () async {
    final i1 = await h.wallet.issueInvoice(
      amount: grin(1000),
      payerAddress: 'grin1payer',
    );
    expect(i1.state, SlateState.i1);
    expect(i1.amount, grin(1000));
    expect((await h.wallet.localTxForSlate(i1.slateId!))?.isSend, isFalse);
    final done = await h.wallet.finalizeInvoice('i2');
    expect(done.success, isTrue);
    expect(done.posted, isTrue);
    expect(done.kernelExcess, '08ab');
  });
}

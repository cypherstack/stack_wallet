import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/address.dart';
import 'package:stackwallet/services/event_bus/events/global/tor_connection_status_changed_event.dart';
import 'package:stackwallet/utilities/amount/amount.dart';
import 'package:stackwallet/wallets/models/tx_data.dart';
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
  });
  tearDown(() async {
    await h.dispose();
    await isar.close();
    await isarRoot.delete(recursive: true);
  });

  Amount grin(int nano) =>
      Amount(rawValue: BigInt.from(nano), fractionDigits: 9);

  TxData send(
    String address, {
    SlatepackMethod? method,
    bool clearnetAck = false,
    bool plaintextAck = false,
  }) => TxData(
    recipients: [
      TxRecipient(
        address: address,
        amount: grin(1000000000),
        isChange: false,
        addressType: AddressType.mimbleWimble,
      ),
    ],
    slatepackMethod: method,
    grinClearnetAcknowledged: clearnetAck,
    grinPlaintextAcknowledged: plaintextAck,
  );

  Future<void> torOn() async {
    h.prefs.tor = true;
    h.tor.current = TorConnectionStatus.connected;
  }

  test('a slatepack send to a grin1 address is encrypted, asks for a proof '
      'and expires', () async {
    await h.wallet.init();
    final prepared = await h.wallet.prepareSend(txData: send('grin1friend'));
    expect(prepared.slatepackMethod, SlatepackMethod.slatepack);
    expect(prepared.fee, grin(23500000));
    final sent = await h.wallet.confirmSend(txData: prepared);
    final args = h.backend.api.initSends.single;
    expect(args.recipientAddress, 'grin1friend');
    expect(args.ttlBlocks, GrinWallet.slatepackTtlBlocks);
    expect(args.minimumConfirmations, 10);
    expect(sent.txid, 'slate-S1');
    expect(sent.slatepack, startsWith('BEGINSLATEPACK.'));
    expect(sent.toString(), isNot(contains('BEGINSLATEPACK')));
    expect(h.backend.api.httpSends, isEmpty);
  });

  test('a plain slatepack send has no recipient address', () async {
    await h.wallet.init();
    final prepared = await h.wallet.prepareSend(
      txData: send('', method: SlatepackMethod.slatepack),
    );
    await h.wallet.confirmSend(txData: prepared);
    expect(h.backend.api.initSends.single.recipientAddress, isNull);
  });

  test('an onion or grin1 HTTP send without Tor is refused before anything '
      'happens', () async {
    await h.wallet.init();
    for (final target in ['http://abc.onion', 'grin1friend']) {
      await expectLater(
        h.wallet.confirmSend(
          txData: send(target, method: SlatepackMethod.http),
        ),
        throwsA(isA<GrinWalletException>()),
        reason: target,
      );
    }
    expect(h.backend.api.httpSends, isEmpty);
  });

  test('a clearnet send with Tor off needs the IP disclosure accepted',
      () async {
    await h.wallet.init();
    await expectLater(
      h.wallet.confirmSend(txData: send('https://wallet.example')),
      throwsA(isA<GrinWalletException>()),
    );
    expect(h.backend.api.httpSends, isEmpty);

    await h.wallet.confirmSend(
      txData: send('https://wallet.example', clearnetAck: true),
    );
    final args = h.backend.api.httpSends.single;
    expect(args.post, isTrue);
    expect(args.ttlBlocks, GrinWallet.slatepackTtlBlocks);
  });

  test('http:// needs the plaintext warning even over Tor', () async {
    await torOn();
    await h.wallet.init();
    await expectLater(
      h.wallet.confirmSend(txData: send('http://wallet.example')),
      throwsA(isA<GrinWalletException>()),
    );
    expect(h.backend.api.httpSends, isEmpty);
    await h.wallet.confirmSend(
      txData: send('http://wallet.example', plaintextAck: true),
    );
    expect(h.backend.api.httpSends, hasLength(1));
  });

  test('Tor on but down refuses an HTTP send even with the kill switch off',
      () async {
    h.prefs.tor = true;
    h.prefs.killSwitch = false;
    h.tor.current = TorConnectionStatus.disconnected;
    await h.wallet.init();
    await expectLater(
      h.wallet.confirmSend(
        txData: send(
          'https://wallet.example',
          clearnetAck: true,
          plaintextAck: true,
        ),
      ),
      throwsA(isA<GrinWalletException>()),
    );
    expect(h.backend.api.httpSends, isEmpty);
  });

  test('an onion send over Tor goes out', () async {
    await torOn();
    await h.wallet.init();
    await h.wallet.confirmSend(txData: send('http://abc.onion'));
    expect(h.backend.api.httpSends.single.recipientUrlOrAddress,
        'http://abc.onion');
  });

  test('send all takes the fee out of the amount', () async {
    await h.wallet.init();
    final prepared = await h.wallet.prepareSend(
      txData: send('grin1friend').copyWith(subtractFeeFromAmount: true),
    );
    expect(prepared.recipients!.single.amount,
        grin(1000000000 - 23500000));
    await h.wallet.confirmSend(txData: prepared);
    final args = h.backend.api.initSends.single;
    expect(args.amount, BigInt.from(1000000000));
    expect(args.amountIncludesFee, isTrue);
    expect(args.selectionStrategyIsAll, isTrue);
  });

  test('a slatepack can only be encrypted to a grin1 address', () async {
    await h.wallet.init();
    await expectLater(
      h.wallet.prepareSend(
        txData: send('https://x.example', method: SlatepackMethod.slatepack),
      ),
      throwsA(isA<GrinWalletException>()),
    );
  });

  test('insufficient funds becomes InsufficientBalanceException', () async {
    await h.wallet.init();
    h.backend.api.estimateError = grinError(10);
    await expectLater(
      h.wallet.estimateFeeFor(grin(5), BigInt.one),
      throwsA(
        isA<Exception>().having(
          (e) => e.runtimeType.toString(),
          'type',
          'InsufficientBalanceException',
        ),
      ),
    );
    expect(await h.wallet.estimateFeeFor(grin(0), BigInt.one), grin(0));
  });
}

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/address.dart';

import 'package:stackwallet/utilities/amount/amount.dart';
import 'package:stackwallet/wallets/models/tx_data.dart';
import 'package:stackwallet/wl_gen/interfaces/lib_xelis_interface.dart';

import 'support/xelis_test_fakes.dart';

void main() {
  Amount amount(int raw) =>
      Amount(rawValue: BigInt.from(raw), fractionDigits: 8);
  TxData request({bool max = false}) => TxData(
    recipients: [
      TxRecipient(
        address: 'integrated-destination',
        amount: amount(100),
        isChange: false,
        addressType: AddressType.xelis,
      ),
    ],
    xelisSendAll: max,
  );
  late FakeNative native;
  late TestWallet wallet;
  setUp(() {
    native = FakeNative();
    wallet = TestWallet(native);
  });

  test('review keeps the integrated destination '
      'and broadcasts its exact capability once', () async {
    final reviewed = await wallet.prepareSend(txData: request());
    expect(reviewed.recipients!.single.address, 'integrated-destination');
    final result = await wallet.confirmSend(txData: reviewed);
    expect(result.txid, reviewed.xelisPreparedTransaction!.hash);
    expect(native.broadcast.single, same(reviewed.xelisPreparedTransaction));
    await expectLater(wallet.confirmSend(txData: reviewed), throwsStateError);
  });

  test('review edits and a closed session cannot broadcast', () async {
    final reviewed = await wallet.prepareSend(txData: request());
    await expectLater(
      wallet.confirmSend(txData: reviewed.copyWith(fee: amount(8))),
      throwsStateError,
    );
    await expectLater(
      wallet.confirmSend(
        txData: reviewed.copyWith(
          recipients: [
            TxRecipient(
              address: 'different-destination',
              amount: amount(100),
              isChange: false,
              addressType: AddressType.xelis,
            ),
          ],
        ),
      ),
      throwsStateError,
    );
    ++wallet.sessionGeneration;
    wallet.wallet = const OpaqueXelisWallet(Object());
    // A replaced handle must invalidate preparation even if TxData survives.
    await expectLater(wallet.confirmSend(txData: reviewed), throwsStateError);
    expect(native.broadcast, isEmpty);
  });

  test('max uses the native maximum and its reviewed amount', () async {
    final reviewed = await wallet.prepareSend(txData: request(max: true));
    expect(native.usedMax, isTrue);
    expect(reviewed.recipients!.single.amount.raw, BigInt.from(93));
    expect(reviewed.fee!.raw, BigInt.from(7));
  });

  test(
    'retryable preserves capability; submitted-needs-resync consumes it',
    () async {
      final reviewed = await wallet.prepareSend(txData: request());
      final failure = StateError('structured failure stand-in');
      native.outcome = XelisBroadcastOutcome(
        XelisBroadcastDisposition.retryable,
        failure: failure,
      );
      await expectLater(
        wallet.confirmSend(txData: reviewed),
        throwsA(same(failure)),
      );
      native.outcome = const XelisBroadcastOutcome(
        XelisBroadcastDisposition.submittedNeedsResync,
      );
      await wallet.confirmSend(txData: reviewed);
      expect(
        native.broadcast,
        everyElement(same(reviewed.xelisPreparedTransaction)),
      );
      await expectLater(wallet.confirmSend(txData: reviewed), throwsStateError);
    },
  );

  test('cancelled review discards native preparation', () async {
    final reviewed = await wallet.prepareSend(txData: request());
    await wallet.cancelSend(txData: reviewed);
    expect(native.discarded.single, same(reviewed.xelisPreparedTransaction));
    await expectLater(wallet.confirmSend(txData: reviewed), throwsStateError);
  });

  test('closing waits for an in-flight broadcast to settle', () async {
    final reviewed = await wallet.prepareSend(txData: request());
    native.pendingBroadcast = Completer<XelisBroadcastOutcome>();
    final send = wallet.confirmSend(txData: reviewed);
    await Future<void>.delayed(Duration.zero);
    wallet.exitInProgress = true;
    ++wallet.sessionGeneration;
    var drained = false;
    final closing = wallet.drainSessionOperations().then((_) => drained = true);
    await Future<void>.delayed(Duration.zero);
    expect(drained, isFalse);
    native.pendingBroadcast!.complete(
      const XelisBroadcastOutcome(XelisBroadcastDisposition.submitted),
    );
    expect((await send).txid, reviewed.xelisPreparedTransaction!.hash);
    await closing;
    expect(drained, isTrue);
  });
}

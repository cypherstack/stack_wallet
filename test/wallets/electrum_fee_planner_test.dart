import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/wallets/wallet/wallet_mixin_interfaces/electrum_fee_planner.dart';

typedef _Payment = ({BigInt recipientAmount, BigInt? changeAmount});

Future<({ElectrumFeeResult<_Payment> result, List<_Payment> builds})> _plan({
  required ElectrumFeeMode mode,
  required int inputTotal,
  required int recipientAmount,
  required int dustLimit,
  required List<int> vSizes,
  int? satsPerVByte = 1,
  int feeRatePerKB = 1000,
  int? minimumFeeAmount,
}) async {
  final builds = <_Payment>[];
  var buildIndex = 0;
  final result = await planElectrumFee<_Payment>(
    mode: mode,
    inputTotal: BigInt.from(inputTotal),
    recipientAmount: BigInt.from(recipientAmount),
    dustLimit: BigInt.from(dustLimit),
    satsPerVByte: satsPerVByte,
    feeRatePerKB: BigInt.from(feeRatePerKB),
    minimumFeeAmount: minimumFeeAmount == null
        ? null
        : BigInt.from(minimumFeeAmount),
    build: ({required recipientAmount, changeAmount}) async {
      final payment = (
        recipientAmount: recipientAmount,
        changeAmount: changeAmount,
      );
      builds.add(payment);
      final vSize =
          vSizes[buildIndex < vSizes.length ? buildIndex++ : vSizes.length - 1];
      return (transaction: payment, vSize: vSize);
    },
  );
  return (result: result, builds: builds);
}

void main() {
  test('keeps the larger fee when measured vsize shrinks', () async {
    final plan = await _plan(
      mode: ElectrumFeeMode.sweep,
      inputTotal: 10000,
      recipientAmount: 10000,
      dustLimit: 546,
      vSizes: [192, 191],
    );

    expect(plan.result.fee, BigInt.from(192));
    expect(plan.result.transaction.recipientAmount, BigInt.from(9808));
    expect(plan.builds.length, 2);
  });

  test('rounds per-kilobyte fees up', () async {
    final plan = await _plan(
      mode: ElectrumFeeMode.sweep,
      inputTotal: 10000,
      recipientAmount: 10000,
      dustLimit: 546,
      vSizes: [191],
      satsPerVByte: null,
      feeRatePerKB: 1001,
    );

    expect(plan.result.fee, BigInt.from(192));
  });

  test('does not let a minimum fee underpay the measured vsize', () async {
    final plan = await _plan(
      mode: ElectrumFeeMode.sweep,
      inputTotal: 10000,
      recipientAmount: 10000,
      dustLimit: 546,
      vSizes: [225],
      satsPerVByte: null,
      feeRatePerKB: 0,
      minimumFeeAmount: 100,
    );

    expect(plan.result.fee, BigInt.from(225));
  });

  test('keeps exact-dust fixed change after vsize shrinks', () async {
    final plan = await _plan(
      mode: ElectrumFeeMode.fixedAmount,
      inputTotal: 1319,
      recipientAmount: 547,
      dustLimit: 546,
      vSizes: [226, 225],
    );

    expect(plan.result.fee, BigInt.from(226));
    expect(plan.result.transaction.recipientAmount, BigInt.from(547));
    expect(plan.result.transaction.changeAmount, BigInt.from(546));
  });

  test('accepts an exact-dust fixed recipient', () async {
    final plan = await _plan(
      mode: ElectrumFeeMode.fixedAmount,
      inputTotal: 772,
      recipientAmount: 546,
      dustLimit: 546,
      vSizes: [226],
    );

    expect(plan.result.fee, BigInt.from(226));
    expect(plan.result.transaction.recipientAmount, BigInt.from(546));
  });

  test('subtracts the fee and preserves change', () async {
    final plan = await _plan(
      mode: ElectrumFeeMode.subtractFeeFromAmount,
      inputTotal: 10000,
      recipientAmount: 6000,
      dustLimit: 546,
      vSizes: [225],
    );

    expect(plan.result.fee, BigInt.from(225));
    expect(plan.result.transaction.recipientAmount, BigInt.from(5775));
    expect(plan.result.transaction.changeAmount, BigInt.from(4000));
  });

  test('uses a sub-dust surplus toward the subtracted fee', () async {
    final plan = await _plan(
      mode: ElectrumFeeMode.subtractFeeFromAmount,
      inputTotal: 10000,
      recipientAmount: 9900,
      dustLimit: 546,
      vSizes: [225],
    );

    expect(plan.result.fee, BigInt.from(225));
    expect(plan.result.transaction.recipientAmount, BigInt.from(9775));
    expect(plan.result.transaction.changeAmount, isNull);
  });

  test('uses an equal sub-dust surplus as the fee', () async {
    final plan = await _plan(
      mode: ElectrumFeeMode.subtractFeeFromAmount,
      inputTotal: 10000,
      recipientAmount: 9775,
      dustLimit: 546,
      vSizes: [225],
    );

    expect(plan.result.fee, BigInt.from(225));
    expect(plan.result.transaction.recipientAmount, BigInt.from(9775));
    expect(plan.result.transaction.changeAmount, isNull);
  });

  test('returns excess sub-dust surplus to the recipient', () async {
    final plan = await _plan(
      mode: ElectrumFeeMode.subtractFeeFromAmount,
      inputTotal: 10000,
      recipientAmount: 9700,
      dustLimit: 546,
      vSizes: [225],
    );

    expect(plan.result.fee, BigInt.from(225));
    expect(plan.result.transaction.recipientAmount, BigInt.from(9775));
    expect(plan.result.transaction.changeAmount, isNull);
  });

  test('fixed mode requests another input when the fee is short', () {
    expect(
      _plan(
        mode: ElectrumFeeMode.fixedAmount,
        inputTotal: 10000,
        recipientAmount: 9900,
        dustLimit: 546,
        vSizes: [225],
      ),
      throwsA(
        isA<ElectrumFeeInsufficientFunds>().having(
          (e) => e.requiredFee,
          'requiredFee',
          BigInt.from(225),
        ),
      ),
    );
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/wallets/wallet/wallet_mixin_interfaces/mweb_fee_utils.dart';

void main() {
  group('effectiveMwebFeeRatePerKB', () {
    test('clamps a preset rate below 1000', () {
      expect(
        effectiveMwebFeeRatePerKB(
          feeRatePerKB: BigInt.from(997),
          satsPerVByte: null,
        ),
        BigInt.from(1000),
      );
    });

    test('preserves an exact preset rate above 1000', () {
      expect(
        effectiveMwebFeeRatePerKB(
          feeRatePerKB: BigInt.from(1001),
          satsPerVByte: null,
        ),
        BigInt.from(1001),
      );
    });

    test('uses custom sats per vByte instead of the preset sentinel', () {
      expect(
        effectiveMwebFeeRatePerKB(
          feeRatePerKB: BigInt.from(-1),
          satsPerVByte: 2,
        ),
        BigInt.from(2000),
      );
    });

    test('also clamps a custom rate below the minimum', () {
      expect(
        effectiveMwebFeeRatePerKB(
          feeRatePerKB: BigInt.from(-1),
          satsPerVByte: 0,
        ),
        BigInt.from(1000),
      );
    });
  });

  group('requiredMwebFee', () {
    test('raises the fee when a second MWEB output is added', () {
      final firstFee = requiredMwebFee(
        currentFee: BigInt.from(200),
        feeIncrease: BigInt.from(1900),
        hasPegin: false,
        vSize: 100,
        feeRatePerKB: BigInt.from(1000),
      );
      final secondFee = requiredMwebFee(
        currentFee: firstFee,
        feeIncrease: BigInt.from(1800),
        hasPegin: false,
        vSize: 150,
        feeRatePerKB: BigInt.from(1000),
      );
      final finalFee = requiredMwebFee(
        currentFee: secondFee,
        feeIncrease: BigInt.zero,
        hasPegin: false,
        vSize: 150,
        feeRatePerKB: BigInt.from(1000),
      );

      expect(
        [firstFee, secondFee, finalFee],
        [BigInt.from(2100), BigInt.from(3900), BigInt.from(3900)],
      );
    });

    // A rate of 5001 over 250 vBytes keeps the rate based fee (1251) clear of
    // the vSize floor and rounds up, so both are pinned.
    test('does not add the MWEB fee again when recalculating a peg-in', () {
      final initialFee = requiredMwebFee(
        currentFee: BigInt.from(100),
        feeIncrease: BigInt.from(2141),
        hasPegin: true,
        vSize: 250,
        feeRatePerKB: BigInt.from(5001),
      );
      final recalculatedFee = requiredMwebFee(
        currentFee: initialFee,
        feeIncrease: BigInt.from(2141),
        hasPegin: true,
        vSize: 250,
        feeRatePerKB: BigInt.from(5001),
      );

      expect(initialFee, BigInt.from(3392));
      expect(recalculatedFee, initialFee);
    });
  });

  test(
    'reconciles from the original candidate and forwards the fee rate',
    () async {
      final requiredFees = [2100, 3900, 3900];
      final paidFees = [200, 2100, 3900];
      final minimumFees = <BigInt>[];
      final calculationRates = <BigInt>[];
      final feeRatePerKB = BigInt.from(1001);
      final original = (pass: 0, feeRateAmount: BigInt.from(-1));
      BigInt? processingRate;
      var nextCandidate = 1;

      final result = await processWithReconciledMwebFee(
        initial: original,
        feeRatePerKB: feeRatePerKB,
        paidFee: (candidate) => BigInt.from(paidFees[candidate.pass]),
        requiredFee: (candidate, feeRatePerKB) async {
          calculationRates.add(feeRatePerKB);
          return BigInt.from(requiredFees[candidate.pass]);
        },
        rebuild: (initial, minimumFee) async {
          expect(initial, original);
          minimumFees.add(minimumFee);
          return (pass: nextCandidate++, feeRateAmount: initial.feeRateAmount);
        },
        process: (candidate, feeRatePerKB) async {
          processingRate = feeRatePerKB;
          return candidate;
        },
      );

      expect(result.pass, 2);
      expect(result.feeRateAmount, BigInt.from(-1));
      expect(minimumFees, [BigInt.from(2100), BigInt.from(3900)]);
      expect(calculationRates, [feeRatePerKB, feeRatePerKB, feeRatePerKB]);
      expect(processingRate, feeRatePerKB);
    },
  );

  test('processes the first candidate without rebuilding it', () async {
    final feeRatePerKB = BigInt.from(1001);
    final original = (pass: 0, feeRateAmount: BigInt.from(-1));
    var requiredFeeCalls = 0;
    var rebuilds = 0;

    final result = await processWithReconciledMwebFee(
      initial: original,
      feeRatePerKB: feeRatePerKB,
      paidFee: (candidate) => BigInt.from(3900),
      requiredFee: (candidate, feeRatePerKB) async {
        requiredFeeCalls += 1;
        return BigInt.from(2100);
      },
      rebuild: (initial, minimumFee) async {
        rebuilds += 1;
        return (pass: 1, feeRateAmount: initial.feeRateAmount);
      },
      process: (candidate, feeRatePerKB) async => candidate,
    );

    expect(result, original);
    expect(requiredFeeCalls, 1);
    expect(rebuilds, 0);
  });
}

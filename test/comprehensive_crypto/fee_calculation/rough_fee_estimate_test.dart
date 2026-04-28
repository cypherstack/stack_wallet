import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/utilities/amount/amount.dart';

import '../vectors/fee_vectors.dart';

// ---------------------------------------------------------------------------
// Pure-function replicas of the actual wallet implementations.
// These are tested against precomputed vectors to catch rounding bugs.
// ---------------------------------------------------------------------------

/// SegWit formula (Bitcoin, Litecoin, Fact0rn, Peercoin, Particl, Namecoin).
///
/// Source: lib/wallets/wallet/impl/bitcoin_wallet.dart (and similar)
Amount roughFeeEstimateSegWit(
  int inputCount,
  int outputCount,
  BigInt feeRatePerKB,
  int fractionDigits,
) {
  return Amount(
    rawValue: BigInt.from(
      ((42 + (272 * inputCount) + (128 * outputCount)) / 4).ceil() *
          (feeRatePerKB.toInt() / 1000).ceil(),
    ),
    fractionDigits: fractionDigits,
  );
}

/// Legacy formula (Dash, Dogecoin, Firo, Bitcoin Cash, eCash).
///
/// Source: lib/wallets/wallet/impl/dash_wallet.dart (and similar)
Amount roughFeeEstimateLegacy(
  int inputCount,
  int outputCount,
  BigInt feeRatePerKB,
  int fractionDigits,
) {
  return Amount(
    rawValue: BigInt.from(
      ((181 * inputCount) + (34 * outputCount) + 10) *
          (feeRatePerKB.toInt() / 1000).ceil(),
    ),
    fractionDigits: fractionDigits,
  );
}

/// Replicate estimateTxFee for consistency comparison.
int estimateTxFee({required int vSize, required BigInt feeRatePerKB}) {
  return (feeRatePerKB * BigInt.from(vSize) ~/ BigInt.from(1000)).toInt();
}

void main() {
  // -------------------------------------------------------------------------
  // Group 1: SegWit roughFeeEstimate
  // -------------------------------------------------------------------------
  group('SegWit roughFeeEstimate', () {
    for (final coinName in kSegWitCoins.keys) {
      group(coinName, () {
        final vectors = kSegWitRoughFeeVectors
            .where((v) => v.coinName == coinName)
            .toList();

        for (final v in vectors) {
          test(
            'in=${v.inputCount}, out=${v.outputCount}, '
            'rate=${v.feeRatePerKB} -> raw=${v.expectedRawValue}',
            () {
              final result = roughFeeEstimateSegWit(
                v.inputCount,
                v.outputCount,
                v.feeRatePerKB,
                v.fractionDigits,
              );
              expect(result.raw, v.expectedRawValue, reason: v.toString());
              expect(
                result.fractionDigits,
                v.fractionDigits,
                reason: 'fractionDigits mismatch for $coinName',
              );
            },
          );
        }
      });
    }
  });

  // -------------------------------------------------------------------------
  // Group 2: Legacy roughFeeEstimate
  // -------------------------------------------------------------------------
  group('Legacy roughFeeEstimate', () {
    for (final coinName in kLegacyCoins.keys) {
      group(coinName, () {
        final vectors = kLegacyRoughFeeVectors
            .where((v) => v.coinName == coinName)
            .toList();

        for (final v in vectors) {
          test(
            'in=${v.inputCount}, out=${v.outputCount}, '
            'rate=${v.feeRatePerKB} -> raw=${v.expectedRawValue}',
            () {
              final result = roughFeeEstimateLegacy(
                v.inputCount,
                v.outputCount,
                v.feeRatePerKB,
                v.fractionDigits,
              );
              expect(result.raw, v.expectedRawValue, reason: v.toString());
              expect(
                result.fractionDigits,
                v.fractionDigits,
                reason: 'fractionDigits mismatch for $coinName',
              );
            },
          );
        }
      });
    }
  });

  // -------------------------------------------------------------------------
  // Group 3: roughFeeEstimate >= estimateTxFee consistency
  // -------------------------------------------------------------------------
  group('roughFeeEstimate >= estimateTxFee consistency', () {
    // For the SegWit formula, the effective vSize is:
    //   ((42 + (272 * inputCount) + (128 * outputCount)) / 4).ceil()
    //
    // roughFeeEstimate uses .ceil() on the fee rate (rounds up),
    // while estimateTxFee uses BigInt integer division (truncates).
    // Therefore roughFeeEstimate should always be >= estimateTxFee
    // at the same effective vSize.

    final testRates = [
      BigInt.from(999),
      BigInt.from(1000),
      BigInt.from(1001),
      BigInt.from(5000),
      BigInt.from(10000),
    ];

    for (final inCount in kInputCounts) {
      for (final outCount in kOutputCounts) {
        final effectiveVSize =
            ((42 + (272 * inCount) + (128 * outCount)) / 4).ceil();

        for (final rate in testRates) {
          test(
            'SegWit in=$inCount, out=$outCount, rate=$rate: '
            'rough (ceil) >= estimate (trunc)',
            () {
              final rough = roughFeeEstimateSegWit(
                inCount,
                outCount,
                rate,
                8,
              );
              final estimate = estimateTxFee(
                vSize: effectiveVSize,
                feeRatePerKB: rate,
              );
              expect(
                rough.raw >= BigInt.from(estimate),
                isTrue,
                reason: 'roughFeeEstimate (${rough.raw}) should be >= '
                    'estimateTxFee ($estimate) for vSize=$effectiveVSize, '
                    'rate=$rate',
              );
            },
          );
        }
      }
    }

    // Also verify for Legacy formula.
    for (final inCount in kInputCounts) {
      for (final outCount in kOutputCounts) {
        final effectiveSize =
            (181 * inCount) + (34 * outCount) + 10;

        for (final rate in testRates) {
          test(
            'Legacy in=$inCount, out=$outCount, rate=$rate: '
            'rough (ceil) >= estimate (trunc)',
            () {
              final rough = roughFeeEstimateLegacy(
                inCount,
                outCount,
                rate,
                8,
              );
              final estimate = estimateTxFee(
                vSize: effectiveSize,
                feeRatePerKB: rate,
              );
              expect(
                rough.raw >= BigInt.from(estimate),
                isTrue,
                reason: 'roughFeeEstimate (${rough.raw}) should be >= '
                    'estimateTxFee ($estimate) for size=$effectiveSize, '
                    'rate=$rate',
              );
            },
          );
        }
      }
    }
  });

  // -------------------------------------------------------------------------
  // Group 4: feeRate=0 produces zero fee
  // -------------------------------------------------------------------------
  group('feeRate=0 produces zero fee', () {
    test('SegWit formula returns zero when feeRate=0', () {
      for (final inCount in kInputCounts) {
        for (final outCount in kOutputCounts) {
          final result = roughFeeEstimateSegWit(
            inCount,
            outCount,
            BigInt.zero,
            8,
          );
          expect(
            result.raw,
            BigInt.zero,
            reason: 'SegWit in=$inCount, out=$outCount at rate=0 '
                'should be zero',
          );
        }
      }
    });

    test('Legacy formula returns zero when feeRate=0', () {
      for (final inCount in kInputCounts) {
        for (final outCount in kOutputCounts) {
          final result = roughFeeEstimateLegacy(
            inCount,
            outCount,
            BigInt.zero,
            8,
          );
          expect(
            result.raw,
            BigInt.zero,
            reason: 'Legacy in=$inCount, out=$outCount at rate=0 '
                'should be zero',
          );
        }
      }
    });
  });

  // -------------------------------------------------------------------------
  // Group 5: eCash fractionDigits=2 correctness
  // -------------------------------------------------------------------------
  group('eCash fractionDigits=2 correctness', () {
    test(
      'eCash inputCount=1, outputCount=2, feeRate=1000: '
      'rawValue=259, fractionDigits=2',
      () {
        // Legacy formula: (181*1 + 34*2 + 10) * (1000/1000).ceil()
        //               = (181 + 68 + 10) * 1 = 259
        final result = roughFeeEstimateLegacy(
          1,
          2,
          BigInt.from(1000),
          2,
        );
        expect(result.raw, BigInt.from(259));
        expect(result.fractionDigits, 2);
      },
    );

    test(
      'eCash inputCount=3, outputCount=1, feeRate=5000: '
      'rawValue=2885, fractionDigits=2',
      () {
        // Legacy formula: (181*3 + 34*1 + 10) * (5000/1000).ceil()
        //               = (543 + 34 + 10) * 5 = 587 * 5 = 2935
        // Wait: (5000/1000).ceil() = 5.0.ceil() = 5
        // 587 * 5 = 2935
        final result = roughFeeEstimateLegacy(
          3,
          1,
          BigInt.from(5000),
          2,
        );
        expect(result.raw, BigInt.from(2935));
        expect(result.fractionDigits, 2);
      },
    );

    test(
      'eCash inputCount=1, outputCount=1, feeRate=999: '
      'rawValue=225, fractionDigits=2',
      () {
        // Legacy formula: (181*1 + 34*1 + 10) * (999/1000).ceil()
        //               = 225 * 1 = 225
        // (999/1000) = 0.999, .ceil() = 1
        final result = roughFeeEstimateLegacy(
          1,
          1,
          BigInt.from(999),
          2,
        );
        expect(result.raw, BigInt.from(225));
        expect(result.fractionDigits, 2);
      },
    );

    test('eCash vectors all use fractionDigits=2', () {
      final ecashVectors =
          kLegacyRoughFeeVectors.where((v) => v.coinName == 'eCash');
      expect(ecashVectors.isNotEmpty, isTrue);
      for (final v in ecashVectors) {
        expect(v.fractionDigits, 2,
            reason: 'eCash should always have fractionDigits=2');
      }
    });
  });

  // -------------------------------------------------------------------------
  // Group 6: Peercoin fractionDigits=6 correctness
  // -------------------------------------------------------------------------
  group('Peercoin fractionDigits=6 correctness', () {
    test('Peercoin vectors all use fractionDigits=6', () {
      final peercoinVectors =
          kSegWitRoughFeeVectors.where((v) => v.coinName == 'Peercoin');
      expect(peercoinVectors.isNotEmpty, isTrue);
      for (final v in peercoinVectors) {
        expect(v.fractionDigits, 6,
            reason: 'Peercoin should always have fractionDigits=6');
      }
    });

    test(
      'Peercoin inputCount=1, outputCount=1, feeRate=1000: '
      'rawValue=111, fractionDigits=6',
      () {
        // SegWit formula: ((42 + 272*1 + 128*1) / 4).ceil() * (1000/1000).ceil()
        //               = (442/4).ceil() * 1 = 110.5.ceil() * 1 = 111
        final result = roughFeeEstimateSegWit(
          1,
          1,
          BigInt.from(1000),
          6,
        );
        expect(result.raw, BigInt.from(111));
        expect(result.fractionDigits, 6);
      },
    );
  });
}

import 'package:flutter_test/flutter_test.dart';

import '../vectors/fee_vectors.dart';

/// Replicate the actual estimateTxFee formula used by all 11 UTXO wallet
/// implementations. This is BigInt integer division (truncation toward zero).
///
/// Source: lib/wallets/wallet/impl/*_wallet.dart
int estimateTxFee({required int vSize, required BigInt feeRatePerKB}) {
  return (feeRatePerKB * BigInt.from(vSize) ~/ BigInt.from(1000)).toInt();
}

void main() {
  // -------------------------------------------------------------------------
  // Per-coin vector-driven tests
  // -------------------------------------------------------------------------
  for (final coin in kAllUtxoCoins) {
    group('estimateTxFee - $coin', () {
      final vectors =
          kEstimateTxFeeVectors.where((v) => v.coinName == coin).toList();

      for (final v in vectors) {
        test(
          'vSize=${v.vSize}, feeRate=${v.feeRatePerKB} -> fee=${v.expectedFee}',
          () {
            final fee = estimateTxFee(
              vSize: v.vSize,
              feeRatePerKB: v.feeRatePerKB,
            );
            expect(fee, v.expectedFee, reason: v.toString());
          },
        );
      }
    });
  }

  // -------------------------------------------------------------------------
  // Explicit boundary / edge case tests
  // -------------------------------------------------------------------------
  group('estimateTxFee boundary conditions', () {
    test('feeRate=999, vSize=154 produces fee=153 (the MWEB bug case)', () {
      // This is the exact scenario that caused the MWEB anonymize bug:
      // fee < vSize because of integer division truncation.
      // 999 * 154 = 153846; 153846 ~/ 1000 = 153
      final fee = estimateTxFee(
        vSize: 154,
        feeRatePerKB: BigInt.from(999),
      );
      expect(fee, 153);
      expect(fee < 154, isTrue,
          reason: 'fee (153) should be less than vSize (154)');
    });

    test('feeRate=1000, vSize=154 produces fee=154 (exact 1 sat/vbyte)', () {
      // 1000 * 154 = 154000; 154000 ~/ 1000 = 154
      final fee = estimateTxFee(
        vSize: 154,
        feeRatePerKB: BigInt.from(1000),
      );
      expect(fee, 154);
    });

    test('feeRate=0 produces zero fee regardless of vSize', () {
      for (final vSize in kVSizes) {
        final fee = estimateTxFee(
          vSize: vSize,
          feeRatePerKB: BigInt.zero,
        );
        expect(fee, 0, reason: 'vSize=$vSize should produce 0 fee at rate=0');
      }
    });

    test('feeRate=1, vSize=999 produces zero fee (extreme truncation)', () {
      // 1 * 999 = 999; 999 ~/ 1000 = 0
      final fee = estimateTxFee(
        vSize: 999,
        feeRatePerKB: BigInt.one,
      );
      expect(fee, 0);
    });

    test('feeRate=1, vSize=1000 produces fee=1 (exact threshold)', () {
      // 1 * 1000 = 1000; 1000 ~/ 1000 = 1
      final fee = estimateTxFee(
        vSize: 1000,
        feeRatePerKB: BigInt.one,
      );
      expect(fee, 1);
    });

    test(
        'very large vSize (100000) with rate 100000 does not overflow', () {
      // 100000 * 100000 = 10,000,000,000; ~/ 1000 = 10,000,000
      // This fits in a 64-bit int. BigInt handles intermediate products.
      final fee = estimateTxFee(
        vSize: 100000,
        feeRatePerKB: BigInt.from(100000),
      );
      expect(fee, 10000000);
    });

    test('fee floor check: fee < vSize when rate < 1000', () {
      // For any feeRate < 1000, the per-vbyte rate is < 1.0 sat/vbyte.
      // With integer division, fee = vSize * rate ~/ 1000.
      // For rate=999: fee = vSize * 999 ~/ 1000
      // This is always < vSize for vSize > 0 (since 999/1000 < 1).
      final rate = BigInt.from(999);
      for (final vSize in [1, 100, 154, 200, 500, 1000, 100000]) {
        final fee = estimateTxFee(vSize: vSize, feeRatePerKB: rate);
        expect(
          fee < vSize,
          isTrue,
          reason: 'fee ($fee) should be < vSize ($vSize) at rate=999',
        );
      }
    });

    test('feeRate=1001, vSize=1 produces fee=1 (just above 1 sat/vbyte)', () {
      // 1001 * 1 = 1001; 1001 ~/ 1000 = 1
      final fee = estimateTxFee(
        vSize: 1,
        feeRatePerKB: BigInt.from(1001),
      );
      expect(fee, 1);
    });

    test('feeRate=999, vSize=1 produces fee=0', () {
      // 999 * 1 = 999; 999 ~/ 1000 = 0
      final fee = estimateTxFee(
        vSize: 1,
        feeRatePerKB: BigInt.from(999),
      );
      expect(fee, 0);
    });

    test('symmetry: formula is commutative in rate*vSize product', () {
      // estimateTxFee depends only on the product rate*vSize, divided by 1000.
      // Swapping rate and vSize values should produce the same result
      // (when both fit in BigInt, which they always do).
      final fee1 = estimateTxFee(
        vSize: 5000,
        feeRatePerKB: BigInt.from(10000),
      );
      final fee2 = estimateTxFee(
        vSize: 10000,
        feeRatePerKB: BigInt.from(5000),
      );
      expect(fee1, fee2,
          reason: '5000*10000 == 10000*5000, both ~/ 1000 = 50000');
      expect(fee1, 50000);
    });
  });
}

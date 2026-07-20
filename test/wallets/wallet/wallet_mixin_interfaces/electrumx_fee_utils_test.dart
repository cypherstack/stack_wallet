import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/wallets/wallet/wallet_mixin_interfaces/electrumx_fee_utils.dart';

void main() {
  group('feeRatePerKBFromCoinUnits', () {
    test('converts exact Litecoin fee rates to litoshis per kB', () {
      expect(
        feeRatePerKBFromCoinUnits(
          Decimal.parse('0.00000993'),
          fractionDigits: 8,
        ),
        BigInt.from(993),
      );
      expect(
        feeRatePerKBFromCoinUnits(
          Decimal.parse('0.00001000'),
          fractionDigits: 8,
        ),
        BigInt.from(1000),
      );
    });

    test('rounds fractional base units up', () {
      expect(
        feeRatePerKBFromCoinUnits(
          Decimal.parse('0.000009939'),
          fractionDigits: 8,
        ),
        BigInt.from(994),
      );
    });
  });

  group('clampFeeRatePerKB', () {
    test('raises an estimate to the relay floor', () {
      expect(
        clampFeeRatePerKB(
          feeRatePerKB: BigInt.from(993),
          minimumFeeRatePerKB: BigInt.from(1000),
        ),
        BigInt.from(1000),
      );
    });

    test('preserves an estimate above the relay floor', () {
      expect(
        clampFeeRatePerKB(
          feeRatePerKB: BigInt.from(1234),
          minimumFeeRatePerKB: BigInt.from(1000),
        ),
        BigInt.from(1234),
      );
    });
  });

  group('normalizeFeeRatePerKB', () {
    test('applies the Litecoin floor to a sub-floor server estimate', () {
      expect(
        normalizeFeeRatePerKB(
          feeRateInCoinUnits: Decimal.parse('0.00000993'),
          fractionDigits: 8,
          minimumFeeRatePerKB: BigInt.from(1000),
        ),
        BigInt.from(1000),
      );
    });

    test('does not impose a floor for currencies without one', () {
      expect(
        normalizeFeeRatePerKB(
          feeRateInCoinUnits: Decimal.parse('0.00000993'),
          fractionDigits: 8,
          minimumFeeRatePerKB: BigInt.zero,
        ),
        BigInt.from(993),
      );
    });
  });

  group('feeForVSize', () {
    test('does not underpay a relay-floor transaction', () {
      expect(feeForVSize(vSize: 276, feeRatePerKB: BigInt.from(1000)), 276);
    });

    test('rounds the absolute fee up without quantizing the fee rate', () {
      expect(feeForVSize(vSize: 276, feeRatePerKB: BigInt.from(1001)), 277);
    });

    test('shows why ceiling alone does not replace the relay floor', () {
      expect(feeForVSize(vSize: 276, feeRatePerKB: BigInt.from(993)), 275);
    });
  });

  group('effectiveMwebFeeRatePerKB', () {
    test('rounds the per-kB rate up to whole sats per vB', () {
      expect(
        effectiveMwebFeeRatePerKB(
          feeRatePerKB: BigInt.from(1001),
          satsPerVByte: null,
        ),
        BigInt.from(2000),
      );
      expect(
        effectiveMwebFeeRatePerKB(
          feeRatePerKB: BigInt.from(993),
          satsPerVByte: null,
        ),
        BigInt.from(1000),
      );
      expect(
        effectiveMwebFeeRatePerKB(
          feeRatePerKB: BigInt.from(1000),
          satsPerVByte: null,
        ),
        BigInt.from(1000),
      );
    });

    test('uses custom sat/vB rate without replacing the sentinel', () {
      expect(
        effectiveMwebFeeRatePerKB(
          feeRatePerKB: BigInt.from(-1),
          satsPerVByte: 3,
        ),
        BigInt.from(3000),
      );
    });
  });

  group('buildWithReconciledFee', () {
    test('rebuilds when the final signed size requires a larger fee', () async {
      final feesUsedToBuild = <BigInt>[];

      final reconciled = await buildWithReconciledFee(
        initialFee: BigInt.from(276),
        build: (fee) async {
          feesUsedToBuild.add(fee);
          return fee == BigInt.from(276) ? 277 : 276;
        },
        requiredFee: BigInt.from,
      );

      expect(reconciled.fee, BigInt.from(277));
      expect(reconciled.result, 276);
      expect(feesUsedToBuild, [BigInt.from(276), BigInt.from(277)]);
    });

    test('never lowers a fee when a rebuilt signature is shorter', () async {
      final reconciled = await buildWithReconciledFee(
        initialFee: BigInt.from(277),
        build: (_) async => 276,
        requiredFee: BigInt.from,
      );

      expect(reconciled.fee, BigInt.from(277));
    });

    test(
      'fails instead of returning a transaction that still underpays',
      () async {
        await expectLater(
          buildWithReconciledFee(
            initialFee: BigInt.one,
            build: (fee) async => fee + BigInt.one,
            requiredFee: (fee) => fee,
            maxAttempts: 2,
          ),
          throwsStateError,
        );
      },
    );
  });
}

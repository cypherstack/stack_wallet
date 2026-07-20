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
}

import 'package:decimal/decimal.dart';

const _kilobyte = 1000;

BigInt feeRatePerKBFromCoinUnits(
  Decimal feeRate, {
  required int fractionDigits,
}) {
  return feeRate.shift(fractionDigits).ceil().toBigInt();
}

BigInt clampFeeRatePerKB({
  required BigInt feeRatePerKB,
  required BigInt minimumFeeRatePerKB,
}) {
  return feeRatePerKB < minimumFeeRatePerKB
      ? minimumFeeRatePerKB
      : feeRatePerKB;
}

int feeForVSize({required int vSize, required BigInt feeRatePerKB}) {
  final unroundedFee = feeRatePerKB * BigInt.from(vSize);
  return ((unroundedFee + BigInt.from(_kilobyte - 1)) ~/ BigInt.from(_kilobyte))
      .toInt();
}

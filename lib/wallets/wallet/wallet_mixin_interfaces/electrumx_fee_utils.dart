import 'package:decimal/decimal.dart';

const _kilobyte = 1000;
final _kilobyteBigInt = BigInt.from(_kilobyte);

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

BigInt normalizeFeeRatePerKB({
  required Decimal feeRateInCoinUnits,
  required int fractionDigits,
  required BigInt minimumFeeRatePerKB,
}) {
  return clampFeeRatePerKB(
    feeRatePerKB: feeRatePerKBFromCoinUnits(
      feeRateInCoinUnits,
      fractionDigits: fractionDigits,
    ),
    minimumFeeRatePerKB: minimumFeeRatePerKB,
  );
}

int feeForVSize({required int vSize, required BigInt feeRatePerKB}) {
  final unroundedFee = feeRatePerKB * BigInt.from(vSize);
  return ((unroundedFee + _kilobyteBigInt - BigInt.one) ~/ _kilobyteBigInt)
      .toInt();
}

BigInt feeRatePerKBFromSatsPerVByte(int satsPerVByte) {
  return BigInt.from(satsPerVByte) * _kilobyteBigInt;
}

BigInt effectiveMwebFeeRatePerKB({
  required BigInt feeRatePerKB,
  required int? satsPerVByte,
}) {
  if (satsPerVByte != null) {
    return feeRatePerKBFromSatsPerVByte(satsPerVByte);
  }

  final roundedSatsPerVByte =
      (feeRatePerKB + _kilobyteBigInt - BigInt.one) ~/ _kilobyteBigInt;
  return roundedSatsPerVByte * _kilobyteBigInt;
}

Future<({T result, BigInt fee})> buildWithReconciledFee<T>({
  required BigInt initialFee,
  required Future<T> Function(BigInt fee) build,
  required BigInt Function(T result) requiredFee,
  int maxAttempts = 10,
}) async {
  if (maxAttempts < 1) {
    throw ArgumentError.value(maxAttempts, 'maxAttempts', 'Must be positive');
  }

  var fee = initialFee;
  for (var attempt = 0; attempt < maxAttempts; attempt++) {
    final result = await build(fee);
    final feeForResult = requiredFee(result);

    if (feeForResult <= fee) {
      return (result: result, fee: fee);
    }

    fee = feeForResult;
  }

  throw StateError(
    'Failed to reconcile the fee with the final transaction size after '
    '$maxAttempts attempts',
  );
}

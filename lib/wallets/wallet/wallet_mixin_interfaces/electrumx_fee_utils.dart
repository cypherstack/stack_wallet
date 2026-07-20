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

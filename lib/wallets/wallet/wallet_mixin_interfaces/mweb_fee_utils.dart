const _kilobyte = 1000;
final _kilobyteBigInt = BigInt.from(_kilobyte);

BigInt effectiveMwebFeeRatePerKB({
  required BigInt feeRatePerKB,
  required int? satsPerVByte,
}) {
  final requestedFeeRatePerKB = satsPerVByte == null
      ? feeRatePerKB
      : BigInt.from(satsPerVByte) * _kilobyteBigInt;

  return requestedFeeRatePerKB < _kilobyteBigInt
      ? _kilobyteBigInt
      : requestedFeeRatePerKB;
}

BigInt requiredMwebFee({
  required BigInt currentFee,
  required BigInt feeIncrease,
  required bool hasPegin,
  required int vSize,
  required BigInt feeRatePerKB,
}) {
  if (!hasPegin) {
    return currentFee + feeIncrease;
  }

  final vSizeBigInt = BigInt.from(vSize);
  final rateFee =
      (feeRatePerKB * vSizeBigInt + _kilobyteBigInt - BigInt.one) ~/
      _kilobyteBigInt;
  final baseFee = rateFee > vSizeBigInt ? rateFee : vSizeBigInt;
  return baseFee + feeIncrease;
}

Future<R> processWithReconciledMwebFee<T, R>({
  required T initial,
  required BigInt feeRatePerKB,
  required BigInt Function(T candidate) paidFee,
  required Future<BigInt> Function(T candidate, BigInt feeRatePerKB)
  requiredFee,
  required Future<T> Function(T initial, BigInt minimumFee) rebuild,
  required Future<R> Function(T candidate, BigInt feeRatePerKB) process,
}) async {
  const maxAttempts = 10;
  var attempt = 0;
  var candidate = initial;

  while (true) {
    final fee = await requiredFee(candidate, feeRatePerKB);
    if (fee <= paidFee(candidate)) {
      return process(candidate, feeRatePerKB);
    }
    if (++attempt > maxAttempts) {
      throw Exception(
        "MWEB fee calculation failed to converge after $maxAttempts attempts",
      );
    }
    candidate = await rebuild(initial, fee);
  }
}

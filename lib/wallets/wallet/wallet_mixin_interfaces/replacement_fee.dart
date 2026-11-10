/// BIP 125 rule 4: a replacement pays at least the original fee plus the
/// incremental relay fee for its own size, in sats per vbyte.
const incrementalRelayFeeRate = 1;

/// The fee a replacement of [vSize] must pay: [newRate] on that size, but at
/// least [oldFee] plus the relay increment.
BigInt requiredReplacementFee({
  required int vSize,
  required BigInt oldFee,
  required int newRate,
}) {
  final size = BigInt.from(vSize);
  final atNewRate = size * BigInt.from(newRate);
  final relayFloor = oldFee + size * BigInt.from(incrementalRelayFeeRate);
  return atNewRate > relayFloor ? atNewRate : relayFloor;
}

/// Throws unless [fee] reaches [requiredReplacementFee].
void requireReplacementFee(
  BigInt fee, {
  required int vSize,
  required BigInt oldFee,
  required int newRate,
}) {
  final required = requiredReplacementFee(
    vSize: vSize,
    oldFee: oldFee,
    newRate: newRate,
  );
  if (fee < required) {
    throw Exception(
      "New fee of $fee does not reach the $required needed to replace",
    );
  }
}

/// A built replacement: the fee it pays, its size, and the build itself.
typedef BuiltReplacement<T> = ({BigInt fee, int vSize, T built});

/// Builds a replacement with [build], starting from [newRate] on [oldVSize],
/// and raises the fee until a build pays [requiredReplacementFee] for its own
/// size. Gives up after [attempts] builds.
Future<T> settleReplacementFee<T>({
  required int oldVSize,
  required BigInt oldFee,
  required int newRate,
  required Future<BuiltReplacement<T>> Function(BigInt newFee) build,
  int attempts = 3,
}) async {
  var newFee = BigInt.from(oldVSize * newRate);
  for (var attempt = 1; ; attempt++) {
    final result = await build(newFee);
    final requiredFee = requiredReplacementFee(
      vSize: result.vSize,
      oldFee: oldFee,
      newRate: newRate,
    );
    if (result.fee >= requiredFee) {
      return result.built;
    }
    if (attempt == attempts) {
      throw Exception("Could not settle on a fee for the replacement");
    }
    newFee = requiredFee;
  }
}

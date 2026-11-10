/// Formats an approximate atomic-unit fee per virtual byte, rounded to tenths.
/// Integer arithmetic preserves precision even for fees beyond double's range.
String? formatApproximateFeeRate(BigInt? rawFee, int? virtualSize) {
  if (rawFee == null ||
      rawFee.isNegative ||
      virtualSize == null ||
      virtualSize <= 0) {
    return null;
  }
  final size = BigInt.from(virtualSize);
  final scaled = rawFee * BigInt.from(10);
  var tenths = scaled ~/ size;
  if ((scaled % size) * BigInt.two >= size) tenths += BigInt.one;
  return '~${tenths ~/ BigInt.from(10)}.${tenths % BigInt.from(10)}';
}

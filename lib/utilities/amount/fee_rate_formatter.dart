import '../util.dart';

/// Formats an approximate atomic-unit fee per virtual byte, rounded to tenths.
/// Integer arithmetic preserves precision even for fees beyond double's range.
String? formatApproximateFeeRate(
  BigInt? rawFee,
  int? virtualSize, {
  String? locale,
}) {
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
  final rate = '~${tenths ~/ BigInt.from(10)}.${tenths % BigInt.from(10)}';
  if (locale == null) {
    return rate;
  }
  final separator = Util.getSymbolsFor(locale: locale)?.DECIMAL_SEP ?? '.';
  return separator == '.' ? rate : rate.replaceFirst('.', separator);
}

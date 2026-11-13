bool shouldSkipMwcFeeEstimate({required int amount, required int available}) =>
    amount <= 0 || available <= 0;

int estimateMwcRestoreHeight(DateTime date) {
  final int secondsSinceEpoch = date.millisecondsSinceEpoch ~/ 1000;
  const int mimblewimblecoinFirstBlock = 1573462801;
  const double overestimateSecondsPerBlock = 61;
  final int chosenSeconds = secondsSinceEpoch - mimblewimblecoinFirstBlock;
  final int approximateHeight = chosenSeconds ~/ overestimateSecondsPerBlock;
  return approximateHeight < 0 ? 0 : approximateHeight;
}

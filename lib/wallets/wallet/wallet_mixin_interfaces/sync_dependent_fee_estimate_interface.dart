mixin SyncDependentFeeEstimateInterface {
  /// The wallet estimates a zero fee while this is false.
  bool get canEstimateFee;
}

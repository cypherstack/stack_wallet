enum FeeRateType { fast, average, slow }

extension FeeRateTypeExt on FeeRateType {
  String get prettyName {
    switch (this) {
      case FeeRateType.fast:
        return "Fast";
      case FeeRateType.average:
        return "Average";
      case FeeRateType.slow:
        return "Slow";
    }
  }
}

enum Fiats {
  USD
  // etc
}

extension FiatExt on Fiats {
  String get ticker {
    switch (this) {
      case Fiats.USD:
        return "USD";
      default:
        return "-";
    }
  }
}

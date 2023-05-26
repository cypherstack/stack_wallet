enum TrocadorKYCType {
  a,
  b,
  c,
  d;

  static TrocadorKYCType fromString(String type) {
    for (final result in values) {
      if (result.name == type.toLowerCase()) {
        return result;
      }
    }
    throw ArgumentError("Invalid trocador kyc type: $type");
  }
}

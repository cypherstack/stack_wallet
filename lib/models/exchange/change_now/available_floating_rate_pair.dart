import 'package:flutter/material.dart';

class AvailableFloatingRatePair {
  final String fromTicker;
  final String toTicker;

  AvailableFloatingRatePair({
    required this.fromTicker,
    required this.toTicker,
  });

  @override
  bool operator ==(other) {
    return other is AvailableFloatingRatePair &&
        fromTicker == other.fromTicker &&
        toTicker == other.toTicker;
  }

  @override
  int get hashCode => hashValues(fromTicker, toTicker);

  @override
  String toString() {
    return "${fromTicker}_$toTicker";
  }
}

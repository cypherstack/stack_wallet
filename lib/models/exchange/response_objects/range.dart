import 'package:decimal/decimal.dart';

class Range {
  final Decimal? min;
  final Decimal? max;

  Range({this.min, this.max});

  Range copyWith({
    Decimal? min,
    Decimal? max,
  }) {
    return Range(
      min: min ?? this.min,
      max: max ?? this.max,
    );
  }

  Map<String, dynamic> toMap() {
    final map = {
      "min": min?.toString(),
      "max": max?.toString(),
    };

    return map;
  }

  @override
  String toString() {
    return "Range: ${toMap()}";
  }
}

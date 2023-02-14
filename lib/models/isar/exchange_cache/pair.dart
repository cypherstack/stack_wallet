import 'package:isar/isar.dart';

part 'pair.g.dart';

// embedded enum // no not modify
enum SupportedRateType { fixed, estimated, both }

@collection
class Pair {
  Pair({
    required this.exchangeName,
    required this.from,
    required this.to,
    required this.rateType,
  });

  Id? id;

  @Index()
  final String exchangeName;

  @Index(composite: [
    CompositeIndex("exchangeName"),
    CompositeIndex("to"),
  ])
  final String from;

  final String to;

  @enumerated
  final SupportedRateType rateType;

  Map<String, dynamic> toMap() {
    return {
      "id": id,
      "exchangeName": exchangeName,
      "from": from,
      "to": to,
      "rateType": rateType,
    };
  }

  @override
  bool operator ==(other) =>
      other is Pair &&
      exchangeName == other.exchangeName &&
      from == other.from &&
      to == other.to &&
      rateType == other.rateType;

  @override
  int get hashCode => Object.hash(
        exchangeName,
        from,
        to,
        rateType,
      );

  @override
  String toString() => "Pair: ${toMap()}";
}

import 'package:isar/isar.dart';
import 'package:stackwallet/utilities/logger.dart';

part 'pair.g.dart';

@collection
class Pair {
  Id? id;

  @Index()
  final String exchangeName;

  @Index(composite: [
    CompositeIndex("exchangeName"),
    CompositeIndex("to"),
  ])
  final String from;
  final String fromNetwork;

  final String to;
  final String toNetwork;

  final bool fixedRate;
  final bool floatingRate;

  Pair({
    required this.exchangeName,
    required this.from,
    required this.fromNetwork,
    required this.to,
    required this.toNetwork,
    required this.fixedRate,
    required this.floatingRate,
  });

  factory Pair.fromMap(
    Map<String, dynamic> map, {
    required String exchangeName,
  }) {
    try {
      return Pair(
        exchangeName: exchangeName,
        from: map["from"] as String,
        fromNetwork: map["fromNetwork"] as String,
        to: map["to"] as String,
        toNetwork: map["toNetwork"] as String,
        fixedRate: map["fixedRate"] as bool,
        floatingRate: map["floatingRate"] as bool,
      )..id = map["id"] as int?;
    } catch (e, s) {
      Logging.instance.log("Pair.fromMap(): $e\n$s", level: LogLevel.Error);
      rethrow;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      "id": id,
      "exchangeName": exchangeName,
      "from": from,
      "fromNetwork": fromNetwork,
      "to": to,
      "toNetwork": toNetwork,
      "fixedRate": fixedRate,
      "floatingRate": floatingRate,
    };
  }

  @override
  bool operator ==(other) =>
      other is Pair &&
      exchangeName == other.exchangeName &&
      from == other.from &&
      fromNetwork == other.fromNetwork &&
      to == other.to &&
      toNetwork == other.toNetwork &&
      fixedRate == other.fixedRate &&
      floatingRate == other.floatingRate;

  @override
  int get hashCode => Object.hash(
        id,
        exchangeName,
        from,
        fromNetwork,
        to,
        toNetwork,
        fixedRate,
        floatingRate,
      );

  @override
  String toString() => "Pair: ${toMap()}";
}

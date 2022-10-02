class Pair {
  final String from;
  final String fromNetwork;

  final String to;
  final String toNetwork;

  final bool fixedRate;
  final bool floatingRate;

  Pair({
    required this.from,
    required this.fromNetwork,
    required this.to,
    required this.toNetwork,
    required this.fixedRate,
    required this.floatingRate,
  });

  Map<String, dynamic> toJson() {
    return {
      "from": from,
      "fromNetwork": fromNetwork,
      "to": to,
      "toNetwork": toNetwork,
      "fixedRate": fixedRate,
      "floatingRate": floatingRate,
    };
  }

  @override
  String toString() {
    return "Pair: ${toJson()}";
  }
}

class FeeObject {
  final int fast;
  final int medium;
  final int slow;

  final int numberOfBlocksFast;
  final int numberOfBlocksAverage;
  final int numberOfBlocksSlow;

  FeeObject({
    required this.numberOfBlocksFast,
    required this.numberOfBlocksAverage,
    required this.numberOfBlocksSlow,
    required this.fast,
    required this.medium,
    required this.slow,
  });

  factory FeeObject.fromJson(Map<String, dynamic> json) {
    return FeeObject(
      fast: json['fast'] as int,
      medium: json['average'] as int,
      slow: json['slow'] as int,
      numberOfBlocksFast: json['numberOfBlocksFast'] as int,
      numberOfBlocksAverage: json['numberOfBlocksAverage'] as int,
      numberOfBlocksSlow: json['numberOfBlocksSlow'] as int,
    );
  }

  @override
  String toString() {
    return "{fast: $fast, medium: $medium, slow: $slow, numberOfBlocksFast: $numberOfBlocksFast, numberOfBlocksAverage: $numberOfBlocksAverage, numberOfBlocksSlow: $numberOfBlocksSlow}";
  }
}

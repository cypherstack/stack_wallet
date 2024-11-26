class NodeTorMismatchConfigException implements Exception {
  final String message;

  NodeTorMismatchConfigException({required this.message});

  @override
  String toString() => message;
}

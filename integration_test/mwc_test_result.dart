/// Represents the result of a single FFI integration test.
class TestResult {
  final String name;
  final String description;
  final bool passed;
  final Duration duration;
  final String? result;
  final String? error;
  final String? stackTrace;
  final DateTime timestamp;
  
  TestResult({
    required this.name,
    required this.description,
    required this.passed,
    required this.duration,
    this.result,
    this.error,
    this.stackTrace,
  }) : timestamp = DateTime.now();
  
  /// Get a summary string for this test result.
  String get summary {
    final status = passed ? 'PASS' : 'FAIL';
    final durationMs = duration.inMilliseconds;
    return '$status: $name (${durationMs}ms)';
  }
}

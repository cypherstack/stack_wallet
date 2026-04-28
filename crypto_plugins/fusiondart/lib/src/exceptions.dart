/// Custom exception class for Fusion related errors.
class FusionError implements Exception {
  /// The error message describing the issue.
  final String message;

  /// Constructs a new FusionError with the provided message.
  FusionError(this.message);

  /// Custom string representation of the FusionError, useful for debugging.
  @override
  String toString() => "FusionError: $message";
}

class ValidationError implements Exception {
  final String message;
  ValidationError(this.message);
  @override
  String toString() => 'Validation error: $message';
}

/// Custom exception class for encryption failures.
class EncryptionFailed implements Exception {}

/// Custom exception class for decryption failures.
class DecryptionFailed implements Exception {}

/// Represents an unrecoverable Fusion error.
class Unrecoverable extends FusionError {
  /// Constructor that initializes the Unrecoverable error with a given [cause].
  Unrecoverable(String cause) : super(cause);
}

// Custom exception classes to provide detailed error information.
class NullPointError implements Exception {
  /// Returns a string representation of the error.
  String errMsg() => 'NullPointError: Either Hpoint or HGpoint is null.';
}

/// Represents an error when the nonce value is not within a valid range.
class NonceRangeError implements Exception {
  /// The error message String.
  final String message;

  /// Creates a new [NonceRangeError] with an optional error [message].
  NonceRangeError(
      [this.message = "Nonce value must be in the range 0 < nonce < order"]);

  /// Returns a string representation of the error.
  @override
  String toString() => "NonceRangeError: $message";
}

/// Represents an error when the result is at infinity.
class ResultAtInfinity implements Exception {
  /// The error message String.
  final String message;

  /// Creates a new [ResultAtInfinity] with an optional error [message].
  ResultAtInfinity([this.message = "Result is at infinity"]);

  /// Returns a string representation of the error.
  @override
  String toString() => "ResultAtInfinity: $message";
}

/// Represents an error when the H point has a known discrete logarithm.
class InsecureHPoint implements Exception {
  /// The error message String.
  final String message;

  /// Creates a new [InsecureHPoint] with an optional error [message].
  InsecureHPoint(
      [this.message =
          "The H point has a known discrete logarithm, which means the commitment setup is broken"]);

  /// Returns a string representation of the error.
  @override
  String toString() => "InsecureHPoint: $message";
}

final class FusionStopRequested implements Exception {}

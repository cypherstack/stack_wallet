/// Enum to represent different Epic Cash transaction methods.
enum EpicTransactionMethod {
  /// Manual slate exchange (copy/paste, QR codes, files).
  slatepack,

  /// Automatic transaction via Epicbox.
  epicbox;

  /// Human readable name for the transaction method.
  String get displayName {
    switch (this) {
      case EpicTransactionMethod.slatepack:
        return 'Slatepack';
      case EpicTransactionMethod.epicbox:
        return 'Epicbox';
    }
  }

  /// Description of how the transaction method works.
  String get description {
    switch (this) {
      case EpicTransactionMethod.slatepack:
        return 'Manual exchange via text, QR codes, or files';
      case EpicTransactionMethod.epicbox:
        return 'Automatic exchange via Epicbox messaging';
    }
  }

  /// Whether this method requires manual intervention.
  bool get isManual {
    switch (this) {
      case EpicTransactionMethod.slatepack:
        return true;
      case EpicTransactionMethod.epicbox:
        return false;
    }
  }

  /// Whether this method works offline.
  bool get worksOffline {
    switch (this) {
      case EpicTransactionMethod.slatepack:
        return true;
      case EpicTransactionMethod.epicbox:
        return false;
    }
  }
}

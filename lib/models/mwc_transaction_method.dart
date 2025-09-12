/// Enum to represent different MWC transaction methods.
enum TransactionMethod {
  /// Manual slatepack exchange (copy/paste, QR codes, files).
  slatepack,

  /// Automatic transaction via MWCMQS.
  mwcmqs,

  /// Direct HTTP/HTTPS to recipient's wallet.
  http,

  /// Unknown or unsupported method.
  unknown;

  /// Human readable name for the transaction method.
  String get displayName {
    switch (this) {
      case TransactionMethod.slatepack:
        return 'Slatepack';
      case TransactionMethod.mwcmqs:
        return 'MWCMQS';
      case TransactionMethod.http:
        return 'HTTP';
      case TransactionMethod.unknown:
        return 'Unknown';
    }
  }

  /// Description of how the transaction method works.
  String get description {
    switch (this) {
      case TransactionMethod.slatepack:
        return 'Manual exchange via text, QR codes, or files';
      case TransactionMethod.mwcmqs:
        return 'Automatic exchange via MWCMQS messaging';
      case TransactionMethod.http:
        return 'Direct connection to recipient wallet';
      case TransactionMethod.unknown:
        return 'Unsupported transaction method';
    }
  }

  /// Whether this method requires manual intervention.
  bool get isManual {
    switch (this) {
      case TransactionMethod.slatepack:
        return true;
      case TransactionMethod.mwcmqs:
        return false;
      case TransactionMethod.http:
        return false;
      case TransactionMethod.unknown:
        return true;
    }
  }

  /// Whether this method works offline.
  bool get worksOffline {
    switch (this) {
      case TransactionMethod.slatepack:
        return true;
      case TransactionMethod.mwcmqs:
        return false;
      case TransactionMethod.http:
        return false;
      case TransactionMethod.unknown:
        return false;
    }
  }
}

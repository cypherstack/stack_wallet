/// Enum to represent different MWC transaction methods.
enum MwcTransactionMethod {
  /// Manual slatepack exchange (copy/paste, QR codes, files).
  slatepack,

  /// Automatic transaction via MWCMQS.
  mwcmqs;

  // /// Direct HTTP/HTTPS to recipient's wallet.
  // http,
  //
  // /// Unknown or unsupported method.
  // unknown;

  /// Human readable name for the transaction method.
  String get displayName {
    switch (this) {
      case MwcTransactionMethod.slatepack:
        return 'Slatepack';
      case MwcTransactionMethod.mwcmqs:
        return 'MWCMQS';
      // case MwcTransactionMethod.http:
      //   return 'HTTP';
      // case MwcTransactionMethod.unknown:
      //   return 'Unknown';
    }
  }

  /// Description of how the transaction method works.
  String get description {
    switch (this) {
      case MwcTransactionMethod.slatepack:
        return 'Manual exchange via text, QR codes, or files';
      case MwcTransactionMethod.mwcmqs:
        return 'Automatic exchange via MWCMQS messaging';
      // case MwcTransactionMethod.http:
      //   return 'Direct connection to recipient wallet';
      // case MwcTransactionMethod.unknown:
      //   return 'Unsupported transaction method';
    }
  }

  /// Whether this method requires manual intervention.
  bool get isManual {
    switch (this) {
      case MwcTransactionMethod.slatepack:
        return true;
      case MwcTransactionMethod.mwcmqs:
        return false;
      // case MwcTransactionMethod.http:
      //   return false;
      // case MwcTransactionMethod.unknown:
      //   return true;
    }
  }

  /// Whether this method works offline.
  bool get worksOffline {
    switch (this) {
      case MwcTransactionMethod.slatepack:
        return true;
      case MwcTransactionMethod.mwcmqs:
        return false;
      // case MwcTransactionMethod.http:
      //   return false;
      // case MwcTransactionMethod.unknown:
      //   return false;
    }
  }
}

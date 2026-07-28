class LedgerErrorCodes {
  LedgerErrorCodes._();

  static const int transactionRejected = 0x6985;
  static const int deviceLocked = 0x5515;
  static const int wrongAppOpen = 0x6E01;
  static const int appNotOpen = 0x6A87;
  static const int insNotSupported = 0x6D02;
  static const int appNotReady = 0x6511;
  static const int unknownApdu = 0x6E00;

  static const Map<int, String> _messages = {
    transactionRejected: 'Transaction rejected by user',
    deviceLocked: 'Device is locked -- unlock your Ledger and try again',
    wrongAppOpen: 'Wrong app open on device -- open the correct app',
    appNotOpen: 'Required app not open on device',
    insNotSupported: 'Instruction not supported -- wrong app may be open',
    appNotReady: 'App is not ready -- wait and try again',
    unknownApdu: 'Unknown APDU command -- wrong app may be open',
  };

  static String messageFor(int statusCode) {
    return _messages[statusCode] ??
        'Unknown Ledger error (0x${statusCode.toRadixString(16)})';
  }

  static bool isUserRejection(int statusCode) {
    return statusCode == transactionRejected;
  }

  static bool isWrongApp(int statusCode) {
    return statusCode == wrongAppOpen ||
        statusCode == appNotOpen ||
        statusCode == insNotSupported ||
        statusCode == unknownApdu;
  }

  static bool isDeviceLocked(int statusCode) {
    return statusCode == deviceLocked;
  }
}

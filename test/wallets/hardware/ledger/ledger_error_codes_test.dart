import 'package:flutter_test/flutter_test.dart';

import 'package:stackduo/wallets/hardware/ledger/ledger_error_codes.dart';

void main() {
  group('LedgerErrorCodes', () {
    group('messageFor', () {
      test('returns message for transactionRejected (0x6985)', () {
        expect(
          LedgerErrorCodes.messageFor(0x6985),
          'Transaction rejected by user',
        );
      });

      test('returns message for deviceLocked (0x5515)', () {
        expect(
          LedgerErrorCodes.messageFor(0x5515),
          'Device is locked -- unlock your Ledger and try again',
        );
      });

      test('returns message for wrongAppOpen (0x6E01)', () {
        expect(
          LedgerErrorCodes.messageFor(0x6E01),
          'Wrong app open on device -- open the correct app',
        );
      });

      test('returns message for appNotOpen (0x6A87)', () {
        expect(
          LedgerErrorCodes.messageFor(0x6A87),
          'Required app not open on device',
        );
      });

      test('returns message for insNotSupported (0x6D02)', () {
        expect(
          LedgerErrorCodes.messageFor(0x6D02),
          'Instruction not supported -- wrong app may be open',
        );
      });

      test('returns message for appNotReady (0x6511)', () {
        expect(
          LedgerErrorCodes.messageFor(0x6511),
          'App is not ready -- wait and try again',
        );
      });

      test('returns message for unknownApdu (0x6E00)', () {
        expect(
          LedgerErrorCodes.messageFor(0x6E00),
          'Unknown APDU command -- wrong app may be open',
        );
      });

      test('returns fallback message for unknown status code', () {
        final message = LedgerErrorCodes.messageFor(0x9999);
        expect(message, contains('Unknown Ledger error'));
        expect(message, contains('9999'));
      });
    });

    group('isUserRejection', () {
      test('returns true for transactionRejected', () {
        expect(LedgerErrorCodes.isUserRejection(0x6985), isTrue);
      });

      test('returns false for other codes', () {
        expect(LedgerErrorCodes.isUserRejection(0x5515), isFalse);
        expect(LedgerErrorCodes.isUserRejection(0x6E01), isFalse);
      });
    });

    group('isWrongApp', () {
      test('returns true for wrongAppOpen', () {
        expect(LedgerErrorCodes.isWrongApp(0x6E01), isTrue);
      });

      test('returns true for appNotOpen', () {
        expect(LedgerErrorCodes.isWrongApp(0x6A87), isTrue);
      });

      test('returns true for insNotSupported', () {
        expect(LedgerErrorCodes.isWrongApp(0x6D02), isTrue);
      });

      test('returns true for unknownApdu', () {
        expect(LedgerErrorCodes.isWrongApp(0x6E00), isTrue);
      });

      test('returns false for non-app codes', () {
        expect(LedgerErrorCodes.isWrongApp(0x6985), isFalse);
        expect(LedgerErrorCodes.isWrongApp(0x5515), isFalse);
      });
    });

    group('isDeviceLocked', () {
      test('returns true for deviceLocked', () {
        expect(LedgerErrorCodes.isDeviceLocked(0x5515), isTrue);
      });

      test('returns false for other codes', () {
        expect(LedgerErrorCodes.isDeviceLocked(0x6985), isFalse);
        expect(LedgerErrorCodes.isDeviceLocked(0x6E01), isFalse);
      });
    });

    group('constant values', () {
      test('all known error codes have correct hex values', () {
        expect(LedgerErrorCodes.transactionRejected, 0x6985);
        expect(LedgerErrorCodes.deviceLocked, 0x5515);
        expect(LedgerErrorCodes.wrongAppOpen, 0x6E01);
        expect(LedgerErrorCodes.appNotOpen, 0x6A87);
        expect(LedgerErrorCodes.insNotSupported, 0x6D02);
        expect(LedgerErrorCodes.appNotReady, 0x6511);
        expect(LedgerErrorCodes.unknownApdu, 0x6E00);
      });
    });
  });
}

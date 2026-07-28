import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:ledger_bitcoin/ledger_bitcoin.dart' as btc;
import 'package:ledger_flutter_plus/ledger_flutter_plus.dart' as ledger;

import '../hardware_account_data.dart';
import '../hardware_wallet_device.dart';
import '../hardware_wallet_service.dart';
import 'ledger_error_codes.dart';
import 'ledger_hardware_wallet_device.dart';

class LedgerBitcoinService implements HardwareWalletService {
  final ledger.LedgerConnection _connection;

  LedgerBitcoinService({required ledger.LedgerConnection connection})
      : _connection = connection;

  @override
  Future<List<HardwareAccountData>> getAvailableAccounts({
    required HardwareWalletDevice device,
    required String derivationPath,
  }) async {
    _assertLedgerDevice(device);

    debugPrint(
      '[LedgerBitcoinService] Getting accounts for path: $derivationPath',
    );

    try {
      final bitcoinApp = btc.BitcoinLedgerApp(_connection);

      final xpub = await bitcoinApp.getXPubKey(
        derivationPath: derivationPath,
      );

      final masterFingerprintBytes = await bitcoinApp.getMasterFingerprint();
      final masterFingerprint = masterFingerprintBytes
          .map((b) => b.toRadixString(16).padLeft(2, '0'))
          .join();

      debugPrint('[LedgerBitcoinService] Got xpub for $derivationPath');

      return [
        HardwareAccountData(
          address: '',
          accountIndex: _accountIndexFromPath(derivationPath),
          derivationPath: derivationPath,
          masterFingerprint: masterFingerprint,
          xpub: xpub,
        ),
      ];
    } catch (e) {
      debugPrint('[LedgerBitcoinService] getAvailableAccounts error: $e');
      _handleLedgerError(e);
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>> signTransaction({
    required HardwareWalletDevice device,
    required Map<String, dynamic> payload,
  }) async {
    _assertLedgerDevice(device);

    debugPrint('[LedgerBitcoinService] Signing transaction');

    final psbt = payload['psbt'] as String?;
    if (psbt == null) {
      throw ArgumentError('payload must contain "psbt" key with PSBT string');
    }

    try {
      final bitcoinApp = btc.BitcoinLedgerApp(_connection);

      final psbtBytes = base64Decode(psbt);
      final signedTxBytes = await bitcoinApp.signTransaction(psbtBytes);

      debugPrint('[LedgerBitcoinService] Transaction signed successfully');

      return {
        'signedPsbt': base64Encode(signedTxBytes),
      };
    } catch (e) {
      debugPrint('[LedgerBitcoinService] signTransaction error: $e');
      _handleLedgerError(e);
      rethrow;
    }
  }

  void _assertLedgerDevice(HardwareWalletDevice device) {
    if (device is! LedgerHardwareWalletDevice) {
      throw ArgumentError(
        'LedgerBitcoinService requires a LedgerHardwareWalletDevice',
      );
    }
  }

  void _handleLedgerError(Object error) {
    if (error is ledger.LedgerDeviceException) {
      final code = error.errorCode;
      final message = LedgerErrorCodes.messageFor(code);
      debugPrint('[LedgerBitcoinService] Ledger error $code: $message');
    }
  }

  int _accountIndexFromPath(String path) {
    final parts = path.split('/');
    if (parts.length >= 4) {
      final accountPart = parts[3].replaceAll("'", '');
      return int.tryParse(accountPart) ?? 0;
    }
    return 0;
  }
}

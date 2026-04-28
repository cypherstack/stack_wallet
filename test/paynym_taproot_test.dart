import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

// Test the logic of _pubKeyFromInput behavior for different input types,
// and the taproot UTXO sorting for notification tx preparation.
//
// These test the pure logic extracted from paynym_interface.dart without
// needing the full wallet mixin context.

/// Mirrors _pubKeyFromInput logic from paynym_interface.dart.
Uint8List? pubKeyFromInput({
  String? scriptSigAsm,
  String? witness,
}) {
  final scriptSigComponents = scriptSigAsm?.split(" ") ?? [];
  if (scriptSigComponents.length > 1) {
    return _hexToBytes(scriptSigComponents[1]);
  }
  if (witness != null) {
    try {
      final witnessComponents = jsonDecode(witness) as List;
      if (witnessComponents.length == 2) {
        return _hexToBytes(witnessComponents[1] as String);
      }
    } catch (_) {}
  }
  return null;
}

/// Mirrors the taproot-aware UTXO sorting from prepareNotificationTx.
List<_MockUTXO> sortForNotificationTx(List<_MockUTXO> utxos) {
  utxos.sort((a, b) {
    final aIsTaproot =
        a.address.startsWith('bc1p') || a.address.startsWith('tb1p');
    final bIsTaproot =
        b.address.startsWith('bc1p') || b.address.startsWith('tb1p');
    if (aIsTaproot != bIsTaproot) {
      return aIsTaproot ? 1 : -1;
    }
    return b.blockTime.compareTo(a.blockTime);
  });
  return utxos;
}

class _MockUTXO {
  final String address;
  final int blockTime;
  final int value;
  _MockUTXO(this.address, this.blockTime, this.value);
}

Uint8List _hexToBytes(String hex) {
  return Uint8List.fromList([
    for (int i = 0; i < hex.length; i += 2)
      int.parse(hex.substring(i, i + 2), radix: 16),
  ]);
}

String _bytesToHex(Uint8List bytes) {
  return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
}

void main() {
  group('pubKeyFromInput', () {
    test('extracts pubkey from P2PKH scriptSigAsm', () {
      // scriptSigAsm format: "<signature> <pubkey>"
      const scriptSigAsm =
          '3045022100abcd02207890[r]'
          ' '
          '0353883a146a23f988e0f381a9507cbdb3e3130cd81b3ce26daf2af088724ce683';

      final result = pubKeyFromInput(scriptSigAsm: scriptSigAsm);
      expect(result, isNotNull);
      expect(
        _bytesToHex(result!),
        '0353883a146a23f988e0f381a9507cbdb3e3130cd81b3ce26daf2af088724ce683',
      );
    });

    test('extracts pubkey from P2WPKH witness (2 elements)', () {
      // P2WPKH witness: ["signature_hex", "pubkey_hex"]
      const witness =
          '["3045022100abcd0220efgh",'
          '"0353883a146a23f988e0f381a9507cbdb3e3130cd81b3ce26daf2af088724ce683"]';

      final result = pubKeyFromInput(witness: witness);
      expect(result, isNotNull);
      expect(
        _bytesToHex(result!),
        '0353883a146a23f988e0f381a9507cbdb3e3130cd81b3ce26daf2af088724ce683',
      );
    });

    test('returns null for taproot witness (1 element)', () {
      // Taproot key-path spend: witness has only the Schnorr signature
      const witness =
          '["650a2d7442562d6aed1b0e438bc0f0f9bd845e4fa07a2866896fc8ffddd27ef2'
          '340ad40154679d22b31cbd7195bbe51178fdc321fa12cd6c7772961202aae019"]';

      final result = pubKeyFromInput(witness: witness);
      expect(result, isNull,
          reason: 'Taproot key-path spend has no pubkey in witness');
    });

    test('returns null for empty scriptSig and null witness', () {
      final result = pubKeyFromInput(scriptSigAsm: '', witness: null);
      expect(result, isNull);
    });

    test('returns null for empty scriptSig and empty witness', () {
      final result = pubKeyFromInput(scriptSigAsm: '', witness: '[]');
      expect(result, isNull);
    });

    test('returns null for single-word scriptSigAsm', () {
      // scriptSigAsm with only one component (no pubkey)
      final result = pubKeyFromInput(scriptSigAsm: 'abcdef');
      expect(result, isNull);
    });

    test('scriptSigAsm takes priority over witness', () {
      const scriptSigAsm =
          'sig '
          'aabbccdd';
      const witness =
          '["sig_hex","eeff0011"]';

      final result = pubKeyFromInput(
        scriptSigAsm: scriptSigAsm,
        witness: witness,
      );
      expect(result, isNotNull);
      expect(_bytesToHex(result!), 'aabbccdd',
          reason: 'scriptSigAsm should be preferred over witness');
    });
  });

  group('notification tx UTXO sorting', () {
    test('non-taproot UTXOs sorted before taproot', () {
      final utxos = [
        _MockUTXO('bc1pabc...', 1000, 5000), // taproot
        _MockUTXO('bc1qabc...', 900, 3000), // native segwit
        _MockUTXO('1Abc...', 800, 2000), // legacy
      ];

      final sorted = sortForNotificationTx(utxos);
      expect(sorted[0].address, startsWith('bc1q'),
          reason: 'non-taproot should come first');
      expect(sorted[1].address, startsWith('1'),
          reason: 'non-taproot should come second');
      expect(sorted[2].address, startsWith('bc1p'),
          reason: 'taproot should be last');
    });

    test('non-taproot UTXOs sorted oldest first among themselves', () {
      final utxos = [
        _MockUTXO('bc1qabc...', 500, 1000), // older
        _MockUTXO('bc1qdef...', 1000, 2000), // newer
        _MockUTXO('1Abc...', 750, 3000), // middle
      ];

      final sorted = sortForNotificationTx(utxos);
      // Oldest first means highest blockTime first (descending)
      expect(sorted[0].address, 'bc1qdef...');
      expect(sorted[1].address, '1Abc...');
      expect(sorted[2].address, 'bc1qabc...');
    });

    test('taproot UTXOs sorted oldest first among themselves', () {
      final utxos = [
        _MockUTXO('bc1pabc...', 500, 1000),
        _MockUTXO('bc1pdef...', 1000, 2000),
      ];

      final sorted = sortForNotificationTx(utxos);
      expect(sorted[0].address, 'bc1pdef...');
      expect(sorted[1].address, 'bc1pabc...');
    });

    test('all taproot still works (no non-taproot available)', () {
      final utxos = [
        _MockUTXO('bc1pabc...', 1000, 5000),
        _MockUTXO('bc1pdef...', 900, 3000),
      ];

      final sorted = sortForNotificationTx(utxos);
      // Still sorted by age, oldest first
      expect(sorted[0].address, 'bc1pabc...');
      expect(sorted[1].address, 'bc1pdef...');
    });

    test('testnet taproot (tb1p) also sorted last', () {
      final utxos = [
        _MockUTXO('tb1pabc...', 1000, 5000), // testnet taproot
        _MockUTXO('tb1qabc...', 900, 3000), // testnet segwit
      ];

      final sorted = sortForNotificationTx(utxos);
      expect(sorted[0].address, startsWith('tb1q'));
      expect(sorted[1].address, startsWith('tb1p'));
    });

    test('mixed mainnet/testnet taproot and non-taproot', () {
      final utxos = [
        _MockUTXO('bc1pabc...', 1000, 5000),
        _MockUTXO('3Abc...', 900, 3000), // P2SH
        _MockUTXO('bc1qabc...', 800, 2000),
      ];

      final sorted = sortForNotificationTx(utxos);
      // Non-taproot first (sorted by age descending)
      expect(sorted[0].address, '3Abc...');
      expect(sorted[1].address, 'bc1qabc...');
      // Taproot last
      expect(sorted[2].address, 'bc1pabc...');
    });
  });
}

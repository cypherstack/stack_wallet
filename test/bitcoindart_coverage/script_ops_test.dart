// Coverage tests for bitcoindart Script/OpCode API.
// Commented out: bitcoindart is no longer a direct dependency.
// Kept as historical reference for the original API patterns.
// See equivalence test files (*_equiv_test.dart) for the active coin regression suite.

/*
import 'dart:typed_data';

import 'package:bitcoindart/src/utils/constants/op.dart' as op;
import 'package:bitcoindart/src/utils/script.dart' as bscript;
import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/services/coins/bitcoincash/bch_utils.dart';

import 'test_vectors.dart';

void main() {
  group('op.OPS constants', () {
    test('OP_RETURN equals 0x6a', () {
      expect(op.OPS['OP_RETURN'], equals(0x6a));
    });

    test('OP_DUP equals 0x76', () {
      expect(op.OPS['OP_DUP'], equals(0x76));
    });

    test('OP_HASH160 equals 0xa9', () {
      expect(op.OPS['OP_HASH160'], equals(0xa9));
    });

    test('OP_EQUALVERIFY equals 0x88', () {
      expect(op.OPS['OP_EQUALVERIFY'], equals(0x88));
    });

    test('OP_CHECKSIG equals 0xac', () {
      expect(op.OPS['OP_CHECKSIG'], equals(0xac));
    });
  });

  group('bscript.compile', () {
    test('OP_RETURN + 80-byte payload uses PUSHDATA1 encoding', () {
      final compiled = bscript.compile([
        (op.OPS['OP_RETURN'] as int),
        kPaynymBlindedCode,
      ]);

      // 80-byte payload > 75, so PUSHDATA1 encoding is used:
      // [0x6a (OP_RETURN), 0x4c (PUSHDATA1), 0x50 (length=80), ...80 data bytes]
      // Total: 1 + 1 + 1 + 80 = 83 bytes
      expect(compiled.length, equals(83));
      expect(compiled[0], equals(0x6a)); // OP_RETURN
      expect(compiled[1], equals(0x4c)); // PUSHDATA1
      expect(compiled[2], equals(0x50)); // length = 80
      expect(
        compiled.sublist(3),
        equals(kPaynymBlindedCode),
      );
    });

    test('OP_RETURN + small payload (<= 75 bytes) uses direct push', () {
      final smallPayload = Uint8List.fromList(List<int>.filled(20, 0xaa));
      final compiled = bscript.compile([
        (op.OPS['OP_RETURN'] as int),
        smallPayload,
      ]);

      // 20-byte payload <= 75, so direct push encoding:
      // [0x6a (OP_RETURN), 0x14 (length=20), ...20 data bytes]
      // Total: 1 + 1 + 20 = 22 bytes
      expect(compiled.length, equals(22));
      expect(compiled[0], equals(0x6a)); // OP_RETURN
      expect(compiled[1], equals(0x14)); // length = 20 (direct push)
      expect(compiled.sublist(2), equals(smallPayload));
    });

    test('compiles empty OP_RETURN (no data push)', () {
      final compiled = bscript.compile([
        (op.OPS['OP_RETURN'] as int),
      ]);

      // Just the opcode byte
      expect(compiled.length, equals(1));
      expect(compiled[0], equals(0x6a));
    });
  });

  group('bscript.decompile', () {
    test('SLP scriptPubKey decompiles with OP_RETURN and SLP identifier', () {
      final decompiled = bscript.decompile(kSlpScriptPubKey);

      expect(decompiled, isNotNull);
      expect(decompiled!.length, greaterThan(1));
      expect(decompiled.first, equals(op.OPS['OP_RETURN']));

      // Second element should be the SLP identifier bytes
      final slpId = decompiled[1];
      expect(slpId, isA<Uint8List>());
      expect((slpId as Uint8List).toList(), equals(kSlpId));
    });

    test('FUZE scriptPubKey decompiles with OP_RETURN, FUZE identifier, and session hash', () {
      final decompiled = bscript.decompile(kFuzeScriptPubKey);

      expect(decompiled, isNotNull);
      expect(decompiled!.length, greaterThan(2));
      expect(decompiled.first, equals(op.OPS['OP_RETURN']));

      // Second element: FUZE identifier
      final fuzeId = decompiled[1];
      expect(fuzeId, isA<Uint8List>());
      expect((fuzeId as Uint8List).toList(), equals(kFuzeId));

      // Third element: 32-byte session hash
      final sessionHash = decompiled[2];
      expect(sessionHash, isA<Uint8List>());
      expect((sessionHash as Uint8List).length, equals(32));
    });

    test('P2PKH scriptPubKey does NOT start with OP_RETURN', () {
      final decompiled = bscript.decompile(kNonSlpScriptPubKey);

      expect(decompiled, isNotNull);
      expect(decompiled!.first, isNot(equals(op.OPS['OP_RETURN'])));
      // First byte of P2PKH is OP_DUP (0x76)
      expect(decompiled.first, equals(op.OPS['OP_DUP']));
    });
  });

  group('BchUtils SLP/FUZE detection', () {
    test('isSLP returns true for kSlpScriptPubKey', () {
      expect(BchUtils.isSLP(kSlpScriptPubKey), isTrue);
    });

    test('isSLP returns false for kNonSlpScriptPubKey', () {
      expect(BchUtils.isSLP(kNonSlpScriptPubKey), isFalse);
    });

    test('isSLP returns false for kFuzeScriptPubKey', () {
      expect(BchUtils.isSLP(kFuzeScriptPubKey), isFalse);
    });

    test('isFUZE returns true for kFuzeScriptPubKey', () {
      expect(BchUtils.isFUZE(kFuzeScriptPubKey), isTrue);
    });

    test('isFUZE returns false for kNonSlpScriptPubKey', () {
      expect(BchUtils.isFUZE(kNonSlpScriptPubKey), isFalse);
    });

    test('isFUZE returns false for kSlpScriptPubKey', () {
      expect(BchUtils.isFUZE(kSlpScriptPubKey), isFalse);
    });
  });
}
*/

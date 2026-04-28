import 'dart:typed_data';

import 'package:coin/coin.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_vectors.dart';

void main() {
  group('Op constants equivalence', () {
    test('Op.returnOp matches bitcoindart OP_RETURN (0x6a)', () {
      expect(Op.returnOp, equals(0x6a));
    });

    test('Op.dup matches bitcoindart OP_DUP (0x76)', () {
      expect(Op.dup, equals(0x76));
    });

    test('Op.hash160 matches bitcoindart OP_HASH160 (0xa9)', () {
      expect(Op.hash160, equals(0xa9));
    });

    test('Op.equalVerify matches bitcoindart OP_EQUALVERIFY (0x88)', () {
      expect(Op.equalVerify, equals(0x88));
    });

    test('Op.checkSig matches bitcoindart OP_CHECKSIG (0xac)', () {
      expect(Op.checkSig, equals(0xac));
    });
  });

  group('Script.compile equivalence', () {
    test('OP_RETURN + 80-byte payload produces byte-identical output', () {
      final script = Script([
        OpCode(Op.returnOp),
        PushData(kPaynymBlindedCode),
      ]);
      final compiled = script.compiled;

      // Expected: [0x6a, 0x4c, 0x50, ...80 payload bytes] = 83 bytes
      // This matches exactly what bitcoindart bscript.compile produces
      expect(compiled.length, equals(83));
      expect(compiled[0], equals(0x6a)); // OP_RETURN
      expect(compiled[1], equals(0x4c)); // PUSHDATA1
      expect(compiled[2], equals(0x50)); // length = 80
      expect(compiled.sublist(3), equals(kPaynymBlindedCode));
    });

    test('OP_RETURN + small payload (<= 75 bytes) produces byte-identical output', () {
      final smallPayload = Uint8List.fromList(List<int>.filled(20, 0xaa));
      final script = Script([
        OpCode(Op.returnOp),
        PushData(smallPayload),
      ]);
      final compiled = script.compiled;

      // Expected: [0x6a, 0x14, ...20 data bytes] = 22 bytes
      // Direct push encoding, matching bitcoindart behavior
      expect(compiled.length, equals(22));
      expect(compiled[0], equals(0x6a)); // OP_RETURN
      expect(compiled[1], equals(0x14)); // length = 20 (direct push)
      expect(compiled.sublist(2), equals(smallPayload));
    });

    test('empty OP_RETURN produces byte-identical output', () {
      final script = Script([
        OpCode(Op.returnOp),
      ]);
      final compiled = script.compiled;

      expect(compiled.length, equals(1));
      expect(compiled[0], equals(0x6a));
    });
  });

  group('Script.decompile equivalence', () {
    test('SLP scriptPubKey decompiles with correct structure', () {
      final script = Script.decompile(kSlpScriptPubKey);

      // First op: OP_RETURN (0x6a)
      expect(script.ops.isNotEmpty, isTrue);
      expect(script.ops.first, isA<OpCode>());
      expect((script.ops.first as OpCode).code, equals(0x6a));

      // Second op: PushData with SLP identifier [83, 76, 80, 0]
      expect(script.ops.length, greaterThan(1));
      expect(script.ops[1], isA<PushData>());
      expect(
        (script.ops[1] as PushData).data.toList(),
        equals(kSlpId),
      );
    });

    test('FUZE scriptPubKey decompiles with FUZE identifier and session hash', () {
      final script = Script.decompile(kFuzeScriptPubKey);

      // First op: OP_RETURN
      expect(script.ops.first, isA<OpCode>());
      expect((script.ops.first as OpCode).code, equals(0x6a));

      // Second op: FUZE identifier [70, 85, 90, 0]
      expect(script.ops[1], isA<PushData>());
      expect(
        (script.ops[1] as PushData).data.toList(),
        equals(kFuzeId),
      );

      // Third op: 32-byte session hash
      expect(script.ops[2], isA<PushData>());
      expect((script.ops[2] as PushData).data.length, equals(32));
    });

    test('P2PKH scriptPubKey does NOT decompile with OP_RETURN first', () {
      final script = Script.decompile(kNonSlpScriptPubKey);

      expect(script.ops.isNotEmpty, isTrue);
      expect(script.ops.first, isA<OpCode>());
      // First opcode should be OP_DUP (0x76), not OP_RETURN
      expect((script.ops.first as OpCode).code, equals(Op.dup));
      expect((script.ops.first as OpCode).code, isNot(equals(Op.returnOp)));
    });

    test('decompiled OP_RETURN + 80-byte payload recompiles to identical bytes', () {
      // Use a script with no small-integer push ambiguity
      final opReturnScript = Uint8List.fromList([
        0x6a, // OP_RETURN
        0x4c, 0x50, // PUSHDATA1, length=80
        ...kPaynymBlindedCode,
      ]);
      final script = Script.decompile(opReturnScript);
      final recompiled = script.compiled;
      expect(recompiled, equals(opReturnScript));
    });

    test('decompiled FUZE script recompiles to identical bytes', () {
      final script = Script.decompile(kFuzeScriptPubKey);
      final recompiled = script.compiled;
      expect(recompiled, equals(kFuzeScriptPubKey));
    });
  });
}

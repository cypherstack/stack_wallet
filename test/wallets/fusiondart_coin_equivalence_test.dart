import 'dart:typed_data';

import 'package:coin/coin.dart' as coin;
import 'package:test/test.dart';
import 'package:hex/hex.dart';

/// Equivalence tests proving coin produces identical outputs to coinlib
/// for all fusion-critical operations: key generation, P2PKH address encoding,
/// script compilation, wire serialization, and hash160.
void main() {
  /// BCH mainnet chain (Bitcoin Cash uses same prefixes as Bitcoin mainnet
  /// for P2PKH/P2SH but no segwit/taproot).
  final bchMainnet = coin.Chain(
    wifPrefix: 0x80,
    p2pkhPrefix: 0x00,
    p2shPrefix: 0x05,
    bech32Hrp: 'bc',
    name: 'Bitcoin Cash',
    bip44CoinType: 145,
    supportsSegwit: false,
    supportsTaproot: false,
    privHDPrefix: 0x0488ade4,
    pubHDPrefix: 0x0488b21e,
  );

  /// BCH testnet chain.
  final bchTestnet = coin.Chain(
    wifPrefix: 0xef,
    p2pkhPrefix: 0x6f,
    p2shPrefix: 0xc4,
    bech32Hrp: 'tb',
    name: 'Bitcoin Cash Testnet',
    bip44CoinType: 1,
    supportsSegwit: false,
    supportsTaproot: false,
    privHDPrefix: 0x04358394,
    pubHDPrefix: 0x043587cf,
  );

  setUpAll(() async {
    await coin.initCoin();
  });

  group('SecretKey generation', () {
    test('generates valid 32-byte private key with 33-byte compressed pubkey',
        () {
      final sk = coin.SecretKey.generate();
      expect(sk.bytes.length, 32);
      expect(sk.publicKey.bytes.length, 33);
      // Compressed pubkey starts with 0x02 or 0x03
      expect(sk.publicKey.bytes[0] == 0x02 || sk.publicKey.bytes[0] == 0x03,
          isTrue);
    });

    test('creates SecretKey from known 32-byte hex', () {
      // Generator scalar 1 (padded to 32 bytes)
      final sk = coin.SecretKey(Uint8List.fromList([
        ...List.filled(31, 0),
        1,
      ]));
      expect(sk.bytes.length, 32);
      expect(sk.publicKey.bytes.length, 33);
      // Pubkey for scalar 1 is the generator point G
      expect(
        HEX.encode(sk.publicKey.bytes),
        '0279be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798',
      );
    });
  });

  group('P2PKH address from pubkey', () {
    test('known generator point produces correct mainnet P2PKH address', () {
      final pubKeyBytes = Uint8List.fromList(
        HEX.decode(
            '0279be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798'),
      );
      final hash = coin.hash160(pubKeyBytes);
      expect(HEX.encode(hash), '751e76e8199196d454941c45d1b3a323f1433bd6');

      final addr = coin.P2pkhAddr(hash);
      expect(addr.encode(bchMainnet), '1BgGZ9tcN4rm9KBzDn7KprQz87SZ26SAMH');
    });

    test('known generator point produces correct testnet P2PKH address', () {
      final pubKeyBytes = Uint8List.fromList(
        HEX.decode(
            '0279be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798'),
      );
      final hash = coin.hash160(pubKeyBytes);
      final addr = coin.P2pkhAddr(hash);
      expect(addr.encode(bchTestnet), 'mrCDrCybB6J1vRfbwM5hemdJz73FwDBC8r');
    });
  });

  group('Addr.fromString round-trip', () {
    test('produces correct P2PKH scriptPubKey from address string', () {
      final addr = coin.Addr.fromString(
        '1BgGZ9tcN4rm9KBzDn7KprQz87SZ26SAMH',
        bchMainnet,
      );
      // P2PKH scriptPubKey: OP_DUP OP_HASH160 <20-byte hash> OP_EQUALVERIFY OP_CHECKSIG
      expect(
        HEX.encode(addr.scriptPubKey),
        '76a914751e76e8199196d454941c45d1b3a323f1433bd688ac',
      );
    });
  });

  group('PayToPubKeyHash script compilation', () {
    test('produces standard 25-byte P2PKH script', () {
      final hash = Uint8List.fromList(
        HEX.decode('751e76e8199196d454941c45d1b3a323f1433bd6'),
      );
      final locking = coin.PayToPubKeyHash(hash);
      final compiled = locking.compiled;
      expect(compiled.length, 25);
      expect(
        HEX.encode(compiled),
        '76a914751e76e8199196d454941c45d1b3a323f1433bd688ac',
      );
    });
  });

  group('Script.decompile round-trip', () {
    test('P2PKH script decompile then compile equals original', () {
      final original = Uint8List.fromList(
        HEX.decode(
            '76a914751e76e8199196d454941c45d1b3a323f1433bd688ac'),
      );
      final script = coin.Script.decompile(original);
      expect(script.compiled, original);
    });

    test('OP_RETURN script decompile then compile equals original', () {
      // OP_RETURN OP_PUSHDATA(4 bytes "FUSE") OP_PUSHDATA(32 bytes session hash)
      final opReturnBytes = Uint8List.fromList([
        0x6a, // OP_RETURN
        0x04, // push 4 bytes
        0x46, 0x55, 0x53, 0x45, // "FUSE"
        0x20, // push 32 bytes
        ...List.filled(32, 0xab), // 32-byte session hash placeholder
      ]);
      final script = coin.Script.decompile(opReturnBytes);
      expect(script.compiled, opReturnBytes);
    });
  });

  group('Outpoint serialization', () {
    test('zero txid and vout 0 produces 36 zero bytes', () {
      final outpoint = coin.Outpoint(
        txid: Uint8List(32),
        vout: 0,
      );
      final bytes = outpoint.toBytes();
      expect(bytes.length, 36);
      expect(bytes, Uint8List(36));
    });

    test('zero txid and vout 1 produces correct wire format', () {
      final outpoint = coin.Outpoint(
        txid: Uint8List(32),
        vout: 1,
      );
      final bytes = outpoint.toBytes();
      expect(bytes.length, 36);
      // First 32 bytes are zero (txid)
      expect(bytes.sublist(0, 32), Uint8List(32));
      // Last 4 bytes are vout=1 in little-endian
      expect(bytes.sublist(32), Uint8List.fromList([0x01, 0x00, 0x00, 0x00]));
    });
  });

  group('TxOutput serialization', () {
    test('546-sat output with P2PKH script produces correct wire format', () {
      final hash = Uint8List.fromList(
        HEX.decode('751e76e8199196d454941c45d1b3a323f1433bd6'),
      );
      final scriptPubKey = coin.PayToPubKeyHash(hash).compiled;
      expect(scriptPubKey.length, 25);

      final txOut = coin.TxOutput(
        value: BigInt.from(546),
        scriptPubKey: scriptPubKey,
      );
      final bytes = txOut.toBytes();
      // 8-byte LE value + 1-byte varint(25) + 25-byte script = 34 bytes
      expect(bytes.length, 34);

      // Value: 546 = 0x0222 in little-endian 8 bytes
      expect(bytes.sublist(0, 8),
          Uint8List.fromList([0x22, 0x02, 0, 0, 0, 0, 0, 0]));
      // Varint: 25 = 0x19
      expect(bytes[8], 0x19);
      // Script
      expect(bytes.sublist(9), scriptPubKey);
    });
  });

  group('WireWriter and WireMeasure', () {
    test('WireMeasure matches WireWriter output length', () {
      // Write: writeUInt32(1) + writeSlice(4 bytes) + writeVarSlice(3 bytes)
      // Expected: 4 + 4 + (1 + 3) = 12 bytes

      // Measure
      final measure = coin.WireMeasure();
      measure.writeUInt32(1);
      measure.writeSlice(Uint8List(4));
      measure.writeVarSlice(Uint8List(3));
      expect(measure.size, 12);

      // Write
      final buffer = Uint8List(12);
      final writer = coin.WireWriter(buffer);
      writer.writeUInt32(1);
      writer.writeSlice(Uint8List(4));
      writer.writeVarSlice(Uint8List(3));

      expect(writer.offset, 12);
      expect(writer.offset, measure.size);

      // Verify written content
      // writeUInt32(1): [0x01, 0x00, 0x00, 0x00]
      expect(buffer.sublist(0, 4),
          Uint8List.fromList([0x01, 0x00, 0x00, 0x00]));
      // writeSlice(4 zeros): [0x00, 0x00, 0x00, 0x00]
      expect(buffer.sublist(4, 8), Uint8List(4));
      // writeVarSlice(3 zeros): varint(3) + [0x00, 0x00, 0x00]
      expect(buffer[8], 3); // varint for length 3
      expect(buffer.sublist(9, 12), Uint8List(3));
    });
  });

  group('hash160', () {
    test('empty input produces known hash160', () {
      final result = coin.hash160(Uint8List(0));
      expect(
        HEX.encode(result),
        'b472a266d0bd89c13706a4132ccfb16f7c3b9fcb',
      );
    });

    test('generator pubkey produces known hash160', () {
      final pubKeyBytes = Uint8List.fromList(
        HEX.decode(
            '0279be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798'),
      );
      final result = coin.hash160(pubKeyBytes);
      expect(
        HEX.encode(result),
        '751e76e8199196d454941c45d1b3a323f1433bd6',
      );
    });
  });
}

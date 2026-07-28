import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/wallets/hardware/psbt_builder.dart';

/// Helper to create a 32-byte txid from a hex string (reversed to internal byte order).
Uint8List _txidFromHex(String hex) {
  final bytes = List<int>.generate(
    hex.length ~/ 2,
    (i) => int.parse(hex.substring(i * 2, i * 2 + 2), radix: 16),
  );
  return Uint8List.fromList(bytes.reversed.toList());
}

/// Helper to create a P2WPKH scriptPubKey: OP_0 <20-byte-hash>.
Uint8List _p2wpkhScript(Uint8List pubkeyHash) {
  return Uint8List.fromList([0x00, 0x14, ...pubkeyHash]);
}

/// Fake 33-byte compressed public key.
Uint8List _fakePubKey([int fill = 0x02]) {
  final pk = Uint8List(33);
  pk[0] = fill;
  for (int i = 1; i < 33; i++) {
    pk[i] = i;
  }
  return pk;
}

/// Fake 20-byte pubkey hash.
Uint8List _fakePubKeyHash([int fill = 0xaa]) {
  return Uint8List.fromList(List.filled(20, fill));
}

/// Standard 4-byte master fingerprint.
Uint8List _masterFingerprint() => Uint8List.fromList([0x12, 0x34, 0x56, 0x78]);

/// BIP-84 derivation path: m/84'/0'/0'/0/0 with hardened markers.
List<int> _bip84Path({int change = 0, int index = 0}) => [
      0x80000000 + 84, // 84'
      0x80000000 + 0, // 0'
      0x80000000 + 0, // 0'
      change,
      index,
    ];

void main() {
  group('PsbtBuilder', () {
    test('output starts with BIP-174 magic bytes', () {
      final psbtBase64 = _buildSimplePsbt();
      final bytes = base64Decode(psbtBase64);

      // "psbt" + 0xff
      expect(bytes[0], 0x70); // 'p'
      expect(bytes[1], 0x73); // 's'
      expect(bytes[2], 0x62); // 'b'
      expect(bytes[3], 0x74); // 't'
      expect(bytes[4], 0xff); // separator
    });

    test('single input single output P2WPKH produces valid structure', () {
      final psbtBase64 = _buildSimplePsbt();
      final bytes = base64Decode(psbtBase64);

      // After magic (5 bytes), we should have:
      // - Global map with unsigned tx (key 0x00), then separator 0x00
      // - One input map, then separator 0x00
      // - One output map, then separator 0x00
      expect(bytes.length, greaterThan(5));

      // Verify we can decode it back -- round trip.
      final reEncoded = base64Encode(bytes);
      expect(reEncoded, psbtBase64);
    });

    test('global map contains unsigned transaction', () {
      final psbtBase64 = _buildSimplePsbt();
      final bytes = base64Decode(psbtBase64);

      // Skip magic.
      int offset = 5;

      // First key-value pair: key length (varint), key, value length, value.
      final keyLen = bytes[offset++];
      expect(keyLen, 1); // Key is just the type byte.
      final keyType = bytes[offset++];
      expect(keyType, 0x00); // Global unsigned tx key.

      // Value length (varint) -- read it.
      final valLen = bytes[offset];
      expect(valLen, greaterThan(10)); // Unsigned tx is at least ~50 bytes.
    });

    test('base64 encoding is valid and decodable', () {
      final psbtBase64 = _buildSimplePsbt();

      // Should not throw.
      final bytes = base64Decode(psbtBase64);
      expect(bytes.length, greaterThan(0));

      // Re-encode should match.
      expect(base64Encode(bytes), psbtBase64);
    });

    test('multi-input PSBT has correct number of input sections', () {
      final inputs = [
        PsbtInput(
          txid: _txidFromHex(
            'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
          ),
          vout: 0,
          value: 50000,
          scriptPubKey: _p2wpkhScript(_fakePubKeyHash(0xaa)),
          derivationPath: _bip84Path(index: 0),
          publicKey: _fakePubKey(0x02),
        ),
        PsbtInput(
          txid: _txidFromHex(
            'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb',
          ),
          vout: 1,
          value: 30000,
          scriptPubKey: _p2wpkhScript(_fakePubKeyHash(0xbb)),
          derivationPath: _bip84Path(index: 1),
          publicKey: _fakePubKey(0x03),
        ),
      ];

      final outputs = [
        PsbtOutput(
          value: 70000,
          scriptPubKey: _p2wpkhScript(_fakePubKeyHash(0xcc)),
        ),
      ];

      final builder = PsbtBuilder(
        masterFingerprint: _masterFingerprint(),
        inputs: inputs,
        outputs: outputs,
      );

      final psbtBase64 = builder.build();
      final bytes = base64Decode(psbtBase64);

      // Verify the unsigned tx in the global section has 2 inputs.
      // Skip magic (5), parse global key-value.
      int offset = 5;
      final keyLen = bytes[offset++];
      offset += keyLen; // skip key
      int valLen = bytes[offset++];
      // Read unsigned tx.
      final unsignedTx = bytes.sublist(offset, offset + valLen);
      offset = 4; // skip version in unsigned tx
      final inputCount = unsignedTx[offset];
      expect(inputCount, 2);
    });

    test('change output includes BIP32 derivation', () {
      final changePubKey = _fakePubKey(0x03);
      final changePath = _bip84Path(change: 1, index: 0);

      final builder = PsbtBuilder(
        masterFingerprint: _masterFingerprint(),
        inputs: [
          PsbtInput(
            txid: _txidFromHex(
              'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
            ),
            vout: 0,
            value: 50000,
            scriptPubKey: _p2wpkhScript(_fakePubKeyHash(0xaa)),
            derivationPath: _bip84Path(index: 0),
            publicKey: _fakePubKey(0x02),
          ),
        ],
        outputs: [
          PsbtOutput(
            value: 30000,
            scriptPubKey: _p2wpkhScript(_fakePubKeyHash(0xcc)),
          ),
          PsbtOutput(
            value: 19000,
            scriptPubKey: _p2wpkhScript(_fakePubKeyHash(0xdd)),
            isChange: true,
            derivationPath: changePath,
            publicKey: changePubKey,
          ),
        ],
      );

      final psbtBase64 = builder.build();
      final bytes = base64Decode(psbtBase64);

      // The PSBT should contain the change pubkey somewhere in the output section.
      final pubKeyHex = changePubKey
          .map((b) => b.toRadixString(16).padLeft(2, '0'))
          .join();
      final psbtHex =
          bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
      expect(psbtHex.contains(pubKeyHex), true);
    });

    test('throws on empty inputs', () {
      expect(
        () => PsbtBuilder(
          masterFingerprint: _masterFingerprint(),
          inputs: [],
          outputs: [
            PsbtOutput(
              value: 50000,
              scriptPubKey: _p2wpkhScript(_fakePubKeyHash()),
            ),
          ],
        ),
        throwsArgumentError,
      );
    });

    test('throws on empty outputs', () {
      expect(
        () => PsbtBuilder(
          masterFingerprint: _masterFingerprint(),
          inputs: [
            PsbtInput(
              txid: _txidFromHex(
                'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
              ),
              vout: 0,
              value: 50000,
              scriptPubKey: _p2wpkhScript(_fakePubKeyHash()),
              derivationPath: _bip84Path(),
              publicKey: _fakePubKey(),
            ),
          ],
          outputs: [],
        ),
        throwsArgumentError,
      );
    });

    test('throws on invalid txid length', () {
      expect(
        () => PsbtBuilder(
          masterFingerprint: _masterFingerprint(),
          inputs: [
            PsbtInput(
              txid: Uint8List.fromList([0x01, 0x02]),
              vout: 0,
              value: 50000,
              scriptPubKey: _p2wpkhScript(_fakePubKeyHash()),
              derivationPath: _bip84Path(),
              publicKey: _fakePubKey(),
            ),
          ],
          outputs: [
            PsbtOutput(
              value: 50000,
              scriptPubKey: _p2wpkhScript(_fakePubKeyHash()),
            ),
          ],
        ),
        throwsArgumentError,
      );
    });

    test('throws on invalid pubkey length', () {
      expect(
        () => PsbtBuilder(
          masterFingerprint: _masterFingerprint(),
          inputs: [
            PsbtInput(
              txid: _txidFromHex(
                'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
              ),
              vout: 0,
              value: 50000,
              scriptPubKey: _p2wpkhScript(_fakePubKeyHash()),
              derivationPath: _bip84Path(),
              publicKey: Uint8List.fromList([0x02, 0x03]),
            ),
          ],
          outputs: [
            PsbtOutput(
              value: 50000,
              scriptPubKey: _p2wpkhScript(_fakePubKeyHash()),
            ),
          ],
        ),
        throwsArgumentError,
      );
    });

    test('throws on change output without derivation', () {
      expect(
        () => PsbtBuilder(
          masterFingerprint: _masterFingerprint(),
          inputs: [
            PsbtInput(
              txid: _txidFromHex(
                'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
              ),
              vout: 0,
              value: 50000,
              scriptPubKey: _p2wpkhScript(_fakePubKeyHash()),
              derivationPath: _bip84Path(),
              publicKey: _fakePubKey(),
            ),
          ],
          outputs: [
            PsbtOutput(
              value: 50000,
              scriptPubKey: _p2wpkhScript(_fakePubKeyHash()),
              isChange: true,
              // Missing derivationPath and publicKey.
            ),
          ],
        ),
        throwsArgumentError,
      );
    });

    test('throws on invalid masterFingerprint length', () {
      expect(
        () => PsbtBuilder(
          masterFingerprint: Uint8List.fromList([0x01]),
          inputs: [
            PsbtInput(
              txid: _txidFromHex(
                'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
              ),
              vout: 0,
              value: 50000,
              scriptPubKey: _p2wpkhScript(_fakePubKeyHash()),
              derivationPath: _bip84Path(),
              publicKey: _fakePubKey(),
            ),
          ],
          outputs: [
            PsbtOutput(
              value: 50000,
              scriptPubKey: _p2wpkhScript(_fakePubKeyHash()),
            ),
          ],
        ),
        throwsArgumentError,
      );
    });
  });

  group('PsbtFinalizer', () {
    test('round-trip: build PSBT, inject signature, finalize to raw tx', () {
      // Build a PSBT.
      final pubKey = _fakePubKey(0x02);
      final psbtBase64 = _buildSimplePsbt(pubKey: pubKey);

      // Manually inject a partial signature into the PSBT.
      final signedPsbt = _injectPartialSignature(psbtBase64, pubKey);

      // Finalize.
      final finalizer = PsbtFinalizer();
      final rawTxHex = finalizer.finalize(signedPsbt);

      // The raw tx hex should:
      // - Start with version bytes (02000000).
      // - Contain segwit marker (0001) after version.
      // - End with locktime bytes (00000000).
      expect(rawTxHex.startsWith('02000000'), true);
      expect(rawTxHex.substring(8, 12), '0001'); // segwit marker + flag
      expect(rawTxHex.endsWith('00000000'), true);
    });

    test('throws on invalid magic bytes', () {
      final badPsbt = base64Encode(Uint8List.fromList([0x00, 0x01, 0x02]));
      final finalizer = PsbtFinalizer();
      expect(
        () => finalizer.finalize(badPsbt),
        throwsFormatException,
      );
    });

    test('throws on missing partial signature', () {
      // Build a valid PSBT but don't inject any signature.
      final psbtBase64 = _buildSimplePsbt();
      final finalizer = PsbtFinalizer();
      expect(
        () => finalizer.finalize(psbtBase64),
        throwsFormatException,
      );
    });
  });
}

/// Build a simple single-input single-output PSBT for testing.
String _buildSimplePsbt({Uint8List? pubKey}) {
  pubKey ??= _fakePubKey(0x02);
  final builder = PsbtBuilder(
    masterFingerprint: _masterFingerprint(),
    inputs: [
      PsbtInput(
        txid: _txidFromHex(
          'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
        ),
        vout: 0,
        value: 50000,
        scriptPubKey: _p2wpkhScript(_fakePubKeyHash(0xaa)),
        derivationPath: _bip84Path(index: 0),
        publicKey: pubKey,
      ),
    ],
    outputs: [
      PsbtOutput(
        value: 49000,
        scriptPubKey: _p2wpkhScript(_fakePubKeyHash(0xbb)),
      ),
    ],
  );
  return builder.build();
}

/// Inject a fake partial signature into a PSBT for testing PsbtFinalizer.
/// This modifies the raw PSBT bytes by replacing the input map section
/// with one that includes a partial_sig entry (key 0x02 + pubkey).
String _injectPartialSignature(String psbtBase64, Uint8List pubKey) {
  final original = base64Decode(psbtBase64);
  final result = BytesBuilder();

  // Copy magic.
  result.add(original.sublist(0, 5));

  int offset = 5;

  // Copy global map as-is until separator.
  while (offset < original.length) {
    final keyLen = original[offset];
    if (keyLen == 0) {
      result.addByte(0x00);
      offset++;
      break;
    }
    // Copy this key-value pair.
    final start = offset;
    offset++; // keyLen byte
    offset += keyLen; // key bytes
    final valLen = original[offset];
    offset++; // valLen byte
    offset += valLen; // value bytes
    result.add(original.sublist(start, offset));
  }

  // Rewrite input map: copy existing entries, then add partial_sig before separator.
  final inputEntries = BytesBuilder();
  while (offset < original.length) {
    final keyLen = original[offset];
    if (keyLen == 0) {
      offset++;
      break;
    }
    final start = offset;
    offset++;
    offset += keyLen;
    final valLen = original[offset];
    offset++;
    offset += valLen;
    inputEntries.add(original.sublist(start, offset));
  }

  result.add(inputEntries.toBytes());

  // Add partial signature: key = 0x02 + pubkey (34 bytes), value = fake DER sig.
  final fakeSig = Uint8List.fromList([
    0x30, 0x44, // DER sequence, length 68
    0x02, 0x20, // integer, length 32
    ...List.filled(32, 0x01), // r value
    0x02, 0x20, // integer, length 32
    ...List.filled(32, 0x02), // s value
    0x01, // SIGHASH_ALL
  ]);

  // Key: type 0x02 + 33 byte pubkey = 34 bytes.
  final sigKey = Uint8List.fromList([0x02, ...pubKey]);
  _writeVarint(result, sigKey.length);
  result.add(sigKey);
  _writeVarint(result, fakeSig.length);
  result.add(fakeSig);

  // Input separator.
  result.addByte(0x00);

  // Copy remaining output maps.
  while (offset < original.length) {
    result.addByte(original[offset]);
    offset++;
  }

  return base64Encode(result.toBytes());
}

void _writeVarint(BytesBuilder buf, int value) {
  if (value < 0xfd) {
    buf.addByte(value);
  } else if (value <= 0xffff) {
    buf.addByte(0xfd);
    buf.addByte(value & 0xff);
    buf.addByte((value >> 8) & 0xff);
  }
}

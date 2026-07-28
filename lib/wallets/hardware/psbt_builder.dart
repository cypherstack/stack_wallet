import 'dart:convert';
import 'dart:typed_data';

/// BIP-174 PSBT magic bytes: "psbt" + 0xff separator.
const List<int> _psbtMagic = [0x70, 0x73, 0x62, 0x74, 0xff];

/// BIP-174 global key types.
const int _globalUnsignedTx = 0x00;

/// BIP-174 per-input key types.
const int _inputWitnessUtxo = 0x01;
const int _inputPartialSig = 0x02;
const int _inputBip32Derivation = 0x06;

/// BIP-174 per-output key types.
const int _outputBip32Derivation = 0x06;

/// Separator byte that terminates each key-value map.
const int _separator = 0x00;

class PsbtInput {
  /// 32-byte txid in internal (little-endian) byte order.
  final Uint8List txid;

  /// Output index in the previous transaction.
  final int vout;

  /// Value in satoshis.
  final int value;

  /// The scriptPubKey of the UTXO being spent (for P2WPKH: OP_0 <20-byte-hash>).
  final Uint8List scriptPubKey;

  /// BIP32 derivation path components (e.g. [84, 0, 0, 0, 5] for m/84'/0'/0'/0/5).
  /// Hardened indices should have 0x80000000 added.
  final List<int> derivationPath;

  /// Compressed public key (33 bytes).
  final Uint8List publicKey;

  PsbtInput({
    required this.txid,
    required this.vout,
    required this.value,
    required this.scriptPubKey,
    required this.derivationPath,
    required this.publicKey,
  });
}

class PsbtOutput {
  /// Value in satoshis.
  final int value;

  /// The scriptPubKey for this output.
  final Uint8List scriptPubKey;

  /// Whether this is a change output (owned by the wallet).
  final bool isChange;

  /// BIP32 derivation path (required for change outputs).
  final List<int>? derivationPath;

  /// Compressed public key (required for change outputs).
  final Uint8List? publicKey;

  PsbtOutput({
    required this.value,
    required this.scriptPubKey,
    this.isChange = false,
    this.derivationPath,
    this.publicKey,
  });
}

class PsbtBuilder {
  /// 4-byte master key fingerprint.
  final Uint8List masterFingerprint;

  final List<PsbtInput> inputs;
  final List<PsbtOutput> outputs;

  /// Transaction version (default 2).
  final int txVersion;

  /// Locktime (default 0).
  final int locktime;

  PsbtBuilder({
    required this.masterFingerprint,
    required this.inputs,
    required this.outputs,
    this.txVersion = 2,
    this.locktime = 0,
  }) {
    if (inputs.isEmpty) {
      throw ArgumentError('PSBT must have at least one input');
    }
    if (outputs.isEmpty) {
      throw ArgumentError('PSBT must have at least one output');
    }
    for (final input in inputs) {
      if (input.txid.length != 32) {
        throw ArgumentError(
          'Input txid must be 32 bytes, got ${input.txid.length}',
        );
      }
      if (input.publicKey.length != 33) {
        throw ArgumentError(
          'Input publicKey must be 33 bytes (compressed), '
          'got ${input.publicKey.length}',
        );
      }
    }
    for (final output in outputs) {
      if (output.isChange) {
        if (output.derivationPath == null || output.publicKey == null) {
          throw ArgumentError(
            'Change outputs must include derivationPath and publicKey',
          );
        }
      }
    }
    if (masterFingerprint.length != 4) {
      throw ArgumentError(
        'masterFingerprint must be 4 bytes, got ${masterFingerprint.length}',
      );
    }
  }

  /// Build a base64-encoded BIP-174 PSBT string.
  String build() {
    final buf = BytesBuilder();

    // Magic bytes.
    buf.add(_psbtMagic);

    // --- Global map ---
    final unsignedTx = _buildUnsignedTx();
    _writeKeyValue(buf, key: [_globalUnsignedTx], value: unsignedTx);
    buf.addByte(_separator);

    // --- Per-input maps ---
    for (final input in inputs) {
      // Witness UTXO (key 0x01): serialized previous TxOut.
      final witnessUtxo = _serializeTxOut(input.value, input.scriptPubKey);
      _writeKeyValue(buf, key: [_inputWitnessUtxo], value: witnessUtxo);

      // BIP32 derivation (key 0x06 + pubkey): fingerprint + path.
      final bip32Key = <int>[_inputBip32Derivation, ...input.publicKey];
      final bip32Value = _serializeBip32Derivation(
        masterFingerprint,
        input.derivationPath,
      );
      _writeKeyValue(buf, key: bip32Key, value: bip32Value);

      buf.addByte(_separator);
    }

    // --- Per-output maps ---
    for (final output in outputs) {
      if (output.isChange &&
          output.derivationPath != null &&
          output.publicKey != null) {
        final bip32Key = <int>[_outputBip32Derivation, ...output.publicKey!];
        final bip32Value = _serializeBip32Derivation(
          masterFingerprint,
          output.derivationPath!,
        );
        _writeKeyValue(buf, key: bip32Key, value: bip32Value);
      }
      buf.addByte(_separator);
    }

    return base64Encode(buf.toBytes());
  }

  /// Build the unsigned transaction (no witness, empty scriptSig).
  Uint8List _buildUnsignedTx() {
    final buf = BytesBuilder();

    // Version (4 bytes LE).
    buf.add(_uint32LE(txVersion));

    // Input count (varint).
    buf.add(_varint(inputs.length));

    for (final input in inputs) {
      // Previous outpoint: txid (32 bytes, already internal/LE order) + vout (4 bytes LE).
      buf.add(input.txid);
      buf.add(_uint32LE(input.vout));
      // scriptSig: empty (varint 0x00).
      buf.addByte(0x00);
      // Sequence: 0xfffffffd (RBF-enabled default).
      buf.add(_uint32LE(0xfffffffd));
    }

    // Output count (varint).
    buf.add(_varint(outputs.length));

    for (final output in outputs) {
      // Value (8 bytes LE).
      buf.add(_uint64LE(output.value));
      // scriptPubKey with varint length prefix.
      buf.add(_varint(output.scriptPubKey.length));
      buf.add(output.scriptPubKey);
    }

    // Locktime (4 bytes LE).
    buf.add(_uint32LE(locktime));

    return buf.toBytes();
  }

  /// Serialize a TxOut: value (8 bytes LE) + scriptPubKey with compact size.
  Uint8List _serializeTxOut(int value, Uint8List scriptPubKey) {
    final buf = BytesBuilder();
    buf.add(_uint64LE(value));
    buf.add(_varint(scriptPubKey.length));
    buf.add(scriptPubKey);
    return buf.toBytes();
  }

  /// Serialize BIP32 derivation: 4-byte fingerprint + path as uint32 LE values.
  Uint8List _serializeBip32Derivation(
    Uint8List fingerprint,
    List<int> path,
  ) {
    final buf = BytesBuilder();
    buf.add(fingerprint);
    for (final component in path) {
      buf.add(_uint32LE(component));
    }
    return buf.toBytes();
  }

  /// Write a BIP-174 key-value pair: <varint keyLen><key><varint valueLen><value>.
  void _writeKeyValue(
    BytesBuilder buf, {
    required List<int> key,
    required Uint8List value,
  }) {
    buf.add(_varint(key.length));
    buf.add(key);
    buf.add(_varint(value.length));
    buf.add(value);
  }
}

class PsbtFinalizer {
  /// Parse a signed PSBT (base64) and extract the finalized raw transaction hex.
  ///
  /// Expects each input to have a partial signature (key 0x02) from Ledger signing.
  /// Constructs witness data (signature + pubkey) and builds the final
  /// segwit transaction with witness flag.
  String finalize(String signedPsbtBase64) {
    final bytes = base64Decode(signedPsbtBase64);
    final reader = _PsbtReader(bytes);

    // Verify magic.
    final magic = reader.readBytes(5);
    for (int i = 0; i < 5; i++) {
      if (magic[i] != _psbtMagic[i]) {
        throw FormatException('Invalid PSBT magic bytes');
      }
    }

    // Parse global map -- extract unsigned tx.
    Uint8List? unsignedTx;
    while (true) {
      final keyLen = reader.readVarint();
      if (keyLen == 0) break;
      final key = reader.readBytes(keyLen);
      final valLen = reader.readVarint();
      final val = reader.readBytes(valLen);
      if (key[0] == _globalUnsignedTx) {
        unsignedTx = val;
      }
    }
    if (unsignedTx == null) {
      throw FormatException('PSBT missing global unsigned transaction');
    }

    // Parse unsigned tx to get input/output counts.
    final txReader = _PsbtReader(unsignedTx);
    final version = txReader.readUint32LE();
    final inputCount = txReader.readVarint();

    // Read inputs from unsigned tx (to get outpoints and sequences).
    final txInputs = <_TxInput>[];
    for (int i = 0; i < inputCount; i++) {
      final prevTxid = txReader.readBytes(32);
      final prevVout = txReader.readUint32LE();
      final scriptSigLen = txReader.readVarint();
      txReader.readBytes(scriptSigLen); // skip scriptSig (empty in PSBT)
      final sequence = txReader.readUint32LE();
      txInputs.add(_TxInput(
        prevTxid: prevTxid,
        prevVout: prevVout,
        sequence: sequence,
      ));
    }

    final outputCount = txReader.readVarint();
    final outputsRaw = BytesBuilder();
    for (int i = 0; i < outputCount; i++) {
      final valBytes = txReader.readBytes(8);
      outputsRaw.add(valBytes);
      final spkLen = txReader.readVarint();
      outputsRaw.add(_varint(spkLen));
      outputsRaw.add(txReader.readBytes(spkLen));
    }
    final locktime = txReader.readUint32LE();

    // Parse per-input maps to extract partial signatures and pubkeys.
    final witnesses = <_WitnessData>[];
    for (int i = 0; i < inputCount; i++) {
      Uint8List? signature;
      Uint8List? pubKey;
      while (true) {
        final keyLen = reader.readVarint();
        if (keyLen == 0) break;
        final key = reader.readBytes(keyLen);
        final valLen = reader.readVarint();
        final val = reader.readBytes(valLen);
        if (key[0] == _inputPartialSig && key.length == 34) {
          signature = val;
          pubKey = Uint8List.fromList(key.sublist(1));
        }
      }
      if (signature == null || pubKey == null) {
        throw FormatException('Input $i missing partial signature in PSBT');
      }
      witnesses.add(_WitnessData(signature: signature, pubKey: pubKey));
    }

    // Skip per-output maps.
    for (int i = 0; i < outputCount; i++) {
      while (true) {
        final keyLen = reader.readVarint();
        if (keyLen == 0) break;
        reader.readBytes(keyLen);
        final valLen = reader.readVarint();
        reader.readBytes(valLen);
      }
    }

    // Build final segwit transaction.
    final finalTx = BytesBuilder();
    finalTx.add(_uint32LE(version));

    // Segwit marker + flag.
    finalTx.addByte(0x00); // marker
    finalTx.addByte(0x01); // flag

    // Inputs (with empty scriptSig -- witnesses carry the data).
    finalTx.add(_varint(inputCount));
    for (final txIn in txInputs) {
      finalTx.add(txIn.prevTxid);
      finalTx.add(_uint32LE(txIn.prevVout));
      finalTx.addByte(0x00); // empty scriptSig
      finalTx.add(_uint32LE(txIn.sequence));
    }

    // Outputs.
    finalTx.add(_varint(outputCount));
    finalTx.add(outputsRaw.toBytes());

    // Witness data for each input: <count> <sig_len> <sig> <pubkey_len> <pubkey>.
    for (final w in witnesses) {
      finalTx.add(_varint(2)); // two witness items
      finalTx.add(_varint(w.signature.length));
      finalTx.add(w.signature);
      finalTx.add(_varint(w.pubKey.length));
      finalTx.add(w.pubKey);
    }

    // Locktime.
    finalTx.add(_uint32LE(locktime));

    // Return hex.
    return finalTx.toBytes().map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }
}

// --- Internal helpers ---

class _TxInput {
  final Uint8List prevTxid;
  final int prevVout;
  final int sequence;
  _TxInput({
    required this.prevTxid,
    required this.prevVout,
    required this.sequence,
  });
}

class _WitnessData {
  final Uint8List signature;
  final Uint8List pubKey;
  _WitnessData({required this.signature, required this.pubKey});
}

class _PsbtReader {
  final Uint8List _data;
  int _offset = 0;

  _PsbtReader(this._data);

  Uint8List readBytes(int count) {
    if (_offset + count > _data.length) {
      throw FormatException(
        'Unexpected end of PSBT data at offset $_offset '
        '(need $count bytes, have ${_data.length - _offset})',
      );
    }
    final result = Uint8List.fromList(_data.sublist(_offset, _offset + count));
    _offset += count;
    return result;
  }

  int readVarint() {
    if (_offset >= _data.length) {
      throw FormatException('Unexpected end of data reading varint');
    }
    final first = _data[_offset++];
    if (first < 0xfd) return first;
    if (first == 0xfd) {
      return _data[_offset++] | (_data[_offset++] << 8);
    }
    if (first == 0xfe) {
      final v = _data[_offset] |
          (_data[_offset + 1] << 8) |
          (_data[_offset + 2] << 16) |
          (_data[_offset + 3] << 24);
      _offset += 4;
      return v;
    }
    // 0xff -- 8 bytes, but we don't expect counts that large.
    throw FormatException('Varint too large for PSBT parsing');
  }

  int readUint32LE() {
    final b = readBytes(4);
    return b[0] | (b[1] << 8) | (b[2] << 16) | (b[3] << 24);
  }
}

/// Encode a non-negative integer as a Bitcoin compact-size varint.
Uint8List _varint(int value) {
  if (value < 0xfd) {
    return Uint8List.fromList([value]);
  } else if (value <= 0xffff) {
    return Uint8List.fromList([0xfd, value & 0xff, (value >> 8) & 0xff]);
  } else if (value <= 0xffffffff) {
    return Uint8List.fromList([
      0xfe,
      value & 0xff,
      (value >> 8) & 0xff,
      (value >> 16) & 0xff,
      (value >> 24) & 0xff,
    ]);
  } else {
    throw ArgumentError('Varint value too large: $value');
  }
}

/// Encode an integer as 4 bytes little-endian.
Uint8List _uint32LE(int value) {
  final bytes = Uint8List(4);
  bytes[0] = value & 0xff;
  bytes[1] = (value >> 8) & 0xff;
  bytes[2] = (value >> 16) & 0xff;
  bytes[3] = (value >> 24) & 0xff;
  return bytes;
}

/// Encode an integer as 8 bytes little-endian.
Uint8List _uint64LE(int value) {
  final bytes = Uint8List(8);
  bytes[0] = value & 0xff;
  bytes[1] = (value >> 8) & 0xff;
  bytes[2] = (value >> 16) & 0xff;
  bytes[3] = (value >> 24) & 0xff;
  bytes[4] = (value >> 32) & 0xff;
  bytes[5] = (value >> 40) & 0xff;
  bytes[6] = (value >> 48) & 0xff;
  bytes[7] = (value >> 56) & 0xff;
  return bytes;
}

import 'dart:typed_data';

import 'package:coinlib/coinlib.dart' as coinlib;

typedef FiroTransactionInput = ({String txid, int vout, BigInt value});
typedef FiroTransactionOutput = ({String script, BigInt value});
typedef FiroTransactionPrevout = ({String txid, int vout});
typedef FiroDecodedTransaction = ({
  String txid,
  List<FiroTransactionPrevout> prevouts,
});

typedef _ParsedFiroTransaction = ({
  coinlib.Transaction transaction,
  bool isWitness,
  List<FiroTransactionPrevout> prevouts,
});

final _secp256k1Field =
    (BigInt.one << 256) - (BigInt.one << 32) - BigInt.from(977);
final _secp256k1Order = BigInt.parse(
  'fffffffffffffffffffffffffffffffebaaedce6af48a03bbfd25e8cd0364141',
  radix: 16,
);

/// The same zero-value output must be used for fee selection and signing.
coinlib.Output firoOpReturnOutput(String hex) {
  if (hex.startsWith('0x')) hex = hex.substring(2);
  if (hex.isEmpty ||
      hex.length.isOdd ||
      !RegExp(r'^[0-9a-fA-F]+$').hasMatch(hex)) {
    throw const FormatException('Invalid OP_RETURN hex');
  }
  if (hex.length > 160) {
    throw const FormatException('OP_RETURN data exceeds 80 byte limit');
  }

  final bytes = coinlib.hexToBytes(hex);
  return coinlib.Output.fromScriptBytes(
    BigInt.zero,
    Uint8List.fromList([
      0x6a,
      if (bytes.length > 75) 0x4c,
      bytes.length,
      ...bytes,
    ]),
  );
}

/// Verify the signed bytes that will be broadcast, not only the TxData fields.
/// [expectedOutputs] contains every payment/change output; [data] is appended.
/// Returns the transaction ID derived from [raw] after successful validation.
String verifyFiroOpReturnTransaction({
  required String raw,
  required String data,
  required Iterable<FiroTransactionInput> expectedInputs,
  required Iterable<FiroTransactionOutput> expectedOutputs,
  required BigInt expectedFee,
}) {
  late final _ParsedFiroTransaction parsed;
  try {
    parsed = _parseFiroTransaction(raw);
  } on FormatException {
    throw StateError(
      'The signed FIRO transaction does not match this bridge swap.',
    );
  }
  final tx = parsed.transaction;
  final inputs = expectedInputs.toList();
  final outputs = <coinlib.Output>[
    for (final output in expectedOutputs)
      coinlib.Output.fromScriptBytes(
        output.value,
        coinlib.hexToBytes(output.script),
      ),
    firoOpReturnOutput(data),
  ];
  final expectedInputKeys = [
    for (final input in inputs)
      coinlib.OutPoint.fromHex(input.txid, input.vout).toHex(),
  ];
  final actualInputKeys = [
    for (final input in tx.inputs) input.prevOut.toHex(),
  ];
  final expectedOutputKeys = [for (final output in outputs) output.toHex()];
  final actualOutputKeys = [for (final output in tx.outputs) output.toHex()];
  final inputValue = inputs.fold<BigInt>(
    BigInt.zero,
    (sum, input) => sum + input.value,
  );
  final outputValue = tx.outputs.fold<BigInt>(
    BigInt.zero,
    (sum, output) => sum + output.value,
  );
  if (tx.version != 1 ||
      parsed.isWitness ||
      tx.inputs.any((input) => !_isStructurallySignedP2pkh(input.scriptSig)) ||
      !_sameItems(expectedInputKeys, actualInputKeys) ||
      !_sameItems(expectedOutputKeys, actualOutputKeys) ||
      expectedFee.isNegative ||
      inputValue - outputValue != expectedFee) {
    throw StateError(
      'The signed FIRO transaction does not match this bridge swap.',
    );
  }
  return tx.txid;
}

/// Decodes a FIRO transaction and derives its standard no-witness transaction
/// ID and input outpoints from the raw bytes.
FiroDecodedTransaction decodeFiroTransaction(String raw) {
  final parsed = _parseFiroTransaction(raw);
  return (txid: parsed.transaction.txid, prevouts: parsed.prevouts);
}

/// Decode the non-witness FIRO transaction layout used by bridge sends.
coinlib.Transaction firoTransactionFromHex(String raw) {
  final parsed = _parseFiroTransaction(raw);
  if (parsed.isWitness) {
    throw const FormatException('Invalid FIRO bridge transaction.');
  }
  return parsed.transaction;
}

// ponytail: pinned coinlib misreads legacy flags; replace after its decoder fix.
_ParsedFiroTransaction _parseFiroTransaction(String raw) {
  try {
    final reader = coinlib.BytesReader(coinlib.hexToBytes(raw));
    final packedVersion = reader.readInt32();
    var inputCount = _readCompactSize(reader);
    var isWitness = false;
    if (inputCount == BigInt.zero) {
      final flags = reader.readUInt8();
      if (flags != 1) {
        throw const FormatException('Invalid FIRO transaction flags.');
      }
      isWitness = true;
      inputCount = _readCompactSize(reader);
    }
    final rawInputs = List.generate(
      _checkedCount(reader, inputCount, 41),
      (_) => _readRawInput(reader),
    );
    final outputs = List.generate(
      _checkedCount(reader, _readCompactSize(reader), 9),
      (_) => _readOutput(reader),
    );
    if (isWitness) {
      for (var i = 0; i < rawInputs.length; i++) {
        final itemCount = _checkedCount(
          reader,
          _readCompactSize(reader),
          1,
          allowZero: true,
        );
        for (var j = 0; j < itemCount; j++) {
          _readVarSlice(reader);
        }
      }
    }
    final locktime = reader.readUInt32();
    final version = packedVersion & 0xffff;
    final type = (packedVersion >> 16) & 0xffff;
    final extraPayload = version == 3 && type != 0
        ? _readVarSlice(reader)
        : null;
    if (!reader.atEnd) {
      throw const FormatException('Invalid FIRO transaction.');
    }

    final transaction = coinlib.Transaction(
      version: packedVersion,
      inputs: rawInputs,
      outputs: outputs,
      locktime: locktime,
      vExtraData: extraPayload,
    );
    return (
      transaction: transaction,
      isWitness: isWitness,
      prevouts: List.unmodifiable([
        for (final input in rawInputs)
          (
            txid: coinlib.bytesToHex(
              Uint8List.fromList(input.prevOut.hash.reversed.toList()),
            ),
            vout: input.prevOut.n,
          ),
      ]),
    );
  } on FormatException {
    rethrow;
  } on Exception {
    throw const FormatException('Invalid FIRO transaction.');
  }
}

BigInt _readCompactSize(coinlib.BytesReader reader) {
  final first = reader.readUInt8();
  if (first < 0xfd) return BigInt.from(first);
  final value = switch (first) {
    0xfd => BigInt.from(reader.readUInt16()),
    0xfe => BigInt.from(reader.readUInt32()),
    _ => reader.readUInt64(),
  };
  if ((first == 0xfd && value < BigInt.from(0xfd)) ||
      (first == 0xfe && value <= BigInt.from(0xffff)) ||
      (first == 0xff && value <= BigInt.from(0xffffffff))) {
    throw const FormatException('Non-canonical FIRO compact size.');
  }
  return value;
}

Uint8List _readVarSlice(coinlib.BytesReader reader) => reader.readSlice(
  _checkedCount(reader, _readCompactSize(reader), 1, allowZero: true),
);

coinlib.RawInput _readRawInput(coinlib.BytesReader reader) => coinlib.RawInput(
  prevOut: coinlib.OutPoint.fromReader(reader),
  scriptSig: _readVarSlice(reader),
  sequence: reader.readUInt32(),
);

coinlib.Output _readOutput(coinlib.BytesReader reader) =>
    coinlib.Output.fromScriptBytes(reader.readUInt64(), _readVarSlice(reader));

int _checkedCount(
  coinlib.BytesReader reader,
  BigInt value,
  int minimumSize, {
  bool allowZero = false,
}) {
  final remaining = reader.bytes.lengthInBytes - reader.offset;
  if ((!allowZero && value == BigInt.zero) ||
      value > BigInt.from(remaining ~/ minimumSize)) {
    throw const FormatException('Invalid FIRO transaction item count.');
  }
  return value.toInt();
}

bool _sameItems(List<String> first, List<String> second) {
  if (first.length != second.length) return false;
  first.sort();
  second.sort();
  for (var i = 0; i < first.length; i++) {
    if (first[i] != second[i]) return false;
  }
  return true;
}

// Checks BIP66/P2PKH shape without claiming to verify a signature without the
// previous output script.
bool _isStructurallySignedP2pkh(Uint8List script) {
  try {
    final reader = coinlib.BytesReader(script);
    final signature = reader.readVarSlice();
    final publicKey = reader.readVarSlice();
    return reader.atEnd &&
        _isCanonicalSignature(signature) &&
        _isSecp256k1Point(publicKey);
  } on Exception {
    return false;
  }
}

bool _isCanonicalSignature(Uint8List signature) {
  if (signature.length < 9 ||
      signature.length > 73 ||
      signature[0] != 0x30 ||
      signature[1] != signature.length - 3 ||
      signature[2] != 0x02 ||
      signature.last != 1) {
    return false;
  }
  final rLength = signature[3];
  final sType = 4 + rLength;
  if (!_isCanonicalScalar(signature, 4, rLength) ||
      sType + 2 >= signature.length - 1 ||
      signature[sType] != 0x02) {
    return false;
  }
  final sLength = signature[sType + 1];
  final sStart = sType + 2;
  return sStart + sLength == signature.length - 1 &&
      _isCanonicalScalar(signature, sStart, sLength);
}

bool _isCanonicalScalar(Uint8List bytes, int start, int length) {
  if (length == 0 ||
      start + length >= bytes.length ||
      (bytes[start] & 0x80) != 0 ||
      (length > 1 && bytes[start] == 0 && (bytes[start + 1] & 0x80) == 0)) {
    return false;
  }
  final value = BigInt.parse(
    coinlib.bytesToHex(bytes.sublist(start, start + length)),
    radix: 16,
  );
  return value > BigInt.zero && value < _secp256k1Order;
}

bool _isSecp256k1Point(Uint8List key) {
  final compressed = key.length == 33 && (key.first == 2 || key.first == 3);
  final uncompressed = key.length == 65 && key.first == 4;
  if (!compressed && !uncompressed) return false;
  final x = BigInt.parse(coinlib.bytesToHex(key.sublist(1, 33)), radix: 16);
  if (x >= _secp256k1Field) return false;
  final ySquared =
      (x.modPow(BigInt.from(3), _secp256k1Field) + BigInt.from(7)) %
      _secp256k1Field;
  if (compressed) {
    final y = ySquared.modPow(
      (_secp256k1Field + BigInt.one) >> 2,
      _secp256k1Field,
    );
    return y * y % _secp256k1Field == ySquared;
  }
  final y = BigInt.parse(coinlib.bytesToHex(key.sublist(33)), radix: 16);
  return y < _secp256k1Field && y * y % _secp256k1Field == ySquared;
}

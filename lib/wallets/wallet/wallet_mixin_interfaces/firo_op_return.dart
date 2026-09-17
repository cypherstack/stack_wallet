import 'dart:typed_data';

import 'package:coinlib/coinlib.dart' as coinlib;

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
void verifyFiroOpReturnTransaction({
  required String raw,
  required String data,
  required String paymentScript,
  required BigInt paymentAmount,
}) {
  final reader = coinlib.BytesReader(coinlib.hexToBytes(raw));
  // FIRO funding uses the legacy layout. Decode its fields directly because the
  // pinned coinlib Transaction reader rewinds one byte too far for legacy inputs.
  int count(int minimumSize) {
    final value = reader.readVarInt();
    if (value <= BigInt.zero ||
        value > BigInt.from(reader.bytes.lengthInBytes ~/ minimumSize)) {
      throw const FormatException('Invalid FIRO transaction item count.');
    }
    return value.toInt();
  }

  final tx = coinlib.Transaction(
    version: reader.readInt32(),
    inputs: List.generate(
      count(41),
      (_) => coinlib.Input.match(coinlib.RawInput.fromReader(reader)),
    ),
    outputs: List.generate(count(9), (_) => coinlib.Output.fromReader(reader)),
    locktime: reader.readUInt32(),
  );
  final expected = coinlib.bytesToHex(firoOpReturnOutput(data).scriptPubKey);
  final dataOutputs = tx.outputs.where(
    (o) => o.scriptPubKey.isNotEmpty && o.scriptPubKey.first == 0x6a,
  );
  final payments = tx.outputs.where(
    (o) => coinlib.bytesToHex(o.scriptPubKey) == paymentScript,
  );
  if (!reader.atEnd ||
      tx.toHex() != raw.toLowerCase() ||
      tx.version != 1 ||
      !tx.complete ||
      tx.isWitness ||
      tx.inputs.any((i) => i is! coinlib.LegacyInput) ||
      dataOutputs.length != 1 ||
      dataOutputs.single.value != BigInt.zero ||
      coinlib.bytesToHex(dataOutputs.single.scriptPubKey) != expected ||
      payments.length != 1 ||
      payments.single.value != paymentAmount) {
    throw StateError(
      'The signed FIRO transaction does not match this bridge swap.',
    );
  }
}

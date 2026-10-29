import 'dart:typed_data';

import 'package:coinlib_flutter/coinlib_flutter.dart' as coinlib;

import '../../../models/isar/models/blockchain_data/v2/input_v2.dart';
import '../../../models/isar/models/blockchain_data/v2/output_v2.dart';

final class UnauthenticatedTransaction implements Exception {
  final String message;

  const UnauthenticatedTransaction(this.message);

  @override
  String toString() => "UnauthenticatedTransaction: $message";
}

/// Sizes computed from raw bytes, excluding MWEB data.
typedef RawTransactionSize = ({int size, int vSize});

/// Parses [rawTxHex], which must hash to [txid]. Witness data is dropped.
/// [legacyTimestamp] is for coins whose transactions below version 3 carry a
/// timestamp, as Peercoin's do.
coinlib.Transaction parseAuthenticatedTransaction({
  required String txid,
  required String rawTxHex,
  bool legacyTimestamp = false,
}) => _parseAuthenticated(txid, rawTxHex, legacyTimestamp: legacyTimestamp).tx;

/// Whether [address] is p2pkh (bip44), whose legacy signature hash does not
/// commit to the amount being spent.
bool isP2pkhAddress(String address, coinlib.Network network) {
  try {
    return coinlib.Address.fromString(address, network).program
        is coinlib.P2PKH;
  } catch (_) {
    return false;
  }
}

/// Verifies [rawTxHex] as [txid], then checks the parent output of each
/// wallet owned p2pkh input, as only the legacy signature hash leaves the
/// amount unverified. Parents are fetched with [fetchRawTransaction]. Only
/// their outputs are read, which the txid commits to, so they may come from a
/// cache. The spend itself may not: its witnesses are checked but are not
/// committed by the txid, so a cached copy could hold a server's lie forever.
Future<RawTransactionSize> fetchAndVerifyOwnedInputSignatures({
  required String txid,
  required String rawTxHex,
  required List<InputV2> inputs,
  required List<OutputV2> outputs,
  required coinlib.Network network,
  required Future<String> Function(String txid) fetchRawTransaction,
  bool allowMweb = false,
  bool legacyTimestamp = false,
}) async {
  final verified = verifyOwnedInputSignatures(
    txid: txid,
    rawTxHex: rawTxHex,
    inputs: inputs,
    outputs: outputs,
    network: network,
    allowMweb: allowMweb,
  );

  final parents = <String, coinlib.Transaction>{};
  for (final (i, input) in inputs.indexed) {
    if (!isP2pkhAddress(input.addresses.single, network)) continue;

    final outpoint = input.outpoint!;
    final parentTxid = outpoint.txid.toLowerCase();
    final parent = parents[parentTxid] ??= parseAuthenticatedTransaction(
      txid: parentTxid,
      rawTxHex: await fetchRawTransaction(parentTxid),
      legacyTimestamp: legacyTimestamp,
    );

    if (outpoint.vout >= parent.outputs.length) {
      throw UnauthenticatedTransaction("Previous output $i missing");
    }
    final prevOut = parent.outputs[outpoint.vout];
    if (input.value != prevOut.value ||
        !scriptPaysTo(input.addresses.single, prevOut.scriptPubKey, network)) {
      throw UnauthenticatedTransaction("Previous output $i mismatch");
    }
  }

  return verified;
}

/// Parses [rawTxHex], which must hash to [txid].
_RawTransaction _parseAuthenticated(
  String txid,
  String rawTxHex, {
  bool legacyTimestamp = false,
}) {
  final _RawTransaction raw;
  try {
    raw = _parse(rawTxHex, legacyTimestamp: legacyTimestamp);
  } catch (_) {
    throw const UnauthenticatedTransaction("Malformed transaction");
  }
  if (raw.txid != txid.toLowerCase()) {
    throw const UnauthenticatedTransaction("Transaction mismatch");
  }
  return raw;
}

/// Checks that [rawTxHex] is transaction [txid], that [inputs] and [outputs]
/// describe it, and that every input is marked [InputV2.walletOwns] and signed
/// with SIGHASH_ALL by the key of the address it spends from. A spend of this
/// wallet's has no inputs of anyone else's, so every witness is checked and
/// the size is authenticated. Throws [UnauthenticatedTransaction] otherwise.
///
/// Outputs with addresses are matched by address and value. With [allowMweb],
/// MWEB data is allowed and outputs recorded as "mweb" are skipped.
RawTransactionSize verifyOwnedInputSignatures({
  required String txid,
  required String rawTxHex,
  required List<InputV2> inputs,
  required List<OutputV2> outputs,
  required coinlib.Network network,
  bool allowMweb = false,
}) {
  final raw = _parseAuthenticated(txid, rawTxHex);

  final tx = raw.tx;
  final canonicalOutputs = outputs
      .where((e) => !(raw.hasMweb && e.scriptPubKeyHex == "mweb"))
      .toList();
  if ((raw.hasMweb && !allowMweb) ||
      inputs.length != tx.inputs.length ||
      canonicalOutputs.length != tx.outputs.length) {
    throw const UnauthenticatedTransaction("Transaction mismatch");
  }

  for (final (i, input) in inputs.indexed) {
    final prevOut = tx.inputs[i].prevOut;
    final prevTxid = coinlib.bytesToHex(
      Uint8List.fromList(prevOut.hash.reversed.toList()),
    );
    if (input.outpoint?.vout != prevOut.n ||
        input.outpoint?.txid.toLowerCase() != prevTxid) {
      throw UnauthenticatedTransaction("Input $i mismatch");
    }
  }

  for (final (i, output) in canonicalOutputs.indexed) {
    final script = tx.outputs[i].scriptPubKey;
    final scriptMatches = output.addresses.isEmpty
        ? output.scriptPubKeyHex.toLowerCase() == coinlib.bytesToHex(script)
        : output.addresses.every((e) => scriptPaysTo(e, script, network));
    if (!scriptMatches || output.value != tx.outputs[i].value) {
      throw UnauthenticatedTransaction("Output $i mismatch");
    }
  }

  for (final (i, input) in inputs.indexed) {
    if (!input.walletOwns || input.addresses.length != 1) {
      throw UnauthenticatedTransaction("Input $i is not this wallet's");
    }

    bool valid;
    try {
      valid = _verifyOwnedInput(raw, i, inputs, network);
    } catch (_) {
      valid = false;
    }
    if (!valid) {
      throw UnauthenticatedTransaction("Invalid signature on input $i");
    }
  }

  return (size: raw.size, vSize: raw.vSize);
}

/// The transaction without witness or MWEB data, its txid, its witnesses, and
/// its size excluding MWEB data.
typedef _RawTransaction = ({
  coinlib.Transaction tx,
  String txid,
  List<List<Uint8List>> witnesses,
  bool hasMweb,
  int size,
  int vSize,
});

_RawTransaction _parse(String hex, {bool legacyTimestamp = false}) {
  final bytes = coinlib.hexToBytes(hex);
  final reader = coinlib.BytesReader(bytes);

  // Lengths are checked against the remaining data before allocating.
  int readCount() {
    final n = reader.readVarInt();
    if (n > BigInt.from(bytes.length - reader.offset)) {
      throw const FormatException("Invalid count");
    }
    return n.toInt();
  }

  final version = reader.readInt32();
  if (legacyTimestamp && version < 3) {
    reader.readUInt32();
  }
  final headerEnd = reader.offset;

  int flag = 0;
  if (bytes.length > reader.offset + 1 && bytes[reader.offset] == 0) {
    reader.offset++;
    flag = reader.readUInt8();
    if (flag == 0 || flag & ~0x09 != 0) {
      throw const FormatException("Unknown flag");
    }
  }
  final hasWitness = flag & 0x01 != 0;
  final hasMweb = flag & 0x08 != 0;

  final bodyStart = reader.offset;
  final inputs = List.generate(
    readCount(),
    (_) => coinlib.RawInput.fromReader(reader),
  );
  final outputs = List.generate(
    readCount(),
    (_) => coinlib.Output.fromReader(reader),
  );
  final bodyEnd = reader.offset;
  final witnesses = [
    for (final _ in inputs)
      hasWitness
          ? List.generate(readCount(), (_) => reader.readVarSlice())
          : <Uint8List>[],
  ];

  // MWEB data sits between the witnesses and the locktime.
  var mwebLength = 0;
  if (hasMweb) {
    mwebLength = bytes.length - reader.offset - 4;
    reader.readSlice(mwebLength);
  }

  final locktimeStart = reader.offset;
  final locktime = reader.readUInt32();

  // Dash and Firo special transactions, version 3 with the type in the upper
  // 16 bits, end with an extra payload.
  Uint8List? extraPayload;
  if (!reader.atEnd && (version & 0xffff) >= 3 && (version >>> 16) != 0) {
    extraPayload = reader.readSlice(readCount());
  }
  if (!reader.atEnd || inputs.isEmpty) {
    throw const FormatException("Malformed transaction");
  }

  // The txid commits to everything but the witnesses and MWEB data.
  final stripped = Uint8List.fromList([
    ...bytes.sublist(0, headerEnd),
    ...bytes.sublist(bodyStart, bodyEnd),
    ...bytes.sublist(locktimeStart),
  ]);
  final txid = coinlib.bytesToHex(
    Uint8List.fromList(coinlib.sha256DoubleHash(stripped).reversed.toList()),
  );

  final tx = coinlib.Transaction(
    version: version,
    inputs: inputs,
    outputs: outputs,
    locktime: locktime,
    vExtraData: extraPayload,
  );
  final size = bytes.length - mwebLength;
  return (
    tx: tx,
    txid: txid,
    witnesses: witnesses,
    hasMweb: hasMweb,
    size: size,
    vSize: ((stripped.length * 3 + size) / 4).ceil(),
  );
}

bool _verifyOwnedInput(
  _RawTransaction raw,
  int inputN,
  List<InputV2> inputs,
  coinlib.Network network,
) {
  final program = coinlib.Address.fromString(
    inputs[inputN].addresses.single,
    network,
  ).program;
  final txIn = raw.tx.inputs[inputN] as coinlib.RawInput;
  final witness = raw.witnesses[inputN];

  if (program is coinlib.P2TR) {
    final insig = coinlib.TaprootKeyInput.match(txIn, witness)?.insig;
    if (insig == null || !_signsAll(insig.hashType)) return false;

    // Taproot signatures commit to every spent output.
    final prevOuts = [
      for (final input in inputs)
        coinlib.Output.fromAddress(
          input.value,
          coinlib.Address.fromString(input.addresses.single, network),
        ),
    ];
    final hash = coinlib.TaprootSignatureHasher(
      coinlib.TaprootKeySignDetails(
        tx: raw.tx,
        inputN: inputN,
        prevOuts: prevOuts,
        hashType: insig.hashType,
      ),
    ).hash;
    return insig.signature.verify(program.tweakedKey, hash);
  }

  // p2pkh carries the signature and key in the scriptSig, p2wpkh and
  // p2sh-p2wpkh in the witness.
  final isLegacy = program is coinlib.P2PKH;
  final coinlib.PKHInput? signed;
  if (isLegacy) {
    signed = coinlib.P2PKHInput.match(txIn);
  } else {
    signed = coinlib.P2WPKHInput.match(
      coinlib.RawInput(prevOut: txIn.prevOut, scriptSig: Uint8List(0)),
      witness,
    );
  }
  final insig = signed?.insig;
  if (signed == null || insig == null || !_signsAll(insig.hashType)) {
    return false;
  }

  final scriptCode = coinlib.P2PKH.fromPublicKey(signed.publicKey).script;
  final p2wpkh = coinlib.P2WPKH.fromPublicKey(signed.publicKey).script;
  final (spentScript, scriptSig) = switch (program) {
    coinlib.P2PKH() => (scriptCode, txIn.scriptSig),
    coinlib.P2WPKH() => (p2wpkh, Uint8List(0)),
    coinlib.P2SH() => (
      coinlib.P2SH.fromRedeemScript(p2wpkh).script,
      coinlib.Script([coinlib.ScriptPushData(p2wpkh.compiled)]).compiled,
    ),
    _ => throw UnsupportedError("Unsupported input $inputN"),
  };
  if (!coinlib.bytesEqual(spentScript.compiled, program.script.compiled) ||
      !coinlib.bytesEqual(scriptSig, txIn.scriptSig) ||
      (isLegacy && witness.isNotEmpty)) {
    return false;
  }

  final hash = isLegacy
      ? coinlib.LegacySignatureHasher(
          coinlib.LegacySignDetailsWithScript(
            tx: raw.tx,
            inputN: inputN,
            scriptCode: scriptCode,
            hashType: insig.hashType,
          ),
        ).hash
      : coinlib.WitnessSignatureHasher(
          coinlib.LegacyWitnessSignDetailsWithScript(
            tx: raw.tx,
            inputN: inputN,
            value: inputs[inputN].value,
            scriptCode: scriptCode,
            hashType: insig.hashType,
          ),
        ).hash;
  return insig.signature.verify(signed.publicKey, hash);
}

bool _signsAll(coinlib.SigHashType hashType) =>
    hashType.all && hashType.allInputs;

/// Whether [script] is exactly the output script of [address].
bool scriptPaysTo(String address, Uint8List script, coinlib.Network network) {
  try {
    return coinlib.bytesEqual(
      coinlib.Address.fromString(address, network).program.script.compiled,
      script,
    );
  } catch (_) {
    return false;
  }
}

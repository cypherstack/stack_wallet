import 'dart:typed_data';

import 'package:bitbox/bitbox.dart' as bitbox;
import 'package:coin/coin.dart' as coin;
import 'package:fusiondart/fusiondart.dart';
import 'package:fusiondart/src/exceptions.dart';
import 'package:fusiondart/src/extensions/on_string.dart';
import 'package:fusiondart/src/extensions/on_uint8list.dart';
import 'package:fusiondart/src/protobuf/fusion.pb.dart';
import 'package:fusiondart/src/protocol.dart';

// Translated from https://github.com/Electron-Cash/Electron-Cash/blob/ba01323b732d1ae4ba2ca66c40e3f27bb92cee4b/electroncash/transaction.py#L289
/// Class that represents a transaction.
class Transaction {
  final List<bitbox.Input> inputs;
  final List<Output> outputs;

  /// Instance variable for the locktime of the transaction.
  BigInt locktime = BigInt.zero;
  // https://github.com/Electron-Cash/Electron-Cash/blob/ba01323b732d1ae4ba2ca66c40e3f27bb92cee4b/electroncash/transaction.py#L311

  /// Instance variable for the version of the transaction.
  BigInt version = BigInt.one;
  // https://github.com/Electron-Cash/Electron-Cash/blob/ba01323b732d1ae4ba2ca66c40e3f27bb92cee4b/electroncash/transaction.py#L312

  /// Default constructor for the Transaction class.
  Transaction(this.inputs, this.outputs);

  /// Factory method to create a Transaction from components and a session hash.
  static ({
    Transaction tx,
    List<({bitbox.Input input, int compIndex})> inputAndCompIndexes
  }) txFromComponents(
    List<List<int>> allComponents,
    List<int> sessionHash,
    coin.Chain network,
  ) {
    // Initialize a new Transaction.
    Transaction tx = Transaction([], []);

    final List<({bitbox.Input input, int compIndex})> inputAndCompIndexes = [];
    final comps =
        allComponents.map((e) => Component()..mergeFromBuffer(e)).toList();

    assert(sessionHash.length == 32);

    final fuseId = Protocol.FUSE_ID.toUint8ListFromUtf8;
    assert(fuseId.length == 4);
    final prefix = [4, ...fuseId];

    final opReturnScript = coin.Script.decompile(Uint8List.fromList([
      0x6a, // OP_RETURN
      ...prefix,
      0x20, // aka 32 aka PUSH
      ...sessionHash,
    ]));

    tx.outputs.add(Output.fromScriptPubKey(
        value: 0, scriptPubkey: opReturnScript.compiled));

    for (int i = 0; i < comps.length; i++) {
      final comp = comps[i];
      if (comp.hasInput()) {
        final inp = comp.input;
        if (inp.prevTxid.length != 32) {
          throw FusionError("bad component prevout");
        }

        final input = bitbox.Input(
          hash: Uint8List.fromList(inp.prevTxid),
          index: inp.prevIndex,
          sequence: 0xffffffff,
          pubkeys: [Uint8List.fromList(inp.pubkey)],
          value: inp.amount.toInt(),
        );

        tx.inputs.add(input);

        inputAndCompIndexes.add(
          (input: input, compIndex: i),
        );
      } else if (comp.hasOutput()) {
        final output = Output.fromOutputComponent(comp.output);
        tx.outputs.add(output);
      } else if (!comp.hasBlank()) {
        throw FusionError("bad component");
      }
    }

    return (tx: tx, inputAndCompIndexes: inputAndCompIndexes);
  }

  /// Serializes the preimage of the transaction.
  Uint8List serializePreimageBytes(
    int i, {
    required coin.Chain network,
    int nHashType = 0x00000041,
    bool useCache = false,
  }) {
    final txInputs = inputs.map(
      (e) => coin.RawInput(
        prevOut: coin.Outpoint(
          txid: e.hash!,
          vout: e.index!,
        ),
        sequence: e.sequence ?? coin.TxInput.sequenceFinal,
      ),
    ).toList();

    final txOutputs = outputs.map(
      (e) => coin.TxOutput(
        value: BigInt.from(e.value),
        scriptPubKey: e.scriptPubKey,
      ),
    ).toList();

    Uint8List _hashConcatSerializable(Iterable<coin.Serializable> list) {
      return Utilities.doubleSha256(
        Uint8List.fromList(
          list.map((e) => e.toBytes().toList()).reduce((a, b) => a + b),
        ),
      );
    }

    final hashPrevouts =
        _hashConcatSerializable(txInputs.map((i) => i.prevOut));

    final sequenceBytes = Uint8List(4 * txInputs.length);
    final sequenceWriter = coin.WireWriter(sequenceBytes);
    for (final input in txInputs) {
      sequenceWriter.writeUInt32(input.sequence);
    }
    final hashSequence = Utilities.doubleSha256(sequenceBytes);

    final hashOutputs = _hashConcatSerializable(txOutputs);

    // Build scriptCode from the public key of the i-th input (P2PKH)
    final thisBitboxIn = inputs[i];
    final pubKey = coin.PublicKey.fromHex(thisBitboxIn.pubkeys![0]!.toHex);
    final scriptCode2 =
        coin.PayToPubKeyHash(coin.hash160(pubKey.bytes)).script;

    final compiledScript = scriptCode2.compiled;

    final size =
        156 + (coin.WireMeasure()..writeVarSlice(compiledScript)).size;
    final bytes = Uint8List(size);
    final writer = coin.WireWriter(bytes);
    writer.writeUInt32(version.toInt());
    writer.writeSlice(hashPrevouts);
    writer.writeSlice(hashSequence);
    txInputs[i].prevOut.writeTo(writer);
    writer.writeVarSlice(compiledScript);
    writer.writeUInt64(BigInt.from(inputs[i].value!));
    writer.writeUInt32(txInputs[i].sequence);
    writer.writeSlice(hashOutputs);
    writer.writeUInt32(locktime.toInt());
    writer.writeUInt32(nHashType);

    return bytes;
  }
}

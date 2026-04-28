import 'dart:typed_data';

import 'package:coin/coin.dart' as coin;
import 'package:fusiondart/src/encrypt.dart' as encrypt;
import 'package:fusiondart/src/exceptions.dart';
import 'package:fusiondart/src/extensions/on_list_int.dart';
import 'package:fusiondart/src/extensions/on_uint8list.dart';
import 'package:fusiondart/src/models/output.dart';
import 'package:fusiondart/src/pedersen.dart';
import 'package:fusiondart/src/protobuf/fusion.pb.dart' as pb;
import 'package:fusiondart/src/util.dart';
import 'package:protobuf/protobuf.dart';

int componentContrib(
  pb.Component component,
  int feerate,
  coin.Chain network,
) {
  if (component.hasInput()) {
    return component.input.amount.toInt() -
        Utilities.componentFee(
            Utilities.sizeOfInput(Uint8List.fromList(component.input.pubkey)),
            feerate);
  } else if (component.hasOutput()) {
    Output out = Output.fromOutputComponent(component.output);
    return -out.value.toInt() -
        Utilities.componentFee(
            Utilities.sizeOfOutput(
                Uint8List.fromList(component.output.scriptpubkey)),
            feerate);
  } else if (component.hasBlank()) {
    return 0;
  } else {
    throw ValidationError('Invalid component type');
  }
}

void check(bool condition, String failMessage) {
  if (!condition) {
    throw ValidationError(failMessage);
  }
}

T protoStrictParse<T extends GeneratedMessage>(T msg, List<int> blob) {
  try {
    msg.mergeFromBuffer(blob);
  } catch (e) {
    throw ArgumentError('ValidationError: decode error');
  }

  if (!(msg.isInitialized())) {
    throw ArgumentError('missing fields');
  }

  if (msg.unknownFields.isNotEmpty) {
    throw ArgumentError('has extra fields');
  }

  if (msg.writeToBuffer().length != blob.length) {
    throw ArgumentError('encoding too long');
  }

  return msg;
}

List<pb.InitialCommitment> checkPlayerCommit(pb.PlayerCommit msg,
    int minExcessFee, int maxExcessFee, int numComponents) {
  check(msg.initialCommitments.length == numComponents,
      "wrong number of component commitments");
  check(msg.blindSigRequests.length == numComponents,
      "wrong number of blind sig requests");

  check(
      minExcessFee <= msg.excessFee.toInt() &&
          msg.excessFee.toInt() <= maxExcessFee,
      "bad excess fee");

  check(msg.randomNumberCommitment.length == 32, "bad random commit");
  check(msg.pedersenTotalNonce.length == 32, "bad nonce");
  check(msg.blindSigRequests.every((r) => r.length == 32),
      "bad blind sig request");

  final List<pb.InitialCommitment> commitMessages = [];
  for (List<int> cblob in msg.initialCommitments) {
    final cmsg = protoStrictParse(pb.InitialCommitment(), cblob);
    check(cmsg.saltedComponentHash.length == 32, "bad salted hash");
    List<int> P = cmsg.amountCommitment;
    check(P.length == 65 && P[0] == 4, "bad commitment point");
    check(
        cmsg.communicationKey.length == 33 &&
            (cmsg.communicationKey[0] == 2 || cmsg.communicationKey[0] == 3),
        "bad communication key");
    commitMessages.add(cmsg);
  }

  final Commitment claimedCommit;
  final Uint8List pointsum;
  // Verify pedersen commitment
  try {
    pointsum = Utilities.addPoints(
      commitMessages
          .map((m) => Uint8List.fromList(m.amountCommitment))
          .toList(),
      Utilities.secp256k1Params,
    );
    claimedCommit = Utilities.pedersenSetup.commit(
      BigInt.from(msg.excessFee.toInt()),
      nonce: (Uint8List.fromList(msg.pedersenTotalNonce)).toBigInt,
    );

    check(pointsum.equals(claimedCommit.pointPUncompressed),
        "pedersen commitment mismatch");
  } catch (e, s) {
    throw ValidationError("pedersen commitment verification error: $e\n$s");
  }
  check(pointsum.equals(claimedCommit.pointPUncompressed),
      "pedersen commitment mismatch");
  return commitMessages;
}

/// Validates a component message.
(String, int) checkCovertComponent(
  pb.CovertComponent msg,
  Uint8List roundPubkey,
  int componentFeerate,
  coin.Chain network,
) {
  Uint8List messageHash = Utilities.sha256(Uint8List.fromList(msg.component));

  check(msg.signature.length == 64, "bad message signature");
  check(Utilities.schnorrVerify(roundPubkey, msg.signature, messageHash),
      "bad message signature");

  final cmsg = protoStrictParse(pb.Component(), msg.component);
  check(cmsg.saltCommitment.length == 32, "bad salt commitment");

  final String sortKey;

  if (cmsg.hasInput()) {
    final inp = cmsg.input;
    check(inp.prevTxid.length == 32, "bad txid");
    check(
        (inp.pubkey.length == 33 &&
                (inp.pubkey[0] == 2 || inp.pubkey[0] == 3)) ||
            (inp.pubkey.length == 65 && inp.pubkey[0] == 4),
        "bad pubkey");

    sortKey = 'i${String.fromCharCodes(inp.prevTxid.reversed)}'
        '${inp.prevIndex.toString()}'
        '${String.fromCharCodes(cmsg.saltCommitment)}';
  } else if (cmsg.hasOutput()) {
    final out = cmsg.output;
    // Basically just checks if its ok address. should throw error if not.
    try {
      Utilities.getAddressFromOutputScript(
        Uint8List.fromList(out.scriptpubkey),
        network,
      );
    } catch (_) {
      rethrow;
    }

    check(out.amount >= Utilities.dustLimit(out.scriptpubkey.length),
        "dust output");
    sortKey =
        'o${out.amount.toString()}${String.fromCharCodes(out.scriptpubkey)}${String.fromCharCodes(cmsg.saltCommitment)}';
  } else if (cmsg.hasBlank()) {
    sortKey = 'b${String.fromCharCodes(cmsg.saltCommitment)}';
  } else {
    throw ValidationError('missing component details');
  }

  return (sortKey, componentContrib(cmsg, componentFeerate, network));
}

pb.InputComponent? validateProofInternal(
  Uint8List proofBlob,
  pb.InitialCommitment commitment,
  List<List<int>> allComponents,
  List<int> badComponents,
  int componentFeerate,
  coin.Chain network,
) {
  final msg = protoStrictParse(pb.Proof(), proofBlob);

  final List<int> componentBlob;
  try {
    componentBlob = allComponents[msg.componentIdx];
  } catch (e) {
    throw ValidationError("component index out of range");
  }

  check(!badComponents.contains(msg.componentIdx), "component in bad list");

  final comp = pb.Component();
  comp.mergeFromBuffer(componentBlob);
  assert(comp.isInitialized());

  check(msg.salt.length == 32, "salt wrong length");
  check(
    Utilities.sha256(Uint8List.fromList(msg.salt))
        .toList()
        .equals(comp.saltCommitment),
    "salt commitment mismatch",
  );

  final iterableSalt = msg.salt;
  check(
    Utilities.sha256(Uint8List.fromList([...iterableSalt, ...componentBlob]))
        .equals(Uint8List.fromList(commitment.saltedComponentHash)),
    "salted component hash mismatch",
  );

  int contrib = componentContrib(comp, componentFeerate, network);

  final List<int> pCommitted = commitment.amountCommitment;

  final Commitment claimedCommit = Utilities.pedersenSetup.commit(
    BigInt.from(contrib),
    nonce: Uint8List.fromList(msg.pedersenNonce).toBigInt,
  );

  check(
    Uint8List.fromList(pCommitted).equals(claimedCommit.pointPUncompressed),
    "pedersen commitment mismatch",
  );

  if (comp.hasInput()) {
    return comp.input;
  } else {
    return null;
  }
}

Future<pb.InputComponent> validateBlame(
  pb.Blames_BlameProof blame,
  Uint8List encProof,
  Uint8List srcCommitBlob,
  Uint8List destCommitBlob,
  List<List<int>> allComponents,
  List<int> badComponents,
  int componentFeerate,
  coin.Chain network,
) async {
  final destCommit = pb.InitialCommitment();
  destCommit.mergeFromBuffer(destCommitBlob);

  // Removed unused var.  This is unused in the python reference, too.
  // List<int> destPubkey = destCommit.communicationKey;

  final srcCommit = pb.InitialCommitment();
  srcCommit.mergeFromBuffer(srcCommitBlob);

  final decrypter = blame.whichDecrypter();

  if (decrypter == pb.Blames_BlameProof_Decrypter.privkey) {
    check(blame.privkey.length == 32, 'bad blame privkey');

    final privateKey = coin.SecretKey(Uint8List.fromList(blame.privkey));

    check(destCommit.communicationKey.equals(privateKey.publicKey.bytes),
        'bad blame privkey');

    try {
      await encrypt.decrypt(
        encProof,
        Uint8List.fromList(blame.privkey),
      );
    } catch (e) {
      throw Exception("validateBlame() undecryptable");
    }
    throw ValidationError('blame gave privkey but decryption worked');
  } else if (decrypter != pb.Blames_BlameProof_Decrypter.sessionKey) {
    throw ValidationError('unknown blame decrypter');
  }
  Uint8List key = Uint8List.fromList(blame.sessionKey);
  check(key.length == 32, 'bad blame session key');
  Uint8List proofBlob;
  try {
    proofBlob = await encrypt.decryptWithSymmkey(encProof, key);
  } catch (e) {
    throw ValidationError('bad blame session key');
  }
  pb.InputComponent? inpComp;
  try {
    inpComp = validateProofInternal(
      proofBlob,
      srcCommit,
      allComponents,
      badComponents,
      componentFeerate,
      network,
    );
  } catch (e) {
    rethrow;
  }

  if (!blame.needLookupBlockchain) {
    throw ValidationError(
        'blame indicated internal inconsistency, none found!');
  }

  if (inpComp == null) {
    throw ValidationError(
        'blame indicated blockchain error on a non-input component');
  }

  return inpComp;
}

import 'package:protobuf/protobuf.dart';
import 'fusion.pb.dart' as pb;
import 'pedersen.dart';
import 'util.dart';
import 'encrypt.dart' as Encrypt;
import 'protocol.dart';
import 'fusion.dart';
import 'dart:typed_data';
import 'package:pointycastle/export.dart';
import 'package:convert/convert.dart';
import 'pedersen.dart';

class ValidationError implements Exception {
  final String message;
  ValidationError(this.message);
  @override
  String toString() => 'Validation error: $message';
}

int componentContrib(pb.Component component, int feerate) {
  if (component.hasInput()) {
    var inp = Input.fromInputComponent(component.input);
    return inp.amount.toInt() - Util.componentFee(inp.sizeOfInput(), feerate);
  } else if (component.hasOutput()) {
    var out = Output.fromOutputComponent(component.output);
    return -out.amount.toInt() - Util.componentFee(out.sizeOfOutput(), feerate);
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
dynamic protoStrictParse(dynamic msg, List<int> blob) {
  try {
    if (msg.mergeFromBuffer(blob) != blob.length) {
      throw ArgumentError('DecodeError');
    }
  } catch (e) {
    throw ArgumentError('ValidationError: decode error');
  }

  if (!msg.isInitialized()) {
    throw ArgumentError('missing fields');
  }

  // Protobuf in dart does not support 'unknownFields' method
  // if (!msg.unknownFields.isEmpty) {
  //   throw ArgumentError('has extra fields');
  // }

  if (msg.writeToBuffer().length != blob.length) {
    throw ArgumentError('encoding too long');
  }

  return msg;
}


List<pb.InitialCommitment> checkPlayerCommit(
    pb.PlayerCommit msg,
    int minExcessFee,
    int maxExcessFee,
    int numComponents
    ) {
  check(msg.initialCommitments.length == numComponents, "wrong number of component commitments");
  check(msg.blindSigRequests.length == numComponents, "wrong number of blind sig requests");

  check(minExcessFee <= msg.excessFee.toInt() && msg.excessFee.toInt() <= maxExcessFee, "bad excess fee");

  check(msg.randomNumberCommitment.length == 32, "bad random commit");
  check(msg.pedersenTotalNonce.length == 32, "bad nonce");
  check(msg.blindSigRequests.every((r) => r.length == 32), "bad blind sig request");

  List<pb.InitialCommitment> commitMessages = [];
  for (var cblob in msg.initialCommitments) {
    pb.InitialCommitment cmsg = protoStrictParse(pb.InitialCommitment(), cblob);
    check(cmsg.saltedComponentHash.length == 32, "bad salted hash");
    var P = cmsg.amountCommitment;
    check(P.length == 65 && P[0] == 4, "bad commitment point");
    check(cmsg.communicationKey.length == 33 && (cmsg.communicationKey[0] == 2 || cmsg.communicationKey[0] == 3), "bad communication key");
    commitMessages.add(cmsg);
  }

  Uint8List HBytes = Uint8List.fromList([0x02] + 'CashFusion gives us fungibility.'.codeUnits);
  ECDomainParameters params = ECDomainParameters('secp256k1');
  ECPoint? HMaybe = params.curve.decodePoint(HBytes);
  if (HMaybe == null) {
    throw Exception('Failed to decode point');
  }
  ECPoint H = HMaybe;
  PedersenSetup setup = PedersenSetup(H);

  var claimedCommit;
  var pointsum;
  // Verify pedersen commitment
  try {
    pointsum = Commitment.add_points(commitMessages.map((m) => Uint8List.fromList(m.amountCommitment)).toList());
    claimedCommit = setup.commit(BigInt.from(msg.excessFee.toInt()), nonce: Util.bytesToBigInt(Uint8List.fromList(msg.pedersenTotalNonce)));

    check(pointsum == claimedCommit.PUncompressed, "pedersen commitment mismatch");
  } catch (e) {
    throw ValidationError("pedersen commitment verification error");
  }
  check(pointsum == claimedCommit.PUncompressed, "pedersen commitment mismatch");
  return commitMessages;
}


Tuple<String, int> checkCovertComponent(
    pb.CovertComponent msg, ECPoint roundPubkey, int componentFeerate) {
  var messageHash = Util.sha256(Uint8List.fromList(msg.component));

  check(msg.signature.length == 64, "bad message signature");
  check(
      Util.schnorrVerify(
          roundPubkey, msg.signature, messageHash),
      "bad message signature");

  var cmsg = protoStrictParse(pb.Component(), msg.component);
  check(cmsg.saltCommitment.length == 32, "bad salt commitment");

  String sortKey;

  if (cmsg.hasInput()) {
    var inp = cmsg.input;
    check(inp.prevTxid.length == 32, "bad txid");
    check(
        (inp.pubkey.length == 33 && (inp.pubkey[0] == 2 || inp.pubkey[0] == 3)) ||
            (inp.pubkey.length == 65 && inp.pubkey[0] == 4),
        "bad pubkey");
    sortKey = 'i' +
        String.fromCharCodes(inp.prevTxid.reversed) +
        inp.prevIndex.toString() +
        String.fromCharCodes(cmsg.saltCommitment);
  } else if (cmsg.hasOutput()) {
    var out = cmsg.output;
    Address addr;
    // Basically just checks if its ok address. should throw error if not.
    addr = Util.getAddressFromOutputScript(out.scriptpubkey);

    check(
        out.amount >= Util.dustLimit(out.scriptpubkey.length), "dust output");
    sortKey = 'o' +
        out.amount.toString() +
        String.fromCharCodes(out.scriptpubkey) +
        String.fromCharCodes(cmsg.saltCommitment);
  } else if (cmsg.hasBlank()) {
    sortKey = 'b' + String.fromCharCodes(cmsg.saltCommitment);
  } else {
    throw ValidationError('missing component details');
  }

  return Tuple(sortKey, componentContrib(cmsg, componentFeerate));
}

pb.InputComponent? validateProofInternal(
    Uint8List proofBlob,
    pb.InitialCommitment commitment,
    List<Uint8List> allComponents,
    List<int> badComponents,
    int componentFeerate,
    ) {

  Uint8List HBytes = Uint8List.fromList([0x02] + 'CashFusion gives us fungibility.'.codeUnits);
  ECDomainParameters params = ECDomainParameters('secp256k1');
  ECPoint? HMaybe = params.curve.decodePoint(HBytes);
  if (HMaybe == null) {
    throw Exception('Failed to decode point');
  }
  ECPoint H = HMaybe;
  PedersenSetup setup = PedersenSetup(H);

  var msg = protoStrictParse(pb.Proof(), proofBlob);

  Uint8List componentBlob;
  try {
    componentBlob = allComponents[msg.componentIdx];
  } catch (e) {
    throw ValidationError("component index out of range");
  }

  check(!badComponents.contains(msg.componentIdx), "component in bad list");

  var comp = pb.Component();
  comp.mergeFromBuffer(componentBlob);
  assert(comp.isInitialized());

  check(msg.salt.length == 32, "salt wrong length");
  check(
    Util.sha256(msg.salt) == comp.saltCommitment,
    "salt commitment mismatch",
  );
  check(
    Util.sha256(Uint8List.fromList([...msg.salt, ...componentBlob])) ==
        commitment.saltedComponentHash,
    "salted component hash mismatch",
  );

  var contrib = componentContrib(comp, componentFeerate);

  var PCommitted = commitment.amountCommitment;

  var claimedCommit = setup.commit(
    BigInt.from(contrib),
    nonce: Util.bytesToBigInt(msg.pedersenNonce),
  );

  check(
    Uint8List.fromList(PCommitted) == claimedCommit.PUncompressed,
    "pedersen commitment mismatch",
  );

  if(comp.hasInput()){
    return comp.input;
  } else {
    return null;
  }
}

Future<dynamic> validateBlame(
    pb.Blames_BlameProof blame,
    Uint8List encProof,
    Uint8List srcCommitBlob,
    Uint8List destCommitBlob,
    List<Uint8List> allComponents,
    List<int> badComponents,
    int componentFeerate,
    ) async {
  var destCommit = pb.InitialCommitment();
  destCommit.mergeFromBuffer(destCommitBlob);
  var destPubkey = destCommit.communicationKey;

  var srcCommit = pb.InitialCommitment();
  srcCommit.mergeFromBuffer(srcCommitBlob);

  var decrypter = blame.whichDecrypter();
  ECDomainParameters params = ECDomainParameters('secp256k1');
  if (decrypter == pb.Blames_BlameProof_Decrypter.privkey) {
    var privkey = Uint8List.fromList(blame.privkey);
    check(privkey.length == 32, 'bad blame privkey');
    var privkeyHexStr = Util.bytesToHex(privkey); // Convert bytes to hex string.
    var privkeyBigInt = BigInt.parse(privkeyHexStr, radix: 16); // Convert hex string to BigInt.
    var privateKey = ECPrivateKey(privkeyBigInt, params); // Create ECPrivateKey
    var pubkeys = Util.pubkeysFromPrivkey(privkeyHexStr);
    check(destCommit.communicationKey == pubkeys[1], 'bad blame privkey');
    try {
      Encrypt.decrypt(encProof, privateKey);
    } catch (e) {
      return 'undecryptable';
    }
    throw ValidationError('blame gave privkey but decryption worked');
  } else if (decrypter != pb.Blames_BlameProof_Decrypter.sessionKey) {
    throw ValidationError('unknown blame decrypter');
  }
  var key = Uint8List.fromList(blame.sessionKey);
  check(key.length == 32, 'bad blame session key');
  Uint8List proofBlob;
  try {
    proofBlob = await Encrypt.decryptWithSymmkey(encProof, key);
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
    );
  } catch (e) {
    return e.toString();
  }

  if (!blame.needLookupBlockchain) {
    throw ValidationError('blame indicated internal inconsistency, none found!');
  }

  if (inpComp == null) {
    throw ValidationError('blame indicated blockchain error on a non-input component');
  }

  return inpComp;
}

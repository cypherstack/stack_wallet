import 'dart:typed_data';

import 'package:coinlib_flutter/coinlib_flutter.dart';

/// A BIP49 (P2SH-P2WPKH) input. Signing is BIP143, the same as P2WPKH; the
/// only difference on the wire is the scriptSig pushing the P2WPKH program.
class P2shP2wpkhInput extends P2WPKHInput {
  P2shP2wpkhInput({
    required super.prevOut,
    required super.publicKey,
    super.insig,
    super.sequence,
  });

  /// An input spending [scriptPubKey], which must be the P2SH output that
  /// commits to the P2WPKH program of [publicKey]. Any other script, including
  /// other P2SH redeem scripts, throws [UnsupportedError].
  factory P2shP2wpkhInput.spending({
    required OutPoint prevOut,
    required ECPublicKey publicKey,
    required Uint8List scriptPubKey,
    int sequence = Input.sequenceFinal,
  }) {
    if (!bytesEqual(scriptPubKey, scriptPubKeyFor(publicKey))) {
      throw UnsupportedError(
        "Output is not a P2SH-P2WPKH output for the signing key",
      );
    }
    return P2shP2wpkhInput(
      prevOut: prevOut,
      publicKey: publicKey,
      sequence: sequence,
    );
  }

  static Script redeemScriptFor(ECPublicKey publicKey) =>
      P2WPKH.fromPublicKey(publicKey).script;

  static Uint8List scriptPubKeyFor(ECPublicKey publicKey) =>
      P2SH.fromRedeemScript(redeemScriptFor(publicKey)).script.compiled;

  @override
  Uint8List get scriptSig =>
      Script([ScriptPushData(redeemScriptFor(publicKey).compiled)]).compiled;

  // Base input plus the largest signature/public-key witness.
  @override
  int get signedSize => 41 + scriptSig.length + 109;

  @override
  P2shP2wpkhInput addSignature(ECDSAInputSignature insig) => P2shP2wpkhInput(
    prevOut: prevOut,
    publicKey: publicKey,
    sequence: sequence,
    insig: insig,
  );

  @override
  P2shP2wpkhInput filterSignatures(bool Function(InputSignature) predicate) =>
      insig == null || predicate(insig!)
      ? this
      : P2shP2wpkhInput(
          prevOut: prevOut,
          publicKey: publicKey,
          sequence: sequence,
        );
}

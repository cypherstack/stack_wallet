import 'dart:typed_data';

import 'package:coinlib_flutter/coinlib_flutter.dart';

class P2shP2wpkhInput extends P2WPKHInput {
  P2shP2wpkhInput({
    required super.prevOut,
    required super.publicKey,
    super.insig,
    super.sequence,
  });

  @override
  Uint8List get scriptSig => Uint8List.fromList([
    22,
    ...P2WPKH.fromPublicKey(publicKey).script.compiled,
  ]);

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

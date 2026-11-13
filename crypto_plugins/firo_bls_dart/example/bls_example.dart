// ignore_for_file: avoid_print

import 'dart:typed_data';

import 'package:bls_dart/bls_dart.dart';

/// Demonstrates BLS12-381 min_pk signature operations.
///
/// This example requires a running Flutter environment (not a plain Dart script)
/// because flutter_rust_bridge requires native library loading.
///
/// Run with: `flutter run example/bls_example.dart`
void main() async {
  // 1. Initialize the Rust runtime — required once before any BLS call.
  await RustLib.init();
  print('RustLib initialized.');

  // 2. Verify a single signature.
  //    In practice, these bytes come from a Walrus storage node or Sui transaction.
  final fakeSig = Uint8List(96); // placeholder — not a real signature
  final fakePk = Uint8List(48); // placeholder — not a real public key
  final msg = Uint8List.fromList([1, 2, 3, 4]);

  final valid = bls12381MinPkVerify(
    sigBytes: fakeSig,
    pkBytes: fakePk,
    msg: msg,
  );
  print('Single verify (fake data): $valid'); // Expected: false

  // 3. Aggregate signatures.
  final aggSig = bls12381MinPkAggregate(sigsBytes: []);
  print('Aggregate of empty list: ${aggSig.length} bytes'); // Expected: 0

  // 4. Verify an aggregate signature.
  final aggValid = bls12381MinPkVerifyAggregate(
    pksBytes: [],
    msg: msg,
    aggSigBytes: fakeSig,
  );
  print('Aggregate verify (empty keys): $aggValid'); // Expected: false
}

# bls_dart

BLS12-381 **min_pk** signature operations for Dart & Flutter, powered by [blst](https://github.com/supranational/blst) via [flutter_rust_bridge](https://pub.dev/packages/flutter_rust_bridge).

Uses the DST string `BLS_SIG_BLS12381G2_XMD:SHA-256_SSWU_RO_NUL_`, matching Sui Move's `bls12381_min_pk_verify`.

> Web is not supported because blst is a native C/assembly library.

## Installation

```yaml
dependencies:
  bls_dart: ^0.1.0
```

## Usage

```dart
import 'package:bls_dart/bls_dart.dart';

void main() async {
  // Initialize the Rust runtime once before calling any BLS function.
  await RustLib.init();

  // Verify a single signature.
  final valid = bls12381MinPkVerify(
    sigBytes: signature,  // 96-byte compressed G2 signature
    pkBytes: publicKey,   // 48-byte compressed G1 public key
    msg: message,         // arbitrary-length message bytes
  );

  // Aggregate multiple signatures into one.
  final aggSig = bls12381MinPkAggregate(
    sigsBytes: [sig1, sig2, sig3], // list of 96-byte signatures
  );
  // Returns 96-byte aggregate signature, or empty Uint8List on error.

  // Verify an aggregate signature (all signers signed the same message).
  final aggValid = bls12381MinPkVerifyAggregate(
    pksBytes: [pk1, pk2, pk3],  // list of 48-byte public keys
    msg: message,
    aggSigBytes: aggSig,        // 96-byte aggregate signature
  );
}
```

## API reference

### `bls12381MinPkVerify`

```dart
bool bls12381MinPkVerify({
  required List<int> sigBytes,   // 96-byte compressed G2 signature
  required List<int> pkBytes,    // 48-byte compressed G1 public key
  required List<int> msg,        // message bytes
})
```

Returns `true` when the signature is valid, `false` otherwise (including malformed inputs).

### `bls12381MinPkAggregate`

```dart
Uint8List bls12381MinPkAggregate({
  required List<Uint8List> sigsBytes, // list of 96-byte signatures
})
```

Returns the 96-byte aggregate signature, or an empty `Uint8List` on error (empty list, malformed input).

### `bls12381MinPkVerifyAggregate`

```dart
bool bls12381MinPkVerifyAggregate({
  required List<Uint8List> pksBytes,   // list of 48-byte public keys
  required List<int> msg,              // shared message
  required List<int> aggSigBytes,      // 96-byte aggregate signature
})
```

Returns `true` when the aggregate signature is valid, `false` otherwise.

## Key sizes

| Type            | Size (bytes) | Curve point |
|-----------------|--------------|-------------|
| Public key      | 48           | G1          |
| Signature       | 96           | G2          |
| Aggregate signature | 96       | G2          |

## How it works

bls_dart wraps the [blst](https://github.com/supranational/blst) C library (v0.3) through a thin Rust shim compiled via [flutter_rust_bridge](https://pub.dev/packages/flutter_rust_bridge). The native library is built automatically by [Cargokit](https://github.com/nicholaslee119/cargokit) when you run `flutter build` or `flutter test`.

All three functions are synchronous after the one-time `RustLib.init()` call — no `Future` overhead per operation.

## License

MIT — see [LICENSE](LICENSE).

## Publishing (maintainers)

bls_dart uses a two-package publish flow because `rust_lib_bls_dart` (the cargokit native build plugin) must be on pub.dev first.

Local development uses a gitignored `pubspec_overrides.yaml` that redirects to `path: rust_builder`.
The committed `pubspec.yaml` always declares the hosted dep — so no file edits are needed before publishing.

```bash
# Step 1 — publish the native builder sub-package
cd rust_builder && flutter pub publish

# Step 2 — publish the main package
cd .. && flutter pub publish
```

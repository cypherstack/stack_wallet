/// BLS12-381 min_pk signature operations for Dart & Flutter.
///
/// Provides BLS functions for verification and Firo masternode service updates:
///
/// - [bls12381MinPkVerify] — verify a single signature
/// - [bls12381MinPkAggregate] — aggregate multiple signatures into one
/// - [bls12381MinPkVerifyAggregate] — verify an aggregate against multiple keys
///
/// Uses the [blst](https://github.com/supranational/blst) C library via
/// [flutter_rust_bridge](https://pub.dev/packages/flutter_rust_bridge).
///
/// **Supported platforms:** iOS, Android, macOS, Linux, Windows.
/// Web is not supported (blst is a native library).
///
/// Before calling any BLS function, initialize the Rust runtime once:
/// ```dart
/// import 'package:bls_dart/bls_dart.dart';
///
/// void main() async {
///   await RustLib.init();
///   // Now BLS functions are available
/// }
/// ```
library;

export 'src/rust/api/bls.dart'
    show
        bls12381MinPkVerify,
        bls12381MinPkAggregate,
        bls12381MinPkVerifyAggregate,
        firoLegacyBlsPublicKey,
        firoLegacyBlsSignDigest;
export 'src/rust/frb_generated.dart' show RustLib;

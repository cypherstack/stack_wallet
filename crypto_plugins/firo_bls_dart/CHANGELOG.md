## 0.1.2

- Fixed: `rust_lib_bls_dart` dependency updated to ^0.0.3 which bundles Rust source inside the published package (fixes build failure when consumed from pub.dev)

## 0.1.1

- Fixed: `rust_lib_bls_dart` dependency updated to ^0.0.2 which includes iOS/macOS podspecs and Android/Linux/Windows build configs missing from v0.0.1

## 0.1.0

- Initial release.
- BLS12-381 min_pk signature verification via blst.
- `bls12381MinPkVerify` — single signature verification.
- `bls12381MinPkAggregate` — aggregate multiple signatures.
- `bls12381MinPkVerifyAggregate` — verify aggregate against multiple public keys.
- Platform support: Android, iOS, macOS, Linux, Windows.
- DST: `BLS_SIG_BLS12381G2_XMD:SHA-256_SSWU_RO_NUL_` (Sui Move compatible).

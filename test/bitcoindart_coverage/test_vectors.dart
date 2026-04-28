/// Shared test vectors for bitcoindart coverage and coin equivalence tests.
///
/// This file exports constants used by ALL test files in this directory.
/// It must NOT import bitcoindart or coin -- only dart:typed_data and
/// dart:convert for self-contained helper functions.
///
/// Vector groups:
///   1. Private keys (BIP-32 test vector 1 derived)
///   2. Particl network params
///   3. Firo network params
///   4. Transaction version constants
///   5. SLP/FUZE detection bytes and script vectors
///   6. OP_RETURN payloads
///   7. Signing test hashes
///   8. Helper functions
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

// ---------------------------------------------------------------------------
// 1. Private keys -- from BIP-32 Test Vector 1
//    Seed: 000102030405060708090a0b0c0d0e0f
//    Master key (m):
// ---------------------------------------------------------------------------

/// BIP-32 Test Vector 1 master private key (chain m).
const kTestPrivKeyHex1 =
    'e8f32e723decf4051aefac8e2c93c9c5b214313817cdb01a1494b917c8436b35';

/// BIP-32 Test Vector 1 master compressed public key (chain m).
const kTestPubKeyHex1 =
    '0339a36013301597daef41fbe593a02cc513d0b55527ec2df1050e2e8ff49c85c2';

/// BIP-32 Test Vector 1 child key (chain m/0H).
const kTestPrivKeyHex2 =
    'edb2e14f9ee77d26dd93b4ecede8d16ed408ce149b6cd80b0715a2d911a0afea';

/// BIP-32 Test Vector 1 child compressed public key (chain m/0H).
const kTestPubKeyHex2 =
    '035a784662a4a20a65bf6aab9ae98a6c068a81c52e4b032c0fb5400c706cfccc56';

/// BIP-32 Test Vector 1 child key (chain m/0H/1).
const kTestPrivKeyHex3 =
    '3c6cb8d0f6a264c91ea8b5030fadaa8e538b020f0a387421a12de9319dc93368';

/// BIP-32 Test Vector 1 child compressed public key (chain m/0H/1).
const kTestPubKeyHex3 =
    '03501e454bf00751f24b1b489aa925215d66af2234e3891c3b21a52bedb3cd711c';

// ---------------------------------------------------------------------------
// 2. Particl mainnet network params
//    Source: lib/wallets/crypto_currency/coins/particl.dart networkParams
// ---------------------------------------------------------------------------

/// Particl mainnet WIF prefix.
const kParticlWif = 0x6c;

/// Particl mainnet P2PKH prefix.
const kParticlP2pkh = 0x38;

/// Particl mainnet P2SH prefix.
const kParticlP2sh = 0x3c;

/// Particl mainnet bech32 human-readable part.
const kParticlBech32 = 'pw';

/// Particl message prefix (same as Bitcoin).
const kParticlMessagePrefix = '\x18Bitcoin Signed Message:\n';

/// Particl mainnet BIP-32 public HD prefix.
const kParticlPubHD = 0x696e82d1;

/// Particl mainnet BIP-32 private HD prefix.
const kParticlPrivHD = 0x8f1daeb8;

// ---------------------------------------------------------------------------
// 3. Firo mainnet network params
//    Source: lib/wallets/crypto_currency/coins/firo.dart networkParams
// ---------------------------------------------------------------------------

/// Firo mainnet WIF prefix.
const kFiroWif = 0xd2;

/// Firo mainnet P2PKH prefix.
const kFiroP2pkh = 0x52;

/// Firo mainnet P2SH prefix.
const kFiroP2sh = 0x07;

/// Firo mainnet bech32 human-readable part.
const kFiroBech32 = 'bc';

/// Firo message prefix (note: says "Zcoin" for historical reasons).
const kFiroMessagePrefix = '\x16Zcoin Signed Message:\n';

/// Firo mainnet BIP-32 public HD prefix.
const kFiroPubHD = 0x0488b21e;

/// Firo mainnet BIP-32 private HD prefix.
const kFiroPrivHD = 0x0488ade4;

// ---------------------------------------------------------------------------
// 4. Transaction version constants
// ---------------------------------------------------------------------------

/// Particl transaction version (hardcoded in particl_wallet.dart).
const kParticlTxVersion = 160;

/// Spark transaction version: 3 | (9 << 16) = 589827.
const kSparkTxVersion = 3 | (9 << 16); // 589827

// ---------------------------------------------------------------------------
// 5. SLP / FUZE detection bytes and script vectors
//    Source: lib/services/coins/bitcoincash/bch_utils.dart
// ---------------------------------------------------------------------------

/// SLP lokad identifier bytes: 'SLP\x00'.
const kSlpId = [83, 76, 80, 0];

/// FUZE lokad identifier bytes: 'FUZ\x00'.
const kFuzeId = [70, 85, 90, 0];

/// A minimal valid SLP OP_RETURN scriptPubKey.
///
/// Structure: OP_RETURN (0x6a) | PUSHDATA 4 (0x04) | 'SLP\x00' |
///            PUSHDATA 1 (0x01) | token_type (0x01) |
///            PUSHDATA 4 (0x04) | 'SEND' (0x53454e44 -- not needed for
///            detection but makes the script realistic).
final kSlpScriptPubKey = Uint8List.fromList([
  0x6a, // OP_RETURN
  0x04, 83, 76, 80, 0, // PUSHDATA(4) 'SLP\x00'
  0x01, 0x01, // PUSHDATA(1) token_type 0x01
  0x04, 0x53, 0x45, 0x4e, 0x44, // PUSHDATA(4) 'SEND'
]);

/// A minimal valid FUZE OP_RETURN scriptPubKey.
///
/// Structure: OP_RETURN (0x6a) | PUSHDATA 4 (0x04) | 'FUZ\x00' |
///            PUSHDATA 32 (0x20) | 32-byte session hash (all 0xAB).
final kFuzeScriptPubKey = Uint8List.fromList([
  0x6a, // OP_RETURN
  0x04, 70, 85, 90, 0, // PUSHDATA(4) 'FUZ\x00'
  0x20, // PUSHDATA(32) -- session hash follows
  ...List<int>.filled(32, 0xab), // 32 bytes of deterministic filler
]);

/// A standard P2PKH scriptPubKey that is NOT SLP.
///
/// Structure: OP_DUP OP_HASH160 <20-byte-hash> OP_EQUALVERIFY OP_CHECKSIG
final kNonSlpScriptPubKey = Uint8List.fromList([
  0x76, // OP_DUP
  0xa9, // OP_HASH160
  0x14, // PUSHDATA(20)
  ...List<int>.filled(20, 0x00), // 20-byte pubkey hash (zeroed)
  0x88, // OP_EQUALVERIFY
  0xac, // OP_CHECKSIG
]);

// ---------------------------------------------------------------------------
// 6. OP_RETURN payload -- blinded payment code (80 bytes)
//    Deterministic: SHA-256 of 'test_blinded_payment_code', zero-padded to 80.
// ---------------------------------------------------------------------------

/// An 80-byte payload for OP_RETURN paynym notification transactions.
///
/// Constructed from SHA-256('test_blinded_payment_code') (32 bytes) followed
/// by 48 zero bytes to reach the required 80-byte length.
final kPaynymBlindedCode = Uint8List.fromList([
  ...sha256
      .convert(utf8.encode('test_blinded_payment_code'))
      .bytes, // 32 bytes
  ...List<int>.filled(48, 0x00), // pad to 80 bytes
]);

// ---------------------------------------------------------------------------
// 7. Test hash for signing (32 bytes) and expected signature outputs
//    SHA-256 of 'test_message'.
// ---------------------------------------------------------------------------

/// A deterministic 32-byte hash suitable for ECDSA signing tests.
final kTestHash32 = Uint8List.fromList(
  sha256.convert(utf8.encode('test_message')).bytes,
);

/// Expected 64-byte compact ECDSA signature (r||s) produced by signing
/// [kTestHash32] with [kTestPrivKeyHex1] using deterministic RFC 6979.
///
/// bitcoindart ECPair.sign() returns compact (r||s), NOT DER.
/// coin EcdsaSig.sign() also returns compact internally.
/// Both must produce this identical byte sequence for the same key+hash.
const kExpectedCompactSigHex1 =
    '314700a16c5a9c8ec50f7dd61fdcfa0f9c3c5be5117e99d92bd7daecd57a5110'
    '109d23cf292ccb1252e35a93020b9472a254db3527dbe95156aa32037d4df1ab';

// ---------------------------------------------------------------------------
// 8. Transaction building test vectors
// ---------------------------------------------------------------------------

/// A deterministic 32-byte txid for UTXO input tests.
///
/// Derived from SHA-256('test_utxo_1'), then reversed to match the txid
/// byte-order convention used by bitcoindart (internal byte order).
/// The hex string is the display-order txid (reversed hash).
final kTestTxId1 = bytesToHex(Uint8List.fromList(
  sha256.convert(utf8.encode('test_utxo_1')).bytes.reversed.toList(),
));

/// Vout index for the test UTXO.
const kTestVout1 = 0;

/// Value of the test UTXO in satoshis (1 mBTC equivalent).
const kTestUtxoValue1 = 100000;

/// Amount to send in satoshis.
const kTestSendAmount1 = 90000;

/// Fee amount in satoshis (kTestUtxoValue1 - kTestSendAmount1).
const kTestFeeAmount1 = 10000;

// ---------------------------------------------------------------------------
// 9. Helper functions
// ---------------------------------------------------------------------------

/// Converts a hex string to [Uint8List].
///
/// Accepts even-length hex strings with no prefix. Throws [FormatException]
/// on invalid input.
Uint8List hexToBytes(String hex) {
  if (hex.length % 2 != 0) {
    throw FormatException('Hex string must have even length', hex);
  }
  return Uint8List.fromList([
    for (int i = 0; i < hex.length; i += 2)
      int.parse(hex.substring(i, i + 2), radix: 16),
  ]);
}

/// Converts a [Uint8List] to a lowercase hex string.
String bytesToHex(Uint8List bytes) {
  return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
}

/// Shared BIP-47 test vectors for equivalence tests between bip47 and coin.
///
/// Vectors sourced from the Samourai BIP-47 test suite:
/// https://gist.github.com/SamouraiDev/6aad669604c5930864bd
/// Spec: https://github.com/bitcoin/bips/blob/master/bip-0047.mediawiki
///
/// This file must NOT import bip47 or coin -- only dart:typed_data for
/// self-contained helper functions.
library;

import 'dart:typed_data';

// ---------------------------------------------------------------------------
// 1. Seeds (128-byte hex strings)
// ---------------------------------------------------------------------------

/// Alice's BIP-39 seed (128 bytes as hex).
const aliceSeedHex =
    '64dca76abc9c6f0cf3d212d248c380c4622c8f93b2c425ec6a5567fd5db57e10'
    'd3e6f94a2f6af4ac2edb8998072aad92098db73558c323777abf5bd1082d970a';

/// Bob's BIP-39 seed (128 bytes as hex).
const bobSeedHex =
    '87eaaac5a539ab028df44d9110defbef3797ddb805ca309f61a69ff96dbaa7ab'
    '5b24038cf029edec5235d933110f0aea8aeecf939ed14fc20730bba71e4b1110';

// ---------------------------------------------------------------------------
// 2. Payment codes (Base58Check encoded)
// ---------------------------------------------------------------------------

/// Alice's v1 payment code (non-segwit).
const alicePaymentCodeBase58 =
    'PM8TJTLJbPRGxSbc8EJi42Wrr6QbNSaSSVJ5Y3E4pbCYiTHUskHg13935Ubb7q8tx9GVbh2UuRnBc3WSyJHhUrw8KhprKnn9eDznYGieTzFcwQRya4GA';

/// Bob's v1 payment code (non-segwit).
const bobPaymentCodeBase58 =
    'PM8TJS2JxQ5ztXUpBBRnpTbcUXbUHy2T1abfrb3KkAAtMEGNbey4oumH7Hc578WgQJhPjBxteQ5GHHToTYHE3A1w6p7tU6KSoFmWBVbFGjKPisZDbP97';

// ---------------------------------------------------------------------------
// 3. Notification address
// ---------------------------------------------------------------------------

/// Alice's notification address (P2PKH derived from child key at index 0).
const aliceNotificationAddress = '1JDdmqFLhpzcUwPeinhJbUPw4Co3aWLyzW';

// ---------------------------------------------------------------------------
// 4. Child public keys (compressed, hex)
// ---------------------------------------------------------------------------

/// Alice's A0 public key (child 0 from payment code).
const aliceA0PubHex =
    '0353883a146a23f988e0f381a9507cbdb3e3130cd81b3ce26daf2af088724ce683';

/// Bob's B0 public key (child 0 from payment code).
const bobB0PubHex =
    '024ce8e3b04ea205ff49f529950616c3db615b1e37753858cc60c1ce64d17e2ad8';

// ---------------------------------------------------------------------------
// 5. Receiving addresses (Alice sends to Bob, 10 P2PKH addresses)
// ---------------------------------------------------------------------------

/// First 10 P2PKH addresses for Alice->Bob payment channel.
const receivingAddresses = [
  '141fi7TY3h936vRUKh1qfUZr8rSBuYbVBK',
  '12u3Uued2fuko2nY4SoSFGCoGLCBUGPkk6',
  '1FsBVhT5dQutGwaPePTYMe5qvYqqjxyftc',
  '1CZAmrbKL6fJ7wUxb99aETwXhcGeG3CpeA',
  '1KQvRShk6NqPfpr4Ehd53XUhpemBXtJPTL',
  '1KsLV2F47JAe6f8RtwzfqhjVa8mZEnTM7t',
  '1DdK9TknVwvBrJe7urqFmaxEtGF2TMWxzD',
  '16DpovNuhQJH7JUSZQFLBQgQYS4QB9Wy8e',
  '17qK2RPGZMDcci2BLQ6Ry2PDGJErrNojT5',
  '1GxfdfP286uE24qLZ9YRP3EWk2urqXgC4s',
];

// ---------------------------------------------------------------------------
// 6. Outpoint for blinding tests
// ---------------------------------------------------------------------------

/// Outpoint bytes (txid + vout) for notification blinding.
const outpointHex =
    '86f411ab1c8e70ae8a0795ab7a6757aea6e4d5ae1826fc7b8f00c597d500609c'
    '01000000';

// ---------------------------------------------------------------------------
// 7. Helper functions
// ---------------------------------------------------------------------------

/// Converts a hex string to [Uint8List].
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

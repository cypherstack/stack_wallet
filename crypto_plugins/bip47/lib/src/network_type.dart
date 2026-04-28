/// Lightweight network type definition for BIP-47 address generation.
///
/// This replaces the bitcoindart NetworkType dependency. Fields match the
/// bitcoindart API so callers can migrate with minimal changes.
class Bip32Type {
  final int public;
  final int private;

  const Bip32Type({required this.public, required this.private});
}

class NetworkType {
  final String? messagePrefix;
  final String? bech32;
  final Bip32Type bip32;
  final int pubKeyHash;
  final int scriptHash;
  final int wif;

  const NetworkType({
    this.messagePrefix,
    this.bech32,
    required this.bip32,
    required this.pubKeyHash,
    required this.scriptHash,
    required this.wif,
  });
}

const bitcoin = NetworkType(
  messagePrefix: '\x18Bitcoin Signed Message:\n',
  bech32: 'bc',
  bip32: Bip32Type(public: 0x0488b21e, private: 0x0488ade4),
  pubKeyHash: 0x00,
  scriptHash: 0x05,
  wif: 0x80,
);

const testnet = NetworkType(
  messagePrefix: '\x18Bitcoin Signed Message:\n',
  bech32: 'tb',
  bip32: Bip32Type(public: 0x043587cf, private: 0x04358394),
  pubKeyHash: 0x6f,
  scriptHash: 0xc4,
  wif: 0xef,
);

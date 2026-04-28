import 'package:coin/coin.dart';

/// Standard BIP39 test mnemonic used across all address generation tests.
const kStandardMnemonic =
    'abandon abandon abandon abandon abandon abandon abandon abandon '
    'abandon abandon abandon about';

/// Describes one (coin, derivePathType) address generation test case.
class AddressVector {
  final String coinName;
  final String derivePathType;
  final String derivationPath;
  final String addressType; // 'p2pkh', 'p2sh', 'p2wpkh', 'p2tr'
  final String expectedAddressPrefix;

  /// The [Chain] for this coin's mainnet.
  final Chain chain;

  const AddressVector({
    required this.coinName,
    required this.derivePathType,
    required this.derivationPath,
    required this.addressType,
    required this.expectedAddressPrefix,
    required this.chain,
  });

  @override
  String toString() => '$coinName $derivePathType ($derivationPath)';
}

// ---------------------------------------------------------------------------
// Chain definitions (inline, matching wallet networkParams exactly)
// ---------------------------------------------------------------------------

const _bitcoin = Chain(
  wifPrefix: 0x80,
  p2pkhPrefix: 0x00,
  p2shPrefix: 0x05,
  bech32Hrp: 'bc',
  name: 'Bitcoin',
  bip44CoinType: 0,
  privHDPrefix: 0x0488ade4,
  pubHDPrefix: 0x0488b21e,
  messagePrefix: '\x18Bitcoin Signed Message:\n',
);

const _litecoin = Chain(
  wifPrefix: 0xb0,
  p2pkhPrefix: 0x30,
  p2shPrefix: 0x32,
  bech32Hrp: 'ltc',
  name: 'Litecoin',
  bip44CoinType: 2,
  privHDPrefix: 0x0488ade4,
  pubHDPrefix: 0x0488b21e,
  messagePrefix: '\x19Litecoin Signed Message:\n',
);

const _bitcoinCash = Chain(
  wifPrefix: 0x80,
  p2pkhPrefix: 0x00,
  p2shPrefix: 0x05,
  name: 'Bitcoin Cash',
  bip44CoinType: 145,
  supportsSegwit: false,
  supportsTaproot: false,
  privHDPrefix: 0x0488ade4,
  pubHDPrefix: 0x0488b21e,
  messagePrefix: '\x18Bitcoin Signed Message:\n',
);

const _namecoin = Chain(
  wifPrefix: 0xb4,
  p2pkhPrefix: 0x34,
  p2shPrefix: 0x0d,
  bech32Hrp: 'nc',
  name: 'Namecoin',
  bip44CoinType: 7,
  privHDPrefix: 0x0488ade4,
  pubHDPrefix: 0x0488b21e,
  messagePrefix: '\x19Namecoin Signed Message:\n',
);

const _firo = Chain(
  wifPrefix: 0xd2,
  p2pkhPrefix: 0x52,
  p2shPrefix: 0x07,
  bech32Hrp: 'bc',
  name: 'Firo',
  bip44CoinType: 136,
  privHDPrefix: 0x0488ade4,
  pubHDPrefix: 0x0488b21e,
  messagePrefix: '\x16Zcoin Signed Message:\n',
);

const _particl = Chain(
  wifPrefix: 0x6c,
  p2pkhPrefix: 0x38,
  p2shPrefix: 0x3c,
  bech32Hrp: 'pw',
  name: 'Particl',
  bip44CoinType: 44,
  supportsSegwit: true,
  supportsTaproot: false,
  privHDPrefix: 0x8f1daeb8,
  pubHDPrefix: 0x696e82d1,
  messagePrefix: '\x18Bitcoin Signed Message:\n',
);

const _dash = Chain(
  wifPrefix: 0xcc,
  p2pkhPrefix: 0x4c,
  p2shPrefix: 0x10,
  name: 'Dash',
  bip44CoinType: 5,
  supportsSegwit: false,
  supportsTaproot: false,
  privHDPrefix: 0x0488ade4,
  pubHDPrefix: 0x0488b21e,
  messagePrefix: '\x18Dash Signed Message:\n',
);

const _dogecoin = Chain(
  wifPrefix: 0x9e,
  p2pkhPrefix: 0x1e,
  p2shPrefix: 0x16,
  name: 'Dogecoin',
  bip44CoinType: 3,
  supportsSegwit: false,
  supportsTaproot: false,
  privHDPrefix: 0x02fac398,
  pubHDPrefix: 0x02facafd,
  messagePrefix: '\x19Dogecoin Signed Message:\n',
);

// eCash shares the same network bytes as Bitcoin (p2pkh=0x00, p2sh=0x05).
const _ecash = Chain(
  wifPrefix: 0x80,
  p2pkhPrefix: 0x00,
  p2shPrefix: 0x05,
  bech32Hrp: 'bc',
  name: 'eCash',
  bip44CoinType: 145,
  privHDPrefix: 0x0488ade4,
  pubHDPrefix: 0x0488b21e,
  messagePrefix: '\x18Bitcoin Signed Message:\n',
);

const _fact0rn = Chain(
  wifPrefix: 0x80,
  p2pkhPrefix: 0x00,
  p2shPrefix: 0x05,
  bech32Hrp: 'fact',
  name: 'Fact0rn',
  bip44CoinType: 0,
  privHDPrefix: 0x0488ade4,
  pubHDPrefix: 0x0488b21e,
  messagePrefix: '\x18Bitcoin Signed Message:\n',
);

const _peercoin = Chain(
  wifPrefix: 0xb7,
  p2pkhPrefix: 0x37,
  p2shPrefix: 0x75,
  bech32Hrp: 'pc',
  name: 'Peercoin',
  bip44CoinType: 6,
  privHDPrefix: 0x0488ade4,
  pubHDPrefix: 0x0488b21e,
  messagePrefix: 'Peercoin Signed Message:\n',
);

// ---------------------------------------------------------------------------
// The full address vector matrix (22 combinations from wallet code)
// ---------------------------------------------------------------------------

const kAddressVectors = <AddressVector>[
  // === Bitcoin (coinType=0): bip44, bip49, bip84, bip86 ===
  AddressVector(
    coinName: 'Bitcoin',
    derivePathType: 'bip44',
    derivationPath: "m/44'/0'/0'/0/0",
    addressType: 'p2pkh',
    expectedAddressPrefix: '1',
    chain: _bitcoin,
  ),
  AddressVector(
    coinName: 'Bitcoin',
    derivePathType: 'bip49',
    derivationPath: "m/49'/0'/0'/0/0",
    addressType: 'p2sh',
    expectedAddressPrefix: '3',
    chain: _bitcoin,
  ),
  AddressVector(
    coinName: 'Bitcoin',
    derivePathType: 'bip84',
    derivationPath: "m/84'/0'/0'/0/0",
    addressType: 'p2wpkh',
    expectedAddressPrefix: 'bc1q',
    chain: _bitcoin,
  ),
  AddressVector(
    coinName: 'Bitcoin',
    derivePathType: 'bip86',
    derivationPath: "m/86'/0'/0'/0/0",
    addressType: 'p2tr',
    expectedAddressPrefix: 'bc1p',
    chain: _bitcoin,
  ),

  // === Litecoin (coinType=2): bip44, bip49, bip84 ===
  AddressVector(
    coinName: 'Litecoin',
    derivePathType: 'bip44',
    derivationPath: "m/44'/2'/0'/0/0",
    addressType: 'p2pkh',
    expectedAddressPrefix: 'L',
    chain: _litecoin,
  ),
  AddressVector(
    coinName: 'Litecoin',
    derivePathType: 'bip49',
    derivationPath: "m/49'/2'/0'/0/0",
    addressType: 'p2sh',
    expectedAddressPrefix: 'M',
    chain: _litecoin,
  ),
  AddressVector(
    coinName: 'Litecoin',
    derivePathType: 'bip84',
    derivationPath: "m/84'/2'/0'/0/0",
    addressType: 'p2wpkh',
    expectedAddressPrefix: 'ltc1q',
    chain: _litecoin,
  ),

  // === Bitcoin Cash (coinType=145): bip44 (coinType=145), bch44 (coinType=0)
  AddressVector(
    coinName: 'Bitcoin Cash',
    derivePathType: 'bip44',
    derivationPath: "m/44'/145'/0'/0/0",
    addressType: 'p2pkh',
    expectedAddressPrefix: '1',
    chain: _bitcoinCash,
  ),
  AddressVector(
    coinName: 'Bitcoin Cash',
    derivePathType: 'bch44',
    derivationPath: "m/44'/0'/0'/0/0",
    addressType: 'p2pkh',
    expectedAddressPrefix: '1',
    chain: _bitcoinCash,
  ),

  // === Namecoin (coinType=7): bip44, bip49, bip84 ===
  AddressVector(
    coinName: 'Namecoin',
    derivePathType: 'bip44',
    derivationPath: "m/44'/7'/0'/0/0",
    addressType: 'p2pkh',
    expectedAddressPrefix: 'N',
    chain: _namecoin,
  ),
  AddressVector(
    coinName: 'Namecoin',
    derivePathType: 'bip49',
    derivationPath: "m/49'/7'/0'/0/0",
    addressType: 'p2sh',
    expectedAddressPrefix: '', // P2SH prefix 0x0d -> base58 char varies
    chain: _namecoin,
  ),
  AddressVector(
    coinName: 'Namecoin',
    derivePathType: 'bip84',
    derivationPath: "m/84'/7'/0'/0/0",
    addressType: 'p2wpkh',
    expectedAddressPrefix: 'nc1q',
    chain: _namecoin,
  ),

  // === Firo (coinType=136): bip44 ===
  AddressVector(
    coinName: 'Firo',
    derivePathType: 'bip44',
    derivationPath: "m/44'/136'/0'/0/0",
    addressType: 'p2pkh',
    expectedAddressPrefix: 'a',
    chain: _firo,
  ),

  // === Particl (coinType=44): bip44, bip84 ===
  AddressVector(
    coinName: 'Particl',
    derivePathType: 'bip44',
    derivationPath: "m/44'/44'/0'/0/0",
    addressType: 'p2pkh',
    expectedAddressPrefix: 'P',
    chain: _particl,
  ),
  AddressVector(
    coinName: 'Particl',
    derivePathType: 'bip84',
    derivationPath: "m/84'/44'/0'/0/0",
    addressType: 'p2wpkh',
    expectedAddressPrefix: 'pw1q',
    chain: _particl,
  ),

  // === Dash (coinType=5): bip44 ===
  AddressVector(
    coinName: 'Dash',
    derivePathType: 'bip44',
    derivationPath: "m/44'/5'/0'/0/0",
    addressType: 'p2pkh',
    expectedAddressPrefix: 'X',
    chain: _dash,
  ),

  // === Dogecoin (coinType=3): bip44 ===
  AddressVector(
    coinName: 'Dogecoin',
    derivePathType: 'bip44',
    derivationPath: "m/44'/3'/0'/0/0",
    addressType: 'p2pkh',
    expectedAddressPrefix: 'D',
    chain: _dogecoin,
  ),

  // === eCash (coinType=899 for eCash44, 145 for bip44): both produce P2PKH
  AddressVector(
    coinName: 'eCash',
    derivePathType: 'eCash44',
    derivationPath: "m/44'/899'/0'/0/0",
    addressType: 'p2pkh',
    expectedAddressPrefix: '1',
    chain: _ecash,
  ),
  AddressVector(
    coinName: 'eCash',
    derivePathType: 'bip44',
    derivationPath: "m/44'/145'/0'/0/0",
    addressType: 'p2pkh',
    expectedAddressPrefix: '1',
    chain: _ecash,
  ),

  // === Fact0rn (coinType=0): bip84 ===
  AddressVector(
    coinName: 'Fact0rn',
    derivePathType: 'bip84',
    derivationPath: "m/84'/0'/0'/0/0",
    addressType: 'p2wpkh',
    expectedAddressPrefix: 'fact1q',
    chain: _fact0rn,
  ),

  // === Peercoin (coinType=6): bip44, bip84 ===
  AddressVector(
    coinName: 'Peercoin',
    derivePathType: 'bip44',
    derivationPath: "m/44'/6'/0'/0/0",
    addressType: 'p2pkh',
    expectedAddressPrefix: 'P',
    chain: _peercoin,
  ),
  AddressVector(
    coinName: 'Peercoin',
    derivePathType: 'bip84',
    derivationPath: "m/84'/6'/0'/0/0",
    addressType: 'p2wpkh',
    expectedAddressPrefix: 'pc1q',
    chain: _peercoin,
  ),
];

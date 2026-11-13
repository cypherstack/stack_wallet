import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/address.dart';
import 'package:stackwallet/wallets/crypto_currency/crypto_currency.dart';

const _mainnetTransparent = 't1c8oqrzA1kYPdgVhfDNUZn3buAbk6rXxiX';
const _mainnetSapling =
    'zs1zt3mq96vp65l8ch54r78nc50ml68qsyg3pkteq8pn8sfgza'
    'khgw4vqn6px5w08hrf2uzuam5kmj';
const _mainnetUnified =
    'u1tcw2tuatlzdc4ncep4nef7v9h5q87jx7t4fzyj7sw5g6775u3fwkucjafgsl2dg6h3hfj'
    'tml85ggqakl5mf2c746ygk7qnp8kyhentqkcnpqwarfcceczd0drzuvtxaeak9kadkwp6sn5x'
    'pj40cwmpjcu8aqy6v8rueum0h9mvefhhfytvrq2dcwxsx4cdk7uzv99yhspftg72ut509';

void main() {
  final zcash = Zcash(CryptoCurrencyNetwork.main);

  test('keeps existing persisted address type ordinals stable', () {
    expect(AddressType.zcashUnified.index, 20);
    expect(AddressType.zcashSapling.index, 21);
  });

  test('classifies supported standalone and unified Zcash addresses', () {
    expect(zcash.getAddressType(_mainnetUnified), AddressType.zcashUnified);
    expect(zcash.getAddressType(_mainnetSapling), AddressType.zcashSapling);
    expect(zcash.getAddressType(_mainnetTransparent), AddressType.p2pkh);
  });

  test('rejects invalid or wrong-network Zcash addresses', () {
    expect(zcash.getAddressType('not-an-address'), isNull);
    expect(
      Zcash(CryptoCurrencyNetwork.test).getAddressType(_mainnetTransparent),
      isNull,
    );
  });
}

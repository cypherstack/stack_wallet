import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/wallets/crypto_currency/crypto_currency.dart';

void main() {
  test(
    'mainnet and testnet transaction explorers use maintained endpoints',
    () {
      const txid =
          '0123456789abcdef0123456789abcdef'
          '0123456789abcdef0123456789abcdef';

      expect(
        Zcash(CryptoCurrencyNetwork.main).defaultBlockExplorer(txid),
        Uri.https('mainnet.zcashexplorer.app', '/transactions/$txid'),
      );
      expect(
        Zcash(CryptoCurrencyNetwork.test).defaultBlockExplorer(txid),
        Uri.https('testnet.zcashexplorer.app', '/transactions/$txid'),
      );
      expect(
        () => Zcash(CryptoCurrencyNetwork.regtest).defaultBlockExplorer(txid),
        throwsUnsupportedError,
      );
    },
  );

  test('node defaults remain explicit rather than guessing an operator', () {
    final coin = Zcash(CryptoCurrencyNetwork.main);

    expect(coin.defaultNodeOrNull(isPrimary: true), isNull);
    expect(() => coin.defaultNode(isPrimary: true), throwsUnsupportedError);
  });
}

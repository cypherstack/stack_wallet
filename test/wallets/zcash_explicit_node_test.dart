import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/wallets/crypto_currency/crypto_currency.dart';

void main() {
  for (final network in const [
    CryptoCurrencyNetwork.main,
    CryptoCurrencyNetwork.test,
    CryptoCurrencyNetwork.regtest,
  ]) {
    test('Zcash $network requires an explicitly configured node', () {
      final coin = Zcash(network);

      expect(coin.defaultNodeOrNull(isPrimary: true), isNull);
      expect(
        () => coin.defaultNode(isPrimary: true),
        throwsA(
          isA<UnsupportedError>().having(
            (error) => error.message,
            'message',
            contains('explicitly configured lightwalletd'),
          ),
        ),
      );
    });
  }
}

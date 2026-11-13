import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/wallets/crypto_currency/crypto_currency.dart';

void main() {
  test('regtest is classified as a test network', () {
    expect(CryptoCurrencyNetwork.regtest.isTestNet, isTrue);
    expect(CryptoCurrencyNetwork.main.isTestNet, isFalse);
  });
}

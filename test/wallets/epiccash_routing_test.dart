import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/wallets/crypto_currency/crypto_currency.dart';
import 'package:stackwallet/wallets/wallet/impl/epiccash_wallet.dart';

void main() {
  test('HTTP receivers bypass Epicbox', () {
    final wallet = EpiccashWallet(CryptoCurrencyNetwork.main);

    expect(wallet.shouldCheckEpicbox('http://receiver'), isFalse);
    expect(wallet.shouldCheckEpicbox('https://receiver'), isFalse);
    expect(wallet.shouldCheckEpicbox('user@epicbox.example'), isTrue);
  });
}

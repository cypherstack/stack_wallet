import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/wallets/crypto_currency/crypto_currency.dart';

void main() {
  test('Dash dust limit uses network policy units', () {
    final dash = Dash(CryptoCurrencyNetwork.main);

    expect(dash.dustLimit.raw, BigInt.from(546));
    expect(dash.dustLimit.fractionDigits, 8);
  });
}

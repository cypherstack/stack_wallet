import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/wallets/crypto_currency/crypto_currency.dart';

void main() {
  test('Peercoin fallback fee uses the fixed network rate', () {
    final peercoin = Peercoin(CryptoCurrencyNetwork.main);

    expect(peercoin.defaultFeeRate, BigInt.from(10000));
  });
}

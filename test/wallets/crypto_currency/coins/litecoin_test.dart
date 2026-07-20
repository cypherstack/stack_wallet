import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/wallets/crypto_currency/crypto_currency.dart';

void main() {
  group('minimumFeeRatePerKB', () {
    test('Litecoin enforces its default minimum relay policy', () {
      expect(
        Litecoin(CryptoCurrencyNetwork.main).minimumFeeRatePerKB,
        BigInt.from(1000),
      );
      expect(
        Litecoin(CryptoCurrencyNetwork.test).minimumFeeRatePerKB,
        BigInt.from(1000),
      );
    });

    test('other Electrum currencies are unchanged by default', () {
      expect(
        Bitcoin(CryptoCurrencyNetwork.main).minimumFeeRatePerKB,
        BigInt.zero,
      );
    });
  });
}

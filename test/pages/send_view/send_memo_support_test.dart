import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/pages/send_view/send_memo_support.dart';
import 'package:stackwallet/wallets/crypto_currency/crypto_currency.dart';

void main() {
  test('Zcash reuses the optional memo affordance', () {
    final coin = Zcash(CryptoCurrencyNetwork.main);

    expect(supportsOptionalSendMemo(coin), isTrue);
    expect(optionalSendMemo(coin, 'shielded memo'), 'shielded memo');
  });

  test('existing memo support and unsupported coin behavior are preserved', () {
    expect(
      supportsOptionalSendMemo(Stellar(CryptoCurrencyNetwork.main)),
      isTrue,
    );
    expect(
      supportsOptionalSendMemo(Solana(CryptoCurrencyNetwork.main)),
      isTrue,
    );
    expect(
      optionalSendMemo(Bitcoin(CryptoCurrencyNetwork.main), 'not supported'),
      isNull,
    );
  });
}

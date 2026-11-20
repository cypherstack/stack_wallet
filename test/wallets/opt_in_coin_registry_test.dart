import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/app_config.dart';
import 'package:stackwallet/wallets/crypto_currency/crypto_currency.dart';
import 'package:stackwallet/wallets/crypto_currency/opt_in_coin_registry.dart';

void main() {
  test('AppConfig defaults to no opt-in declaration', () {
    expect(AppConfig.extraCoins, isEmpty);
    expect(AppConfig.coins, isNotEmpty);
  });

  test('resolves multiple opt-in coins in declaration order', () {
    final coins = resolveOptInCoins('test, main', factories: factories);

    expect(coins.map((coin) => coin.identifier), ['bitcoinTestNet', 'bitcoin']);
  });

  test('trims whitespace and ignores empty entries', () {
    final coins = resolveOptInCoins(' , main , , test, ', factories: factories);

    expect(coins.map((coin) => coin.identifier), ['bitcoin', 'bitcoinTestNet']);
  });

  test('refuses unknown and duplicate opt-in names', () {
    expect(
      () => resolveOptInCoins('missing', factories: factories),
      throwsArgumentError,
    );
    expect(
      () => resolveOptInCoins('main,main', factories: factories),
      throwsA(isA<StateError>()),
    );
  });

  test('returns an unmodifiable result', () {
    final coins = resolveOptInCoins('main', factories: factories);

    expect(
      () => coins.add(Bitcoin(CryptoCurrencyNetwork.main)),
      throwsUnsupportedError,
    );
  });
}

final factories = <String, OptInCoinFactory>{
  'main': () => Bitcoin(CryptoCurrencyNetwork.main),
  'test': () => Bitcoin(CryptoCurrencyNetwork.test),
};

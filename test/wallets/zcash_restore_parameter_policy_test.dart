import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/wallets/crypto_currency/crypto_currency.dart';
import 'package:stackwallet/wallets/wallet/intermediate/zcash_restore_parameter_policy.dart';

void main() {
  test('mainnet restored Sapling funds acquire proving parameters', () {
    expect(
      shouldAcquireSaplingParametersAfterRestore(
        network: CryptoCurrencyNetwork.main,
        spendableSaplingZatoshis: 1,
      ),
      isTrue,
    );
  });

  test('testnet restored Sapling funds acquire proving parameters', () {
    expect(
      shouldAcquireSaplingParametersAfterRestore(
        network: CryptoCurrencyNetwork.test,
        spendableSaplingZatoshis: 1,
      ),
      isTrue,
    );
  });

  test('zero spendable Sapling funds do not acquire parameters', () {
    expect(
      shouldAcquireSaplingParametersAfterRestore(
        network: CryptoCurrencyNetwork.main,
        spendableSaplingZatoshis: 0,
      ),
      isFalse,
    );
  });

  test('negative spendable Sapling funds do not acquire parameters', () {
    expect(
      shouldAcquireSaplingParametersAfterRestore(
        network: CryptoCurrencyNetwork.main,
        spendableSaplingZatoshis: -1,
      ),
      isFalse,
    );
  });

  test('regtest restored Sapling funds acquire the shared parameters', () {
    expect(
      shouldAcquireSaplingParametersAfterRestore(
        network: CryptoCurrencyNetwork.regtest,
        spendableSaplingZatoshis: 1,
      ),
      isTrue,
    );
  });
}

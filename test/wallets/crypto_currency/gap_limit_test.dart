import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/wallets/crypto_currency/crypto_currency.dart';

// The per-wallet address gap-limit override (WalletInfoKeys.addressGapLimit) is
// applied via Bip39HDCurrency.effectiveGapLimit in the ElectrumX scan loops.
// It must be UP-ONLY: a stored value below the coin default (or null) must never
// shrink the scan, because scanning shallower than the default could stop before
// a funded address and hide a balance.
void main() {
  group(
    "Bip39HDCurrency.effectiveGapLimit (per-wallet override is up-only)",
    () {
      final btc = Bitcoin(CryptoCurrencyNetwork.main);
      final def = btc.maxUnusedAddressGap;

      test("coin default is a sane positive value", () {
        expect(def, greaterThan(0));
      });

      test("null override falls back to the coin default", () {
        expect(btc.effectiveGapLimit(null), def);
      });

      test("a larger override raises the effective gap", () {
        expect(btc.effectiveGapLimit(def + 150), def + 150);
      });

      test("a smaller/invalid override is clamped up to the default", () {
        expect(btc.effectiveGapLimit(def - 1), def);
        expect(btc.effectiveGapLimit(1), def);
        expect(btc.effectiveGapLimit(0), def);
        expect(btc.effectiveGapLimit(-5), def);
      });

      test("an override equal to the default yields the default", () {
        expect(btc.effectiveGapLimit(def), def);
      });
    },
  );
}

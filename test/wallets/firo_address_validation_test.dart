import "package:coinlib_flutter/coinlib_flutter.dart" as coinlib;
import "package:flutter_test/flutter_test.dart";
import "package:stackwallet/models/isar/models/blockchain_data/address.dart";
import "package:stackwallet/wallets/crypto_currency/crypto_currency.dart";

void main() {
  final mainnet = Firo(CryptoCurrencyNetwork.main);
  final testnet = Firo(CryptoCurrencyNetwork.test);

  test("accepts Firo transparent addresses", () {
    expect(
      mainnet.validateAddress("a8VV7vMzJdTQj1eLEJNskhLEBUxfNWhpAg"),
      isTrue,
    );
    expect(
      mainnet.getAddressType("a8VV7vMzJdTQj1eLEJNskhLEBUxfNWhpAg"),
      AddressType.p2pkh,
    );
    expect(
      testnet.validateAddress("THqfkegzJjpF4PQFAWPhJWMWagwHecfqva"),
      isTrue,
    );
    expect(
      testnet.getAddressType("THqfkegzJjpF4PQFAWPhJWMWagwHecfqva"),
      AddressType.p2pkh,
    );
  });

  test("rejects Bitcoin Bech32 addresses", () {
    const mainnetBitcoin = "bc1qc5ymmsay89r6gr4fy2kklvrkuvzyln4shdvjhf";
    const testnetBitcoin = "tb1qzzlm6mnc8k54mx6akehl8p9ray8r439va5ndyq";

    expect(mainnet.validateAddress(mainnetBitcoin), isFalse);
    expect(mainnet.getAddressType(mainnetBitcoin), isNull);
    expect(
      () => coinlib.Address.fromString(mainnetBitcoin, mainnet.networkParams),
      throwsA(anything),
    );
    expect(testnet.validateAddress(testnetBitcoin), isFalse);
    expect(testnet.getAddressType(testnetBitcoin), isNull);
    expect(
      () => coinlib.Address.fromString(testnetBitcoin, testnet.networkParams),
      throwsA(anything),
    );
  });

  test("keeps Firo exchange addresses", () {
    expect(
      mainnet.validateAddress("EXXMGtieRLNGfgewJ4jJCN4kZFTUcjYMDdHs"),
      isTrue,
    );
    expect(
      testnet.validateAddress("EXTKtrsZSTGU2vUbuCV6sBDVqPAS3JQkaYJ3"),
      isTrue,
    );
  });
}

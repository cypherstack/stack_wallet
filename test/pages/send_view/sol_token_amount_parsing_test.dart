import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/models/isar/models/solana/sol_contract.dart';
import 'package:stackwallet/pages/send_view/sol_token_send_view.dart';
import 'package:stackwallet/wallets/crypto_currency/crypto_currency.dart';

void main() {
  final token = SolContract(
    address: "mint",
    name: "Token",
    symbol: "TKN",
    decimals: 6,
  );
  final solana = Solana(CryptoCurrencyNetwork.main);

  test("mobile SPL inputs use the locale decimal separator", () {
    expect(
      parseMobileSolTokenAmount(
        "1.25",
        locale: "en_US",
        coin: solana,
        tokenContract: token,
      )?.raw,
      BigInt.from(1250000),
    );
    expect(
      parseMobileSolTokenAmount(
        "1,25",
        locale: "de_DE",
        coin: solana,
        tokenContract: token,
      )?.raw,
      BigInt.from(1250000),
    );
    expect(
      parseMobileSolTokenFiatAmount("1,25", locale: "de_DE")?.raw,
      BigInt.from(125),
    );
  });

  test("mobile SPL inputs reject grouping and signs", () {
    for (final value in ["1,000", "+1", "-1", " 1"]) {
      expect(
        parseMobileSolTokenAmount(
          value,
          locale: "en_US",
          coin: solana,
          tokenContract: token,
        ),
        isNull,
        reason: value,
      );
    }
    expect(
      parseMobileSolTokenAmount(
        "1.000",
        locale: "de_DE",
        coin: solana,
        tokenContract: token,
      ),
      isNull,
    );
  });
}

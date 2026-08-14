import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/models/isar/models/solana/sol_contract.dart';
import 'package:stackwallet/pages/send_view/sol_token_send_view.dart';
import 'package:stackwallet/wallets/crypto_currency/crypto_currency.dart';

void main() {
  test("mobile SPL inputs parse locale grouping", () {
    final token = SolContract(
      address: "mint",
      name: "Token",
      symbol: "TKN",
      decimals: 6,
    );
    final solana = Solana(CryptoCurrencyNetwork.main);

    expect(
      parseMobileSolTokenAmount(
        "1,000",
        locale: "en_US",
        coin: solana,
        tokenContract: token,
      )?.raw,
      BigInt.from(1000000000),
    );
    expect(
      parseMobileSolTokenAmount(
        "1.000",
        locale: "de_DE",
        coin: solana,
        tokenContract: token,
      )?.raw,
      BigInt.from(1000000000),
    );
    expect(
      parseMobileSolTokenFiatAmount("1,000", locale: "en_US")?.raw,
      BigInt.from(100000),
    );
    expect(parseMobileSolTokenFiatAmount("+1", locale: "en_US"), isNull);
  });
}

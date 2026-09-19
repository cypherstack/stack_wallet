import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/models/isar/models/solana/sol_contract.dart';
import 'package:stackwallet/pages_desktop_specific/my_stack_view/wallet_view/sub_widgets/desktop_sol_token_send.dart';
import 'package:stackwallet/pages_desktop_specific/my_stack_view/wallet_view/sub_widgets/desktop_token_send.dart';
import 'package:stackwallet/wallets/crypto_currency/crypto_currency.dart';

void main() {
  final token = SolContract(
    address: "mint",
    name: "Token",
    symbol: "TKN",
    decimals: 6,
  );
  final solana = Solana(CryptoCurrencyNetwork.main);

  test("desktop token inputs use the locale decimal separator", () {
    expect(
      parseDesktopSolTokenAmount(
        "1.25",
        locale: "en_US",
        coin: solana,
        tokenContract: token,
      )?.raw,
      BigInt.from(1250000),
    );
    expect(
      parseDesktopSolTokenAmount(
        "1,25",
        locale: "de_DE",
        coin: solana,
        tokenContract: token,
      )?.raw,
      BigInt.from(1250000),
    );
    expect(
      parseDesktopTokenFiatAmount("1,25", locale: "de_DE")?.raw,
      BigInt.from(125),
    );
  });

  test("desktop token inputs reject grouping and signs", () {
    for (final value in ["1,000", "+1", "-1", " 1"]) {
      expect(
        parseDesktopSolTokenAmount(
          value,
          locale: "en_US",
          coin: solana,
          tokenContract: token,
        ),
        isNull,
        reason: value,
      );
    }
    expect(parseDesktopSolTokenFiatAmount("1.000", locale: "de_DE"), isNull);
  });
}

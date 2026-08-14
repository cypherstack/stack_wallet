import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/models/isar/models/solana/sol_contract.dart';
import 'package:stackwallet/pages_desktop_specific/my_stack_view/wallet_view/sub_widgets/desktop_sol_token_send.dart';
import 'package:stackwallet/pages_desktop_specific/my_stack_view/wallet_view/sub_widgets/desktop_token_send.dart';
import 'package:stackwallet/wallets/crypto_currency/crypto_currency.dart';

void main() {
  test('desktop token inputs parse locale grouping', () {
    final token = SolContract(
      address: 'mint',
      name: 'Token',
      symbol: 'TKN',
      decimals: 6,
    );
    final solana = Solana(CryptoCurrencyNetwork.main);

    expect(
      parseDesktopSolTokenAmount(
        '1,000',
        locale: 'en_US',
        coin: solana,
        tokenContract: token,
      )?.raw,
      BigInt.from(1000000000),
    );
    expect(
      parseDesktopSolTokenFiatAmount('1,000', locale: 'en_US')?.raw,
      BigInt.from(100000),
    );
    expect(
      parseDesktopTokenFiatAmount('1.000', locale: 'de_DE')?.raw,
      BigInt.from(100000),
    );
    expect(
      parseDesktopSolTokenAmount(
        '-1',
        locale: 'en_US',
        coin: solana,
        tokenContract: token,
      ),
      isNull,
    );
  });
}

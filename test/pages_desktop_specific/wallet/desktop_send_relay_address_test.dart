import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/pages_desktop_specific/my_stack_view/wallet_view/sub_widgets/desktop_send.dart';
import 'package:stackwallet/wallets/crypto_currency/crypto_currency.dart';

void main() {
  final epic = Epiccash(CryptoCurrencyNetwork.main);
  final mwc = Mimblewimblecoin(CryptoCurrencyNetwork.main);
  final bitcoin = Bitcoin(CryptoCurrencyNetwork.main);

  test('an Epicbox address loses the prefixes and the trailing slash', () {
    expect(
      stripRelayPrefixes(epic, 'https://user@epicbox.example/'),
      'user@epicbox.example',
    );
    expect(
      stripRelayPrefixes(epic, 'http://user@epicbox.example'),
      'user@epicbox.example',
    );
    expect(
      stripRelayPrefixes(epic, 'mailto:user@epicbox.example'),
      'user@epicbox.example',
    );
  });

  test('an MWCMQS address loses the prefixes and the trailing slash', () {
    expect(
      stripRelayPrefixes(mwc, 'https://user@mqs.example/'),
      'user@mqs.example',
    );
    expect(
      stripRelayPrefixes(mwc, 'mailto:user@mqs.example'),
      'user@mqs.example',
    );
  });

  test('an http receiver address is kept as it is', () {
    expect(
      stripRelayPrefixes(epic, 'https://receiver.example:3415'),
      'https://receiver.example:3415',
    );
    expect(
      stripRelayPrefixes(mwc, 'http://receiver.example:3415/'),
      'http://receiver.example:3415/',
    );
  });

  test('other coins keep the text as it is', () {
    expect(
      stripRelayPrefixes(bitcoin, 'https://user@host.example/'),
      'https://user@host.example/',
    );
  });
}

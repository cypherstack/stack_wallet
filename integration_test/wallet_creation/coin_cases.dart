import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/app_config.dart';
import 'package:stackwallet/wallets/crypto_currency/crypto_currency.dart';

import 'coin_matrix.dart';

export 'coin_matrix.dart' show defaultWordCounts;

List<CryptoCurrency> creationCoins() {
  final mainnet = AppConfig.coins.where(
    (coin) => coin.network == CryptoCurrencyNetwork.main,
  );
  expect(
    mainnet.map((coin) => coin.identifier).toSet(),
    {...defaultWordCounts.keys, 'bitcoinFrost'},
    reason:
        'Every configured main coin needs an explicit creation case. '
        'Bitcoin FROST requires a separate multisig suite.',
  );
  return [
    for (final id in defaultWordCounts.keys)
      mainnet.singleWhere((coin) => coin.identifier == id),
  ];
}

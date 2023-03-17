import 'package:stackwallet/utilities/enums/coin_enum.dart';

Uri getBlockExplorerTransactionUrlFor({
  required Coin coin,
  required String txid,
}) {
  switch (coin) {
    case Coin.bitcoin:
      return Uri.parse("https://chain.so/tx/BTC/$txid");
    case Coin.bitcoinTestNet:
      return Uri.parse("https://chain.so/tx/BTCTEST/$txid");
    case Coin.monero:
      return Uri.parse("https://xmrchain.net/tx/$txid");
  }
}

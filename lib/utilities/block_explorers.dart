import 'package:epicmobile/utilities/enums/coin_enum.dart';

Uri getBlockExplorerTransactionUrlFor({
  required Coin coin,
  required String txid,
}) {
  switch (coin) {
    case Coin.bitcoin:
      return Uri.parse("https://chain.so/tx/BTC/$txid");
    case Coin.litecoin:
      return Uri.parse("https://chain.so/tx/LTC/$txid");
    case Coin.litecoinTestNet:
      return Uri.parse("https://chain.so/tx/LTCTEST/$txid");
    case Coin.bitcoinTestNet:
      return Uri.parse("https://chain.so/tx/BTCTEST/$txid");
    case Coin.dogecoin:
      return Uri.parse("https://chain.so/tx/DOGE/$txid");
    case Coin.dogecoinTestNet:
      return Uri.parse("https://chain.so/tx/DOGETEST/$txid");
    case Coin.epicCash:
      // TODO: Handle this case.
      throw UnimplementedError("missing block explorer for epic cash");
    case Coin.bitcoincash:
      return Uri.parse("https://blockchair.com/bitcoin-cash/transaction/$txid");
    case Coin.bitcoincashTestnet:
      return Uri.parse(
          "https://blockexplorer.one/bitcoin-cash/testnet/tx/$txid");
    case Coin.namecoin:
      return Uri.parse("https://chainz.cryptoid.info/nmc/tx.dws?$txid.htm");
  }
}

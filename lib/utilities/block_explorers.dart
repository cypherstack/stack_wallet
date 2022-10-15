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
    case Coin.dogecoin:
      return Uri.parse("https://chain.so/tx/DOGE/$txid");
    case Coin.dogecoinTestNet:
      return Uri.parse("https://chain.so/tx/DOGETEST/$txid");
    case Coin.epicCash:
      // TODO: Handle this case.
      throw UnimplementedError("missing block explorer for epic cash");
    case Coin.monero:
      return Uri.parse("https://xmrchain.net/tx/$txid");
    case Coin.moneroTestNet:
      return Uri.parse("https://testnet.xmrchain.net/tx/$txid");
    case Coin.moneroStageNet:
      return Uri.parse("https://stagenet.xmrchain.net/tx/$txid");
    case Coin.wownero:
      return Uri.parse("https://explore.wownero.com/search?value=$txid");
    case Coin.firo:
      return Uri.parse("https://explorer.firo.org/tx/$txid");
    case Coin.firoTestNet:
      return Uri.parse("https://testexplorer.firo.org/tx/$txid");
    case Coin.bitcoincash:
      return Uri.parse("https://blockchair.com/bitcoin-cash/transaction/$txid");
    case Coin.bitcoincashTestnet:
      return Uri.parse(
          "https://blockexplorer.one/bitcoin-cash/testnet/tx/$txid");
    case Coin.namecoin:
      return Uri.parse("https://chainz.cryptoid.info/nmc/tx.dws?$txid.htm");
  }
}

import 'package:stackwallet/db/isar/main_db.dart';
import 'package:stackwallet/models/isar/models/block_explorer.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';

Uri getDefaultBlockExplorerUrlFor({
  required Coin coin,
  required String txid,
}) {
  switch (coin) {
    case Coin.bitcoin:
      return Uri.parse("https://mempool.space/tx/$txid");
    case Coin.litecoin:
      return Uri.parse("https://chain.so/tx/LTC/$txid");
    case Coin.litecoinTestNet:
      return Uri.parse("https://chain.so/tx/LTCTEST/$txid");
    case Coin.bitcoinTestNet:
      return Uri.parse("https://mempool.space/testnet/tx/$txid");
    case Coin.dogecoin:
      return Uri.parse("https://chain.so/tx/DOGE/$txid");
    case Coin.eCash:
      return Uri.parse("https://explorer.bitcoinabc.org/tx/$txid");
    case Coin.dogecoinTestNet:
      return Uri.parse("https://chain.so/tx/DOGETEST/$txid");
    case Coin.epicCash:
      // TODO: Handle this case.
      throw UnimplementedError("missing block explorer for epic cash");
    case Coin.ethereum:
      return Uri.parse("https://etherscan.io/tx/$txid");
    case Coin.monero:
      return Uri.parse("https://xmrchain.net/tx/$txid");
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
    case Coin.particl:
      return Uri.parse("https://chainz.cryptoid.info/part/tx.dws?$txid.htm");
    case Coin.nano:
      return Uri.parse("https://www.nanolooker.com/block/$txid");
  }
}

/// returns internal Isar ID for the inserted object/record
Future<int> setBlockExplorerForCoin({
  required Coin coin,
  required Uri url,
}) async {
  return await MainDB.instance.putTransactionBlockExplorer(
    TransactionBlockExplorer(
      ticker: coin.ticker,
      url: url.toString(),
    ),
  );
}

Uri getBlockExplorerTransactionUrlFor({
  required Coin coin,
  required String txid,
}) {
  String? url = MainDB.instance.getTransactionBlockExplorer(coin: coin)?.url;
  if (url == null) {
    return getDefaultBlockExplorerUrlFor(coin: coin, txid: txid);
  } else {
    url = url.replaceAll("%5BTXID%5D", txid);
    return Uri.parse(url);
  }
}

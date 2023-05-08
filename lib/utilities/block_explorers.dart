import 'dart:ffi';

import 'package:stackwallet/utilities/enums/coin_enum.dart';

import '../db/hive/db.dart';
import '../db/isar/main_db.dart';
import '../models/isar/models/block_explorer.dart';

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
  }
}

Future<int> setBlockExplorerForCoin(
    {required Coin coin, required Uri url}
    ) async {
  await MainDB.instance.putTransactionBlockExplorer(TransactionBlockExplorer(ticker: coin.ticker, url: url.toString()));
  return 0;
}

Uri getBlockExplorerTransactionUrlFor({
  required Coin coin,
  required String txid,
}) {
  var url = MainDB.instance.getTransactionBlockExplorer(coin: coin)?.url.toString();
  if (url == null) {
    return getDefaultBlockExplorerUrlFor(coin: coin, txid: txid);
  } else {
    url =  url.replaceAll("%5BTXID%5D", txid);
    return Uri.parse(url);
  }
}

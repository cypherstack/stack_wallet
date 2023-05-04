import 'dart:ffi';

import 'package:stackwallet/utilities/enums/coin_enum.dart';

import '../db/hive/db.dart';

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

int setBlockExplorerForCoin(
    {required Coin coin, required Uri url}
    ) {
  var ticker = coin.ticker;
  DB.instance.put<dynamic>(
    boxName: DB.boxNameAllWalletsData,
    key: "${ticker}blockExplorerUrl",
    value: url);
  return 0;
}

Uri getBlockExplorerTransactionUrlFor({
  required Coin coin,
  required String txid,
}) {
  var ticker = coin.ticker;
  var url = DB.instance.get<dynamic>(
    boxName: DB.boxNameAllWalletsData,
    key: "${ticker}blockExplorerUrl",
  );
  if (url == null) {
    return getDefaultBlockExplorerUrlFor(coin: coin, txid: txid);
  } else {
    url = url.replace("%5BTXID%5D", txid);
    return Uri.parse(url.toString());
  }
}

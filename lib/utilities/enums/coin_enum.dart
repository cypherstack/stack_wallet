import 'package:stackwallet/services/coins/bitcoin/bitcoin_wallet.dart' as btc;
import 'package:stackwallet/services/coins/bitcoincash/bitcoincash_wallet.dart'
    as bch;
import 'package:stackwallet/services/coins/dogecoin/dogecoin_wallet.dart'
    as doge;
import 'package:stackwallet/services/coins/epiccash/epiccash_wallet.dart'
    as epic;
import 'package:stackwallet/services/coins/firo/firo_wallet.dart' as firo;
import 'package:stackwallet/services/coins/monero/monero_wallet.dart' as xmr;
import 'package:stackwallet/services/coins/namecoin/namecoin_wallet.dart'
    as nmc;
import 'package:stackwallet/services/coins/wownero/wownero_wallet.dart' as wow;

enum Coin {
  bitcoin,
  bitcoincash,
  dogecoin,
  epicCash,
  firo,
  monero,
  wownero,
  namecoin,

  ///
  ///
  ///

  bitcoinTestNet,
  bitcoincashTestnet,
  dogecoinTestNet,
  firoTestNet,
  moneroTestNet,
  moneroStageNet
}

// remove firotestnet for now
const int kTestNetCoinCount = 5;

extension CoinExt on Coin {
  String get prettyName {
    switch (this) {
      case Coin.bitcoin:
        return "Bitcoin";
      case Coin.bitcoincash:
        return "Bitcoin Cash";
      case Coin.dogecoin:
        return "Dogecoin";
      case Coin.epicCash:
        return "Epic Cash";
      case Coin.firo:
        return "Firo";
      case Coin.monero:
        return "Monero";
      case Coin.moneroTestNet:
        return "tMonero";
      case Coin.moneroStageNet:
        return "sMonero";
      case Coin.wownero:
        return "Wownero";
      case Coin.namecoin:
        return "Namecoin";
      case Coin.bitcoinTestNet:
        return "tBitcoin";
      case Coin.bitcoincashTestnet:
        return "tBitcoin Cash";
      case Coin.firoTestNet:
        return "tFiro";
      case Coin.dogecoinTestNet:
        return "tDogecoin";
    }
  }

  String get ticker {
    switch (this) {
      case Coin.bitcoin:
        return "BTC";
      case Coin.bitcoincash:
        return "BCH";
      case Coin.dogecoin:
        return "DOGE";
      case Coin.epicCash:
        return "EPIC";
      case Coin.firo:
        return "FIRO";
      case Coin.monero:
        return "XMR";
      case Coin.moneroTestNet:
        return "tXMR";
      case Coin.moneroStageNet:
        return "sXMR";
      case Coin.wownero:
        return "WOW";
      case Coin.namecoin:
        return "NMC";
      case Coin.bitcoinTestNet:
        return "tBTC";
      case Coin.bitcoincashTestnet:
        return "tBCH";
      case Coin.firoTestNet:
        return "tFIRO";
      case Coin.dogecoinTestNet:
        return "tDOGE";
    }
  }

  String get uriScheme {
    switch (this) {
      case Coin.bitcoin:
        return "bitcoin";
      case Coin.bitcoincash:
        return "bitcoincash";
      case Coin.dogecoin:
        return "dogecoin";
      case Coin.epicCash:
        // TODO: is this actually the right one?
        return "epic";
      case Coin.firo:
        return "firo";
      case Coin.monero:
      case Coin.moneroTestNet:
      case Coin.moneroStageNet:
        return "monero";
      case Coin.wownero:
        return "wownero";
      case Coin.namecoin:
        return "namecoin";
      case Coin.bitcoinTestNet:
        return "bitcoin";
      case Coin.bitcoincashTestnet:
        return "bitcoincash";
      case Coin.firoTestNet:
        return "firo";
      case Coin.dogecoinTestNet:
        return "dogecoin";
    }
  }

  bool get isElectrumXCoin {
    switch (this) {
      case Coin.bitcoin:
      case Coin.bitcoincash:
      case Coin.dogecoin:
      case Coin.firo:
      case Coin.namecoin:
      case Coin.bitcoinTestNet:
      case Coin.bitcoincashTestnet:
      case Coin.firoTestNet:
      case Coin.dogecoinTestNet:
        return true;

      case Coin.epicCash:
      case Coin.monero:
      case Coin.moneroTestNet:
      case Coin.moneroStageNet:
      case Coin.wownero:
        return false;
    }
  }

  int get requiredConfirmations {
    switch (this) {
      case Coin.bitcoin:
      case Coin.bitcoinTestNet:
        return btc.MINIMUM_CONFIRMATIONS;

      case Coin.bitcoincash:
      case Coin.bitcoincashTestnet:
        return bch.MINIMUM_CONFIRMATIONS;

      case Coin.firo:
      case Coin.firoTestNet:
        return firo.MINIMUM_CONFIRMATIONS;

      case Coin.dogecoin:
      case Coin.dogecoinTestNet:
        return doge.MINIMUM_CONFIRMATIONS;

      case Coin.epicCash:
        return epic.MINIMUM_CONFIRMATIONS;

      case Coin.monero:
      case Coin.moneroTestNet:
      case Coin.moneroStageNet:
        return xmr.MINIMUM_CONFIRMATIONS;

      case Coin.wownero:
        return wow.MINIMUM_CONFIRMATIONS;

      case Coin.namecoin:
        return nmc.MINIMUM_CONFIRMATIONS;
    }
  }
}

Coin coinFromPrettyName(String name) {
  switch (name) {
    case "Bitcoin":
    case "bitcoin":
      return Coin.bitcoin;
    case "Bitcoincash":
    case "bitcoincash":
    case "Bitcoin Cash":
      return Coin.bitcoincash;
    case "Dogecoin":
    case "dogecoin":
      return Coin.dogecoin;
    case "Epic Cash":
    case "epicCash":
      return Coin.epicCash;
    case "Firo":
    case "firo":
      return Coin.firo;
    case "Monero":
    case "monero":
      return Coin.monero;
    case "Monero Testnet":
    case "monero testnet":
    case "moneroTestNet":
    case "tMonero":
    case "tmonero":
      return Coin.moneroTestNet;
    case "Monero Stagenet":
    case "monero stagenet":
    case "moneroStageNet":
    case "sMonero":
    case "smonero":
      return Coin.moneroStageNet;
    case "Wownero":
    case "tWownero":
    case "wownero":
      return Coin.wownero;
    case "Namecoin":
    case "namecoin":
      return Coin.namecoin;
    case "Bitcoin Testnet":
    case "tBitcoin":
    case "bitcoinTestNet":
      return Coin.bitcoinTestNet;
    case "Bitcoincash Testnet":
    case "tBitcoin Cash":
    case "Bitcoin Cash Testnet":
      return Coin.bitcoincashTestnet;
    case "Firo Testnet":
    case "tFiro":
    case "firoTestNet":
      return Coin.firoTestNet;
    case "Dogecoin Testnet":
    case "tDogecoin":
    case "dogecoinTestNet":
      return Coin.dogecoinTestNet;
    default:
      throw ArgumentError.value(
          name, "name", "No Coin enum value with that prettyName");
  }
}

Coin coinFromTickerCaseInsensitive(String ticker) {
  switch (ticker.toLowerCase()) {
    case "btc":
      return Coin.bitcoin;
    case "bch":
      return Coin.bitcoincash;
    case "doge":
      return Coin.dogecoin;
    case "epic":
      return Coin.epicCash;
    case "firo":
      return Coin.firo;
    case "xmr":
      return Coin.monero;
    case "txmr":
      return Coin.moneroTestNet;
    case "sxmr":
      return Coin.moneroStageNet;
    case "wow":
      return Coin.wownero;
    case "nmc":
      return Coin.namecoin;
    case "tbtc":
      return Coin.bitcoinTestNet;
    case "tbch":
      return Coin.bitcoincashTestnet;
    case "tfiro":
      return Coin.firoTestNet;
    case "tdoge":
      return Coin.dogecoinTestNet;
    default:
      throw ArgumentError.value(
          ticker, "name", "No Coin enum value with that ticker");
  }
}

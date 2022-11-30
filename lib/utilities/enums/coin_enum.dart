import 'package:epicmobile/services/coins/bitcoin/bitcoin_wallet.dart' as btc;
import 'package:epicmobile/services/coins/bitcoincash/bitcoincash_wallet.dart'
    as bch;
import 'package:epicmobile/services/coins/dogecoin/dogecoin_wallet.dart'
    as doge;
import 'package:epicmobile/services/coins/epiccash/epiccash_wallet.dart'
    as epic;
import 'package:epicmobile/services/coins/litecoin/litecoin_wallet.dart' as ltc;
import 'package:epicmobile/services/coins/namecoin/namecoin_wallet.dart' as nmc;

enum Coin {
  bitcoin,
  bitcoincash,
  dogecoin,
  epicCash,
  litecoin,
  namecoin,

  ///

  ///
  ///

  bitcoinTestNet,
  litecoinTestNet,
  bitcoincashTestnet,
  dogecoinTestNet,
}

// remove firotestnet for now
const int kTestNetCoinCount = 4;

extension CoinExt on Coin {
  String get prettyName {
    switch (this) {
      case Coin.bitcoin:
        return "Bitcoin";
      case Coin.litecoin:
        return "Litecoin";
      case Coin.bitcoincash:
        return "Bitcoin Cash";
      case Coin.dogecoin:
        return "Dogecoin";
      case Coin.epicCash:
        return "Epic Cash";
      case Coin.namecoin:
        return "Namecoin";
      case Coin.bitcoinTestNet:
        return "tBitcoin";
      case Coin.litecoinTestNet:
        return "tLitecoin";
      case Coin.bitcoincashTestnet:
        return "tBitcoin Cash";
      case Coin.dogecoinTestNet:
        return "tDogecoin";
    }
  }

  String get ticker {
    switch (this) {
      case Coin.bitcoin:
        return "BTC";
      case Coin.litecoin:
        return "LTC";
      case Coin.bitcoincash:
        return "BCH";
      case Coin.dogecoin:
        return "DOGE";
      case Coin.epicCash:
        return "EPIC";
      case Coin.namecoin:
        return "NMC";
      case Coin.bitcoinTestNet:
        return "tBTC";
      case Coin.litecoinTestNet:
        return "tLTC";
      case Coin.bitcoincashTestnet:
        return "tBCH";
      case Coin.dogecoinTestNet:
        return "tDOGE";
    }
  }

  String get uriScheme {
    switch (this) {
      case Coin.bitcoin:
        return "bitcoin";
      case Coin.litecoin:
        return "litecoin";
      case Coin.bitcoincash:
        return "bitcoincash";
      case Coin.dogecoin:
        return "dogecoin";
      case Coin.epicCash:
        // TODO: is this actually the right one?
        return "epic";
      case Coin.namecoin:
        return "namecoin";
      case Coin.bitcoinTestNet:
        return "bitcoin";
      case Coin.litecoinTestNet:
        return "litecoin";
      case Coin.bitcoincashTestnet:
        return "bchtest";
      case Coin.dogecoinTestNet:
        return "dogecoin";
    }
  }

  bool get isElectrumXCoin {
    switch (this) {
      case Coin.bitcoin:
      case Coin.litecoin:
      case Coin.bitcoincash:
      case Coin.dogecoin:
      case Coin.namecoin:
      case Coin.bitcoinTestNet:
      case Coin.litecoinTestNet:
      case Coin.bitcoincashTestnet:
      case Coin.dogecoinTestNet:
        return true;

      case Coin.epicCash:
        return false;
    }
  }

  int get requiredConfirmations {
    switch (this) {
      case Coin.bitcoin:
      case Coin.bitcoinTestNet:
        return btc.MINIMUM_CONFIRMATIONS;

      case Coin.litecoin:
      case Coin.litecoinTestNet:
        return ltc.MINIMUM_CONFIRMATIONS;

      case Coin.bitcoincash:
      case Coin.bitcoincashTestnet:
        return bch.MINIMUM_CONFIRMATIONS;

      case Coin.dogecoin:
      case Coin.dogecoinTestNet:
        return doge.MINIMUM_CONFIRMATIONS;

      case Coin.epicCash:
        return epic.MINIMUM_CONFIRMATIONS;

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

    case "Litecoin":
    case "litecoin":
      return Coin.litecoin;

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

    case "Namecoin":
    case "namecoin":
      return Coin.namecoin;

    case "Bitcoin Testnet":
    case "tBitcoin":
    case "bitcoinTestNet":
      return Coin.bitcoinTestNet;

    case "Litecoin Testnet":
    case "tlitecoin":
    case "litecoinTestNet":
    case "tLitecoin":
      return Coin.litecoinTestNet;

    case "Bitcoincash Testnet":
    case "tBitcoin Cash":
    case "Bitcoin Cash Testnet":
    case "bitcoincashTestnet":
      return Coin.bitcoincashTestnet;

    case "Dogecoin Testnet":
    case "tDogecoin":
    case "dogecoinTestNet":
      return Coin.dogecoinTestNet;

    default:
      throw ArgumentError.value(
        name,
        "name",
        "No Coin enum value with that prettyName",
      );
  }
}

Coin coinFromTickerCaseInsensitive(String ticker) {
  switch (ticker.toLowerCase()) {
    case "btc":
      return Coin.bitcoin;
    case "ltc":
      return Coin.litecoin;
    case "bch":
      return Coin.bitcoincash;
    case "doge":
      return Coin.dogecoin;
    case "epic":
      return Coin.epicCash;
    case "nmc":
      return Coin.namecoin;
    case "tltc":
      return Coin.litecoinTestNet;
    case "tbtc":
      return Coin.bitcoinTestNet;
    case "tbch":
      return Coin.bitcoincashTestnet;
    case "tdoge":
      return Coin.dogecoinTestNet;
    default:
      throw ArgumentError.value(
          ticker, "name", "No Coin enum value with that ticker");
  }
}

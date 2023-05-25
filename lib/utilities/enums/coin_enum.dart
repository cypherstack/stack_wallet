import 'package:stackwallet/services/coins/bitcoin/bitcoin_wallet.dart' as btc;
import 'package:stackwallet/services/coins/bitcoincash/bitcoincash_wallet.dart'
    as bch;
import 'package:stackwallet/services/coins/dogecoin/dogecoin_wallet.dart'
    as doge;
import 'package:stackwallet/services/coins/ecash/ecash_wallet.dart' as ecash;
import 'package:stackwallet/services/coins/epiccash/epiccash_wallet.dart'
    as epic;
import 'package:stackwallet/services/coins/ethereum/ethereum_wallet.dart'
    as eth;
import 'package:stackwallet/services/coins/firo/firo_wallet.dart' as firo;
import 'package:stackwallet/services/coins/litecoin/litecoin_wallet.dart'
    as ltc;
import 'package:stackwallet/services/coins/monero/monero_wallet.dart' as xmr;
import 'package:stackwallet/services/coins/namecoin/namecoin_wallet.dart'
    as nmc;
import 'package:stackwallet/services/coins/particl/particl_wallet.dart'
    as particl;
import 'package:stackwallet/services/coins/wownero/wownero_wallet.dart' as wow;
import 'package:stackwallet/utilities/constants.dart';

enum Coin {
  bitcoin,
  bitcoincash,
  dogecoin,
  eCash,
  epicCash,
  ethereum,
  firo,
  litecoin,
  monero,
  namecoin,
  particl,
  wownero,

  ///

  ///
  ///

  bitcoinTestNet,
  litecoinTestNet,
  bitcoincashTestnet,
  dogecoinTestNet,
  firoTestNet,
}

final int kTestNetCoinCount = 4; // Util.isDesktop ? 5 : 4;
// remove firotestnet for now

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
      case Coin.eCash:
        return "eCash";
      case Coin.ethereum:
        return "Ethereum";
      case Coin.firo:
        return "Firo";
      case Coin.monero:
        return "Monero";
      case Coin.particl:
        return "Particl";
      case Coin.wownero:
        return "Wownero";
      case Coin.namecoin:
        return "Namecoin";
      case Coin.bitcoinTestNet:
        return "tBitcoin";
      case Coin.litecoinTestNet:
        return "tLitecoin";
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
      case Coin.litecoin:
        return "LTC";
      case Coin.bitcoincash:
        return "BCH";
      case Coin.dogecoin:
        return "DOGE";
      case Coin.epicCash:
        return "EPIC";
      case Coin.ethereum:
        return "ETH";
      case Coin.eCash:
        return "XEC";
      case Coin.firo:
        return "FIRO";
      case Coin.monero:
        return "XMR";
      case Coin.particl:
        return "PART";
      case Coin.wownero:
        return "WOW";
      case Coin.namecoin:
        return "NMC";
      case Coin.bitcoinTestNet:
        return "tBTC";
      case Coin.litecoinTestNet:
        return "tLTC";
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
      case Coin.litecoin:
        return "litecoin";
      case Coin.bitcoincash:
        return "bitcoincash";
      case Coin.dogecoin:
        return "dogecoin";
      case Coin.epicCash:
        // TODO: is this actually the right one?
        return "epic";
      case Coin.ethereum:
        return "ethereum";
      case Coin.eCash:
        return "ecash";
      case Coin.firo:
        return "firo";
      case Coin.monero:
        return "monero";
      case Coin.particl:
        return "particl";
      case Coin.wownero:
        return "wownero";
      case Coin.namecoin:
        return "namecoin";
      case Coin.bitcoinTestNet:
        return "bitcoin";
      case Coin.litecoinTestNet:
        return "litecoin";
      case Coin.bitcoincashTestnet:
        return "bchtest";
      case Coin.firoTestNet:
        return "firo";
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
      case Coin.firo:
      case Coin.namecoin:
      case Coin.particl:
      case Coin.bitcoinTestNet:
      case Coin.litecoinTestNet:
      case Coin.bitcoincashTestnet:
      case Coin.firoTestNet:
      case Coin.dogecoinTestNet:
      case Coin.eCash:
        return true;

      case Coin.epicCash:
      case Coin.ethereum:
      case Coin.monero:
      case Coin.wownero:
        return false;
    }
  }

  bool get hasBuySupport {
    switch (this) {
      case Coin.bitcoin:
      case Coin.litecoin:
      case Coin.bitcoincash:
      case Coin.dogecoin:
      case Coin.ethereum:
        return true;

      case Coin.firo:
      case Coin.namecoin:
      case Coin.particl:
      case Coin.eCash:
      case Coin.epicCash:
      case Coin.monero:
      case Coin.wownero:
      case Coin.dogecoinTestNet:
      case Coin.bitcoinTestNet:
      case Coin.litecoinTestNet:
      case Coin.bitcoincashTestnet:
      case Coin.firoTestNet:
        return false;
    }
  }

  bool get isTestNet {
    switch (this) {
      case Coin.bitcoin:
      case Coin.litecoin:
      case Coin.bitcoincash:
      case Coin.dogecoin:
      case Coin.firo:
      case Coin.namecoin:
      case Coin.particl:
      case Coin.epicCash:
      case Coin.ethereum:
      case Coin.monero:
      case Coin.wownero:
      case Coin.eCash:
        return false;

      case Coin.dogecoinTestNet:
      case Coin.bitcoinTestNet:
      case Coin.litecoinTestNet:
      case Coin.bitcoincashTestnet:
      case Coin.firoTestNet:
        return true;
    }
  }

  Coin get mainNetVersion {
    switch (this) {
      case Coin.bitcoin:
      case Coin.litecoin:
      case Coin.bitcoincash:
      case Coin.dogecoin:
      case Coin.firo:
      case Coin.namecoin:
      case Coin.particl:
      case Coin.epicCash:
      case Coin.ethereum:
      case Coin.monero:
      case Coin.wownero:
      case Coin.eCash:
        return this;

      case Coin.dogecoinTestNet:
        return Coin.dogecoin;

      case Coin.bitcoinTestNet:
        return Coin.bitcoin;

      case Coin.litecoinTestNet:
        return Coin.litecoin;

      case Coin.bitcoincashTestnet:
        return Coin.bitcoincash;

      case Coin.firoTestNet:
        return Coin.firo;
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

      case Coin.firo:
      case Coin.firoTestNet:
        return firo.MINIMUM_CONFIRMATIONS;

      case Coin.dogecoin:
      case Coin.dogecoinTestNet:
        return doge.MINIMUM_CONFIRMATIONS;

      case Coin.epicCash:
        return epic.MINIMUM_CONFIRMATIONS;

      case Coin.eCash:
        return ecash.MINIMUM_CONFIRMATIONS;

      case Coin.ethereum:
        return eth.MINIMUM_CONFIRMATIONS;

      case Coin.monero:
        return xmr.MINIMUM_CONFIRMATIONS;

      case Coin.particl:
        return particl.MINIMUM_CONFIRMATIONS;

      case Coin.wownero:
        return wow.MINIMUM_CONFIRMATIONS;

      case Coin.namecoin:
        return nmc.MINIMUM_CONFIRMATIONS;
    }
  }

  int get decimals => Constants.decimalPlacesForCoin(this);
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

    case "Ethereum":
    case "ethereum":
      return Coin.ethereum;

    case "Firo":
    case "firo":
      return Coin.firo;

    case "E-Cash":
    case "ecash":
    case "eCash":
      return Coin.eCash;

    case "Monero":
    case "monero":
      return Coin.monero;

    case "Particl":
    case "particl":
      return Coin.particl;

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

    case "Firo Testnet":
    case "tFiro":
    case "firoTestNet":
      return Coin.firoTestNet;

    case "Dogecoin Testnet":
    case "tDogecoin":
    case "dogecoinTestNet":
      return Coin.dogecoinTestNet;

    case "Wownero":
    case "tWownero":
    case "wownero":
      return Coin.wownero;

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
    case "xec":
      return Coin.eCash;
    case "eth":
      return Coin.ethereum;
    case "firo":
      return Coin.firo;
    case "xmr":
      return Coin.monero;
    case "nmc":
      return Coin.namecoin;
    case "part":
      return Coin.particl;
    case "tltc":
      return Coin.litecoinTestNet;
    case "tbtc":
      return Coin.bitcoinTestNet;
    case "tbch":
      return Coin.bitcoincashTestnet;
    case "tfiro":
      return Coin.firoTestNet;
    case "tdoge":
      return Coin.dogecoinTestNet;
    case "wow":
      return Coin.wownero;
    default:
      throw ArgumentError.value(
          ticker, "name", "No Coin enum value with that ticker");
  }
}

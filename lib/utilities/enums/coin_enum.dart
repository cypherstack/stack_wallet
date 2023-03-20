import 'package:stackwallet/services/coins/bitcoin/bitcoin_wallet.dart' as btc;
import 'package:stackwallet/services/coins/monero/monero_wallet.dart' as xmr;
import 'package:stackwallet/utilities/constants.dart';

enum Coin {
  bitcoin,
  monero,

  ///

  ///
  ///
  bitcoinTestNet,
}

final int kTestNetCoinCount = 1; // Util.isDesktop ? 5 : 4;

extension CoinExt on Coin {
  String get prettyName {
    switch (this) {
      case Coin.bitcoin:
        return "Bitcoin";
      case Coin.monero:
        return "Monero";
      case Coin.bitcoinTestNet:
        return "tBitcoin";
    }
  }

  String get ticker {
    switch (this) {
      case Coin.bitcoin:
        return "BTC";
      case Coin.monero:
        return "XMR";
      case Coin.bitcoinTestNet:
        return "tBTC";
    }
  }

  String get uriScheme {
    switch (this) {
      case Coin.bitcoin:
        return "bitcoin";
      case Coin.monero:
        return "monero";
      case Coin.bitcoinTestNet:
        return "bitcoin";
    }
  }

  bool get isElectrumXCoin {
    switch (this) {
      case Coin.bitcoin:
      case Coin.bitcoinTestNet:
        return true;

      case Coin.monero:
        return false;
    }
  }

  bool get hasBuySupport {
    switch (this) {
      case Coin.bitcoin:
        return true;

      case Coin.monero:
      case Coin.bitcoinTestNet:
        return false;
    }
  }

  bool get isTestNet {
    switch (this) {
      case Coin.bitcoin:
      case Coin.monero:
        return false;

      case Coin.bitcoinTestNet:
        return true;
    }
  }

  Coin get mainNetVersion {
    switch (this) {
      case Coin.bitcoin:
      case Coin.monero:
        return this;

      case Coin.bitcoinTestNet:
        return Coin.bitcoin;
    }
  }

  int get requiredConfirmations {
    switch (this) {
      case Coin.bitcoin:
      case Coin.bitcoinTestNet:
        return btc.MINIMUM_CONFIRMATIONS;

      case Coin.monero:
        return xmr.MINIMUM_CONFIRMATIONS;
    }
  }

  int get decimals => Constants.decimalPlacesForCoin(this);
}

Coin coinFromPrettyName(String name) {
  switch (name) {
    case "Bitcoin":
    case "bitcoin":
      return Coin.bitcoin;

    case "Monero":
    case "monero":
      return Coin.monero;

    case "Bitcoin Testnet":
    case "tBitcoin":
    case "bitcoinTestNet":
      return Coin.bitcoinTestNet;

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
    case "xmr":
      return Coin.monero;
    case "tbtc":
      return Coin.bitcoinTestNet;
    default:
      throw ArgumentError.value(
          ticker, "name", "No Coin enum value with that ticker");
  }
}

import 'package:epicmobile/services/coins/epiccash/epiccash_wallet.dart'
    as epic;

enum Coin {
  epicCash,
}

// remove firotestnet for now
const int kTestNetCoinCount = 0;

extension CoinExt on Coin {
  String get prettyName {
    switch (this) {
      case Coin.epicCash:
        return "Epic Cash";
    }
  }

  String get ticker {
    switch (this) {
      case Coin.epicCash:
        return "EPIC";
    }
  }

  String get uriScheme {
    switch (this) {
      case Coin.epicCash:
        // TODO: is this actually the right one?
        return "epic";
    }
  }

  bool get isElectrumXCoin {
    switch (this) {
      case Coin.epicCash:
        return false;
    }
  }

  int get requiredConfirmations {
    switch (this) {
      case Coin.epicCash:
        return epic.MINIMUM_CONFIRMATIONS;
    }
  }
}

Coin coinFromPrettyName(String name) {
  switch (name) {
    case "Epic Cash":
    case "epicCash":
      return Coin.epicCash;

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
    case "epic":
      return Coin.epicCash;

    default:
      throw ArgumentError.value(
          ticker, "name", "No Coin enum value with that ticker");
  }
}

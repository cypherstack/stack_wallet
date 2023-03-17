import 'dart:io';

import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/utilities/util.dart';

class _LayoutSizing {
  const _LayoutSizing();

  double get circularBorderRadius => 8.0;
  double get checkboxBorderRadius => 4.0;

  double get standardPadding => 16.0;
}

abstract class Constants {
  static const size = _LayoutSizing();

  static void exchangeForExperiencedUsers(int count) {
    enableExchange =
        Util.isDesktop || Platform.isAndroid || count > 5 || !Platform.isIOS;
  }

  static bool enableExchange = Util.isDesktop || !Platform.isIOS;
  // just use enable exchange flag
  // static bool enableBuy = enableExchange;
  // // true; // true for development,

  //TODO: correct for monero?
  static const int _satsPerCoinMonero = 1000000000000;
  static const int _satsPerCoin = 100000000;
  static const int _decimalPlaces = 8;
  static const int _decimalPlacesWownero = 11;
  static const int _decimalPlacesMonero = 12;

  static const int notificationsMax = 0xFFFFFFFF;
  static const Duration networkAliveTimerDuration = Duration(seconds: 10);

  static const int pinLength = 4;

  // Enable Logger.print statements
  static const bool disableLogger = false;

  static const int currentHiveDbVersion = 5;

  static const int rescanV1 = 1;

  static int satsPerCoin(Coin coin) {
    switch (coin) {
      case Coin.bitcoin:
      case Coin.bitcoinTestNet:
        return _satsPerCoin;

      case Coin.monero:
        return _satsPerCoinMonero;
    }
  }

  static int decimalPlacesForCoin(Coin coin) {
    switch (coin) {
      case Coin.bitcoin:
      case Coin.bitcoinTestNet:
        return _decimalPlaces;

      case Coin.monero:
        return _decimalPlacesMonero;
    }
  }

  static List<int> possibleLengthsForCoin(Coin coin) {
    final List<int> values = [];
    switch (coin) {
      case Coin.bitcoin:
      case Coin.bitcoinTestNet:
        values.addAll([24, 21, 18, 15, 12]);
        break;

      case Coin.monero:
        values.addAll([25]);
        break;
    }
    return values;
  }

  static int targetBlockTimeInSeconds(Coin coin) {
    // TODO verify values
    switch (coin) {
      case Coin.bitcoin:
      case Coin.bitcoinTestNet:
        return 600;

      case Coin.monero:
        return 120;
    }
  }

  static const int seedPhraseWordCountBip39 = 24;
  static const int seedPhraseWordCountMonero = 25;

  static const Map<int, String> monthMapShort = {
    1: 'Jan',
    2: 'Feb',
    3: 'Mar',
    4: 'Apr',
    5: 'May',
    6: 'Jun',
    7: 'Jul',
    8: 'Aug',
    9: 'Sep',
    10: 'Oct',
    11: 'Nov',
    12: 'Dec',
  };

  static const Map<int, String> monthMap = {
    1: 'January',
    2: 'February',
    3: 'March',
    4: 'April',
    5: 'May',
    6: 'June',
    7: 'July',
    8: 'August',
    9: 'September',
    10: 'October',
    11: 'November',
    12: 'December',
  };
}

import 'package:flutter/material.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';

const kCoinThemeColorDefaults = CoinThemeColorDefault();

class CoinThemeColorDefault {
  const CoinThemeColorDefault();

  Color get bitcoin => const Color(0xFFFCC17B);
  Color get litecoin => const Color(0xFF7FA6E1);
  Color get bitcoincash => const Color(0xFF7BCFB8);
  Color get firo => const Color(0xFFFF897A);
  Color get dogecoin => const Color(0xFFFFE079);
  Color get epicCash => const Color(0xFFC5C7CB);
  Color get eCash => const Color(0xFFC5C7CB);
  Color get ethereum => const Color(0xFFA7ADE9);
  Color get monero => const Color(0xFFFF9E6B);
  Color get namecoin => const Color(0xFF91B1E1);
  Color get wownero => const Color(0xFFED80C1);
  Color get particl => const Color(0xFF8175BD);

  Color forCoin(Coin coin) {
    switch (coin) {
      case Coin.bitcoin:
      case Coin.bitcoinTestNet:
        return bitcoin;
      case Coin.litecoin:
      case Coin.litecoinTestNet:
        return litecoin;
      case Coin.bitcoincash:
      case Coin.bitcoincashTestnet:
        return bitcoincash;
      case Coin.dogecoin:
      case Coin.dogecoinTestNet:
        return dogecoin;
      case Coin.eCash:
        return eCash;
      case Coin.epicCash:
        return epicCash;
      case Coin.ethereum:
        return ethereum;
      case Coin.firo:
      case Coin.firoTestNet:
        return firo;
      case Coin.monero:
        return monero;
      case Coin.namecoin:
        return namecoin;
      case Coin.wownero:
        return wownero;
      case Coin.particl:
        return particl;
    }
  }
}

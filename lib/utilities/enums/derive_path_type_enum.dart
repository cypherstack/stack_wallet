import 'package:stackwallet/utilities/enums/coin_enum.dart';

enum DerivePathType {
  bip44,
  bch44,
  bip49,
  bip84,
}

extension DerivePathTypeExt on DerivePathType {
  static DerivePathType primaryFor(Coin coin) {
    switch (coin) {
      case Coin.bitcoincash:
      case Coin.bitcoincashTestnet:
      case Coin.dogecoin:
      case Coin.dogecoinTestNet:
      case Coin.firo:
      case Coin.firoTestNet:
        return DerivePathType.bip44;

      case Coin.bitcoin:
      case Coin.bitcoinTestNet:
      case Coin.litecoin:
      case Coin.litecoinTestNet:
      case Coin.namecoin:
      case Coin.particl:
        return DerivePathType.bip84;

      case Coin.epicCash:
      case Coin.monero:
      case Coin.wownero:
        throw UnsupportedError(
            "$coin does not use bitcoin style derivation paths");
    }
  }
}

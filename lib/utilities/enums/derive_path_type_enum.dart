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
      case Coin.bitcoin:
      case Coin.bitcoinTestNet:
        return DerivePathType.bip84;

      case Coin.monero:
        throw UnsupportedError(
            "$coin does not use bitcoin style derivation paths");
    }
  }
}

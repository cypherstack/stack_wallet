import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stackwallet/themes/theme_providers.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';

final coinImageProvider = Provider.family<String, Coin>((ref, coin) {
  final assets = ref.watch(themeProvider).assets;
  switch (coin) {
    case Coin.bitcoin:
      return assets.bitcoinImage;
    case Coin.litecoin:
    case Coin.litecoinTestNet:
      return assets.litecoinImage;
    case Coin.bitcoincash:
      return assets.bitcoincashImage;
    case Coin.dogecoin:
      return assets.dogecoinImage;
    case Coin.eCash:
      return assets.eCashImage!;
    case Coin.epicCash:
      return assets.epicCashImage;
    case Coin.firo:
      return assets.firoImage;
    case Coin.monero:
      return assets.moneroImage;
    case Coin.wownero:
      return assets.wowneroImage;
    case Coin.namecoin:
      return assets.namecoinImage;
    case Coin.particl:
      return assets.particlImage;
    case Coin.bitcoinTestNet:
      return assets.bitcoinImage;
    case Coin.bitcoincashTestnet:
      return assets.bitcoincashImage;
    case Coin.firoTestNet:
      return assets.firoImage;
    case Coin.dogecoinTestNet:
      return assets.dogecoinImage;
    case Coin.ethereum:
      return assets.ethereumImage;
  }
});

final coinImageSecondaryProvider = Provider.family<String, Coin>((ref, coin) {
  final assets = ref.watch(themeProvider).assets;
  switch (coin) {
    case Coin.bitcoin:
      return assets.bitcoinImageSecondary;
    case Coin.litecoin:
    case Coin.litecoinTestNet:
      return assets.litecoinImageSecondary;
    case Coin.bitcoincash:
      return assets.bitcoincashImageSecondary;
    case Coin.dogecoin:
      return assets.dogecoinImageSecondary;
    case Coin.eCash:
      return assets.eCashImageSecondary!;
    case Coin.epicCash:
      return assets.epicCashImageSecondary;
    case Coin.firo:
      return assets.firoImageSecondary;
    case Coin.monero:
      return assets.moneroImageSecondary;
    case Coin.wownero:
      return assets.wowneroImageSecondary;
    case Coin.namecoin:
      return assets.namecoinImageSecondary;
    case Coin.particl:
      return assets.particlImageSecondary;
    case Coin.bitcoinTestNet:
      return assets.bitcoinImageSecondary;
    case Coin.bitcoincashTestnet:
      return assets.bitcoincashImageSecondary;
    case Coin.firoTestNet:
      return assets.firoImageSecondary;
    case Coin.dogecoinTestNet:
      return assets.dogecoinImageSecondary;
    case Coin.ethereum:
      return assets.ethereumImageSecondary;
  }
});

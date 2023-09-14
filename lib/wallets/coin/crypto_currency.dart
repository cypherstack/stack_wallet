import 'package:stackwallet/utilities/enums/coin_enum.dart';

enum CryptoCurrencyNetwork {
  main,
  test,
  stage;
}

abstract class CryptoCurrency {
  @Deprecated("Should eventually move away from Coin enum")
  late final Coin coin;

  final CryptoCurrencyNetwork network;

  CryptoCurrency(this.network);
}

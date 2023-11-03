import 'package:stackwallet/utilities/constants.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';

enum CryptoCurrencyNetwork {
  main,
  test,
  stage;
}

abstract class CryptoCurrency {
  @Deprecated("[prio=low] Should eventually move away from Coin enum")
  late final Coin coin;

  final CryptoCurrencyNetwork network;

  CryptoCurrency(this.network);

  // override in subclass if the currency has tokens on it's network
  // (used for eth currently)
  bool get hasTokenSupport => false;

  // TODO: [prio=low] require these be overridden in concrete implementations to remove reliance on [coin]
  int get fractionDigits => coin.decimals;
  BigInt get satsPerCoin => Constants.satsPerCoin(coin);

  int get minConfirms;

  // TODO: [prio=low] could be handled differently as (at least) epiccash does not use this
  String get genesisHash;

  bool validateAddress(String address);
}

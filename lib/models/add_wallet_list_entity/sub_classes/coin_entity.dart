import 'package:stackwallet/models/add_wallet_list_entity/add_wallet_list_entity.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';

class CoinEntity extends AddWalletListEntity {
  CoinEntity(this._coin);

  final Coin _coin;

  @override
  Coin get coin => _coin;

  @override
  String get name => coin.prettyName;

  @override
  String get ticker => coin.ticker;

  @override
  List<Object?> get props => [coin, name, ticker];
}

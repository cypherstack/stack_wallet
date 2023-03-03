import 'package:stackwallet/models/add_wallet_list_entity/add_wallet_list_entity.dart';
import 'package:stackwallet/models/isar/models/ethereum/eth_contract.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';

class EthTokenEntity extends AddWalletListEntity {
  EthTokenEntity(this.token);

  final EthContract token;

  @override
  Coin get coin => Coin.ethereum;

  @override
  String get name => token.name;

  @override
  String get ticker => token.symbol;

  @override
  List<Object?> get props => [coin, name, ticker, token.address];
}

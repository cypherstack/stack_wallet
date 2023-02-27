import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:stackwallet/models/ethereum/eth_token.dart';
import 'package:stackwallet/pages/add_wallet_views/add_wallet_view/sub_widgets/coin_select_item.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';

class MobileCoinList extends StatelessWidget {
  const MobileCoinList({
    Key? key,
    required this.entities,
  }) : super(key: key);

  final List<AddWalletListEntity> entities;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      itemCount: entities.length,
      primary: false,
      itemBuilder: (ctx, index) {
        return Padding(
          padding: const EdgeInsets.all(4),
          child: CoinSelectItem(
            entity: entities[index],
          ),
        );
      },
    );
  }
}

abstract class AddWalletListEntity extends Equatable {
  Coin get coin;
  String get name;
  String get ticker;
}

class EthTokenEntity extends AddWalletListEntity {
  EthTokenEntity(this.token);

  final EthToken token;

  @override
  Coin get coin => Coin.ethereum;

  @override
  String get name => token.name;

  @override
  String get ticker => token.symbol;

  @override
  List<Object?> get props => [coin, name, ticker, token.contractAddress];
}

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

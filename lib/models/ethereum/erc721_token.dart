import 'package:stackwallet/models/ethereum/eth_token.dart';

class Erc721Token extends EthToken {
  Erc721Token({
    required super.contractAddress,
    required super.name,
    required super.symbol,
    required super.decimals,
    required super.balance,
  });
}

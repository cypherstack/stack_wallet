import 'package:stackwallet/models/ethereum/eth_token.dart';

class Erc20Token extends EthToken {
  Erc20Token({
    required super.contractAddress,
    required super.name,
    required super.symbol,
    required super.decimals,
    required super.balance,
  });
}

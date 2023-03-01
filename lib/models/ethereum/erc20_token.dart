import 'package:stackwallet/models/ethereum/eth_token.dart';

class Erc20ContractInfo extends EthContractInfo {
  const Erc20ContractInfo({
    required super.contractAddress,
    required super.name,
    required super.symbol,
    required super.decimals,
  });
}

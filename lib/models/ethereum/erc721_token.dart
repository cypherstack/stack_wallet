import 'package:stackwallet/models/ethereum/eth_token.dart';

class Erc721ContractInfo extends EthContractInfo {
  const Erc721ContractInfo({
    required super.contractAddress,
    required super.name,
    required super.symbol,
    required super.decimals,
  });
}

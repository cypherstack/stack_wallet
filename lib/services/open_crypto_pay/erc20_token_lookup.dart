import '../../db/isar/main_db.dart';
import '../../models/isar/models/ethereum/eth_contract.dart';

class OpenCryptoPayErc20TokenLookup {
  const OpenCryptoPayErc20TokenLookup._();

  static List<EthContract> enabledTokens(
    MainDB mainDB,
    Iterable<String> addresses,
  ) {
    return addresses
        .map(mainDB.getEthContractSync)
        .whereType<EthContract>()
        .where((e) => e.type == EthContractType.erc20)
        .toList();
  }

  static EthContract? enabledToken(
    MainDB mainDB,
    Iterable<String> addresses,
    String contractAddress,
  ) {
    final normalized = contractAddress.toLowerCase();
    for (final contract in enabledTokens(mainDB, addresses)) {
      if (contract.address.toLowerCase() == normalized) return contract;
    }
    return null;
  }
}

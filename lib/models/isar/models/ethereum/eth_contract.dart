import 'package:isar/isar.dart';
import 'package:stackwallet/models/isar/models/contract.dart';

part 'eth_contract.g.dart';

@collection
class EthContract extends Contract {
  EthContract({
    required this.address,
    required this.name,
    required this.symbol,
    required this.decimals,
    required this.type,
    this.abi,
    this.otherData,
  });

  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late final String address;

  late final String name;

  late final String symbol;

  late final int decimals;

  late final String? abi;

  @enumerated
  late final EthContractType type;

  late final String? otherData;
}

// Used in Isar db and stored there as int indexes so adding/removing values
// in this definition should be done extremely carefully in production
enum EthContractType {
  erc20,
  erc721;
}

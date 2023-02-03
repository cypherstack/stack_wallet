import 'package:isar/isar.dart';
import 'package:stackwallet/exceptions/address/address_exception.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/crypto_currency_address.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/transaction.dart';

part 'address.g.dart';

@Collection(accessor: "addresses")
class Address extends CryptoCurrencyAddress {
  Address({
    required this.walletId,
    required this.value,
    required this.publicKey,
    required this.derivationIndex,
    required this.derivationPath,
    required this.type,
    required this.subType,
    this.otherData,
  });

  Id id = Isar.autoIncrement;

  @Index()
  late final String walletId;

  @Index(unique: true, composite: [CompositeIndex("walletId")])
  late final String value;

  late final List<byte> publicKey;

  @Index()
  late final int derivationIndex; // -1 generally means unknown

  @enumerated
  late final AddressType type;

  @enumerated
  late final AddressSubType subType;

  late final DerivationPath? derivationPath;

  late final String? otherData;

  final transactions = IsarLinks<Transaction>();

  int derivationChain() {
    if (subType == AddressSubType.receiving) {
      return 0; // 0 for receiving (external)
    } else if (subType == AddressSubType.change) {
      return 1; // 1 for change (internal)
    } else {
      throw AddressException("Could not imply derivation chain value");
    }
  }

  bool isPaynymAddress() =>
      subType == AddressSubType.paynymNotification ||
      subType == AddressSubType.paynymSend ||
      subType == AddressSubType.paynymReceive;

  @override
  String toString() => "{ "
      "id: $id, "
      "walletId: $walletId, "
      "value: $value, "
      "publicKey: $publicKey, "
      "derivationIndex: $derivationIndex, "
      "type: ${type.name}, "
      "subType: ${subType.name}, "
      "transactionsLength: ${transactions.length} "
      "derivationPath: $derivationPath, "
      "otherData: $otherData, "
      "}";
}

// do not modify
enum AddressType {
  p2pkh,
  p2sh,
  p2wpkh,
  cryptonote,
  mimbleWimble,
  unknown,
  nonWallet,
}

// do not modify
enum AddressSubType {
  receiving,
  change,
  paynymNotification,
  paynymSend,
  paynymReceive,
  unknown,
  nonWallet,
}

@Embedded(inheritance: false)
class DerivationPath {
  late final String value;

  List<String> getComponents() => value.split("/");

  String getPurpose() => getComponents()[1];

  @override
  toString() => value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is DerivationPath && value == other.value;

  @ignore
  @override
  int get hashCode => value.hashCode;
}

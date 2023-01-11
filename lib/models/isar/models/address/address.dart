import 'package:isar/isar.dart';
import 'package:stackwallet/models/isar/models/address/crypto_currency_address.dart';
import 'package:stackwallet/services/coins/coin_paynym_extension.dart';

part 'address.g.dart';

class AddressException extends SWException {
  AddressException(super.message);
}

@Collection(accessor: "addresses")
class Address extends CryptoCurrencyAddress {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String value;

  late List<byte> publicKey;

  @Index()
  late int derivationIndex;

  @enumerated
  late AddressType type;

  @enumerated
  late AddressSubType subType;

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
  String toString() => value;
}

enum AddressType {
  p2pkh,
  p2sh,
  p2wpkh,
}

enum AddressSubType {
  receiving,
  change,
  paynymNotification,
  paynymSend,
  paynymReceive,
}

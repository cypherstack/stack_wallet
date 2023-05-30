import 'dart:convert';

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

  String toJsonString() {
    final Map<String, dynamic> result = {
      "walletId": walletId,
      "value": value,
      "publicKey": publicKey,
      "derivationIndex": derivationIndex,
      "type": type.name,
      "subType": subType.name,
      "derivationPath": derivationPath?.value,
      "otherData": otherData,
    };
    return jsonEncode(result);
  }

  static Address fromJsonString(
    String jsonString, {
    String? overrideWalletId,
  }) {
    final json = jsonDecode(jsonString);
    final derivationPathString = json["derivationPath"] as String?;

    final DerivationPath? derivationPath =
        derivationPathString == null ? null : DerivationPath();
    if (derivationPath != null) {
      derivationPath.value = derivationPathString!;
    }

    return Address(
      walletId: overrideWalletId ?? json["walletId"] as String,
      value: json["value"] as String,
      publicKey: List<int>.from(json["publicKey"] as List),
      derivationIndex: json["derivationIndex"] as int,
      derivationPath: derivationPath,
      type: AddressType.values.byName(json["type"] as String),
      subType: AddressSubType.values.byName(json["subType"] as String),
      otherData: json["otherData"] as String?,
    );
  }
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
  ethereum,
  nano,
  banano;

  String get readableName {
    switch (this) {
      case AddressType.p2pkh:
        return "Legacy";
      case AddressType.p2sh:
        return "Wrapped segwit";
      case AddressType.p2wpkh:
        return "Segwit";
      case AddressType.cryptonote:
        return "Cryptonote";
      case AddressType.mimbleWimble:
        return "Mimble Wimble";
      case AddressType.unknown:
        return "Unknown";
      case AddressType.nonWallet:
        return "Non wallet/unknown";
      case AddressType.ethereum:
        return "Ethereum";
      case AddressType.nano:
        return "Nano";
      case AddressType.banano:
        return "Banano";
    }
  }
}

// do not modify
enum AddressSubType {
  receiving,
  change,
  paynymNotification,
  paynymSend,
  paynymReceive,
  unknown,
  nonWallet;

  String get prettyName {
    switch (this) {
      case AddressSubType.receiving:
        return "Receiving";
      case AddressSubType.change:
        return "Change";
      case AddressSubType.paynymNotification:
        return "PayNym Notification";
      case AddressSubType.paynymSend:
        return "PayNym Send";
      case AddressSubType.paynymReceive:
        return "PayNym Receiving";
      case AddressSubType.unknown:
        return "Unknown";
      case AddressSubType.nonWallet:
        return "Non wallet/unknown";
    }
  }
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

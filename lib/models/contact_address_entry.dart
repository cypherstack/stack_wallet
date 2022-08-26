import 'dart:convert';

import 'package:stackwallet/utilities/enums/coin_enum.dart';

class ContactAddressEntry {
  final Coin coin;
  final String address;
  final String label;

  const ContactAddressEntry({
    required this.coin,
    required this.address,
    required this.label,
  });

  ContactAddressEntry copyWith({
    Coin? coin,
    String? address,
    String? label,
  }) {
    return ContactAddressEntry(
      coin: coin ?? this.coin,
      address: address ?? this.address,
      label: label ?? this.label,
    );
  }

  factory ContactAddressEntry.fromJson(Map<String, dynamic> jsonObject) {
    return ContactAddressEntry(
      coin: Coin.values.byName(jsonObject["coin"] as String),
      address: jsonObject["address"] as String,
      label: jsonObject["label"] as String,
    );
  }

  Map<String, String> toMap() {
    return {
      "label": label,
      "address": address,
      "coin": coin.name,
    };
  }

  String toJsonString() {
    return jsonEncode(toMap());
  }

  @override
  String toString() {
    return "AddressBookEntry: ${toJsonString()}";
  }
}

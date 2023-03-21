import 'dart:convert';

import 'package:stackduo/utilities/enums/coin_enum.dart';

class ContactAddressEntry {
  final Coin coin;
  final String address;
  final String label;
  final String? other;

  const ContactAddressEntry({
    required this.coin,
    required this.address,
    required this.label,
    this.other,
  });

  ContactAddressEntry copyWith({
    Coin? coin,
    String? address,
    String? label,
    String? other,
  }) {
    return ContactAddressEntry(
      coin: coin ?? this.coin,
      address: address ?? this.address,
      label: label ?? this.label,
      other: other ?? this.other,
    );
  }

  factory ContactAddressEntry.fromJson(Map<String, dynamic> jsonObject) {
    return ContactAddressEntry(
      coin: Coin.values.byName(jsonObject["coin"] as String),
      address: jsonObject["address"] as String,
      label: jsonObject["label"] as String,
      other: jsonObject["other"] as String?,
    );
  }

  Map<String, String> toMap() {
    return {
      "label": label,
      "address": address,
      "coin": coin.name,
      "other": other ?? "",
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

import 'dart:convert';

class CryptonoteKeyRestoreData {
  const CryptonoteKeyRestoreData({
    required this.address,
    required this.privateViewKey,
    required this.privateSpendKey,
  });

  final String address;
  final String privateViewKey;
  final String privateSpendKey;

  factory CryptonoteKeyRestoreData.fromJsonEncodedString(String value) {
    final json = jsonDecode(value);
    if (json is! Map<String, dynamic>) {
      throw const FormatException("Invalid Cryptonote key restore data");
    }

    return CryptonoteKeyRestoreData(
      address: json["address"] as String,
      privateViewKey: json["privateViewKey"] as String,
      privateSpendKey: json["privateSpendKey"] as String,
    );
  }

  String toJsonEncodedString() => jsonEncode({
    "address": address,
    "privateViewKey": privateViewKey,
    "privateSpendKey": privateSpendKey,
  });

  @override
  String toString() =>
      "CryptonoteKeyRestoreData(address: $address, private keys: <redacted>)";
}

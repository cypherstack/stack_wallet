import 'dart:convert';

class CryptonoteKeyRestoreData {
  static const int currentVersion = 1;

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

    final version = json["version"];
    if (version != null && version != currentVersion) {
      throw const FormatException(
        "Unsupported Cryptonote key restore data version",
      );
    }

    final address = json["address"];
    final privateViewKey = json["privateViewKey"];
    final privateSpendKey = json["privateSpendKey"];
    if (address is! String ||
        address.isEmpty ||
        privateViewKey is! String ||
        privateViewKey.isEmpty ||
        privateSpendKey is! String ||
        privateSpendKey.isEmpty) {
      throw const FormatException("Invalid Cryptonote key restore data");
    }

    return CryptonoteKeyRestoreData(
      address: address,
      privateViewKey: privateViewKey,
      privateSpendKey: privateSpendKey,
    );
  }

  String toJsonEncodedString() => jsonEncode({
    "version": currentVersion,
    "address": address,
    "privateViewKey": privateViewKey,
    "privateSpendKey": privateSpendKey,
  });

  @override
  String toString() =>
      "CryptonoteKeyRestoreData(address: $address, private keys: <redacted>)";
}

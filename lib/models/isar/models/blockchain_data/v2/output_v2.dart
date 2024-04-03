import 'package:decimal/decimal.dart';
import 'package:isar/isar.dart';

part 'output_v2.g.dart';

@Embedded()
class OutputV2 {
  late final String scriptPubKeyHex;
  late final String? scriptPubKeyAsm;
  late final String valueStringSats;
  late final List<String> addresses;

  late final bool walletOwns;

  @ignore
  BigInt get value => BigInt.parse(valueStringSats);

  OutputV2();

  static OutputV2 isarCantDoRequiredInDefaultConstructor({
    required String scriptPubKeyHex,
    String? scriptPubKeyAsm,
    required String valueStringSats,
    required List<String> addresses,
    required bool walletOwns,
  }) =>
      OutputV2()
        ..scriptPubKeyHex = scriptPubKeyHex
        ..scriptPubKeyAsm = scriptPubKeyAsm
        ..valueStringSats = valueStringSats
        ..walletOwns = walletOwns
        ..addresses = List.unmodifiable(addresses);

  OutputV2 copyWith({
    String? scriptPubKeyHex,
    String? scriptPubKeyAsm,
    String? valueStringSats,
    List<String>? addresses,
    bool? walletOwns,
  }) {
    return OutputV2.isarCantDoRequiredInDefaultConstructor(
      scriptPubKeyHex: scriptPubKeyHex ?? this.scriptPubKeyHex,
      scriptPubKeyAsm: scriptPubKeyAsm ?? this.scriptPubKeyAsm,
      valueStringSats: valueStringSats ?? this.valueStringSats,
      addresses: addresses ?? this.addresses,
      walletOwns: walletOwns ?? this.walletOwns,
    );
  }

  static OutputV2 fromElectrumXJson(
    Map<String, dynamic> json, {
    required bool walletOwns,
    required int decimalPlaces,
    bool isFullAmountNotSats = false,
  }) {
    try {
      List<String> addresses = [];

      if (json["scriptPubKey"]?["addresses"] is List) {
        for (final e in json["scriptPubKey"]["addresses"] as List) {
          addresses.add(e as String);
        }
      } else if (json["scriptPubKey"]?["address"] is String) {
        addresses.add(json["scriptPubKey"]?["address"] as String);
      }

      return OutputV2.isarCantDoRequiredInDefaultConstructor(
        scriptPubKeyHex: json["scriptPubKey"]["hex"] as String,
        scriptPubKeyAsm: json["scriptPubKey"]["asm"] as String?,
        valueStringSats: parseOutputAmountString(
          json["value"] != null ? json["value"].toString(): "0",
          decimalPlaces: decimalPlaces,
          isFullAmountNotSats: isFullAmountNotSats,
        ),
        addresses: addresses,
        walletOwns: walletOwns,
      );
    } catch (e) {
      throw Exception("Failed to parse OutputV2 from $json");
    }
  }

  static String parseOutputAmountString(
    String amount, {
    required int decimalPlaces,
    bool isFullAmountNotSats = false,
  }) {
    final temp = Decimal.parse(amount);
    if (temp < Decimal.zero) {
      throw Exception("Negative value found");
    }

    final String valueStringSats;
    if (isFullAmountNotSats) {
      valueStringSats = temp.shift(decimalPlaces).toBigInt().toString();
    } else if (temp.isInteger) {
      valueStringSats = temp.toString();
    } else {
      valueStringSats = temp.shift(decimalPlaces).toBigInt().toString();
    }

    return valueStringSats;
  }

  @override
  String toString() {
    return 'OutputV2(\n'
        '  scriptPubKeyHex: $scriptPubKeyHex,\n'
        '  scriptPubKeyAsm: $scriptPubKeyAsm,\n'
        '  value: $value,\n'
        '  walletOwns: $walletOwns,\n'
        '  addresses: $addresses,\n'
        ')';
  }
}

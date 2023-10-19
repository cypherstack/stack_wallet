import 'package:decimal/decimal.dart';
import 'package:isar/isar.dart';

part 'output_v2.g.dart';

@Embedded()
class OutputV2 {
  late final String scriptPubKeyHex;
  late final String valueStringSats;
  late final List<String> addresses;

  @ignore
  BigInt get value => BigInt.parse(valueStringSats);

  OutputV2();

  static OutputV2 isarCantDoRequiredInDefaultConstructor({
    required String scriptPubKeyHex,
    required String valueStringSats,
    required List<String> addresses,
  }) =>
      OutputV2()
        ..scriptPubKeyHex = scriptPubKeyHex
        ..valueStringSats = valueStringSats
        ..addresses = List.unmodifiable(addresses);

  static OutputV2 fromElectrumXJson(
    Map<String, dynamic> json, {
    required int decimalPlaces,
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
        valueStringSats: parseOutputAmountString(
          json["value"].toString(),
          decimalPlaces: decimalPlaces,
        ),
        addresses: addresses,
      );
    } catch (e) {
      throw Exception("Failed to parse OutputV2 from $json");
    }
  }

  static String parseOutputAmountString(
    String amount, {
    required int decimalPlaces,
  }) {
    final temp = Decimal.parse(amount);
    if (temp < Decimal.zero) {
      throw Exception("Negative value found");
    }

    final String valueStringSats;
    if (temp.isInteger) {
      valueStringSats = temp.toString();
    } else {
      valueStringSats = temp.shift(decimalPlaces).toBigInt().toString();
    }

    return valueStringSats;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is OutputV2 &&
        other.scriptPubKeyHex == scriptPubKeyHex &&
        _listEquals(other.addresses, addresses) &&
        other.valueStringSats == valueStringSats;
  }

  @override
  int get hashCode => Object.hash(
        scriptPubKeyHex,
        valueStringSats,
      );

  @override
  String toString() {
    return 'OutputV2(\n'
        '  scriptPubKeyHex: $scriptPubKeyHex,\n'
        '  value: $value,\n'
        '  addresses: $addresses,\n'
        ')';
  }
}

bool _listEquals<T, U>(List<T> a, List<U> b) {
  if (T != U) {
    return false;
  }

  if (a.length != b.length) {
    return false;
  }

  for (int i = 0; i < a.length; i++) {
    if (a[i] != b[i]) {
      return false;
    }
  }

  return true;
}

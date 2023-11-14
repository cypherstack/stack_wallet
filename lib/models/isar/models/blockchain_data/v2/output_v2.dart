import 'package:decimal/decimal.dart';
import 'package:isar/isar.dart';

part 'output_v2.g.dart';

@Embedded()
class OutputV2 {
  late final String scriptPubKeyHex;
  late final String valueStringSats;
  late final List<String> addresses;

  late final bool walletOwns;

  @ignore
  BigInt get value => BigInt.parse(valueStringSats);

  OutputV2();

  static OutputV2 isarCantDoRequiredInDefaultConstructor({
    required String scriptPubKeyHex,
    required String valueStringSats,
    required List<String> addresses,
    required bool walletOwns,
  }) =>
      OutputV2()
        ..scriptPubKeyHex = scriptPubKeyHex
        ..valueStringSats = valueStringSats
        ..walletOwns = walletOwns
        ..addresses = List.unmodifiable(addresses);

  OutputV2 copyWith({
    String? scriptPubKeyHex,
    String? valueStringSats,
    List<String>? addresses,
    bool? walletOwns,
  }) {
    return OutputV2.isarCantDoRequiredInDefaultConstructor(
      scriptPubKeyHex: scriptPubKeyHex ?? this.scriptPubKeyHex,
      valueStringSats: valueStringSats ?? this.valueStringSats,
      addresses: addresses ?? this.addresses,
      walletOwns: walletOwns ?? this.walletOwns,
    );
  }

  static OutputV2 fromElectrumXJson(
    Map<String, dynamic> json, {
    required bool walletOwns,
    required int decimalPlaces,
    bool isECashFullAmountNotSats = false,
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
        valueStringSats: parseOutputAmountString(json["value"].toString(),
            decimalPlaces: decimalPlaces,
            isECashFullAmountNotSats: isECashFullAmountNotSats),
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
    bool isECashFullAmountNotSats = false,
  }) {
    final temp = Decimal.parse(amount);
    if (temp < Decimal.zero) {
      throw Exception("Negative value found");
    }

    final String valueStringSats;
    if (isECashFullAmountNotSats) {
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
        '  value: $value,\n'
        '  walletOwns: $walletOwns,\n'
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

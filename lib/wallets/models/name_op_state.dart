import 'package:namecoin/namecoin.dart';

class NameOpState {
  final String name;

  final OpName type;

  final String saltHex;
  final String commitment;
  final String value;
  final String nameScriptHex;

  NameOpState({
    required this.name,
    required this.type,
    required this.saltHex,
    required this.commitment,
    required this.value,
    required this.nameScriptHex,
  });

  NameOpState copyWith({
    String? walletId,
    String? name,
    String? txid,
    OpName? type,
    String? saltHex,
    String? commitment,
    String? value,
    String? nameScriptHex,
  }) {
    return NameOpState(
      name: name ?? this.name,
      type: type ?? this.type,
      saltHex: saltHex ?? this.saltHex,
      commitment: commitment ?? this.commitment,
      value: value ?? this.value,
      nameScriptHex: nameScriptHex ?? this.nameScriptHex,
    );
  }

  @override
  String toString() {
    return "NameOpState("
        "name: $name, "
        "type: ${type.name}, "
        "saltHex: $saltHex, "
        "commitment: $commitment, "
        "value: $value, "
        "nameScriptHex: $nameScriptHex)";
  }
}

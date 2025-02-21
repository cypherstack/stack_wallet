import 'package:namecoin/namecoin.dart';

import '../../models/isar/models/blockchain_data/utxo.dart';

class NameOpState {
  final String name;
  final OpName type;
  final String saltHex;
  final String commitment;
  final String value;
  final String nameScriptHex;
  final int outputPosition;
  final UTXO? output;

  NameOpState({
    required this.name,
    required this.type,
    required this.saltHex,
    required this.commitment,
    required this.value,
    required this.nameScriptHex,
    required this.outputPosition,
    this.output,
  });

  NameOpState copyWith({
    String? name,
    OpName? type,
    String? saltHex,
    String? commitment,
    String? value,
    String? nameScriptHex,
    int? outputPosition,
  }) {
    return NameOpState(
      name: name ?? this.name,
      type: type ?? this.type,
      saltHex: saltHex ?? this.saltHex,
      commitment: commitment ?? this.commitment,
      value: value ?? this.value,
      nameScriptHex: nameScriptHex ?? this.nameScriptHex,
      outputPosition: outputPosition ?? this.outputPosition,
      output: output,
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
        "nameScriptHex: $nameScriptHex, "
        "outputPosition: $outputPosition, "
        "output: $output)";
  }
}

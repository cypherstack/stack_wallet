import 'dart:convert';

import 'package:isar/isar.dart';

part 'output.g.dart';

@embedded
class Output {
  Output({
    this.scriptPubKey,
    this.scriptPubKeyAsm,
    this.scriptPubKeyType,
    this.scriptPubKeyAddress = "",
    this.value = 0,
  });

  late final String? scriptPubKey;

  late final String? scriptPubKeyAsm;

  late final String? scriptPubKeyType;

  late final String scriptPubKeyAddress;

  late final int value;

  String toJsonString() {
    final Map<String, dynamic> result = {
      "scriptPubKey": scriptPubKey,
      "scriptPubKeyAsm": scriptPubKeyAsm,
      "scriptPubKeyType": scriptPubKeyType,
      "scriptPubKeyAddress": scriptPubKeyAddress,
      "value": value,
    };
    return jsonEncode(result);
  }

  static Output fromJsonString(String jsonString) {
    final json = jsonDecode(jsonString);
    return Output(
      scriptPubKey: json["scriptPubKey"] as String?,
      scriptPubKeyAsm: json["scriptPubKeyAsm"] as String?,
      scriptPubKeyType: json["scriptPubKeyType"] as String?,
      scriptPubKeyAddress: json["scriptPubKeyAddress"] as String,
      value: json["value"] as int,
    );
  }
}

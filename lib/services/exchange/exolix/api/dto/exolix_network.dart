import 'exolix_base_dto.dart';

/// A network entry as returned in currency listings and the dedicated
/// networks endpoints.
class ExolixNetwork extends ExolixBaseDto {
  final String network;
  final String name;
  final String? shortName;
  final String? notes;
  final String? addressRegex;
  final bool isDefault;
  final String? blockExplorer;
  final bool memoNeeded;
  final String? memoName;
  final String? memoRegex;
  final int precision;
  final int? decimal;
  final String? contract;
  final String? icon;

  ExolixNetwork({
    required this.network,
    required this.name,
    required this.shortName,
    required this.notes,
    required this.addressRegex,
    required this.isDefault,
    required this.blockExplorer,
    required this.memoNeeded,
    required this.memoName,
    required this.memoRegex,
    required this.precision,
    required this.decimal,
    required this.contract,
    required this.icon,
  });

  factory ExolixNetwork.fromJson(Map<String, dynamic> json) {
    // The docs are inconsistent: one example uses "addresRegex" (typo),
    // another uses "addressRegex". Accept both.
    final dynamic addrRegex = json["addressRegex"] ?? json["addresRegex"];
    return ExolixNetwork(
      network: json["network"] as String? ?? "",
      name: json["name"] as String? ?? "",
      shortName: json["shortName"] as String?,
      notes: json["notes"] as String?,
      addressRegex: addrRegex as String?,
      isDefault: json["isDefault"] as bool? ?? false,
      blockExplorer: json["blockExplorer"] as String?,
      memoNeeded: json["memoNeeded"] as bool? ?? false,
      memoName: json["memoName"] as String?,
      memoRegex: json["memoRegex"] as String?,
      precision: _parseInt(json["precision"]),
      decimal: json["decimal"] == null ? null : _parseInt(json["decimal"]),
      contract: json["contract"] as String?,
      icon: json["icon"] as String?,
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      "network": network,
      "name": name,
      "shortName": shortName,
      "notes": notes,
      "addressRegex": addressRegex,
      "isDefault": isDefault,
      "blockExplorer": blockExplorer,
      "memoNeeded": memoNeeded,
      "memoName": memoName,
      "memoRegex": memoRegex,
      "precision": precision,
      "decimal": decimal,
      "contract": contract,
      "icon": icon,
    };
  }
}

int _parseInt(dynamic value) {
  if (value is int) return value;
  if (value is double) return value.toInt();
  if (value is String) {
    final parsedInt = int.tryParse(value);
    if (parsedInt != null) return parsedInt;
    throw FormatException(
      "Expected an integer value but got unparseable string",
      value,
    );
  }
  throw FormatException(
    "Expected an integer value (int, or numeric String) but got"
        " ${value.runtimeType}",
    "$value",
  );
}

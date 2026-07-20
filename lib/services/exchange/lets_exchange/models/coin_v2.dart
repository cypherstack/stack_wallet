class CoinV2 {
  CoinV2({
    required this.code,
    required this.name,
    required this.isActive,
    required this.icon,
    required this.additionalInfoGet,
    required this.additionalInfoSend,
    required this.defaultNetworkCode,
    required this.defaultNetworkName,
    required this.networks,
  });

  final String code;
  final String name;

  final bool isActive;
  final String icon;
  final String additionalInfoGet;
  final String additionalInfoSend;
  final String defaultNetworkCode;
  final String defaultNetworkName;
  final List<CoinNetwork> networks;

  factory CoinV2.fromJson(Map<String, dynamic> json) => CoinV2(
    code: json["code"] as String,
    name: json["name"] as String,
    isActive: int.parse(json["is_active"].toString()) == 1,
    icon: json["icon"] as String,
    additionalInfoGet: json["additional_info_get"] as String,
    additionalInfoSend: json["additional_info_send"] as String,
    defaultNetworkCode: json["default_network_code"] as String,
    defaultNetworkName: json["default_network_name"] as String,
    networks: (json["networks"] as List<dynamic>)
        .map((dynamic e) => CoinNetwork.fromJson(e as Map<String, dynamic>))
        .toList(),
  );

  Map<String, dynamic> toMap() => {
    "code": code,
    "name": name,
    "is_active": isActive,
    "icon": icon,
    "additional_info_get": additionalInfoGet,
    "additional_info_send": additionalInfoSend,
    "default_network_code": defaultNetworkCode,
    "default_network_name": defaultNetworkName,
    "networks": networks.map((CoinNetwork e) => e.toMap()).toList(),
  };

  @override
  String toString() => toMap().toString();
}

class CoinNetwork {
  CoinNetwork({
    required this.name,
    required this.code,
    required this.isActive,
    required this.hasExtra,
    required this.extraName,
    required this.explorer,
    required this.contractAddress,
    required this.validationAddressRegex,
    required this.validationAddressExtraRegex,
  });

  final String name;
  final String code;
  final bool isActive;
  final bool hasExtra;
  final String? extraName;
  final String explorer;
  final String contractAddress;
  final String validationAddressRegex;
  final String? validationAddressExtraRegex;

  factory CoinNetwork.fromJson(Map<String, dynamic> json) => CoinNetwork(
    name: json["name"] as String,
    code: json["code"] as String,
    isActive: int.parse(json["is_active"].toString()) == 1,
    hasExtra: int.parse(json["has_extra"].toString()) == 1,
    extraName: json["extra_name"] as String?,
    explorer: json["explorer"] as String,
    contractAddress: json["contract_address"] as String,
    validationAddressRegex: json["validation_address_regex"] as String,
    validationAddressExtraRegex:
        json["validation_address_extra_regex"] as String?,
  );

  Map<String, dynamic> toMap() => {
    "name": name,
    "code": code,
    "is_active": isActive,
    "has_extra": hasExtra,
    "extra_name": extraName,
    "explorer": explorer,
    "contract_address": contractAddress,
    "validation_address_regex": validationAddressRegex,
    "validation_address_extra_regex": validationAddressExtraRegex,
  };

  @override
  String toString() => toMap().toString();
}

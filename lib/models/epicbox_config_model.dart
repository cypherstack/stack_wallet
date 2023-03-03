import 'dart:convert';

import 'package:hive/hive.dart';

part 'type_adaptors/epicbox_config_model.g.dart';

// @HiveType(typeId: 14)
class EpicBoxConfigModel {
  // @HiveField(1)
  final String host;
  // @HiveField(2)
  final int? port;
  // @HiveField(3)
  final bool? protocolInsecure;
  // @HiveField(4)
  final int? addressIndex;
  // // @HiveField(5)
  // final String? id;
  // // @HiveField(6)
  // final String? name;

  EpicBoxConfigModel({
    required this.host,
    this.port,
    this.protocolInsecure,
    this.addressIndex,
    // this.id,
    // this.name,
  });

  EpicBoxConfigModel copyWith({
    int? port,
    bool? protocolInsecure,
    int? addressIndex,
    // String? id,
    // String? name,
  }) {
    return EpicBoxConfigModel(
      host: host,
      port: this.port ?? 443,
      protocolInsecure: this.protocolInsecure ?? false,
      addressIndex: this.addressIndex ?? 0,
      // id: id ?? this.id,
      // name: name ?? this.name,
    );
  }

  Map<String, dynamic> toMap() {
    Map<String, dynamic> map = {};
    map['epicbox_domain'] = host;
    map['epicbox_port'] = port;
    map['epicbox_protocol_insecure'] = protocolInsecure;
    map['epicbox_address_index'] = addressIndex;
    // map['id'] = id;
    // map['name'] = name;
    return map;
  }

  Map<String, dynamic> toJson() {
    return {
      'epicbox_domain': host,
      'epicbox_port': port,
      'epicbox_protocol_insecure': protocolInsecure,
      'epicbox_address_index': addressIndex,
      // 'id': id,
      // 'name': name,
    };
  }

  @override
  String toString() {
    return json.encode(toJson());
  }
}

part 'type_adaptors/epicbox_model.g.dart';

// @HiveType(typeId: 12)
class EpicBoxModel {
  // @HiveField(0)
  final String id;
  // @HiveField(1)
  final String host;
  // @HiveField(2)
  final int? port;
  // @HiveField(3)
  final String name;
  // @HiveField(4)
  final bool? useSSL;
  // @HiveField(5)
  final bool? enabled;
  // @HiveField(6)
  final bool? isFailover;
  // @HiveField(7)
  final bool? isDown;

  EpicBoxModel({
    required this.host,
    required this.name,
    this.port,
    required this.id,
    this.useSSL,
    this.enabled,
    this.isFailover,
    this.isDown,
  });

  EpicBoxModel copyWith({
    String? host,
    int? port,
    String? name,
    bool? useSSL,
    bool? enabled,
    bool? isFailover,
    bool? isDown,
  }) {
    return EpicBoxModel(
      host: host ?? this.host,
      port: port ?? this.port,
      name: name ?? this.name,
      id: id,
      useSSL: useSSL ?? this.useSSL,
      enabled: enabled ?? this.enabled,
      isFailover: isFailover ?? this.isFailover,
      isDown: isDown ?? this.isDown,
    );
  }

  Map<String, dynamic> toMap() {
    Map<String, dynamic> map = {};
    map['host'] = host;
    map['port'] = port;
    map['name'] = name;
    map['id'] = id;
    map['useSSL'] = useSSL;
    map['enabled'] = enabled;
    map['isFailover'] = isFailover;
    map['isDown'] = isDown;
    return map;
  }

  bool get isDefault => id.startsWith("default_");

  @override
  String toString() {
    return toMap().toString();
  }
}

import 'package:hive_ce/hive.dart';

/// A slate relay server: an epicbox for Epic Cash, an mwcmqs for MWC.
abstract class RelayServerModel {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String host;
  @HiveField(2)
  final int? port;
  @HiveField(3)
  final String name;
  @HiveField(4)
  final bool? useSSL;
  @HiveField(5)
  final bool? enabled;
  @HiveField(6)
  final bool? isFailover;
  @HiveField(7)
  final bool? isDown;

  const RelayServerModel({
    required this.id,
    required this.host,
    this.port,
    required this.name,
    this.useSSL,
    this.enabled,
    this.isFailover,
    this.isDown,
  });

  RelayServerModel copyWith({
    String? host,
    int? port,
    String? name,
    bool? useSSL,
    bool? enabled,
    bool? isFailover,
    bool? isDown,
  });

  bool get isDefault => id.startsWith("default_");

  Map<String, dynamic> toMap() => toJson();

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'host': host,
      'port': port,
      'name': name,
      'useSSL': useSSL,
      'enabled': enabled,
      'isFailover': isFailover,
      'isDown': isDown,
    };
  }
}

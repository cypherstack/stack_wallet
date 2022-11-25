import 'package:hive/hive.dart';
import 'package:stackwallet/utilities/default_nodes.dart';
import 'package:stackwallet/utilities/flutter_secure_storage_interface.dart';

part 'type_adaptors/node_model.g.dart';

// @HiveType(typeId: 12)
class NodeModel {
  // @HiveField(0)
  final String id;
  // @HiveField(1)
  final String host;
  // @HiveField(2)
  final int port;
  // @HiveField(3)
  final String name;
  // @HiveField(4)
  final bool useSSL;
  // @HiveField(5)
  final String? loginName;
  // @HiveField(6)
  final bool enabled;
  // @HiveField(7)
  final String coinName;
  // @HiveField(8)
  final bool isFailover;
  // @HiveField(9)
  final bool isDown;

  NodeModel({
    required this.host,
    required this.port,
    required this.name,
    required this.id,
    required this.useSSL,
    required this.enabled,
    required this.coinName,
    required this.isFailover,
    required this.isDown,
    this.loginName,
  });

  NodeModel copyWith({
    String? host,
    int? port,
    String? name,
    bool? useSSL,
    String? loginName,
    bool? enabled,
    String? coinName,
    bool? isFailover,
    bool? isDown,
  }) {
    return NodeModel(
      host: host ?? this.host,
      port: port ?? this.port,
      name: name ?? this.name,
      id: id,
      useSSL: useSSL ?? this.useSSL,
      loginName: loginName ?? this.loginName,
      enabled: enabled ?? this.enabled,
      coinName: coinName ?? this.coinName,
      isFailover: isFailover ?? this.isFailover,
      isDown: isDown ?? this.isDown,
    );
  }

  /// convenience getter to retrieve login password
  Future<String?> getPassword(SecureStorageInterface secureStorage) async {
    return await secureStorage.read(key: "${id}_nodePW");
  }

  Map<String, dynamic> toMap() {
    Map<String, dynamic> map = {};
    map['host'] = host;
    map['port'] = port;
    map['name'] = name;
    map['id'] = id;
    map['useSSL'] = useSSL;
    map['loginName'] = loginName;
    map['enabled'] = enabled;
    map['coinName'] = coinName;
    map['isFailover'] = isFailover;
    map['isDown'] = isDown;
    return map;
  }

  bool get isDefault => id.startsWith(DefaultNodes.defaultNodeIdPrefix);

  @override
  String toString() {
    return toMap().toString();
  }
}

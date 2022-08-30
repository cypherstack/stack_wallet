import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart';
import 'package:stackwallet/hive/db.dart';
import 'package:stackwallet/models/node_model.dart';
import 'package:stackwallet/utilities/default_nodes.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/utilities/flutter_secure_storage_interface.dart';
import 'package:stackwallet/utilities/logger.dart';

const kStackCommunityNodesEndpoint = "https://extras.stackwallet.com";

class NodeService extends ChangeNotifier {
  final FlutterSecureStorageInterface secureStorageInterface;

  /// Exposed [secureStorageInterface] in order to inject mock for tests
  NodeService({
    this.secureStorageInterface = const SecureStorageWrapper(
      FlutterSecureStorage(),
    ),
  });

  Future<void> updateDefaults() async {
    for (final defaultNode in DefaultNodes.all) {
      final savedNode = DB.instance
          .get<NodeModel>(boxName: DB.boxNameNodeModels, key: defaultNode.id);
      if (savedNode == null) {
        // save the default node to hive
        await DB.instance.put<NodeModel>(
            boxName: DB.boxNameNodeModels,
            key: defaultNode.id,
            value: defaultNode);
      } else {
        // update all fields but copy over previously set enabled state
        await DB.instance.put<NodeModel>(
            boxName: DB.boxNameNodeModels,
            key: savedNode.id,
            value: defaultNode.copyWith(enabled: savedNode.enabled));
      }
    }
  }

  Future<void> setPrimaryNodeFor({
    required Coin coin,
    required NodeModel node,
    bool shouldNotifyListeners = false,
  }) async {
    await DB.instance.put<NodeModel>(
        boxName: DB.boxNamePrimaryNodes, key: coin.name, value: node);
    if (shouldNotifyListeners) {
      notifyListeners();
    }
  }

  NodeModel? getPrimaryNodeFor({required Coin coin}) {
    return DB.instance
        .get<NodeModel>(boxName: DB.boxNamePrimaryNodes, key: coin.name);
  }

  List<NodeModel> get primaryNodes {
    return DB.instance.values<NodeModel>(boxName: DB.boxNamePrimaryNodes);
  }

  List<NodeModel> get nodes {
    return DB.instance.values<NodeModel>(boxName: DB.boxNameNodeModels);
  }

  List<NodeModel> getNodesFor(Coin coin) {
    final list = DB.instance
        .values<NodeModel>(boxName: DB.boxNameNodeModels)
        .where((e) =>
            e.coinName == coin.name && e.name != DefaultNodes.defaultName)
        .toList();

    // add default to end of list
    list.addAll(DB.instance
        .values<NodeModel>(boxName: DB.boxNameNodeModels)
        .where((e) =>
            e.coinName == coin.name && e.name == DefaultNodes.defaultName)
        .toList());

    // return reversed list so default node appears at beginning
    return list.reversed.toList();
  }

  NodeModel? getNodeById({required String id}) {
    return DB.instance.get<NodeModel>(boxName: DB.boxNameNodeModels, key: id);
  }

  List<NodeModel> failoverNodesFor({required Coin coin}) {
    return getNodesFor(coin).where((e) => e.isFailover && !e.isDown).toList();
  }

  // should probably just combine this and edit into a save() func at some point
  /// Over write node in hive if a node with existing id already exists.
  /// Otherwise add node to hive
  Future<void> add(
    NodeModel node,
    String? password,
    bool shouldNotifyListeners,
  ) async {
    await DB.instance.put<NodeModel>(
        boxName: DB.boxNameNodeModels, key: node.id, value: node);

    if (password != null) {
      await secureStorageInterface.write(
          key: "${node.id}_nodePW", value: password);
    }
    if (shouldNotifyListeners) {
      notifyListeners();
    }
  }

  Future<void> delete(String id, bool shouldNotifyListeners) async {
    await DB.instance.delete<NodeModel>(boxName: DB.boxNameNodeModels, key: id);

    await secureStorageInterface.delete(key: "${id}_nodePW");
    if (shouldNotifyListeners) {
      notifyListeners();
    }
  }

  Future<void> setEnabledState(
    String id,
    bool enabled,
    bool shouldNotifyListeners,
  ) async {
    final model = DB.instance.get<NodeModel>(
      boxName: DB.boxNameNodeModels,
      key: id,
    )!;
    await DB.instance.put<NodeModel>(
        boxName: DB.boxNameNodeModels,
        key: model.id,
        value: model.copyWith(enabled: enabled));
    if (shouldNotifyListeners) {
      notifyListeners();
    }
  }

  /// convenience wrapper for add
  Future<void> edit(
    NodeModel editedNode,
    String? password,
    bool shouldNotifyListeners,
  ) async {
    return add(editedNode, password, shouldNotifyListeners);
  }

  //============================================================================

  Future<void> updateCommunityNodes() async {
    final Client client = Client();
    try {
      final uri = Uri.parse("$kStackCommunityNodesEndpoint/getNodes");
      final response = await client.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "jsonrpc": "2.0",
          "id": "0",
        }),
      );

      final json = jsonDecode(response.body) as Map;
      final result = jsonDecode(json['result'] as String);
      final map = jsonDecode(result as String);
      Logging.instance.log(map, level: LogLevel.Info);

      for (final coin in Coin.values) {
        final nodeList = List<Map<String, dynamic>>.from(
            map["nodes"][coin.name] as List? ?? []);
        for (final nodeMap in nodeList) {
          NodeModel node = NodeModel(
            host: nodeMap["host"] as String,
            port: nodeMap["port"] as int,
            name: nodeMap["name"] as String,
            id: nodeMap["id"] as String,
            useSSL: nodeMap["useSSL"] == "true",
            enabled: true,
            coinName: coin.name,
            isFailover: true,
            isDown: nodeMap["isDown"] == "true",
          );
          final currentNode = getNodeById(id: nodeMap["id"] as String);
          if (currentNode != null) {
            node = currentNode.copyWith(
              host: node.host,
              port: node.port,
              name: node.name,
              useSSL: node.useSSL,
              coinName: node.coinName,
              isDown: node.isDown,
            );
          }
          await add(node, null, false);
        }
      }
    } catch (e, s) {
      Logging.instance
          .log("updateCommunityNodes() failed: $e\n$s", level: LogLevel.Error);
    }
  }
}

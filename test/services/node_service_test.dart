import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:hive_test/hive_test.dart';
import 'package:stackwallet/db/hive/db.dart';
import 'package:stackwallet/models/node_model.dart';
import 'package:stackwallet/services/node_service.dart';
import 'package:stackwallet/utilities/default_nodes.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/utilities/flutter_secure_storage_interface.dart';

void main() {
  bool wasRegistered = false;
  setUp(() async {
    await setUpTestHive();
    if (!wasRegistered) {
      wasRegistered = true;
      Hive.registerAdapter(NodeModelAdapter());
    }
    await Hive.openBox<NodeModel>(DB.boxNameNodeModels);
    await Hive.openBox<NodeModel>(DB.boxNamePrimaryNodes);
  });

  group("Empty nodes DB tests", () {
    test("getPrimaryNodeFor", () {
      final fakeStore = FakeSecureStorage();
      final service = NodeService(secureStorageInterface: fakeStore);
      final node = service.getPrimaryNodeFor(coin: Coin.bitcoin);
      expect(node, null);
      expect(fakeStore.interactions, 0);
    });

    test("setPrimaryNodeFor", () async {
      final fakeStore = FakeSecureStorage();
      final service = NodeService(secureStorageInterface: fakeStore);
      final node = service.getPrimaryNodeFor(coin: Coin.bitcoin);
      expect(node, null);
      final node1 = NodeModel(
        host: "host",
        port: 42,
        name: "btcnode",
        id: "pnodeID",
        useSSL: true,
        enabled: true,
        coinName: "bitcoin",
        isFailover: true,
        isDown: false,
      );
      await service.setPrimaryNodeFor(
        coin: Coin.bitcoin,
        node: node1,
        shouldNotifyListeners: true,
      );

      expect(service.getPrimaryNodeFor(coin: Coin.bitcoin).toString(),
          node1.toString());
      expect(fakeStore.interactions, 0);
    });

    test("getNodesFor", () {
      final fakeStore = FakeSecureStorage();
      final service = NodeService(secureStorageInterface: fakeStore);
      final nodes = service.getNodesFor(Coin.bitcoin);
      expect(nodes.isEmpty, true);
      expect(fakeStore.interactions, 0);
    });

    test("get primary nodes", () {
      final fakeStore = FakeSecureStorage();
      final service = NodeService(secureStorageInterface: fakeStore);
      final nodes = service.primaryNodes;
      expect(nodes.isEmpty, true);
      expect(fakeStore.interactions, 0);
    });

    test("get nodes", () {
      final fakeStore = FakeSecureStorage();
      final service = NodeService(secureStorageInterface: fakeStore);
      final nodes = service.nodes;
      expect(nodes.isEmpty, true);
      expect(fakeStore.interactions, 0);
    });

    test("get failover nodes", () {
      final fakeStore = FakeSecureStorage();
      final service = NodeService(secureStorageInterface: fakeStore);
      final nodes = service.failoverNodesFor(coin: Coin.bitcoin);
      expect(nodes.isEmpty, true);
      expect(fakeStore.interactions, 0);
    });

    test("get non existing getNodeById", () {
      final fakeStore = FakeSecureStorage();
      final service = NodeService(secureStorageInterface: fakeStore);
      final node = service.getNodeById(id: "Some ID");
      expect(node, null);
      expect(fakeStore.interactions, 0);
    });

    test("updateDefaults", () async {
      final fakeStore = FakeSecureStorage();
      final service = NodeService(secureStorageInterface: fakeStore);
      await service.updateDefaults();
      expect(service.nodes.length, DefaultNodes.all.length);
      expect(fakeStore.interactions, 0);
    });
  });

  group("Defaults populated tests", () {
    final nodeA = NodeModel(
      host: "host1",
      port: 421,
      name: "btcnode",
      id: "pnodeID1",
      useSSL: true,
      enabled: true,
      coinName: "bitcoin",
      isFailover: true,
      isDown: false,
    );
    final nodeB = NodeModel(
      host: "host2",
      port: 422,
      name: "btcnode",
      id: "pnodeID2",
      useSSL: true,
      enabled: true,
      coinName: "monero",
      isFailover: true,
      isDown: false,
    );
    final nodeC = NodeModel(
      host: "host3",
      port: 423,
      name: "btcnode",
      id: "pnodeID3",
      useSSL: true,
      enabled: true,
      coinName: "epicCash",
      isFailover: true,
      isDown: false,
    );

    setUp(() async {
      await NodeService(secureStorageInterface: FakeSecureStorage())
          .updateDefaults();
    });

    test("setPrimaryNodeFor and getPrimaryNodeFor", () async {
      final fakeStore = FakeSecureStorage();
      final service = NodeService(secureStorageInterface: fakeStore);
      expect(service.getPrimaryNodeFor(coin: Coin.bitcoin), null);
      await service.setPrimaryNodeFor(
          coin: Coin.bitcoin, node: DefaultNodes.bitcoin);
      expect(service.getPrimaryNodeFor(coin: Coin.bitcoin).toString(),
          DefaultNodes.bitcoin.toString());
      expect(fakeStore.interactions, 0);
    });

    test("get primary nodes", () async {
      final fakeStore = FakeSecureStorage();
      final service = NodeService(secureStorageInterface: fakeStore);
      await service.setPrimaryNodeFor(
          coin: Coin.bitcoin, node: DefaultNodes.bitcoin);
      await service.setPrimaryNodeFor(
          coin: Coin.monero, node: DefaultNodes.monero);
      expect(service.primaryNodes.toString(),
          [DefaultNodes.bitcoin, DefaultNodes.monero].toString());
      expect(fakeStore.interactions, 0);
    });

    test("get nodes", () async {
      final fakeStore = FakeSecureStorage();
      final service = NodeService(secureStorageInterface: fakeStore);
      final nodes = service.nodes;
      final defaults = DefaultNodes.all;

      nodes.sort((a, b) => a.host.compareTo(b.host));
      defaults.sort((a, b) => a.host.compareTo(b.host));

      expect(nodes.length, defaults.length);
      expect(nodes.toString(), defaults.toString());
      expect(fakeStore.interactions, 0);
    });

    test("add a node without a password", () async {
      final fakeStore = FakeSecureStorage();
      final service = NodeService(secureStorageInterface: fakeStore);
      await service.add(nodeA, null, true);
      expect(service.nodes.length, DefaultNodes.all.length + 1);
      expect(fakeStore.interactions, 0);
    });

    test("add a node with a password", () async {
      final fakeStore = FakeSecureStorage();
      final service = NodeService(secureStorageInterface: fakeStore);
      await service.add(nodeA, "some password", true);
      expect(service.nodes.length, DefaultNodes.all.length + 1);
      expect(fakeStore.interactions, 1);
      expect(fakeStore.writes, 1);
    });

    group("Additional nodes in storage tests", () {
      setUp(() async {
        await DB.instance.put<NodeModel>(
            boxName: DB.boxNameNodeModels, key: nodeA.id, value: nodeA);
        await DB.instance.put<NodeModel>(
            boxName: DB.boxNameNodeModels, key: nodeB.id, value: nodeB);
        await DB.instance.put<NodeModel>(
            boxName: DB.boxNameNodeModels, key: nodeC.id, value: nodeC);
      });

      test("edit a node with a password", () async {
        final fakeStore = FakeSecureStorage();
        final service = NodeService(secureStorageInterface: fakeStore);
        final currentLength = service.nodes.length;

        final editedNode = nodeA.copyWith(name: "Some new kind of name");

        await service.edit(editedNode, "123456", true);

        expect(service.nodes.length, currentLength);

        expect(service.getNodeById(id: nodeA.id).toString(),
            editedNode.toString());
        expect(
            (await service.getNodeById(id: nodeA.id)!.getPassword(fakeStore))!,
            "123456");

        expect(fakeStore.interactions, 2);
        expect(fakeStore.reads, 1);
        expect(fakeStore.writes, 1);
      });

      test("delete a node", () async {
        final fakeStore = FakeSecureStorage();
        final service = NodeService(secureStorageInterface: fakeStore);

        await service.delete(nodeB.id, true);

        expect(service.nodes.length, DefaultNodes.all.length + 2);
        expect(
            service.nodes.where((element) => element.id == nodeB.id).length, 0);

        expect(fakeStore.interactions, 1);
        expect(fakeStore.deletes, 1);
      });

      test("set enabled", () async {
        final fakeStore = FakeSecureStorage();
        final service = NodeService(secureStorageInterface: fakeStore);

        final preString = nodeC.toString();

        await service.setEnabledState(nodeC.id, false, true);

        final updatedNode = service.getNodeById(id: nodeC.id);

        expect(preString == updatedNode.toString(), false);
        expect(updatedNode!.enabled, false);

        expect(fakeStore.interactions, 0);
      });
    });
  });

  tearDown(() async {
    await tearDownTestHive();
  });
}

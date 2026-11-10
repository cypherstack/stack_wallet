import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:stackwallet/db/db_version_migration.dart';
import 'package:stackwallet/db/hive/db.dart';
import 'package:stackwallet/db/isar/main_db.dart';
import 'package:stackwallet/models/isar/models/ethereum/eth_contract.dart';
import 'package:stackwallet/models/node_model.dart';
import 'package:stackwallet/utilities/constants.dart';
import 'package:stackwallet/utilities/default_eth_tokens.dart';
import 'package:stackwallet/utilities/flutter_secure_storage_interface.dart';
import 'package:stackwallet/wallets/crypto_currency/crypto_currency.dart';

import 'hive/hive_ce_test_utils.dart';

void main() {
  test('v17 adds rsFIRO once and preserves the token catalog', () async {
    await setUpHiveCeTest();
    addTearDown(tearDownHiveCeTest);
    final info = await DB.instance.hive.openBox<dynamic>(DB.boxNameDBInfo);
    final directory = await Directory.systemTemp.createTemp(
      'rsfiro_migration_',
    );
    addTearDown(() => directory.delete(recursive: true));
    await Isar.initializeIsarCore(download: true);
    final isar = await Isar.open(
      [EthContractSchema],
      directory: directory.path,
      inspector: false,
    );
    addTearDown(() => isar.close(deleteFromDisk: true));
    final db = MainDB.instance;
    await db.initMainDB(mock: isar);
    Future<void> migrate(int version) =>
        DbVersionMigrator().migrate(version, secureStore: FakeSecureStorage());

    await migrate(16);
    expect(Constants.currentDataVersion, 18);
    expect(info.get('hive_data_version'), 18);
    expect(await db.getEthContracts().isEmpty(), isTrue);

    final custom = DefaultTokens.usdc.copyWith(name: 'Custom token');
    await db.putEthContract(custom);
    await migrate(16);
    expect(await db.getEthContracts().count(), 2);
    expect((await db.getEthContract(custom.address))!.name, 'Custom token');

    final existing = (await db.getEthContract(DefaultTokens.rsFiro.address))!
        .copyWith(
          address: DefaultTokens.rsFiro.address.toUpperCase(),
          abi: 'keep',
        );
    await db.putEthContract(existing);
    await migrate(16);
    expect(await db.getEthContracts().count(), 2);
    expect((await db.getEthContract(existing.address))!.abi, 'keep');

    await isar.writeTxn(() => isar.ethContracts.delete(existing.id));
    await migrate(info.get('hive_data_version') as int);
    expect(await db.getEthContracts().count(), 1);
  });

  test('v18 lets the default Fact0rn node use Tor', () async {
    await setUpHiveCeTest();
    addTearDown(tearDownHiveCeTest);
    final adapter = NodeModelAdapter();
    if (!DB.instance.hive.isAdapterRegistered(adapter.typeId)) {
      DB.instance.hive.registerAdapter(adapter);
    }
    final info = await DB.instance.hive.openBox<dynamic>(DB.boxNameDBInfo);
    final nodes = await DB.instance.hive.openBox<NodeModel>(
      DB.boxNameNodeModels,
    );
    NodeModel clearOnly(CryptoCurrency coin) => coin
        .defaultNode(isPrimary: true)
        .copyWith(loginName: null, trusted: null, torEnabled: false);
    final fact0rn = clearOnly(Fact0rn(CryptoCurrencyNetwork.main));
    final bitcoin = clearOnly(Bitcoin(CryptoCurrencyNetwork.main));
    await nodes.put(fact0rn.id, fact0rn);
    await nodes.put(bitcoin.id, bitcoin);

    await DbVersionMigrator().migrate(17, secureStore: FakeSecureStorage());

    expect(info.get('hive_data_version'), 18);
    expect(nodes.get(fact0rn.id)!.torEnabled, isTrue);
    expect(nodes.get(fact0rn.id)!.clearnetEnabled, isTrue);
    expect(nodes.get(fact0rn.id)!.isPrimary, isTrue);
    expect(nodes.get(bitcoin.id)!.torEnabled, isFalse);
  });

  test('v18 leaves an edited Fact0rn default node alone', () async {
    await setUpHiveCeTest();
    addTearDown(tearDownHiveCeTest);
    final adapter = NodeModelAdapter();
    if (!DB.instance.hive.isAdapterRegistered(adapter.typeId)) {
      DB.instance.hive.registerAdapter(adapter);
    }
    await DB.instance.hive.openBox<dynamic>(DB.boxNameDBInfo);
    final nodes = await DB.instance.hive.openBox<NodeModel>(
      DB.boxNameNodeModels,
    );
    final shipped = Fact0rn(CryptoCurrencyNetwork.main)
        .defaultNode(isPrimary: true)
        .copyWith(loginName: null, trusted: null, torEnabled: false);
    final edited = [
      shipped.copyWith(loginName: null, trusted: null, isFailover: false),
      shipped.copyWith(loginName: null, trusted: null, host: "example.com"),
      shipped.copyWith(loginName: null, trusted: null, port: 50001),
      shipped.copyWith(loginName: null, trusted: null, useSSL: false),
      shipped.copyWith(loginName: null, trusted: null, name: "Mine"),
      shipped.copyWith(loginName: "user", trusted: null),
    ];

    for (final node in edited) {
      await nodes.put(node.id, node);
      await DbVersionMigrator().migrate(17, secureStore: FakeSecureStorage());
      expect(nodes.get(node.id)!.torEnabled, isFalse, reason: "$node");
    }
  });
}

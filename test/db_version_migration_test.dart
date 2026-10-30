import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:stackwallet/db/db_version_migration.dart';
import 'package:stackwallet/db/hive/db.dart';
import 'package:stackwallet/db/isar/main_db.dart';
import 'package:stackwallet/models/isar/models/ethereum/eth_contract.dart';
import 'package:stackwallet/utilities/constants.dart';
import 'package:stackwallet/utilities/default_eth_tokens.dart';
import 'package:stackwallet/utilities/flutter_secure_storage_interface.dart';

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
    expect(Constants.currentDataVersion, 17);
    expect(info.get('hive_data_version'), 17);
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
}

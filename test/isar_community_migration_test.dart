import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/transaction.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/v2/transaction_v2.dart';
import 'package:stackwallet/models/isar/models/log.dart';
import 'package:stackwallet/utilities/enums/log_level_enum.dart';

Future<String> _isarCoreLibraryPath() async {
  final packageConfigFile = File('.dart_tool/package_config.json');
  final packageConfig =
      jsonDecode(await packageConfigFile.readAsString())
          as Map<String, dynamic>;
  final packages = packageConfig['packages'] as List<dynamic>;
  final package = packages.cast<Map<String, dynamic>?>().firstWhere(
    (entry) => entry?['name'] == 'isar_community_flutter_libs',
    orElse: () => null,
  );
  if (package == null) {
    throw StateError('Could not resolve isar_community_flutter_libs');
  }

  final libraryRelativePath = switch (Platform.operatingSystem) {
    'macos' => 'macos/libisar.dylib',
    'linux' => 'linux/libisar.so',
    'windows' => 'windows/libisar.dll',
    final platform => throw UnsupportedError(
      'Isar migration test is not supported on $platform',
    ),
  };

  final resolvedPackageRoot = packageConfigFile.uri.resolve(
    package['rootUri'] as String,
  );
  final packageRoot = resolvedPackageRoot.replace(
    path: '${resolvedPackageRoot.path}/',
  );
  return File.fromUri(packageRoot.resolve(libraryRelativePath)).path;
}

void main() {
  test('opens and updates an Isar 3.3.0-dev.2 database with 3.3.2', () async {
    final temporaryDirectory = await Directory.systemTemp.createTemp(
      'stack-wallet-isar-migration-',
    );
    Isar? isar;

    try {
      await Isar.initializeIsarCore(
        libraries: {Abi.current(): await _isarCoreLibraryPath()},
      );

      final fixture = File(
        'test/fixtures/isar_3_3_0_dev_2/'
        'isar_3_3_0_dev_2_log.isar.gz',
      );
      final fixtureBytes = await fixture.readAsBytes();
      expect(
        sha256.convert(fixtureBytes).toString(),
        'c7bd6db8215a61d888c78c42a18b10541274d340c3c5377a5424bdcb595ad126',
        reason: 'The migration fixture must only change intentionally',
      );
      final databaseFile = File(
        '${temporaryDirectory.path}/isar_3_3_0_dev_2_log.isar',
      );
      await databaseFile.writeAsBytes(gzip.decode(fixtureBytes), flush: true);

      isar = await Isar.open(
        [LogSchema],
        directory: temporaryDirectory.path,
        name: 'isar_3_3_0_dev_2_log',
      );
      // ignore: experimental_member_use
      await isar.verify();

      final migratedLog = await isar.logs
          .where()
          .timestampInMillisUTCEqualTo(1722470400000)
          .findFirst();
      expect(migratedLog, isNotNull);
      expect(migratedLog!.message, 'created by isar_community 3.3.0-dev.2');
      expect(migratedLog.logLevel, LogLevel.Warning);

      await isar.writeTxn(() async {
        await isar!.logs.put(
          Log()
            ..message = 'written by isar_community 3.3.2'
            ..timestampInMillisUTC = 1722470401000
            ..logLevel = LogLevel.Info,
        );
      });
      await isar.close();
      isar = null;

      isar = await Isar.open(
        [LogSchema],
        directory: temporaryDirectory.path,
        name: 'isar_3_3_0_dev_2_log',
      );
      // ignore: experimental_member_use
      await isar.verify();
      expect(await isar.logs.count(), 2);
    } finally {
      await isar?.close();
      await temporaryDirectory.delete(recursive: true);
    }
  });

  test(
    'opens and updates an Isar 3.3.0-dev.2 wallet database with 3.3.2',
    () async {
      final temporaryDirectory = await Directory.systemTemp.createTemp(
        'stack-wallet-isar-wallet-migration-',
      );
      Isar? isar;

      try {
        await Isar.initializeIsarCore(
          libraries: {Abi.current(): await _isarCoreLibraryPath()},
        );

        final fixture = File(
          'test/fixtures/isar_3_3_0_dev_2/'
          'isar_3_3_0_dev_2_wallet_data.isar.gz',
        );
        final fixtureBytes = await fixture.readAsBytes();
        expect(
          sha256.convert(fixtureBytes).toString(),
          '6a0ce2f29c58875985d32253acb54469632fd55111812c39e1a41a87cf93f22a',
          reason: 'The migration fixture must only change intentionally',
        );
        final databaseFile = File(
          '${temporaryDirectory.path}/isar_3_3_0_dev_2_wallet_data.isar',
        );
        await databaseFile.writeAsBytes(gzip.decode(fixtureBytes), flush: true);

        isar = await Isar.open(
          [TransactionV2Schema],
          directory: temporaryDirectory.path,
          name: 'isar_3_3_0_dev_2_wallet_data',
        );
        // ignore: experimental_member_use
        await isar.verify();

        final migratedTransaction = await isar.transactionV2s
            .where()
            .txidWalletIdEqualTo('migration-transaction', 'migration-wallet')
            .findFirst();
        expect(migratedTransaction, isNotNull);
        expect(migratedTransaction!.type, TransactionType.outgoing);
        expect(migratedTransaction.nonce, 7);
        expect(migratedTransaction.inputs.single.valueStringSats, '101');
        expect(
          migratedTransaction.inputs.single.outpoint!.txid,
          'previous-transaction',
        );
        expect(migratedTransaction.outputs.single.valueStringSats, '100');
        expect(migratedTransaction.outputs.single.addresses, ['xel:recipient']);

        await isar.writeTxn(() async {
          await isar!.transactionV2s.put(
            TransactionV2(
              walletId: 'migration-wallet',
              blockHash: 'current-block-hash',
              hash: 'current-transaction',
              txid: 'current-transaction',
              timestamp: 1722470401,
              height: 43,
              inputs: const [],
              outputs: const [],
              version: -1,
              type: TransactionType.incoming,
              subType: TransactionSubType.none,
              otherData: jsonEncode({'nonce': 8}),
            ),
          );
        });
        await isar.close();
        isar = null;

        isar = await Isar.open(
          [TransactionV2Schema],
          directory: temporaryDirectory.path,
          name: 'isar_3_3_0_dev_2_wallet_data',
        );
        // ignore: experimental_member_use
        await isar.verify();
        expect(await isar.transactionV2s.count(), 2);
      } finally {
        await isar?.close();
        await temporaryDirectory.delete(recursive: true);
      }
    },
  );
}

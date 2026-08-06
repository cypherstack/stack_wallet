import 'dart:ffi';
import 'dart:io';

import 'package:isar_community/isar.dart';
import 'package:stack_wallet_isar_fixture_generator/log.dart';
import 'package:stack_wallet_isar_fixture_generator/transaction_v2.dart';

Future<void> main(List<String> args) async {
  if (args.length != 2) {
    stderr.writeln('Usage: generate <output-directory> <isar-core-library>');
    exitCode = 64;
    return;
  }

  final outputDirectory = Directory(args[0])..createSync(recursive: true);
  await Isar.initializeIsarCore(libraries: {Abi.current(): args[1]});

  await _generateLogFixture(outputDirectory);
  await _generateWalletDataFixture(outputDirectory);
}

Future<void> _generateLogFixture(Directory outputDirectory) async {
  const databaseName = 'isar_3_3_0_dev_2_log';
  final isar = await Isar.open(
    [LogSchema],
    directory: outputDirectory.path,
    name: databaseName,
  );
  await isar.writeTxn(() async {
    await isar.logs.put(
      Log()
        ..message = 'created by isar_community 3.3.0-dev.2'
        ..timestampInMillisUTC = 1722470400000
        ..logLevel = LogLevel.Warning,
    );
  });
  await isar.close();

  await _compressDatabase(outputDirectory, databaseName);
}

Future<void> _generateWalletDataFixture(Directory outputDirectory) async {
  const databaseName = 'isar_3_3_0_dev_2_wallet_data';
  final isar = await Isar.open(
    [TransactionV2Schema],
    directory: outputDirectory.path,
    name: databaseName,
  );
  await isar.writeTxn(() async {
    final outpoint = OutpointV2()
      ..txid = 'previous-transaction'
      ..vout = 1;
    final input = InputV2()
      ..scriptSigHex = '00'
      ..scriptSigAsm = null
      ..sequence = 42
      ..outpoint = outpoint
      ..addresses = ['xel:sender']
      ..valueStringSats = '101'
      ..coinbase = null
      ..witness = null
      ..innerRedeemScriptAsm = null
      ..walletOwns = true;
    final output = OutputV2()
      ..scriptPubKeyHex = '51'
      ..scriptPubKeyAsm = null
      ..valueStringSats = '100'
      ..addresses = ['xel:recipient']
      ..walletOwns = false;

    await isar.transactionV2s.put(
      TransactionV2(
        walletId: 'migration-wallet',
        blockHash: 'block-hash',
        hash: 'migration-transaction',
        txid: 'migration-transaction',
        timestamp: 1722470400,
        height: 42,
        inputs: [input],
        outputs: [output],
        version: -1,
        type: TransactionType.outgoing,
        subType: TransactionSubType.none,
        otherData: '{"nonce":7}',
      ),
    );
  });
  await isar.close();

  await _compressDatabase(outputDirectory, databaseName);
}

Future<void> _compressDatabase(
  Directory outputDirectory,
  String databaseName,
) async {
  final databaseFile = File('${outputDirectory.path}/$databaseName.isar');
  final compressedFile = File('${databaseFile.path}.gz');
  await compressedFile.writeAsBytes(
    gzip.encode(await databaseFile.readAsBytes()),
    flush: true,
  );
  await databaseFile.delete();

  final lockFile = File('${databaseFile.path}-lck');
  if (await lockFile.exists()) {
    await lockFile.delete();
  }
}

import 'dart:async';
import 'dart:io';

import 'package:hive_ce/hive.dart';
import 'package:stackwallet/db/hive/db.dart';

const _helperPath = 'test/hive/hive_ce_test_utils.dart';
const _defaultHiveCeTestTimeout = Duration(seconds: 15);

Directory? _testHiveDirectory;

Future<void> setUpHiveCeTest({
  Duration timeout = _defaultHiveCeTestTimeout,
}) async {
  if (_testHiveDirectory != null) {
    throw StateError(
      '$_helperPath [init]: previous Hive CE temp directory '
      '"${_testHiveDirectory!.path}" was not cleaned up before reinitialization.',
    );
  }

  try {
    await (() async {
      final tempDirectory = await Directory.systemTemp.createTemp(
        'stack_wallet_hive_ce_test_',
      );
      Hive.init(tempDirectory.path);
      DB.instance.hive.init(tempDirectory.path);
      _testHiveDirectory = tempDirectory;
    })().timeout(
      timeout,
      onTimeout: () => throw TimeoutException(
        '$_helperPath [init]: timed out after ${timeout.inSeconds}s.',
      ),
    );
  } catch (error, stackTrace) {
    final tempDirectory = _testHiveDirectory;
    _testHiveDirectory = null;

    if (tempDirectory != null && await tempDirectory.exists()) {
      await tempDirectory.delete(recursive: true);
    }

    Error.throwWithStackTrace(
      StateError('$_helperPath [init]: $error'),
      stackTrace,
    );
  }
}

Future<void> tearDownHiveCeTest({
  Duration timeout = _defaultHiveCeTestTimeout,
}) async {
  final tempDirectory = _testHiveDirectory;
  if (tempDirectory == null) {
    throw StateError(
      '$_helperPath [cleanup]: called before setUpHiveCeTest().',
    );
  }

  _testHiveDirectory = null;

  try {
    await (() async {
      await DB.instance.hive.close();
      await Hive.close();
      if (await tempDirectory.exists()) {
        await tempDirectory.delete(recursive: true);
      }
    })().timeout(
      timeout,
      onTimeout: () => throw TimeoutException(
        '$_helperPath [cleanup]: timed out after ${timeout.inSeconds}s.',
      ),
    );
  } catch (error, stackTrace) {
    Error.throwWithStackTrace(
      StateError('$_helperPath [cleanup]: $error'),
      stackTrace,
    );
  }
}

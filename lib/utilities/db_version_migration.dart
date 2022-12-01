import 'package:epicmobile/utilities/flutter_secure_storage_interface.dart';
import 'package:epicmobile/utilities/logger.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class DbVersionMigrator {
  Future<void> migrate(
    int fromVersion, {
    FlutterSecureStorageInterface secureStore = const SecureStorageWrapper(
      FlutterSecureStorage(),
    ),
  }) async {
    Logging.instance.log(
      "Running migrate fromVersion $fromVersion",
      level: LogLevel.Warning,
    );
    switch (fromVersion) {
      default:
        // finally return
        return;
    }
  }
}

import 'package:stackwallet/db/isar/main_db.dart';
import 'package:stackwallet/utilities/flutter_secure_storage_interface.dart';

class WalletsService {
  late final SecureStorageInterface _secureStore;
  late final MainDB _mainDB;

  WalletsService({
    required SecureStorageInterface secureStorageInterface,
    required MainDB mainDB,
  }) {
    _secureStore = secureStorageInterface;
    _mainDB = mainDB;
  }
}

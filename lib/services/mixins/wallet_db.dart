import 'package:stackwallet/db/isar/main_db.dart';

mixin WalletDB {
  MainDB? _db;
  MainDB get db => _db!;

  void initWalletDB({MainDB? mockableOverride}) async {
    _db = mockableOverride ?? MainDB.instance;
  }
}

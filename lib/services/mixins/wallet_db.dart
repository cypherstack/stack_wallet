import 'package:stackwallet/db/main_db.dart';

mixin WalletDB {
  MainDB? _db;
  MainDB get db => _db!;

  void isarInit({MainDB? mockableOverride}) async {
    _db = mockableOverride ?? MainDB.instance;
  }
}

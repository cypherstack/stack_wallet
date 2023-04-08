import 'package:stackwallet/db/hive/db.dart';

mixin FiroHive {
  late final String _walletId;

  void initFiroHive(String walletId) {
    _walletId = walletId;
  }

  // jindex
  List? firoGetJIndex() {
    return DB.instance.get<dynamic>(boxName: _walletId, key: "jindex") as List?;
  }

  Future<void> firoUpdateJIndex(List jIndex) async {
    await DB.instance.put<dynamic>(
      boxName: _walletId,
      key: "jindex",
      value: jIndex,
    );
  }

  // _lelantus_coins
  List? firoGetLelantusCoins() {
    return DB.instance.get<dynamic>(boxName: _walletId, key: "_lelantus_coins")
        as List?;
  }

  Future<void> firoUpdateLelantusCoins(List lelantusCoins) async {
    await DB.instance.put<dynamic>(
      boxName: _walletId,
      key: "_lelantus_coins",
      value: lelantusCoins,
    );
  }

  // mintIndex
  int? firoGetMintIndex() {
    return DB.instance.get<dynamic>(boxName: _walletId, key: "mintIndex")
        as int?;
  }

  Future<void> firoUpdateMintIndex(int mintIndex) async {
    await DB.instance.put<dynamic>(
      boxName: _walletId,
      key: "mintIndex",
      value: mintIndex,
    );
  }
}

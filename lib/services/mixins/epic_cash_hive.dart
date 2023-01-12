import 'package:stackwallet/hive/db.dart';

mixin EpicCashHive {
  late final String _walletId;

  void initEpicCashHive(String walletId) {
    _walletId = walletId;
  }

  // receiving index
  int? epicGetReceivingIndex() {
    return DB.instance.get<dynamic>(boxName: _walletId, key: "receivingIndex")
        as int?;
  }

  Future<void> epicUpdateReceivingIndex(int index) async {
    await DB.instance.put<dynamic>(
      boxName: _walletId,
      key: "receivingIndex",
      value: index,
    );
  }

  // change index
  int? epicGetChangeIndex() {
    return DB.instance.get<dynamic>(boxName: _walletId, key: "changeIndex")
        as int?;
  }

  Future<void> epicUpdateChangeIndex(int index) async {
    await DB.instance.put<dynamic>(
      boxName: _walletId,
      key: "changeIndex",
      value: index,
    );
  }

  // slateToAddresses
  Map epicGetSlatesToAddresses() {
    return DB.instance.get<dynamic>(
          boxName: _walletId,
          key: "slate_to_address",
        ) as Map? ??
        {};
  }

  Future<void> epicUpdateSlatesToAddresses(Map map) async {
    await DB.instance.put<dynamic>(
      boxName: _walletId,
      key: "slate_to_address",
      value: map,
    );
  }

  // slatesToCommits
  Map? epicGetSlatesToCommits() {
    return DB.instance.get<dynamic>(
      boxName: _walletId,
      key: "slatesToCommits",
    ) as Map?;
  }

  Future<void> epicUpdateSlatesToCommits(Map map) async {
    await DB.instance.put<dynamic>(
      boxName: _walletId,
      key: "slatesToCommits",
      value: map,
    );
  }

  // last scanned block
  int? epicGetLastScannedBlock() {
    return DB.instance.get<dynamic>(boxName: _walletId, key: "lastScannedBlock")
        as int?;
  }

  Future<void> epicUpdateLastScannedBlock(int blockHeight) async {
    await DB.instance.put<dynamic>(
      boxName: _walletId,
      key: "lastScannedBlock",
      value: blockHeight,
    );
  }

  // epic restore height
  int? epicGetRestoreHeight() {
    return DB.instance.get<dynamic>(boxName: _walletId, key: "restoreHeight")
        as int?;
  }

  Future<void> epicUpdateRestoreHeight(int height) async {
    await DB.instance.put<dynamic>(
      boxName: _walletId,
      key: "restoreHeight",
      value: height,
    );
  }

  // epic creation height
  int? epicGetCreationHeight() {
    return DB.instance.get<dynamic>(boxName: _walletId, key: "creationHeight")
        as int?;
  }

  Future<void> epicUpdateCreationHeight(int height) async {
    await DB.instance.put<dynamic>(
      boxName: _walletId,
      key: "creationHeight",
      value: height,
    );
  }
}

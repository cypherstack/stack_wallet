import 'package:stackwallet/db/hive/db.dart';
import 'package:stackwallet/models/ethereum/eth_token.dart';

mixin EthExtrasWalletCache {
  late final String _walletId;

  void initEthExtrasCache(String walletId) {
    _walletId = walletId;
  }

  // cached list of user added token contracts
  Set<EthContractInfo> getCachedTokenContracts() {
    final list = DB.instance.get<dynamic>(
          boxName: _walletId,
          key: "ethTokenContracts",
        ) as List<String>? ??
        [];
    return list.map((e) => EthContractInfo.fromJson(e)!).toSet();
  }

  Future<void> updateCachedTokenContracts(
      Set<EthContractInfo> contracts) async {
    await DB.instance.put<dynamic>(
      boxName: _walletId,
      key: "ethTokenContracts",
      value: contracts.map((e) => e.toJson()).toList(),
    );
  }
}

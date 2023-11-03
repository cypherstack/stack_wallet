import 'package:stackwallet/models/paymint/fee_object_model.dart';
import 'package:stackwallet/pages/settings_views/global_settings_view/manage_nodes_views/add_edit_node_view.dart';
import 'package:stackwallet/services/node_service.dart';
import 'package:stackwallet/utilities/amount/amount.dart';
import 'package:stackwallet/utilities/logger.dart';
import 'package:stackwallet/utilities/test_epic_box_connection.dart';
import 'package:stackwallet/wallets/models/tx_data.dart';
import 'package:stackwallet/wallets/wallet/bip39_wallet.dart';

class EpiccashWallet extends Bip39Wallet {
  final NodeService nodeService;

  EpiccashWallet(super.cryptoCurrency, {required this.nodeService});

  @override
  Future<TxData> confirmSend({required TxData txData}) {
    // TODO: implement confirmSend
    throw UnimplementedError();
  }

  @override
  Future<TxData> prepareSend({required TxData txData}) {
    // TODO: implement prepareSend
    throw UnimplementedError();
  }

  @override
  Future<void> recover({required bool isRescan}) {
    // TODO: implement recover
    throw UnimplementedError();
  }

  @override
  Future<void> refresh() {
    // TODO: implement refresh
    throw UnimplementedError();
  }

  @override
  Future<void> updateBalance() {
    // TODO: implement updateBalance
    throw UnimplementedError();
  }

  @override
  Future<void> updateTransactions() {
    // TODO: implement updateTransactions
    throw UnimplementedError();
  }

  @override
  Future<void> updateUTXOs() {
    // TODO: implement updateUTXOs
    throw UnimplementedError();
  }

  @override
  Future<void> updateNode() {
    // TODO: implement updateNode
    throw UnimplementedError();
  }

  @override
  Future<bool> pingCheck() async {
    try {
      final node = nodeService.getPrimaryNodeFor(coin: cryptoCurrency.coin);

      // force unwrap optional as we want connection test to fail if wallet
      // wasn't initialized or epicbox node was set to null
      return await testEpicNodeConnection(
            NodeFormData()
              ..host = node!.host
              ..useSSL = node.useSSL
              ..port = node.port,
          ) !=
          null;
    } catch (e, s) {
      Logging.instance.log("$e\n$s", level: LogLevel.Info);
      return false;
    }
  }

  @override
  Future<void> updateChainHeight() async {
    // final height = await fetchChainHeight();
    // await walletInfo.updateCachedChainHeight(
    //   newHeight: height,
    //   isar: mainDB.isar,
    // );
  }

  @override
  Future<Amount> estimateFeeFor(Amount amount, int feeRate) {
    // TODO: implement estimateFeeFor
    throw UnimplementedError();
  }

  @override
  // TODO: implement fees
  Future<FeeObject> get fees => throw UnimplementedError();
}

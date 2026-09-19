//ON
import 'package:flutter_libepiccash/epic_cash.dart' as epc;
import 'package:flutter_libepiccash/git_versions.dart' as epic_versions;
import 'package:flutter_libepiccash/lib.dart';
import 'package:flutter_libepiccash/models/transaction.dart';

//END_ON
import '../../utilities/dynamic_object.dart';
import '../interfaces/libepiccash_interface.dart';

LibEpicCashInterface get libEpic => _getLib();

//OFF
LibEpicCashInterface _getLib() => throw Exception("EPIC not enabled!");

//END_OFF
//ON
LibEpicCashInterface _getLib() => const _LibEpicCashInterfaceImpl();

final class _LibEpicCashInterfaceImpl extends LibEpicCashInterface {
  const _LibEpicCashInterfaceImpl();

  @override
  Future<String> cancelTransaction({
    required DynamicObject wallet,
    required String transactionId,
  }) {
    return wallet.get<EpicWallet>().cancelTransaction(
      transactionId: transactionId,
    );
  }

  @override
  Future<({String slateId, String commitId, String slateJson})> txReceive({
    required DynamicObject wallet,
    required String slateJson,
  }) async {
    return (await wallet.get<EpicWallet>().txReceive(
      slateJson: slateJson,
    )).toRecord();
  }

  @override
  Future<({String slateId, String commitId, String slateJson})> txFinalize({
    required DynamicObject wallet,
    required String slateJson,
  }) async {
    return (await wallet.get<EpicWallet>().txFinalize(
      slateJson: slateJson,
    )).toRecord();
  }

  @override
  Future<({String commitId, String slateId, String slateJson})>
  createTransaction({
    required DynamicObject wallet,
    required int amount,
    required String address,
    required int secretKeyIndex,
    required int minimumConfirmations,
    required String note,
    bool returnSlate = false,
  }) async {
    return (await wallet.get<EpicWallet>().createTransaction(
      amount: amount,
      address: address,
      secretKeyIndex: secretKeyIndex,
      minimumConfirmations: minimumConfirmations,
      note: note,
      returnSlate: returnSlate,
    )).toRecord();
  }

  @override
  void updateEpicboxConfig({
    required DynamicObject wallet,
    required String epicBoxConfig,
  }) {
    return wallet.get<EpicWallet>().updateEpicboxConfig(epicBoxConfig);
  }

  @override
  void updateConfig({required DynamicObject wallet, required String config}) {
    return wallet.get<EpicWallet>().updateConfig(config);
  }

  @override
  Future<String> deleteWallet({required String config}) {
    return EpicWallet.deleteWallet(config: config);
  }

  @override
  Future<String> getAddressInfo({
    required DynamicObject wallet,
    required int index,
    required String epicboxConfig,
  }) {
    return wallet.get<EpicWallet>().getAddressInfo(index: index);
  }

  @override
  Future<int> getChainHeight({required String config}) {
    return LibEpiccash.getChainHeight(config: config);
  }

  @override
  Future<({int fee, bool strategyUseAll, int total})> getTransactionFees({
    required DynamicObject wallet,
    required int amount,
    required int minimumConfirmations,
  }) {
    return wallet.get<EpicWallet>().getTransactionFees(
      amount: amount,
      minimumConfirmations: minimumConfirmations,
    );
  }

  @override
  Future<List<EpicTransaction>> getTransactions({
    required DynamicObject wallet,
    required int refreshFromNode,
  }) async {
    final transactions = await wallet.get<EpicWallet>().getTransactions(
      refreshFromNode: refreshFromNode,
    );

    return transactions
        .map(
          (e) => EpicTransaction(
            parentKeyId: e.parentKeyId,
            id: e.id,
            txType: e.txType,
            creationTs: e.creationTs,
            confirmationTs: e.confirmationTs,
            confirmed: e.confirmed,
            numInputs: e.numInputs,
            numOutputs: e.numOutputs,
            amountCredited: e.amountCredited,
            amountDebited: e.amountDebited,
            txSlateId: e.txSlateId,
            fee: e.fee,
            ttlCutoffHeight: e.ttlCutoffHeight,
            messages: e.messages?.messages
                .map(
                  (f) => EpicMessage(
                    id: f.id,
                    publicKey: f.publicKey,
                    message: f.message,
                    messageSig: f.messageSig,
                  ),
                )
                .toList(),
            storedTx: e.storedTx,
            kernelExcess: e.kernelExcess,
            kernelLookupMinHeight: e.kernelLookupMinHeight,
            paymentProof: e.paymentProof,
          ),
        )
        .toList();
  }

  @override
  Future<
    ({
      double awaitingFinalization,
      double pending,
      double spendable,
      double total,
    })
  >
  getWalletBalances({
    required DynamicObject wallet,
    required int refreshFromNode,
    required int minimumConfirmations,
  }) {
    return wallet.get<EpicWallet>().getBalancesRecord(
      refreshFromNode: refreshFromNode,
      minimumConfirmations: minimumConfirmations,
    );
  }

  @override
  Future<DynamicObject> initializeNewWallet({
    required String config,
    required String mnemonic,
    required String password,
    required String name,
    required String epicBoxConfig,
  }) async {
    final wallet = await EpicWallet.create(
      config: config,
      mnemonic: mnemonic,
      password: password,
      name: name,
      epicboxConfig: epicBoxConfig,
    );

    return DynamicObject(wallet);
  }

  @override
  Future<DynamicObject> openWallet({
    required String config,
    required String password,
    required String epicboxConfig,
  }) async {
    final wallet = await EpicWallet.load(
      config: config,
      password: password,
      epicboxConfig: epicboxConfig,
    );

    return DynamicObject(wallet);
  }

  @override
  Future<DynamicObject> recoverWallet({
    required String config,
    required String password,
    required String mnemonic,
    required String name,
    required String epicBoxConfig,
  }) async {
    final wallet = await EpicWallet.recover(
      config: config,
      password: password,
      mnemonic: mnemonic,
      name: name,
      epicboxConfig: epicBoxConfig,
    );

    return DynamicObject(wallet);
  }

  @override
  Future<int> scanOutputs({
    required DynamicObject wallet,
    required int startHeight,
    required int numberOfBlocks,
  }) {
    return wallet.get<EpicWallet>().scanOutputs(
      startHeight: startHeight,
      numberOfBlocks: numberOfBlocks,
    );
  }

  @override
  Future<void> startEpicboxListener({required DynamicObject wallet}) {
    return wallet.get<EpicWallet>().startListener();
  }

  @override
  Future<void> stopEpicboxListener({required DynamicObject wallet}) {
    return wallet.get<EpicWallet>().stopListener();
  }

  @override
  Future<bool> isEpicboxListenerRunning({required DynamicObject wallet}) {
    return wallet.get<EpicWallet>().isEpicboxListenerRunning();
  }

  @override
  Future<({String commitId, String slateId})> txHttpSend({
    required DynamicObject wallet,
    required int selectionStrategyIsAll,
    required int minimumConfirmations,
    required String message,
    required int amount,
    required String address,
  }) {
    try {
      return wallet.get<EpicWallet>().txHttpSend(
        selectionStrategyIsAll: selectionStrategyIsAll,
        minimumConfirmations: minimumConfirmations,
        message: message,
        amount: amount,
        address: address,
      );
    } on BadEpicHttpAddressException catch (_) {
      throw BadHttpAddressException();
    }
  }

  @override
  bool txTypeIsReceiveCancelled(Enum value) {
    return value == TransactionType.TxReceivedCancelled;
  }

  @override
  bool txTypeIsReceived(Enum value) {
    return value == TransactionType.TxReceived;
  }

  @override
  bool txTypeIsSentCancelled(Enum value) {
    return value == TransactionType.TxSentCancelled;
  }

  @override
  Future<bool> validateSendAddress({required String address}) {
    return EpicWallet.validateSendAddress(address: address);
  }

  @override
  bool validateSendAddressSync({required String address}) {
    return epc.validateSendAddress(address) == "1"; //lol
  }

  @override
  Future<void> close({required DynamicObject wallet}) {
    return wallet.get<EpicWallet>().close();
  }

  @override
  String getPluginVersion() => epic_versions.getPluginVersion();
}

//END_ON

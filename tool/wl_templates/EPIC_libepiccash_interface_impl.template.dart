//ON
import 'package:flutter_libepiccash/git_versions.dart' as epic_versions;
import 'package:flutter_libepiccash/lib.dart';
import 'package:flutter_libepiccash/models/transaction.dart';

//END_ON
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
    required String wallet,
    required String transactionId,
  }) {
    return LibEpiccash.cancelTransaction(
      wallet: wallet,
      transactionId: transactionId,
    );
  }

  @override
  Future<({String commitId, String slateId})> createTransaction({
    required String wallet,
    required int amount,
    required String address,
    required int secretKeyIndex,
    required String epicboxConfig,
    required int minimumConfirmations,
    required String note,
  }) {
    return LibEpiccash.createTransaction(
      wallet: wallet,
      amount: amount,
      address: address,
      secretKeyIndex: secretKeyIndex,
      epicboxConfig: epicboxConfig,
      minimumConfirmations: minimumConfirmations,
      note: note,
    );
  }

  @override
  Future<String> deleteWallet({
    required String wallet,
    required String config,
  }) {
    return LibEpiccash.deleteWallet(wallet: wallet, config: config);
  }

  @override
  Future<String> getAddressInfo({
    required String wallet,
    required int index,
    required String epicboxConfig,
  }) {
    return LibEpiccash.getAddressInfo(
      wallet: wallet,
      index: index,
      epicboxConfig: epicboxConfig,
    );
  }

  @override
  Future<int> getChainHeight({required String config}) {
    return LibEpiccash.getChainHeight(config: config);
  }

  @override
  Future<({int fee, bool strategyUseAll, int total})> getTransactionFees({
    required String wallet,
    required int amount,
    required int minimumConfirmations,
    required int available,
  }) {
    return LibEpiccash.getTransactionFees(
      wallet: wallet,
      amount: amount,
      minimumConfirmations: minimumConfirmations,
      available: available,
    );
  }

  @override
  Future<List<EpicTransaction>> getTransactions({
    required String wallet,
    required int refreshFromNode,
  }) async {
    final transactions = await LibEpiccash.getTransactions(
      wallet: wallet,
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
    required String wallet,
    required int refreshFromNode,
    required int minimumConfirmations,
  }) {
    return LibEpiccash.getWalletBalances(
      wallet: wallet,
      refreshFromNode: refreshFromNode,
      minimumConfirmations: minimumConfirmations,
    );
  }

  @override
  Future<String> initializeNewWallet({
    required String config,
    required String mnemonic,
    required String password,
    required String name,
  }) {
    return LibEpiccash.initializeNewWallet(
      config: config,
      mnemonic: mnemonic,
      password: password,
      name: name,
    );
  }

  @override
  Future<String> openWallet({
    required String config,
    required String password,
  }) {
    return LibEpiccash.openWallet(config: config, password: password);
  }

  @override
  Future<void> recoverWallet({
    required String config,
    required String password,
    required String mnemonic,
    required String name,
  }) {
    return LibEpiccash.recoverWallet(
      config: config,
      password: password,
      mnemonic: mnemonic,
      name: name,
    );
  }

  @override
  Future<int> scanOutputs({
    required String wallet,
    required int startHeight,
    required int numberOfBlocks,
  }) {
    return LibEpiccash.scanOutputs(
      wallet: wallet,
      startHeight: startHeight,
      numberOfBlocks: numberOfBlocks,
    );
  }

  @override
  void startEpicboxListener({
    required String wallet,
    required String epicboxConfig,
  }) {
    return LibEpiccash.startEpicboxListener(
      wallet: wallet,
      epicboxConfig: epicboxConfig,
    );
  }

  @override
  void stopEpicboxListener() {
    return LibEpiccash.stopEpicboxListener();
  }

  @override
  Future<({String commitId, String slateId})> txHttpSend({
    required String wallet,
    required int selectionStrategyIsAll,
    required int minimumConfirmations,
    required String message,
    required int amount,
    required String address,
  }) {
    try {
      return LibEpiccash.txHttpSend(
        wallet: wallet,
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
  bool validateSendAddress({required String address}) {
    return LibEpiccash.validateSendAddress(address: address);
  }

  @override
  String getPluginVersion() => epic_versions.getPluginVersion();
}

//END_ON

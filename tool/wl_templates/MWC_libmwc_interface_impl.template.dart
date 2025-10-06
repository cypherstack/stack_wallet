//ON
import 'package:flutter_libmwc/git_versions.dart' as mimblewimblecoin_versions;
import 'package:flutter_libmwc/lib.dart' as mimblewimblecoin;
import 'package:flutter_libmwc/models/transaction.dart'
    as mimblewimblecoin_models;

//END_ON
import '../interfaces/libmwc_interface.dart';

LibMwcInterface get libMwc => _getLibMwc();

//OFF
LibMwcInterface _getLibMwc() => throw Exception("MWC not enabled!");

//END_OFF
//ON
LibMwcInterface _getLibMwc() => const _LibMwcInterfaceImpl();

final class _LibMwcInterfaceImpl extends LibMwcInterface {
  const _LibMwcInterfaceImpl();

  @override
  Future<String> cancelTransaction({
    required String wallet,
    required String transactionId,
  }) {
    return mimblewimblecoin.Libmwc.cancelTransaction(
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
    required String mwcmqsConfig,
    required int minimumConfirmations,
    required String note,
  }) {
    return mimblewimblecoin.Libmwc.createTransaction(
      wallet: wallet,
      amount: amount,
      address: address,
      secretKeyIndex: secretKeyIndex,
      mwcmqsConfig: mwcmqsConfig,
      minimumConfirmations: minimumConfirmations,
      note: note,
    );
  }

  @override
  Future<
    ({
      String? recipientAddress,
      String? senderAddress,
      String slateJson,
      bool wasEncrypted,
    })
  >
  decodeSlatepack({required String slatepack}) {
    return mimblewimblecoin.Libmwc.decodeSlatepack(slatepack: slatepack);
  }

  @override
  Future<
    ({
      String? recipientAddress,
      String? senderAddress,
      String slateJson,
      bool wasEncrypted,
    })
  >
  decodeSlatepackWithWallet({
    required String wallet,
    required String slatepack,
  }) {
    return mimblewimblecoin.Libmwc.decodeSlatepackWithWallet(
      wallet: wallet,
      slatepack: slatepack,
    );
  }

  @override
  Future<String> deleteWallet({
    required String wallet,
    required String config,
  }) {
    return mimblewimblecoin.Libmwc.deleteWallet(wallet: wallet, config: config);
  }

  @override
  Future<({String? recipientAddress, String slatepack, bool wasEncrypted})>
  encodeSlatepack({
    required String slateJson,
    String? recipientAddress,
    bool encrypt = false,
    String? wallet,
  }) {
    return mimblewimblecoin.Libmwc.encodeSlatepack(
      slateJson: slateJson,
      recipientAddress: recipientAddress,
      encrypt: encrypt,
      wallet: wallet,
    );
  }

  @override
  Future<String> getAddressInfo({required String wallet, required int index}) {
    return mimblewimblecoin.Libmwc.getAddressInfo(wallet: wallet, index: index);
  }

  @override
  Future<int> getChainHeight({required String config}) {
    return mimblewimblecoin.Libmwc.getChainHeight(config: config);
  }

  @override
  Future<({int fee, bool strategyUseAll, int total})> getTransactionFees({
    required String wallet,
    required int amount,
    required int minimumConfirmations,
    required int available,
  }) {
    return mimblewimblecoin.Libmwc.getTransactionFees(
      wallet: wallet,
      amount: amount,
      minimumConfirmations: minimumConfirmations,
      available: available,
    );
  }

  @override
  Future<List<MwcTransaction>> getTransactions({
    required String wallet,
    required int refreshFromNode,
  }) async {
    final transactions = await mimblewimblecoin.Libmwc.getTransactions(
      wallet: wallet,
      refreshFromNode: refreshFromNode,
    );

    return transactions
        .map(
          (e) => MwcTransaction(
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
                  (f) => MwcMessage(
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
    return mimblewimblecoin.Libmwc.getWalletBalances(
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
    return mimblewimblecoin.Libmwc.initializeNewWallet(
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
    return mimblewimblecoin.Libmwc.openWallet(
      config: config,
      password: password,
    );
  }

  @override
  Future<void> recoverWallet({
    required String config,
    required String password,
    required String mnemonic,
    required String name,
  }) {
    return mimblewimblecoin.Libmwc.recoverWallet(
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
    return mimblewimblecoin.Libmwc.scanOutputs(
      wallet: wallet,
      startHeight: startHeight,
      numberOfBlocks: numberOfBlocks,
    );
  }

  @override
  void startMwcMqsListener({
    required String wallet,
    required String mwcmqsConfig,
  }) {
    return mimblewimblecoin.Libmwc.startMwcMqsListener(
      wallet: wallet,
      mwcmqsConfig: mwcmqsConfig,
    );
  }

  @override
  void stopMwcMqsListener() {
    return mimblewimblecoin.Libmwc.stopMwcMqsListener();
  }

  @override
  Future<({String commitId, String slateId})> txFinalize({
    required String wallet,
    required String slateJson,
  }) {
    return mimblewimblecoin.Libmwc.txFinalize(
      wallet: wallet,
      slateJson: slateJson,
    );
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
    return mimblewimblecoin.Libmwc.txHttpSend(
      wallet: wallet,
      selectionStrategyIsAll: selectionStrategyIsAll,
      minimumConfirmations: minimumConfirmations,
      message: message,
      amount: amount,
      address: address,
    );
  }

  @override
  Future<String> txInit({
    required String wallet,
    required int amount,
    int minimumConfirmations = 1,
    bool selectionStrategyIsAll = false,
    String message = '',
  }) {
    return mimblewimblecoin.Libmwc.txInit(
      wallet: wallet,
      amount: amount,
      message: message,
      minimumConfirmations: minimumConfirmations,
      selectionStrategyIsAll: selectionStrategyIsAll,
    );
  }

  @override
  Future<({String commitId, String slateId, String slateJson})>
  txReceiveDetailed({required String wallet, required String slateJson}) {
    return mimblewimblecoin.Libmwc.txReceiveDetailed(
      wallet: wallet,
      slateJson: slateJson,
    );
  }

  @override
  bool txTypeIsReceiveCancelled(Enum value) {
    return value == mimblewimblecoin_models.TransactionType.TxReceivedCancelled;
  }

  @override
  bool txTypeIsReceived(Enum value) {
    return value == mimblewimblecoin_models.TransactionType.TxReceived;
  }

  @override
  bool txTypeIsSentCancelled(Enum value) {
    return value == mimblewimblecoin_models.TransactionType.TxSentCancelled;
  }

  @override
  bool validateSendAddress({required String address}) {
    return mimblewimblecoin.Libmwc.validateSendAddress(address: address);
  }

  @override
  String getPluginVersion() => mimblewimblecoin_versions.getPluginVersion();
}

//END_ON
